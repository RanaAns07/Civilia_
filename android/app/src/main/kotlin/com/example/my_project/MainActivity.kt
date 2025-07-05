// android/app/src/main/kotlin/com/civilia/app/MainActivity.kt
package com.example.my_project // Ensure this package name matches your applicationId in build.gradle.kts

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.net.wifi.p2p.WifiP2pConfig
import android.net.wifi.p2p.WifiP2pDevice
import android.net.wifi.p2p.WifiP2pDeviceList
import android.net.wifi.p2p.WifiP2pManager
import android.net.wifi.p2p.WifiP2pManager.ActionListener
import android.net.wifi.p2p.WifiP2pManager.Channel
import android.net.wifi.p2p.WifiP2pManager.ConnectionInfoListener
import android.net.wifi.p2p.WifiP2pManager.PeerListListener
import android.os.Build
import android.os.Looper
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.io.BufferedReader
import java.io.IOException
import java.io.InputStreamReader
import java.io.PrintWriter
import java.net.InetAddress
import java.net.ServerSocket
import java.net.Socket
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

class MainActivity: FlutterActivity() {
    private val METHOD_CHANNEL_NAME = "com.civilia.app/wifi_direct_method"
    private val EVENT_CHANNEL_NAME = "com.civilia.app/wifi_direct_event"

    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var eventSink: EventChannel.EventSink? = null // Changed to var

    private lateinit var wifiDirectHandler: WifiDirectHandler

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL_NAME)
        eventChannel = EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL_NAME)

        // Pass this@MainActivity context to the handler
        wifiDirectHandler = WifiDirectHandler(this, methodChannel, eventSink)

        methodChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "startDiscovery" -> {
                    wifiDirectHandler.startDiscovery(result)
                }
                "stopDiscovery" -> {
                    wifiDirectHandler.stopDiscovery(result)
                }
                "connectToPeer" -> {
                    val address = call.argument<String>("address")
                    if (address != null) {
                        wifiDirectHandler.connectToPeer(address, result)
                    } else {
                        result.error("INVALID_ARGUMENT", "Peer address is required.", null)
                    }
                }
                "disconnect" -> {
                    wifiDirectHandler.disconnect(result)
                }
                "sendMessage" -> {
                    val message = call.argument<String>("message")
                    if (message != null) {
                        wifiDirectHandler.sendMessage(message, result)
                    } else {
                        result.error("INVALID_ARGUMENT", "Message is required.", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        eventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, sink: EventChannel.EventSink) {
                eventSink = sink
                wifiDirectHandler.setEventSink(sink) // Provide the sink to the handler
                Log.d("MainActivity", "EventChannel onListen")
            }

            override fun onCancel(arguments: Any?) {
                eventSink = null
                wifiDirectHandler.setEventSink(null)
                Log.d("MainActivity", "EventChannel onCancel")
            }
        })
    }

    override fun onResume() {
        super.onResume()
        wifiDirectHandler.registerReceiver()
    }

    override fun onPause() {
        super.onPause()
        wifiDirectHandler.unregisterReceiver()
    }

    override fun onDestroy() {
        super.onDestroy()
        wifiDirectHandler.cleanup() // Ensure all resources are released
    }
}

