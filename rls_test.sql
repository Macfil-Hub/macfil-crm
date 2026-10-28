-- Macfil CRM access-rules test. Paste all of this into Supabase > SQL Editor and press Run.
-- It creates pretend staff (one per role) and pretend quotes and activities, checks what each
-- person can see and change, then undoes everything. Nothing is saved; safe to run any time.

-- Runs one statement as a given pretend user, the same way the app would. Returns the row count, or 'blocked'.
create or replace function pg_temp.try_as(uid uuid, q text) returns text language plpgsql as $$
declare n bigint; r text;
begin
  perform set_config('request.jwt.claims', json_build_object('sub', uid, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', uid::text, true);
  set local role authenticated;
  begin
    if q ilike 'select%' then execute q into n; else execute q; get diagnostics n = row_count; end if;
    r := n::text;
  exception when others then r := 'blocked';
  end;
  reset role;
  return r;
end $$;

create or replace function pg_temp.rls_test()
returns table(result text, who text, "check" text, expected text, got text) language plpgsql as $$
declare
  u jsonb := '{}'; ini text; c record; g text;
  a_res text[] := '{}'; a_who text[] := '{}'; a_chk text[] := '{}'; a_exp text[] := '{}'; a_got text[] := '{}';
begin
  begin
    -- Pretend staff: XM manager (admin), XF finance, XS sales support, XA and XB sales, XI not yet activated
    foreach ini in array array['XM','XF','XS','XA','XB','XI'] loop
      u := u || jsonb_build_object(ini, gen_random_uuid());
      insert into auth.users (id, email, raw_user_meta_data)
        values ((u->>ini)::uuid, lower(ini) || '@rls-test.invalid', jsonb_build_object('name', 'Test ' || ini));
    end loop;
    update staff s set data = s.data || v.d from (values
      ('XM', '{"ini":"XM","role":"manager","admin":true,"active":true}'::jsonb),
      ('XF', '{"ini":"XF","role":"finance","admin":false,"active":true}'),
      ('XS', '{"ini":"XS","role":"support","admin":false,"active":true}'),
      ('XA', '{"ini":"XA","role":"sales","admin":false,"active":true}'),
      ('XB', '{"ini":"XB","role":"sales","admin":false,"active":true}'),
      ('XI', '{"ini":"XI","role":"sales","admin":false,"active":false}')) v(i, d)
    where s.id = (u->>v.i)::uuid;

    -- Pretend records: XA is Sales on qtest1 and AE on qtest2; qtest3 belongs only to XB
    insert into customers values ('ctest1', '{"name":"RLS Test Customer"}');
    insert into quotes values
      ('qtest1', '{"seq":90001,"customer":"RLS Test Customer","sales":"XA","ae":""}'),
      ('qtest2', '{"seq":90002,"customer":"RLS Test Customer","sales":"XB","ae":"XA"}'),
      ('qtest3', '{"seq":90003,"customer":"RLS Test Customer","sales":"XB","ae":""}');
    insert into visits values
      ('vtest1', '{"owner":"XA","customer":"RLS Test Customer"}'),
      ('vtest2', '{"owner":"XB","customer":"RLS Test Customer"}');

    for c in select * from (values
      ('XM', 'Manager sees all quotes',                    'select count(*) from quotes where id like ''qtest%''', '3'),
      ('XM', 'Manager sees all activities',                'select count(*) from visits where id like ''vtest%''', '2'),
      ('XM', 'Manager can edit anyone''s quote',           'update quotes set data = data || ''{"remark":"t"}'' where id = ''qtest3''', '1'),
      ('XF', 'Finance sees all quotes',                    'select count(*) from quotes where id like ''qtest%''', '3'),
      ('XF', 'Finance sees all activities',                'select count(*) from visits where id like ''vtest%''', '2'),
      ('XF', 'Finance cannot edit a quote',                'update quotes set data = data || ''{"remark":"t"}'' where id = ''qtest1''', '0'),
      ('XF', 'Finance cannot create a quote',              'insert into quotes values (''qtest9'', ''{"sales":"XF"}'')', 'blocked'),
      ('XF', 'Finance cannot create an activity',          'insert into visits values (''vtest9'', ''{"owner":"XF"}'')', 'blocked'),
      ('XS', 'Sales support sees all quotes',              'select count(*) from quotes where id like ''qtest%''', '3'),
      ('XS', 'Sales support can create a quote for others','insert into quotes values (''qtest4'', ''{"sales":"XB","ae":""}'')', '1'),
      ('XS', 'Sales support can edit any quote',           'update quotes set data = data || ''{"remark":"t"}'' where id = ''qtest3''', '1'),
      ('XA', 'Sales sees only quotes where they are Sales or AE', 'select count(*) from quotes where id like ''qtest%''', '2'),
      ('XA', 'Sales sees only their own activities',       'select count(*) from visits where id like ''vtest%''', '1'),
      ('XA', 'Sales can edit own quote (as Sales)',        'update quotes set data = data || ''{"remark":"t"}'' where id = ''qtest1''', '1'),
      ('XA', 'Sales can edit own quote (as AE)',           'update quotes set data = data || ''{"remark":"t"}'' where id = ''qtest2''', '1'),
      ('XA', 'Sales cannot edit someone else''s quote',    'update quotes set data = data || ''{"remark":"t"}'' where id = ''qtest3''', '0'),
      ('XA', 'Sales cannot hand a quote to someone else',  'update quotes set data = data || ''{"sales":"XB"}'' where id = ''qtest1''', 'blocked'),
      ('XA', 'Sales cannot delete a quote',                'delete from quotes where id = ''qtest1''', '0'),
      ('XA', 'Sales can create own quote',                 'insert into quotes values (''qtest5'', ''{"sales":"XA","ae":""}'')', '1'),
      ('XA', 'Sales cannot create a quote only for others','insert into quotes values (''qtest6'', ''{"sales":"XB","ae":""}'')', 'blocked'),
      ('XA', 'Sales can create own activity',              'insert into visits values (''vtest3'', ''{"owner":"XA"}'')', '1'),
      ('XA', 'Sales cannot create an activity for others', 'insert into visits values (''vtest4'', ''{"owner":"XB"}'')', 'blocked'),
      ('XA', 'Sales cannot change their own role',         'update staff set data = data || ''{"role":"manager"}'' where id = auth.uid()', '0'),
      ('XA', 'Sales can see customers',                    'select count(*) from customers where id = ''ctest1''', '1'),
      ('XI', 'Inactive account sees no quotes',            'select count(*) from quotes where id like ''qtest%''', '0'),
      ('XI', 'Inactive account sees no customers',         'select count(*) from customers where id = ''ctest1''', '0'),
      ('XI', 'Inactive account cannot create a quote',     'insert into quotes values (''qtest7'', ''{"sales":"XI"}'')', 'blocked'),
      ('XM', 'Admin manager can delete a quote',           'delete from quotes where id = ''qtest3''', '1')
    ) v(who, label, q, expect) loop
      g := pg_temp.try_as((u->>c.who)::uuid, c.q);
      a_res := a_res || case when g = c.expect then 'PASS' else 'FAIL' end;
      a_who := a_who || c.who; a_chk := a_chk || c.label; a_exp := a_exp || c.expect; a_got := a_got || g;
    end loop;

    raise exception 'undo_test_data';  -- rolls back every pretend record created above
  exception when others then
    if sqlerrm <> 'undo_test_data' then
      a_res := a_res || 'ERROR'::text; a_who := a_who || ''::text; a_chk := a_chk || sqlerrm;
      a_exp := a_exp || ''::text; a_got := a_got || ''::text;
    end if;
  end;
  return query select * from unnest(a_res, a_who, a_chk, a_exp, a_got);
end $$;

select * from pg_temp.rls_test();
