-- Macfil CRM database setup. Paste all of this into Supabase > SQL Editor and press Run, once.

create table staff (id uuid primary key references auth.users on delete cascade, data jsonb not null default '{}');
create table quotes (id text primary key, data jsonb not null);
create table customers (id text primary key, data jsonb not null);
create table visits (id text primary key, data jsonb not null);

-- Quote numbers continue from the Excel register (next number 1617)
create sequence quote_seq start 1617;
create function next_seq() returns int language sql security definer set search_path = public
  as $$ select nextval('quote_seq')::int $$;

-- Who is signed in, and what they may do
create function me() returns jsonb language sql stable security definer set search_path = public
  as $$ select data from staff where id = auth.uid() and coalesce((data->>'active')::boolean, false) $$;
create function see_all() returns boolean language sql stable set search_path = public
  as $$ select coalesce(me()->>'role' in ('manager','finance','support'), false) $$;
create function can_edit() returns boolean language sql stable set search_path = public
  as $$ select coalesce(me() is not null and me()->>'role' <> 'finance', false) $$;
create function is_admin() returns boolean language sql stable set search_path = public
  as $$ select coalesce((me()->>'admin')::boolean, false) $$;

-- Every new sign-up becomes an inactive staff record; the very first sign-up becomes the admin manager
create function on_signup() returns trigger language plpgsql security definer set search_path = public as $$
declare first boolean := not exists (select 1 from staff);
begin
  insert into staff (id, data) values (new.id, jsonb_build_object(
    'name', coalesce(new.raw_user_meta_data->>'name', new.email), 'email', new.email, 'ini', '',
    'role', case when first then 'manager' else 'sales' end, 'admin', first, 'active', first));
  return new;
end $$;
create trigger on_signup after insert on auth.users for each row execute function on_signup();

-- Row-level security: sales see only their own quotes and activities, enforced by the database
alter table staff enable row level security;
alter table quotes enable row level security;
alter table customers enable row level security;
alter table visits enable row level security;

create policy staff_read on staff for select to authenticated using (true);
create policy staff_admin on staff for all to authenticated using (is_admin()) with check (is_admin());

create policy quotes_read on quotes for select to authenticated
  using (see_all() or (me() is not null and me()->>'ini' in (data->>'sales', data->>'ae')));
create policy quotes_add on quotes for insert to authenticated with check (can_edit());
create policy quotes_edit on quotes for update to authenticated
  using (can_edit() and (see_all() or me()->>'ini' in (data->>'sales', data->>'ae')));
create policy quotes_delete on quotes for delete to authenticated using (is_admin());

create policy customers_read on customers for select to authenticated using (me() is not null);
create policy customers_add on customers for insert to authenticated with check (can_edit());
create policy customers_edit on customers for update to authenticated using (can_edit());
create policy customers_delete on customers for delete to authenticated using (is_admin());

create policy visits_read on visits for select to authenticated
  using (see_all() or (me() is not null and data->>'owner' = me()->>'ini'));
create policy visits_add on visits for insert to authenticated with check (can_edit());
create policy visits_edit on visits for update to authenticated
  using (can_edit() and (see_all() or data->>'owner' = me()->>'ini'));
create policy visits_delete on visits for delete to authenticated using (is_admin());

-- Let signed-in users reach the tables through the app (the rules above still decide what each person sees).
-- Newer Supabase projects no longer grant this automatically.
grant select, insert, update, delete on staff, quotes, customers, visits to authenticated;
grant execute on function next_seq(), me(), see_all(), can_edit(), is_admin() to authenticated;

-- Live updates between users
alter publication supabase_realtime add table staff, quotes, customers, visits;

-- Photo storage for activity reports
insert into storage.buckets (id, name, public) values ('photos', 'photos', true);
create policy photos_upload on storage.objects for insert to authenticated
  with check (bucket_id = 'photos' and me() is not null);
