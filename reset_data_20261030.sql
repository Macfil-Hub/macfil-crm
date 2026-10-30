-- Reset the CRM's test data (30 Oct 2026).
-- Clears: all quotes, customers, activities (visits, calls, meetings, reminders, check-ins) and career records.
-- Keeps: staff accounts and sign-ins, career programme settings (targets and training).
-- Quote numbers restart: the next new quote is number 1 (MF26-1-...).
-- A backup copy is saved first in a private "backup" schema, so this can be undone with undo_reset_20261030.sql.
-- Paste all of this into Supabase > SQL Editor and press Run, once.

begin;

-- 1. Backup copies, kept out of the app's reach (the CRM only reads the "public" schema)
create schema if not exists backup;
revoke all on schema backup from anon, authenticated;
create table backup.quotes_20261030 as table public.quotes;
create table backup.customers_20261030 as table public.customers;
create table backup.visits_20261030 as table public.visits;
create table backup.career_20261030 as table public.career;
create table backup.quote_seq_20261030 as select last_value from public.quote_seq;

-- 2. Clear the data
delete from public.quotes;
delete from public.customers;
delete from public.visits;
delete from public.career;

-- 3. Restart quote numbers at 1
alter sequence public.quote_seq restart with 1;

commit;

-- 4. Check: every count should be 0, and the backup counts show what was saved
select 'quotes' as what, count(*) from public.quotes
union all select 'customers', count(*) from public.customers
union all select 'activities', count(*) from public.visits
union all select 'career records', count(*) from public.career
union all select 'backup: quotes', count(*) from backup.quotes_20261030
union all select 'backup: customers', count(*) from backup.customers_20261030
union all select 'backup: activities', count(*) from backup.visits_20261030
union all select 'backup: career records', count(*) from backup.career_20261030;
