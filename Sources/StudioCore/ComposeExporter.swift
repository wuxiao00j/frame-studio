import Foundation

enum ComposeExporter {
    static func write(_ p:DesignProject,to root:URL)throws {
        try DesignExporter.copyTemplate("Android",to:root)
        let source="app/src/main/java/dev/framestudio/generated/"
        try DesignExporter.writeText(try String(contentsOf:DesignExporter.resources.appendingPathComponent("compose_runtime.kt"),encoding:.utf8),at:root,path:source+"DesignRuntime.kt")
        try DesignExporter.writeAssets(p,at:root,path:"app/src/main/assets")
        try DesignExporter.writeText("""
        pluginManagement { repositories { google(); mavenCentral(); gradlePluginPortal() } }
        dependencyResolutionManagement { repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS); repositories { google(); mavenCentral() } }
        rootProject.name = "DesignedApp"
        include(":app")
        """,at:root,path:"settings.gradle.kts")
        try DesignExporter.writeText("""
        plugins {
            id("com.android.application") version "8.11.1" apply false
            id("org.jetbrains.kotlin.android") version "2.2.20" apply false
            id("org.jetbrains.kotlin.plugin.compose") version "2.2.20" apply false
        }
        """,at:root,path:"build.gradle.kts")
        try DesignExporter.writeText("""
        plugins { id("com.android.application"); id("org.jetbrains.kotlin.android"); id("org.jetbrains.kotlin.plugin.compose") }
        android {
            namespace = "dev.framestudio.generated"
            compileSdk = 36
            defaultConfig { applicationId = "dev.framestudio.generated"; minSdk = 24; targetSdk = 36; versionCode = 1; versionName = "1.0" }
            buildFeatures { compose = true }
            compileOptions { sourceCompatibility = JavaVersion.VERSION_17; targetCompatibility = JavaVersion.VERSION_17 }
            kotlinOptions { jvmTarget = "17" }
        }
        dependencies {
            implementation("androidx.activity:activity-compose:1.10.1")
            implementation(platform("androidx.compose:compose-bom:2025.08.01"))
            implementation("androidx.compose.ui:ui")
            implementation("androidx.compose.foundation:foundation")
            implementation("androidx.compose.material3:material3")
            implementation("androidx.compose.material:material-icons-extended:1.7.8")
        }
        """,at:root,path:"app/build.gradle.kts")
        try DesignExporter.writeText("org.gradle.jvmargs=-Xmx3g -Dfile.encoding=UTF-8\nandroid.useAndroidX=true\nkotlin.code.style=official\n",at:root,path:"gradle.properties")
        try DesignExporter.writeText("""
        <manifest xmlns:android="http://schemas.android.com/apk/res/android">
            <application android:label="@string/app_name" android:theme="@style/AppTheme" android:supportsRtl="true" android:allowBackup="false">
                <activity android:name=".MainActivity" android:exported="true" android:windowSoftInputMode="adjustNothing">
                    <intent-filter><action android:name="android.intent.action.MAIN"/><category android:name="android.intent.category.LAUNCHER"/></intent-filter>
                </activity>
            </application>
        </manifest>
        """,at:root,path:"app/src/main/AndroidManifest.xml")
        let title=p.name.replacingOccurrences(of:"&",with:"&amp;").replacingOccurrences(of:"<",with:"&lt;").replacingOccurrences(of:">",with:"&gt;").replacingOccurrences(of:"'",with:"\\'").replacingOccurrences(of:"\"",with:"\\\"")
        try DesignExporter.writeText("<resources><string name=\"app_name\">\(title)</string><style name=\"AppTheme\" parent=\"android:style/Theme.Material.Light.NoActionBar\"><item name=\"android:fontFamily\">sans</item><item name=\"android:windowLightStatusBar\">true</item><item name=\"android:windowActionModeOverlay\">true</item></style></resources>",at:root,path:"app/src/main/res/values/strings.xml")
        for page in p.pages {
            let nodes=page.nodes.filter{!$0.hidden}
            let json=try JSONSerialization.data(withJSONObject:nodes.map{try DesignExporter.data($0,device:p.device,page:page)},options:[.sortedKeys,.withoutEscapingSlashes])
            let data=String(data:json,encoding:.utf8)!
            let custom=nodes.filter{$0.kind == .custom && !($0.composeCode ?? "").trimmingCharacters(in:.whitespacesAndNewlines).isEmpty}.map{"\(DesignExporter.literal($0.id)) -> { \($0.composeCode!) }"}.joined(separator:"\n")
            let name=DesignExporter.pageName(page)
            try DesignExporter.writeText("""
            package dev.framestudio.generated
            import androidx.compose.runtime.*
            import androidx.compose.material3.*
            import androidx.compose.foundation.layout.*
            import androidx.compose.ui.Modifier
            import androidx.compose.ui.unit.*
            // \(page.name.replacingOccurrences(of:"\n",with:" ").replacingOccurrences(of:"\r",with:" "))
            @Composable
            fun \(name)(variant: Int, navigate: (String) -> Unit, openSidebar: () -> Unit) {
                val nodes = remember { parseDesignNodes(\(DesignExporter.kotlinString(data))) }
                DesignCanvas(\(DesignExporter.literal(page.id)), designColor(\(DesignExporter.literal(page.background))), nodes, variant, navigate, openSidebar, \(page.isScrollable), listOf(\(Variant.allCases.map{SwiftExporter.number(page.contentHeight($0,device:p.device))+"f"}.joined(separator:", ")))) { id ->
                    when (id) { \(custom)
                        else -> Text("TODO: Compose 自定义组件")
                    }
                }
            }
            """,at:root,path:source+name+".kt")
        }
        let cases=p.pages.map{"\(DesignExporter.literal($0.id)) -> \(DesignExporter.pageName($0))(variant, navigate, openSidebar)"}.joined(separator:"\n")
        let routes=p.pages.map{"TextButton(onClick = { navigate(\(DesignExporter.literal($0.id))) }, modifier = Modifier.fillMaxWidth()) { Text(\(DesignExporter.literal($0.name))) }"}.joined(separator:"\n")
        try DesignExporter.writeText("""
        package dev.framestudio.generated
        import android.os.Bundle
        import androidx.activity.ComponentActivity
        import androidx.activity.compose.setContent
        import androidx.activity.compose.BackHandler
        import androidx.activity.enableEdgeToEdge
        import androidx.compose.foundation.*
        import androidx.compose.foundation.layout.*
        import androidx.compose.material3.*
        import androidx.compose.runtime.*
        import androidx.compose.runtime.saveable.rememberSaveable
        import androidx.compose.ui.Modifier
        import androidx.compose.ui.graphics.Color
        import androidx.compose.ui.unit.dp
        import kotlin.math.min
        class MainActivity : ComponentActivity() {
            override fun onCreate(savedInstanceState: Bundle?) { super.onCreate(savedInstanceState); enableEdgeToEdge(); setContent { MaterialTheme(colorScheme = lightColorScheme(primary = Color(0xFF7560D4))) { DesignedApp() } } }
        }
        @Composable fun DesignedApp() {
            var selected by rememberSaveable { mutableStateOf(\(DesignExporter.literal(p.pages[0].id))) }
            var sidebar by rememberSaveable { mutableStateOf(false) }
            val history = remember { mutableStateListOf<String>() }
            val navigate: (String) -> Unit = { if (it == "__back") { if (history.isNotEmpty()) selected = history.removeAt(history.lastIndex) } else if (it.isNotEmpty() && it != selected) { history.add(selected); selected = it }; sidebar = false }
            BackHandler(enabled = history.isNotEmpty()) { navigate("__back") }
            val openSidebar: () -> Unit = { sidebar = !sidebar }
            BoxWithConstraints(Modifier.fillMaxSize()) {
                val landscape = maxWidth > maxHeight
                val variant = \(p.wideMode ? "(if (min(maxWidth.value, maxHeight.value) < \(SwiftExporter.number((p.device.outer.width+p.device.inner.width)/2))f) 2 else 4) + (if (landscape) 1 else 0)" : "if (landscape) 1 else 0")
                when(selected) { \(cases)
                    else -> \(DesignExporter.pageName(p.pages[0]))(variant, navigate, openSidebar)
                }
                if (sidebar) {
                    Box(Modifier.fillMaxSize().background(Color.Black.copy(alpha = 0.18f)).clickable { sidebar = false })
                    Column(Modifier.fillMaxHeight().width(min(maxWidth.value * 0.8f, 280f).dp).background(Color.White).padding(top = 48.dp).verticalScroll(rememberScrollState())) {
                        TextButton(onClick = { sidebar = false }) { Text("关闭侧栏") }
                        \(routes)
                    }
                }
            }
        }
        """,at:root,path:source+"MainActivity.kt")
        try DesignExporter.writeText("""
        # \(p.name) · Android 原生 Compose 导出

        UI 源码工程：包含 Kotlin 页面、Compose 组件、PNG 资源、Manifest 和项目配置。导出不生成 APK / AAB。
        UI source scaffold: Kotlin pages, Compose widgets, PNG assets and project configuration. Export never generates APK/AAB packages. Business features still need implementation.
        JDK 17、Gradle 8.14、AGP 8.11.1、Kotlin / Compose 插件 2.2.20、compile / target SDK 36、min SDK 24。

        ```sh
        ./gradlew :app:compileDebugKotlin
        ```

        上面的命令仅编译检查 Kotlin，不打包手机 App。
        The command above compiles Kotlin for validation without packaging a mobile app.
        首次编译需要下载 Gradle 和 Google / Maven Central 依赖。Android Studio 自动设置 local.properties，或在环境中设置 ANDROID_HOME。未导出本机绝对 SDK 路径。
        系统图标映射为 Material Icons；图片保存在 app/src/main/assets。
        自定义 Compose 代码来自 composeCode 字段；缺失时保留 TODO 占位，详见 EXPORT_REPORT.md。
        """,at:root,path:"README.md")
        try DesignExporter.writeText(".gradle/\nlocal.properties\nbuild/\napp/build/\n.idea/\n",at:root,path:".gitignore")
        try FileManager.default.setAttributes([.posixPermissions:0o755],ofItemAtPath:root.appendingPathComponent("gradlew").path)
    }
}
