# Macfil CRM: project brief

## Who this is for
- Company: Macfil Sdn Bhd, a Malaysian buying house and authorised distributor of rotating equipment (main products: Sulzer submersible pumps and mixers). Repairs go to the sister company MEESB (repair and overhaul workshop).
- Users: about 12 staff, on desktop and phone equally.
- Owner: Wong (Director). He is not a developer and works on Windows. Explain every step in plain language with exact clicks or commands. Ask before any destructive database change.

## Goal
A CRM modelled on Translead CRM (Japanese CRM/SFA):
- Four record types: Customers, Contacts, Quotes (deals), Activities.
- One screen per customer and per quote, with few clicks.
- Excel-like editing in tables.
- Fix Translead's known gaps: a pipeline board that works on mobile, and charts.

## Stack
- Starting point: `index.html` (working single-file prototype) and `setup.sql` (schema, row-level security, sign-up trigger, quote sequence, photo bucket). Keep the app simple to deploy. Restructure only if it clearly helps maintenance.
- Supabase (Singapore region):
  - Postgres
  - Auth with email and password
  - Row-level security
  - Realtime
  - Storage for activity photos
- Code in a GitHub repository. Static hosting on GitHub Pages (assumed; confirm with Wong).
- The Supabase Auth Site URL and Redirect URLs must match the hosting URL.
- The Supabase anon/publishable key in the frontend is fine. Never commit a service_role or secret key.

## Roles and access (enforced by RLS, not only in the UI)
| Role | Who (initials) | Sees | Can do |
| --- | --- | --- | --- |
| Manager | CM, WL, CS, AY, PC | Everything | Everything; WL is also user admin |
| Finance | AT | Everything | Read only; also user admin |
| Sales support | SH | All deals | Creates quotes for anyone |
| Sales / AE | KC, DH, AZ, FF | Only quotes where they are Sales or AE, and their own activities | Create and edit their own |

Additional rules:
- New sign-ups start inactive. The first sign-up becomes the admin manager.
- Admins set initials, role, admin and active status in the Team screen.

## Team
| Initials | Name | Title |
| --- | --- | --- |
| CM | Yap Chee Meng | Managing Director |
| WL | Wong Woei Liang | Director (owner) |
| CS | Yap Chee Siong | Sales Manager |
| AY | Alvin Yap Chee Hong | Sales Manager |
| AT | Angie Tan Yi Yuen | Finance Manager |
| PC | Peter Choong | Business Development Manager |
| SH | Siti Hajar | Senior Application Engineer, acts as sales support |
| KC | Kenneth Cheow | Sales Executive |
| DH | Derek Hoo | Sales Executive |
| AZ | Afnan Zikry | Sales Executive |
| FF | Fifi Natasha | Sales Engineer |

JW and AJ are former staff who appear in historical data only. MF and JO are office-only and should be ignored.

## Sales workflow (confirmed with Wong)
1. Enquiries land with the salesperson. The salesperson or sales support logs the enquiry, and the quote number is issued immediately.
2. Quote number format: `MF26-{seq}-{product}-{sales}-{ae}`, plus `-R1`, `-R2` for revisions.
   - `seq` comes from the database sequence and continues from 1617.
3. **Quote Status (since 29 Oct 2026):** one Status field with exactly the list from `Macfil_Quotation_Summary.xlsx` (DATA sheet): On Going, Quoted, To Revise, Closed, Win, Lost, Declined.
   - Open: On Going, Quoted, To Revise. The pipeline board columns are these plus Win.
   - Closed = the enquiry closed with no result (not lost to a competitor). It is not counted in conversion.
   - Quoted sets the follow-up to 3 days later. Win records the won date.
   - Older quotes saved with `stage`/`outcome` are read through `st(q)` in index.html (Cancelled → Closed, Revision → To Revise, Won → Win, earlier stages → On Going).
   - The stage table below is the original working agreement; the technical, sourcing and pricing steps now live in the quote checklist.

   Original pipeline stages, each with an owner and a "done when" rule:

| Stage | Owner | Done when |
| --- | --- | --- |
| New enquiry | Sales or sales support | Customer and requirement are clear, quote number issued |
| Technical and sourcing | AE and sales support | Technical review done, supplier or stock cost known |
| Pricing and approval | Salesperson | Margin checked; approval if large or special |
| Quoted | Salesperson | Quote sent; follow-up date set automatically to 3 days later |
| Revision and negotiation | Salesperson | Customer agrees or deal is lost; revisions keep the number with an -R suffix |
| Won (PO received) | Salesperson | PO recorded |

