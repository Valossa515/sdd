---
name: android-testing
description: Testing guide for Android projects. JVM unit tests for the pure Kotlin domain, ViewModel tests with MockK, Turbine and coroutines-test, Robolectric tests for adapters and Room, Compose UI tests, and WorkManager tests.
stack: android
versions: "Kotlin 2.x, AGP 9.x, JUnit 5 (JVM modules), JUnit 4 (Android modules), MockK, Turbine, kotlinx-coroutines-test, Robolectric, Compose UI Test, work-testing"
---

# Android Testing

## Which runner where

Android test tooling is split between two JUnit generations. Keep them apart by module:

| Module type | Runner | Why |
|-------------|--------|-----|
| Pure Kotlin (`core-domain`) | JUnit 5 | No Android dependency, runs on the JVM |
| Android library and `app`, local tests (`src/test`) | JUnit 4 | Robolectric and the AndroidX test rules are JUnit 4 |
| Instrumented tests (`src/androidTest`) | JUnit 4 (`AndroidJUnitRunner`) | Required by the instrumentation runner |

Do not mix JUnit 5 annotations into a Robolectric or instrumented test class.

---

## Dependencies (build.gradle.kts)

```kotlin
// core-domain
dependencies {
    testImplementation(libs.junit.jupiter)
    testImplementation(libs.kotlinx.coroutines.test)
}
tasks.withType<Test> { useJUnitPlatform() }
```

```kotlin
// Android modules
android {
    testOptions { unitTests.isIncludeAndroidResources = true }
}

dependencies {
    testImplementation(libs.junit4)
    testImplementation(libs.mockk)
    testImplementation(libs.turbine)
    testImplementation(libs.kotlinx.coroutines.test)
    testImplementation(libs.robolectric)
    testImplementation(libs.androidx.test.core)
    testImplementation(libs.androidx.room.testing)
    testImplementation(libs.androidx.work.testing)
    testImplementation(libs.hilt.android.testing)
    kspTest(libs.hilt.compiler)

    // Compose UI tests on the JVM (Robolectric) — see "Compose UI Tests"
    testImplementation(platform(libs.androidx.compose.bom))
    testImplementation(libs.androidx.compose.ui.test.junit4)
}
```

Do not add `ui-test-manifest`. In `debugImplementation` it merges an exported test `ComponentActivity` into the debug APK, and in `testImplementation` it does not reach the Robolectric manifest. The Compose section shows the setup that needs neither.

---

## Unit Tests — Domain

Pure functions, real objects, no mocks. Inject the clock and every other source of non-determinism.

```kotlin
class RiskScorerTest {

    private val scorer = RiskScorer(ScoreWeights.default())
    private val context = ScoringContext(rules = AdjustmentRules.default(), trustedPackages = emptySet())

    @Test
    fun `sideloaded app with NFC and card emulation is red`() {
        val app = anInstalledApp(installerPackage = null)

        val result = scorer.score(app, setOf(Signal.SIDELOADED, Signal.NFC_PERMISSION, Signal.CARD_EMULATION), context)

        assertEquals(65, result.score)
        assertEquals(RiskLevel.RED, result.level)
    }

    @Test
    fun `store app is capped at green even with NFC signals`() {
        val app = anInstalledApp(installerPackage = "com.android.vending")

        val result = scorer.score(app, setOf(Signal.NFC_PERMISSION, Signal.CARD_EMULATION), context)

        assertEquals(RiskLevel.GREEN, result.level)
    }
}
```

Every business rule in a spec's acceptance criteria gets a test here, named after the rule.

---

## ViewModel Tests

Replace the main dispatcher, mock the ports and assert on the emitted states with Turbine.

```kotlin
// src/test/kotlin/.../support/MainDispatcherRule.kt
class MainDispatcherRule(
    private val dispatcher: TestDispatcher = UnconfinedTestDispatcher(),
) : TestWatcher() {
    override fun starting(description: Description) = Dispatchers.setMain(dispatcher)
    override fun finished(description: Description) = Dispatchers.resetMain()
}
```

```kotlin
class ScanResultViewModelTest {

    @get:Rule val mainDispatcherRule = MainDispatcherRule()

    private val scanRepository = mockk<ScanRepository>()
    private val scanDevice = mockk<ScanDevice>(relaxed = true)

    @Test
    fun `emits content when a report exists`() = runTest {
        every { scanRepository.latestReport() } returns flowOf(aScanReport(redApps = 1))
        val viewModel = ScanResultViewModel(scanRepository, scanDevice)

        viewModel.uiState.test {
            val state = expectMostRecentItem()
            assertTrue(state is ScanResultUiState.Content)
            assertEquals(1, (state as ScanResultUiState.Content).risky.size)
        }
    }

    @Test
    fun `emits empty when there is no report yet`() = runTest {
        every { scanRepository.latestReport() } returns flowOf(null)
        val viewModel = ScanResultViewModel(scanRepository, scanDevice)

        viewModel.uiState.test {
            assertEquals(ScanResultUiState.Empty, expectMostRecentItem())
        }
    }
}
```

