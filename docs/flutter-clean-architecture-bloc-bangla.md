# Flutter এ Feature-Based Clean Architecture + BLoC State Management (বাংলা গাইড)

## ১. Clean Architecture কী এবং কেন দরকার?

Clean Architecture হলো একটা ডিজাইন প্যাটার্ন যেখানে আমরা অ্যাপকে কয়েকটা **আলাদা আলাদা লেয়ারে** ভাগ করি, যাতে:

- প্রতিটা লেয়ার একে অপরের থেকে **স্বাধীন** থাকে (Loosely Coupled)
- **UI বদলালে বিজনেস লজিক নষ্ট হয় না**
- **Database/API বদলালে বাকি কোড নষ্ট হয় না**
- Unit Test লেখা সহজ হয়
- টিমে কাজ করা সহজ হয় (একেকজন একেক লেয়ারে কাজ করতে পারে)

মূলত ৩টা লেয়ার থাকে:

```
┌─────────────────────────────────────┐
│           Presentation Layer         │  ← UI + BLoC (State Management)
├─────────────────────────────────────┤
│             Domain Layer              │  ← Entity + UseCase + Abstraction
├─────────────────────────────────────┤
│              Data Layer               │  ← Model + Repository Impl + DataSource
└─────────────────────────────────────┘
```

**নিয়মটা মনে রাখুন:** নির্ভরতা (Dependency) সবসময় **বাইরে থেকে ভিতরের দিকে** যায়।
অর্থাৎ, Presentation → Domain কে চেনে, Data → Domain কে চেনে, কিন্তু **Domain কাউকে চেনে না**। Domain সবচেয়ে "pure" এবং "independent" লেয়ার।

---

## ২. Feature-Based ফোল্ডার স্ট্রাকচার কী?

দুই ধরনের স্ট্রাকচার হয়:

1. **Layer-based**: প্রথমে `presentation/`, `domain/`, `data/` — তারপর ভিতরে সব ফিচার একসাথে মিশে থাকে। বড় প্রজেক্টে এটা অগোছালো হয়ে যায়।
2. **Feature-based** (Recommended): প্রথমে প্রতিটা ফিচার আলাদা ফোল্ডার, তারপর প্রতিটা ফিচারের ভিতরে নিজস্ব `presentation/`, `domain/`, `data/` থাকে।

```
lib/
├── core/
│   ├── error/
│   │   └── failures.dart
│   ├── usecase/
│   │   └── usecase.dart
│   └── network/
│       └── network_info.dart
│
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   └── auth_remote_data_source.dart
│   │   │   ├── models/
│   │   │   │   └── user_model.dart
│   │   │   └── repositories/
│   │   │       └── auth_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── user_entity.dart
│   │   │   ├── repositories/
│   │   │   │   └── auth_repository.dart   ← Abstraction
│   │   │   └── usecases/
│   │   │       └── login_usecase.dart
│   │   └── presentation/
│   │       ├── bloc/
│   │       │   ├── auth_bloc.dart
│   │       │   ├── auth_event.dart
│   │       │   └── auth_state.dart
│   │       └── pages/
│   │           └── login_page.dart
│   │
│   └── todo/
│       ├── data/
│       ├── domain/
│       └── presentation/
│
└── main.dart
```

**সুবিধা:** নতুন একটা ফিচার (যেমন "Profile" বা "Chat") যোগ করতে চাইলে শুধু `features/` এর ভিতরে নতুন একটা ফোল্ডার বানালেই হয় — বাকি কোড না ঘেঁটেই।

---

## ৩. প্রতিটা লেয়ারের কাজ কী (থিওরি)

### ৩.১ Domain Layer (সবচেয়ে গুরুত্বপূর্ণ, Pure Dart — কোনো Flutter dependency নেই)

