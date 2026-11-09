# Eala — Project Development Guidelines & Architecture

This README.md file must serve as the **primary development blueprint and architectural guideline** for this project.

Every developer and AI agent must carefully read and follow these instructions before making any changes or implementing new features.

All the following requirements must be followed consistently throughout the entire project.

## 1. State Management & Dependency Injection

- Use **Flutter BLoC** for state management throughout the application.
- Use **get_it** for dependency injection.
- All dependencies must be registered and accessed through get_it.
- Use the following command to generate dependency registrations:

  ```bash
  dart run build_runner build --delete-conflicting-outputs
  ```

- All dependency annotations must be configured to work correctly with the above command.
- Every BLoC, repository interface, repository implementation, and use case class must be registered using `@injectable`, `@LazySingleton(as: SomeClass)`, or the appropriate annotation.
- Make sure every required dependency can be resolved through get_it without manually creating instances.

### BLoC Instance Usage

Every BLoC instance must be accessed through the `instance` variable registered with get_it.

Always follow this pattern when providing a BLoC:

```dart
BlocProvider(
  create: (BuildContext context) => instance<LoginBloc>()..add(InitEvent()),
  child: _buildPage(context),
);
```

Do not manually instantiate BLoC classes using their constructors. All BLoC instances must be retrieved through `instance`.

## 2. Architecture & Project Structure

- Follow **Feature-Based Clean Architecture** throughout the project.
- Maintain a consistent folder structure for every feature.
- Do not introduce different architectural or coding structures for different features.
- Follow the architecture documented in [`docs/flutter-clean-architecture-bloc-bangla.md`](docs/flutter-clean-architecture-bloc-bangla.md).
- Before implementing any new feature, carefully review the existing architecture and follow the same conventions.

Every feature must follow the established Clean Architecture structure, including its presentation, domain, and data layers, with responsibilities separated appropriately.

The architecture and folder structure must remain consistent throughout the entire application.

### 2.1 Layers & the Dependency Rule

```text
┌─────────────────────────────────────┐
│         Presentation Layer          │  ← Page/Widget + BLoC (Event, State)
├─────────────────────────────────────┤
│            Domain Layer             │  ← Entity + Repository (abstract) + UseCase
├─────────────────────────────────────┤
│             Data Layer              │  ← Model + DataSource + Repository (impl)
└─────────────────────────────────────┘
```

Dependencies always point **inward, toward Domain**:

- Presentation → knows Domain only (never Data, never DataSources, never Supabase/drift).
- Data → knows Domain (implements its abstractions).
- **Domain knows nobody.** It is pure Dart: no Flutter imports, no `fromJson`, no Supabase/drift/Dio types.

| Layer | Contains | Depends on |
|---|---|---|
| Presentation | BLoC, Event, State, Page, feature widgets | Domain |
| Domain | Entity, Repository (abstract), UseCase | Nothing (pure Dart) |
| Data | Model, DataSource (remote/local), Repository (impl) | Domain |

### 2.2 Folder Structure (Feature-Based)

Every feature lives in its own folder under `lib/features/` and has its own `data/`, `domain/`, `presentation/`. Code shared by all features lives in `lib/core/`.

```text
lib/
├── core/
│   ├── error/
│   │   ├── failures.dart          ← Failure, ServerFailure, NetworkFailure, CacheFailure
│   │   └── exceptions.dart        ← ServerException, CacheException (thrown by DataSources)
│   ├── usecase/
│   │   └── usecase.dart           ← UseCase<Type, Params>, NoParams
│   ├── network/
│   ├── di/                        ← get_it `instance` + injectable config
│   ├── router/                    ← go_router (app_router.dart, route_names.dart)
│   ├── platform/                  ← native MethodChannel clients (alarm)
│   ├── database/                  ← drift AppDatabase + DatabaseModule
│   ├── theme/                     ← AppColor, AppTheme, Dimension
│   ├── constants/                 ← AppConstant
│   └── widgets/                   ← common reusable widgets
│
├── features/
│   └── <feature>/
│       ├── data/
│       │   ├── datasources/
│       │   │   ├── <feature>_remote_data_source.dart   ← Supabase calls
│       │   │   └── <feature>_local_data_source.dart    ← drift / secure storage
│       │   ├── models/
│       │   │   └── <name>_model.dart
│       │   └── repositories/
│       │       └── <feature>_repository_impl.dart
│       ├── domain/
│       │   ├── entities/
│       │   │   └── <name>_entity.dart
│       │   ├── repositories/
│       │   │   └── <feature>_repository.dart           ← abstraction
│       │   └── usecases/
│       │       └── <action>_usecase.dart
│       └── presentation/
│           ├── bloc/
│           │   ├── <feature>_bloc.dart
│           │   ├── <feature>_event.dart
│           │   └── <feature>_state.dart
│           ├── pages/
│           │   └── <name>_page.dart
│           └── widgets/                                ← feature-only widgets
│
└── main.dart
```

Adding a new feature (e.g. Profile, Chat) means adding a new folder under `features/` without touching other features.

### 2.3 Responsibilities of Each Piece

**Domain**
- **Entity** – the core business object. Only `final` fields and a `const` constructor. No JSON, no Flutter.
- **Repository (abstract)** – the contract: *what* can be done, not *how*. Every method returns `Future<Either<Failure, T>>`.
- **UseCase** – exactly one business action per class (`LoginUseCase`, `GetTodosUseCase`). Implements `UseCase<Type, Params>`, calls the repository abstraction and does not know whether data comes from the server or local DB. Use a `<Action>Params` class for inputs, or `NoParams` when there are none.

**Data**
- **Model** – `extends` the Entity and adds `fromJson()` / `toJson()` (and drift table mapping when needed).
- **DataSource** – where the real Supabase query / drift (SQLite) query happens. Returns Models and **throws** exceptions (`ServerException`, `CacheException`) on error — it never returns `Either`.
- **Repository (impl)** – implements the Domain abstraction. Calls DataSources, applies the local-first flow (section 4), catches exceptions and converts them to `Left(Failure)`; success goes to `Right(data)`.

**Presentation**
- **Event** – what the user did (`LoginButtonPressed`). Extends `Equatable`.
- **State** – what the UI shows (`Initial`, `Loading`, `Success`, `Failure`). Extends `Equatable`.
- **BLoC** – listens to Events, calls UseCases, `fold`s the `Either` result and emits States. It only knows UseCases — never repositories' implementations, DataSources, Supabase or drift.
- **Page/Widget** – renders from State via `BlocBuilder` / `BlocListener` / `BlocConsumer` and dispatches Events. No business logic in widgets.

### 2.4 Core Building Blocks

```dart
// lib/core/error/failures.dart
abstract class Failure {
  final String message;
  const Failure(this.message);
}

class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

class CacheFailure extends Failure {
  const CacheFailure(super.message);
}
```

```dart
// lib/core/usecase/usecase.dart
import 'package:dartz/dartz.dart';
import '../error/failures.dart';

abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

class NoParams {}
```

### 2.5 Wiring with get_it + injectable

The architecture guide shows manual `sl.registerFactory(...)` registration for explanation only. **In this project, registration is generated by injectable** (section 1) and the locator is named `instance`:

| Class | Annotation |
|---|---|
| BLoC | `@injectable` (new instance per screen) |
| UseCase | `@lazySingleton` |
| Repository impl | `@LazySingleton(as: FeatureRepository)` |
| DataSource impl | `@LazySingleton(as: FeatureRemoteDataSource)` / `@LazySingleton(as: FeatureLocalDataSource)` |
| External (Supabase client, AppDatabase, secure storage) | `@module` with `@preResolve` / `@lazySingleton` getters |

```dart
@LazySingleton(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  AuthRepositoryImpl(this.remoteDataSource);
  ...
}
```

Registering the abstraction with its implementation (`as: AuthRepository`) is the Dependency Inversion Principle: swapping `AuthRepositoryImpl` for another implementation changes only that annotation — BLoC, UseCase and UI stay untouched.

BLoCs are always provided with `instance<XBloc>()` (section 1). Never construct BLoCs, UseCases, Repositories or DataSources manually.

### 2.6 Data Flow

```text
User taps button
  → Page dispatches Event
  → BLoC calls UseCase
  → UseCase calls Repository (abstraction)
  → RepositoryImpl calls Local/Remote DataSource (drift / Supabase)
  → DataSource returns Model (or throws)
  → RepositoryImpl returns Either<Failure, Entity>
  → BLoC folds result and emits State
  → Page rebuilds from the new State
```

### 2.7 New Feature Checklist

1. `domain/entities/` – Entity (pure Dart).
2. `domain/repositories/` – abstract Repository returning `Either<Failure, T>`.
3. `domain/usecases/` – one UseCase per action (+ Params class).
4. `data/models/` – Model extending the Entity with `fromJson` / `toJson`.
5. `data/datasources/` – remote (Supabase) and/or local (drift) DataSource, abstract + impl, throwing exceptions.
6. `data/repositories/` – Repository impl: local-first, exception → `Failure`.
7. `presentation/bloc/` – Event, State (Equatable), BLoC calling UseCases.
8. `presentation/pages/` – Page using `instance<XBloc>()`, `appLanguage()`, `appTheme()`, `AppColor`, ScreenUtil.
9. Annotate with injectable, then run `dart run build_runner build --delete-conflicting-outputs`.
10. Register the page in go_router (`lib/core/router/`).

> **Note:** The code samples in `docs/flutter-clean-architecture-bloc-bangla.md` explain the structure. Where they differ from this README (manual `sl` registration, `Navigator.pushReplacementNamed`, hardcoded strings, `EdgeInsets`, Dio), **this README's rules win**: injectable + `instance`, go_router, `appLanguage()`, ScreenUtil/`REdgeInsets`, Supabase.

## 3. API Response Handling

- Use the **dartz** package for handling API responses and functional error handling.
- Follow a consistent approach for success and failure responses.
- Keep API response handling inside the appropriate data and domain layers.
- Avoid duplicating response-handling logic across different features.

## 4. Local Storage & Database

Use the following packages for local data management:

- **flutter_secure_storage:** For storing sensitive and internal application data securely.
- **drift:** For managing the application's internal local database. drift is a type-safe, **relational** layer on top of **SQLite** (tables, primary/foreign keys, joins, transactions, migrations), fully offline on the device. Packages: `drift`, `drift_flutter` (opens the SQLite file), and `drift_dev` (dev, code generation). Do not add `isar`, `hive`/`hive_ce`, or raw `sqflite`.

### drift Setup

