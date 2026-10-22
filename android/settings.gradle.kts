pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            val localProps = file("local.properties")
            if (localProps.exists()) {
                localProps.reader(Charsets.UTF_8).use { properties.load(it) }
            }
            var path = properties.getProperty("flutter.sdk")
            val devSdk = java.io.File("/Users/sunilsharma/Developer/flutter")
            if (path == null || path.contains("Documents") || path.contains("Sunil’s")) {
                if (devSdk.exists()) {
                    path = devSdk.absolutePath
                }
            }
            require(path != null) { "flutter.sdk not set in local.properties" }
            path
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

val flutterSdkPath =
    run {
        val properties = java.util.Properties()
        val localProps = file("local.properties")
        if (localProps.exists()) {
            localProps.reader(Charsets.UTF_8).use { properties.load(it) }
        }
        var path = properties.getProperty("flutter.sdk")
        val devSdk = java.io.File("/Users/sunilsharma/Developer/flutter")
        if (path == null || path.contains("Documents") || path.contains("Sunil’s")) {
            if (devSdk.exists()) {
                path = devSdk.absolutePath
            }
        }
        path ?: "/Users/sunilsharma/Developer/flutter"
    }

extra["flutterSdkPath"] = flutterSdkPath

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "9.1.0" apply false
    id("org.jetbrains.kotlin.android") version "2.4.0" apply false
}

include(":app")
