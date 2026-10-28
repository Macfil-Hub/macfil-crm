-- Sales career development: adds two new tables. Changes no existing data.
-- Paste all of this into Supabase > SQL Editor and press Run, once.

-- One row per staff member in the programme (level, start date, training, notes, quarterly reviews).
create table career (id uuid primary key references staff(id) on delete cascade, data jsonb not null default '{}');
-- Programme settings: KPI targets and training modules per career level (one row, id 'main').
create table career_settings (id text primary key, data jsonb not null default '{}');

create function is_manager() returns boolean language sql stable set search_path = public
  as $$ select coalesce(me()->>'role' = 'manager', false) $$;

-- Who sees what:
--   Managers see and edit everyone's career record.
--   Each person can read their own record only, and cannot change it.
--   Finance and sales support do not see career records (promotion and salary notes are private).
alter table career enable row level security;
alter table career_settings enable row level security;

create policy career_read on career for select to authenticated
  using (is_manager() or (id = auth.uid() and me() is not null));
create policy career_write on career for all to authenticated
  using (is_manager()) with check (is_manager());

create policy career_settings_read on career_settings for select to authenticated using (me() is not null);
create policy career_settings_write on career_settings for all to authenticated
  using (is_manager()) with check (is_manager());

grant select, insert, update, delete on career, career_settings to authenticated;
grant execute on function is_manager() to authenticated;

-- Live updates between users
alter publication supabase_realtime add table career, career_settings;
