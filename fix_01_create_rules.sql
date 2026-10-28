-- Fix 1 (2026-10-28): Sales users may only create quotes where they are Sales or AE,
-- and only activities they own. Managers and sales support can still create for anyone.
-- Changes rules only; no data is touched. Paste into Supabase > SQL Editor and press Run, once.

drop policy quotes_add on quotes;
create policy quotes_add on quotes for insert to authenticated
  with check (can_edit() and (see_all() or me()->>'ini' in (data->>'sales', data->>'ae')));

drop policy visits_add on visits;
create policy visits_add on visits for insert to authenticated
  with check (can_edit() and (see_all() or data->>'owner' = me()->>'ini'));
