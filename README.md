# LeadHub

Internal platform quản trị công việc cho team core 4 leaders/sub-leaders. Realtime, online song song, không cần cài app.

## Live
Sau khi deploy GitHub Pages, paste link vào đây: `https://<user>.github.io/leadhub/`

## Tech
React 18 (CDN) + Supabase + GitHub Pages. Single-file `index.html`. No build step.

## Cài đặt cho team mới

1. **Fork repo này** (hoặc clone về local).
2. **Tạo Supabase project free** tại [supabase.com](https://supabase.com) → lấy `Project URL` + `anon public key` (Settings → API).
3. **Vào Supabase SQL Editor** → paste toàn bộ `supabase-schema.sql` → Run. Schema idempotent — chạy lại bao nhiêu lần cũng không reset data.
4. **Mở `index.html`**, tìm 2 dòng:
   ```js
   const SUPABASE_URL = "YOUR_SUPABASE_URL_HERE";
   const SUPABASE_KEY = "YOUR_SUPABASE_ANON_KEY_HERE";
   ```
   Thay bằng URL + anon key của bạn.
5. **Push lên GitHub**, bật GitHub Pages (Settings → Pages → main branch → root). Đảm bảo có `.nojekyll` ở root.
6. **Login PIN mặc định:** `1001` (Leader A).

## Đăng nhập demo

| Tên | PIN | Role |
|---|---|---|
| Leader A | 1001 | lead_pm (super-user) |
| Leader B | 1002 | lead_tech |
| Sub-leader C | 1003 | sub_content |
| Sub-leader D | 1004 | sub_ops |

→ Sau khi setup, đổi tên/PIN qua màn **Settings → Users** (chỉ `lead_pm` thấy).

## Tính năng

- **Dashboard** — stat cards + tiến độ goals + task sắp đến deadline.
- **Kanban 5 cột** — Backlog / Todo / Doing / Review / Done. Realtime sync giữa các tab.
- **Timeline (Gantt-lite)** — task hiển thị theo `start_at → due_at`, group theo mảng hoặc assignee.
- **Goals & Milestones** — gắn task vào mục tiêu lớn, % progress tự tính.
- **My Tasks** — tab cá nhân, chỉ task được assign cho mình.
- **Activity log + comment** trong từng task.
- **4 role với permission matrix** — `lead_pm` super-user, các role khác CRUD trong mảng mình + xem cross-mảng.
- **Connection indicator** 🟢🟡🔴.

## Bảo mật

Đây là **internal tool**. Bảo mật qua:
- Không công khai URL/anon key trên public site/forum.
- Anon key OK để commit (anon key được Supabase thiết kế public).
- KHÔNG BAO GIỜ commit `service_role` key — đó là god mode.
- RLS dùng policy `open_all` (đơn giản, đủ cho internal). Cần chặt hơn → đổi policy theo `auth.uid()`.

## Versioning

SemVer. Lịch sử trong [CHANGELOG.md](CHANGELOG.md). Mỗi release đi kèm git tag (`v0.1.0`, `v1.0.0`...).

## License

MIT — xem [LICENSE](LICENSE).

---

Tham khảo pattern: [PLAYBOOK.md](PLAYBOOK.md).
AI memory: [CLAUDE.md](CLAUDE.md).
