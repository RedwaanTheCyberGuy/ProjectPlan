-- Beyond Code project plan schema
-- 1. Replace the two email placeholders in public.is_beyond_code_member().
-- 2. Run this file in the Supabase SQL editor.
-- 3. Invite both users in Authentication, then run supabase/seed.sql or use the app's Seed tasks button.

create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null,
  email text not null unique,
  role text not null default 'member' check (role in ('owner', 'partner', 'member')),
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.tasks (
  id uuid primary key default gen_random_uuid(),
  source_id text unique,
  progress_status text default 'Not Started',
  title text not null,
  description text,
  category text not null check (category in (
    'Compliance & Safeguarding',
    'Sales Funnels',
    'Courses',
    'Facility',
    'Marketing',
    'Brand',
    'Pricing',
    'Equipment',
    'Growth & Scale',
    'Parking Lot'
  )),
  status text not null default 'To Do' check (status in ('To Do', 'Urgent', 'This Week', 'Next', 'Growth', 'Blind Spots', 'Done')),
  priority text not null default 'Medium' check (priority in ('Low', 'Medium', 'High', 'Urgent')),
  tags text[] not null default '{}',
  assigned_to uuid references public.profiles(id) on delete set null,
  due_date date,
  completed boolean not null default false,
  completed_at timestamptz,
  created_by uuid references public.profiles(id) on delete set null,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.task_notes (
  id uuid primary key default gen_random_uuid(),
  task_id uuid not null references public.tasks(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  note text not null,
  created_at timestamptz not null default now()
);

create or replace function public.is_beyond_code_member()
returns boolean
language sql
stable
as $$
  select lower(coalesce(auth.jwt() ->> 'email', '')) in (
    'info@redwaanthecyberguy.com',
    'tarikmokthar78@hotmail.com'
  );
$$;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists set_profiles_updated_at on public.profiles;
create trigger set_profiles_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

drop trigger if exists set_tasks_updated_at on public.tasks;
create trigger set_tasks_updated_at
before update on public.tasks
for each row execute function public.set_updated_at();

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if lower(new.email) in ('info@redwaanthecyberguy.com', 'tarikmokthar78@hotmail.com') then
    insert into public.profiles (id, full_name, email, role, avatar_url)
    values (
      new.id,
      case 
        when lower(new.email) = 'info@redwaanthecyberguy.com' then 'Redwaan' 
        else 'Tarik' 
      end,
      new.email,
      case when lower(new.email) = 'info@redwaanthecyberguy.com' then 'owner' else 'partner' end,
      new.raw_user_meta_data ->> 'avatar_url'
    )
    on conflict (id) do update
      set full_name = excluded.full_name,
          email = excluded.email,
          role = excluded.role,
          avatar_url = excluded.avatar_url;
  end if;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert or update on auth.users
for each row execute function public.handle_new_user();

alter table public.profiles enable row level security;
alter table public.tasks enable row level security;
alter table public.task_notes enable row level security;

drop policy if exists "Beyond Code members can read profiles" on public.profiles;
create policy "Beyond Code members can read profiles"
on public.profiles for select
to authenticated
using (public.is_beyond_code_member());

drop policy if exists "Users can update their profile" on public.profiles;
create policy "Users can update their profile"
on public.profiles for update
to authenticated
using (public.is_beyond_code_member() and id = auth.uid())
with check (public.is_beyond_code_member() and id = auth.uid());

drop policy if exists "Beyond Code members can insert their profile" on public.profiles;
create policy "Beyond Code members can insert their profile"
on public.profiles for insert
to authenticated
with check (public.is_beyond_code_member() and id = auth.uid());

drop policy if exists "Beyond Code members can read tasks" on public.tasks;
create policy "Beyond Code members can read tasks"
on public.tasks for select
to authenticated
using (public.is_beyond_code_member());

drop policy if exists "Beyond Code members can create tasks" on public.tasks;
create policy "Beyond Code members can create tasks"
on public.tasks for insert
to authenticated
with check (public.is_beyond_code_member());

drop policy if exists "Beyond Code members can update tasks" on public.tasks;
create policy "Beyond Code members can update tasks"
on public.tasks for update
to authenticated
using (public.is_beyond_code_member())
with check (public.is_beyond_code_member());

drop policy if exists "Beyond Code members can delete tasks" on public.tasks;
create policy "Beyond Code members can delete tasks"
on public.tasks for delete
to authenticated
using (public.is_beyond_code_member());

drop policy if exists "Beyond Code members can read task notes" on public.task_notes;
create policy "Beyond Code members can read task notes"
on public.task_notes for select
to authenticated
using (public.is_beyond_code_member());

drop policy if exists "Beyond Code members can create task notes" on public.task_notes;
create policy "Beyond Code members can create task notes"
on public.task_notes for insert
to authenticated
with check (public.is_beyond_code_member() and user_id = auth.uid());

drop policy if exists "Beyond Code members can delete their task notes" on public.task_notes;
create policy "Beyond Code members can delete their task notes"
on public.task_notes for delete
to authenticated
using (public.is_beyond_code_member() and user_id = auth.uid());

alter table public.tasks replica identity full;
alter table public.task_notes replica identity full;

do $$
begin
  begin
    alter publication supabase_realtime add table public.tasks;
  exception
    when duplicate_object then null;
  end;
  begin
    alter publication supabase_realtime add table public.task_notes;
  exception
    when duplicate_object then null;
  end;
end $$;
