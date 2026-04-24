# mungiz — Execution Roadmap

| Field | Detail |
|:------|:-------|
| **Version** | 2.0 |
| **Date** | April 22, 2026 |
| **Derived From** | `docs/plan.md` v1.0 |
| **Methodology** | Agile — 1-week sprints |
| **Platforms** | Android · iOS · Web (PWA) |

---

## Roadmap Overview

| Phase | Stage | Timeline | Objective |
|:------|:------|:---------|:----------|
| **1 — MVP** | S1: Project Scaffolding | Week 1 | Flutter init, deps, folder structure |
| | S2: Backend + Local DB | Week 1–2 | Supabase tables/RLS, Drift local DB |
| | S3: Core Shell | Week 2 | Theme, router, providers |
| | S4: Authentication | Week 2–3 | Register, login, logout, guard |
| | S5: Task CRUD | Week 3–4 | Create, view, complete, hide tasks |
| | S6: Task Assignment | Week 4–5 | Assign to others, dual-view |
| | S7: Sync Engine | Week 5–6 | Offline queue, background sync |
| | S8: Testing + CI | Week 6–7 | Unit/widget tests, GitHub Actions |
| **2 — Quick Wins** | S9: Visual Dashboard | Week 7–8 | Task stats, charts, progress rings |
| | S10: Export & Sharing | Week 8 | PDF/Excel task reports |
| | S11: Theme & Polish | Week 8–9 | Dark/light toggle, animations |
| | S12: Deployment | Week 9–10 | Play Store, TestFlight, Web hosting |

### Dependency Graph

```
S1 ► S2 ► S3 ► S4 ► S5 ► S6 ► S7 ► S8
                                      │
                              S9 ◄────┤
                              S10 ◄───┤
                              S11 ◄───┘
                                      │
                              S12 ◄───┘
```

---

## Phase 1 — MVP (Core + Offline Architecture)

> Delivers the exact company requirements — task registration, viewing, and completion hiding — with an offline-first architecture ensuring field reliability without internet.

---

### Stage 1: Project Scaffolding

**Goal:** Initialize the Flutter project, install all dependencies, establish feature-first directory structure.

**Features from Product Plan:** Infrastructure prerequisite for all features.

**Integration / Architecture Notes:**
- Single codebase targeting Android, iOS, Web.
- Feature-first folder structure per plan.md §3.2.
- Code generation via `build_runner` for Riverpod, Freezed, JSON Serializable.
- `.env` for credentials, loaded via `--dart-define`, must be in `.gitignore`.

**Task Checklist:**

- [x] Run `flutter create` with org name and project name `mungiz`
- [x] Enable web support (`flutter config --enable-web`)
- [x] Add production dependencies: `flutter_riverpod`, `riverpod_annotation`, `go_router`, `supabase_flutter`, `freezed_annotation`, `json_annotation`, `drift`, `sqlite3_flutter_libs`, `path_provider`, `path`, `gap`, `google_fonts`, `flutter_animate`, `connectivity_plus`
- [x] Add dev dependencies: `build_runner`, `riverpod_generator`, `freezed`, `json_serializable`, `drift_dev`, `mocktail`, `very_good_analysis`
  - **Note:** `drift`/`drift_dev` pinned to `^2.31.0` (not 2.32.x) to resolve `analyzer` version conflict with `riverpod_generator ^4.0.3`. See implementation_plan for full root cause analysis.
  - **Note:** `flutter_lints` replaced by `very_good_analysis` (stricter, enterprise-grade lint rules).
- [x] Run `flutter pub get`
- [x] Create feature-first directory structure under `lib/`:
  - `core/constants/`, `core/theme/`, `core/router/`, `core/providers/`, `core/utils/`, `core/database/`
  - `features/auth/data/`, `features/auth/domain/`, `features/auth/presentation/`
  - `features/tasks/data/`, `features/tasks/domain/`, `features/tasks/presentation/screens/`, `features/tasks/presentation/widgets/`
  - `features/sync/data/`, `features/sync/domain/`
- [x] Create `.env` with placeholder Supabase URL and anon key
- [x] Add `.env`, `*.g.dart`, `*.freezed.dart`, `build/` to `.gitignore`
- [x] Initialize Git repository, create initial commit
- [x] Verify `flutter analyze` passes with zero warnings

---

### Stage 2: Backend + Local Database

