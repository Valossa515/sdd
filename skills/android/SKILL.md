---
name: android
description: Use this skill for any Android app task — Gradle modules, Compose screens, ViewModels, Room, DataStore, WorkManager, permissions, tests, or refactoring. Targets Kotlin 2.x with Jetpack Compose, Hilt, Room and a multi-module Gradle build.
stack: android
versions: "Kotlin 2.x, AGP 9.x (built-in Kotlin), Jetpack Compose (BOM), Material 3, Hilt, Room, DataStore, WorkManager, Gradle Kotlin DSL"
---

# Android Agent Skill

You are an expert Android engineer building apps in Kotlin with Jetpack Compose. Follow these guidelines for every task in this project. Android leaves structure, DI and state handling open: this skill makes those choices explicit, so every feature is built the same way.

## Stack Versions (always target these unless told otherwise)

- **Kotlin**: 2.x, coroutines and Flow throughout
- **Android Gradle Plugin**: 9.x with **built-in Kotlin**, Gradle with Kotlin DSL (`build.gradle.kts`) and a version catalog (`gradle/libs.versions.toml`)
- **JDK**: one version for the toolchain, the Gradle daemon and CI (see Gradle → JDK)
- **SDK levels**: `minSdk`, `targetSdk` and `compileSdk` come from the project's convention (see `.agent/SKILLS.md` → Project Overrides); never raise or lower them inside a feature task. `compileSdk` may be higher than `targetSdk`: recent AndroidX libraries require a recent `compileSdk`, which only decides which APIs compile, while `targetSdk` decides runtime behaviour and follows the Play Store requirement. Record such a split as a decision
- **UI**: Jetpack Compose via the Compose BOM, Material 3, Navigation Compose with type-safe routes
- **DI**: Hilt 2.59.2+ (KSP 2.3.6+, the minimums for AGP 9)
- **Persistence**: Room (KSP) for relational data, DataStore (Preferences) for settings
- **Background work**: WorkManager
- **Serialization**: kotlinx.serialization

---

## Architecture

A multi-module Gradle build. Logic that does not need Android lives in pure Kotlin modules, so it runs in plain JVM tests and can be reused.

```
settings.gradle.kts
gradle/libs.versions.toml       ← every version and dependency alias
app/                            ← Application class, navigation graph, screens, workers, DI wiring
├── src/main/kotlin/com/example/app/
│   ├── ExampleApplication.kt
│   ├── MainActivity.kt
│   ├── navigation/             ← routes + NavHost
│   ├── ui/
│   │   ├── theme/
│   │   ├── components/         ← reusable composables with no ViewModel
│   │   └── <feature>/          ← <Feature>Screen.kt, <Feature>ViewModel.kt, <Feature>UiState.kt
│   ├── work/                   ← WorkManager workers and schedulers
│   └── di/                     ← Hilt modules that bind app-level types
core-domain/                    ← pure Kotlin: models, use case and port interfaces, business rules
core-data/                      ← Android library: Room, DataStore, repository implementations
core-<capability>/              ← Android library: one platform capability behind domain ports
```

**Dependency direction:** `app` → `core-data` / `core-<capability>` → `core-domain`. Nothing points back.

**Rules:**
- `core-domain` applies only the `kotlin("jvm")` plugin: **zero** `android.*` or `androidx.*` imports
- Business rules (scoring, validation, comparison, parsing) live in `core-domain` as pure functions or plain classes
- Platform APIs (`PackageManager`, `NfcAdapter`, sensors, `ContentResolver`) are called only from adapter classes in `core-<capability>` or `core-data` that implement a `core-domain` interface
- Composables render state and emit events. They never call a repository, a DAO or a platform API
- One ViewModel per screen. It exposes a single `StateFlow<UiState>` and takes use cases or repositories in the constructor
- A library module never depends on `app`

---

## Naming Conventions