4. Approvals: there is no fixed approver. The requester picks the approver for each deal.
5. Each quote carries a checklist: technical review, supplier or stock cost known, and margin checked (Pending, Done or N/A).
6. Outcomes at any stage: Lost, Declined or Cancelled, each with a reason.
7. After the PO, a separate order status tracks the deal until payment: Order placed (from stock, a supplier PO, or an MEESB job) → Delivered (DO issued) → Invoiced → Paid.

## Activities
- One timeline per customer and per quote.
- Types: Visit, Call, Meeting, Email, Note.
- Scheduling: salespeople schedule their own activities, and managers can assign them to others.
- Visit report fields: who attended, discussion notes, outcome, photos, and next action with a follow-up date.
- The next-action date feeds the home-screen follow-up list.
- Each activity links to a customer and to related quote numbers.

## Screens
| Screen | What it shows |
| --- | --- |
| Home | My or Everyone follow-ups, overdue quotes, activities due in the next 7 days, KPI tiles (open quotes, overdue, pipeline value, invoiced amount to collect) |
| Pipeline | Drag-and-drop board by stage; on mobile, a stage dropdown on each card |
| Quotes | Table with filters (stage, outcome, owner, product), sortable columns and inline editing |
| Customer | One screen with contacts, all quotes, all activities, and quick-add buttons |
| Quote | One screen with details, checklist and activity timeline |
| Activities | Planned and Done lists |
| Calendar | Month view of activities, reminders (activities of type Reminder, with a `remind` field in minutes) and quote follow-up dates; in-app pop-up while open; .ics export for the phone calendar |
| Team | Admin only |

## Sales career development
- Combines the Macfil sales career development programme (workflow document of 16 Oct 2026) with the CRM. Screen: Career (managers) / My progress (staff in the programme).
- Tables from `setup_career.sql`: `career` (one row per staff id: level, start, range, certs, targets, training, assess, onb, notes, reviews) and `career_settings` (row `main`: KPI targets, training modules and expected months per level).
- Access: managers read and write all; a staff member reads only their own row; finance and support see none.
- KPIs are computed in the browser from quotes (Sales or AE), customers and activities. Won date is the quote's `won` field (set when the stage becomes Won), falling back to the quote date.
- Readiness: Ready = at least 75% of KPI targets met, all training passed, and a manager note or review in the last 92 days. Developing = at least 50% of each. At risk = longer than expected at the level with no review in 92 days.
- Default targets and training modules are drafts; Wong confirms them under Programme settings.
- Lost reasons: quotes carry `why` (one of LOSTR in index.html) when Closed, Lost or Declined; `lostPanel()` groups the last 90 days by reason.
- Check-ins: `career.checkin` = {date, time, remind, notes, by, vid}; `vid` is a visits record of type `Check-in` with `careerOf` = staff id, owned by the manager. A Monthly check-in note dated on or after the booking clears it and marks the visit Done.

## Backlog (in this order)
1. **Deploy the prototype.** Set up the GitHub repo, GitHub Pages and the Supabase project. Run `setup.sql`. Test RLS with one test user per role.
2. **Manager dashboard charts:**
   - Pipeline value and forecast by stage
   - Performance per salesperson
   - Overdue follow-ups and ageing quotes
   - Payments outstanding
3. **Excel import** of `Macfil_Quotation_Summary.xlsx`, sheet `2026`:
   - Contents: 618 quotes, No. 1000 to 1616. Columns: No., Inq Date, Customer, Description, Curr, Price, Product, Brand, Sales, AE, Status, Remark.
   - Clean-up: merge duplicate customer names (for example "Palm Oleo" and "Palm-Oleo"), trim initials, and skip "KIV" placeholder rows.
   - The Excel Status values now import one to one into the CRM Status field (same list).
4. **Word (.docx) quotation** generated from a quote, in Macfil's format. Ask Wong for a sample quotation.
5. **Email logging from Outlook / Microsoft 365.** This is blocked until the company's M365 admin approves the connection.
6. **AI meeting summaries and pre-visit customer briefs** through a server-side function calling the Claude API. The API key must never be in the browser.

## Known limitations of the prototype
- Realtime reloads a whole table on every change. This is fine at the current size, but revisit it after the import.
- Updates read and then write the whole JSON record, so simultaneous edits can overwrite each other. Consider column-based tables or a server-side merge.
- The photos bucket is public, protected only by unguessable paths. Consider signed URLs.

## Working style
- Mobile-first, with light and dark mode.
- Test before saying something is done.
- Keep a short CHANGELOG.md in plain language for Wong.
- Small, reviewable changes. Explain what changed and how to check it.
