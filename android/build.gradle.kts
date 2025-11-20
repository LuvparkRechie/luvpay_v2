// Top-level build file
plugins {
    // Add any necessary plugins here
}

val kotlinVersion = "2.1.0"

allprojects {
    repositories {
        google()
        mavenCentral()
        maven(url = "https://maven.scijava.org/content/repositories/public/")
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.set(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.set(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}