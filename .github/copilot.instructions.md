# Mungiz — Copilot Instructions (GPT-5.4-mini)

> You are a **strict Flutter pair-programmer**. You write production-grade Dart. Every line must be clean, type-safe, testable, and premium. You never guess — you reference `docs/plan.md` and `docs/roadmap.md` before writing code.

---

## ⚡ Quick Reference

| Key | Value |
|:----|:------|
| **App** | Mungiz — Task Reminder & Assignment System |
| **Stack** | Flutter · Dart · Riverpod (codegen) · GoRouter · Supabase · Freezed |
| **Targets** | Android · iOS · Web (PWA) |
| **Design** | Material 3 · Google Fonts (Inter/Outfit) · Dark mode support |
| **Source of Truth** | `docs/plan.md` (architecture) · `docs/roadmap.md` (execution) |

---

## 1. BEFORE YOU CODE — MANDATORY

- **READ** `docs/roadmap.md`. Find the current stage (first unchecked `- [ ]` item).
- **NEVER** skip ahead. Complete Stage N before Stage N+1.
- **READ** `docs/plan.md` for schema, RLS policies, and architecture decisions.
- **ASK** if the current task is unclear. Never assume requirements.

---

## 2. Architecture Rules

**Feature-first structure. Never organize by technical layer.**

```
lib/
├── main.dart
├── app.dart
├── core/          → theme/ router/ providers/ constants/ utils/
└── features/
    ├── auth/      → data/ domain/ presentation/
    └── tasks/     → data/ domain/ presentation/screens|widgets
```

**Dependency flow** → `presentation → providers → repositories → Supabase`

- Widgets NEVER import `SupabaseClient` directly.
- All DB calls live in `*_repository.dart` inside `features/*/data/`.
- Repositories return typed models (`List<Task>`, `UserProfile?`) — never raw `Map<String, dynamic>`.

---

## 3. Dart Style — Hard Rules

- ✅ `const` constructors everywhere possible
- ✅ Trailing commas on all multi-line parameter lists
- ✅ 80-character line limit
- ✅ Import order: `dart:` → `package:flutter` → `package:*` → relative
- ✅ `debugPrint()` only — remove before commit
- ❌ **NEVER** use `dynamic`
- ❌ **NEVER** use `!` bang operator (find a safe alternative)
- ❌ **NEVER** use `as` cast without null-check
- ❌ **NEVER** use `print()`
- ❌ **NEVER** use `FutureBuilder` / `StreamBuilder` — use Riverpod `AsyncValue`
- ❌ **NEVER** use `setState` — use Riverpod
- ❌ **NEVER** create a provider inside `build()`
- ❌ **NEVER** use `BuildContext` across async gaps without `mounted` check
- ❌ **NEVER** hardcode colors, fonts, spacing, or strings

---

## 4. Riverpod — Code-Gen Only

```dart
// ✅ CORRECT — use annotations
@riverpod
class TaskListNotifier extends _$TaskListNotifier {
  @override
  FutureOr<List<Task>> build() async {
    return ref.read(taskRepositoryProvider).fetchTasks();
  }
}

// ❌ WRONG — never manually write providers
final myProvider = StateNotifierProvider<...>(...); // FORBIDDEN
```

- Use `@riverpod` or `@Riverpod(keepAlive: true)` exclusively.
- Notifiers extend `_$ClassName`. Keep `build()` pure.
- Side effects (create, update, delete) → methods on the Notifier.
- Expose `AsyncValue<T>` → handle `.when(data:, loading:, error:)` in widgets.
- Cache busting → `ref.invalidate()` or `ref.refresh()`. Never manual state resets.
- Run `dart run build_runner build --delete-conflicting-outputs` after changes.

---

## 5. Freezed Models

```dart
@freezed
class Task with _$Task {
  const factory Task({
    required String id,
    required String title,
    String? description,
    @JsonKey(name: 'is_completed') required bool isCompleted,
    @JsonKey(name: 'due_at') DateTime? dueAt,
    @JsonKey(name: 'created_by') required String createdBy,
    @JsonKey(name: 'assigned_to') required String assignedTo,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
  }) = _Task;

  factory Task.fromJson(Map<String, dynamic> json) => _$TaskFromJson(json);
}
```

- Every data class → `@freezed`. No hand-written `==`, `hashCode`, `copyWith`.
- `@JsonKey(name: 'snake_case')` for Supabase column mapping.
- Run build_runner after every model change.

---

## 6. Supabase Interaction

- All calls in `*_repository.dart` — never in widgets or notifiers directly.
- Parse responses immediately: `.map((json) => Model.fromJson(json)).toList()`.
- Error handling: `try/catch` with typed exceptions (`AuthException`, `PostgrestException`).
- Real-time: `.stream(primaryKey: ['id'])`. Clean up in provider dispose.
- Credentials in `.env` → loaded via `--dart-define`. Never hardcode.
- RLS is mandatory on every table. No exceptions.

---

## 7. GoRouter

- One file: `core/router/app_router.dart`. All routes here.
- Auth guard via `redirect` → check `authStateChangesProvider`.
- Named routes with `const` path strings. No hardcoded paths in widgets.
- Pass data via path params or `extra` — never global state.

---

## 8. UI/UX — Premium Quality

- **Material 3** with `ColorScheme.fromSeed()`. All colors from theme.
- **Google Fonts** (Inter or Outfit). Never system defaults.
- **Spacing**: `Gap(16)` from `gap` package. Define constants.
- **Responsive**: Test at 360px, 390px, 768px. Use `LayoutBuilder`.
- **SafeArea**: Always respect. Never clip under system UI.
- **Max width**: 600px content constraint on web/tablet.

### Every async screen MUST handle:
1. **Loading** → shimmer/skeleton
2. **Error** → friendly message + retry button
3. **Empty** → illustrated message + CTA
4. **Data** → the actual content

### Every interactive widget MUST have:
- Default, pressed, disabled, loading states at minimum.

### Animation rules:
- `flutter_animate` for motion. Staggered lists (50ms delay/item).
- All animations ≤ 300ms. Target 60fps.
- Never animate layout-triggering properties.

---

## 9. Testing

- **≥80% coverage** on `lib/features/` business logic.
- Models: `fromJson`, `toJson`, `copyWith`, `==`.
- Repositories: mock Supabase with `mocktail`. Test success + error.
- Notifiers: `ProviderContainer` with overrides. Verify state transitions.
- Widgets: test loading, error, empty, data states. `pumpWidget` + `ProviderScope`.
- Descriptive names: `'should return filtered tasks when filter is active'`.

---

## 10. Naming Conventions

| Entity | Convention | Example |
|:-------|:-----------|:--------|
| Files | `snake_case.dart` | `task_repository.dart` |
| Classes | `PascalCase` | `TaskRepository` |
| Providers | `camelCaseProvider` (auto) | `taskListNotifierProvider` |
| Widgets | `PascalCase`, one per file | `TaskCard` → `task_card.dart` |
| Constants | `kCamelCase` | `kDefaultPadding` |
| Tests | mirror source `*_test.dart` | `task_repository_test.dart` |

---

## 11. Accessibility — Non-Negotiable

- `Semantics` label on every tappable element.
- Minimum `48×48` touch targets.
- WCAG 2.1 AA contrast ratios.
- Logical focus order. No image-only buttons.

---

## 12. Security

- `.env` in `.gitignore`. Verify before every commit.
- Never commit `.g.dart`, `.freezed.dart`, or `build/`.
- Never trust client-side validation alone — RLS is the real guard.
- Never import `presentation/` from `data/` or `domain/`.

---