---

## Adapter Tests — Robolectric

Adapters that wrap platform APIs are tested against Robolectric shadows, so the real query code runs.

```kotlin
@RunWith(RobolectricTestRunner::class)
class PackageManagerAppInventoryTest {

    private val context: Context = ApplicationProvider.getApplicationContext()
    private val shadowPackageManager = shadowOf(context.packageManager)

    @Test
    fun `returns user apps and skips system apps`() = runTest {
        shadowPackageManager.installPackage(aPackageInfo("com.example.user", system = false))
        shadowPackageManager.installPackage(aPackageInfo("com.example.system", system = true))

        val apps = PackageManagerAppInventory(context).installedApps()

        assertEquals(listOf("com.example.user"), apps.map { it.packageName })
    }
}
```

Behaviour that depends on the API level is tested once per branch with `@Config(sdk = [...])`.

---

## Room Tests

An in-memory database with the real DAOs. Migrations are tested with `MigrationTestHelper` against the exported schemas.

```kotlin
@RunWith(RobolectricTestRunner::class)
class ScanRunDaoTest {

    private lateinit var database: AppDatabase
    private lateinit var dao: ScanRunDao

    @Before
    fun setUp() {
        database = Room.inMemoryDatabaseBuilder(ApplicationProvider.getApplicationContext(), AppDatabase::class.java)
            .allowMainThreadQueries()
            .build()
        dao = database.scanRunDao()
    }

    @After
    fun tearDown() = database.close()

    @Test
    fun `deleteOlderThanLatest keeps only the newest runs`() = runTest {
        repeat(12) { dao.insert(aScanRunEntity(startedAt = it.toLong())) }

        dao.deleteOlderThanLatest(keep = 10)

        assertEquals(11L, dao.observeLatest().first()?.startedAt)
        assertEquals(10, database.query("SELECT * FROM scan_run", null).count)
    }
}
```

Test the constraints the schema promises, not only the happy path: a duplicate primary key and an orphan foreign key throw `SQLiteConstraintException`, and deleting a parent row removes the children when the foreign key cascades. If the DAOs have no delete operation, delete the parent with SQL in the test (`database.openHelper.writableDatabase.execSQL(...)`) instead of adding a DAO method only for the test.

### Migration tests on the JVM

Room's Gradle plugin puts the exported schemas only in the instrumented-test assets. For local Robolectric tests, add them to the unit-test assets with the non-deprecated AGP 9 API:

```kotlin
// core-data/build.gradle.kts
android {
    sourceSets.getByName("test").assets.directories.add("$projectDir/schemas")
}
```

Use the `MigrationTestHelper` constructor that takes a file and a driver. Under Robolectric, the older `(instrumentation, Database::class.java)` constructor fails with "This driver is configured to open a database named ... but ... was requested".

```kotlin
@RunWith(RobolectricTestRunner::class)
class AppDatabaseMigrationTest {

    private val file = ApplicationProvider.getApplicationContext<Context>().getDatabasePath("migration-test.db")

    @get:Rule
    val helper = MigrationTestHelper(
        instrumentation = InstrumentationRegistry.getInstrumentation(),
        file = file,
        driver = AndroidSQLiteDriver(),
        databaseClass = AppDatabase::class,
    )

    @Test
    fun `version 1 is created and validated from the exported schema`() {
        helper.createDatabase(1).close()
        helper.runMigrationsAndValidate(1, emptyList()).close()
    }
}
```

The test validates the schema JSON, but the build rewrites that JSON for the current version, so it does not catch an entity change without a version bump. A CI step does (see `SKILL.md` → Schema files).

### Hilt graph

Test the graph in the module that owns the types, with `@HiltAndroidTest` and `HiltTestApplication`. Inject every binding someone will use, including classes with an `@Inject` constructor that no module provides: Hilt only validates bindings that are requested.

```kotlin
@HiltAndroidTest
@RunWith(RobolectricTestRunner::class)
@Config(application = HiltTestApplication::class)
class DataModuleTest {

    @get:Rule val hiltRule = HiltAndroidRule(this)

    @Inject lateinit var database: AppDatabase
    @Inject lateinit var settings: SettingsDataSource

    @Test
    fun `graph provides the database and the settings source`() {
        hiltRule.inject()
        assertNotNull(database.scanRunDao())
        assertNotNull(settings)
    }
}
```

### DataStore

Test a `DataStore` source with a real `DataStore` on a temporary file, created with `PreferenceDataStoreFactory.create(scope) { file }`. Do not fake the store.

