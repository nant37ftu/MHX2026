# Changelog

Tất cả thay đổi đáng chú ý của LeadHub. Format theo [Keep a Changelog](https://keepachangelog.com), versioning theo [SemVer](https://semver.org/).

## [1.0.0] — 2026-05-13

### Added
- **Realtime channel** subscribe 4 bảng (`tasks`, `goals`, `users`, `activities`). Khi user A update task, các tab khác cập nhật <1s không cần F5. Auto-reconnect sau 5s nếu mất kết nối.
- **`useStateSync.applyRemote`** — function thứ 3 trả về từ hook, bypass DB sync khi nhận payload realtime, dedupe bằng JSON.stringify để tránh re-render loop khi server echo lại update của chính mình.
- **Connection indicator động:** 🟡 connecting → 🟢 live khi `SUBSCRIBED` → 🔴 offline khi `CHANNEL_ERROR`/`CLOSED` + auto retry.
- **Timeline (Gantt-lite):** thanh ngang start_at → due_at, zoom Tuần (14 ngày) / Tháng (60 ngày), group theo Mảng hoặc Người, today line màu đỏ, hover bar → tooltip, click → mở Task Detail. Task không có start/due hiển thị riêng ở "Chưa lên lịch".
- **Goals view:** card grid responsive, progress bar tự tính `count(done)/count(total)`, expand inline để xem task con, badge area, due date đỏ nếu quá hạn, nút xoá cho lead_pm.
- **Goal Create Modal:** title, mô tả, area, due_at.
- **Settings** với 3 tabs (chỉ `lead_pm` truy cập):
  - **Người dùng:** bảng inline-edit PIN/name/role/area/color/active, nút "+ Thêm user" prompt PIN+name, sync tự động Supabase.
  - **Dự án:** form edit name/description/start_at/end_at với nút Lưu.
  - **Giới thiệu:** version, link repo, link Supabase.
- **Activity log + comment** trong Task Detail Modal:
  - Auto-log khi tạo task (`created`), đổi status (`status_change` với from/to), đổi assignee (`assigned`), sửa title/description (`edited`).
  - Section "Lịch sử & bình luận" hiển thị timeline activities theo thứ tự thời gian, avatar + tên user + relative time (vừa xong / X phút trước / X giờ trước).
  - Comment input textarea, Ctrl+Enter để gửi nhanh.
- Badge mới cho status (`backlog`/`todo`/`doing`/`review`/`done`) dùng trong Goals view.
- Helper `fmtRelative()` cho timestamp trong activity log.

### Changed
- Bump `VERSION` 0.5.0 → 1.0.0.
- 5 tables sync (thêm `activities`).
- `useStateSync` return shape: `[data, setData, { loading, error, applyRemote }]` (thêm `applyRemote`).
- `TaskDetailModal` nhận thêm props `activities` + `onComment`. `onSave(next, original)` truyền cả original để diff log activity.

### Migration
- Không cần migration DB — schema Phase 0 đã có sẵn `activities` + realtime publication cho 4 bảng.

---

## [0.5.0] — 2026-05-13

### Added
- Wire Supabase: paste credentials thật vào `index.html` (URL + publishable key).
- 5 cặp mapper `fromDb` / `toDb` cho `users`, `projects`, `goals`, `tasks`, `activities` (DB snake_case ↔ JS camelCase).
- Custom hook `useStateSync(table, fromDb, toDb)` — diff-wrapper auto-sync theo PLAYBOOK 5.2. Trả về `[data, setData, { loading, error }]`. Setter tự diff prev/next rồi gọi `sb.from(table).upsert/delete()` từng row đã đổi. Component dùng như `setState` bình thường, không biết đến DB.
- Login PIN fetch users thật từ Supabase, không còn mock. Loading spinner trong khi fetch. Error banner + nút "Thử lại" nếu fetch fail (chưa chạy schema / sai key / mất mạng).
- Auto-login từ `localStorage` chạy sau khi users load xong.
- **Task Detail Modal:** inline-edit title + dropdown status/priority/area/assignee/goal + date picker start_at/due_at + textarea description. Tự set `done_at` khi chuyển status sang `done`, clear khi out khỏi `done`. Nút Xoá hiện cho `lead_pm` hoặc người tạo.
- **Quick Create Modal** (+ Task button trên TopBar và nút + trong Kanban column): tạo task mới với title/status/priority/area/assignee/due/goal. Mặc định area = mảng của user, assignee = chính user.
- Dashboard, Kanban, My Tasks render từ data Supabase. Click bất kỳ task nào → mở Task Detail Modal.
- 3 states đầy đủ: Loading (spinner) / Empty (placeholder + CTA) / Error (banner + retry).
- Connection indicator: 🟢 Live khi Supabase wired, 🟤 Local khi không có credentials.

### Changed
- Bump `VERSION` 0.1.0 → 0.5.0.
- Xoá mock data hardcoded; mọi state đến từ Supabase qua `useStateSync`.

### Migration
- Trước khi chạy: vào Supabase SQL Editor → paste `supabase-schema.sql` → Run (idempotent, chạy lại không reset data).
- Nếu fork repo này, thay `SUPABASE_URL` + `SUPABASE_KEY` trong `index.html`.

### Known limitations (sẽ fix ở Phase 2)
- Chưa có realtime — phải F5 để thấy update của user khác.
- Activity log + comment chưa làm.
- Timeline / Goals / Settings vẫn placeholder.

---

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
