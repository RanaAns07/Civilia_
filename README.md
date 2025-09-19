# 🛡️ Civilia War Time Companion

> A mobile-first crisis management platform designed to empower civilians, responders, and aid workers with real-time safety intelligence, **Bluetooth Mesh offline communication**, and emergency guidance during times of **war or disaster** when traditional communication networks fail.

---

## 📖 Table of Contents

- [🌍 Introduction](#introduction)  
- [💡 Motivation](#motivation)  
- [🚀 Key Features](#key-features)  
- [🛠 Technology Stack](#technology-stack)  
- [🏗 System Architecture](#system-architecture)  
- [🔧 Implementation Overview](#implementation-overview)  
- [⚡ Challenges & Solutions](#challenges--solutions)  
- [🔮 Future Enhancements](#future-enhancements)  
- [📜 License](#license)  

---

## 🌍 Introduction

**Civilia War Time Companion** is a resilient mobile application providing critical tools for **civilian safety, crisis communication**, and **resilience during emergencies**.

Designed for wartime conditions, natural disasters, and communication blackouts, Civilia allows communities to:

- 🔔 Share real-time safety updates  
- ⚠️ Report and track incidents  
- 📡 Communicate offline via **Bluetooth Mesh**  
- 🆘 Send SOS alerts  
- 🏥 Access offline first aid guides  

This project is continuously evolving with improvements in **offline networking**, **AI integration**, and **crisis intelligence**.

---

## 💡 Motivation

- 🛰️ **Civilian Safety in Blackouts**  
  Stay connected when cellular networks collapse.  

- 🆘 **Emergency First Response**  
  Provide danger alerts, safe zone maps, and life-saving guides.  

- 🤝 **Community Empowerment**  
  Foster shared awareness via citizen-sourced incident reporting.  

- 🛠️ **Resilience in Crisis**  
  Build trust in tools that work under extreme conditions.  

---

## 🚀 Key Features

### 🗺️ Interactive Crisis Map
- Real-time safe/danger zone mapping  
- Community-reported incident overlays  

### ⚠️ Incident Reporting
- Submit incident type, description, location, optional image  
- Responders can update incident status  

### 🆘 SOS Alerts
- One-tap distress signal  
- Live geolocation sharing with nearby peers  

### 🏥 First Aid & Emergency Guides
- Offline emergency response instructions (CPR, burns, bleeding, etc.)

### 📡 Offline Bluetooth Mesh Messaging
- Peer-to-peer & multi-hop messaging without internet  
- Native mesh networking for wide offline coverage  

### 🤖 AI Assistant (Civilia)
- Gemini-powered assistant for in-app emergency guidance  

### 👮 Role-Based Access
- Different toolsets for civilians, responders, and aid workers  

### ⚙️ Profile & App Settings
- Language preferences, dark mode, and notification control  

---

## 🛠 Technology Stack

| Component             | Technology                      |
|----------------------|----------------------------------|
| **Frontend**          | Flutter (Android & iOS)         |
| **Backend**           | Django REST Framework (Python)  |
| **Cloud Services**    | Firebase (Auth, Firestore)      |
| **Offline Messaging** | Bluetooth Mesh (native)         |
| **AI Integration**    | Gemini API                      |
| **Location Services** | Geolocator (GPS + Reverse Geocode) |
| **Media Upload**      | Image Picker                    |

---

## 🏗 System Architecture
                                 +-------------------------+
                                 |     Mobile Frontend     |
                                 |       (Flutter)         |
                                 | Crisis Map, UI, AI Chat |
                                 +-----------+-------------+
                                             |
                                             v
                             +-------------------------------+
                             |        Django REST API        |
                             |   (Auth, Incident Reports,    |
                             |   Role-Based Access Control)  |
                             +-------------------------------+
                                             |
                           +----------------+----------------+
                           |                                 |
                           v                                 v
          +-----------------------------+     +-----------------------------+
          |      Bluetooth Mesh Layer   |     |     Firebase Cloud Sync     |
          | (Offline Multi-Hop Messaging)|     | (Firestore, Auth Syncing)   |
          +-----------------------------+     +-----------------------------+
---

## 🔧 Implementation Overview

- **Frontend:** Flutter UI with interactive crisis maps, reporting tools, and SOS interface  
- **Backend:** Django REST APIs for authentication, role management, incident CRUD  
- **Offline Comms:** Bluetooth Mesh using native integration for true decentralized messaging  
- **AI Assistant:** Gemini-powered chatbot for real-time user support in the app  

---

## ⚡ Challenges & Solutions

| Challenge                                | Solution                                                                 |
|-----------------------------------------|--------------------------------------------------------------------------|
| Offline reliability                     | Switched from Wi-Fi Direct to **Bluetooth Mesh** with multi-hop relaying |
| High-stress UX                          | Minimal-click flows with large buttons & clear visuals                   |
| Data sync during blackouts              | Built offline-first storage with auto-sync on reconnection               |
| Security under threat                   | End-to-end encryption for mesh + HTTPS for cloud comms                   |
| Device performance limitations          | Used image compression, map caching, and lazy rendering                  |

---

## 🔮 Future Enhancements

- 🔁 Full Bluetooth Mesh routing & relay optimization  
- 🧠 AI-powered **threat prediction** and **safe route suggestion**  
- 🧭 **AR Navigation** with overlays for safe zones and active incidents  
- 🌐 NGO + UN aid integration APIs  
- 🚁 Drone/satellite feeds for real-time crisis visualization  
- 📚 Interactive training modules for survival and first aid  

---


## 📜 License

This project is part of the **Final Year Project (ADP-CS, 2023–2025)** at **Riphah International College, Lahore**.

> Licensing terms will be updated upon official open-source release.

---

🛡️ *Civilia is built with one goal: Keep people informed, connected, and safe — even when everything else fails.*