- **Entity**: বিজনেসের মূল ডেটা মডেল। শুধু ফিল্ড আর কনস্ট্রাক্টর — কোনো JSON parsing নেই।
- **Repository Abstraction (Interface)**: বলে দেয় "কী কী কাজ করা যাবে" কিন্তু "কীভাবে" সেটা বলে না। যেমন `abstract class AuthRepository`।
- **UseCase**: একটা নির্দিষ্ট বিজনেস অ্যাকশন। যেমন `LoginUseCase`, `GetTodosUseCase`। এটা Repository ব্যবহার করে কিন্তু জানে না Repository আসলে API থেকে ডেটা আনছে না Local DB থেকে।

### ৩.২ Data Layer (Domain এর Interface বাস্তবায়ন করে)

- **Model**: Entity কে extend করে, কিন্তু সাথে `fromJson()`, `toJson()` ইত্যাদি থাকে।
- **DataSource**: আসল API কল বা Database কোয়েরি এখানে হয় (Remote/Local)।
- **Repository Implementation**: Abstraction এর বাস্তব রূপ। DataSource থেকে ডেটা এনে Entity তে রূপান্তর করে রিটার্ন করে। এখানে Error handling (Success/Failure) হয়।

### ৩.৩ Presentation Layer (Flutter UI + BLoC)

- **BLoC**: Event শুনে UseCase কল করে, তারপর State emit করে।
- **Event**: ইউজার কী অ্যাকশন করলো (যেমন `LoginButtonPressed`)।
- **State**: UI কী দেখাবে (যেমন `AuthLoading`, `AuthSuccess`, `AuthFailure`)।
- **Page/Widget**: BLoC এর State শুনে UI রেন্ডার করে।

---

## ৪. উদাহরণ ১: Auth (Login) ফিচার — সম্পূর্ণ কোড সহ

### ধাপ ১ — Core: Failure ক্লাস (সব ফিচার শেয়ার করবে)

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

### ধাপ ২ — Core: UseCase এর সাধারণ Interface

আমরা `dartz` প্যাকেজের `Either<Failure, SuccessType>` ব্যবহার করবো error handling এর জন্য (try-catch এর বদলে functional approach)।

```dart
// lib/core/usecase/usecase.dart
import 'package:dartz/dartz.dart';
import '../error/failures.dart';

abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

// যদি কোনো প্যারামিটার লাগে না, তাহলে এটা ব্যবহার করা হয়
class NoParams {}
```

### ধাপ ৩ — Domain Layer: Entity

```dart
// lib/features/auth/domain/entities/user_entity.dart
class UserEntity {
  final String id;
  final String name;
  final String email;

  const UserEntity({
    required this.id,
    required this.name,
    required this.email,
  });
}
```

> লক্ষ্য করুন: এখানে কোনো `fromJson`, `toJson`, বা Flutter widget নেই। এটা ১০০% pure business object।

### ধাপ ৪ — Domain Layer: Repository Abstraction

```dart
// lib/features/auth/domain/repositories/auth_repository.dart
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<Either<Failure, UserEntity>> login({
    required String email,
    required String password,
  });

  Future<Either<Failure, void>> logout();
}
```

এটা শুধু একটা **চুক্তি (contract)** — বাস্তবে কীভাবে login হবে (Firebase/REST API/GraphQL) সেটা Domain layer জানেই না।

### ধাপ ৫ — Domain Layer: UseCase

```dart
// lib/features/auth/domain/usecases/login_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase implements UseCase<UserEntity, LoginParams> {
  final AuthRepository repository;

  LoginUseCase(this.repository);

  @override
  Future<Either<Failure, UserEntity>> call(LoginParams params) async {
    return await repository.login(
      email: params.email,
      password: params.password,
    );
  }
}

class LoginParams {
  final String email;
  final String password;

  LoginParams({required this.email, required this.password});
}
```

একটা UseCase = একটা নির্দিষ্ট কাজ। এভাবে প্রতিটা ফিচারের জন্য আলাদা UseCase বানালে কোড পরিষ্কার থাকে এবং টেস্ট করা সহজ হয়।

### ধাপ ৬ — Data Layer: Model (Entity কে Extend করে)

```dart
// lib/features/auth/data/models/user_model.dart
import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.name,
    required super.email,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
    };
  }
}
```

### ধাপ ৭ — Data Layer: Remote DataSource