**Goal:** Provision Supabase backend AND set up Drift local database as the single source of truth.

**Features from Product Plan:** FR-001 through FR-010 (data layer); plan.md §3.3; NFR-007 (offline tolerance).

**Integration / Architecture Notes:**
- **Offline-first principle:** Drift (local SQLite) is the single source of truth. The UI always reads from Drift. Supabase is the remote sync target — never queried directly by the UI.
- Local Drift schema mirrors Supabase `profiles` and `tasks` tables with an additional `sync_status` column (`synced`, `pending_create`, `pending_update`, `pending_delete`).
- A `sync_queue` table in Drift tracks mutations that need to be pushed to Supabase.
- Supabase RLS policies remain mandatory for server-side security.
- Database trigger on Supabase auto-creates `profiles` row on new user sign-up.

**Task Checklist:**

- [x] Create Supabase project (development environment)
- [x] Create `profiles` table per plan.md §3.3 (id, email, display_name, avatar_url, created_at, updated_at)
- [x] Create `tasks` table per plan.md §3.3 (id, title, description, is_completed, due_at, created_by, assigned_to, created_at, updated_at)
- [x] Set up foreign key constraints on both tables
- [x] Enable RLS on `profiles` and `tasks` tables with all four policies per plan.md §3.3
- [x] Create DB trigger to auto-insert `profiles` on `auth.users` INSERT
- [x] Create `updated_at` auto-update trigger
- [x] Enable Supabase Auth (email/password)
- [x] Record Supabase URL and anon key in `.env`
- [x] Create `core/database/app_database.dart`: Drift database class with `tasks` and `profiles` tables mirroring Supabase schema
- [x] Add `sync_status` column to Drift `tasks` table (enum: synced, pending_create, pending_update, pending_delete)
- [x] Create `sync_queue` Drift table: (id, table_name, record_id, operation, payload, created_at)
- [x] Run `build_runner` for Drift codegen
- [x] Verify Drift DB opens and migrates correctly on app launch
- [x] Verify Supabase tables and RLS via SQL editor test queries

---

### Stage 3: Core Shell

**Goal:** Build the shared application shell — theme, routing, Supabase init, and Drift provider.

**Features from Product Plan:** NFR-005 (cross-platform consistency), NFR-006 (accessibility).

**Integration / Architecture Notes:**
- `main.dart` initializes both Supabase and Drift, wraps app in `ProviderScope`.
- `app.dart` defines `MaterialApp.router` with GoRouter and Material 3 theme.
- Theme: `ColorScheme.fromSeed()`, light/dark variants, Google Fonts (Inter/Outfit).
- Core providers expose `SupabaseClient`, `AppDatabase` (Drift), and `authStateChanges`.
- GoRouter in `core/router/` with auth redirect guard.

**Task Checklist:**

- [x] Create `main.dart`: init Supabase + Drift, run app in `ProviderScope`
- [x] Create `app.dart`: `MaterialApp.router` with GoRouter and theme
- [x] Create `core/theme/app_theme.dart`: Material 3 `ThemeData`, light + dark, `ColorScheme.fromSeed()`
- [x] Create `core/theme/app_typography.dart`: Google Fonts text theme
- [x] Create `core/theme/app_spacing.dart`: spacing constants
- [x] Create `core/providers/supabase_providers.dart`: providers for `SupabaseClient` and `authStateChanges`
- [x] Create `core/providers/database_providers.dart`: provider for `AppDatabase` (Drift)
- [x] Create `core/providers/connectivity_provider.dart`: provider wrapping `connectivity_plus`
- [x] Create `core/router/app_router.dart`: GoRouter with placeholder routes + auth guard
- [x] Create `core/constants/app_constants.dart`: route paths as `const` strings
- [x] Run `build_runner`
- [x] Verify app launches on Android, iOS, Web with themed shell

---

### Stage 4: Authentication

**Goal:** Implement registration, login, logout with route guarding. Auth data cached locally for offline access.

**Features from Product Plan:** FR-001; US-001, US-002, US-003.

**Integration / Architecture Notes:**
- `AuthRepository` wraps `supabase.auth` calls. On successful auth, profile is cached to Drift.
- Riverpod notifier manages auth state, exposes `AsyncValue`.
- GoRouter redirect forces unauthenticated users to login.
- Offline: if cached session exists in Drift, allow limited read-only access.

