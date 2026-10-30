# Macfil CRM: change log

## 2026-10-30
- Career: new **KPI trend** panel on each person's page and on My progress: a small bar chart per KPI for the last 6 months (4 quarters for new customers), green when the target was met, with the target as a dashed line. Hover or tap a bar for its value.
- Career: **Book check-in** now starts with a ready-made agenda (KPIs, open quotes, lost reasons, training, last actions, new actions), which the manager can edit.
- Quotes: setting a quote to **Closed, Lost or Declined** now needs a reason from a list (Price, Technical scope, Slow response, Delivery time, Competitor brand, Customer cancelled, Other). The old text box is kept for details. Choosing one of these statuses on the board or in the table opens the quote so the reason can be picked.
- Career: new **Why deals were lost** panel on each person's page and on the team page (last 90 days), with the training or action that would help most.
- Career: managers can **Book check-in** on a person's page. It goes into the manager's Calendar with a reminder, the salesperson sees the booked date on My progress, and the roster shows it. Saving a "Monthly check-in" note on or after that date closes the booking and marks the calendar entry Done.

## 2026-10-29
- Follow-ups: the four tiles at the top now follow the Mine / Everyone switch, like the list below them.
- Quotes: **Product code** is now a list (BC Brook Crompton, SP Sulzer, GN General, NW Neway). **Brand** suggests the common brands and tidies spelling when saved (for example "BROOK CROMPTON" becomes "Brook"); if left empty it is filled from the product code.
- Quotes: a price is required before the status can be Quoted, To Revise or Win.
- Quotes: follow-up dates are hidden on closed quotes (Win, Closed, Lost, Declined), so they no longer show as overdue.
- Quotes table: new **Inq Date**, **Brand** and **Remark** columns, matching the Excel. Search also looks in brand and remark.
- Totals now show RM and USD separately instead of adding them together.
- New **Calendar** screen in the side menu: a month view of planned activities, reminders and quote follow-up dates. Tap a day to see its list and add an activity or a reminder for that day. Managers can switch between Mine and Everyone.
- **Reminders:** add one from the Calendar, or set "Reminder alert" on any activity (at the time, 10 or 30 minutes, 1 hour or 1 day before). While the CRM is open, a pop-up appears at the reminder time. "Add to phone calendar" saves it to the phone's own calendar, which alerts even when the CRM is closed.
- Fixed: before 8 am, new records were dated the previous day (the app used UTC instead of Malaysia time).
- Activities: Photos now has two buttons, **Take photo** and **Choose from gallery or files**, so staff can add pictures already on their phone. Chosen photos show as thumbnails and can be removed before saving. Several photos with the same name (common on iPhone) no longer clash.
- Quotes now use the same **Status** list as the Quotation Summary Excel file: On Going, Quoted, To Revise, Closed, Win, Lost, Declined. It replaces the separate Stage and Outcome fields in the quote form, the Quotes table and its filter.
- The Pipeline board now has four columns: On Going, Quoted, To Revise and Win.
- Existing quotes keep their position: Won becomes Win, Revision becomes To Revise, Cancelled becomes Closed, and the early stages become On Going.
- Fixed: on phones, the bottom menu covered the Save and Cancel buttons on forms.

## 2026-10-29: Sales career development
- New **Career** screen for managers: who is Ready, Developing, Early stage or At risk; who needs a check-in; a roster with each person's quotes, conversion and orders won; and settings for targets and training per career level.
- New **My progress** screen for salespeople in the programme: readiness checklist, KPIs, training, feedback notes and quarterly ratings. A short progress line also appears at the top of Follow-ups.
- KPIs (quotes issued, conversion, new customers, orders won, repeat business, activities done) are worked out from the CRM itself, so nobody types them in. Tap a KPI to see the quotes behind it.
- Managers add feedback notes with development actions, record quarterly reviews (rating, recommendation, MD decision and reason), tick onboarding steps and update training.
- Privacy: each person sees only their own career page and never sees promotion or salary decisions. Finance and sales support do not see career records.
- Quotes now remember the date they were won, and new customers remember the date they were added, so KPIs are accurate from now on.
- Database: `setup_career.sql` has been run in Supabase (adds the `career` and `career_settings` tables).

## 2026-10-28
- Project folder prepared for GitHub: the prototype page is now called `index.html` (GitHub Pages needs this name).
- Updated the Supabase connection library to a current version, so it works with new Supabase projects and their new-style keys.
- Fixed: the page got stuck on "Loading…" before the Supabase address was filled in; it now shows the "Setup not finished" message.
- Started a git history for the project.
- Database setup script: added access grants that newer Supabase projects need, so signed-in staff can reach the tables.
- Connected the app to Macfil's Supabase project (Singapore). The database setup script has been run.
- Fixed: the "Forgot password" email link now opens the CRM page itself, not the bare GitHub address.
- Fixed: the sign-up confirmation email now always links back to the CRM page.
- Added rls_test.sql: a one-click check, run in Supabase, that each role sees and changes only what it should. It leaves no data behind.
- Tightened access rules (fix_01_create_rules.sql): Sales staff can only create quotes where they are Sales or AE, and only their own activities. The app now explains this instead of showing a database error.
- Fixed: saving a visit or activity failed with "Could not save"; the Photos field is now a proper photo picker.