```dart
// lib/features/auth/data/datasources/auth_remote_data_source.dart
import 'package:dio/dio.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> login({required String email, required String password});
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio dio;

  AuthRemoteDataSourceImpl(this.dio);

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final response = await dio.post('/login', data: {
      'email': email,
      'password': password,
    });

    if (response.statusCode == 200) {
      return UserModel.fromJson(response.data);
    } else {
      throw ServerException();
    }
  }
}

class ServerException implements Exception {}
```

### ধাপ ৮ — Data Layer: Repository Implementation

```dart
// lib/features/auth/data/repositories/auth_repository_impl.dart
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, UserEntity>> login({
    required String email,
    required String password,
  }) async {
    try {
      final user = await remoteDataSource.login(
        email: email,
        password: password,
      );
      return Right(user); // Success হলে Right এ ডেটা যায়
    } on ServerException {
      return const Left(ServerFailure('লগইন ব্যর্থ হয়েছে'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    // logout logic
    return const Right(null);
  }
}
```

এখানেই আসল "Abstraction থেকে বাস্তবায়ন" ঘটে। এই ক্লাসটা `AuthRepository` এর প্রতিশ্রুতি পূরণ করছে।

### ধাপ ৯ — Presentation Layer: BLoC Event

```dart
// lib/features/auth/presentation/bloc/auth_event.dart
import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object> get props => [];
}

class LoginButtonPressed extends AuthEvent {
  final String email;
  final String password;

  const LoginButtonPressed({required this.email, required this.password});

  @override
  List<Object> get props => [email, password];
}
```

### ধাপ ১০ — Presentation Layer: BLoC State

```dart
// lib/features/auth/presentation/bloc/auth_state.dart
import 'package:equatable/equatable.dart';
import '../../domain/entities/user_entity.dart';

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthSuccess extends AuthState {
  final UserEntity user;
  const AuthSuccess(this.user);

  @override
  List<Object> get props => [user];
}

class AuthFailureState extends AuthState {
  final String message;
  const AuthFailureState(this.message);

  @override
  List<Object> get props => [message];
}
```

### ধাপ ১১ — Presentation Layer: BLoC (মূল লজিক)

```dart
// lib/features/auth/presentation/bloc/auth_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/login_usecase.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;

  AuthBloc({required this.loginUseCase}) : super(AuthInitial()) {
    on<LoginButtonPressed>(_onLoginButtonPressed);
  }

  Future<void> _onLoginButtonPressed(
    LoginButtonPressed event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    final result = await loginUseCase(
      LoginParams(email: event.email, password: event.password),
    );

    result.fold(
      (failure) => emit(AuthFailureState(failure.message)),
      (user) => emit(AuthSuccess(user)),
    );
  }
}
```

লক্ষ্য করুন: BLoC জানেই না ডেটা API থেকে আসছে না Firebase থেকে। এটা শুধু `LoginUseCase` কল করছে।

### ধাপ ১২ — Presentation Layer: UI

```dart
// lib/features/auth/presentation/pages/login_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class LoginPage extends StatelessWidget {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('লগইন')),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthFailureState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
          if (state is AuthSuccess) {
            Navigator.pushReplacementNamed(context, '/home');
          }
        },
        builder: (context, state) {
          if (state is AuthLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'ইমেইল'),
                ),
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(labelText: 'পাসওয়ার্ড'),
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    context.read<AuthBloc>().add(
                          LoginButtonPressed(
                            email: emailController.text,
                            password: passwordController.text,
                          ),
                        );
                  },
                  child: const Text('লগইন করুন'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
```

### ধাপ ১৩ — Dependency Injection (get_it দিয়ে সব জোড়া লাগানো)

```dart
// lib/features/auth/injection_container.dart
import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'data/datasources/auth_remote_data_source.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'domain/repositories/auth_repository.dart';
import 'domain/usecases/login_usecase.dart';
import 'presentation/bloc/auth_bloc.dart';

final sl = GetIt.instance; // sl = Service Locator

void initAuthFeature() {
  // Bloc
  sl.registerFactory(() => AuthBloc(loginUseCase: sl()));

  // UseCase
  sl.registerLazySingleton(() => LoginUseCase(sl()));

  // Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sl()),
  );

  // DataSource
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(sl()),
  );

  // External
  sl.registerLazySingleton(() => Dio());
}
```

