---
name: android-testing
description: Testing guide for Android projects. JVM unit tests for the pure Kotlin domain, ViewModel tests with MockK, Turbine and coroutines-test, Robolectric tests for adapters and Room, Compose UI tests, and WorkManager tests.
stack: android
versions: "Kotlin 2.x, JUnit 5 (JVM modules), JUnit 4 (Android modules), MockK, Turbine, kotlinx-coroutines-test, Robolectric, Compose UI Test, work-testing"
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

    androidTestImplementation(platform(libs.androidx.compose.bom))
    androidTestImplementation(libs.androidx.compose.ui.test.junit4)
    debugImplementation(libs.androidx.compose.ui.test.manifest)
}
```

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

---

## Compose UI Tests

Test the stateless `*Content` composable: one test per `UiState`, plus the callbacks. No ViewModel, no Hilt.

```kotlin
class ScanResultContentTest {

    @get:Rule val composeRule = createComposeRule()

    @Test
    fun showsRiskyAppsAndReportsClicks() {
        var clicked: String? = null
        composeRule.setContent {
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
    fun showsEmptyStateBeforeTheFirstScan() {
        composeRule.setContent {
            AppTheme { ScanResultContent(ScanResultUiState.Empty, onAppClick = {}, onScanClick = {}) }
        }

        composeRule.onNodeWithTag("empty-state").assertIsDisplayed()
    }
}
```

Prefer finders a user would recognise (`onNodeWithText`, `onNodeWithContentDescription`). Use `testTag` only when there is no stable text.

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

Promises the product makes about permissions are enforced by tests against the merged manifest, not by convention.

```kotlin
@RunWith(RobolectricTestRunner::class)
class ManifestPermissionsTest {

    @Test
    fun `app does not request the internet permission`() {
        val context: Context = ApplicationProvider.getApplicationContext()
        val info = context.packageManager.getPackageInfo(context.packageName, PackageManager.GET_PERMISSIONS)

        assertFalse(info.requestedPermissions.orEmpty().contains(Manifest.permission.INTERNET))
    }
}
```

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
- ❌ Skipping the migration test when the Room version changes