**Task Checklist:**

- [x] Create `features/auth/domain/user_profile.dart`: Freezed model matching `profiles` table
- [x] Run `build_runner` for Freezed codegen
- [x] Create `features/auth/data/auth_repository.dart`:
  - `signUp(email, password)` — register + cache profile to Drift
  - `signIn(email, password)` — login + cache profile to Drift
  - `signOut()` — terminate session, clear sensitive local data
  - `currentUser` / `authStateChanges` — stream of auth state
- [x] Create auth Riverpod providers/notifiers (`authStateProvider`, `authNotifierProvider`)
- [x] Create `features/auth/presentation/login_screen.dart`: email/password fields, validation, loading state, link to register, error display
- [x] Create `features/auth/presentation/register_screen.dart`: email/password/confirm fields, validation, loading state, link to login, error display
- [x] Update GoRouter: add `/login`, `/register` routes with auth redirect guard
- [x] Verify: register → auto-login → home → logout → redirect to login
- [x] Verify: profile row auto-created in Supabase and cached in Drift

---

### Stage 5: Task CRUD (Core)

**Goal:** Create personal tasks, view task list, mark complete, hide completed — all offline-first via Drift.

**Features from Product Plan:** FR-002, FR-004, FR-005, FR-006; US-004, US-005, US-007, US-008, US-009.

**Integration / Architecture Notes:**
- **All reads come from Drift** (local DB). UI never queries Supabase directly.
- **All writes go to Drift first**, marked with `sync_status: pending_create/pending_update`. The Sync Engine (Stage 7) pushes them to Supabase later.
- Task list is a reactive Drift `watch` query — UI updates instantly on local write.
- Default view hides completed tasks; toggle/filter reveals them.
- Personal task: `created_by` = `assigned_to` = current user.

**Task Checklist:**

- [x] Create `features/tasks/domain/task.dart`: Freezed model with `@JsonKey` for snake_case
- [x] Run `build_runner`
- [x] Create `features/tasks/data/task_local_repository.dart` (Drift):
  - `watchTasks()` — reactive stream of tasks from local DB
  - `insertTask(task)` — insert with `sync_status: pending_create`
  - `toggleComplete(taskId, isCompleted)` — update locally, mark `sync_status: pending_update`
  - `getTaskById(id)` — single task lookup
- [x] Create `features/tasks/data/task_remote_repository.dart` (Supabase):
  - `fetchAllTasks()` — pull all user tasks from Supabase (used by sync)
  - `pushTask(task)` — upsert to Supabase
  - `pushCompletion(taskId, isCompleted)` — update remote
- [x] Create task Riverpod notifiers: `taskListNotifierProvider` watching Drift, methods for `addTask()`, `toggleComplete()`
- [x] Create `features/tasks/presentation/widgets/task_card.dart`: task display with completion toggle
- [x] Create `features/tasks/presentation/widgets/empty_tasks.dart`: illustrated empty state with CTA
- [x] Create `features/tasks/presentation/screens/task_list_screen.dart`: displays tasks via Drift watch, toggle for completed, FAB for create, handles loading/error/empty/data
- [x] Create `features/tasks/presentation/screens/create_task_screen.dart`: title (required), description (optional), due date picker (optional), submit with validation
- [x] Update GoRouter: `/`, `/tasks/create`
- [x] Verify: create task → instant local display → mark complete → hidden → toggle to reveal

---

### Stage 6: Task Assignment

**Goal:** Assign tasks to other registered users. Both creator and assignee see the task.

**Features from Product Plan:** FR-003; US-006.

**Integration / Architecture Notes:**
- User lookup by email queries `profiles` (requires connectivity for first lookup; cache result in Drift).
- Assigned task: `created_by` = current user, `assigned_to` = target user.
- Task list shows both self-created and assigned-to-me tasks.
- Task card displays "Assigned by/to [name]" when creator ≠ assignee.
- Write goes to Drift first, synced later.

**Task Checklist:**

- [x] Create `features/auth/data/profile_repository.dart`:
  - `findUserByEmail(email)` — query Supabase `profiles`, cache in Drift
  - `getCachedProfile(userId)` — lookup from Drift