এখানে দেখুন `AuthRepository` (Abstraction) রেজিস্টার হচ্ছে `AuthRepositoryImpl` (বাস্তবায়ন) দিয়ে। এই একটা লাইনই পুরো Dependency Inversion Principle বাস্তবায়ন করছে — চাইলে ভবিষ্যতে `AuthRepositoryImpl` এর বদলে `FirebaseAuthRepositoryImpl` বসিয়ে দিলেই হবে, বাকি কোড একই থাকবে।

`main.dart` এ:

```dart
void main() {
  initAuthFeature();
  runApp(const MyApp());
}
```

এবং BLoC ব্যবহার করার সময়:

```dart
BlocProvider(
  create: (_) => sl<AuthBloc>(),
  child: LoginPage(),
)
```

---

## ৫. উদাহরণ ২: Todo ফিচার (সংক্ষেপে, প্যাটার্ন বোঝানোর জন্য)

এবার একই প্যাটার্ন দিয়ে দ্বিতীয় ফিচার — এখানে বুঝবেন প্যাটার্নটা কতটা reusable।

### Entity

```dart
// lib/features/todo/domain/entities/todo_entity.dart
class TodoEntity {
  final String id;
  final String title;
  final bool isCompleted;

  const TodoEntity({
    required this.id,
    required this.title,
    required this.isCompleted,
  });
}
```

### Repository Abstraction

```dart
// lib/features/todo/domain/repositories/todo_repository.dart
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/todo_entity.dart';

abstract class TodoRepository {
  Future<Either<Failure, List<TodoEntity>>> getTodos();
  Future<Either<Failure, TodoEntity>> addTodo(String title);
  Future<Either<Failure, void>> deleteTodo(String id);
}
```

### UseCases (একাধিক, প্রতিটা একটা কাজের জন্য)

```dart
// lib/features/todo/domain/usecases/get_todos_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/todo_entity.dart';
import '../repositories/todo_repository.dart';

class GetTodosUseCase implements UseCase<List<TodoEntity>, NoParams> {
  final TodoRepository repository;
  GetTodosUseCase(this.repository);

  @override
  Future<Either<Failure, List<TodoEntity>>> call(NoParams params) {
    return repository.getTodos();
  }
}
```

```dart
// lib/features/todo/domain/usecases/add_todo_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/todo_entity.dart';
import '../repositories/todo_repository.dart';

class AddTodoUseCase implements UseCase<TodoEntity, String> {
  final TodoRepository repository;
  AddTodoUseCase(this.repository);

  @override
  Future<Either<Failure, TodoEntity>> call(String title) {
    return repository.addTodo(title);
  }
}
```

### BLoC (Event, State, Bloc — একসাথে সংক্ষেপে)

```dart
// todo_event.dart
abstract class TodoEvent {}
class LoadTodos extends TodoEvent {}
class AddTodoEvent extends TodoEvent {
  final String title;
  AddTodoEvent(this.title);
}

// todo_state.dart
abstract class TodoState {}
class TodoInitial extends TodoState {}
class TodoLoading extends TodoState {}
class TodoLoaded extends TodoState {
  final List<TodoEntity> todos;
  TodoLoaded(this.todos);
}
class TodoError extends TodoState {
  final String message;
  TodoError(this.message);
}

// todo_bloc.dart
class TodoBloc extends Bloc<TodoEvent, TodoState> {
  final GetTodosUseCase getTodosUseCase;
  final AddTodoUseCase addTodoUseCase;

  TodoBloc({required this.getTodosUseCase, required this.addTodoUseCase})
      : super(TodoInitial()) {
    on<LoadTodos>((event, emit) async {
      emit(TodoLoading());
      final result = await getTodosUseCase(NoParams());
      result.fold(
        (failure) => emit(TodoError(failure.message)),
        (todos) => emit(TodoLoaded(todos)),
      );
    });

    on<AddTodoEvent>((event, emit) async {
      final result = await addTodoUseCase(event.title);
      result.fold(
        (failure) => emit(TodoError(failure.message)),
        (_) => add(LoadTodos()), // যোগ হলে আবার লোড করো
      );
    });
  }
}
```

