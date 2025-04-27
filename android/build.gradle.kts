buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.android.tools.build:gradle:8.7.0")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.8.22")
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
}

tasks.register("clean", Delete::class) {
    delete(rootProject.buildDir)
} 