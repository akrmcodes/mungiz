-- =============================================================================
-- MUNGIZ — Supabase Database Schema
-- =============================================================================
-- Version:     1.0
-- Date:        2026-04-23
-- Derived From: docs/plan.md §3.3, docs/roadmap.md Stage 2
-- Target:      Supabase SQL Editor (PostgreSQL 15+)
--
-- This script provisions the complete backend schema:
--   1. Tables:    profiles, tasks
--   2. Triggers:  auto-create profile on sign-up, auto-update updated_at
--   3. RLS:       Row Level Security policies per plan.md §3.3
--
-- IMPORTANT: Run this script ONCE in the Supabase SQL Editor.
--            Ensure the "Enable RLS" toggle is ON for both tables after execution.
-- =============================================================================


-- =============================================================================
-- 1. EXTENSIONS
-- =============================================================================
-- Supabase enables these by default, but we declare explicitly for clarity.

CREATE EXTENSION IF NOT EXISTS "pgcrypto";   -- Provides gen_random_uuid()


-- =============================================================================
-- 2. TABLES
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 2.1 PROFILES
-- -----------------------------------------------------------------------------
-- Mirrors auth.users. One profile per authenticated user.
-- The id column is a foreign key to auth.users(id) — when a user is deleted
-- from Supabase Auth, their profile is cascade-deleted.

CREATE TABLE IF NOT EXISTS public.profiles (
  id           UUID        PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email        TEXT        NOT NULL UNIQUE,
  display_name TEXT,
  avatar_url   TEXT,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE  public.profiles              IS 'User profiles, 1:1 with auth.users.';
COMMENT ON COLUMN public.profiles.id           IS 'PK — maps directly to auth.users.id.';
COMMENT ON COLUMN public.profiles.email        IS 'User email, synced from auth.users on sign-up.';
COMMENT ON COLUMN public.profiles.display_name IS 'Optional display name set by the user.';
COMMENT ON COLUMN public.profiles.avatar_url   IS 'Optional URL to the user''s avatar image.';

-- -----------------------------------------------------------------------------
-- 2.2 TASKS
-- -----------------------------------------------------------------------------
-- Central task table. Each task has a creator and an assignee (may be the same
-- user for personal tasks). Both FKs reference profiles(id) with cascade delete.

CREATE TABLE IF NOT EXISTS public.tasks (
  id           UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  title        TEXT        NOT NULL,
  description  TEXT,
  is_completed BOOLEAN     NOT NULL DEFAULT false,
  due_at       TIMESTAMPTZ,
  created_by   UUID        NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  assigned_to  UUID        NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE  public.tasks             IS 'Task items — the core domain entity.';
COMMENT ON COLUMN public.tasks.created_by  IS 'The user who created this task.';
COMMENT ON COLUMN public.tasks.assigned_to IS 'The user this task is assigned to.';

-- Create indexes for the most common query patterns
CREATE INDEX IF NOT EXISTS idx_tasks_created_by  ON public.tasks (created_by);
CREATE INDEX IF NOT EXISTS idx_tasks_assigned_to ON public.tasks (assigned_to);
CREATE INDEX IF NOT EXISTS idx_tasks_due_at      ON public.tasks (due_at)
  WHERE due_at IS NOT NULL;


-- =============================================================================
-- 3. TRIGGER FUNCTIONS
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 3.1 AUTO-CREATE PROFILE ON SIGN-UP
-- -----------------------------------------------------------------------------
-- When a new user registers via Supabase Auth, this trigger automatically
-- inserts a corresponding row into public.profiles with their email.

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER          -- Runs with the privileges of the function owner
SET search_path = public  -- Prevent search_path injection
AS $$
BEGIN
  INSERT INTO public.profiles (id, email)
  VALUES (NEW.id, NEW.email);
  RETURN NEW;
END;
$$;

COMMENT ON FUNCTION public.handle_new_user()
  IS 'Trigger function: auto-inserts a profiles row when a new user signs up.';

-- Attach the trigger to auth.users
-- DROP TRIGGER first to make the script re-runnable
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- -----------------------------------------------------------------------------
-- 3.2 AUTO-UPDATE updated_at TIMESTAMP
-- -----------------------------------------------------------------------------
-- Generic trigger function that sets updated_at = now() on any UPDATE.
-- Attached to both profiles and tasks tables.

CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

COMMENT ON FUNCTION public.handle_updated_at()
  IS 'Trigger function: auto-sets updated_at to now() on row update.';

-- Attach to profiles
DROP TRIGGER IF EXISTS on_profiles_updated ON public.profiles;

CREATE TRIGGER on_profiles_updated
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_updated_at();

-- Attach to tasks
DROP TRIGGER IF EXISTS on_tasks_updated ON public.tasks;

CREATE TRIGGER on_tasks_updated
  BEFORE UPDATE ON public.tasks
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_updated_at();


-- =============================================================================
-- 4. ROW LEVEL SECURITY (RLS)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 4.1 ENABLE RLS
-- -----------------------------------------------------------------------------

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tasks    ENABLE ROW LEVEL SECURITY;

-- -----------------------------------------------------------------------------
-- 4.2 PROFILES POLICIES
-- -----------------------------------------------------------------------------

-- Any authenticated user can read any profile.
-- Required for task assignment — users need to look up other users by email.
CREATE POLICY "Authenticated users can view all profiles"
  ON public.profiles
  FOR SELECT
  TO authenticated
  USING (true);

-- Users can only update their own profile.
CREATE POLICY "Users can update own profile"
  ON public.profiles
  FOR UPDATE
  TO authenticated
  USING (id = auth.uid())
  WITH CHECK (id = auth.uid());

-- -----------------------------------------------------------------------------
-- 4.3 TASKS POLICIES (per plan.md §3.3)
-- -----------------------------------------------------------------------------

-- SELECT: Users can view tasks where they are the creator OR the assignee.
CREATE POLICY "Users can view own tasks"
  ON public.tasks
  FOR SELECT
  TO authenticated
  USING (auth.uid() = created_by OR auth.uid() = assigned_to);

-- INSERT: Users can only create tasks where they are the creator.
CREATE POLICY "Users can create tasks"
  ON public.tasks
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = created_by);

-- UPDATE: Users can update tasks where they are the creator OR the assignee.
CREATE POLICY "Users can update own tasks"
  ON public.tasks
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = created_by OR auth.uid() = assigned_to)
  WITH CHECK (auth.uid() = created_by OR auth.uid() = assigned_to);

-- DELETE: Users can only delete tasks they created.
CREATE POLICY "Users can delete own tasks"
  ON public.tasks
  FOR DELETE
  TO authenticated
  USING (auth.uid() = created_by);


-- =============================================================================
-- 5. VERIFICATION QUERIES (Optional — run these after the script to confirm)
-- =============================================================================

-- Verify tables exist
-- SELECT table_name FROM information_schema.tables
-- WHERE table_schema = 'public' AND table_name IN ('profiles', 'tasks');

-- Verify RLS is enabled
-- SELECT tablename, rowsecurity FROM pg_tables
-- WHERE schemaname = 'public' AND tablename IN ('profiles', 'tasks');

-- Verify policies
-- SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
-- FROM pg_policies
-- WHERE schemaname = 'public';

-- Verify triggers
-- SELECT trigger_name, event_manipulation, event_object_table, action_timing
-- FROM information_schema.triggers
-- WHERE trigger_schema = 'public' OR event_object_schema = 'auth';


-- =============================================================================
-- END OF SCHEMA SCRIPT
-- =============================================================================
