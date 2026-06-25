allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)

    // Inject a default namespace for plugins published before AGP 8
    // (isar_flutter_libs 3.1.0+1 ships without one). Runs when the
    // Android library plugin is applied, before evaluation completes.
    plugins.withId("com.android.library") {
        val androidExt = extensions.findByName("android") ?: return@withId
        try {
            val getNs = androidExt.javaClass.getMethod("getNamespace")
            val current = getNs.invoke(androidExt) as String?
            if (current.isNullOrEmpty()) {
                val groupName = project.group.toString().ifEmpty { project.name }
                androidExt.javaClass.getMethod("setNamespace", String::class.java)
                    .invoke(androidExt, groupName)
            }
        } catch (_: Exception) {
            // Method not present on this AGP version — nothing to patch.
        }
        // Force compileSdk 34 on every Android library subproject.
        // isar_flutter_libs ships with compileSdk 31 which is too low
        // for android:attr/lStar (introduced in API 31's R values).
        try {
            androidExt.javaClass.getMethod("setCompileSdkVersion", Int::class.javaPrimitiveType)
                .invoke(androidExt, 34)
        } catch (_: Exception) {
            // Older AGP exposes only the string overload.
            try {
                androidExt.javaClass.getMethod("setCompileSdkVersion", String::class.java)
                    .invoke(androidExt, "android-34")
            } catch (_: Exception) {}
        }
    }

    // Force Java 17 on every subproject (app + every plugin library).
    // Some Flutter plugins still ship with sourceCompatibility = 1.8
    // which Gradle/javac warn about as obsolete. Bumping them keeps
    // the build clean and future-proofs against JDK removing the
    // legacy targets entirely.
    //
    // Kotlin is left to inherit from the plugin's own DSL — Kotlin 2.x
    // removed kotlinOptions and the new compilerOptions block doesn't
    // compose cleanly here. The Java fix is what silences the warnings
    // the user actually sees; Kotlin's jvmTarget already matches.
    afterEvaluate {
        tasks.withType<JavaCompile>().configureEach {
            sourceCompatibility = JavaVersion.VERSION_17.toString()
            targetCompatibility = JavaVersion.VERSION_17.toString()
            // Hide the noisy "deprecated API" notes from third-party
            // plugins we can't fix. Still surfaces real errors.
            options.compilerArgs.addAll(listOf("-Xlint:-options", "-Xlint:-deprecation"))
        }
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