**খেয়াল করুন**: `auth` ফিচার আর `todo` ফিচার — দুটোই একই প্যাটার্ন (Entity → Repository Abstraction → UseCase → BLoC → UI) অনুসরণ করছে। এটাই Clean Architecture এর শক্তি — একবার প্যাটার্ন শিখলে যেকোনো ফিচারে এটা কপি করা যায়।

---

## ৬. পুরো ডেটা ফ্লো — একনজরে

```
User Tap Button
      │
      ▼
  UI dispatches Event  ────────►  BLoC
      │                             │
      │                             ▼
      │                     BLoC calls UseCase
      │                             │
      │                             ▼
      │                UseCase calls Repository (Abstraction)
      │                             │
      │                             ▼
      │            RepositoryImpl calls DataSource (API/DB)
      │                             │
      │                             ▼
      │              DataSource রিটার্ন করে Model
      │                             │
      │                             ▼
      │        RepositoryImpl Model কে Entity বানিয়ে Either<Failure, Entity> রিটার্ন করে
      │                             │
      │                             ▼
      │              BLoC ফলাফল অনুযায়ী State emit করে
      │                             │
      ◄─────────────────────────────┘
UI নতুন State দেখে rebuild হয়
```

---

## ৭. কেন Abstraction (Interface) গুরুত্বপূর্ণ?

ধরুন আজকে আপনি REST API দিয়ে login করাচ্ছেন। কাল যদি ক্লায়েন্ট বলে "Firebase Auth ব্যবহার করো", তাহলে আপনাকে শুধু করতে হবে:

```dart
class FirebaseAuthRepositoryImpl implements AuthRepository {
  // Firebase দিয়ে implement করুন
}
```

এবং injection_container এ একটা লাইন বদলাতে হবে:

```dart
sl.registerLazySingleton<AuthRepository>(() => FirebaseAuthRepositoryImpl(sl()));
```

**BLoC, UseCase, UI — কোনোটাই বদলাতে হবে না!** কারণ তারা সবাই `AuthRepository` **abstraction** এর সাথে কথা বলে, বাস্তবায়নের সাথে না। একে বলে **Dependency Inversion Principle (DIP)** — SOLID এর "D"।

---

## ৮. দরকারি Packages

```yaml
dependencies:
  flutter_bloc: ^8.1.6      # BLoC state management
  equatable: ^2.0.5         # State/Event এর == অপারেটর সহজ করতে
  dartz: ^0.10.1            # Either<Failure, Success> এর জন্য
  get_it: ^7.7.0            # Dependency Injection
  dio: ^5.4.0               # HTTP client
```

---

## ৯. সংক্ষেপে মনে রাখার সূত্র

| লেয়ার | কী থাকে | নির্ভর করে কার উপর |
|---|---|---|
| **Presentation** | BLoC, Event, State, Page/Widget | Domain এর উপর |
| **Domain** | Entity, Repository (Abstract), UseCase | **কারো উপর না (Pure Dart)** |
| **Data** | Model, DataSource, Repository (Impl) | Domain এর উপর (Abstraction implement করে) |

- **Entity** = ডেটার আসল রূপ (শুধু ফিল্ড)
- **UseCase** = একটা নির্দিষ্ট বিজনেস অ্যাকশন (এক ক্লাস = এক কাজ)
- **Repository Abstraction** = চুক্তি/নিয়ম, বাস্তবায়ন নয়
- **Repository Implementation** = আসল কাজ (API/DB কল)
- **BLoC** = Event নেয়, UseCase কল করে, State দেয়

এই প্যাটার্নটা একবার আয়ত্ত করলে, আপনি যত ইচ্ছা ফিচার (Profile, Chat, Payment, Notification) একই কাঠামোয় যোগ করতে পারবেন — কোড পরিষ্কার, টেস্টেবল এবং scalable থাকবে।
