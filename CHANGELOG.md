# Changelog

Tất cả thay đổi đáng chú ý của LeadHub. Format theo [Keep a Changelog](https://keepachangelog.com), versioning theo [SemVer](https://semver.org/).

## [0.1.0] — 2026-05-13

### Added
- Skeleton single-file `index.html` với React 18 (CDN) + Babel standalone.
- Color tokens đầy đủ trong `:root` (brand, surface, text, semantic, area, status, layout).
- PinPad login 4 số + 4 user chips clickable.
- Auto-login từ `localStorage` (`leadhub_pin`).
- Khoá nhập 10s sau 3 lần PIN sai.
- Layout: Sidebar (brand + nav + user + conn indicator) + TopBar (hamburger mobile + title + quick + Task).
- 6 màn: Dashboard, Kanban, Timeline, Goals, My Tasks, Settings.
  - **Dashboard:** 4 stat cards + tiến độ goals + task sắp đến deadline.
  - **Kanban:** 5 cột (Backlog/Todo/Doing/Review/Done) render từ mock data, card có badge area/priority + avatar assignee + due date.
  - **My Tasks:** reuse Kanban prefilter `assigneeId === currentUser.id`.
  - **Timeline / Goals / Settings:** placeholder "Coming…" (sẽ làm Phase 2).
- Toast system (success / warn / error / info), auto-dismiss 3.5s.
- Role permission matrix `ROLE_PERMS` const — `lead_pm` super-user, các role khác xem all + edit mảng mình.
- Connection indicator 🟢🟡🔴 + Mock mode 🟤 (Phase 0 chưa wire Supabase).
- Responsive shell: desktop ≥1024, tablet 768-1023 (kanban scroll ngang), mobile <768 (sidebar drawer + overlay).
- Mock data: 4 users + 1 project + 2 goals + 6 tasks (mirror seed của `supabase-schema.sql`).
- `supabase-schema.sql` idempotent với tables/indexes/RLS/realtime publication/seed.
- `CLAUDE.md` — project memory cho Claude Code session sau.
- `README.md` — install guide + danh sách PIN demo.
- `.claude/commands/release.md` + `fix.md` — slash commands.
- `.nojekyll` + `.gitignore` + `LICENSE` (MIT).

### Phase tracker
- ✅ Phase 0 — skeleton & mock.
- ⏳ Phase 1 — Supabase wiring + CRUD thật.
- ⏳ Phase 2 — Realtime + 6 màn đầy đủ.
- ⏳ Phase 3 — Polish + notification + responsive.

### Migration cần làm
- Trước khi bump v0.5.0 (Phase 1): tạo Supabase project, chạy `supabase-schema.sql`, paste URL + anon key vào `index.html`.