- `lib/core/database/app_database.dart` holds the single `@DriftDatabase` class `AppDatabase`. Add every feature's table to its `tables: [...]` list.
- `lib/core/database/database_module.dart` (injectable `@module`) provides `AppDatabase` as a lazy singleton (`driftDatabase(name: 'eala')` → `eala.sqlite` in the app documents directory), so local DataSources get it injected.
- Tables live in the feature's `data/models/` (e.g. `alarms_table.dart`): a `Table` class with `@DataClassName('<Name>Record')` (never the same name as a Domain entity), plus mapping extensions `Record.toEntity()` and `Entity.toCompanion()`. Domain never sees drift types.
- Lists or other non-SQL values are stored through a `TypeConverter` (e.g. `WeekdaysConverter` → JSON text).
- Writes keyed by the natural id use `insertOnConflictUpdate`, so saving again updates the row.
- **Schema changes:** whenever a table or column changes, increase `schemaVersion` and add a step in `migration.onUpgrade` (`if (from < N) { ... }`). Never edit a released schema without a migration — users' data would be lost or the app would crash.
- For reactive UI, DataSources can expose drift's `.watch()` streams instead of `.get()`.
- Tests use `AppDatabase(NativeDatabase.memory())` (from `package:drift/native.dart`) — no device needed.
- `lib/core/di/injection.dart` defines `instance` and `configureDependencies()`, awaited in `main()` before `runApp`.
- After changing a table or an injectable class, run `dart run build_runner build` (the `--delete-conflicting-outputs` flag is accepted but ignored by the current build_runner).

### Local-First Data Management

The application must follow a **Local-First Data Architecture**.

The expected workflow is:

1. When data is requested for the first time, fetch it from the server.
2. Store the retrieved data in the local drift database.
3. For subsequent requests, load data from local storage instead of depending on the server.
4. Make API requests internally when necessary to fetch updated data.
5. Synchronize the latest server data with the local database.
6. Update the UI automatically whenever the local data changes.

The application should remain functional and display previously loaded data even when there is no internet connection.

Always prioritize local data availability and synchronize it with the server whenever possible.

## 5. Image Caching & Offline Support

- All network images must be cached properly.
- Previously loaded images should remain available when the device is offline.
- Use a professional and reliable image-caching solution.
- Handle image loading, caching, and error states appropriately.
- Avoid displaying broken images when cached versions are available.
- Ensure image caching works consistently throughout the application.

## 6. Color Management

Create a centralized class named `AppColor` to manage all application colors.

- Store all common and required colors in this class.
- Avoid hardcoding colors directly inside widgets.
- Always use the predefined colors from `AppColor`.
- If a new color is required, add it to `AppColor` and reuse it wherever necessary.

This will ensure consistent color usage and make future theme changes easier.

`AppColor` lives in `lib/core/theme/app_color.dart` and is grouped by role (brand, surfaces, text, tab bar). The brand accent is `AppColor.primary` (gold/orange) with `AppColor.onPrimary` for content on it. Name new colours by their role, not by their value.

## 7. Navigation & Routing

- Use **go_router** for application navigation and route management.
- The package has already been added to the project.
- Register and manage all application pages through the established go_router configuration (`lib/core/router/`).
- Follow the existing routing structure when adding new pages.
- Avoid implementing separate navigation approaches or using unnecessary navigation packages.
- **Page transition (global):** every page slides in from the right (right → left) and back out to the right on pop (left → right), on Android and iOS alike, with the edge swipe back. It is set once in `AppTheme.darkTheme.pageTransitionsTheme` (`CupertinoPageTransitionsBuilder` for Android; iOS uses it by default). Every `GoRoute` uses `pageBuilder: (context, state) => appPage(state, const XPage())` (`app_router.dart`), which returns a `MaterialPage` so the theme's transition applies (with plain `builder:` go_router chose a page without any transition here); `MaterialPageRoute`s pick it up too. Do not give single pages their own transition.

## 8. Responsive UI Development

Use **flutter_screenutil** throughout the application to maintain responsive UI across different screen sizes.

Every dimension must use the appropriate ScreenUtil extension.

Follow these conventions:

| Purpose | Usage |
|---|---|
| Height | `20.h` |
| Width | `20.w` |
| Font size | `20.spMin`, `20.spMax`, or `20.sp` |
| Border radius | `20.r` |
| Full screen width | `1.sw` |
| Full screen height | `1.sh` |
| Margin and padding | `REdgeInsets()` |

### Important Rules

- Use `.h` for heights.
- Use `.w` for widths.
- Use `.r` for border radius.
- Use `.spMin`, `.spMax`, or `.sp` for font sizes.
- Use `REdgeInsets()` instead of `EdgeInsets()` for margins and padding.
- Use `1.sw` and `1.sh` when full screen dimensions are required.
- Use `.r` for **square** sizes (icons, circles, avatar rings, and offsets inside them) so they stay square on every screen.
- Wrap screen content in `SafeArea` and keep the scaled padding in `REdgeInsets`; never scale the system insets themselves.
- Apply these conventions consistently wherever dimensions are defined.

Do not use hardcoded dimensions when a ScreenUtil extension is applicable.

## 9. Global Context, Localization & Theme Access

The following global variables and helper methods have already been added to `main.dart`:

```dart
BuildContext get appContext => navigatorKey.currentContext!;

AppLocalizations appLanguage([BuildContext? context]) =>
    AppLocalizations.of(context ?? appContext)!;

ThemeData appTheme([BuildContext? context]) =>
    Theme.of(context ?? appContext);
```

Always use these helpers when accessing the application context, localization, or theme.

### Usage Examples

Access localization:

```dart
appLanguage(context).customer_list.toUpperCase()
```

Or without passing context:

```dart
appLanguage().customer_list.toUpperCase()
```

Access the application theme:

```dart
appTheme(context)
```

Or without passing context:

```dart
appTheme()
```

**Important:** If a `BuildContext` is available, always pass it. Otherwise, use the global helper methods.

Do not introduce duplicate global context, localization, or theme-access implementations.

## 10. Localization & String Management

All user-facing strings must be localized.

- Never hardcode text or strings directly inside widgets.
- Store all user-facing strings in:

  `lib/l10n/app_en.arb`

- Access localized strings using the `appLanguage()` helper.

Example:

```dart
appLanguage(context).customer_list.toUpperCase()
```

Or:

```dart
appLanguage().customer_list.toUpperCase()
```

- Use the context parameter whenever it is available.
- Follow the existing localization generation and naming conventions.
- Whenever a new user-facing string is introduced, add its corresponding entry to `app_en.arb` and use the generated localization accessor.

This rule must be followed carefully throughout the entire application.

## 11. Application Theme Management

Create a centralized class named `AppTheme` to manage all application theme-related configurations.

Use the following theme structure as the reference implementation:

```dart
class AppTheme {
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSwatch(
      primarySwatch: getMaterialColor(Colors.transparent),
    ),
    primaryColor: AppColor.primary,
    primaryColorDark: AppColor.textColor,
    primaryColorLight: AppColor.textColor,
    scaffoldBackgroundColor: AppColor.backgroundColor,
    dividerColor: Colors.transparent,
    canvasColor: AppColor.cardColor,
    splashFactory: NoSplash.splashFactory,
    hoverColor: Colors.transparent,
    splashColor: Colors.transparent,
    highlightColor: Colors.transparent,
    textSelectionTheme: TextSelectionThemeData(
      selectionColor: AppColor.grey,
    ),
    inputDecorationTheme: InputDecorationTheme(
      hintStyle: TextStyle(
        color: AppColor.grey.withOpacity(0.5),
        fontSize: 14.spMin,
        fontWeight: Dimension.textRegular,
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColor.white,
      iconTheme: IconThemeData(
        color: AppColor.iconColor,
      ),
      titleTextStyle: TextStyle(
        color: AppColor.textColor,
        fontSize: 20.spMin,
        fontWeight: Dimension.textMedium,
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.white,
    ),
    cardTheme: CardThemeData(
      color: AppColor.cardColor,
      shadowColor: AppColor.cardShadow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4.r),
      ),
      elevation: 4,
      clipBehavior: Clip.antiAlias,
    ),
    buttonTheme: ButtonThemeData(
      buttonColor: AppColor.primary,
    ),
    iconTheme: IconThemeData(
      color: AppColor.iconColor,
    ),
    textTheme: TextTheme(
      headlineLarge: TextStyle(
        color: AppColor.textColor,
        fontSize: 16.spMin,
        fontWeight: Dimension.textBold,
        decorationColor: AppColor.textColor,
      ),
      headlineMedium: TextStyle(
        color: AppColor.textColor,
        fontSize: 14.spMin,
        fontWeight: Dimension.textBold,
        decorationColor: AppColor.textColor,
      ),
      headlineSmall: TextStyle(
        color: AppColor.textColor,
        fontSize: 12.spMin,
        fontWeight: Dimension.textBold,
        decorationColor: AppColor.textColor,
      ),
      displaySmall: TextStyle(
        color: AppColor.textColor,
        fontSize: 14.spMin,
        fontWeight: Dimension.textRegular,
        decorationColor: AppColor.textColor,
      ),
      titleSmall: TextStyle(
        color: AppColor.textColor,
        fontSize: 14.spMin,
        fontWeight: Dimension.textRegular,
        height: 1.3,
        decorationColor: AppColor.textColor,
      ),
      bodyLarge: TextStyle(
        color: AppColor.textColor,
        fontSize: 14.spMin,
        fontWeight: Dimension.textRegular,
        height: 1.3,
        decorationColor: AppColor.textColor,
      ),
      bodyMedium: TextStyle(
        color: AppColor.textColor,
        fontSize: 12.spMin,
        fontWeight: Dimension.textRegular,
        decorationColor: AppColor.textColor,
      ),
      bodySmall: TextStyle(
        color: AppColor.textColor,
        fontSize: 10.spMin,
        fontWeight: Dimension.textRegular,
        decorationColor: AppColor.textColor,
      ),
    ),
    fontFamily: getFontFamily(),
  );

  static String getFontFamily() {
    try {
      return appContext.read<AppControllerBloc>().state.locale ==
              Locale('en')
          ? FontFamily.satoshi
          : FontFamily.shabnam;
    } catch (e) {
      return FontFamily.satoshi;
    }
  }
}
```

The above implementation should be followed as the reference for managing application-wide theme configurations.

### Using Text Styles

All text styles must be accessed through the application's theme instead of creating independent `TextStyle` configurations unnecessarily.

For example:

```dart
appTheme(context).textTheme.bodyLarge!.copyWith(
  fontWeight: Dimension.textMedium,
  fontSize: 16.spMin,
)
```

Or without context:

```dart
appTheme().textTheme.bodyLarge!.copyWith(
  fontWeight: Dimension.textMedium,
  fontSize: 16.spMin,
)
```

### Important Rules

- Use the predefined `TextTheme` styles wherever possible.
- Use `.copyWith()` when a particular widget requires modifications to an existing text style.
- Use `Dimension` for predefined font weights.
- Use `AppColor` for colors.
- Use ScreenUtil for font sizes.
- Avoid creating unnecessary standalone text styles.
- Keep all text styling consistent with the centralized `AppTheme` configuration.

### Current Theme Implementation

- `lib/core/theme/app_theme.dart` → `AppTheme.darkTheme` (the design is dark only), applied in `main.dart`. The system font is used (SF Pro / Roboto), so no `fontFamily` is set; `FontFamily`/`AppControllerBloc` from the reference above are not part of this project yet.
- `lib/core/theme/dimension.dart` → `Dimension.textRegular / textMedium / textSemiBold / textBold`.
- Every `TextStyle` in the theme sets `letterSpacing` (0 when the design has none). Otherwise Material 3's default tracking is merged in and text renders wider than designed.
- Text roles used by the screens:

| Role | Use |
|---|---|
| `headlineLarge` | Large screen title (34, bold) |
| `headlineSmall` | Section header (20, bold) |
| `titleLarge` | Card title (21, regular) |
| `titleMedium` | List row title (17, semibold) |
| `titleSmall` | Quiet add-row label (16.5, semibold) |
| `bodyLarge` | List row subtitle (15, secondary colour) |
| `bodyMedium` | Regular body text (14) |
| `bodySmall` | Muted supporting text under a title (14) |
| `labelLarge` | Small secondary label (14, semibold) |
| `labelSmall` | Tab bar label (10.5, semibold) |

When a design needs a new text role, add it to the theme first and read it with `appTheme(context).textTheme.<role>!.copyWith(...)`.

## 12. Asset Management

All application assets must be stored inside the centralized `assets` directory.

Follow this folder structure:

```text
assets/
├── images/
└── icons/
```

### Asset Guidelines

- Store all image assets inside `assets/images/`.
- Store all icon assets inside `assets/icons/`.
- All icon assets must use the SVG format.
- Do not store application assets in random locations.
- Keep asset organization consistent throughout the project.

### FlutterGen Integration

After adding or modifying assets, run:

```bash
fluttergen
```

All generated asset references must be available through:

```text
lib/gen/assets.gen.dart
```

### Asset Usage

Use the generated `Assets` class instead of manually specifying asset paths.

For images:

```dart
Assets.images.user.image()
```

For SVG icons:

```dart
Assets.images.user.svg()
```

Use the appropriate generated asset reference and method depending on whether the asset is an image or an SVG.

Never hardcode asset paths inside widgets when a generated reference is available.

### No Unused Assets (App Size)

Every asset ships inside the app, so unused ones only make it bigger.