class WifiDirectHandler(private val context: Context, private val methodChannel: MethodChannel, private var eventSink: EventChannel.EventSink?) : // Changed eventSink to var
    PeerListListener, ConnectionInfoListener {

    private val TAG = "WifiDirectHandler"

    private var manager: WifiP2pManager? = null
    private var channel: Channel? = null
    private lateinit var receiver: BroadcastReceiver
    private val intentFilter = IntentFilter()

    private val peers = mutableListOf<WifiP2pDevice>()
    private var isGroupOwner = false
    private var groupOwnerAddress: InetAddress? = null
    private var clientSocket: Socket? = null
    private var serverSocket: ServerSocket? = null
    private val executorService: ExecutorService = Executors.newCachedThreadPool()

    init {
        manager = context.getSystemService(Context.WIFI_P2P_SERVICE) as WifiP2pManager?
        channel = manager?.initialize(context, Looper.getMainLooper(), null)

        intentFilter.addAction(WifiP2pManager.WIFI_P2P_STATE_CHANGED_ACTION)
        intentFilter.addAction(WifiP2pManager.WIFI_P2P_PEERS_CHANGED_ACTION)
        intentFilter.addAction(WifiP2pManager.WIFI_P2P_CONNECTION_CHANGED_ACTION)
        intentFilter.addAction(WifiP2pManager.WIFI_P2P_THIS_DEVICE_CHANGED_ACTION)

        receiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                when (intent?.action) {
                    WifiP2pManager.WIFI_P2P_STATE_CHANGED_ACTION -> {
                        val state = intent.getIntExtra(WifiP2pManager.EXTRA_WIFI_STATE, -1)
                        if (state == WifiP2pManager.WIFI_P2P_STATE_ENABLED) {
                            sendEvent("connection_status_changed", mapOf("status" to "Wi-Fi P2P Enabled"))
                        } else {
                            sendEvent("connection_status_changed", mapOf("status" to "Wi-Fi P2P Disabled"))
                        }
                    }
                    WifiP2pManager.WIFI_P2P_PEERS_CHANGED_ACTION -> {
                        manager?.requestPeers(channel, this@WifiDirectHandler)
                    }
                    WifiP2pManager.WIFI_P2P_CONNECTION_CHANGED_ACTION -> {
                        val networkInfo = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                            intent.getParcelableExtra(WifiP2pManager.EXTRA_NETWORK_INFO, android.net.NetworkInfo::class.java)
                        } else {
                            @Suppress("DEPRECATION")
                            intent.getParcelableExtra(WifiP2pManager.EXTRA_NETWORK_INFO)
                        }
                        if (networkInfo?.isConnected == true) {
                            manager?.requestConnectionInfo(channel, this@WifiDirectHandler)
                        } else {
                            sendEvent("connection_status_changed", mapOf("status" to "Disconnected"))
                            cleanupSockets()
                        }
                    }
                    WifiP2pManager.WIFI_P2P_THIS_DEVICE_CHANGED_ACTION -> {
                        // Handle device info changes if needed
                    }
                }
            }
        }
    }

    fun setEventSink(sink: EventChannel.EventSink?) {
        eventSink = sink
    }

    fun registerReceiver() {
        context.registerReceiver(receiver, intentFilter)
    }

    fun unregisterReceiver() {
        try {
            context.unregisterReceiver(receiver)
        } catch (e: IllegalArgumentException) {
            Log.e(TAG, "Receiver not registered: ${e.message}")
        }
    }

    fun startDiscovery(result: MethodChannel.Result) {
        manager?.discoverPeers(channel, object : ActionListener {
            override fun onSuccess() {
                sendEvent("connection_status_changed", mapOf("status" to "Discovery started"))
                result.success("Discovery started")
            }

            override fun onFailure(reason: Int) {
                val errorMessage = getReasonString(reason)
                sendEvent("error", mapOf("message" to "Discovery failed: $errorMessage"))
                result.error("DISCOVERY_FAILED", "Discovery failed: $errorMessage", null)
            }
        })
    }

    fun stopDiscovery(result: MethodChannel.Result) {
        manager?.stopPeerDiscovery(channel, object : ActionListener {
            override fun onSuccess() {
                sendEvent("connection_status_changed", mapOf("status" to "Discovery stopped"))
                result.success("Discovery stopped")
            }

            override fun onFailure(reason: Int) {
                val errorMessage = getReasonString(reason)
                sendEvent("error", mapOf("message" to "Stop discovery failed: $errorMessage"))
                result.error("STOP_DISCOVERY_FAILED", "Stop discovery failed: $errorMessage", null)
            }
        })
    }

    override fun onPeersAvailable(peerList: WifiP2pDeviceList?) {
        peers.clear()
        peerList?.deviceList?.let {
            peers.addAll(it)
        }
        val peerNames = peers.map { it.deviceName } // Use deviceName for display
        sendEvent("peers_updated", mapOf("peers" to peerNames))
        Log.d(TAG, "Peers available: ${peerNames.joinToString()}")
    }

    fun connectToPeer(deviceName: String, result: MethodChannel.Result) { // Changed parameter to deviceName
        val device = peers.find { it.deviceName == deviceName } // Find by deviceName
        if (device != null) {
            val config = WifiP2pConfig().apply {
                deviceAddress = device.deviceAddress
            }
            manager?.connect(channel, config, object : ActionListener {
                override fun onSuccess() {
                    sendEvent("connection_status_changed", mapOf("status" to "Connection initiated"))
                    result.success("Connection initiated")
                    Log.d(TAG, "Connection initiated to ${device.deviceName}")
                }

                override fun onFailure(reason: Int) {
                    val errorMessage = getReasonString(reason)
                    sendEvent("error", mapOf("message" to "Connection failed: $errorMessage"))
                    result.error("CONNECTION_FAILED", "Connection failed: $errorMessage", null)
                    Log.e(TAG, "Connection failed to ${device.deviceName}: $errorMessage")
                }
            })
        } else {
            result.error("PEER_NOT_FOUND", "Selected peer not found.", null)
            sendEvent("error", mapOf("message" to "Selected peer not found: $deviceName"))
        }
    }

    override fun onConnectionInfoAvailable(info: android.net.wifi.p2p.WifiP2pInfo?) {
        if (info != null && info.groupFormed) {
            isGroupOwner = info.isGroupOwner
            groupOwnerAddress = info.groupOwnerAddress

            sendEvent("connection_status_changed", mapOf("status" to "Connected"))
            Log.d(TAG, "Group formed. Is owner: $isGroupOwner, Group Owner Address: $groupOwnerAddress")

            if (isGroupOwner) {
                startServer()
            } else {
                groupOwnerAddress?.let { connectToServer(it) }
            }
        }
    }

    private fun startServer() {
        executorService.execute {
            try {
                serverSocket = ServerSocket(8888) // Port for communication
                Log.d(TAG, "Server socket created, waiting for client...")
                sendEvent("connection_status_changed", mapOf("status" to "Waiting for client..."))
                clientSocket = serverSocket?.accept()
                Log.d(TAG, "Client connected to server!")
                sendEvent("connection_status_changed", mapOf("status" to "Connected (Group Owner)"))
                startReadingMessages(clientSocket)
            } catch (e: IOException) {
                Log.e(TAG, "Server socket error: ${e.message}")
                sendEvent("error", mapOf("message" to "Server error: ${e.message}"))
                cleanupSockets()
            }
        }
    }

    private fun connectToServer(ownerAddress: InetAddress) {
        executorService.execute {
            try {
                clientSocket = Socket(ownerAddress, 8888)
                Log.d(TAG, "Connected to group owner!")
                sendEvent("connection_status_changed", mapOf("status" to "Connected (Client)"))
                startReadingMessages(clientSocket)
            } catch (e: IOException) {
                Log.e(TAG, "Client socket error: ${e.message}")
                sendEvent("error", mapOf("message" to "Client error: ${e.message}"))
                cleanupSockets()
            }
        }
    }

    private fun startReadingMessages(socket: Socket?) {
        if (socket == null) return
        executorService.execute {
            try {
                val reader = BufferedReader(InputStreamReader(socket.getInputStream()))
                var line: String? = null // Initialized to null
                while (socket.isConnected && reader.readLine().also { line = it } != null) {
                    line?.let {
                        sendEvent("message_received", mapOf("message" to it))
                        Log.d(TAG, "Message received: $it")
                    }
                }
            } catch (e: IOException) {
                Log.e(TAG, "Error reading message: ${e.message}")
                sendEvent("error", mapOf("message" to "Message read error: ${e.message}"))
            } finally {
                Log.d(TAG, "Disconnected from message stream.")
                sendEvent("connection_status_changed", mapOf("status" to "Disconnected"))
                cleanupSockets()
            }
        }
    }

    fun sendMessage(message: String, result: MethodChannel.Result) {
        executorService.execute {
            try {
                if (clientSocket != null && clientSocket!!.isConnected) {
                    val writer = PrintWriter(clientSocket!!.getOutputStream(), true)
                    writer.println(message)
                    result.success("Message sent")
                    Log.d(TAG, "Message sent: $message")
                } else {
                    result.error("NOT_CONNECTED", "Not connected to a peer.", null)
                    sendEvent("error", mapOf("message" to "Cannot send message: not connected."))
                }
            } catch (e: IOException) {
                Log.e(TAG, "Error sending message: ${e.message}")
                result.error("SEND_FAILED", "Failed to send message: ${e.message}", null)
                sendEvent("error", mapOf("message" to "Send message error: ${e.message}"))
            }
        }
    }

    fun disconnect(result: MethodChannel.Result) {
        manager?.removeGroup(channel, object : ActionListener {
            override fun onSuccess() {
                sendEvent("connection_status_changed", mapOf("status" to "Disconnected"))
                result.success("Disconnected")
                Log.d(TAG, "Disconnected from group.")
                cleanupSockets()
            }

            override fun onFailure(reason: Int) {
                val errorMessage = getReasonString(reason)
                sendEvent("error", mapOf("message" to "Failed to disconnect: $errorMessage"))
                result.error("DISCONNECT_FAILED", "Failed to disconnect: $errorMessage", null)
                Log.e(TAG, "Failed to disconnect: $errorMessage")
            }
        })
    }

    fun cleanup() {
        unregisterReceiver()
        manager?.cancelConnect(channel, null)
        manager?.removeGroup(channel, null)
        cleanupSockets()
        executorService.shutdownNow()
        Log.d(TAG, "WifiDirectHandler cleaned up.")
    }

    private fun cleanupSockets() {
        try {
            clientSocket?.close()
            serverSocket?.close()
        } catch (e: IOException) {
            Log.e(TAG, "Error closing sockets: ${e.message}")
        } finally {
            clientSocket = null
            serverSocket = null
            isGroupOwner = false
            groupOwnerAddress = null
        }
    }

    private fun sendEvent(type: String, data: Map<String, Any>) {
        // Ensure eventSink is not null and on the main thread
        context.mainLooper.run {
            eventSink?.success(mapOf("type" to type, "data" to data))
        }
    }

    private fun getReasonString(reason: Int): String {
        return when (reason) {
            WifiP2pManager.P2P_UNSUPPORTED -> "P2P_UNSUPPORTED"
            WifiP2pManager.ERROR -> "ERROR"
            WifiP2pManager.BUSY -> "BUSY"
            WifiP2pManager.NO_SERVICE_REQUESTS -> "NO_SERVICE_REQUESTS"
            else -> "UNKNOWN_REASON ($reason)"
        }
    }
}
