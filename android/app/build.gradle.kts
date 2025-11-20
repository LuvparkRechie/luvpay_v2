import java.util.Properties
import java.io.FileInputStream
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin") 
}
val keyProperties = Properties().apply {
    val keyFile = rootProject.file("key.properties")
    if (keyFile.exists()) { 
        load(FileInputStream(keyFile))
    } else {
        throw GradleException("key.properties file not found.")
    }
}
android {
    namespace = "com.cmds.luvpark"
    compileSdk = 36
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.cmds.luvpark"
        minSdk = 24
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            keyAlias = keyProperties["keyAlias"] as String
            keyPassword = keyProperties["keyPassword"] as String
            storePassword = keyProperties["storePassword"] as String
            storeFile = file(keyProperties["storeFile"] as String) 
        }
    }

    buildTypes {
        release { 
            isMinifyEnabled = false
            isShrinkResources = false

            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )

            signingConfig = signingConfigs.getByName("release")
        }
    }
    packagingOptions {
        jniLibs {
            useLegacyPackaging = false
        }
    }

}

allprojects { 
    repositories {
        google()
        mavenCentral()
        maven(url = "https://maven.scijava.org/content/repositories/public/")
    }
}

flutter {
    source = "../.."
}