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
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