| Artifact | Convention | Example |
|----------|-----------|---------|
| Gradle module | kebab-case, `core-` prefix for libraries | `core-domain`, `core-data` |
| Screen composable | `{Feature}Screen` (stateful) / `{Feature}Content` (stateless) | `ScanResultScreen`, `ScanResultContent` |
| ViewModel | `{Feature}ViewModel` | `ScanResultViewModel` |
| UI state | `{Feature}UiState` | `ScanResultUiState` |
| Route | `@Serializable` object or data class named `{Feature}Route` | `AppDetailRoute(packageName)` |
| Use case | verb phrase, `operator fun invoke` | `ScanDevice`, `MarkAppTrusted` |
| Port (domain interface) | noun, no `I` prefix | `AppInventory`, `ScanRepository` |
| Adapter | technology + port | `PackageManagerAppInventory`, `RoomScanRepository` |
| Room entity / DAO | `{Thing}Entity` / `{Thing}Dao` | `ScanRunEntity`, `ScanRunDao` |
| Worker | `{Purpose}Worker` | `PeriodicScanWorker` |
| Hilt module | `{Scope}Module` | `DataModule`, `DetectionModule` |
| String resource | `snake_case`, prefixed by screen | `scan_result_title` |

---

## Gradle

Versions live only in the catalog. Module build files reference aliases.

```toml
# gradle/libs.versions.toml
[versions]
kotlin = "2.x.x"
agp = "9.x.x"
ksp = "2.x.x-x.x.x"
composeBom = "20xx.xx.xx"
hilt = "2.x"
room = "2.x.x"

[libraries]
androidx-compose-bom = { group = "androidx.compose", name = "compose-bom", version.ref = "composeBom" }
androidx-compose-material3 = { group = "androidx.compose.material3", name = "material3" }
hilt-android = { group = "com.google.dagger", name = "hilt-android", version.ref = "hilt" }
hilt-compiler = { group = "com.google.dagger", name = "hilt-compiler", version.ref = "hilt" }
room-runtime = { group = "androidx.room", name = "room-runtime", version.ref = "room" }
room-ktx = { group = "androidx.room", name = "room-ktx", version.ref = "room" }
room-compiler = { group = "androidx.room", name = "room-compiler", version.ref = "room" }

[plugins]
android-application = { id = "com.android.application", version.ref = "agp" }
android-library = { id = "com.android.library", version.ref = "agp" }
kotlin-jvm = { id = "org.jetbrains.kotlin.jvm", version.ref = "kotlin" }
kotlin-compose = { id = "org.jetbrains.kotlin.plugin.compose", version.ref = "kotlin" }
ksp = { id = "com.google.devtools.ksp", version.ref = "ksp" }
hilt = { id = "com.google.dagger.hilt.android", version.ref = "hilt" }
```

```kotlin
// core-domain/build.gradle.kts — pure Kotlin, no Android plugin
plugins {
    alias(libs.plugins.kotlin.jvm)
}

kotlin { jvmToolchain(libs.versions.jdk.get().toInt()) }

dependencies {
    implementation(libs.kotlinx.coroutines.core)
    testImplementation(libs.junit.jupiter)
}

tasks.withType<Test> { useJUnitPlatform() }
```

```kotlin
// core-data/build.gradle.kts — Android library (AGP 9: no kotlin-android plugin)
plugins {
    alias(libs.plugins.android.library)
    alias(libs.plugins.ksp)
    alias(libs.plugins.hilt)
}

android {
    namespace = "com.example.app.core.data"
    compileSdk = libs.versions.compileSdk.get().toInt()
    defaultConfig { minSdk = libs.versions.minSdk.get().toInt() }
}

kotlin { jvmToolchain(libs.versions.jdk.get().toInt()) }

dependencies {
    implementation(project(":core-domain"))
    implementation(libs.room.runtime)
    implementation(libs.room.ktx)
    ksp(libs.room.compiler)
    implementation(libs.hilt.android)
    ksp(libs.hilt.compiler)
}
```

