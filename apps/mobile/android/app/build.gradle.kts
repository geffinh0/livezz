import groovy.json.JsonSlurper

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.livezz.livezz_mobile"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // applicationId vem do flavor (tenants/<id>/tenant.json). Nada de cliente fixo aqui.
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Um flavor por tenant, lido de tenants/<id>/tenant.json (white-label, TRV08).
    flavorDimensions += "tenant"
    productFlavors {
        val tenantsDir = rootProject.file("../../../tenants")
        tenantsDir.listFiles()
            ?.filter { File(it, "tenant.json").isFile }
            ?.sortedBy { it.name }
            ?.forEach { dir ->
                @Suppress("UNCHECKED_CAST")
                val t = JsonSlurper().parse(File(dir, "tenant.json")) as Map<String, Any>
                create(t["id"] as String) {
                    dimension = "tenant"
                    applicationId = t["androidPackage"] as String
                    resValue("string", "app_name", t["appName"] as String)
                }
            }
    }

    buildTypes {
        release {
            // Assinatura de release do cliente entra na Fase 13 (key.properties fora do git).
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
