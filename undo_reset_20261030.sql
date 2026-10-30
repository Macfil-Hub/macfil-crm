-- Undo reset_data_20261030.sql: puts back the quotes, customers, activities and career records saved before the reset,
-- and the quote number counter. Records created after the reset are kept, unless they have the same id as a restored one.
-- Paste into Supabase > SQL Editor and press Run, once.

begin;
insert into public.quotes select * from backup.quotes_20261030 on conflict (id) do nothing;
insert into public.customers select * from backup.customers_20261030 on conflict (id) do nothing;
insert into public.visits select * from backup.visits_20261030 on conflict (id) do nothing;
insert into public.career select * from backup.career_20261030 on conflict (id) do nothing;
select setval('public.quote_seq', (select last_value from backup.quote_seq_20261030));
commit;

-- When you are sure the backup is no longer needed, delete it with:
--   drop schema backup cascade;