Use the real version numbers already in the project's catalog. When a library is missing, add it to the catalog first, then reference the alias.

### Built-in Kotlin (AGP 9)

AGP 9 compiles Kotlin itself and enables this by default:

- Android modules apply only `com.android.application` or `com.android.library`. **Do not apply `org.jetbrains.kotlin.android`**
- `org.jetbrains.kotlin.kapt` is incompatible with built-in Kotlin. Use KSP for Room and Hilt
- The Kotlin version comes from the Kotlin Gradle plugin on the build classpath. Declaring `kotlin-jvm` with `apply false` in the root build file, as the pure Kotlin module needs anyway, sets it for every module
- Modules that use Compose still apply the Compose compiler plugin (`org.jetbrains.kotlin.plugin.compose`)
- Pure Kotlin modules are unchanged: they apply `kotlin-jvm`

A project still on AGP 8 keeps the `kotlin-android` plugin. Record which one applies in `.agent/SKILLS.md` → Project Overrides and do not mix the two.

### JDK

Pick one JDK version and use it in three places, all reading the same catalog entry:

- the Kotlin toolchain of every module (`jvmToolchain`)
- the Gradle daemon, pinned in `gradle/gradle-daemon-jvm.properties` (`toolchainVersion=<n>`)
- CI (`actions/setup-java`)

Static analysis plugins such as detekt run inside the Gradle daemon, so compiling with the right toolchain is not enough: a daemon on a newer JDK than the plugin supports fails with an error that does not name the cause. Prefer the JDK bundled with the current Android Studio over the newest release.

### `api` or `implementation` in library modules

A dependency whose types appear in the module's public API (a supertype, a constructor parameter, a return type) is `api`; everything else is `implementation`. An adapter that implements a `core-domain` port and takes a `CoroutineDispatcher` exposes both, so `core-domain` and `kotlinx-coroutines-core` are `api` there. With `implementation`, a consumer of the library does not compile until it declares them itself.

### Before adding or upgrading a build plugin

Check that the plugin supports the project's AGP, Kotlin, Gradle and JDK versions. If it does not run with them, stop and report it. Do not change another version, disable a check or add a workaround to make it pass.

---

## Domain Layer

Models are immutable. Ports are interfaces. Rules are pure and take every input as a parameter, including the clock.

```kotlin
// core-domain
data class InstalledApp(
    val packageName: String,
    val label: String,
    val installerPackage: String?,
    val firstInstallTime: Instant,
    val requestedPermissions: Set<String>,
)

enum class RiskLevel { GREEN, YELLOW, RED }

data class RiskResult(val score: Int, val level: RiskLevel, val signals: Set<Signal>)

interface AppInventory {
    suspend fun installedApps(): List<InstalledApp>
}

class RiskScorer(private val weights: ScoreWeights) {
    fun score(app: InstalledApp, signals: Set<Signal>, context: ScoringContext): RiskResult {
        val raw = signals.sumOf(weights::of).coerceAtMost(100)
        val adjusted = context.rules.fold(raw) { acc, rule -> rule.adjust(acc, app, signals) }
        return RiskResult(adjusted, RiskLevel.fromScore(adjusted), signals)
    }
}
```

Expected failures are values, not exceptions:

```kotlin
sealed interface CardReadResult {
    data class Success(val applicationLabel: String, val lastFourDigits: String, val expiry: YearMonth) : CardReadResult
    data object UnsupportedCard : CardReadResult
    data object ConnectionLost : CardReadResult
}
```

---

## UI — Compose

### Lint rules for composables

Composables are named in PascalCase (`ScanResultScreen`), which the default function-naming rules of ktlint and detekt reject. Exempt only functions annotated with `@Composable`; every other function stays checked.

```ini
# .editorconfig (repository root)
[*.{kt,kts}]
ktlint_function_naming_ignore_when_annotated_with = Composable
```

