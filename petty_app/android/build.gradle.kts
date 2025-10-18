// Top-level build file where you can add configuration options common to all sub-projects/modules.

import org.gradle.api.tasks.Delete
import org.gradle.api.file.Directory

plugins {
    // Add your required plugins here if needed
    // Example: id("com.android.application") version "8.5.0" apply false
    // Example: id("org.jetbrains.kotlin.android") version "1.9.0" apply false
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Configure new centralized build directory
val newBuildDir: Directory = rootProject.layout.buildDirectory
    .dir("../../build")
    .get()

rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    // Each subproject (like :app) will have its own build directory under the central one
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)

    // Ensure that the app module is evaluated first
    project.evaluationDependsOn(":app")
}

// Clean task for removing all builds
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
