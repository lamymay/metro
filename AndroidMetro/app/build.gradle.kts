plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.android)
}

android {
    namespace = "com.rakukura.metrolab"
    compileSdk = 34

    defaultConfig {
        applicationId = "com.rakukura.metrolab"
        // Android 4.1. Everything in this app is framework-only for exactly this reason.
        minSdk = 16
        targetSdk = 34
        versionCode = 1
        versionName = "1.0"
    }

    buildTypes {
        debug {
            isMinifyEnabled = false
        }
        release {
            isMinifyEnabled = false
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }

    lint {
        abortOnError = false
    }
}

// No runtime dependencies beyond the Kotlin stdlib the plugin adds itself.
dependencies {
}