```yaml
# <module>/detekt.yml, applied with buildUponDefaultConfig = true
naming:
  FunctionNaming:
    ignoreAnnotated: ['Composable']
```

Do not silence the rule with `@Suppress` or by disabling it. When detekt's `MagicNumber` flags color literals, give each one a named `const val` in the theme's `Color.kt`.

Each screen has a stateful entry point that owns the ViewModel and a stateless content composable that is easy to preview and test.

```kotlin
sealed interface ScanResultUiState {
    data object Loading : ScanResultUiState
    data object Empty : ScanResultUiState
    data class Content(val risky: List<AppRiskItem>, val safeCount: Int) : ScanResultUiState
    data class Error(@StringRes val message: Int) : ScanResultUiState
}

@HiltViewModel
class ScanResultViewModel @Inject constructor(
    private val scanRepository: ScanRepository,
    private val scanDevice: ScanDevice,
) : ViewModel() {

    val uiState: StateFlow<ScanResultUiState> = scanRepository.latestReport()
        .map { report -> report?.toUiState() ?: ScanResultUiState.Empty }
        .catch { emit(ScanResultUiState.Error(R.string.scan_result_error)) }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), ScanResultUiState.Loading)

    fun onScanRequested() {
        viewModelScope.launch { scanDevice(ScanTrigger.MANUAL) }
    }
}

@Composable
fun ScanResultScreen(
    onAppClick: (String) -> Unit,
    viewModel: ScanResultViewModel = hiltViewModel(),
) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()
    ScanResultContent(uiState = uiState, onAppClick = onAppClick, onScanClick = viewModel::onScanRequested)
}

@Composable
fun ScanResultContent(
    uiState: ScanResultUiState,
    onAppClick: (String) -> Unit,
    onScanClick: () -> Unit,
    modifier: Modifier = Modifier,
) {
    when (uiState) {
        ScanResultUiState.Loading -> LoadingIndicator(modifier)
        ScanResultUiState.Empty -> EmptyState(onScanClick = onScanClick, modifier = modifier)
        is ScanResultUiState.Content -> RiskList(uiState.risky, onAppClick, modifier)
        is ScanResultUiState.Error -> ErrorState(message = stringResource(uiState.message), modifier = modifier)
    }
}
```

**Rules:**
- Every screen with data handles **loading, empty, content and error**
- Collect flows with `collectAsStateWithLifecycle()`, never `collectAsState()`
- All user-visible text comes from `strings.xml` through `stringResource`
- Meaning is never carried by color alone: pair color with an icon and text, and give icons a `contentDescription`
- The stateless `*Content` composable takes `modifier: Modifier = Modifier` as its last optional parameter
- One-off events (navigation, snackbars) are modelled as state that the UI consumes and acknowledges, not as a `SharedFlow` the UI might miss
- Components that pick their own colors (statuses, risk levels) read the theme's mode from a `CompositionLocal` provided by the app theme, never from `isSystemInDarkTheme()` directly: otherwise a theme forced to light or dark is ignored
- Call `enableEdgeToEdge()` in the Activity before `setContent`, and pad content with `safeDrawingPadding()`; from Android 15 with a recent `targetSdk` the system draws edge-to-edge anyway, so this keeps older versions consistent
- Set a window theme for light and dark (`res/values/themes.xml` and `res/values-night/themes.xml`), so the window does not flash white before Compose draws in dark mode

---

## Navigation

Type-safe routes with kotlinx.serialization. The `NavHost` is the only place that knows about `NavController`; screens receive lambdas.

```kotlin
@Serializable data object HomeRoute
@Serializable data class AppDetailRoute(val packageName: String)

@Composable
fun AppNavHost(navController: NavHostController = rememberNavController()) {
    NavHost(navController = navController, startDestination = HomeRoute) {
        composable<HomeRoute> {
            HomeScreen(onAppClick = { navController.navigate(AppDetailRoute(it)) })
        }
        composable<AppDetailRoute> {
            AppDetailScreen(onBack = navController::popBackStack)
        }
    }
}
```

