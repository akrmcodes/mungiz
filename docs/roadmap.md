# Mungiz — Task Management System
## Implementation Roadmap

| Field          | Detail                                      |
| :------------- | :------------------------------------------ |
| **Project**    | Mungiz — Task Reminder & Assignment System  |
| **Version**    | 1.0                                         |
| **Date**       | April 18, 2026                              |
| **Companion**  | [plan.md](./plan.md) (SDLC Plan)            |
| **Status**     | Draft — Pending Stakeholder Approval        |

---

## Table of Contents

- [Section A: MVP (Stages 1–7)](#section-a-mvp-stages-17)
- [Section B: Post-MVP (Stages 8–12)](#section-b-post-mvp-stages-812)

---

## Pre-Stage: Developer Environment & AI Tooling Configuration

> This section must be completed **before** any coding begins. It establishes the developer environment, project dependencies, and AI-assisted coding infrastructure.

### 0.1 — MCP (Model Context Protocol) Configuration

Configure the following MCP servers to create a high-performance, AI-assisted development workflow. These servers grant your AI coding assistant (Cursor, Copilot, Claude Code, Gemini Code Assist) deep contextual awareness of your project.

#### Required MCP Servers

| MCP Server                         | Purpose                                                          | Transport |
| :--------------------------------- | :--------------------------------------------------------------- | :-------- |
| **Dart & Flutter MCP Server**      | Flutter-specific tooling: run analysis, manage pubspec, search pub.dev, hot reload, inspect widget tree. | `stdio`   |
| **Filesystem MCP Server**         | Secure read/write access to project files. Enables AI to navigate, create, and modify code files directly. | `stdio`   |
| **GitHub MCP Server**             | Repository management: create issues, manage PRs, review code, create branches — all via AI assistant. | `stdio`   |
| **Supabase MCP Server**           | Database introspection: inspect schema, test queries, manage migrations, and audit RLS policies via AI. | `stdio`   |
| **Memory/Context Server**         | Persistent AI memory across sessions. Retains project decisions, architecture notes, and developer preferences. | `stdio`   |

#### Configuration File

Create `.vscode/mcp.json` (for VS Code) or configure in your IDE's MCP settings:

```json
{
  "mcpServers": {
    "dart-flutter": {
      "command": "npx",
      "args": ["-y", "@anthropic/dart-flutter-mcp-server", "--project-dir", "."]
    },
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "/path/to/mungiz"]
    },
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "${env:GITHUB_PAT}"
      }
    },
    "supabase": {
      "command": "npx",
      "args": ["-y", "@supabase/mcp-server"],
      "env": {
        "SUPABASE_URL": "${env:SUPABASE_URL}",
        "SUPABASE_SERVICE_ROLE_KEY": "${env:SUPABASE_SERVICE_ROLE_KEY}"
      }
    }
  }
}
```

#### Pre-Stage Checklist

- [ ] Install Node.js ≥ 18 (required for `npx` MCP servers)
- [ ] Install Flutter SDK (stable channel, latest)
- [ ] Install Dart SDK (bundled with Flutter)
- [ ] Configure IDE to use the MCP servers listed above
- [ ] Verify each MCP server connects successfully (check IDE MCP panel)
- [ ] Create a `.env` file at project root with Supabase credentials (add to `.gitignore`)
- [ ] Install VS Code extensions: Flutter, Dart, Error Lens, GitLens

---

### 0.2 — Project Dependencies (`pubspec.yaml`)

The following is the exact dependency manifest for the project. All packages are pinned to verified compatible versions.

```yaml
name: mungiz
description: A lightweight task management & reminder system.
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.5.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter

  # ── State Management ──────────────────────────────
  flutter_riverpod: ^2.5.1          # Riverpod integration for Flutter
  riverpod_annotation: ^2.3.5       # @riverpod annotation support

  # ── Backend (Supabase) ────────────────────────────
  supabase_flutter: ^2.7.0          # Supabase client SDK for Flutter

  # ── Data Modeling ─────────────────────────────────
  freezed_annotation: ^2.4.1        # Immutable data class annotations
  json_annotation: ^4.9.0           # JSON serialization annotations

  # ── Navigation ────────────────────────────────────
  go_router: ^14.0.0                # Declarative routing with deep linking

  # ── UI Utilities ──────────────────────────────────
  flutter_slidable: ^3.1.1          # Swipe-to-dismiss / swipe actions
  intl: ^0.19.0                     # Date/time formatting & i18n
  gap: ^3.0.1                       # SizedBox replacement for spacing
  google_fonts: ^6.2.1              # Google Fonts integration
  flutter_animate: ^4.5.0           # Declarative animation builder

  # ── Local Notifications (Post-MVP) ────────────────
  # flutter_local_notifications: ^21.0.0
  # timezone: ^0.9.4

dev_dependencies:
  flutter_test:
    sdk: flutter

  # ── Code Generation ───────────────────────────────
  build_runner: ^2.4.9              # Code generation orchestrator
  riverpod_generator: ^2.4.5        # Generates Riverpod providers from annotations
  freezed: ^2.4.7                   # Generates immutable data classes
  json_serializable: ^6.7.1         # Generates fromJson/toJson methods

  # ── Testing Utilities ─────────────────────────────
  mocktail: ^1.0.4                  # Lightweight mocking library
  # patrol: ^3.12.0                 # Integration testing (Post-MVP)

  # ── Linting ───────────────────────────────────────
  flutter_lints: ^4.0.0             # Official Flutter lint rules

flutter:
  uses-material-design: true
```

#### Dependency Checklist

- [ ] Create the Flutter project: `flutter create --org com.mungiz --project-name mungiz .`
- [ ] Replace default `pubspec.yaml` with the manifest above
- [ ] Run `flutter pub get` — verify zero resolution errors
- [ ] Run `dart run build_runner build --delete-conflicting-outputs` — verify code gen works
- [ ] Add `*.g.dart` and `*.freezed.dart` patterns to `.gitignore` (optional, team preference)

---

# Section A: MVP (Stages 1–7)

> **Scope**: Only features strictly required by the client's original specification.
> - Create personal tasks or assign tasks to a specific person
> - Display required tasks
> - Hide completed tasks

---

## Stage 1 — Project Scaffolding & Core Infrastructure

**Sprint**: Week 1 | **Estimated Effort**: 3–4 hours

### Objective
Establish the project skeleton, configure theming, set up the router, and initialize the Supabase client.

### Tasks

- [ ] **1.1** — Create the feature-first directory structure:
  ```
  lib/
  ├── main.dart
  ├── app.dart
  ├── core/
  │   ├── constants/
  │   │   └── app_constants.dart
  │   ├── theme/
  │   │   ├── app_theme.dart
  │   │   └── app_colors.dart
  │   ├── router/
  │   │   └── app_router.dart
  │   ├── providers/
  │   │   └── supabase_providers.dart
  │   └── utils/
  │       └── extensions.dart
  ├── features/
  │   ├── auth/
  │   │   ├── data/
  │   │   ├── domain/
  │   │   └── presentation/
  │   └── tasks/
  │       ├── data/
  │       ├── domain/
  │       └── presentation/
  │           ├── screens/
  │           └── widgets/
  └── generated/
  ```
- [ ] **1.2** — Configure `main.dart`:
  - Initialize `WidgetsFlutterBinding`
  - Initialize Supabase with URL and Anon Key from environment
  - Wrap app in `ProviderScope`
- [ ] **1.3** — Configure `app.dart`:
  - Set up `MaterialApp.router` with GoRouter
  - Apply custom `ThemeData` (light mode)
  - Configure Google Fonts as default text theme
- [ ] **1.4** — Configure `app_router.dart`:
  - Define initial routes: `/login`, `/register`, `/tasks`
  - Implement `redirect` guard: unauthenticated → `/login`, authenticated → `/tasks`
- [ ] **1.5** — Configure `supabase_providers.dart`:
  - Create a Riverpod provider exposing the `SupabaseClient` instance
  - Create an `authStateChangesProvider` that streams `AuthState`
- [ ] **1.6** — Configure `app_theme.dart` and `app_colors.dart`:
  - Define a cohesive color palette (primary, secondary, surface, error)
  - Configure `ThemeData` with Material 3 design tokens
  - Set up typography scale using Google Fonts (e.g., Inter or Outfit)

### Deliverable
A running Flutter app that displays a placeholder screen, initializes Supabase, and routes based on auth state.

### Verification
- [ ] `flutter run` launches without errors on Android emulator, iOS simulator, and Chrome
- [ ] `dart analyze` returns zero warnings
- [ ] Supabase client initializes (verify via debug logs)

---

## Stage 2 — Supabase Backend Setup

**Sprint**: Week 1 | **Estimated Effort**: 2–3 hours

### Objective
Configure the Supabase project with the database schema, RLS policies, and authentication settings.

### Tasks

- [ ] **2.1** — Create a new Supabase project (or use existing)
  - Note the Project URL and Anon Key
  - Store in `.env` file (do NOT commit to git)
- [ ] **2.2** — Create the `profiles` table:
  ```sql
  CREATE TABLE profiles (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    email TEXT NOT NULL UNIQUE,
    display_name TEXT,
    avatar_url TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
  );
  ```
- [ ] **2.3** — Create a trigger to auto-create a profile on user signup:
  ```sql
  CREATE OR REPLACE FUNCTION public.handle_new_user()
  RETURNS TRIGGER AS $$
  BEGIN
    INSERT INTO public.profiles (id, email, display_name)
    VALUES (NEW.id, NEW.email, NEW.raw_user_meta_data->>'display_name');
    RETURN NEW;
  END;
  $$ LANGUAGE plpgsql SECURITY DEFINER;
  
  CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
  ```
- [ ] **2.4** — Create the `tasks` table:
  ```sql
  CREATE TABLE tasks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    description TEXT,
    is_completed BOOLEAN NOT NULL DEFAULT false,
    due_at TIMESTAMPTZ,
    created_by UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    assigned_to UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
  );
  ```
- [ ] **2.5** — Enable Row Level Security on both tables:
  ```sql
  ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
  ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
  ```
- [ ] **2.6** — Create RLS policies as defined in [plan.md § 3.3](#row-level-security-rls-policies)
- [ ] **2.7** — Enable Realtime on the `tasks` table:
  - Supabase Dashboard → Database → Replication → Enable `tasks` table
- [ ] **2.8** — Configure Authentication:
  - Enable Email/Password provider in Supabase Auth settings
  - Disable email confirmation for development (re-enable for production)
- [ ] **2.9** — Create indexes for performance:
  ```sql
  CREATE INDEX idx_tasks_assigned_to ON tasks(assigned_to);
  CREATE INDEX idx_tasks_created_by ON tasks(created_by);
  CREATE INDEX idx_tasks_is_completed ON tasks(is_completed);
  ```

### Deliverable
A fully configured Supabase project with schema, RLS, triggers, and indexes.

### Verification
- [ ] Insert a test user via Supabase Auth Dashboard — verify profile is auto-created
- [ ] Insert a test task via SQL Editor — verify RLS blocks unauthorized access
- [ ] Verify Realtime is streaming changes on the `tasks` table

---

## Stage 3 — Authentication Feature

**Sprint**: Week 2 | **Estimated Effort**: 5–6 hours

### Objective
Implement the full authentication flow: registration, login, logout, and auth state management.

### Tasks

#### 3A — Domain Layer
- [ ] **3.1** — Create `UserProfile` Freezed model in `features/auth/domain/user_profile.dart`:
  - Fields: `id`, `email`, `displayName`, `avatarUrl`, `createdAt`
  - Include `fromJson`/`toJson` factory methods
- [ ] **3.2** — Run code generation: `dart run build_runner build --delete-conflicting-outputs`

#### 3B — Data Layer
- [ ] **3.3** — Create `AuthRepository` in `features/auth/data/auth_repository.dart`:
  - `signUp(email, password, displayName)` → calls `supabase.auth.signUp()`
  - `signIn(email, password)` → calls `supabase.auth.signInWithPassword()`
  - `signOut()` → calls `supabase.auth.signOut()`
  - `getCurrentUser()` → returns current session user
  - `onAuthStateChange` → exposes the auth state stream
- [ ] **3.4** — Create Riverpod provider for `AuthRepository` using `@riverpod`

#### 3C — Presentation Layer
- [ ] **3.5** — Create `LoginScreen` in `features/auth/presentation/login_screen.dart`:
  - Email & password text fields with validation
  - "Sign In" button with loading state
  - "Don't have an account? Register" navigation link
  - Error display (SnackBar) for failed auth attempts
- [ ] **3.6** — Create `RegisterScreen` in `features/auth/presentation/register_screen.dart`:
  - Email, password, display name fields with validation
  - "Create Account" button with loading state
  - "Already have an account? Sign In" navigation link
  - Error display for registration failures
- [ ] **3.7** — Create `AuthNotifier` (using `@riverpod`) to manage auth state transitions:
  - Expose `AsyncValue<UserProfile?>` to the UI
  - Handle loading, success, and error states
- [ ] **3.8** — Update `app_router.dart`:
  - Wire the auth guard to check `authStateChangesProvider`
  - Redirect unauthenticated users to `/login`
  - Redirect authenticated users away from `/login` to `/tasks`

### Deliverable
A working auth flow where users can register, log in, log out, and are routed appropriately.

### Verification
- [ ] Register a new user → verify profile created in Supabase Dashboard
- [ ] Log in with registered credentials → verify redirect to tasks screen
- [ ] Log out → verify redirect to login screen
- [ ] Attempt login with wrong password → verify error message displayed
- [ ] `dart analyze` returns zero warnings

---

## Stage 4 — Task Data Layer & Models

**Sprint**: Week 2 | **Estimated Effort**: 3–4 hours

### Objective
Implement the Task domain model and repository for all CRUD operations.

### Tasks

#### 4A — Domain Layer
- [ ] **4.1** — Create `Task` Freezed model in `features/tasks/domain/task_model.dart`:
  - Fields: `id`, `title`, `description`, `isCompleted`, `dueAt`, `createdBy`, `assignedTo`, `createdAt`, `updatedAt`
  - Include `fromJson` / `toJson` with `@JsonKey` annotations for snake_case mapping
- [ ] **4.2** — Run code generation

#### 4B — Data Layer
- [ ] **4.3** — Create `TaskRepository` in `features/tasks/data/task_repository.dart`:
  - `fetchTasks(userId)` → SELECT tasks WHERE `assigned_to = userId` OR `created_by = userId`, ordered by `created_at DESC`
  - `createTask(title, description, dueAt, assignedTo)` → INSERT into tasks
  - `updateTask(taskId, updates)` → UPDATE task by ID
  - `toggleComplete(taskId, isCompleted)` → UPDATE `is_completed` flag
  - `deleteTask(taskId)` → DELETE task by ID
  - `streamTasks(userId)` → Real-time stream via `supabase.from('tasks').stream(...)`
- [ ] **4.4** — Create Riverpod provider for `TaskRepository` using `@riverpod`
- [ ] **4.5** — Create `TaskListNotifier` (using `@riverpod AsyncNotifier`):
  - Expose `AsyncValue<List<Task>>` to the UI
  - Methods: `addTask()`, `toggleTask()`, `deleteTask()`, `refreshTasks()`
  - Subscribe to real-time stream for live updates

### Deliverable
A fully tested data layer capable of CRUD operations on tasks via Supabase.

### Verification
- [ ] Write and pass unit tests for `Task` model serialization
- [ ] Write and pass unit tests for `TaskRepository` (mocked Supabase client)
- [ ] Verify real-time stream receives inserts/updates/deletes via Supabase Dashboard

---

## Stage 5 — Task List Screen (View & Hide Completed)

**Sprint**: Week 3 | **Estimated Effort**: 5–6 hours

### Objective
Build the primary screen: display all tasks assigned to the user, with the ability to hide completed tasks.

### Tasks

- [ ] **5.1** — Create `TaskListScreen` in `features/tasks/presentation/screens/task_list_screen.dart`:
  - AppBar with title "My Tasks" and a sign-out action button
  - Body renders a `ListView` of tasks from `TaskListNotifier`
  - FloatingActionButton (FAB) to navigate to Create Task screen
  - Handle loading state with skeleton/shimmer placeholder
  - Handle empty state with an illustrated empty message
  - Handle error state with a retry button
- [ ] **5.2** — Create `TaskCard` widget in `features/tasks/presentation/widgets/task_card.dart`:
  - Display task title, description (truncated), and due date (formatted via `intl`)
  - Leading checkbox to toggle `is_completed`
  - Visual distinction for completed tasks (strikethrough text, muted opacity)
  - Swipe-to-delete using `flutter_slidable`
- [ ] **5.3** — Implement "Hide Completed Tasks" toggle:
  - Add a filter toggle in the AppBar (icon button or chip)
  - Create a `taskFilterProvider` (StateProvider) with values: `all` | `active` | `completed`
  - Default filter: `active` (hides completed tasks by default, per client requirement)
  - Create a `filteredTasksProvider` that combines `TaskListNotifier` output with the active filter
- [ ] **5.4** — Wire the FAB to navigate to the Create Task screen (built in Stage 6)
- [ ] **5.5** — Implement pull-to-refresh on the task list

### Deliverable
A functional task list screen that displays tasks, allows toggling completion, and hides completed tasks by default.

### Verification
- [ ] Tasks load and display correctly from Supabase
- [ ] Toggling a task's checkbox updates `is_completed` in the database
- [ ] Completed tasks are hidden by default; toggling the filter reveals them
- [ ] Swipe-to-delete removes the task
- [ ] Empty state renders when no tasks exist
- [ ] Pull-to-refresh reloads the task list
- [ ] `dart analyze` returns zero warnings

---

## Stage 6 — Create & Assign Task Screen

**Sprint**: Week 3 | **Estimated Effort**: 4–5 hours

### Objective
Build the task creation screen, including the ability to assign a task to another user.

### Tasks

- [ ] **6.1** — Create `CreateTaskScreen` in `features/tasks/presentation/screens/create_task_screen.dart`:
  - Title text field (required, validated)
  - Description text field (optional, multiline)
  - Due date/time picker (optional, using `showDatePicker` + `showTimePicker`)
  - Assignee field: email text input to assign task to another user
  - "Assign to Myself" default checkbox (pre-checked)
  - "Create Task" submit button with loading state
- [ ] **6.2** — Create `UserLookupRepository` (or add method to `AuthRepository`):
  - `findUserByEmail(email)` → SELECT from `profiles` WHERE `email = ?`
  - Returns `UserProfile?` — used to validate assignee before task creation
- [ ] **6.3** — Implement task creation logic:
  - If "Assign to Myself" is checked → `assigned_to = current_user.id`
  - If assigning to another → lookup user by email, set `assigned_to = found_user.id`
  - Display error if provided email does not match any registered user
  - On success → navigate back to Task List Screen
- [ ] **6.4** — Add form validation:
  - Title: required, min 1 character, max 200 characters
  - Description: max 2000 characters
  - Assignee email: valid email format (when provided)
- [ ] **6.5** — Create Riverpod provider for the create task form state

### Deliverable
A complete task creation flow supporting both personal and assigned tasks.

### Verification
- [ ] Create a personal task → verify it appears in the task list
- [ ] Assign a task to another user by email → verify it appears in their task list
- [ ] Submit with empty title → verify validation error
- [ ] Enter a nonexistent email → verify "User not found" error
- [ ] `dart analyze` returns zero warnings

---

## Stage 7 — MVP Polish, Testing & Quality Gates

**Sprint**: Week 4 | **Estimated Effort**: 6–8 hours

### Objective
Finalize the MVP with comprehensive testing, code cleanup, and quality assurance.

### Tasks

#### 7A — Unit Tests
- [ ] **7.1** — Test `Task` model: serialization, equality, `copyWith`
- [ ] **7.2** — Test `UserProfile` model: serialization, equality, `copyWith`
- [ ] **7.3** — Test `TaskRepository`: mock Supabase client, verify CRUD operations
- [ ] **7.4** — Test `AuthRepository`: mock Supabase auth, verify signUp/signIn/signOut
- [ ] **7.5** — Test `TaskListNotifier`: verify state transitions (loading → data → error)
- [ ] **7.6** — Test `filteredTasksProvider`: verify filtering logic for all/active/completed

#### 7B — Widget Tests
- [ ] **7.7** — Test `TaskCard`: renders title, description, checkbox state, swipe action
- [ ] **7.8** — Test `LoginScreen`: renders fields, triggers sign-in on tap, displays errors
- [ ] **7.9** — Test `CreateTaskScreen`: validates form, handles assignment toggle

#### 7C — Code Quality
- [ ] **7.10** — Run `dart analyze` — resolve all warnings
- [ ] **7.11** — Run `dart format --set-exit-if-changed .` — ensure all files formatted
- [ ] **7.12** — Run `flutter test --coverage` — verify ≥ 80% on business logic
- [ ] **7.13** — Review all TODO/FIXME comments — resolve or document in backlog
- [ ] **7.14** — Verify consistent error handling across all repository methods
- [ ] **7.15** — Verify all screens handle loading, error, and empty states

#### 7D — Cross-Platform Verification
- [ ] **7.16** — Test on Android emulator (API 34+)
- [ ] **7.17** — Test on iOS simulator (iPhone 15)
- [ ] **7.18** — Test on Chrome (Web)
- [ ] **7.19** — Verify responsive layout on tablet-sized screens

### Deliverable
A production-quality MVP that satisfies all client requirements with verified test coverage.

### Verification
- [ ] All unit and widget tests pass
- [ ] `dart analyze` returns zero warnings/errors
- [ ] Coverage report shows ≥ 80% on `lib/features/`
- [ ] App runs without crashes on all three platforms
- [ ] Core flows verified: Register → Login → Create Task → View Task → Complete → Hide

---

# Section B: Post-MVP (Stages 8–12)

> **Scope**: Features not explicitly requested by the client but designed to elevate the product quality, demonstrate technical maturity, and impress stakeholders.

---

## Stage 8 — Task Editing & Deletion Refinement

**Sprint**: Week 5 | **Estimated Effort**: 3–4 hours

### Objective
Allow users to edit existing tasks and add confirmation dialogs for destructive actions.

### Tasks

- [ ] **8.1** — Create `EditTaskScreen` in `features/tasks/presentation/screens/edit_task_screen.dart`:
  - Pre-populate form fields with existing task data
  - Allow editing title, description, due date, and assignee
  - "Save Changes" button with loading state
- [ ] **8.2** — Add navigation from `TaskCard` tap → `EditTaskScreen`
- [ ] **8.3** — Add confirmation dialog before task deletion (swipe action):
  - "Are you sure you want to delete this task?" with Cancel/Delete actions
- [ ] **8.4** — Add `updated_at` timestamping on task updates
- [ ] **8.5** — Write unit tests for edit flow
- [ ] **8.6** — Write widget test for `EditTaskScreen`

### Deliverable
Users can edit tasks inline and delete with confirmation, preventing accidental data loss.

---

## Stage 9 — Dark Mode & Theming

**Sprint**: Week 5 | **Estimated Effort**: 2–3 hours

### Objective
Implement a complete dark mode theme with a user-controlled toggle.

### Tasks

- [ ] **9.1** — Create `app_theme_dark.dart` with a dark `ThemeData`:
  - Dark surface colors, adjusted contrast ratios
  - Properly themed cards, dialogs, and input fields
- [ ] **9.2** — Create a `themeNotifierProvider` to toggle between light/dark modes
- [ ] **9.3** — Persist theme preference locally (using `SharedPreferences` or Supabase profile metadata)
- [ ] **9.4** — Add a theme toggle switch in the AppBar or a settings menu
- [ ] **9.5** — Verify WCAG contrast ratios for both themes
- [ ] **9.6** — Test theme switching does not cause layout shifts or rendering issues

### Deliverable
A polished dark mode experience with persistent user preference.

---

## Stage 10 — Micro-Animations & Visual Polish

**Sprint**: Week 6 | **Estimated Effort**: 3–4 hours

### Objective
Add tasteful animations to enhance the user experience without compromising performance.

### Tasks

- [ ] **10.1** — Add staggered list animation to `TaskListScreen` using `flutter_animate`:
  - Tasks fade-in and slide-up sequentially on initial load
- [ ] **10.2** — Add animated checkbox transition on task completion toggle
- [ ] **10.3** — Add hero animation for FAB → Create Task screen transition
- [ ] **10.4** — Add subtle scale animation on `TaskCard` long-press
- [ ] **10.5** — Add animated empty state illustration (simple lottie or animated SVG)
- [ ] **10.6** — Add page transition animations between routes (fade or slide)
- [ ] **10.7** — Verify animations run at 60fps on mid-range devices (use Flutter DevTools performance overlay)

### Deliverable
A fluid, premium-feeling UI with smooth transitions that delight users.

---

## Stage 11 — Push Notifications & Reminders

**Sprint**: Week 6–7 | **Estimated Effort**: 5–6 hours

### Objective
Implement local push notifications to remind users of upcoming tasks.

### Tasks

- [ ] **11.1** — Uncomment and install `flutter_local_notifications` and `timezone` in `pubspec.yaml`
- [ ] **11.2** — Create `NotificationService` class:
  - Initialize `FlutterLocalNotificationsPlugin`
  - Configure Android notification channel
  - Configure iOS notification permissions
  - `scheduleReminder(taskId, title, scheduledDate)` → schedule a local notification
  - `cancelReminder(taskId)` → cancel a scheduled notification
- [ ] **11.3** — Integrate notification scheduling into task creation/edit flow:
  - When a task is created with a `due_at` → schedule a reminder 30 minutes before
  - When a task is edited and `due_at` changes → reschedule the reminder
  - When a task is deleted → cancel the reminder
- [ ] **11.4** — Handle notification tap → deep-link to the specific task
- [ ] **11.5** — Request notification permissions on first app launch (with graceful fallback)
- [ ] **11.6** — Test notifications on Android and iOS physical devices

### Deliverable
Users receive timely reminders for upcoming tasks, increasing engagement and task completion rates.

---

## Stage 12 — CI/CD Pipeline & Deployment

**Sprint**: Week 7–8 | **Estimated Effort**: 4–5 hours

### Objective
Automate the build, test, and deployment pipeline using GitHub Actions.

### Tasks

- [ ] **12.1** — Create `.github/workflows/ci.yml`:
  ```yaml
  # Trigger on push to main and PRs
  # Steps:
  #   1. Checkout code
  #   2. Setup Flutter SDK
  #   3. Run `flutter pub get`
  #   4. Run `dart format --set-exit-if-changed .`
  #   5. Run `dart analyze`
  #   6. Run `flutter test --coverage`
  #   7. Upload coverage report
  ```
- [ ] **12.2** — Create `.github/workflows/deploy-web.yml`:
  - Build Flutter web: `flutter build web --release`
  - Deploy to Vercel or Firebase Hosting
- [ ] **12.3** — Create `.github/workflows/deploy-android.yml`:
  - Build Android App Bundle: `flutter build appbundle --release`
  - Upload to Google Play Console (Internal Testing track) via Fastlane or Gradle Play Publisher
- [ ] **12.4** — Create `.github/workflows/deploy-ios.yml`:
  - Build iOS archive: `flutter build ipa --release`
  - Upload to TestFlight via Fastlane
- [ ] **12.5** — Configure GitHub Secrets:
  - `SUPABASE_URL`, `SUPABASE_ANON_KEY`
  - `PLAY_STORE_SERVICE_ACCOUNT_JSON` (for Android deployment)
  - `APP_STORE_CONNECT_API_KEY` (for iOS deployment)
  - `VERCEL_TOKEN` or `FIREBASE_TOKEN` (for web deployment)
- [ ] **12.6** — Test the full CI pipeline:
  - Push a commit → verify lint, test, and build steps all pass
  - Merge to `main` → verify automatic deployment triggers
- [ ] **12.7** — Set up Sentry or Firebase Crashlytics for production error monitoring
- [ ] **12.8** — Create a `README.md` with:
  - Project description and setup instructions
  - Environment variable documentation
  - Build and deployment instructions
  - Architecture overview with link to `plan.md`

### Deliverable
A fully automated CI/CD pipeline that ensures code quality on every commit and deploys to all three platforms on merge to `main`.

---

## Summary & Timeline

| Stage | Name                                | Section    | Sprint  | Est. Hours |
| :---- | :---------------------------------- | :--------- | :------ | :--------- |
| 0     | Environment & AI Tooling Setup      | Pre-Stage  | Week 1  | 1–2        |
| 1     | Project Scaffolding & Infrastructure | **MVP**   | Week 1  | 3–4        |
| 2     | Supabase Backend Setup              | **MVP**    | Week 1  | 2–3        |
| 3     | Authentication Feature              | **MVP**    | Week 2  | 5–6        |
| 4     | Task Data Layer & Models            | **MVP**    | Week 2  | 3–4        |
| 5     | Task List Screen                    | **MVP**    | Week 3  | 5–6        |
| 6     | Create & Assign Task Screen         | **MVP**    | Week 3  | 4–5        |
| 7     | MVP Polish, Testing & QA            | **MVP**    | Week 4  | 6–8        |
| 8     | Task Editing & Deletion             | Post-MVP   | Week 5  | 3–4        |
| 9     | Dark Mode & Theming                 | Post-MVP   | Week 5  | 2–3        |
| 10    | Micro-Animations & Polish           | Post-MVP   | Week 6  | 3–4        |
| 11    | Push Notifications & Reminders      | Post-MVP   | Week 6–7| 5–6        |
| 12    | CI/CD Pipeline & Deployment         | Post-MVP   | Week 7–8| 4–5        |
|       |                                     |            | **Total** | **~42–54 hrs** |

---

### Key Milestones

| Milestone                    | Target    | Gate Criteria                                           |
| :--------------------------- | :-------- | :------------------------------------------------------ |
| **MVP Feature Complete**     | Week 3    | All Stage 1–6 checklists complete                       |
| **MVP Quality Certified**    | Week 4    | Stage 7 complete, ≥80% test coverage, 0 analyzer warnings |
| **Post-MVP Polish Complete** | Week 6    | Stages 8–10 complete, dark mode + animations live        |
| **Production Release**       | Week 8    | Stage 12 complete, CI/CD pipeline operational, app deployed |

---

*End of Implementation Roadmap — Version 1.0*
