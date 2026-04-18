# Mungiz — Task Management System
## Software Development Life Cycle (SDLC) Plan

| Field          | Detail                                      |
| :------------- | :------------------------------------------ |
| **Project**    | Mungiz — Task Reminder & Assignment System  |
| **Version**    | 1.0                                         |
| **Date**       | April 18, 2026                              |
| **Prepared By**| Lead Developer / Project Architect          |
| **Status**     | Draft — Pending Stakeholder Approval        |

---

## Table of Contents

1. [Phase 1 — Planning & Requirement Analysis](#phase-1--planning--requirement-analysis)
2. [Phase 2 — Defining Requirements](#phase-2--defining-requirements)
3. [Phase 3 — System Design](#phase-3--system-design)
4. [Phase 4 — Coding & Implementation](#phase-4--coding--implementation)
5. [Phase 5 — Testing](#phase-5--testing)
6. [Phase 6 — Deployment](#phase-6--deployment)
7. [Phase 7 — Maintenance](#phase-7--maintenance)

---

## Phase 1 — Planning & Requirement Analysis

### 1.1 Project Overview

The client has requested a **Task Reminder System** with the following core workflow:

1. Registering personal tasks **or** assigning tasks to a specific person.
2. Displaying required tasks via a website or application.
3. Hiding completed tasks.

The client's stated platform requirement is: **Android, iOS, and Windows Phone**.

### 1.2 Architectural Decision: Technology Stack

After thorough analysis, the following technology stack has been selected to maximize delivery speed, code reuse, and long-term maintainability:

| Layer              | Technology                | Rationale                                                                 |
| :----------------- | :------------------------ | :------------------------------------------------------------------------ |
| **Framework**      | Flutter (Dart)            | Single codebase targeting Android, iOS, and Web simultaneously.           |
| **State Mgmt.**    | Riverpod (Code-Gen)       | Type-safe, compile-time checked, scalable reactive state management.      |
| **Backend (BaaS)** | Supabase                  | Open-source, PostgreSQL-based, real-time subscriptions, built-in Auth.    |
| **Data Modeling**   | Freezed + JSON Serializable | Immutable models, `copyWith`, automatic `fromJson`/`toJson`.             |
| **Routing**        | GoRouter                  | Declarative, deep-link-aware navigation with guard support.               |
| **CI/CD**          | GitHub Actions            | Automated build, test, and deployment pipeline.                           |

#### 1.2.1 Why Supabase over Firebase?

| Criterion            | Supabase                                      | Firebase                                     |
| :------------------- | :--------------------------------------------- | :------------------------------------------- |
| **Database Model**   | PostgreSQL (relational, SQL, ACID)             | Firestore (NoSQL, document-based)            |
| **Data Integrity**   | Foreign keys, constraints, joins               | Manual denormalization required               |
| **Vendor Lock-in**   | Open source, self-hostable                     | Proprietary, Google-dependent                |
| **Real-time**        | Native Postgres real-time via Replication       | Native Firestore snapshots                   |
| **Auth**             | Built-in (email, OAuth, MFA)                   | Built-in (email, OAuth, MFA)                 |
| **Row Level Security** | Native PostgreSQL RLS policies               | Firestore Security Rules                     |
| **Cost at Scale**    | Predictable PostgreSQL pricing                 | Pay-per-read/write can spike unpredictably   |

**Decision:** Supabase is selected. A relational model (PostgreSQL) is the natural fit for task management data where tasks belong to users, have statuses, and may reference assignees — relationships that are first-class citizens in SQL.

---

### 1.3 Windows Phone Platform Assessment

#### Formal Deprecation Notice — Windows Phone Support

The client's original requirements specify support for **"Android/iOS/Windows Phone devices."** After rigorous technical, historical, and market analysis, the development team formally recommends **excluding Windows Phone** from the target platform matrix. The following justification is presented for stakeholder review.

#### 1.3.1 Historical Timeline of Discontinuation

| Date               | Event                                                                  |
| :----------------- | :--------------------------------------------------------------------- |
| **Oct 2017**       | Microsoft CEO Satya Nadella publicly confirms Windows Phone is no longer a strategic focus. |
| **Jul 2017**       | Microsoft officially ends support for **Windows Phone 8.1**.           |
| **Jan 2020**       | Microsoft officially ends support for **Windows 10 Mobile** (v1709), the final mobile OS version. |
| **Mar 2019**       | Microsoft removes the Windows Phone app from the App Store and Google Play. |
| **Dec 2019**       | Microsoft Store for Windows 10 Mobile ceases to function for app installations. |

#### 1.3.2 Technical Infeasibility

| Factor                     | Assessment                                                                                             |
| :------------------------- | :----------------------------------------------------------------------------------------------------- |
| **SDK Availability**       | No active SDK exists for Windows Phone development. Visual Studio has removed WP project templates.     |
| **Flutter Support**        | Flutter has **never** supported Windows Phone. Flutter's Windows target compiles to Win32/UWP desktop applications, not the legacy Windows Phone runtime. |
| **App Store**              | The Windows Phone Store has been shut down. There is no distribution channel for new applications.       |
| **Security Updates**       | Zero security patches since January 14, 2020. Any deployed app would operate on an unpatched, vulnerable OS, creating a **liability risk** for the company. |
| **Global Market Share**    | Windows Phone held **0.0%** global mobile OS market share as of Q4 2019 (source: StatCounter, IDC). The platform has no measurable active user base. |

#### 1.3.3 Proposed Remediation

To honor the **spirit** of the client's multi-platform requirement — broad device accessibility — we propose substituting Windows Phone with **Web (PWA)** support:

| Original Requirement | Proposed Replacement      | Justification                                                  |
| :------------------- | :------------------------ | :------------------------------------------------------------- |
| Windows Phone        | **Web (Progressive Web App)** | Accessible on any device with a modern browser, including Windows desktops, Chromebooks, and Linux machines. Flutter's Web target provides this at zero additional development cost. |

**Final target platforms:** Android · iOS · Web (PWA)

> This substitution expands the reach of the application beyond what Windows Phone could ever have provided, at no incremental development cost.

---

## Phase 2 — Defining Requirements

### 2.1 Functional Requirements (FR)

| ID      | Requirement                           | Description                                                                                                | Priority    |
| :------ | :------------------------------------ | :--------------------------------------------------------------------------------------------------------- | :---------- |
| FR-001  | User Registration & Authentication    | Users can register via email/password and authenticate to access the system.                                | **Must**    |
| FR-002  | Create Personal Task                  | An authenticated user can create a task assigned to themselves with a title, optional description, and optional due date/time. | **Must**    |
| FR-003  | Assign Task to Another User           | An authenticated user can create a task and assign it to another registered user by email or username.       | **Must**    |
| FR-004  | View Task List                        | Users can view a list of all tasks assigned to them (both personal and assigned by others).                  | **Must**    |
| FR-005  | Mark Task as Complete                 | Users can mark a task as completed.                                                                         | **Must**    |
| FR-006  | Hide Completed Tasks                  | Completed tasks are hidden from the default task view. A toggle or filter allows viewing completed tasks.    | **Must**    |
| FR-007  | Task Reminder Notification            | The system sends a push/local notification to remind the user of an upcoming task based on the due date/time. | **Should**  |
| FR-008  | User Profile                          | Users can view and edit their display name and profile information.                                          | **Could**   |
| FR-009  | Task Editing                          | Users can edit the title, description, and due date of an existing task.                                     | **Should**  |
| FR-010  | Task Deletion                         | Users can permanently delete a task they own or that was assigned to them.                                    | **Should**  |

### 2.2 Non-Functional Requirements (NFR)

| ID       | Requirement               | Description                                                                                                   | Target Metric         |
| :------- | :------------------------- | :------------------------------------------------------------------------------------------------------------ | :-------------------- |
| NFR-001  | Performance                | The task list screen must render within 2 seconds on a mid-range device (e.g., Snapdragon 6-series).           | ≤ 2s TTI              |
| NFR-002  | Availability               | The backend (Supabase) must maintain 99.9% uptime via the managed cloud service.                               | 99.9%                 |
| NFR-003  | Security                   | All data transmission must occur over HTTPS/TLS. Row Level Security (RLS) policies must be enforced on every table. All user passwords are hashed server-side. | HTTPS + RLS           |
| NFR-004  | Scalability                | The architecture must support horizontal scaling. Supabase's managed PostgreSQL handles this natively.          | 10K concurrent users  |
| NFR-005  | Cross-Platform Consistency | The UI/UX must provide a consistent, native-feeling experience across Android, iOS, and Web.                    | Pixel-perfect parity  |
| NFR-006  | Accessibility              | The application must adhere to WCAG 2.1 Level AA guidelines for accessibility.                                  | WCAG 2.1 AA           |
| NFR-007  | Offline Tolerance          | The app must gracefully degrade when offline, displaying cached data and queuing mutations for sync.            | Graceful degradation  |
| NFR-008  | Code Quality               | Code must pass `dart analyze` with zero warnings. Minimum 80% test coverage on business logic.                  | 0 warnings, ≥80% cov. |

### 2.3 User Stories

#### Epic 1: Authentication
- **US-001**: As a new user, I want to register with my email and password so that I can access the system.
- **US-002**: As a returning user, I want to log in with my credentials so that I can see my tasks.
- **US-003**: As a logged-in user, I want to log out so that my session is terminated securely.

#### Epic 2: Task Management (Core)
- **US-004**: As a user, I want to create a new task with a title so that I can track my work.
- **US-005**: As a user, I want to optionally add a description and due date to my task so that I have full context.
- **US-006**: As a user, I want to assign a task to another user by their email so that I can delegate work.
- **US-007**: As a user, I want to see all tasks assigned to me in a list so that I know what I need to do.
- **US-008**: As a user, I want to mark a task as complete so that I can track my progress.
- **US-009**: As a user, I want completed tasks to be hidden by default so that I can focus on pending work.

#### Epic 3: Task Management (Extended)
- **US-010**: As a user, I want to edit an existing task so that I can update its details.
- **US-011**: As a user, I want to delete a task so that I can remove items I no longer need.
- **US-012**: As a user, I want to filter between "All", "Active", and "Completed" tasks so that I can view tasks by status.

---

## Phase 3 — System Design

### 3.1 System Architecture

The system follows a **Client–BaaS** architecture pattern:

```
┌─────────────────────────────────────────────────┐
│          Flutter Client (Android/iOS/Web)        │
│                                                  │
│  ┌──────────────┐  ┌──────────────┐             │
│  │ Presentation │──│    State     │             │
│  │    Layer     │  │  Management  │             │
│  │  (Screens)   │  │  (Riverpod)  │             │
│  └──────────────┘  └──────┬───────┘             │
│                           │                      │
│               ┌───────────▼─────────┐           │
│               │   Repository Layer  │           │
│               │ (Data Abstraction)  │           │
│               └───────────┬─────────┘           │
└───────────────────────────┼─────────────────────┘
                            │ HTTPS / WSS
┌───────────────────────────┼─────────────────────┐
│              Supabase (BaaS)                     │
│                           │                      │
│  ┌─────────┐  ┌──────────▼──────┐  ┌─────────┐ │
│  │  Auth   │  │   PostgreSQL    │  │Realtime │ │
│  │ Service │  │   Database      │  │ Engine  │ │
│  └─────────┘  └─────────────────┘  └─────────┘ │
│                                                  │
│  ┌──────────────────────────────────────────┐   │
│  │     Row Level Security (RLS Policies)    │   │
│  └──────────────────────────────────────────┘   │
└─────────────────────────────────────────────────┘
```

### 3.2 Application Architecture (Feature-First)

```
lib/
├── main.dart                       # App entry point, Supabase init
├── app.dart                        # MaterialApp.router configuration
│
├── core/                           # Shared infrastructure
│   ├── constants/                  # App-wide constants
│   ├── theme/                      # ThemeData, color schemes, typography
│   ├── router/                     # GoRouter configuration & guards
│   ├── providers/                  # Core providers (Supabase client, Auth state)
│   └── utils/                      # Helper functions, extensions
│
├── features/
│   ├── auth/                       # Authentication feature
│   │   ├── data/                   # Auth repository implementation
│   │   ├── domain/                 # User model (Freezed)
│   │   └── presentation/          # Login, Register screens
│   │
│   └── tasks/                      # Task Management feature
│       ├── data/                   # Task repository implementation
│       ├── domain/                 # Task model (Freezed)
│       └── presentation/          # Task list, Task creation screens
│           ├── screens/
│           └── widgets/
│
└── generated/                      # build_runner output (.g.dart, .freezed.dart)
```

### 3.3 Data Modeling (Supabase PostgreSQL)

#### Table: `profiles`

| Column         | Type        | Constraints                    | Description                    |
| :------------- | :---------- | :----------------------------- | :----------------------------- |
| `id`           | `uuid`      | PK, FK → `auth.users.id`      | Maps to Supabase Auth user.    |
| `email`        | `text`      | NOT NULL, UNIQUE               | User's email address.          |
| `display_name` | `text`      | NULLABLE                       | User's display name.           |
| `avatar_url`   | `text`      | NULLABLE                       | URL to profile avatar.         |
| `created_at`   | `timestamptz` | NOT NULL, DEFAULT `now()`    | Account creation timestamp.    |
| `updated_at`   | `timestamptz` | NOT NULL, DEFAULT `now()`    | Last profile update timestamp. |

#### Table: `tasks`

| Column         | Type        | Constraints                    | Description                               |
| :------------- | :---------- | :----------------------------- | :---------------------------------------- |
| `id`           | `uuid`      | PK, DEFAULT `gen_random_uuid()` | Unique task identifier.                 |
| `title`        | `text`      | NOT NULL                       | Task title (required).                    |
| `description`  | `text`      | NULLABLE                       | Optional task description.                |
| `is_completed` | `boolean`   | NOT NULL, DEFAULT `false`      | Completion status flag.                   |
| `due_at`       | `timestamptz` | NULLABLE                     | Optional due date/time for reminders.     |
| `created_by`   | `uuid`      | NOT NULL, FK → `profiles.id`  | The user who created the task.            |
| `assigned_to`  | `uuid`      | NOT NULL, FK → `profiles.id`  | The user the task is assigned to.         |
| `created_at`   | `timestamptz` | NOT NULL, DEFAULT `now()`    | Task creation timestamp.                  |
| `updated_at`   | `timestamptz` | NOT NULL, DEFAULT `now()`    | Last task update timestamp.               |

#### Row Level Security (RLS) Policies

```sql
-- Users can only read tasks assigned to them or created by them
CREATE POLICY "Users can view own tasks"
  ON tasks FOR SELECT
  USING (auth.uid() = assigned_to OR auth.uid() = created_by);

-- Users can only insert tasks where they are the creator
CREATE POLICY "Users can create tasks"
  ON tasks FOR INSERT
  WITH CHECK (auth.uid() = created_by);

-- Users can only update tasks assigned to them or created by them
CREATE POLICY "Users can update own tasks"
  ON tasks FOR UPDATE
  USING (auth.uid() = assigned_to OR auth.uid() = created_by);

-- Users can only delete tasks they created
CREATE POLICY "Users can delete own tasks"
  ON tasks FOR DELETE
  USING (auth.uid() = created_by);
```

#### Entity Relationship Diagram

```
┌───────────────────────┐          ┌───────────────────────┐
│       PROFILES        │          │         TASKS         │
├───────────────────────┤          ├───────────────────────┤
│ id (PK, uuid)         │◄────┐   │ id (PK, uuid)         │
│ email (text)          │     ├───│ created_by (FK, uuid)  │
│ display_name (text)   │     ├───│ assigned_to (FK, uuid) │
│ avatar_url (text)     │     │   │ title (text)           │
│ created_at (tstz)     │     │   │ description (text)     │
│ updated_at (tstz)     │     │   │ is_completed (bool)    │
└───────────────────────┘     │   │ due_at (tstz)          │
                              │   │ created_at (tstz)      │
        1 ──────── * ─────────┘   │ updated_at (tstz)      │
     (one profile has             └───────────────────────┘
      many tasks)
```

### 3.4 UI/UX Design

> **[UI/UX Design and wireframing will be strictly handled by the Lead Developer using Figma]**
>
> All screen layouts, interaction patterns, color systems, typography scales, and component libraries will be designed and prototyped in Figma before implementation begins. The Figma source file will serve as the single source of truth for the visual design system.

---

## Phase 4 — Coding & Implementation

> The complete, stage-by-stage implementation plan with executable checklists is documented in the companion file:
>
> **→ [roadmap.md](./roadmap.md)**

The coding phase follows Agile Sprint methodology with 1-week sprint cycles. Key principles:

- **Feature-first architecture** — Code is organized by business domain, not by technical layer.
- **Code generation** — Riverpod (`@riverpod`), Freezed (`@freezed`), and JSON Serializable eliminate boilerplate.
- **Repository pattern** — All Supabase interactions are abstracted behind repository interfaces for testability.
- **Continuous integration** — Every push triggers `dart analyze`, `dart format --set-exit-if-changed .`, and `flutter test`.

---

## Phase 5 — Testing

> Detailed testing tasks and tooling setup are specified in **[roadmap.md](./roadmap.md)**.

### 5.1 Testing Strategy Overview

| Level               | Scope                                    | Tools                                 | Coverage Target |
| :------------------ | :--------------------------------------- | :------------------------------------ | :-------------- |
| **Unit Tests**      | Models, Repositories, Providers/Notifiers | `flutter_test`, `mocktail`            | ≥ 80%           |
| **Widget Tests**    | Individual UI components, screens         | `flutter_test`, `golden_toolkit`      | ≥ 60%           |
| **Integration Tests** | Full user flows (E2E)                   | `integration_test`, `patrol`          | Critical paths  |

### 5.2 Unit Testing Strategy

- **Models**: Verify Freezed model serialization (`fromJson`/`toJson`), equality, and `copyWith` behavior.
- **Repositories**: Mock the Supabase client using `mocktail`. Test CRUD operations return expected data and handle errors.
- **Providers/Notifiers**: Use Riverpod's `ProviderContainer` for isolated provider testing. Verify state transitions for task creation, completion, and deletion flows.

### 5.3 Widget Testing Strategy

- **Component Tests**: Each reusable widget (TaskCard, TaskForm, EmptyState) is tested for correct rendering given various input states.
- **Screen Tests**: Full screens tested with mocked providers to verify layout, interaction callbacks, and navigation triggers.

### 5.4 Integration Testing Strategy

- **Critical User Flows**:
  1. Registration → Login → Create Task → View Task → Complete Task → Verify Hidden
  2. Login → Assign Task to User → Verify Assignee Sees Task
  3. Login → Create Task → Edit Task → Delete Task

### 5.5 Quality Gates

All pull requests must pass the following automated checks before merge:

```
✅ dart analyze        → 0 warnings, 0 errors
✅ dart format --set-exit-if-changed .  → All files formatted
✅ flutter test        → All tests pass
✅ flutter test --coverage → ≥ 80% line coverage on /lib/features/
```

---

## Phase 6 — Deployment

> Detailed CI/CD pipeline configuration is specified in **[roadmap.md](./roadmap.md)**.

### 6.1 Deployment Strategy

| Platform    | Distribution Channel            | Build Artifact     |
| :---------- | :------------------------------ | :----------------- |
| **Android** | Google Play Store (Internal → Production) | `.aab` (App Bundle) |
| **iOS**     | Apple TestFlight → App Store    | `.ipa`             |
| **Web**     | Firebase Hosting or Vercel      | Static build (`build/web/`) |

### 6.2 CI/CD Pipeline (GitHub Actions)

```
┌──────────┐    ┌────────────┐    ┌───────────┐    ┌──────────────┐
│ Push to   │───▶│ Lint &     │───▶│ Run Tests │───▶│ All Passed?  │
│   main    │    │ Analyze    │    │           │    │              │
└──────────┘    └────────────┘    └───────────┘    └──────┬───────┘
                                                          │
                                    ┌─────────────────────┼─────────────────────┐
                                    │                     │                     │
                              ┌─────▼─────┐        ┌─────▼─────┐        ┌─────▼─────┐
                              │ Build     │        │ Build     │        │ Build     │
                              │ Android   │        │ iOS       │        │ Web       │
                              │ (.aab)    │        │ (.ipa)    │        │           │
                              └─────┬─────┘        └─────┬─────┘        └─────┬─────┘
                                    │                     │                     │
                              ┌─────▼─────┐        ┌─────▼─────┐        ┌─────▼─────┐
                              │ Deploy to │        │ Deploy to │        │ Deploy to │
                              │Play Store │        │TestFlight │        │ Hosting   │
                              └───────────┘        └───────────┘        └───────────┘
```

### 6.3 Environment Management

| Environment   | Branch    | Backend Instance       | Purpose                    |
| :------------ | :-------- | :--------------------- | :------------------------- |
| **Development** | `dev`   | Supabase (dev project) | Active development & debugging |
| **Staging**    | `staging` | Supabase (staging project) | QA, UAT, pre-release testing |
| **Production** | `main`   | Supabase (prod project) | Live user-facing release   |

---

## Phase 7 — Maintenance

> Detailed post-launch maintenance procedures are specified in **[roadmap.md](./roadmap.md)**.

### 7.1 Post-Launch Monitoring

| Concern             | Tool / Service                | Action                                        |
| :------------------ | :---------------------------- | :-------------------------------------------- |
| **Crash Reporting** | Sentry or Firebase Crashlytics | Automatic crash capture with stack traces.     |
| **Performance**     | Supabase Dashboard + Sentry   | Monitor API latency, DB query performance.     |
| **Error Logging**   | Supabase Logs + Sentry        | Centralized error aggregation and alerting.    |
| **User Analytics**  | PostHog or Mixpanel (optional) | Track feature usage, retention, and funnels.   |
| **Uptime**          | UptimeRobot or BetterStack    | Monitor Supabase endpoint availability.        |

### 7.2 Bug-Fixing & Iteration Process

1. **Triage**: Bugs reported via GitHub Issues, categorized by severity (Critical / High / Medium / Low).
2. **Hotfix Flow**: Critical bugs on `main` are addressed via `hotfix/*` branches, merged directly after review.
3. **Sprint Cadence**: Non-critical bugs and feature requests are prioritized in weekly sprint planning.
4. **Release Cadence**: Bi-weekly production releases with semantic versioning (`v1.0.1`, `v1.1.0`, etc.).

### 7.3 Dependency Management

- **Weekly**: Run `flutter pub outdated` to monitor dependency freshness.
- **Monthly**: Audit and update minor/patch versions.
- **Quarterly**: Evaluate major version upgrades with migration testing.

---

## Appendix A — Glossary

| Term     | Definition                                                        |
| :------- | :---------------------------------------------------------------- |
| **BaaS** | Backend-as-a-Service. A cloud service providing backend infrastructure (auth, database, storage). |
| **RLS**  | Row Level Security. PostgreSQL feature that restricts data access at the row level based on policies. |
| **PWA**  | Progressive Web App. A web application that provides native-like experiences via modern browser APIs. |
| **MCP**  | Model Context Protocol. A standardized protocol enabling AI assistants to interact with development tools. |
| **TTI**  | Time to Interactive. The time it takes for a page to become fully interactive.                        |

---

## Appendix B — References

| Resource                        | URL                                                              |
| :------------------------------ | :--------------------------------------------------------------- |
| Flutter Documentation           | https://docs.flutter.dev                                          |
| Riverpod Documentation          | https://riverpod.dev                                              |
| Supabase Documentation          | https://supabase.com/docs                                         |
| Freezed Package                 | https://pub.dev/packages/freezed                                  |
| GoRouter Package                | https://pub.dev/packages/go_router                                |
| Microsoft WP EOL Notice         | https://support.microsoft.com/en-us/windows/windows-phone-8-1-end-of-support-faq |
| MCP Specification               | https://modelcontextprotocol.io                                   |

---

*End of SDLC Plan — Version 1.0*
