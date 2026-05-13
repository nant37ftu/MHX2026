# 📘 PLAYBOOK — Patterns & Logic cho Internal Web App

> Tổng hợp các pattern, quyết định kiến trúc, và best-practice rút ra từ project **CLB Quản Lý Bán Hàng** — dùng để tái áp dụng cho các platform nội bộ tiếp theo.

**Đối tượng:** Internal tool / SaaS nhẹ / dashboard quản trị / app cho team nhỏ-vừa (5–50 users).
**Tech foundation:** Single-file React + Supabase + GitHub Pages.

---

## 📑 Mục lục

1. [Khi nào dùng tech stack này](#1-khi-nào-dùng-tech-stack-này)
2. [Quyết định kiến trúc + trade-offs](#2-quyết-định-kiến-trúc--trade-offs)
3. [Cấu trúc thư mục chuẩn](#3-cấu-trúc-thư-mục-chuẩn)
4. [Database patterns](#4-database-patterns)
5. [State management patterns](#5-state-management-patterns)
6. [Realtime sync patterns](#6-realtime-sync-patterns)
7. [Auth & Role-based access](#7-auth--role-based-access)
8. [UI/UX patterns](#8-uiux-patterns)
9. [Responsive design](#9-responsive-design)
10. [Versioning workflow](#10-versioning-workflow)
11. [Làm việc với Claude Code (token-saving)](#11-làm-việc-với-claude-code-token-saving)
12. [Feature evolution roadmap](#12-feature-evolution-roadmap)
13. [Anti-patterns cần tránh](#13-anti-patterns-cần-tránh)
14. [Code snippets tái sử dụng](#14-code-snippets-tái-sử-dụng)

---

## 1. Khi nào dùng tech stack này

### ✅ Phù hợp khi
- **Internal tool** cho team / CLB / công ty (5–50 active users)
- **MVP / Prototype** cần demo nhanh
- Cần **realtime sync** (KDS, kanban, dashboard live)
- Solo dev hoặc 1–3 dev
- Budget = $0 → hosting free, DB free tier
- Auth không phức tạp (PIN, role-based, không cần MFA)
- Mobile = responsive web đủ (không cần native app)

### ❌ Không phù hợp khi
- Public site cần SEO (cần SSR — dùng Next.js + Vercel)
- Traffic >100K MAU (vượt free tier)
- Compliance nặng (banking, healthcare, HIPAA)
- Cần offline-first (cần Service Worker phức tạp)
- Team >10 dev (single-file là bottleneck)

---

## 2. Quyết định kiến trúc + trade-offs

### Frontend hosting

| Lựa chọn | Pro | Con | Khi nào dùng |
|---|---|---|---|
| **GitHub Pages** ⭐ | Free, push = deploy, custom domain | Chỉ static, không SSR | Internal tool, demo, MVP |
| Vercel | Next.js native, edge functions | Tier free giới hạn hơn | Cần SSR / API routes |
| Netlify | Form handling, plugins phong phú | UI hơi rối | Site marketing |
| Cloudflare Pages | CDN tốt nhất | Build pipeline limit | Site traffic cao |

### Backend / Database

| Lựa chọn | Pro | Con | Khi nào dùng |
|---|---|---|---|
| **Supabase** ⭐ | Postgres + Realtime + Auth + RLS, free tier rộng | Auto-pause sau 7 ngày | App internal cần realtime |
| Firebase | Mobile SDK tốt, push thật, scaling tốt | NoSQL hạn chế, vendor lock-in | App di động, chat |
| PocketBase | Self-host, single binary, file storage | Bạn tự host = bạn tự lo | Self-hosted, có server riêng |
| Neon + Vercel | Postgres serverless, branching | Setup phức tạp hơn | Production grade, có CI/CD |

### Frontend framework

| Lựa chọn | Pro | Con |
|---|---|---|
| **React via CDN (no build)** ⭐ | Zero setup, deploy thẳng | Hơi chậm load lần đầu vì Babel transpile client-side |
| Next.js | SSR, routing, API routes | Cần build pipeline, deploy phức tạp hơn |
| Vue/Svelte | DX tốt, bundle nhỏ | Ít ví dụ hơn cho beginner |
| Vanilla JS | Cực nhanh, zero deps | Phải tự viết nhiều |

### Auth

| Lựa chọn | Pro | Con | Khi nào |
|---|---|---|---|
| **PIN code custom** ⭐ | Đơn giản, không cần email/SMS | Không secure cho public app | Internal tool, kiosk |
| Supabase Auth (email + password) | Built-in, bảo mật chuẩn | Khách phải nhớ password | App public, B2C |
| OAuth (Google/GitHub) | Khách không phải nhớ pwd | Phụ thuộc provider | App có user dev/professional |
| Magic link email | Không password | Phải có email service | App truyền thông, blog |
| SMS OTP | Khách thường có số điện thoại | Tốn phí SMS | App thị trường VN |

### File structure

| Lựa chọn | Pro | Con |
|---|---|---|
| **Single file (`index.html`)** ⭐ | No build, dễ deploy, easy grok | Khó scale >3000 dòng |
| Multi-file ES modules (no bundler) | Chia logic được | Phụ thuộc module CDN |
| Vite + React | DX hiện đại, HMR | Cần Node.js + build step |

---

## 3. Cấu trúc thư mục chuẩn

Đối với single-file React app:

```
my-app/
├── index.html                 # Toàn bộ app (HTML + CSS + React JSX qua Babel)
├── supabase-schema.sql        # DB schema, idempotent, có seed data
├── README.md                  # User-facing: install, deploy, tính năng
├── CLAUDE.md                  # AI memory: context, conventions cho Claude Code
├── PLAYBOOK.md                # (File này) — Patterns tổng quát
├── CHANGELOG.md               # Lịch sử version theo SemVer
├── LICENSE                    # MIT phổ biến
├── .gitignore                 # node_modules, .DS_Store, .env
├── .nojekyll                  # bắt buộc nếu deploy GitHub Pages
└── .claude/
    └── commands/              # Slash commands tuỳ chỉnh (optional)
        ├── release.md
        └── fix.md
```

Lý do giữ **TỐI THIỂU**: mỗi file = thêm chi phí maintain, đồng bộ, review.

---

## 4. Database patterns

### 4.1 Schema idempotent (run-rerun safe)

```sql
CREATE TABLE IF NOT EXISTS products ( ... );

-- Seed chỉ khi rỗng
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM products) THEN
    INSERT INTO products ... VALUES ...;
  END IF;
END $$;

-- ALTER PUBLICATION với guard
DO $$ BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE products;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
```

→ User có thể chạy lại bao nhiêu lần cũng được, không lỗi.

### 4.2 RLS open access cho internal app

```sql
ALTER TABLE my_table ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "open_all" ON my_table;
CREATE POLICY "open_all" ON my_table
  FOR ALL TO anon, authenticated
  USING (true) WITH CHECK (true);
```

Bảo mật qua **không công khai URL/key**, không qua RLS phức tạp. Khi cần chặt hơn → policy theo `auth.uid()`.

### 4.3 Quy tắc đặt tên cột

- Snake_case trong DB (`order_id`, `created_at`)
- camelCase trong JS (`orderId`, `createdAt`)
- Có mapper `fromDb` / `toDb` ở client để chuyển đổi

```js
const orderFromDb = r => ({ id:r.id, createdAt:r.created_at, ... });
const orderToDb   = o => ({ id:o.id, created_at:o.createdAt, ... });
```

### 4.4 Tránh cột reserved name

Tránh: `by`, `end`, `on`, `order`, `user`, `group`, `default`, `select`.
Đổi tên thành: `by_id`, `end_at`, `on_menu`, `is_default`...

### 4.5 JSONB cho fields phức tạp

```sql
recipe  JSONB NOT NULL DEFAULT '{"ing":[],"steps":[]}'::jsonb,
items   JSONB NOT NULL DEFAULT '[]'::jsonb
```

Dùng khi:
- Cấu trúc thay đổi linh hoạt (recipe, settings, metadata)
- Truy vấn thường lấy cả object
- Không cần JOIN/filter nội bộ field

Không dùng JSONB khi cần query/sort/filter theo từng field bên trong → tách bảng riêng.

### 4.6 Realtime publication

```sql
ALTER PUBLICATION supabase_realtime ADD TABLE my_table;
```

**Chỉ enable cho bảng cần realtime** — mỗi bảng = thêm load WebSocket + message quota.

Quy tắc: bật cho `orders`, `state`, các bảng thay đổi liên tục. Tắt cho `categories`, `config`, các bảng ít đổi.

---

## 5. State management patterns

### 5.1 App root giữ TẤT CẢ state, truyền xuống qua props

Tránh Context cho data, chỉ dùng cho theme/locale/toast.

```jsx
function App() {
  const [orders, setOrders] = useState([]);
  const [products, setProducts] = useState([]);
  // ...
  return <Layout>
    <OrderScreen orders={orders} setOrders={setOrders} ... />
  </Layout>;
}
```

Lợi: dễ debug, dễ trace data flow, không có "magic context".

### 5.2 Diff-wrapper auto-sync DB

Pattern then chốt cho cloud-sync state:

```js
const ref = useRef([]);
const setX = useCallback(updater => {
  const prev = ref.current;
  const next = typeof updater === 'function' ? updater(prev) : updater;
  ref.current = next;
  _setX(next);
  // Diff prev vs next → INSERT/UPDATE/DELETE từng row đã đổi
  syncToDb(prev, next, 'table', 'id', mapToDb);
}, []);
```

Component dùng `setX` như `setState` bình thường, không biết đến DB.

### 5.3 Optimistic UI

UI cập nhật ngay (local state), DB sync async. Nếu DB lỗi → toast + (optional) rollback.

```js
const cancel = id => {
  setOrders(os => os.map(o => o.id === id ? {...o, st: 'cancelled'} : o));
  toast('Đã huỷ', 'success');
  // syncToDb tự gọi từ wrapper
};
```

Trừ khi cần độ chính xác tuyệt đối (banking), optimistic = UX tốt hơn nhiều.

### 5.4 Refs để side effect access latest state

```js
const effectiveRoleRef = useRef('off');
useEffect(() => { effectiveRoleRef.current = effectiveRole; }, [effectiveRole]);

// Trong realtime callback (không re-render khi role đổi):
if (effectiveRoleRef.current === 'kitchen') notify(...);
```

---

## 6. Realtime sync patterns

### 6.1 Channel + multiple table subscriptions

```js
const ch = sb.channel('main')
  .on('postgres_changes', {event:'*', schema:'public', table:'orders'}, payload => {
    handleOrder(payload);
  })
  .on('postgres_changes', {event:'*', schema:'public', table:'products'}, payload => {
    handleProduct(payload);
  })
  .subscribe(status => setConnStatus(status === 'SUBSCRIBED' ? 'live' : 'offline'));

return () => sb.removeChannel(ch);
```

### 6.2 Handle 3 events: INSERT / UPDATE / DELETE

```js
const handle = payload => {
  if (payload.eventType === 'DELETE') {
    _setItems(arr => arr.filter(x => x.id !== payload.old.id));
  } else {
    const incoming = mapFromDb(payload.new);
    _setItems(arr => {
      const existing = arr.find(x => x.id === incoming.id);
      // Dedupe: nếu giống hệt local thì bỏ qua (tránh re-render)
      if (existing && JSON.stringify(existing) === JSON.stringify(incoming)) return arr;
      return existing
        ? arr.map(x => x.id === incoming.id ? incoming : x)
        : [...arr, incoming];
    });
  }
};
```

### 6.3 Indicator kết nối

UX vàng/đỏ/xanh để user biết realtime hoạt động:
- 🟢 Live (subscribed)
- 🟡 Connecting (chờ subscribe)
- 🔴 Offline (channel error / closed)

### 6.4 Push notifications từ realtime

```js
.on('postgres_changes', {event:'INSERT', table:'orders'}, payload => {
  if (notifEnabledRef.current && roleRef.current === 'kitchen') {
    new Notification('Đơn mới', { body: `${payload.new.customer}`, icon: '🛒' });
  }
});
```

Hạn chế:
- Browser Notification API chỉ work khi tab đang mở
- Cần `Notification.requestPermission()` lần đầu
- Để push thật (background) cần Service Worker + Web Push protocol

---

## 7. Auth & Role-based access

### 7.1 PIN login (cho internal app)

```jsx
function LoginScreen({ users, onLogin }) {
  const [pin, setPin] = useState('');
  const tryLogin = (val) => {
    const u = users.find(x => x.pin === val && x.active);
    if (u) { localStorage.setItem('user_pin', val); onLogin(u); }
    else showError('PIN sai');
  };
  // ... numpad UI, auto-submit khi đủ 4 số
}
```

Logout = xoá localStorage + reset state.

### 7.2 Auto-login từ localStorage

```js
useEffect(() => {
  const savedPin = localStorage.getItem('user_pin');
  if (savedPin) {
    const u = staff.find(s => s.pin === savedPin && s.active);
    if (u) setCurrentUser(u);
    else localStorage.removeItem('user_pin'); // PIN expired
  }
}, [staff]);
```

### 7.3 Role-based screen filtering

```js
const ROLE_PERMS = {
  admin:    ['dashboard','users','settings','reports'],
  manager:  ['dashboard','reports'],
  worker:   ['dashboard'],
};

const allowed = ROLE_PERMS[currentUser.role] || [];
const sidebarNav = ALL_NAV.filter(item => allowed.includes(item.key));
const activeScreen = allowed.includes(screen) ? screen : allowed[0];
```

### 7.4 Role thay đổi theo lịch (advanced)

Khi role phụ thuộc context (giờ trong ngày, ca làm, ngày trong tuần):

```js
const getCurrentShift = (shifts) => {
  const now = Date.now();
  const m = new Date().getHours() * 60 + new Date().getMinutes();
  return shifts.find(s => {
    const start = toMinutes(s.start_at);
    const end = toMinutes(s.end_at);
    return end > start ? (m >= start && m < end) : (m >= start || m < end);
  });
};

const getEffectiveRole = (currentShift, assignments, user) => {
  if (!currentShift) return user.defaultRole;
  const a = assignments.find(x => x.shift_id === currentShift.id && x.user_id === user.id);
  return a ? a.role : 'off';
};
```

Re-render mỗi 60s để UI cập nhật khi ca chuyển:
```js
useEffect(() => {
  const t = setInterval(() => setTick(x => x + 1), 60000);
  return () => clearInterval(t);
}, []);
```

---

## 8. UI/UX patterns

### 8.1 Three states cho mọi data view

Mỗi screen render data phải handle:
1. **Loading** — skeleton hoặc spinner
2. **Empty** — message + CTA ("Chưa có đơn nào — Tạo đơn đầu tiên")
3. **Error** — message + retry button

### 8.2 Toast system

Non-blocking notification, auto-dismiss sau 3-4s:

```jsx
function App() {
  const [toasts, setToasts] = useState([]);
  const toast = (msg, type='info') => {
    const id = Date.now() + Math.random();
    setToasts(t => [...t, {id, msg, type}]);
    setTimeout(() => setToasts(t => t.filter(x => x.id !== id)), 3500);
  };
  return <>...<Toast list={toasts}/></>;
}
```

Types: `success | warn | error | info` với màu tương ứng.

### 8.3 Color tokens trong CSS variables

```css
:root {
  --primary:    #EE4D2D;
  --primary-bg: #FFF4F0;
  --bg:         #F5F5F5;
  --border:     #E8E8E8;
  --text:       #212121;
  --muted:      #767676;
}
```

Tất cả màu reference qua var → đổi theme 1 dòng.

### 8.4 Role-color mapping

```js
const ROLE_COLORS = {
  admin:   ['#7C3AED', '#F5F3FF'],  // [text, bg]
  manager: ['#1D4ED8', '#EFF6FF'],
  worker:  ['#16A34A', '#F0FDF4'],
};
```

Dùng đồng nhất khắp app (badge, avatar, indicator).

### 8.5 Avatar = initials fallback

```js
const initials = name => name.split(' ').map(w => w[0]).slice(-2).join('');
```

Lấy 2 chữ cái cuối của tên. Đẹp, đơn giản, không cần upload ảnh.

### 8.6 Inline edit (click-to-edit)

```jsx
{editing === item.id
  ? <input value={val} onBlur={save} autoFocus />
  : <button onClick={() => startEdit(item.id, item.value)}>{item.value}</button>
}
```

UX nhanh hơn modal edit, hợp cho bảng config (giá, tên, label).

### 8.7 Quantity stepper

```jsx
<div style={{display:'flex'}}>
  <button onClick={dec} disabled={val<=min}>−</button>
  <span>{val}</span>
  <button onClick={inc} disabled={val>=max}>+</button>
</div>
```

### 8.8 Floating help button

Nút tròn fixed bottom-right, mở modal hướng dẫn 4 tab:
- Tổng quan
- Vai trò
- Quy trình
- Tài khoản

Dễ access mà không chiếm không gian.

### 8.9 Sticky footer button (fix mobile keyboard)

Khi có form dài với button "Submit" ở dưới:

```jsx
<div style={{display:'flex', flexDirection:'column', height:'100%'}}>
  <div style={{flex:1, overflow:'auto'}}>{form content}</div>
  <div style={{flexShrink:0, borderTop:'1px solid #eee', padding:12}}>
    <button>Submit</button>
  </div>
</div>
```

Footer LUÔN visible, content scroll trong.

### 8.10 Tab-based settings

Khi có nhiều nhóm config, dùng tabs ngang trên thay vì sidebar dọc:

```jsx
{tabs.map(t => (
  <button onClick={() => setTab(t.k)}
    style={{borderBottom: tab === t.k ? '2.5px solid var(--primary)' : 'none'}}>
    {t.label}
  </button>
))}
{tab === 'staff' && <StaffSettings ... />}
{tab === 'products' && <ProductSettings ... />}
```

---

## 9. Responsive design

### 9.1 3 breakpoints chính

```css
/* Desktop: ≥ 1024px — default */
/* Tablet:  768-1023px */
@media (max-width: 1023px) { ... }
/* Mobile:  < 768px */
@media (max-width: 768px) { ... }
/* Small mobile: < 480px */
@media (max-width: 480px) { ... }
```

### 9.2 Sidebar → mobile drawer

```css
.sidebar { width: 220px; }
@media (max-width: 768px) {
  .sidebar {
    position: fixed; left:0; top:0; bottom:0;
    transform: translateX(-100%);
    transition: transform .25s;
  }
  .sidebar.open { transform: translateX(0); }
  .sb-overlay { /* dark overlay khi drawer mở */ }
}
```

TopBar có hamburger button trên mobile, set `setOpen(true)` để slide.

### 9.3 Stack panels trên mobile

Layout 2 panels ngang trên desktop → stack dọc trên mobile:

```css
.split-shell { display: flex; }
@media (max-width: 768px) {
  .split-shell { flex-direction: column; }
  .panel-right { width: 100%; max-height: 46vh; }
}
```

### 9.4 Hide non-essential elements

```css
@media (max-width: 768px) {
  .hide-mobile { display: none !important; }
  .topbar-meta { display: none; }
}
```

Trên mobile: bỏ time, status text dài, breadcrumb.

### 9.5 Touch target ≥ 44px

Buttons trên mobile phải đủ to để chạm. Đặt `min-height: 44px` cho các button quan trọng.

---

## 10. Versioning workflow

### 10.1 SemVer (Semantic Versioning)

- **MAJOR** (1.x.x): breaking change, refactor lớn
- **MINOR** (x.1.x): thêm tính năng tương thích
- **PATCH** (x.x.1): chỉ fix bug

### 10.2 Constants trong code

```js
const VERSION = "1.1.0";
```

Hiển thị ở Sidebar + Login screen để user biết.

### 10.3 CHANGELOG.md format

Theo [Keep a Changelog](https://keepachangelog.com):

```markdown
## [1.1.0] — YYYY-MM-DD
### Added
- Tính năng mới
### Changed
- Thay đổi behavior
### Fixed
- Bug được sửa
### Removed
- Tính năng bị bỏ
### Migration cần làm (nếu có)
- Chạy lại supabase-schema.sql
```

### 10.4 Git tag mỗi release

```bash
git commit -m "v1.1.0: short description"
git tag -a v1.1.0 -m "Release v1.1.0"
git push && git push origin v1.1.0
```

→ GitHub tự tạo Releases page, dễ rollback.

---

## 11. Làm việc với Claude Code (token-saving)

### 11.1 CLAUDE.md là project memory

File `CLAUDE.md` ở root, Claude tự đọc đầu mỗi session. Nội dung:
- Project overview (tech stack, mục đích)
- File structure
- Database schema tóm tắt
- Conventions quan trọng
- Workflow chuẩn (release, fix bug)
- Pitfalls đã gặp

→ Không phải giới thiệu lại project mỗi session.

### 11.2 Prompt cụ thể, không mơ hồ

✅ Tốt:
> "Sửa file index.html, function `createOrder` (khoảng dòng 700), thêm validation: nếu cart.items.length === 0 thì hiện toast 'Giỏ trống' thay vì alert."

❌ Tệ:
> "Làm app tốt hơn"

### 11.3 Workflow chuẩn cho từng loại task

| Loại | Workflow |
|---|---|
| Bug nhỏ | Tả triệu chứng + file → Claude grep → đề xuất fix → apply |
| Feature mới | Tả requirement → Plan mode (Shift+Tab) → review plan → implement → commit |
| Refactor | Subagent Explore phân tích → review → quyết → implement |
| Câu hỏi codebase | Subagent Explore (không tốn main context) |

### 11.4 /clear thường xuyên

- Mỗi task lớn xong → `/clear` rồi prompt task mới
- Conversation >50 turns → `/clear` (Claude vẫn nhớ qua CLAUDE.md)

### 11.5 Commit = checkpoint context

Mỗi feature xong → commit ngay với message rõ ràng. Future session có thể `git log` để biết.

### 11.6 Slash commands tuỳ chỉnh

Trong `.claude/commands/`:

**`release.md`:**
```markdown
Tạo release version mới:
1. Hỏi bump loại nào (patch/minor/major) + mô tả
2. Update VERSION trong code
3. Thêm entry CHANGELOG.md
4. Commit, tag, push
```

**`fix.md`:**
```markdown
Sửa bug: $ARGUMENTS
1. Grep tìm file/function
2. Read đúng phần cần sửa
3. Đề xuất fix → confirm
4. Apply + commit với prefix "fix:"
```

Gọi: `/release minor "thêm dark mode"` hay `/fix login crash`.

### 11.7 Subagent cho deep work

```
> Dùng subagent general-purpose phân tích kiến trúc realtime sync, viết tóm tắt < 300 từ.
```

Subagent có context riêng, kết quả trả về cô đọng.

---

## 12. Feature evolution roadmap

Pattern phát triển từng tiered, KHÔNG build mọi thứ cùng lúc:

### Phase 0: MVP demo (1-3 ngày)
- Single HTML file
- Mock data (no DB)
- 1-2 màn hình core
- Mục tiêu: validate UI/UX với user

### Phase 1: Functional alpha (3-7 ngày)
- Thêm DB (Supabase)
- Persist data
- Tất cả CRUD basic
- Mục tiêu: dùng thật được

### Phase 2: Multi-user (1-2 tuần)
- Auth (PIN/OAuth)
- Realtime sync
- Role-based access
- Mục tiêu: nhiều người dùng chung

### Phase 3: Polish (1 tuần)
- Responsive mobile
- Error states, empty states
- Notification, toast
- CHANGELOG + version
- Mục tiêu: bản chính thức v1.0

### Phase 4: Scale (theo nhu cầu)
- Admin tools (settings, schedule, permissions)
- Analytics / Reports
- Push notifications thật (service worker)
- API public (nếu cần)

### Phase 5: Migrate (khi đụng trần)
- Free tier hết → Pro hoặc self-host
- Single-file → multi-file (Vite, Next.js)
- localStorage → cookie/session
- v2.0 — breaking changes OK

→ Quy tắc: **mỗi version chỉ 1-3 tính năng focused**, không nhồi nhét.

---

## 13. Anti-patterns cần tránh

### 13.1 Đừng tạo file mới vô tội vạ
Single file dễ grok hơn 20 files. Chỉ tách khi >3000 dòng và team >2 dev.

### 13.2 Đừng dùng Context cho data
Context cho theme/locale OK. Cho data → props vì:
- Dễ debug
- Không có magic re-render
- Trace flow rõ ràng

### 13.3 Đừng dùng Redux/Zustand cho app <10K dòng
useState + useReducer + props là đủ. Thêm state lib = thêm boilerplate.

### 13.4 Đừng thêm build tool sớm
CDN React + Babel chạy được — dùng. Khi nào load lần đầu chậm hơn 3s mới migrate Vite.

### 13.5 Đừng over-engineer auth
PIN 4 số đủ cho internal tool. Đừng nhồi MFA + SSO + LDAP từ đầu.

### 13.6 Đừng load full table mỗi lần
Khi orders > 10K rows: query với LIMIT + filter date. Hoặc archive tháng cũ sang bảng `orders_archive`.

### 13.7 Đừng commit `.env` hoặc service_role key
Anon key của Supabase OK (public by design). Service_role key = god mode, KHÔNG BAO GIỜ commit.

### 13.8 Đừng skip CHANGELOG
3 tháng sau bạn quên mình đã làm gì. Viết CHANGELOG là favor tặng future-self.

### 13.9 Đừng đặt user-facing string trong code logic
Tách `const MESSAGES = { ORDER_CREATED: '...', ORDER_CANCELLED: '...' }` để dễ đa ngôn ngữ sau.

### 13.10 Đừng quên responsive từ đầu
Mobile sau cùng = phải refactor layout cả app. Bắt đầu với flex-column-default-row-when-wide.

---

## 14. Code snippets tái sử dụng

### 14.1 Supabase client init

```js
const sb = window.supabase.createClient(SUPABASE_URL, SUPABASE_KEY, {
  realtime: { params: { eventsPerSecond: 10 } }
});
```

### 14.2 Toast helper

```js
const useToast = () => {
  const [toasts, setToasts] = useState([]);
  const toast = useCallback((msg, type='info') => {
    const id = Date.now() + Math.random();
    setToasts(t => [...t, {id, msg, type}]);
    setTimeout(() => setToasts(t => t.filter(x => x.id !== id)), 3500);
  }, []);
  return { toasts, toast, dismiss: id => setToasts(t => t.filter(x => x.id !== id)) };
};
```

### 14.3 PIN keypad

```jsx
function PinPad({ length = 4, onComplete }) {
  const [pin, setPin] = useState('');
  const press = n => {
    if (pin.length >= length) return;
    const next = pin + n;
    setPin(next);
    if (next.length === length) setTimeout(() => onComplete(next), 100);
  };
  return (
    <>
      <div className="dots">{Array.from({length}).map((_,i) => <span className={pin.length>i?'filled':''}/>)}</div>
      <div className="grid">
        {[1,2,3,4,5,6,7,8,9].map(n => <button onClick={()=>press(n)}>{n}</button>)}
        <button onClick={()=>setPin('')}>Clear</button>
        <button onClick={()=>press('0')}>0</button>
        <button onClick={()=>setPin(p=>p.slice(0,-1))}>⌫</button>
      </div>
    </>
  );
}
```

### 14.4 Format VND

```js
const fmt = n => (n||0).toLocaleString('vi-VN') + 'đ';
```

### 14.5 Time helpers

```js
const nowHM = () => {
  const d = new Date();
  return `${String(d.getHours()).padStart(2,'0')}:${String(d.getMinutes()).padStart(2,'0')}`;
};
const hmToMin = s => { const [h,m] = s.split(':').map(Number); return h*60+(m||0); };
```

### 14.6 Idempotent SQL pattern

```sql
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM my_table WHERE key = 'singleton') THEN
    INSERT INTO my_table (key, value) VALUES ('singleton', 'default');
  END IF;
END $$;
```

### 14.7 CSV export với BOM UTF-8

```js
const exportCSV = (rows, filename) => {
  const csv = '﻿' + rows.map(r => r.map(c => `"${c}"`).join(',')).join('\n');
  const blob = new Blob([csv], { type: 'text/csv;charset=utf-8' });
  const a = Object.assign(document.createElement('a'), {
    href: URL.createObjectURL(blob),
    download: filename + '.csv'
  });
  a.click();
  URL.revokeObjectURL(a.href);
};
```

### 14.8 Responsive sidebar CSS

```css
.sidebar { width: 220px; transition: transform .25s; }
.app-main { flex: 1; min-width: 0; }

@media (max-width: 768px) {
  .sidebar {
    position: fixed; left:0; top:0; bottom:0; z-index:200;
    transform: translateX(-100%);
    box-shadow: 2px 0 16px rgba(0,0,0,.15);
  }
  .sidebar.open { transform: translateX(0); }
  .sb-overlay {
    position: fixed; inset: 0;
    background: rgba(0,0,0,.4); z-index: 150;
  }
  .desktop-only { display: none !important; }
}
```

---

## 🎯 TL;DR — checklist khi start project mới

- [ ] Tạo folder + `index.html` từ template (copy từ project này)
- [ ] Tạo Supabase project free → lấy URL + anon key
- [ ] Viết `supabase-schema.sql` idempotent, ENABLE RLS với policy open_all
- [ ] Thêm `categories` table cho mọi enum admin có thể đổi
- [ ] Thiết lập `VERSION = "0.1.0"` (alpha), CHANGELOG, CLAUDE.md ngay từ đầu
- [ ] Auth = PIN nếu internal, OAuth nếu public
- [ ] Color tokens trong `:root`
- [ ] Sidebar + TopBar layout chuẩn
- [ ] Toast system + Loading/Empty/Error states
- [ ] Realtime cho bảng `orders`/`events` chính
- [ ] Responsive 3 breakpoints
- [ ] Setup `.nojekyll` + push GitHub Pages → đã live trong 1 ngày
- [ ] Mỗi feature → 1 commit + tag + entry CHANGELOG
- [ ] Slash commands `/release`, `/fix` trong `.claude/commands/`

---

## 📚 Tham khảo mở rộng

- [Supabase docs](https://supabase.com/docs)
- [Keep a Changelog](https://keepachangelog.com/)
- [Semantic Versioning](https://semver.org/)
- [Claude Code docs](https://docs.claude.com/claude-code/)
- [Tabler Icons](https://tabler.io/icons) — bộ icon dùng trong project
- React via CDN: https://unpkg.com/react@18/umd/react.production.min.js

---

*Playbook này tổng hợp từ project CLB Quản Lý Bán Hàng (v1.1.0).*  
*Cập nhật lần cuối: 2026-05-11.*
*Author: Lê Văn Trí — Learn to Leap.*
