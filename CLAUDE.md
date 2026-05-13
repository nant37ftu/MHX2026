# CLAUDE.md — LeadHub Project Memory

## Project overview
LeadHub là platform quản trị công việc nội bộ cho team core 4 leaders/sub-leaders cùng chạy 1 dự án. Single-file React (CDN) + Supabase + GitHub Pages. Internal tool, không public.

## Tech stack
- Frontend: React 18 + Babel standalone (CDN), single `index.html`
- DB: Supabase (Postgres + Realtime), RLS open_all
- Auth: PIN 4 số custom, persist localStorage (`leadhub_pin`)
- Hosting: GitHub Pages, branch `main`, `.nojekyll`

## File structure
Xem PLAYBOOK.md mục 3 — tuân thủ tối thiểu.

```
leadhub/
├── index.html
├── supabase-schema.sql
├── README.md
├── CLAUDE.md           (file này)
├── PLAYBOOK.md
├── CHANGELOG.md
├── LICENSE
├── .gitignore
├── .nojekyll
└── .claude/commands/   (release.md, fix.md)
```

## Database tables
- `users` (pin, full_name, role, area, color, is_active)
- `projects` (name, description, start_at, end_at)
- `goals` (project_id, title, area, due_at, status, sort_order)
- `tasks` (project_id, goal_id, title, status, priority, area, assignee_id, due_at, checklist jsonb, tags jsonb)
- `activities` (task_id, user_id, kind, payload jsonb) — audit + comments

Realtime bật cho: `tasks`, `goals`, `activities`, `users`. Tắt cho `projects` (ít đổi).

## Conventions
- DB snake_case, JS camelCase, có `fromDb` / `toDb` mapper.
- App root giữ state, pass props. KHÔNG Context cho data (chỉ theme/toast/locale).
- Optimistic UI + diff-wrapper sync (PLAYBOOK 5.2).
- Color tokens trong `:root`.
- 3 states cho mọi data view (Loading / Empty / Error).
- SemVer + CHANGELOG mọi release.
- `index.html` < 3000 dòng — nếu vượt, cân nhắc tách.

## Roles & permissions
Định nghĩa trong `ROLE_PERMS` const ở `index.html`:
- `lead_pm` (super-user): full CRUD, settings users, delete any task.
- `lead_tech`, `sub_content`, `sub_ops`: CRUD task mảng mình, xem cross-mảng.

Role là `text` trong DB (không enum) — rename/thêm role không cần migration schema.

## Status columns (Kanban)
`backlog → todo → doing → review → done`. Định nghĩa trong `STATUS_COLS` const.

## Area codes
`pm | tech | content | ops` — màu trong CSS vars `--area-pm/tech/content/ops`.

## Workflow
- Bug nhỏ: tả triệu chứng + dòng → grep → fix → commit `fix: ...`
- Feature: plan trước → implement → commit `feat: ...` → entry CHANGELOG → tag nếu bump version
- Mỗi version: 1-3 feature focused, không nhồi.

## Phase tracker
- ✅ Phase 0 (v0.1.0): skeleton + mock data hardcoded. Login PIN + Layout + Dashboard + Kanban hoạt động bằng mock.
- ✅ Phase 1 (v0.5.0): Supabase wired, `useStateSync` hook (diff-wrapper auto-sync), mappers, login PIN từ DB, Task Detail Modal + Quick Create, CRUD đủ Create/Update/Delete tasks.
- ✅ Phase 2 (v1.0.0): Realtime channel 4 tables + auto-reconnect, Timeline (Gantt-lite) zoom Week/Month + group Area/Assignee, Goals view + Create Goal, Settings 3 tabs (Users/Project/About), Activity log + comment + auto-log status_change/assigned/edited/created.
- ✅ Phase 3 (v1.1.0): Responsive polish, browser notification, search/filter Kanban, export CSV, drag-drop Kanban.

## Environment
- Supabase URL: `https://oczwzcmgqcdjrozgyisr.supabase.co` (hardcoded trong `index.html`)
- Supabase publishable key: `sb_publishable_...` (OK public, format mới thay cho `anon` key — đừng dùng `service_role` key)
- GitHub repo: https://github.com/nant37ftu/MHX2026.git
- GitHub Pages URL: (paste sau khi bật Pages)

## Sync architecture
- `useStateSync(table, fromDb, toDb, onError)` ở `index.html` line ~360-410.
- Setter tự diff prev/next theo `id` → gọi `sb.from(table).upsert(toDb(item))` cho insert/update, `delete().eq('id', id)` cho row biến mất.
- `JSON.stringify` để so prev vs next item — nếu giống hệt thì skip upsert.
- Phase 2 sẽ thêm 1 channel realtime subscribe 4 bảng → handler dedupe (PLAYBOOK 6.2) để tránh re-render loop khi nhận lại update của chính mình.

## Pitfalls đã gặp
(Sẽ điền dần khi gặp)

## Anti-scope (đừng tự thêm)
- ❌ Chat realtime nhiều room (đã có Slack/Zalo).
- ❌ File upload (dùng link Google Drive paste vào description).
- ❌ Email notification (chưa cần).
- ❌ Mobile native app.
- ❌ Audit log chi tiết enterprise.