- Add an asset only when code in the project uses it. When converting a design export, copy **only the files the screen references**, never a whole folder (the export's `icons/` has 100+ SVGs).
- Before finishing a task that adds assets, check that each new file is referenced through `Assets.…`; delete the rest. When the code that used an asset is removed, remove the asset too.
- Prefer SVG over raster images; keep images small (compress, no oversized sources).
- The same rule applies to packages, fonts and audio. A native platform file (e.g. iOS `ios/Runner/demo.aiff`, the alarm notification sound) is **not** also put in `assets/`: it would ship twice.
- Never list the bare `assets/` folder in pubspec: everything in it (even a stray `.DS_Store`) would be bundled. List only the sub-folders that hold used files.
- Removed in the Nov 2026 review (unused): packages `dio`, `auto_size_text`, `url_launcher` (still pulled in by `supabase_flutter`), `cupertino_icons` (a ~280 KB font no screen used); asset `assets/audio/demo.aiff` (duplicate of the iOS bundle copy); five unused tab-bar colours.

### App icon (Android + iOS)

- **`assets/logo.png` is the app logo** (white "e" alarm clock with orange bells, made for a dark background). Keep it: it is the source of the launcher icon. It is not listed in pubspec `flutter: assets`, so it is **not** bundled inside the app (no size cost).
- `assets/launcher/icon.png` (1024², logo at ~62 % on black, used for iOS and old Android) and `assets/launcher/icon_foreground.png` (1024², clear, logo inside the 66/108 safe circle of Android adaptive icons) are made from the logo; they are not bundled either.
- Generated with **`flutter_launcher_icons`** (dev dependency, config in `pubspec.yaml` under `flutter_launcher_icons:`): iOS with alpha removed on black (App Store rule), Android `ic_launcher` plus an adaptive icon (black background + foreground). After changing the logo, remake the two launcher sources the same way, then run `dart run flutter_launcher_icons`.
- **Check after every run:** the tool rewrites `ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES` to `= AppIcon` in `ios/Runner.xcodeproj/project.pbxproj` (a tool bug). Put it back to `YES` (or `git checkout` that file if nothing else changed in it).

### Release builds (smallest app)

- Android: `flutter build appbundle --release --obfuscate --split-debug-info=build/symbols` (Play delivers per-device splits; R8 shrinking is on by default for release). For a side-loaded APK use `flutter build apk --release --split-per-abi`.
- iOS: `flutter build ipa --release --obfuscate --split-debug-info=build/symbols`.
- Keep `build/symbols` for each release (needed to read Crashlytics stack traces of obfuscated builds).

### SVG Icons

Icons are organised exactly like the design export (`flutter-export/assets/icons/`), and pubspec lists each folder (Flutter does not read sub-folders of a listed folder):

| Folder | Generated accessor | Contents |
|---|---|---|
| `assets/icons/` | `Assets.icons.info` | generic icons |
| `assets/icons/tab/` | `Assets.icons.tab.alarm` / `.alarmOn` | tab bar icons: outline + solid `_on` for the selected tab |
| `assets/icons/page/` | `Assets.icons.page.plus` | icons used by page-level widgets (plus, chevron, alarm badges) |

Copy only the icons a screen needs from the export; do not import the whole set.

**One file per icon shape.** An icon used in several places lives once in the common `assets/icons/` folder and every screen uses that same file (e.g. `Assets.icons.alarm` is used by the tab bar, the Settings row and the reason's alarm badge). The export has copies of the same shape with a different stroke width in `tab/`, `settings/` and `page/`; do not copy those duplicates. Before adding an icon, check whether the same shape already exists (compare the SVG path) and reuse it. Only keep a separate file when the shape differs, e.g. the solid `_on` tab icons or the crossed-out `alarm_off_badge`.

- Icon SVGs are drawn in **white** (`stroke="#FFFFFF"` / `fill="#FFFFFF"`, 24×24 viewBox) so they can be tinted to any colour.
- Show them with the common `AppSvgIcon` widget, not with `SvgPicture` directly:

```dart
AppSvgIcon(Assets.icons.plus, size: 26.r, color: AppColor.onPrimary)
```

- When a design (e.g. an exported Dart file) uses Material `Icons.*` or web icons, convert each to an SVG in `assets/icons/` (snake_case file name), run `fluttergen`, and use the generated `Assets.icons.<name>`.

## 13. Common Widgets & Reusable Components

- Store all common and reusable widgets in a separate, centralized location.
- Before creating a new widget, check whether an appropriate reusable widget already exists.
- Reuse existing common widgets wherever possible.
- If a widget is required in multiple places, consider making it a common widget.
- Avoid duplicating widget implementations across different features.
- Maintain a consistent design and implementation approach for reusable components.

Feature-specific widgets should remain inside their respective feature structures unless they are genuinely reusable across the application.

Common widgets live in `lib/core/widgets/`:

| Widget | Purpose |
|---|---|
| `AppSvgIcon` | Tinted square SVG icon from `Assets.icons` |
| `AppTabBar` / `AppTabItem` | iOS 26 **liquid glass** bottom tab bar (wraps `GlassTabBar.bottom`); must be the `bottomBar` of a `GlassScaffold` |
| `SectionHeader` | List heading: bold title + optional trailing control |
| `AddCard` | The one way to add on every list: `first: true` = big empty-state card (gold plus, title, subtitle); `first: false` = quiet 58-tall row with a plus tile and `label`. `AddCard.row(label, color)` = just the row (a picker's "New Reason"; `color: AppColor.surfaceSecondary` inside a sheet) |
| `SlidingBorderScope` / `SlidingBorderTarget` / `SelectionMotion` | **The one selection-border animation of the app**: one orange border springs from the old selected row to the new one, across headings/groups too. Wrap the list once, mark each row with a target. Every choice list uses it (directly for grouped lists like voices, through `AnimatedSelectList` for flat ones); never write another border animation |
| `AnimatedSelectList` / `SelectItem` / `SelectRow` | The single-choice card list. **Every choice list (area, tone, ...) uses it**, so they all move the same way: the shared `SlidingBorderScope` border, the icon pops, the subtitle turns orange, the check springs in, new rows rise in. Icon = server SVG (`SelectItem.iconUrl`, via `CachedSvgIcon`) or the title's first letter. `SelectItem.iconFile` = the same icon already downloaded by the app (used first, offline). `markBuilder` replaces the end check (e.g. a `PlayButton`; `SizedBox.shrink()` for nothing); `footer` adds a last row ("New Reason") |
| `SelectListSkeleton` / `Shimmer` | Loading skeleton (shimmer) shaped like `AnimatedSelectList` rows; `Shimmer` paints any placeholder shapes with the sweeping highlight (no package) |
| `CachedSvgIcon` | Server SVG (`path`) painted in one colour, kept on the device by `flutter_cache_manager`, so it shows offline; falls back to the widget you pass. Adds the base URL itself. Files already found this run are remembered (paths only), so an icon shown again paints at once without a lookup or a blank frame. `file:` = a copy the app downloaded itself (alarm sounds): painted from there, no network |
| `StepTopBar` | Top bar of a multi-step flow: back button + animated progress line (0..1) |
| `HighlightedTitle` | Step heading; words in `*stars*` are drawn in the brand colour; rises in (`animate: false` when the page runs its own entrance; `textAlign`) |
| `PillButton` | The bottom "Continue" pill (58 tall, orange when enabled; `quiet` = dark grey with white text, e.g. "Skip for now") |
| `RiseIn` / `RiseTransition` | **The one entrance motion of the app**: fade + lift (`dy`), optional `blur` (exists only while moving), `delay`, `duration`; `RiseIn.curve` is the app's settle curve. `RiseTransition` is the same motion driven by an animation the page owns (one window of a page timeline, e.g. the ready screen). Never write another fade-and-lift |
| `SpringIn` | Pops a child in once on a spring (60 % → 100 % + fade, optional `delay`); for things that appear in place (the name field's check/pencil chip, the ready seal). Fade/scale transitions only, no rebuild per frame |
| `GhostButton` | The quiet text-only action under a `PillButton` ("Save for later", later "Cancel") |
| `showAppSheet` / `AppSheet` / `AppSheetScope` | **The app's one bottom sheet** (spring in/out, drag down to close, scrim, grabber, title + optional `subtitle` + close chip, scrolling body, footer button; without a footer the body keeps clear of the home indicator). Close from inside with `AppSheetScope.of(context).close(result)`. Never use another kind of sheet |
| `showChoiceSheet` | A sheet to choose one `SelectItem` (the app's `AnimatedSelectList` inside); "Keep …" until a change, then "Use …" |
| `showTextSheet` | A sheet to write / speak one line (`DictationTextField`) with suggestions; "No Changes" / "Use This" / "Remove" |
| `showAppAlert` / `AppAlertAction` | The iOS-style alert ("Discard changes?"); red for a destructive action |
| `ListGroup` / `ListGroupRow` | A rounded card of rows split by hairlines (Settings, a reason's screen): icon (or `leading`), label, value (`highlight` = orange), trailing / chevron; `tint` colours an action row ("Connect an alarm"), `iconColor` the icon alone (a reason's alarm: orange clock, white time), `danger` a red one ("Delete Reason"). `ListGroup(color, radius)`: inside a sheet use `AppColor.surfaceSecondary`, radius 14. `ListGroupSwitchRow` = a row ending in the iOS switch (Settings' notifications, an alarm's "Enabled") |
| `AppSwitch` | The app's on / off switch (iOS style, green when on); `ListGroupSwitchRow` and the alarm cards use it |
| `HintedScrollView` | A form page's scrolling body with the "more below" chevron (fades in while there is more to scroll): a reason's screen, the alarm editor |
| `PlayButton` / `PlayBars` | Round play/stop button for audio previews; while playing, the dancing bars animation (painted, own layer) |
| `CheckCircle` | The round "chosen" mark of a choice card (ring, or orange with a check that springs in); used by `SelectRow` and the length boxes |
| `PlayingRing` | Breathing orange ring around a round avatar while its sound plays (controller runs only while active) |
| `DictationTextField` | Big free-text field the user can type **or speak** into: mic in the corner, warming rule, counter (`showCounter`), optional `note` under the rule; a tap outside closes the keyboard (`onTapOutside`) - never wrap a page in a tap-to-unfocus `GestureDetector`, it steals the tap from the field so it can not focus; while listening it cross-fades into `DictationBar`; spoken words are appended (clipped at a whole word) |
| `DictationBar` / `LiveMeter` / `DictationTranscript` | The listening panel: live transcript (newest word brightens, blinking caret), discard + live loudness meter + stop |
| `SuggestionList` / `SuggestionListSkeleton` / `SuggestionError` / `SuggestionLabel` | Suggestions under a field, 3 at a time + "More ideas" (`expandable: false` = only the first 3); shimmer placeholder while they load; "Try again" row on failure; the small upper-case label |

### Liquid Glass (iOS 26 look)

- Package: **`liquid_glass_widgets`** (maintained, shader-based; works on iOS and Android with Impeller). It is initialised once in `main()` (`await LiquidGlassWidgets.initialize()` and `LiquidGlassWidgets.wrap(child: MyApp(), brightnessResolver: Theme.maybeBrightnessOf)`).
- Use glass only for navigation chrome (tab bar, app bars). A screen that shows glass uses `GlassScaffold` (gives the glass a layer to draw on); the Dashboard is the only one today.
- The tab bar is dark, mostly clear glass (`AppColor.glassTint` via `LiquidGlassSettings`) so it does not turn grey on the black background. The lens under the selected tab follows the selection with jelly physics, magnifies its icon, and can be dragged across tabs, like iOS 26.
- Because the lens draws a second copy of the selected label, widget tests use `find.text('Alarms').first` / `findsWidgets` for tab labels.
- Do not wrap ordinary content in glass; glass on glass degrades by design.

### Auth (Supabase)

> **Rule for all account work: a user's data is never lost, and a social login always connects to the existing user** (same Supabase auth user *and* same `user` row / `user.id`). Anonymous → Google/Apple uses `linkIdentityWithIdToken` only, never a plain sign-in (that would create a second user and orphan the first). If the social identity already belongs to another user, sign into that account and **merge** the anonymous user's data into it on the server instead of discarding it. Never run destructive SQL on user data without an explicit go-ahead.

`lib/features/auth/` (Clean Architecture). For now every install signs in **anonymously**; Google/Apple sign-in (linking the anonymous user with `linkIdentityWithIdToken`) comes with onboarding.

- **Domain:** `AppUser` (Supabase UUID `id`, `isAnonymous`), `AuthRepository.ensureSignedIn()`, `EnsureSignedInUseCase`.
- **Data:** `AuthRemoteDataSource` (uses the `SupabaseClient` from `lib/core/supabase/supabase_module.dart`), `AuthRepositoryImpl`: reuse the saved session if there is one, otherwise `signInAnonymously()`.
- **When it runs:** `DashboardBloc` handles `EnsureSessionEvent`, sent when the Dashboard opens and whenever the app returns to the foreground, so an offline first launch is retried automatically. It does nothing when a session already exists.
- **Session storage:** `supabase_flutter` saves the session on the device and refreshes it; it survives app restarts but **not uninstalling the app** (a reinstall starts a new anonymous user).
- **User profile on the device:** after sign-in the user's row of the Supabase `user` table is downloaded and saved in **flutter_secure_storage** (iOS Keychain / Android Keystore) as one JSON string under the key `user_profile`, so it is always available, even offline. `UserProfile` (domain; id, authUserId, name, email, photo, primaryProvider, platform, appVersion, status, fcmToken, createdAt, updatedAt) is mapped to/from the row's snake_case keys in `data/models/user_profile_model.dart`. `SyncUserProfileUseCase` downloads and saves (run by `DashboardBloc` right after the session is ensured; if it fails the previous copy stays); `GetCachedUserProfileUseCase` reads the saved copy. Read the profile with `instance<GetCachedUserProfileUseCase>()`, never from storage directly.
- **Device info on the server:** `platform` (`ios`/`android`), `app_version` (`version+build`, e.g. `1.0.0+1`) and `fcm_token` are written to the user's `user` row by `UpdateDeviceInfoUseCase`, with the app's own session (policy "update own profile"). The repository compares with the saved profile and sends a request **only when something changed** (new app version after an update, new/refreshed token, other platform); a null token never overwrites the stored one. `DashboardBloc` runs it after every session check (app start and resume) and whenever `fcmTokenChanges` (`lib/core/notification/fcm_token.dart`) announces a token, because the token normally arrives after the session is ready. Set the token only through `setFcmToken()`, never by assigning `fcmToken` directly, or the server will not hear about it.
- **Reinstall safety:** the iOS Keychain survives uninstalling the app, so the saved profile is compared with the signed-in Supabase user (`auth_user_id`); a profile of a different user is deleted and never shown.
- **Supabase dashboard requirement:** Authentication → Sign In / Providers → **"Allow anonymous sign-ins"** must be on; otherwise sign-in fails with `anonymous_provider_disabled` (the app keeps working and retries).
- Never put the service_role / secret key in the app; only the publishable key (`AppConstant.SUPABASE_KEY`), with RLS enabled on every table.

### Firebase (Crashlytics, Analytics, Messaging)

Project **`eala-01`**, configured with the FlutterFire CLI (`flutterfire configure --project=eala-01 --platforms=android,ios --android-package-name=com.eala.app --ios-bundle-id=com.example.nativeAlerm`). Generated files: `lib/firebase_options.dart`, `android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist`, `firebase.json`. **If the bundle id or package name changes, re-run the command** (it also re-adds the Gradle and Xcode build steps). Needs `dart pub global activate flutterfire_cli` and a logged-in `firebase` CLI (`npm i -g firebase-tools`).

- **Startup (`main()`):** `initializeFirebase()` first (so Crashlytics sees everything after it), then `FirebaseMessaging.onBackgroundMessage(...)`, DI, Supabase, glass, and `NotificationService.initialize()` (not awaited, so the permission prompt does not delay the first frame).
- **Crashlytics** (`lib/core/firebase/firebase_initializer.dart`): `FlutterError.onError` and `PlatformDispatcher.onError` report fatal errors. Collection is **off in debug builds** (`!kDebugMode`); test it with a release/profile build and `FirebaseCrashlytics.instance.crash()`. Android uses the Crashlytics Gradle plugin; iOS has the "upload-crashlytics-symbols" build phase.
- **Analytics** (`AnalyticsService`, `lib/core/firebase/analytics_service.dart`): active users, sessions and engagement are automatic. `DashboardBloc` also logs a `screen_view` for each tab (`my_alarms`, `reasons`, `settings`). Use `instance<AnalyticsService>()`; never call `FirebaseAnalytics` from a widget.
- **Messaging + local notifications** (`lib/core/notification/`): `NotificationService` asks permission, fills the token, and shows push messages that arrive while the app is open through `LocalNotificationPresenter` (flutter_local_notifications, channel `eala_general`) because Firebase draws nothing in the foreground. In background/closed state the system shows `notification` messages itself (channel and icon set in `AndroidManifest.xml`); data-only messages with `title` and `body` are drawn by `firebaseMessagingBackgroundHandler`. `PushContent.fromMessage` is the one place that reads a message's title/body.
- **The token variable:** `String? fcmToken` in `lib/core/notification/fcm_token.dart`. Import it anywhere and read `fcmToken`; it is null until Firebase issues one and is updated on every refresh. It uses `getToken`/`onTokenRefresh`, which the plugin marks deprecated in favour of `register()`/`onRegistered`; those return the *Firebase Installation ID*, not the FCM token the console and the HTTP v1 `token` field need, so keep the deprecated calls (with their `ignore` comments) unless the sending side changes.
- **Plugins and DI:** `FirebaseModule` provides `FirebaseMessaging`, `FirebaseAnalytics`, `FirebaseCrashlytics` and `FlutterLocalNotificationsPlugin`; tests replace services with fakes (`FakeAnalyticsService`).
- **iOS notification delegate:** `AppDelegate` handles only notifications whose `userInfo` has an `alarmId` (the native alarm layer); everything else is passed to `super` so Firebase and flutter_local_notifications receive it. Keep that rule when editing `willPresent`/`didReceive`.

**One-time setup outside the code (needed for iOS push):**
1. The Apple Developer account holder must accept the latest Program License Agreement (Xcode currently refuses to update provisioning with "PLA Update available").
2. In Xcode: Runner → Signing & Capabilities → **+ Capability → Push Notifications** (this creates the entitlements file; Background Modes → Remote notifications is already in `Info.plist`). The current wildcard profile ("iOS Team Provisioning Profile: *") cannot carry push, so the App ID `com.example.nativeAlerm` must be an explicit one. Without this, iOS builds still work but push messages are not received and `fcmToken` stays null.
3. Create an APNs Auth Key (.p8) in the Apple Developer portal and upload it in Firebase console → Project settings → Cloud Messaging → Apple app configuration.
4. Firebase console → Crashlytics: open the dashboard once so it finishes enabling.

Android needs nothing extra (the notification permission is already requested by the alarm layer too). The iOS Simulator cannot get an APNs token, so test push on a real iPhone or an Android device.

### Reasons Feature

`lib/features/reasons/` follows the full Clean Architecture stack and is the reference for a list feature:

- **Server-driven content:** the app contains **no** list of areas of life, tones or voices. A reason carries them as the server sends them, so they can change without an app update. Never hardcode area/tone/voice data in the app.
- **One reason = one object:** `Reason` is a `reason` row with what it points at **joined in over its foreign keys** — `area` (`AreaOfLife`, `area_id`), `sound` (`SoundType`, `sound_type_id`), `voice` (`Voice` with its group, `voice_id`) — plus `name`, `purpose`, `why` ("" = none), `lengthSeconds`, `createdAt`. One request: `reasonSelect` = `'*, area_of_life(*), sound_type(*), voice(*, voice_group(id, title, description))'` (`data/models/reason_model.dart`, parsed by `reasonFromJson`). The ids are always there; the joined objects are null only if the server did not send them. `ReasonDraft` (area, purpose, why, sound, voice, length) is what the user chooses: a new reason is `NewReason(baseName, draft)`, an edit is `updateReason(id, draft)`.
- **Domain:** `ReasonRepository` (`watchReasons()`, `watchReason(id)`, `refreshReasons()`, `createReason`, `renameReason`, `updateReason` — every write returns the reason as saved — and `deleteReason(id)`), use cases `WatchReasons`, `WatchReason`, `RefreshReasons`, `CreateReason`, `RenameReason`, `UpdateReason`, `DeleteReason`, and `nextReasonName(base, taken)`.
- **Cache (drift, `AppDatabase.schemaVersion` 8):** table `reasons` = `id`, `created_at` (order) and `data`: **the server's whole joined row as JSON**, so the cache holds the full object and nothing is joined on the device. v8 dropped the old shape; the table is only a copy of the server (every write goes there first), so it is refilled by the next refresh and no user data is lost.
- **Cache first, server in the background:** every screen reads the device copy (instant, offline too). `RefreshReasonsEvent` (with `LoadReasonsEvent` and whenever the app comes back to the front) downloads the user's joined rows and `replaceAll` mirrors them in one transaction (added / updated / removed; order = `created_at`). Offline or any error: the copy stays, the user sees nothing. The remote waits up to 15 s for the session the dashboard opens at launch, and asks for the user's `user.id` once per signed-in auth user (kept in memory), not on every refresh.
- **Writes:** create / rename / update go to Supabase first with `.select(reasonSelect)`, so the answer is the new full row; that row replaces the device copy and every screen watching it (list, reason screen) updates by itself. **Delete** removes the row on the server first (`delete().eq('id', id).select('id')`; an empty answer means RLS refused, so it fails), then the device copy, so the list drops it. Refresh, create, rename, update and delete run one at a time in the repository, so a refresh can never put an older list back over a fresh write.
- **Saving a new reason (`reason` table):** `user_id` = the signed-in user's **`user.id`** (`user.auth_user_id = auth.uid()`), the draft's columns (`why` empty → null), and `name` = the area's `name`, made unique per user (`Health`, `Health 2`, ... highest + 1; `Healthy` / `Health club` do not count). Renaming / editing updates the row by id (and `updated_at`).
- **Needs on the Supabase side:** RLS on `reason` allows `select`, `insert`, `update` and `delete` for `authenticated` where `user_id = (select id from public."user" where auth_user_id = (select auth.uid()))`; the joins need `select` on `area_of_life`, `sound_type`, `voice`, `voice_group` and the foreign keys `reason.area_id`, `reason.sound_type_id`, `reason.voice_id`.
- **Presentation:** `ReasonsBloc` (follows `watchReasons`), `ReasonsPage` (a row opens the reason's screen with its cached object), `ReasonRow`, `ReasonEmblem` (the area's server icon in its tint on a 15 % tint square; the area's first letter when it has no icon or it can not be loaded; `disc: true` = the reason screen's round header look — use it, never draw another area mark). A reason added while the list is covered keeps its place invisible and rises in once the list is on top again.
- The alarm mark on a reason (`ReasonAlarmBadge`: none/on/off, in `reason_emblem.dart`) is built but not wired to data yet, because alarms do not reference a reason.
- `ReasonRow` is *at least* 78 tall and grows with the text (large accessibility fonts); do not give rows a fixed height.

### Server files (icons, images): base URL + path

The database stores only the **path** of a file (e.g. `icons/health.svg`). The address those paths live under is **`AppConstant.baseUrl`** (Supabase Storage's public URL by default: `<SUPABASE_URL>/storage/v1/object/public/`). To show any server file, turn the stored path into a URL with **`mediaUrl(path)`** (`lib/core/network/media_url.dart`); never build a file URL by hand and never put the base URL in the database or a widget. A value that already is a full `http(s)` URL is returned unchanged. Widgets that show server files (`CachedSvgIcon` now, an image widget later) take the *path* and call `mediaUrl` themselves, so the base URL is added in exactly one place. Network images and icons must be cached (README §5): `CachedSvgIcon` uses `flutter_cache_manager`.

### Speech to text (dictation)

Package **`speech_to_text`** (Apple Speech on iOS, Google on Android). `lib/core/speech/`:

- `SpeechRecognizer` (lazy singleton) wraps the plugin: asks for permissions on first use, listens with partial results (stops after 3 s of silence or 1 min), maps the platform sound level to 0..1. The plugin keeps listeners from its first `initialize`, so there is exactly one instance (`SpeechModule`).
- `DictationController` (abstract `ChangeNotifier`: `listening`, `said`, `saying`, `level`, `onFinished`) and `SpeechDictationController` (`@Injectable(as: DictationController)`, a new one per screen: `instance<DictationController>()`). Tests register `FakeDictation`.
- Permissions: iOS `NSMicrophoneUsageDescription` + `NSSpeechRecognitionUsageDescription` (Info.plist); Android `RECORD_AUDIO` + the `android.speech.RecognitionService` `<queries>` entry. If speech is unavailable (denied, no recogniser) the field shows a SnackBar.

### Animation performance rules

Every animation must stay cheap; the app runs on low-end phones too.

- Fade with `FadeTransition` (an opacity layer), not `Opacity` inside an `AnimatedBuilder`; rebuild only the small part that moves (a `Transform`).
- Put anything that repaints every frame on its **own layer** with `RepaintBoundary` (shimmer, the select-list border, the progress line, the live meter), so the page around it is not repainted.
- Never rebuild/lay out text on a repeating animation (the dictation caret is a `FadeTransition` inside the text, the transcript rebuilds only when a word changes).
- Never create a `CurvedAnimation` in `build` (each one adds a listener to its parent that is never removed). Make page-timeline windows once (`late final`), e.g. `controller.drive(CurveTween(curve: Interval(...)))`.
- Network pictures are decoded at the size they are shown (`memCacheWidth`/`memCacheHeight` = size × device pixel ratio), never at the file's full size (`VoiceAvatar` does this).
- Create no controller/timer when the motion is off: `RiseIn` (also used for the suggestion entrances) skips itself when `MediaQuery.disableAnimations` (reduce motion) is on; the meter stands still and the caret stops.
- Expensive effects (blur) only while they animate, never on settled content.
- Repeating animations (shimmer, caret, meter) live only as long as their widget; dispose every controller/ticker/timer.

### Audio previews

Package **`audioplayers`** (plays with the platform's own player, small). `SamplePlayer` (`lib/core/audio/sample_player.dart`, `@Injectable(as: SamplePlayer)`, one per screen via `instance<SamplePlayer>()`, disposed with it): `play(url)` downloads the file through `flutter_cache_manager` (so a sample heard once plays offline) and plays it, stopping the previous one; `playFile(path)` plays a file the app already has (a downloaded alarm sound, offline); `onComplete`, `stop()`, `dispose()`. Always pass full URLs (`voice.audioUrl`). Tests register `FakeSamplePlayer`.

### Sound Feature (no cache)

`lib/features/sound/`: `SoundType` (table **`sound_type`**: id, title, description, icon path, color) and `SoundQuote` (table **`quotes_of_sound`**: area_id, sound_id, quote). `SoundRepository.getSoundTypes()` and `getSoundQuote(areaId, soundId)` (the first row of that area and sound, or null), with `GetSoundTypesUseCase` / `GetSoundQuoteUseCase`. Straight from the server, nothing saved on the device.

### Area of Life Feature (server list, local first)

`lib/features/area_of_life/` holds the list of areas of life from the Supabase table **`area_of_life`** (`id int8, name, title, description, icon, color (hex text), created_at, updated_at`). It is shared by Create Reason and, later, onboarding.

- **Domain:** `AreaOfLife` (id, name, title, description, icon URL, `color` as ARGB int), `AreaOfLifeRepository` (`watchAreas()` stream + `refreshAreas()`), `WatchAreasOfLifeUseCase`, `RefreshAreasOfLifeUseCase`.
- **Data:** `AreaOfLifeRemoteDataSource` (Supabase select ordered by id), `AreaOfLifeLocalDataSource` (drift `AreasOfLifeTable` → `areas_of_life`, `AppDatabase.schemaVersion` **5**), `AreaOfLifeRepositoryImpl`, `AreaOfLifeModel.fromJson` (colour hex → ARGB, blank text → null, missing title → name).
- **Local-first flow:** the UI only watches the saved rows (instant, works offline). A refresh downloads the server rows and, in one transaction, adds/updates rows and deletes rows the server no longer has; drift's `watch()` then pushes the change to the page. A failed refresh leaves the saved rows alone; an **empty** server answer is ignored (never wipes the saved list).
- **Needs on the Supabase side:** Row Level Security must allow reading it, e.g. `create policy "read areas" on public.area_of_life for select to anon, authenticated using (true);` — without a select policy the server answers with an empty list and the page shows "Nothing to choose from yet."
- `icon` holds only the **path** of a single-colour SVG on the server (see *Server files* below); it is painted in the area's `color`.

### Voice Feature (server list, local first)

`lib/features/voice/` mirrors Area of Life for the Supabase table **`voice`** (`id, name, voice_id, audio, avatar, group_id, gender, accent, traits, color, is_premium, created_at, updated_at`). Each voice's group comes from **`voice_group`** (`id, title, description`) in the **same request**: `select('*, voice_group(id, title, description)')`, a join over the `voice.group_id` → `voice_group.id` foreign key (the join needs that foreign key). `Voice.group` (`VoiceGroup`) holds it, and the cached `voices` row keeps `group_title` / `group_description` (`AppDatabase.schemaVersion` **7**, v6→v7 adds the two columns).

- **Domain:** `Voice` (all columns; `color` as ARGB int, `isPremium` bool), `VoiceRepository` (`watchVoices()` + `refreshVoices()`), `WatchVoicesUseCase`, `RefreshVoicesUseCase`.
- **Data:** `VoiceRemoteDataSource`, `VoiceLocalDataSource` (drift `VoicesTable` → `voices`, `AppDatabase.schemaVersion` **6**), `VoiceRepositoryImpl`, `VoiceModel.fromJson`. Same rules as areas: saved copy first, background refresh in one transaction, failures and empty answers never wipe the saved list.
- **`audio` and `avatar` are server paths.** Always use `voice.audioUrl` / `voice.avatarUrl` (they call `mediaUrl`), never the raw path.
- Needs a `select` RLS policy on `voice`, like `area_of_life`.

### Alarm Audio Feature (alarm sounds + sound tracks, files kept on the device)

`lib/features/alarm_audio/` keeps the server tables **`alarm_sound`** and **`sound_track`** (same columns: `id, title, description, icon, color, audio, created_at, updated_at`) on the device, **with their icon and audio files**, because making an alarm needs them and must work offline.

- **Domain:** `AlarmAudio` (kind, id, title, description, `icon` / `audio` = server paths, `color` ARGB, `iconFile` / `audioFile` = the downloaded copies' full paths, null until downloaded), `AlarmAudioKind` (`alarmSound` / `soundTrack`, each knows its `table`), `AlarmAudioRepository` (`watchAudio(kind)`, `refreshAudio()`), `RefreshAlarmAudioUseCase`, `WatchAlarmAudioUseCase(kind)` (the device's copy only: Create Alarm reads it, never the server).
- **Cache (drift, `AppDatabase.schemaVersion` 9):** one table `alarm_audios` keyed by (`kind` = server table, `id`). `icon_file` / `audio_file` hold only the file **names** in the app's `alarm_audio` folder (Application Support: the system never clears it), never full paths — the app's folder can move after an update.
- **When:** `DashboardBloc` runs the refresh in the background right after the session is ready, i.e. **every time the app opens** (launch, and every return to the foreground: `DashboardPage` sends `EnsureSessionEvent` on resume). Two refreshes at once run only once.
- **Refresh:** both tables are mirrored (added / updated / removed; an empty answer is ignored, offline keeps everything). Then each row's files: the file name is `<table>-<id>-<icon|audio>-<fingerprint of path + updated_at><.ext>`, so **a new path or a newer `updated_at` = a new file**: it is downloaded (`dart:io` `HttpClient`, written as `.part` and renamed when complete), recorded on the row, and the **old file is deleted** with every other file no row uses (removed rows, removed icons). Unchanged files are not downloaded again; a file missing from the device is. A download that fails keeps the row's previous file (still playable offline) and is tried again on the next open.
- **On the server side:** RLS `select` for `authenticated` on both tables; files are server paths turned into URLs by `mediaUrl()`. **Replacing a file under the same path must also change `updated_at`** (or the app can not know): give both tables an `updated_at` trigger, or upload new files under new names.

### Purpose Suggestions of an Area (no cache)

`purpose_suggestion` (`id, area_id, suggestion, created_at, updated_at`) belongs to the `area_of_life` feature: `PurposeSuggestion`, `PurposeSuggestionModel`, `AreaOfLifeRepository.getPurposeSuggestions(areaId)`, `GetPurposeSuggestionsUseCase(PurposeSuggestionsParams(areaId))`. Suggestions are **fully dynamic**, so they are **never saved on the device**: every call asks the server, and offline is a failure. Needs a `select` RLS policy on `purpose_suggestion`.

`matter_suggestion` (`id, area_id, purpose_suggestion_id, suggestion, ...`) is in the same feature: `MatterSuggestion`, `AreaOfLifeRepository.getMatterSuggestions(areaId, purposeSuggestionId)`, `GetMatterSuggestionsUseCase(MatterSuggestionsParams(...))`. The server query is `area_id = areaId` and `purpose_suggestion_id = id` when the purpose reads like one of the purpose suggestions (`state.purposeSuggestion`), or `purpose_suggestion_id is null` when it is the user's own text. Never saved on the device.

### Create Reason Feature (multi-step mother page)

`lib/features/create_reason/` is its **own feature** (everything about creating a reason lives there: `presentation/bloc`, `pages`, `widgets`, and later its `domain`/`data` for saving the reason). Route `RouteNames.createReasonPath` (`/createReason`), opened by the Reasons tab's `AddCard`. It reads the areas through the shared `area_of_life` feature.

- **`CreateReasonPage` is the mother page:** top `StepTopBar` (progress = `(stepIndex + 1) / AppConstant.createReasonStepCount`, 5 steps as designed), a `PageView` (no swiping) whose pages are the steps, and the bottom `PillButton` "Continue" (enabled by `CreateReasonState.canContinue`). The system back gesture goes one step back; only the first step closes the page.
- **`CreateReasonBloc` holds every step's data** (`CreateReasonState`) so the last step can insert the reason into Supabase in one go. Events: `LoadAreasEvent`, `RefreshAreasEvent`, `LoadVoicesEvent`, `RefreshVoicesEvent`, `LoadSuggestionsEvent`, `AreaSelectedEvent`, `NextStepEvent`, `PreviousStepEvent`. `LoadStatus` (loading / loaded / failed) is shared by every list in the state.
- **Data the later steps need is loaded ahead:** the page sends `LoadAreasEvent` and `LoadVoicesEvent` when it opens, so `state.voices` is ready (and cached) before the voice step. "Continue" on the area step sends `LoadSuggestionsEvent(selectedAreaId)`; `state.areaSuggestions` / `suggestionsStatus` then hold that area's suggestions (`suggestionsAreaId` says which area; an answer for an area the user has since left is dropped).
- **Steps by name:** `CreateReasonState.areaStep`, `purposeStep`, `voiceStep`, `matterStep`, `soundStep` (their index in the page); never compare `stepIndex` with a bare number. The step count is `AppConstant.createReasonStepCount`.
- **To add a step:** build its page widget (like `SelectAreaStep`), append it to `_steps` in the page, raise `AppConstant.createReasonStepCount`, name its index in `CreateReasonState`, add its data there and a case to `canContinue`. Steps built (all 5): 1 `SelectAreaStep`, 2 `PurposeStep`, 3 `SelectVoiceStep`, 4 `MatterStep`, 5 `SelectSoundStep`. On the last step the button reads "Create Reason" (`state.isLastStep`) and sends `CreateReasonSubmittedEvent`: `state.saveStatus` (idle / saving "Saving…" / saved / failed SnackBar), `state.createdReason`. When saved, the page is **replaced** by the ready screen (`context.pushReplacement`), so back from it lands on the reasons list. The two text steps share `ComposerTextStep` (eyebrow, heading, type-or-speak field with its controller and mic, suggestions slot with a `fill` callback); a new text step must use it too.
- **Step 5 `SelectSoundStep`** ("How should it sound?"): the sound types load when the page opens (`LoadSoundTypesEvent`; skeleton / "Try again"), the first is chosen until the user picks (`state.selectedSound`). The example card shows `quotes_of_sound` for the selected area and sound (`state.soundQuoteShown`), loaded fresh on entering the step and on every sound change, with a shimmer while it loads; the words rise in one by one. Under the dials (one orange circle springs between them) the sound's description cross-fades; then the length: 30 or 45 seconds (`AppConstant.reasonLengthsSeconds`, default 30, `state.lengthSeconds`), one `SlidingBorderScope` border between the two boxes. Names/notes of the lengths are in `app_en.arb` (`create_reason_length_30/45`).
- **Step 4 `MatterStep`** ("Why does it matter to you?", optional): "OPTIONAL", the heading, the purpose as a quote ("FOR" + the text), the field (no counter; "A few more words, or clear it to skip." while 1-7 characters) and, while empty, the first 3 matter suggestions (`state.matterSuggestionsShown`, loaded on "Continue" from the purpose step for `state.matterSuggestionsKey` = selected area + picked purpose suggestion id or null). The footer reads "Skip for now" in the quiet look while empty (`state.continueSkips`), "Continue" otherwise; 1-7 characters keep it off. `state.matter` holds the text.
- **Step 3 `SelectVoiceStep`** ("Who should say it?"): the cached voices under their group headings (groups in id order, voices without a group last), `VoiceRow` cards (portrait from `voice.avatarUrl` cached, "Female · American · Warm", `PlayButton`) inside one `SlidingBorderScope`. The play button plays `voice.audioUrl` with `SamplePlayer`, shows `PlayBars` and the avatar's `PlayingRing`, and also chooses the voice; one plays at a time, it stops on a second tap, at the end, or when the step is left. `state.selectedVoiceId` / `selectedVoice`; Continue needs a voice. A chosen voice the server removed is un-chosen.
- **Step 2 `PurposeStep`** ("What are you working toward?"): the selected area's title on top (its tint mixed into white), the heading, a `DictationTextField` (type or speak), and while the field is empty the area's suggestions (`state.suggestions`, from `purpose_suggestion`) as a `SuggestionList` (shimmer while loading, "Try again" on failure). Picking a suggestion puts its text in the field. **Flag:** `state.purposeSuggestion` / `state.purposeFromSuggestion` is worked out from the current text: it is the selected area's suggestion whose text the purpose reads (trimmed, spaces collapsed, letter case ignored), however the user got there (picked, or typed/spoken/edited until it matches again); otherwise null = the user's own text. The next steps suggest differently for the two cases (e.g. `purpose_suggestion_id` for matter suggestions). Choosing another area drops a purpose that is one of the old area's suggestions (own text stays). Continue needs ≥ 12 characters and 2 words (`AppConstant.purposeMin*`, max 180) and the mic off (`state.dictating`).
- **Step 1 `SelectAreaStep`:** `AnimatedSelectList` of the areas (title, description, icon, colour from the server). First time with nothing saved → `SelectListSkeleton`; offline with nothing saved → message + "Try again"; later opens show the saved areas at once while the refresh runs, and areas that arrive or change update in place (new rows rise in). A chosen area the server has removed is un-chosen.

- **Shared pieces for the reason screens:** `ReasonSummaryCard(reason, name)`, `ReasonNameField` (`large` = page title), `AreaLabel`, `VoiceAvatar`, `VoicePicker` (grouped voices + samples; the voice step and the voice sheet), `reason_choice_items.dart` (`areaChoice`, `soundChoice`, `lengthChoice`, `reasonLengthName/Note`: the same rows in the steps and the reason's sheets). `AppColor.tintOf(argb)` turns a server tint into a colour; `initialOf(name)` gives the letter shown when there is no picture.
- **Ready screen `ReasonReadyPage`** ("Your reason is ready.", route `RouteNames.reasonReadyPath`, the saved `Reason` in `extra`; without one the route goes home). One 2.5 s arrival timeline (green seal springs in, tick drawn, a ring leaves it, heading / card / buttons rise in, one haptic; reduce motion shows it all at once). The card: area icon + title, the editable name (`ReasonNameField`: pencil chip → orange check, saves on done / check / tap outside, Escape cancels, empty or unchanged is dropped), purpose, "Why it matters" (if any), voice and tone. `ReasonReadyBloc` renames optimistically and puts the old name back (SnackBar) if the server says no. **No close button:** back (button or gesture) does what "Save for later" does — pop to the reasons list. "Use with alarm" replaces the ready screen with Create Alarm (`pushReplacement(RouteNames.createAlarmPath, extra: reason.id)`), the new reason already chosen; back from the editor returns to where Create Reason was opened.

### Reason Detail Feature (a reason's own screen, edited with sheets)

`lib/features/reason_detail/`. Route `RouteNames.reasonDetailPath`, opened from a list row with the cached `Reason` in `extra` (no reason → home). It shows at once and offline.

- **Screen:** "‹ Reasons" and "…", the area disc + the name as the page title (`ReasonNameField(large: true)`, renamed at once on its own), the "Connect an alarm" row, "What it's about" (Area of life, Purpose, Why it matters), "How it speaks" (Tone, Voice, Length), "Alarm": with an alarm on the device that plays it (`ReasonDetailState.alarm`, from the followed alarms, `WatchAlarmsUseCase`) one row per time it rings (`_AlarmRows`: orange clock, "6:30 AM", "Tue Wed" / "Weekdays" from `repeatLabel`; editing an alarm is not built, so the rows do nothing on tap) and no "Connect an alarm" row; without one, "Not in an alarm yet." and the "Connect an alarm" row as before. Rows are the common `ListGroup` / `ListGroupRow`. A "more below" chevron shows while there is more to scroll.
- **Editing = sheets that hold, one Save:** every row opens its sheet already showing the current choice — area / tone / length: `showChoiceSheet` (the app's `AnimatedSelectList`); purpose / why: `showTextSheet` (`DictationTextField` + `SuggestionList`, ideas from `purpose_suggestion` / `matter_suggestion` like Create Reason); voice: `showVoiceSheet` (`VoicePicker`, samples play). A sheet saves nothing: the choice is held in `ReasonDetailState.draft`, its row reads orange, and the `SaveBar` (Save Changes + Discard + caption) springs up. Choosing the saved value again is no change. Save Changes → `UpdateReasonUseCase` (server, then cache → the list follows). Discard and back with held changes ask first ("Discard changes?", `showAppAlert`). Failures: SnackBar, the changes stay held.
- **`ReasonDetailBloc`** (`@factoryParam` reason): follows `watchReason(id)` (held changes stay held when the saved copy changes), the cached areas and voices (refreshed in the background), and the tones from the server (tapping Tone before they arrive asks again only when no request is on its way); `purposeSuggestions` / `whySuggestions` feed the text sheets — an area's purpose ideas are asked once while the screen is open (both sheets need them; failures are not kept, nothing is saved on the device).
- **"…" (more) → `showReasonActions`** (`widgets/reason_actions_sheet.dart`): an `AppSheet` titled with the reason's name holding one `ListGroup` — "Use with an alarm" (does nothing yet: alarm linking is not built; it will also need the lock / "up to 3 alarms" state of the design) and the red "Delete Reason". Choosing Delete closes the sheet, then 120 ms later asks with `showAppAlert` ("Delete “name”?", "This can’t be undone.", Cancel | red Delete). Yes → `ReasonDetailDeleteRequestedEvent` → `DeleteReasonWithAlarmUseCase`; `state.deleted` pops the screen (the list has already dropped it), a failure (`deleteFailures`) shows "Couldn’t delete this reason" and stays.
- **Delete with its alarm:** a Reason with an alarm (`hasAlarm`: on the device, or `reason.alarm_id` on the server) asks "Delete “name”?" / "Its alarm will be deleted too. Every alarm needs a reason.". `DeleteReasonWithAlarmUseCase` (`lib/features/reason_detail/domain/usecases/`) removes the alarm from the server first (`RemoteAlarmRepository.remove` → `AlarmRemoteDataSource.deleteAlarm`: every `sub_alarm` row with its `alarm_id`, then the Reason's link, then the `alarm` row; each delete asks for the rows it removed, so a delete that row-level security silently refuses fails instead of leaving rows behind, and the Reason's link is put back if the alarm row stays), then cancels its ring and deletes it on the device, then deletes the Reason (server, then device). Offline nothing changes and it says it couldn't delete.
- **"Connect an alarm"** is drawn (`ListGroupRow` with `tint: AppColor.primary`) but does nothing until alarm linking is built.

### My Alarms Feature (the Alarms tab)

`lib/features/my_alarms/`. `MyAlarmsBloc` follows the saved alarms (`WatchMyAlarmsEvent` → `WatchAlarmsUseCase`, a drift watch: a change made anywhere — the editor, a Reason deleted with its alarm, a reschedule — shows at once), switches off one-off alarms that have rung (`LoadMyAlarmsEvent` → `GetAlarmsUseCase`, on open and on resume), follows the cached reasons (`WatchReasonsUseCase`) and runs each card's switch (`SetAlarmEnabledUseCase`). `MyAlarmsLoaded`: `alarms` (switched-on ones by their next ring, then the others), `reasons`, `alarmLimit`, `alarmCount` (fills the `SlotMeter` pills), `reasonOf(alarm)`, `toggleFailures`.

- **No alarm:** the big `AddCard` ("Set your first alarm / Pick a time and a reason.").
- **Alarms:** the section reads "Next alarm" and the meter "1 of 3" (used pills white). One `AlarmCard` each (radius 28): the Reason (`ReasonEmblem(disc: true, size: 40)` + name, or the name it was saved with until the cache has it) and an `AppSwitch`; the next ring's time, large, with an orange AM/PM; "Next ring · Today / Tomorrow / Wednesday" (or "Off · won’t ring"); the seven days S M T W T F S (repeat days orange, the next ring's day ringed in white). Off dims everything under the Reason. Then the quiet "Add alarm" row. Cards do nothing on tap yet (editing an alarm is not built).
- **The switch:** moves at once; `SetAlarmEnabledUseCase` sets the alarm on the device at its next ring (`nextRingOf`) or cancels it (`AlarmScheduler.cancel`), then saves it; if the device refuses, the switch goes back with "Couldn’t change the alarm".

### Create Alarm Feature ("Add Alarm", the alarm editor)

`lib/features/create_alarm/`. Route `RouteNames.createAlarmPath` (`extra`: an optional Reason id the alarm starts with), opened by My Alarms' add card. **Never more than `AppConstant.maxAlarmCount` (3) alarms:** My Alarms shows the "Alarm limit" alert (`showAlarmLimitAlert`) instead of opening the page when they are all taken, the page closes with the same alert if it is reached anyway, and `CreateAlarmUseCase` refuses a 4th (`AlarmLimitFailure`). The slot meter's pills fill with the number of saved alarms; My Alarms reloads the count when the page comes back.

- **Offline by design:** everything the page offers comes from the device — the cached reasons (`WatchReasonsUseCase`), alarm sounds and sound tracks (`WatchAlarmAudioUseCase`, rows + downloaded files from the Alarm Audio feature). Sound samples play the downloaded file (`SamplePlayer.playFile`).
- **Domain:** `AlarmTime` (12-hour), `AlarmDraft` (time, days 0 = Sun, `byDay` = a time per day, reasonId, soundTrackId, alarmSoundId, again 0-2, enabled), `ScheduleCard`; `alarm_schedule.dart` is the design's schedule logic with no widgets (`groupDays`, `fromCards`, `addCard`, `toggleCardDay`, `setCardTime`, `finalize`, `repeatLabel` with `RepeatWords`, `nextRing`). `CreateAlarmUseCase` finalizes the draft (equal times → a simple alarm), builds the `Alarm` (days → 1 = Mon .. 7 = Sun, `dayTimes` = minutes after midnight per day, `time` = `nextRing`), saves it, and when enabled sets it to ring through `AlarmScheduler`; if the device refuses, the saved alarm is removed again.
- **`CreateAlarmBloc`** holds the whole form (draft + cards); `@factoryParam` reasonId. On start it counts the alarms (the limit, and `takenReasonIds`: the Reasons this device's alarms play, including one made offline) and checks alarm access (`HasAlarmAccessUseCase`; denied → "Enabled" reads off and a red "This alarm won’t ring / Enable Alarm Access" row asks again). Each sound list starts on its first row; the Reason has **no default**.
- **Page (`CreateAlarmPage`):** "Cancel" + "Add Alarm"; `ScheduleCards` (the wheel `TimeWheel` and the seven days; "Add another time" makes cards, a tapped day moves to that card with a "Sunday moved from 6:30 AM" note, an empty card goes); "What you’ll hear": `AlarmReasonRow` (`ReasonEmblem`, or a breathing dashed tile while there is none), Soundtrack and Alarm sound (`ListGroupRow`); "Ring again" (`SegmentedControl` + `RingAgainCaption`); "Enabled" (`ListGroupSwitchRow`); one orange button that reads "Choose a reason" / "Add a reason" (and does that) until there is a Reason, then "Save Alarm". Sections rise in (`RiseIn`), the body is a `HintedScrollView`.
- **Pickers (`alarm_pickers.dart`, all `AppSheet` + `AnimatedSelectList`):** `showReasonPicker` (pickable Reasons: the chosen one first, none another alarm plays; last row "New Reason" → the Create Reason flow pushed with `extra: CreateReasonPage.returnReasonExtra`, which pops with the made `Reason` instead of showing the ready screen, and it is chosen at once); `showSoundSheet` (rows with a `PlayButton`; a row with no audio, e.g. "None", is grey and silent; for soundtracks playing also chooses; the sheet owns its `SamplePlayer`, so nothing plays after it closes).
- **On the server first:** `CreateAlarmUseCase` uploads the alarm (`RemoteAlarmRepository.upload`) before keeping it on the device. `AlarmRemoteDataSource.insertAlarm` writes the editor's first card (as `groupDays` orders them: weekdays before the weekend) as an `alarm` row (`user_id` from `OwnUserId`, `time` = that card's next ring as a timestamptz, `week_days` = a JSON text array of day names `["Mon","Tue"]`, `reason_id`, `sound_track_id`, `alarm_sound_id`, `number_of_ring` = Ring again 0-2, `enable`), every other card as a `sub_alarm` row (`alarm_id`, `time`, `week_days`), and sets the chosen Reason's `alarm_id`. It then reads the alarm back as one object with its foreign keys (`alarmSelect`: `sub_alarms`, `reason` whole with its own joins, `sound_track`, `alarm_sound`; `reason!reason_id` because `reason.alarm_id` links the tables the other way too), and `alarmFromServer` turns that object into the device's `Alarm` (with `remoteId` = `alarm.id`). Any failed step removes what was already written. The joined `reason` (now with its `alarm_id`) is saved into the device's reasons table (`ReasonLocalDataSource.saveRow`), and a removed alarm saves the Reasons it freed (`alarm_id` null) the same way. Mapping: `alarm_server_model.dart` (`serverSchedules`, `scheduleColumns`, `alarmColumns`, `alarmFromServer`, `serverDayNames`).
- **One Reason, one alarm:** `reason.alarm_id` (the alarm that plays it; null = free) is the rule. `Reason.alarmId` reads it from the cached server row (the `reasons` table keeps the whole row as JSON, so the column needs no table change; an older copy without it is filled by the next reasons refresh). `CreateAlarmState.pickableReasons` offers only Reasons with no `alarmId` that no alarm on the device plays (`takenReasonIds`), with the chosen one first.
- **Offline:** when the upload fails the alarm is still made and kept on the device with no `remoteId`; `UploadPendingAlarmsUseCase` sends such alarms (those with a Reason) every time the app opens with a session (`DashboardBloc`, after `EnsureSessionEvent`). If the device then refuses to schedule the alarm, it is removed from the device and the server (`RemoteAlarmRepository.remove`).
- **Saved where:** the `alarms` table (drift v10 added `reason_id`, `sound_track_id`, `alarm_sound_id`, `ring_again`, `day_times`; v11 `remote_id`, the server's `alarm.id`). The Reason and the two sounds the alarm points at are already on the device (the reasons cache and the Alarm Audio cache), so the alarm works offline. **Native:** `PlatformAlarmScheduler` sends the next ring (`timeMs`) on the existing `scheduleAlarm` channel, the Reason's name as the alarm text, Ring again as the native repeats (`repeatCount` = again, `AlarmScheduler.ringAgainInterval` = 300 s apart), the chosen alarm sound's downloaded file (`tuneFile`, looked up in the device's `alarm_sound` list; left out when it is not downloaded, so the default tune rings) and, for repeating days, `ringDays` (`Alarm.ringDays`: weekday 1 = Mon .. 7 = Sun → minutes after midnight). Not native yet: the soundtrack.
- **Repeating alarms stay set:** the device sets each next ring by itself (see *Native Alarm Layer*), so a weekly alarm rings even if the app is never opened. On top of that, `RescheduleAlarmsUseCase` runs every time the app opens (`DashboardBloc` `RescheduleAlarmsEvent`, at launch and on resume, offline too): an enabled repeating alarm whose ring and its Ring again rings are over moves to `nextRingOf(alarm, now)` (the editor's `nextRing`, never a second copy of it), is set on the device again and saved with that time. One-off alarms are left alone.
- **Later (Edit Alarm):** the design's edit mode (Delete, "Save Changes" only after a change, the first-time "peek" at a closed card's wheel) is not built; the domain and widgets are ready for it.

### Settings Feature

`lib/features/settings/` (Clean Architecture, same shape as Reasons):

- **Domain:** `UserSettings` (`notifyBilling`, `notifyAlarms`, `notifyQuotes`; defaults true/true/false), `AppInfo` (name, version, build), `SettingsRepository`, and the use cases `GetSettingsUseCase`, `SaveSettingsUseCase`, `GetAppInfoUseCase`.
- **Data:** drift table `SettingsTable` (one row, id 1; `AppDatabase.schemaVersion` is now 3 with a `from < 3` migration). `SettingsLocalDataSource` returns the defaults when nothing was saved. `AppInfoDataSource` reads the version through `package_info_plus` (the only package added for this screen; it shows "Eala 1.0.0 (1)").
- **Presentation:** `SettingsBloc` (`LoadSettingsEvent`, `NotificationToggledEvent`; the switch moves at once, then saves, and reverts if saving fails), `SettingsPage`, and the widgets `ProfileCard`, `SettingsSwitchRow` (on the common `ListGroup` / `ListGroupRow`), `Horizon` (the warm glow at the bottom).
- Switches are `CupertinoSwitch` (the native 51 x 31 iOS switch) coloured with `AppColor.toggleOn/toggleOff`.
- Row text reuses the theme: `titleMedium` with a regular weight for labels, `bodyLarge` (with `height: 1.45`, `letterSpacing: 0`) for captions and the version line.
- **No account system yet**, so the page always shows the signed-out look: "Set your name" / "Not signed in", the "Sign In" row, and the plan value "Free" (`settings_plan_free`). The design's Premium badge, Credits row, "Sign Out" row, and their icons (`premium_crown`, `credit`, `logout`) are **deliberately not included** — add them, with their icons, when auth and subscriptions exist. Rows without a destination yet (Help, FAQ, …) do nothing on tap.
- Icons used here live in `assets/icons/settings/` (`Assets.icons.settings.*`).

### App Shell: Dashboard

`DashboardPage` (`lib/features/dashboard/`) is the **mother screen** and the app's home. It owns the floating `AppTabBar` and a `PageView` whose pages are the tabs, in order:

| Tab | Page | Feature |
|---|---|---|
| 0 Alarms | `MyAlarmsPage` | `lib/features/my_alarms/` (slot meter, the saved alarms as `AlarmCard`s, add card → Create Alarm) |
| 1 Reasons | `ReasonsPage` | `lib/features/reasons/` (list of saved reasons; created through Create Reason) |
| 2 Settings | `SettingsPage` | `lib/features/settings/` (notification switches, support and legal rows, signed-out look) |

- Tapping a tab calls `PageController.animateToPage`; swiping the pages sends `DashboardTabChangedEvent`, and `DashboardBloc` (selected index only) drives the tab bar highlight.
- Each tab is its own feature with its own BLoC provided inside its page (`instance<…Bloc>()`); the Dashboard holds no tab data. A tab page that must keep its state while another tab shows uses `AutomaticKeepAliveClientMixin`.
- To add a tab, add its two icons (outline + solid, in `assets/icons/tab/`), string, page and an `AppTabItem` in `DashboardPage`.
- Each tab page wraps its own content in `SafeArea(bottom: false)` and leaves ~100 bottom padding so content scrolls clear of the tab bar.

### Converting Design Code

Design screens are delivered as Dart files (e.g. exported from the web prototype). When converting one:

1. Create (or extend) the feature under `lib/features/<feature>/` with its `presentation/pages`, `bloc`, `widgets` (and `domain`/`data` when it owns data; reuse other features' UseCases when it does not).
2. Move every colour to `AppColor`, every text style to `AppTheme` (then `copyWith`), every string to `app_en.arb`, every constant to `AppConstant`, every icon to an SVG in `assets/icons/`.
3. Replace raw numbers with ScreenUtil (`.h`, `.w`, `.r`, `.spMin`, `REdgeInsets`).
4. Reuse anything already in `lib/core/widgets/`; move a widget there when a second screen needs it.
5. Register the page in go_router and its BLoC with injectable.

## 14. Application Constants

Create a centralized class named `AppConstant` to manage application-wide constant values.

- Store all common and required constant data in this class.
- Avoid hardcoding constant values throughout the application.
- Reuse predefined constants wherever applicable.
- Whenever a new application-wide constant is required, add it to `AppConstant`.
- `AppConstant` lives in `lib/core/constants/app_constant.dart` (e.g. `maxAlarmCount`, `pillRadius`).

Keep constants organized and maintain a consistent naming convention.

## 15. Backend Integration – Supabase

Use **Flutter Supabase** for server-side communication and backend integration.

- Use the existing Supabase setup and configuration.
- Follow the established Clean Architecture when integrating Supabase.
- Keep API and server communication inside the appropriate data layer.
- Use repositories and use cases to manage business logic and data access.
- Follow the established `dartz`-based response-handling approach.
- Synchronize server data with the local drift database.
- Keep the UI independent of direct Supabase calls.

All backend integrations must follow the same architecture and coding conventions.

## 16. Consistent Coding Structure & Development Standards

Maintaining a consistent coding structure throughout the entire application is mandatory.

- Follow the same architectural patterns across all features.
- Do not introduce different folder structures or coding approaches for individual features.
- Follow the existing naming conventions.
- Reuse common implementations wherever possible.
- Keep responsibilities separated according to Clean Architecture principles.
- Avoid unnecessary code, dependencies, abstractions, and implementations.
- Do not duplicate existing functionality.
- Do not introduce additional packages or architectural patterns without a genuine requirement.
- Always review existing implementations before adding new ones.

Every new implementation must follow the established project conventions.

## 17. Existing Functionality & Code Safety

Preserving existing functionality is a top priority.

Whenever implementing a new feature or modifying existing code:

1. Carefully inspect the existing implementation before making changes.
2. Understand the existing architecture, dependencies, and related functionality.
3. Make only the changes necessary to complete the requested task.
4. Avoid modifying unrelated files or existing implementations.
5. Ensure existing features and functionality continue working as expected.
6. Avoid introducing breaking changes or unnecessary refactoring.
7. Check for potential side effects before modifying shared components or common functionality.
8. Verify that the implementation follows the project's existing coding standards.

**Never break existing functionality while implementing new features.**

Be especially careful when modifying shared dependencies, common widgets, navigation, theme configurations, database structures, and application-wide components.

### Native Alarm Layer

The alarm feature relies on native code (`android/app/src/main/kotlin/com/eala/app/`, `ios/Runner/`) reached through `lib/core/platform/alarm_platform_client.dart` (MethodChannel `com.eala.app/alarm` / `app/alarm`, EventChannel `*_events`). Treat these channels as a contract: Android and iOS must behave the same, and any change on one side must be mirrored on the other. See `docs/alarm_test_matrix.md` for the scenarios to re-test.

- `AlarmPlatformClient` is an injectable lazy singleton; get it with `instance<AlarmPlatformClient>()`. Its `events` stream is **one shared native subscription** — never create another `EventChannel.receiveBroadcastStream()` for the alarm channel, it would take the events away from every other listener.
- The home screen (Dashboard) is wrapped in `AlarmEventListener` (`lib/features/alarm/presentation/widgets/`). It opens the message page after an alarm unlock (event or cold launch), the iOS ringing page, and the Android permission walkthrough. Keep it on whatever screen is the app's home; only the first mounted instance acts.
- The home route is `RouteNames.dashboardPath`; pages that need to return home use `GoRouter.of(context).go(RouteNames.dashboardPath)`.
- **`scheduleAlarm` keys** (`AlarmScheduleOptions`): `tuneFile` is a full path to a sound file on the device. Native makes the alarm's **own copy** when it is set (iOS: converted to CAF/IMA4 in `Library/Sounds` as `eala-<alarmId>-<file name>.caf`, so AlarmKit and notifications can play it by name; Android: `files/alarm_tunes/`), so Flutter may replace or delete the original later; the copy goes when the alarm is cancelled. Order: `tuneFile`, then `tuneAsset`, then the default tune. `ringDays` (weekday 1 = Mon .. 7 = Sun → minutes after midnight) makes a weekly alarm: iOS 26+ sets one AlarmKit weekly (`relative`) alarm per distinct time (ids from the alarm id, plus `"<alarmId>@<minutes>"` for further times), iOS < 26 a repeating calendar notification per day (`"<alarmId>#<day>"`); Android sets the next day itself in `AlarmReceiver` when the main alarm rings. Setting an alarm again replaces it. **Finishing the message (`dismissAlarm`) never cancels a weekly alarm** — only its ring-again repeats (iOS `AlarmScheduler.finish`; Android never cancelled there).
- **Reboot and app update:** Android's AlarmManager forgets every alarm then, so `AlarmBootReceiver` (`BOOT_COMPLETED`, `MY_PACKAGE_REPLACED`) sets each stored alarm (`AlarmConfigStore`) again without the app being opened: a weekly alarm on its next day, a one-off alarm at its saved `ringTimeMs` if that is still ahead (waiting ring-again repeats are not set again). iOS needs nothing: AlarmKit alarms and notifications survive a reboot.

## 18. README.md Maintenance & AI Agent Instructions

This `README.md` file is the primary reference document for understanding and developing this project.

Every developer and AI agent working on this project must:

- Read and understand this README before starting development.
- Follow all documented architectural and coding guidelines.
- Maintain the same coding structure and conventions throughout the project.
- Review the existing implementation before making changes.
- Avoid unnecessary code and modifications.
- Prioritize existing functionality and backward compatibility.

### Keep This Documentation Updated

Whenever a new development convention, architectural decision, important package, reusable implementation, or project-wide guideline is introduced, update this `README.md` accordingly if it is important for future development.

Do not document temporary implementation details or unnecessary information.

The README should always reflect the actual project architecture and development standards.

---

## Final Development Principles

Every implementation must follow these core principles:

1. **Consistency:** Maintain the same coding and architectural structure everywhere.
2. **Clean Architecture:** Follow the documented Feature-Based Clean Architecture.
3. **Reusability:** Reuse existing common components and implementations.
4. **Local-First:** Prioritize local data availability and background synchronization.
5. **Scalability:** Keep the application structured for future development.
6. **Maintainability:** Write clean, readable, and maintainable code.
7. **Localization:** Never hardcode user-facing strings.
8. **Responsiveness:** Use Flutter ScreenUtil for all applicable dimensions.
9. **Dependency Management:** Use get_it and generated dependency registration.
10. **Code Safety:** Never break existing functionality when introducing new changes.
11. **Minimal Changes:** Implement only what is required. Do not add unnecessary code, packages, abstractions, or features.
12. **Documentation:** Keep this README updated whenever an important project-wide development guideline changes.

**Important:** Do not simply implement a feature so that it works. Implement it by following the project's established architecture, coding conventions, and development guidelines. Every new feature must look and behave as though it was developed using the same standards as the rest of the application.