The ViewModel reads route arguments with `savedStateHandle.toRoute<AppDetailRoute>()`.

---

## Dependency Injection — Hilt

Constructor injection everywhere. Modules only bind interfaces to implementations and provide types the project does not own.

```kotlin
@HiltAndroidApp
class ExampleApplication : Application(), Configuration.Provider {
    @Inject lateinit var workerFactory: HiltWorkerFactory

    override val workManagerConfiguration: Configuration
        get() = Configuration.Builder().setWorkerFactory(workerFactory).build()
}

@Module
@InstallIn(SingletonComponent::class)
abstract class DetectionModule {
    @Binds
    abstract fun bindAppInventory(impl: PackageManagerAppInventory): AppInventory
}

@Module
@InstallIn(SingletonComponent::class)
object DataModule {
    @Provides
    @Singleton
    fun provideDatabase(@ApplicationContext context: Context): AppDatabase =
        Room.databaseBuilder(context, AppDatabase::class.java, "app.db").build()

    @Provides
    fun provideScanRunDao(database: AppDatabase): ScanRunDao = database.scanRunDao()

    @Provides
    fun provideClock(): Clock = Clock.systemUTC()
}
```

Pure domain classes (`RiskScorer`) have no Hilt annotations: provide them from a module in the Android module that uses them.

Keep Room and DataStore as `implementation` dependencies of the data module. Hilt still assembles the whole graph in `app`, but the `app` module cannot see those types, so the test that injects the database, the DAOs and the `DataStore` lives in the data module (see `testing.md` → Hilt graph). Do not turn them into `api` just to test from `app`.

---

## Persistence — Room

Entities are persistence shapes, separate from domain models. DAOs return `Flow` for reads the UI observes and are `suspend` for writes.

```kotlin
@Entity(tableName = "scan_run")
data class ScanRunEntity(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val startedAt: Long,
    val finishedAt: Long,
    val trigger: String,
    val totalApps: Int,
)

@Dao
interface ScanRunDao {
    @Query("SELECT * FROM scan_run ORDER BY startedAt DESC LIMIT 1")
    fun observeLatest(): Flow<ScanRunEntity?>

    @Insert
    suspend fun insert(run: ScanRunEntity): Long

    @Query("DELETE FROM scan_run WHERE id NOT IN (SELECT id FROM scan_run ORDER BY startedAt DESC LIMIT :keep)")
    suspend fun deleteOlderThanLatest(keep: Int)
}

@Database(entities = [ScanRunEntity::class, AppSnapshotEntity::class], version = 1, exportSchema = true)
abstract class AppDatabase : RoomDatabase() {
    abstract fun scanRunDao(): ScanRunDao
}

class RoomScanRepository @Inject constructor(
    private val database: AppDatabase,
    private val scanRunDao: ScanRunDao,
    private val snapshotDao: AppSnapshotDao,
) : ScanRepository {
    override suspend fun save(report: ScanReport) = database.withTransaction {
        val scanId = scanRunDao.insert(report.toEntity())
        snapshotDao.insertAll(report.apps.map { it.toEntity(scanId) })
    }
}
```

**Rules:**
- `exportSchema = true` and the schema JSON files are committed
- Every version bump ships a `Migration` and a migration test
- Multi-table writes run inside `withTransaction`
- Repositories map entities to domain models; entities never reach a ViewModel
- Room and Hilt use KSP only; `kapt` does not work with AGP 9's built-in Kotlin

### Schema files

Apply the Room Gradle plugin so the schema is exported to a fixed folder, and commit what it generates:

```kotlin
// core-data/build.gradle.kts
plugins {
    alias(libs.plugins.android.library)
    alias(libs.plugins.ksp)
    alias(libs.plugins.room)
}

room { schemaDirectory("$projectDir/schemas") }
```

