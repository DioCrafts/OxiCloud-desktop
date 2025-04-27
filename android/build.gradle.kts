buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.android.tools.build:gradle:8.2.2")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.22")
        classpath("dev.flutter.flutter-gradle-plugin:1.0.0")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

plugins {
    id("com.android.application") version "8.7.0" apply false
    id("org.jetbrains.kotlin.android") version "1.8.22" apply false
    id("dev.flutter.flutter-gradle-plugin") version "1.0.0" apply false
}

tasks.register("clean", Delete::class) {
    delete(rootProject.buildDir)
} 