On Windows, a second write to the same `DataStore` file fails in JVM tests with "Unable to rename ... .preferences_pb.tmp": the JVM cannot rename the temporary file over the existing one. Android and Linux are not affected. Skip only the tests that write more than once on Windows, explain why in the test, and let CI on Linux run them:

```kotlin
@Test
fun `written values are read back`() = runTest {
    // Windows JVM cannot rename DataStore's temp file over the existing one; CI (Linux) runs this test
    assumeFalse(System.getProperty("os.name").startsWith("Windows"))
    ...
}
```

A skipped test does not fail the build, so confirm in CI that it ran. Publishing the test reports as a CI artifact (`*/build/reports/tests/`, with `if: always()`) shows the run, failure and skip counts per class.

---

## Compose UI Tests

Test the stateless `*Content` composable: one test per `UiState`, plus the callbacks. No ViewModel, no Hilt. Compose tests run on the JVM with Robolectric, in `src/test`, so they run in `./gradlew build` and in CI without a device.

`createComposeRule()` needs a host `ComponentActivity` declared in the manifest, which only `ui-test-manifest` provides. Instead, start a plain `ComponentActivity` with Robolectric and use `createEmptyComposeRule()`. The debug APK stays free of test components.

```kotlin
@RunWith(RobolectricTestRunner::class)
class ScanResultContentTest {

    @get:Rule val composeRule = createEmptyComposeRule()

    private fun setContent(content: @Composable () -> Unit) {
        Robolectric.buildActivity(ComponentActivity::class.java).setup().get().setContent(content = content)
    }

    @Test
    fun `shows risky apps and reports clicks`() {
        var clicked: String? = null
        setContent {
            AppTheme {
                ScanResultContent(
                    uiState = ScanResultUiState.Content(risky = listOf(anAppRiskItem("com.example.decoy")), safeCount = 3),
                    onAppClick = { clicked = it },
                    onScanClick = {},
                )
            }
        }

        composeRule.onNodeWithText("Decoy app").assertIsDisplayed().performClick()

        assertEquals("com.example.decoy", clicked)
    }

    @Test
    @Config(qualifiers = "+night")
    fun `shows empty state before the first scan in dark mode`() {
        setContent {
            AppTheme { ScanResultContent(ScanResultUiState.Empty, onAppClick = {}, onScanClick = {}) }
        }

        composeRule.onNodeWithTag("empty-state").assertIsDisplayed()
    }
}
```

Prefer finders a user would recognise (`onNodeWithText`, `onNodeWithContentDescription`). Use `testTag` only when there is no stable text. Run the same test in light and dark mode with `@Config(qualifiers = "+night")`.

### Navigation

Test the graph through the real Activity with `createAndroidComposeRule<MainActivity>()`: click by the label a user sees and check the destination by its title, one test per edge. Check the back stack by observable behaviour instead of adding `navigation-testing`: after a screen is popped, pressing back from the next one finishes the Activity.

```kotlin
@RunWith(RobolectricTestRunner::class)
class AppNavHostTest {

    @get:Rule val composeRule = createAndroidComposeRule<MainActivity>()

    @Test
    fun `onboarding leaves the back stack`() {
        composeRule.onNodeWithText("Start").performClick()
        composeRule.onNodeWithText("Home").assertIsDisplayed()

        composeRule.activityRule.scenario.onActivity { it.onBackPressedDispatcher.onBackPressed() }

        assertTrue(composeRule.activity.isFinishing)
    }
}
```

### Colors and contrast

Color choices that carry meaning (risk levels, statuses) live in a pure function of the theme, so they are tested on the JVM without rendering. Assert that each meaningful color differs from the others and that every text/background pair meets WCAG AA (4.5:1). Do not compare pixels: it is slow and brittle.

```kotlin
class RiskLevelColorsTest {

    @Test
    fun `every level meets AA contrast in light and dark mode`() {
        for (dark in listOf(false, true)) {
            for (level in RiskLevelUi.entries) {
                val colors = riskLevelColors(level, dark)
                assertTrue("$level dark=$dark", contrast(colors.content, colors.container) >= 4.5)
            }
        }
    }

    private fun contrast(a: Color, b: Color): Double {
        val (light, dark) = listOf(a.luminance(), b.luminance()).sortedDescending()
        return (light + 0.05) / (dark + 0.05)
    }
}
```

---

## WorkManager Tests

Run the worker directly with `TestListenableWorkerBuilder` and a factory that supplies its dependencies.

