Tạo release mới cho LeadHub:

1. Hỏi user: bump loại nào (patch / minor / major)? Mô tả ngắn cho release?
2. Update `const VERSION` trong `index.html`.
3. Thêm entry vào `CHANGELOG.md` đầu file theo format:
   ```
   ## [X.Y.Z] — YYYY-MM-DD
   ### Added / Changed / Fixed / Removed
   - ...
   ```
4. `git add . && git commit -m "vX.Y.Z: <description>"`
5. `git tag -a vX.Y.Z -m "Release vX.Y.Z"`
6. `git push && git push origin vX.Y.Z` (nếu đã có remote)

Quy tắc SemVer:
- PATCH: chỉ fix bug, không thêm tính năng.
- MINOR: thêm tính năng tương thích ngược.
- MAJOR: breaking change, refactor lớn.