The build **rewrites** the JSON of the current version every time. A migration test therefore compares the code with itself and cannot catch an entity that changed without a version bump. What catches it is a CI step after the build that fails when the build changed the schema folder. Use `git status`, not `git diff`, so a new `N.json` that was never committed is caught too:

```yaml
- name: Room schema committed
  run: |
    CHANGED=$(git status --porcelain -- core-data/schemas)
    if [ -n "$CHANGED" ]; then
      echo "$CHANGED"
      echo "The build regenerated the Room schema. Commit it together with the entity change."
      exit 1
    fi
```

Decide when a schema version is frozen and record it in the project's decisions. Before the first public release no device has the database, so version 1 may still change with its JSON committed and no migration. From the first release on, a published `N.json` never changes: any change is a new version with a `Migration` and a test, and CI should reject edits to a published `N.json`.

### DataStore

Settings and flags go in Preferences DataStore behind a repository interface defined in `core-domain`. Exactly one `DataStore` instance per file: provide it as a `@Singleton`; two instances on the same file corrupt each other and throw.

Reads catch `IOException` and emit empty preferences, so the defaults apply when the file cannot be read. Rethrow anything else.

```kotlin
class DataStoreSettingsRepository @Inject constructor(
    private val dataStore: DataStore<Preferences>,
) : SettingsRepository {
    override val monitoringEnabled: Flow<Boolean> =
        dataStore.data
            .catch { if (it is IOException) emit(emptyPreferences()) else throw it }
            .map { it[MONITORING_ENABLED] ?: true }

    override suspend fun setMonitoringEnabled(enabled: Boolean) {
        dataStore.edit { it[MONITORING_ENABLED] = enabled }
    }

    private companion object {
        val MONITORING_ENABLED = booleanPreferencesKey("monitoring_enabled")
    }
}
```

---

## Background Work — WorkManager

Deferrable and periodic work uses WorkManager. A worker is a thin shell that calls a use case.

```kotlin
@HiltWorker
class PeriodicScanWorker @AssistedInject constructor(
    @Assisted context: Context,
    @Assisted params: WorkerParameters,
    private val scanDevice: ScanDevice,
    private val notifier: RiskNotifier,
) : CoroutineWorker(context, params) {

    override suspend fun doWork(): Result = try {
        val report = scanDevice(ScanTrigger.PERIODIC)
        notifier.notifyNewRisks(report)
        Result.success()
    } catch (e: CancellationException) {
        throw e
    } catch (e: Exception) {
        if (runAttemptCount < MAX_ATTEMPTS) Result.retry() else Result.failure()
    }

    companion object {
        const val UNIQUE_NAME = "periodic-scan"
        private const val MAX_ATTEMPTS = 3
    }
}

class ScanScheduler @Inject constructor(private val workManager: WorkManager) {
    fun schedule(intervalHours: Long) {
        val request = PeriodicWorkRequestBuilder<PeriodicScanWorker>(intervalHours, TimeUnit.HOURS).build()
        workManager.enqueueUniquePeriodicWork(
            PeriodicScanWorker.UNIQUE_NAME,
            ExistingPeriodicWorkPolicy.UPDATE,
            request,
        )
    }

    fun cancel() = workManager.cancelUniqueWork(PeriodicScanWorker.UNIQUE_NAME)
}
```

Periodic work has a 15-minute minimum interval and the system may delay it. Anything the user must see promptly is also computed when the app opens.

---

## Permissions and Manifest

- Declare only the permissions the feature needs. Each new `<uses-permission>` is named in the spec and in the PR description
- Hardware the app can work without is declared `android:required="false"`, and the code checks for it at runtime
- Runtime permissions are requested in context, right before the feature that needs them, with `rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission())`. A denial never blocks the rest of the app
- Components are `android:exported="false"` unless another app must start them
- Libraries add permissions and components to the merged manifest (AndroidX core, profileinstaller, startup, WorkManager, Room). Check the merged manifest whenever a dependency is added, and enforce an allowlist with a test (see `testing.md` → Manifest and Privacy Checks)

