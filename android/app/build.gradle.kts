import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

// 🔑 قراءة بيانات مفتاح التوقيع الحقيقي من key.properties (الملف نفسو
// مستثنى من git عمداً لأنه فيه كلمات سر — شوف .gitignore)
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

// 🔒 الإصدار الرسمي (release) لا يُبنى إلا بمفتاح التوقيع الخاص بمالكة المشروع.
// بدون مفتاح التوقيع الخاص بها يفشل البناء بدل أن يُنتج APK غير موقّع أو موقّع بمفتاح آخر
// (APK بمفتاح مختلف لا يقدر يحدّث النسخة المثبتة عند المستخدمين أصلاً). التفاصيل: OFFICIAL_RELEASES.md
gradle.taskGraph.whenReady {
    val wantsRelease = allTasks.any {
        it.name.contains("Release", ignoreCase = true) &&
            (it.name.startsWith("assemble") || it.name.startsWith("bundle") || it.name.startsWith("package"))
    }
    if (wantsRelease && !keystorePropertiesFile.exists()) {
        throw GradleException(
            "\n\nبناء الإصدار الرسمي (release) متاح لمالكة المشروع فقط: مفتاح التوقيع غير موجود عندك." +
                "\nالإصدارات الرسمية تُبنى وتُنشر من جهازها فقط. للتجربة استعمل: flutter run أو flutter build apk --debug" +
                "\nOfficial release builds are produced only by the project owner. See OFFICIAL_RELEASES.md.\n"
        )
    }
}

android {
    namespace = "com.example.edu_pridge_flutter"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.edu_pridge_flutter"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // 🔑 هلق موقّع بمفتاح إصدار حقيقي دائم (edubridge-release.jks)
            // بدل مفتاح التجربة (debug) — ضروري لأي تحديث مستقبلي للتطبيق
            // ولأي نشر عام (Uptodown، Play Store، إلخ)
            signingConfig = signingConfigs.getByName("release")
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}

flutter {
    source = "../.."
}
