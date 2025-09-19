plugins {
    // Declare Firebase App Distribution plugin here (if used)
    id("com.google.firebase.appdistribution") version "4.0.0" apply false
    // IMPORTANT: Declare google-services plugin here with a consistent version.
    // We will manage its version via classpath in buildscript dependencies.
    id("com.google.gms.google-services") version "4.4.2" apply false
}

buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // Android Gradle Plugin
        classpath("com.android.tools.build:gradle:7.3.0") // Ensure this matches your project's AGP version

        // IMPORTANT: Explicitly declare the google-services plugin classpath with the desired version.
        // This is the primary place to control its version to avoid conflicts.
        classpath("com.google.gms:google-services:4.4.2") // <--- ENSURE THIS LINE IS HERE WITH VERSION 4.4.2
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