- Library modules declare no permissions. A permission in a library manifest is merged silently into every app that uses it, which matters most for a module meant to become an SDK. Restricted permissions such as `QUERY_ALL_PACKAGES` go in the app manifest, the library README tells integrators to declare it (or a `<queries>` element), and a test checks the library's merged manifest (with `unitTests.isIncludeAndroidResources = true`, or Robolectric does not see it)
- When lint flags a permission the app genuinely needs (`QueryAllPackagesPermission`), suppress it on that element with `tools:ignore` and an XML comment that gives the reason. No module-wide `lint.xml` for it

```xml
<uses-permission android:name="android.permission.NFC" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-feature android:name="android.hardware.nfc" android:required="false" />
```

---

## Reading installed packages

- Fetch in two steps: a light list with flags `0`, filtered there, then `getPackageInfo` with `GET_PERMISSIONS`, `GET_SERVICES` and `MATCH_DISABLED_COMPONENTS` for each package kept. Each call carries one app, and system apps, usually the majority, are never loaded in full
- System apps are those with `FLAG_SYSTEM` or `FLAG_UPDATED_SYSTEM_APP`. An update to a preinstalled app must carry the original signature, so a sideloaded APK cannot pass as one
- Exclude the calling app's own package
- Include disabled services, and check that a fully disabled user app still appears in the light list
- A package that disappears between the list and the detail (`NameNotFoundException`) is skipped. Other `PackageManager` errors are propagated
- Version branches (`longVersionCode` from API 28, `getInstallSourceInfo().installingPackageName` from 30 in place of `getInstallerPackageName`, `PackageInfoFlags` from 33) live in one `internal` file of extension functions. `@Suppress("DEPRECATION")` is allowed only on the old branch of an `SDK_INT` check whose other branch uses the replacement

## Dispatchers in adapters

- An adapter that blocks (package queries, files, NFC I/O) takes a `CoroutineDispatcher` in its constructor and runs the work in `withContext(dispatcher)`. Hilt provides it through a qualifier; tests pass the `runTest` dispatcher
- Loops over many items call `ensureActive()` on each item, so a cancelled scan stops early
- A constructor that takes a `Context` keeps only what it needs (`packageManager`, `packageName`), never the `Context` itself

---

## Error Handling

- Expected outcomes (no hardware, unsupported input, empty result) are modelled as sealed results in `core-domain` and mapped to a `UiState`
- Adapters catch the platform exceptions they know (`IOException`, `SecurityException`, `TagLostException`) and return a domain result. They never swallow `CancellationException`
- ViewModels turn unexpected failures into `UiState.Error` with a string resource. Raw exception messages are never shown to the user
- No `try/catch` in composables

---

## Configuration

- Build-time constants go in `buildConfigField` or resources, per build type or flavor. No secrets in the repository
- Tunable business values (weights, thresholds, intervals, allow-lists) live in one file in `core-domain` or in a bundled resource, not scattered as literals
- `release` builds enable R8 (`isMinifyEnabled = true`) and keep rules live in each module's `consumer-rules.pro`

---

## Security and Privacy

- Never log personal or sensitive data (card numbers, tokens, message contents, full package lists). Sensitive values are masked in the adapter that reads them and never leave it in full
- Sensitive values are not written to Room, DataStore, `SavedStateHandle`, crash reports or analytics
- Screens that show sensitive data set `WindowManager.LayoutParams.FLAG_SECURE`
- If the product promises offline or local-only behaviour, the manifest must not declare `android.permission.INTERNET`, and a test enforces it
- An app that keeps sensitive data on the device turns backup off. `android:allowBackup="false"` alone is not enough: from `targetSdk` 31, some devices still run device-to-device transfer. Add `android:dataExtractionRules` excluding every domain in `<cloud-backup>` and `<device-transfer>`, and `android:fullBackupContent` excluding them for Android 11 and lower. A test reads both XML files, and a CI step checks that the three attributes are in the manifest, because the rule files are not readable through public APIs