```kotlin
@RunWith(RobolectricTestRunner::class)
class PeriodicScanWorkerTest {

    private val context: Context = ApplicationProvider.getApplicationContext()
    private val scanDevice = mockk<ScanDevice>()
    private val notifier = mockk<RiskNotifier>(relaxed = true)

    private fun buildWorker() = TestListenableWorkerBuilder<PeriodicScanWorker>(context)
        .setWorkerFactory(object : WorkerFactory() {
            override fun createWorker(appContext: Context, workerClassName: String, params: WorkerParameters) =
                PeriodicScanWorker(appContext, params, scanDevice, notifier)
        })
        .build()

    @Test
    fun `scans and notifies on success`() = runTest {
        val report = aScanReport(redApps = 1)
        coEvery { scanDevice(ScanTrigger.PERIODIC) } returns report

        val result = buildWorker().doWork()

        assertEquals(ListenableWorker.Result.success(), result)
        verify { notifier.notifyNewRisks(report) }
    }
}
```

---

## Manifest and Privacy Checks

Promises the product makes about permissions and exported components are enforced by tests against the merged manifest, not by convention. Robolectric's `PackageManager` returns the merged manifest, so libraries that add permissions or components are caught too.

Check an **allowlist**, not a denylist: a test that only forbids `INTERNET` lets every other new permission through.

```kotlin
@RunWith(RobolectricTestRunner::class)
class MergedManifestTest {

    private val context: Context = ApplicationProvider.getApplicationContext()

    @Test
    fun `requested permissions are within the explicit allowlist`() {
        val allowed = setOf(
            "android.permission.NFC",
            "android.permission.POST_NOTIFICATIONS",
            // Added by androidx.core; signature-level, only this app holds it
            "${context.packageName}.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION",
        )

        val requested = context.packageManager
            .getPackageInfo(context.packageName, PackageManager.GET_PERMISSIONS)
            .requestedPermissions?.toSet().orEmpty()

        val notAllowed = requested - allowed
        assertTrue("Permissions outside the allowlist: $notAllowed", notAllowed.isEmpty())
    }

    @Test
    fun `main activity is the only exported activity`() {
        val exported = context.packageManager
            .getPackageInfo(context.packageName, PackageManager.GET_ACTIVITIES)
            .activities.orEmpty()
            .filter { it.exported }
            .map { it.name }

        assertEquals(listOf(MainActivity::class.java.name), exported)
    }
}
```

When a dependency adds a permission or component, the test fails. Accept it only with a recorded decision (in `.agent/SKILLS.md` → Project Overrides) and update the allowlist in the same change.

---

## Test Fixtures

Top-level factory functions with default arguments; each test overrides only what it cares about. Fixtures for domain models live in `core-domain`'s test fixtures so every module reuses them.

```kotlin
fun anInstalledApp(
    packageName: String = "com.example.app",
    label: String = "Example",
    installerPackage: String? = "com.android.vending",
    firstInstallTime: Instant = Instant.parse("2026-01-01T00:00:00Z"),
    requestedPermissions: Set<String> = emptySet(),
) = InstalledApp(packageName, label, installerPackage, firstInstallTime, requestedPermissions)
```

Test data for sensitive values is always synthetic (documented test card numbers, made-up package names). Never paste real user data into a fixture.

---

## Naming Convention for Tests

JVM and Robolectric tests use backtick names that read as a sentence: `` `<unit> <does what> when <condition>` ``. Instrumented tests use camelCase, because backtick names with spaces are not valid on older Android runtimes.

```
`store app is capped at green even with NFC signals`
`emits empty when there is no report yet`
showsEmptyStateBeforeTheFirstScan
```

---

## What NOT to do

- ❌ Robolectric or mocks in `core-domain` tests — if a domain test needs them, the code is in the wrong module
- ❌ JUnit 5 annotations in Robolectric or instrumented test classes
- ❌ `runBlocking` or `Thread.sleep` in tests — use `runTest` and Turbine
- ❌ Testing a screen through its ViewModel and Hilt when the stateless `*Content` composable covers it
- ❌ Mocking `PackageManager`, `Context` or Room DAOs by hand — use Robolectric shadows and an in-memory database
- ❌ Reading `System.currentTimeMillis()` or `Instant.now()` in code under test — inject a `Clock`
- ❌ Real personal or card data in fixtures, snapshots or logs
- ❌ `ui-test-manifest` in any configuration — use `createEmptyComposeRule()` with an Activity started by Robolectric
- ❌ Comparing screenshot pixels to check a color — test the color function and the contrast instead
- ❌ A manifest test that only forbids specific permissions — check an allowlist
- ❌ The `(instrumentation, Database::class.java)` `MigrationTestHelper` constructor under Robolectric — use the file-and-driver constructor
- ❌ A fake `DataStore` in the tests of a `DataStore` source
- ❌ Making Room or DataStore `api` dependencies only to test the Hilt graph from `app`
- ❌ Skipping the migration test when the Room version changes