- [x] Update `task_local_repository.dart`: `insertAssignedTask(task)` with distinct `created_by`/`assigned_to`
- [x] Update `task_remote_repository.dart`: handle assigned task push
- [x] Update `CreateTaskScreen`: optional "Assign to" email field, validate user exists, error if not found
- [x] Update `TaskCard`: show assignment indicator when creator ≠ assignee
- [x] Update task notifier to handle assigned tasks
- [x] Verify: User A assigns to User B → syncs → User B sees it → RLS enforced

---

### Stage 7: Sync Engine

**Goal:** Build background sync system that pushes local mutations to Supabase and pulls remote changes.

**Features from Product Plan:** NFR-007 (offline tolerance).

**Integration / Architecture Notes:**
- **Push:** On connectivity restored, iterate `sync_queue` / tasks with `pending_*` status, push to Supabase in order, mark `synced` on success.
- **Pull:** After push completes, fetch remote tasks and upsert into Drift (conflict resolution: server wins for same `updated_at`, or last-write-wins).
- Connectivity monitored via `connectivity_plus`.
- Sync runs automatically on connectivity change and periodically when online.
- Visual sync indicator in app bar (synced / syncing / offline).

**Task Checklist:**

- [x] Create `features/sync/data/sync_engine.dart`:
  - `pushPendingChanges()` — iterate pending items, push to Supabase, update `sync_status`
  - `pullRemoteChanges()` — fetch from Supabase, upsert into Drift
  - `fullSync()` — push then pull
  - Error handling: retry logic with exponential backoff for transient failures
- [x] Create `features/sync/data/conflict_resolver.dart`: last-write-wins strategy using `updated_at`
- [x] Create sync Riverpod provider:
  - Watch connectivity state
  - Trigger `fullSync()` on connectivity restored
  - Periodic sync when online (configurable interval)
  - Expose sync status (`idle`, `syncing`, `error`, `offline`)
- [x] Create sync status UI indicator widget (app bar badge/icon)
- [x] Handle edge cases: partial sync failure (retry individual items), duplicate prevention
- [x] Verify: go offline → create/complete tasks → restore connection → data syncs → visible on another device
- [x] Verify: conflict scenario → server data correctly reconciled

---

### Stage 8: Testing + CI

**Goal:** Achieve ≥80% test coverage on business logic. Automate quality gates via GitHub Actions.

**Features from Product Plan:** NFR-008; plan.md §5.1–5.5, §6.2.

**Integration / Architecture Notes:**
- Unit tests: models, local/remote repositories (mocked), notifiers, sync engine.
- Widget tests: all screens for loading/error/empty/data states.
- Integration tests: critical user flows end-to-end.
- CI pipeline: lint → format → test → coverage check on every push/PR.

**Task Checklist:**

- [ ] **Unit Tests — Models:**
  - [ ] `Task` fromJson/toJson round-trip, copyWith, equality
  - [ ] `UserProfile` fromJson/toJson round-trip
- [ ] **Unit Tests — Repositories:**
  - [ ] `TaskLocalRepository`: insert, watch, toggle complete (in-memory Drift)
  - [ ] `TaskRemoteRepository`: fetch, push (mocked Supabase via mocktail)
  - [ ] `AuthRepository`: signUp, signIn, signOut (mocked)
- [ ] **Unit Tests — Sync Engine:**
  - [ ] Push pending changes — success and partial failure
  - [ ] Pull remote changes — upsert into local DB
  - [ ] Conflict resolution — last-write-wins
- [ ] **Unit Tests — Notifiers:**
  - [ ] Task list: load, create, complete, delete state transitions
  - [ ] Auth: sign-in, sign-out, error state transitions
- [ ] **Widget Tests:**
  - [ ] TaskCard: active vs completed rendering
  - [ ] TaskListScreen: loading, error, empty, data states
  - [ ] CreateTaskScreen: validation, submit
  - [ ] LoginScreen: validation, error display
- [ ] **Integration Tests:**
  - [ ] Register → Login → Create → View → Complete → Hidden
  - [ ] Assign Task → Sync → Assignee sees task
  - [ ] Offline create → Reconnect → Synced
- [ ] Run `flutter test --coverage`, verify ≥80% on `lib/features/`
- [ ] Create `.github/workflows/ci.yml`: checkout → Flutter setup → pub get → format → analyze → test → coverage
- [ ] Configure branch protection: CI must pass before merge to `main`

---

## Phase 2 — High-Impact Quick Wins