```xml
<application
    android:allowBackup="false"
    android:dataExtractionRules="@xml/data_extraction_rules"
    android:fullBackupContent="@xml/full_backup_content">
```

```xml
<!-- res/xml/data_extraction_rules.xml -->
<data-extraction-rules>
    <cloud-backup>
        <exclude domain="root" path="." />
        <exclude domain="file" path="." />
        <exclude domain="database" path="." />
        <exclude domain="sharedpref" path="." />
        <exclude domain="external" path="." />
        <exclude domain="device_root" path="." />
        <exclude domain="device_file" path="." />
        <exclude domain="device_database" path="." />
        <exclude domain="device_sharedpref" path="." />
    </cloud-backup>
    <device-transfer>
        <!-- the same nine excludes -->
    </device-transfer>
</data-extraction-rules>
```

---

## Specs for Android features

Android features are not HTTP endpoints. In the feature spec (`.spec.toon`), set `feature.interface` and fill `status` as `specs/feature.schema.md` defines:

| The feature is | `interface` | `status` holds |
|----------------|-------------|----------------|
| A screen or user interaction | `ui` | the `UiState` case shown (`Content`, `Empty`, `Error`) |
| A use case, collector, parser or repository | `library` | the result type returned (`Success`, `UnsupportedCard`) |
| A worker or scheduled job | `background` | the worker outcome (`Success`, `Retry`, `Failure`) |
| The build, a Gradle task or CI | `command` | the exit code (`0`, `1`) |

Use the names the code uses, so a spec error maps to one sealed result subtype or one `UiState` case. The architecture contract lists Gradle modules and files, not endpoints.

---

## Testing

See `testing.md` for the full testing guide. Quick rules:

- `core-domain`: JUnit 5 on the JVM, no Robolectric, no mocks of domain types
- ViewModels: JUnit + MockK + Turbine + `kotlinx-coroutines-test`, with a main-dispatcher rule
- Adapters and Room: Robolectric or instrumented tests with JUnit 4
- Screens: Compose UI tests against the stateless `*Content` composable, one test per `UiState`
- **Minimum coverage**: 80% on `core-domain`

---

## What NOT to do

- ❌ `android.*` or `androidx.*` imports in `core-domain`
- ❌ Business rules in composables, ViewModels, workers or DAOs
- ❌ Calling repositories, DAOs or platform APIs from a composable
- ❌ `GlobalScope`, `runBlocking` in production code, or a `CoroutineScope` created by hand inside a ViewModel
- ❌ `collectAsState()` for flows that outlive the screen — use `collectAsStateWithLifecycle()`
- ❌ Hard-coded user-visible strings, or version numbers outside `libs.versions.toml`
- ❌ `!!` — use `?:` with a domain result or `requireNotNull` with a message
- ❌ Passing `Context`, `NavController` or a ViewModel down the composable tree
- ❌ `fallbackToDestructiveMigration()` in a release build
- ❌ Foreground services or exact alarms for work that WorkManager can defer
- ❌ Catching `Exception` without rethrowing `CancellationException`
- ❌ Adding a permission, a dependency or an exported component that the spec does not name
- ❌ Applying `org.jetbrains.kotlin.android` or `kapt` on AGP 9
- ❌ HTTP statuses in the spec of a screen, use case or worker — set `feature.interface`
- ❌ Changing a version or disabling a check to make an incompatible plugin run
- ❌ `@Suppress` or a disabled rule to get composables past ktlint or detekt — exempt `@Composable` in the config
- ❌ Reading `isSystemInDarkTheme()` inside a component instead of the mode the app theme provides
- ❌ Two `DataStore` instances for the same file, or reading `dataStore.data` without handling `IOException`
- ❌ Trusting the migration test alone to catch schema changes — the build rewrites the current schema; check it in CI
- ❌ Relying on `allowBackup="false"` alone to keep data on the device
