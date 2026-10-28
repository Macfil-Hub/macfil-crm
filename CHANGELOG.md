# Macfil CRM: change log

## 2026-10-28
- Project folder prepared for GitHub: the prototype page is now called `index.html` (GitHub Pages needs this name).
- Updated the Supabase connection library to a current version, so it works with new Supabase projects and their new-style keys.
- Fixed: the page got stuck on "Loading…" before the Supabase address was filled in; it now shows the "Setup not finished" message.
- Started a git history for the project.
- Database setup script: added access grants that newer Supabase projects need, so signed-in staff can reach the tables.
