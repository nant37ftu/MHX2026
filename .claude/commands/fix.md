Sửa bug: $ARGUMENTS

1. Grep tìm function / component / từ khoá liên quan trong `index.html`.
2. Read đúng đoạn code đó (đừng đọc cả file).
3. Đề xuất fix → đợi user confirm trước khi apply.
4. Apply fix.
5. Test nhanh: mở `index.html` trong browser, xác nhận hết lỗi, không có console error.
6. Commit với prefix `fix:` — ví dụ `fix: pinpad không reset khi đăng xuất`.

Nếu bug do schema DB → cập nhật `supabase-schema.sql` idempotent + ghi chú migration trong CHANGELOG.
