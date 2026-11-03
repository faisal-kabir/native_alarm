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

- Presentation → knows Domain only (never Data, never DataSources, never Supabase/Isar).
- Data → knows Domain (implements its abstractions).
- **Domain knows nobody.** It is pure Dart: no Flutter imports, no `fromJson`, no Supabase/Isar/Dio types.

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
│   └── platform/                  ← native MethodChannel clients (alarm)
│
├── features/
│   └── <feature>/
│       ├── data/
│       │   ├── datasources/
│       │   │   ├── <feature>_remote_data_source.dart   ← Supabase calls
│       │   │   └── <feature>_local_data_source.dart    ← Isar / secure storage
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
- **Model** – `extends` the Entity and adds `fromJson()` / `toJson()` (and Isar mapping when needed).
- **DataSource** – where the real Supabase query / Isar query happens. Returns Models and **throws** exceptions (`ServerException`, `CacheException`) on error — it never returns `Either`.
- **Repository (impl)** – implements the Domain abstraction. Calls DataSources, applies the local-first flow (section 4), catches exceptions and converts them to `Left(Failure)`; success goes to `Right(data)`.

**Presentation**
- **Event** – what the user did (`LoginButtonPressed`). Extends `Equatable`.
- **State** – what the UI shows (`Initial`, `Loading`, `Success`, `Failure`). Extends `Equatable`.
- **BLoC** – listens to Events, calls UseCases, `fold`s the `Either` result and emits States. It only knows UseCases — never repositories' implementations, DataSources, Supabase or Isar.
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
| External (Supabase client, Isar, secure storage) | `@module` with `@preResolve` / `@lazySingleton` getters |

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
  → RepositoryImpl calls Local/Remote DataSource (Isar / Supabase)
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
5. `data/datasources/` – remote (Supabase) and/or local (Isar) DataSource, abstract + impl, throwing exceptions.
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
- **isar:** For managing the application's internal local database. The project uses **`isar_community`** (the maintained drop-in fork of Isar 3; original `isar 3.1.0` is unmaintained and does not build with this project's AGP 9). Import it as `package:isar_community/isar.dart`.

### Isar Setup

- The database is opened once in `lib/core/database/database_module.dart` (an injectable `@module`, `@preResolve`), so `Isar` is injected into local DataSources.
- Every new `@collection` schema must be added to the `Isar.open([...])` list there.
- Collections live in the feature's `data/models/` (e.g. `alarm_isar_model.dart`) with `fromEntity()` / `toEntity()` mapping; Domain never sees Isar types.
- `lib/core/di/injection.dart` defines `instance` and `configureDependencies()`, awaited in `main()` before `runApp`.
- After changing a collection or an injectable class, run `dart run build_runner build` (the `--delete-conflicting-outputs` flag is accepted but ignored by the current build_runner).

### Local-First Data Management

The application must follow a **Local-First Data Architecture**.

The expected workflow is:

1. When data is requested for the first time, fetch it from the server.
2. Store the retrieved data in the local Isar database.
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

## 7. Navigation & Routing

- Use **go_router** for application navigation and route management.
- The package has already been added to the project.
- Register and manage all application pages through the established go_router configuration (`lib/core/router/`).
- Follow the existing routing structure when adding new pages.
- Avoid implementing separate navigation approaches or using unnecessary navigation packages.

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

## 13. Common Widgets & Reusable Components

- Store all common and reusable widgets in a separate, centralized location.
- Before creating a new widget, check whether an appropriate reusable widget already exists.
- Reuse existing common widgets wherever possible.
- If a widget is required in multiple places, consider making it a common widget.
- Avoid duplicating widget implementations across different features.
- Maintain a consistent design and implementation approach for reusable components.

Feature-specific widgets should remain inside their respective feature structures unless they are genuinely reusable across the application.

## 14. Application Constants

Create a centralized class named `AppConstant` to manage application-wide constant values.

- Store all common and required constant data in this class.
- Avoid hardcoding constant values throughout the application.
- Reuse predefined constants wherever applicable.
- Whenever a new application-wide constant is required, add it to `AppConstant`.

Keep constants organized and maintain a consistent naming convention.

## 15. Backend Integration – Supabase

Use **Flutter Supabase** for server-side communication and backend integration.

- Use the existing Supabase setup and configuration.
- Follow the established Clean Architecture when integrating Supabase.
- Keep API and server communication inside the appropriate data layer.
- Use repositories and use cases to manage business logic and data access.
- Follow the established `dartz`-based response-handling approach.
- Synchronize server data with the local Isar database.
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