> Technically simple features that deliver maximum visual impact and business value. No complex infrastructure — pure polish and stakeholder delight.

---

### Stage 9: Visual Dashboard & Analytics

**Goal:** Add a beautiful analytics dashboard showing task statistics — instantly impressive to managers.

**Features from Product Plan:** Extends FR-004 (task viewing) with business intelligence layer.

**Integration / Architecture Notes:**
- All data sourced from Drift (offline-compatible by default).
- Use `fl_chart` package for animated, interactive charts.
- Dashboard is a new tab/screen in the main navigation.
- Computed stats: total tasks, completed vs pending, completion rate %, tasks by assignee, overdue count.
- Cards with animated counters and progress rings for visual impact.

**Task Checklist:**

- [ ] Add `fl_chart` dependency
- [ ] Create `features/dashboard/` feature directory
- [ ] Create `features/dashboard/data/dashboard_repository.dart`: queries against Drift for aggregated stats (counts, rates, groupings)
- [ ] Create `features/dashboard/domain/task_stats.dart`: Freezed model for stats (totalTasks, completed, pending, overdueCount, completionRate)
- [ ] Create dashboard Riverpod provider: watches Drift and computes stats reactively
- [ ] Create `features/dashboard/presentation/dashboard_screen.dart`:
  - [ ] Summary cards row: Total, Completed, Pending, Overdue — each with animated counter
  - [ ] Animated circular progress ring showing completion rate percentage
  - [ ] Bar chart: tasks completed per day (last 7 days) via `fl_chart`
  - [ ] Pie/donut chart: task distribution by status
- [ ] Create `features/dashboard/presentation/widgets/stat_card.dart`: reusable animated stat card
- [ ] Create `features/dashboard/presentation/widgets/progress_ring.dart`: animated circular progress
- [ ] Add dashboard to main navigation (bottom nav tab or drawer entry)
- [ ] Update GoRouter with `/dashboard` route
- [ ] Verify: stats update reactively as tasks are created/completed

---

### Stage 10: Export & Sharing

**Goal:** Enable users to export their task lists as PDF or Excel files — high business value for reporting.

**Features from Product Plan:** Extends FR-004; delivers reporting capability managers expect.

**Integration / Architecture Notes:**
- Use `pdf` package for PDF generation, `excel` (or `syncfusion_flutter_xlsio`) for Excel.
- Export reads from Drift — works fully offline.
- PDF: branded header, task table with status indicators, generated date, summary stats.
- Share via platform share sheet (`share_plus` package).
- Export options accessible from task list screen via action menu.

**Task Checklist:**

- [ ] Add `pdf`, `printing`, `excel` (or equivalent), `share_plus`, `path_provider` dependencies
- [ ] Create `core/utils/pdf_export_service.dart`:
  - Generate branded PDF document with app name/logo header
  - Task table: title, assignee, due date, status
  - Summary footer: total/completed/pending counts
  - Date of generation
- [ ] Create `core/utils/excel_export_service.dart`:
  - Generate Excel workbook with task data sheet
  - Columns: title, description, assigned to, due date, status, created date
  - Auto-width columns, header styling
- [ ] Add export action menu to `TaskListScreen` (overflow menu or FAB speed dial)
- [ ] Implement "Export as PDF" flow: generate → preview → share/save
- [ ] Implement "Export as Excel" flow: generate → share/save
- [ ] Verify: export works offline with local data
- [ ] Verify: generated files open correctly on all platforms

---

### Stage 11: Theme Polish & Micro-Animations

**Goal:** Add dark/light mode toggle, premium animations, and polished empty states for a world-class feel.

**Features from Product Plan:** NFR-005, NFR-006; elevates perceived quality dramatically.

**Integration / Architecture Notes:**
- Theme mode preference persisted locally (Drift or `shared_preferences`).
- `flutter_animate` for staggered list animations (50ms/item, ≤300ms).
- Shimmer/skeleton loaders for all async screens.
- Beautiful illustrated empty states for zero-task and zero-results scenarios.
- Responsive layouts: 360px, 390px, 768px breakpoints, max 600px content on web.
- Accessibility: Semantics labels, 48×48 touch targets, WCAG 2.1 AA contrast.

**Task Checklist:**

