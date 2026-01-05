pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            val lp = file("local.properties")
            if (lp.exists()) {
                lp.inputStream().use { properties.load(it) }
            }
            val candidates = listOf(
                properties.getProperty("flutter.sdk"),
                System.getenv("FLUTTER_SDK"),
                System.getenv("FLUTTER_HOME"),
                "C:/src/flutter",
                "C:/flutter"
            ).filterNotNull()
            val found = candidates.firstOrNull { p ->
                try {
                    file("$p/packages/flutter_tools/gradle").exists()
                } catch (e: Exception) {
                    false
                }
            }
            found ?: throw GradleException("Flutter SDK path not found; set flutter.sdk in local.properties or FLUTTER_SDK/FLUTTER_HOME env vars")
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.9.1" apply false
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
}

include(":app")
