-- Private career decisions: promotion recommendations and quarterly-review recommendations and MD decisions.
-- Only managers can read or change them (salespeople can no longer read them from their own career record),
-- and only the MD can approve or decline (any manager while no MD is set in Team).
-- Paste all of this into Supabase > SQL Editor and press Run, once. Existing data is moved, not lost.

begin;

-- One row per decision. data.kind = 'promo' or 'review'; data.staff = the staff id it is about.
create table career_decisions (id text primary key, data jsonb not null);

create function is_md() returns boolean language sql stable set search_path = public
  as $$ select is_manager() and coalesce((me()->>'md')::boolean, false) $$;
create function md_set() returns boolean language sql stable security definer set search_path = public
  as $$ select exists (select 1 from staff where data->>'role' = 'manager'
                         and coalesce((data->>'md')::boolean, false) and coalesce((data->>'active')::boolean, true)) $$;

alter table career_decisions enable row level security;
create policy career_decisions_managers on career_decisions for all to authenticated
  using (is_manager()) with check (is_manager());

-- Approving or declining (a promotion's status, or a review's MD decision) is for the MD only, once an MD is set.
-- A decision already made can then only be changed by the MD too.
create function check_md_decision() returns trigger language plpgsql set search_path = public as $$
declare
  now_d text := coalesce(new.data->>'status', new.data->>'md', '');
  was_d text := case when tg_op = 'UPDATE' then coalesce(old.data->>'status', old.data->>'md', '') else '' end;
begin
  if md_set() and not is_md() and (
       (now_d in ('approved', 'declined') and now_d is distinct from was_d)
    or (was_d in ('approved', 'declined') and new.data is distinct from old.data)) then
    raise exception 'Only the MD can approve, decline or change an MD decision.';
  end if;
  return new;
end $$;
create function check_md_delete() returns trigger language plpgsql set search_path = public as $$
begin
  if coalesce(old.data->>'status', old.data->>'md', '') in ('approved', 'declined') and md_set() and not is_md() then
    raise exception 'Only the MD can remove an MD decision.';
  end if;
  return old;
end $$;
create trigger career_decisions_md_delete before delete on career_decisions
  for each row execute function check_md_delete();
create trigger career_decisions_md before insert or update on career_decisions
  for each row execute function check_md_decision();

grant select, insert, update, delete on career_decisions to authenticated;
grant execute on function is_md(), md_set() to authenticated;
alter publication supabase_realtime add table career_decisions;

-- Move existing promotions and review decisions out of the career table.
alter table career_decisions disable trigger career_decisions_md;
insert into career_decisions (id, data)
  select p->>'id', p || jsonb_build_object('kind', 'promo', 'staff', c.id::text)
  from career c, jsonb_array_elements(coalesce(c.data->'promos', '[]')) p
  on conflict (id) do nothing;
insert into career_decisions (id, data)
  select r->>'id', jsonb_build_object('kind', 'review', 'staff', c.id::text, 'rec', r->'rec', 'md', r->'md', 'reason', r->'reason')
  from career c, jsonb_array_elements(coalesce(c.data->'reviews', '[]')) r
  on conflict (id) do nothing;
alter table career_decisions enable trigger career_decisions_md;

-- What the salesperson may still see: approved level changes ("history") and each review's quarter, date and rating.
update career c set data = (c.data - 'promos') || jsonb_build_object(
  'history', coalesce((select jsonb_agg(jsonb_build_object('from', p->'from', 'to', p->'to', 'fromStart', p->'fromStart', 'effective', p->'effective'))
                       from jsonb_array_elements(coalesce(c.data->'promos', '[]')) p where p->>'status' = 'approved'), '[]'::jsonb),
  'reviews', coalesce((select jsonb_agg(r - 'rec' - 'md' - 'reason')
                       from jsonb_array_elements(coalesce(c.data->'reviews', '[]')) r), '[]'::jsonb));

commit;