- [ ] Create `core/providers/theme_mode_provider.dart`: persisted theme mode (light/dark/system)
- [ ] Add theme toggle switch to app settings or app bar
- [ ] Wire theme mode provider into `MaterialApp.router`
- [ ] Add shimmer/skeleton loading states to task list, dashboard, profile screens
- [ ] Implement staggered list animations on task list with `flutter_animate`
- [ ] Add hero/shared-element transitions for screen navigation
- [ ] Create illustrated empty state widgets (no tasks, no results)
- [ ] Add subtle micro-animations: FAB entrance, card press feedback, completion checkmark
- [ ] Implement responsive layout with `LayoutBuilder` + max-width constraint (600px)
- [ ] Test layouts at 360px, 390px, 768px breakpoints
- [ ] Add `Semantics` labels to all tappable widgets
- [ ] Verify 48×48 minimum touch targets
- [ ] Audit color contrast for both light and dark themes (WCAG 2.1 AA)
- [ ] Add `SafeArea` wrappers on all screens
- [ ] Visual QA pass across Android, iOS, Web

---

### Stage 12: Deployment & Launch

**Goal:** Release to Google Play, App Store, and Web. Establish post-launch monitoring.

**Features from Product Plan:** plan.md §6.1–6.3, §7.1–7.3.

**Integration / Architecture Notes:**
- Staging and production Supabase projects with identical schemas.
- CI/CD extended with build and deploy workflows per platform.
- PWA manifest and service worker for web.
- Post-launch: Sentry for crash reporting, UptimeRobot for uptime.

**Task Checklist:**

- [ ] Provision Supabase staging project; replicate schema + RLS
- [ ] Provision Supabase production project; replicate schema + RLS
- [ ] Configure Android app signing (keystore, upload key)
- [ ] Configure iOS app signing (certificates, provisioning profiles)
- [ ] Set app metadata: name, description, icons, splash screen (all platforms)
- [ ] Configure PWA manifest + service worker for web
- [ ] Create `.github/workflows/deploy-android.yml`: build `.aab`, upload to Play Store internal track
- [ ] Create `.github/workflows/deploy-ios.yml`: build `.ipa`, upload to TestFlight
- [ ] Create `.github/workflows/deploy-web.yml`: `flutter build web`, deploy to hosting
- [ ] Configure GitHub Secrets per environment (Supabase creds, signing keys)
- [ ] Deploy to internal/beta tracks; run smoke tests on all platforms
- [ ] Promote to production (Play Store, App Store submission, web go-live)
- [ ] Integrate Sentry for crash reporting
- [ ] Set up UptimeRobot for Supabase endpoint monitoring
- [ ] Establish GitHub Issues templates + severity labels for bug triage
- [ ] Document hotfix workflow and bi-weekly release cadence

---

## Appendix — Cross-Cutting Concerns

| Concern | Standard | Stages |
|:--------|:---------|:-------|
| **Security** | HTTPS/TLS; RLS on every table; `.env` in `.gitignore`; never trust client-only validation | S2, S4–S7, S12 |
| **Offline-First** | Drift is single source of truth; UI reads local only; sync engine pushes/pulls | S2, S5–S7 |
| **Performance** | ≤2s TTI; 60fps animations; ≤300ms durations | S5, S9, S11 |
| **Accessibility** | WCAG 2.1 AA; 48×48 targets; Semantics labels; AA contrast | S4–S11 |
| **Code Quality** | `dart analyze` 0 warnings; `dart format`; ≥80% test coverage | S1–S8 |
| **Cross-Platform** | Consistent UX on Android/iOS/Web; responsive breakpoints; max 600px web | S3, S11, S12 |
| **Validation** | Client-side (UX) + server-side (RLS/constraints); required fields enforced | S4–S6 |
| **UI/UX** | Material 3; Google Fonts; dark mode; shimmer loaders; staggered animations | S3, S9, S11 |
| **State Mgmt** | Riverpod codegen only; no setState/FutureBuilder; AsyncValue.when() | S4–S9 |
| **Data Modeling** | Freezed for all models; @JsonKey snake_case; build_runner after changes | S4–S6, S9 |
| **Error Handling** | Typed exceptions; user-friendly messages; loading/error/empty/data on every screen | S4–S7, S9 |
| **Sync Strategy** | Push-then-pull; last-write-wins conflict resolution; exponential backoff retry | S7, S8 |

---

*End of Execution Roadmap — Version 2.0*
