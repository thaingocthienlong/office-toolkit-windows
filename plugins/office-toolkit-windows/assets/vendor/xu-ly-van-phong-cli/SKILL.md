---
name: xu-ly-van-phong-cli
description: TẠO, SỬA, PHÂN TÍCH VÀ CHUYỂN ĐỔI FILE VĂN PHÒNG (WORD, EXCEL, POWERPOINT) BẰNG OFFICECLI - CÔNG CỤ CLI CHUYÊN DỤNG CHO AI AGENT. Thay thế pipeline Node.js/Python bằng single binary không cần cài Office. Hỗ trợ 2 luồng xuất bản - Chuẩn Hành chính NĐ 30 (đen trắng, nghiêm ngặt) và Chuẩn Thẩm mỹ Hiện đại (Brand Kit linh hoạt). Kích hoạt khi user đề cập 'officecli', 'soạn công văn', 'tạo file word', 'làm slide', 'tạo bảng tính'; yêu cầu 'tạo báo cáo', 'làm đề xuất', 'bóc tách format file này', 'bắt chước format file này', 'chuyển sang word', 'sửa file docx/xlsx/pptx'; nói 'gộp file', 'tách trang', 'format cho đẹp', 'chuyển file md này thành word/excel/slide'; trong tình huống user gửi file Word/Excel/Slide kèm yêu cầu chỉnh sửa, gửi file MD/text thô cần chuyển thành tài liệu chuyên nghiệp, hoặc cần tạo tài liệu từ đầu. KHÔNG dùng cho viết nội dung bài viết, lập trình phần mềm, xử lý PDF scan (dùng boc-tach-pdf), đăng bài mạng xã hội. Dùng cho MỌI nghiệp vụ tạo và xử lý file văn phòng bằng officecli - kể cả khi user chỉ gửi 1 file và nói 'xử lý giúp tôi'.
---

# Xử lý Văn phòng - OfficeCLI Edition

Skill xử lý toàn diện file văn phòng (DOCX, XLSX, PPTX) bằng **OfficeCLI** - CLI chuyên dụng cho AI Agent. Single binary, không cần cài Office, không dependency.

> **Khác biệt với skill `xu-ly-van-phong` gốc:** Skill gốc dùng Python (Extractor) + Node.js (Generator). Skill này thay toàn bộ bằng `officecli` CLI thuần - nhanh hơn, ít lỗi hơn, có preview HTML real-time.

---

## 0. Cài đặt OfficeCLI (chạy một lần)

### Lựa chọn A: Cài đặt trực tuyến (Khuyến nghị)
```powershell
# Windows (PowerShell)
irm https://d.officecli.ai/install.ps1 | iex
```

### Lựa chọn B: Cài đặt ngoại tuyến (Fallback - Đã tích hợp sẵn trong Skill)
Trong trường hợp mạng bị lỗi hoặc không tải được binary từ GitHub:
```powershell
# Chạy script PowerShell sau để copy binary từ thư mục tài nguyên của Skill vào system path:
$dest = "C:\Users\gabeo\.officecli\bin"
New-Item -ItemType Directory -Path $dest -Force | Out-Null
Copy-Item -Path "C:\Users\gabeo\.gemini\config\skills\xu-ly-van-phong-cli\resources\bin\officecli.exe" -Destination "$dest\officecli.exe" -Force
[Environment]::SetEnvironmentVariable("Path", "$dest;" + [Environment]::GetEnvironmentVariable("Path", "User"), "User")
$env:Path = "$dest;$env:Path"
```

Xác nhận: `officecli --version`. Nếu chưa nhận, mở terminal mới hoặc chỉ định đường dẫn trực tiếp: `& "C:\Users\gabeo\.officecli\bin\officecli.exe" --version`.

---

## 1. Nguyên lý Hoạt động

Mọi tài liệu đi qua hệ thống phân tách rõ **Tầng Đọc** và **Tầng Ghi**. Không sửa trực tiếp file xấu - bóc tách Data rồi sinh file mới.

### Chiều Đọc & Bóc tách

| Nghiệp vụ | Lệnh OfficeCLI |
|---|---|
| Xem cấu trúc tài liệu | `officecli view <file> outline` |
| Thống kê (trang, từ, shapes) | `officecli view <file> stats` |
| Trích text thuần | `officecli view <file> text` |
| Phát hiện lỗi format | `officecli view <file> issues` |
| Lấy thuộc tính element | `officecli get <file> <path> --depth N --json` |
| Truy vấn CSS-like | `officecli query <file> '<selector>'` |
| Bóc toàn bộ (round-trip) | `officecli dump <file> [<path>]` → JSON batch |
| Validate schema | `officecli validate <file>` |
| Bóc theme/brand | `officecli get <file> / --json` → đọc theme colors |

### Chiều Ghi & Tái tạo

| Nghiệp vụ | Lệnh OfficeCLI |
|---|---|
| Tạo file trống | `officecli create <file>` |
| Thêm element | `officecli add <file> <parent> --type <type> [--prop ...]` |
| Sửa thuộc tính | `officecli set <file> <path> --prop key=value` |
| Tìm & thay text | `officecli set <file> / --find X --replace Y` |
| Di chuyển/hoán đổi | `officecli move/swap <file> ...` |
| Xóa element | `officecli remove <file> '<path>'` |
| Clone element | `officecli add <file> / --from '<path>'` |
| Batch nhiều lệnh | `officecli batch <file> --commands '[...]' --json` |
| Set document props | `officecli set <file> / --prop docDefaults.font=Arial` |
| Raw XML (L3) | `officecli raw-set <file> <part> --xpath "..." --action replace --xml '...'` |

### QA Loop - Kiểm tra Trước khi Giao

```powershell
# 1. Preview HTML real-time
officecli watch <file>                    # Mở http://localhost:26315

# 2. Kiểm tra lỗi tự động
officecli view <file> issues              # format | content | structure
officecli validate <file>                 # Schema validation

# 3. Screenshot kiểm tra visual
officecli view <file> screenshot -o preview.png

# 4. Save và close
officecli close <file>
```

---

## 2. Đường ray Đôi (Dual-Track) & Agent Workflow

**TỐI QUAN TRỌNG:** Agent KHÔNG ĐƯỢC tự ý đoán luồng định dạng. Trước khi tạo file, bắt buộc hỏi người dùng chọn 1 trong 3 tùy chọn:

| Lựa chọn | Luồng Thực thi | Ứng dụng | Kỹ thuật OfficeCLI |
|:---:|---|---|---|
| **[1]** | **Chuẩn Hành chính Quốc gia (NĐ 30)** | Công văn, Tờ trình, Quyết định nhà nước | **Đen/Trắng tuyệt đối.** Cấm Brand Kit. `--prop font="Times New Roman"`, lề chuẩn (Trái 3cm, Phải 1.5cm, Trên/Dưới 2cm). Theo `standards/nd30.md` của skill `xu-ly-van-phong` |
| **[2]** | **Chuẩn Thẩm mỹ Hiện đại (Doanh nghiệp)** | Đề xuất, Pitch Deck, Báo cáo nội bộ | **Kích hoạt Brand Kit.** Dùng theme colors (`accent1..accent6`), bảng zebra, callout box. Load sub-skill phù hợp |
| **[3]** | **Đọc & Bóc tách (chỉ phân tích)** | Cào file mẫu lấy format | Chỉ chạy `view`, `get`, `query`, `dump`. Xuất báo cáo thông số |

### Nhánh đặc biệt: User chỉ đưa CONTENT (file MD, text) - không có file mẫu

Quy trình 3 bước:

1. **Phân tích content** → lập Kế hoạch Thiết kế (chia slide/sheet/heading, bảng nào thành chart, số nào thành callout) và trình user duyệt.
2. **Chốt Brand Kit** → đề xuất 2-3 palette (dùng theme colors `accent1..accent6` của officecli), hoặc nhận màu/logo user cung cấp.
3. **Generate + QA loop** → `officecli create` → `add/set` → `view issues` → fix → `close`.

---

## 3. Kiến trúc Vật lý của Skill

### Tầng 1: Tài liệu Hướng dẫn (`references/`)

| Thư mục | Nội dung | Khi nào đọc |
|---|---|---|
| `references/officecli-command-guide.md` | **Hướng dẫn lệnh tổng hợp** - cú pháp, ví dụ, pitfalls | Đọc khi cần tra cứu cú pháp cụ thể |
| `references/schemas/docx/` | 44 file JSON schema cho Word | Đọc file cụ thể khi cần biết properties chi tiết (VD: `paragraph.json`) |
| `references/schemas/pptx/` | 34 file JSON schema cho PowerPoint | Tương tự |
| `references/schemas/xlsx/` | 41 file JSON schema cho Excel | Tương tự |

### Tầng 2: Sub-Skills Chuyên biệt (`references/skills/`)

Agent **PHẢI** chọn đúng sub-skill dựa trên nghiệp vụ và đọc SKILL.md tương ứng trước khi bắt tay vào làm:

| Nghiệp vụ | Sub-skill cần đọc | Dung lượng |
|---|---|---|
| Word - báo cáo, thư, đề xuất | `references/skills/officecli-docx/SKILL.md` | 43 KB |
| Word - luận văn, bài báo khoa học | `references/skills/officecli-academic-paper/SKILL.md` | 45 KB |
| Word - form fields | `references/skills/officecli-word-form/SKILL.md` | 46 KB |
| PowerPoint - slide thông thường | `references/skills/officecli-pptx/SKILL.md` | 44 KB |
| PowerPoint - pitch deck gọi vốn | `references/skills/officecli-pitch-deck/SKILL.md` | 66 KB |
| PowerPoint - Morph animation | `references/skills/morph-ppt/SKILL.md` | 48 KB |
| PowerPoint - 3D Morph | `references/skills/morph-ppt-3d/SKILL.md` | (trong morph-ppt-3d/) |
| Excel - bảng tính chung | `references/skills/officecli-xlsx/SKILL.md` | 35 KB |
| Excel - mô hình tài chính | `references/skills/officecli-financial-model/SKILL.md` | 48 KB |
| Excel - dashboard KPI | `references/skills/officecli-data-dashboard/SKILL.md` | 29 KB |

> **Quy tắc chọn sub-skill:** Chọn sub-skill **chuyên biệt nhất** khớp nghiệp vụ. Nếu không khớp, dùng mặc định format (docx/pptx/xlsx). Mỗi artifact chỉ load **một** sub-skill, không xếp chồng.

### Tầng 3: Tiêu chuẩn & Templates

Kế thừa từ skill `xu-ly-van-phong` gốc:
- NĐ 30: Xem `xu-ly-van-phong/standards/nd30.md`
- Brand Kits: Xem `xu-ly-van-phong/standards/brand_kits/`
- Templates hành chính: Xem `xu-ly-van-phong/templates/`
- Dynamic structure: Xem `xu-ly-van-phong/standards/dynamic_structure/`

### Tầng 4: Examples

- `examples/README.md` - Mô tả các file mẫu tạo bằng OfficeCLI (tham khảo cấu trúc lệnh)

---

## 4. Resident Mode - Hiệu suất

OfficeCLI tự khởi động resident process khi truy cập file đầu tiên. Để tối ưu:

```powershell
# Mở phiên dài (12 phút idle timeout)
officecli open report.docx

# Thao tác liên tục - không cần save giữa chừng
officecli set report.docx ...
officecli add report.docx ...
officecli get report.docx ...         # Luôn thấy edit mới nhất

# Save khi cần đưa file cho tool khác đọc
officecli save report.docx            # Flush, giữ resident

# Hoặc đóng hoàn toàn
officecli close report.docx           # Flush + giải phóng
```

> **Quan trọng:** Chỉ cần `save`/`close` khi chuyển file sang tool khác (viewer, upload, email). Các lệnh officecli nội bộ (`get`/`query`/`view`) luôn đọc dữ liệu mới nhất từ memory.

---

## 5. Nguyên tắc Tuân thủ Tuyệt đối

1. **HỎI TRƯỚC KHI VẼ:** Luôn dùng Bảng 3 Lựa chọn hỏi User trước khi tạo file.
2. **TRACK 1 CẤM MÀU SẮC:** User chọn [1] → nghiêm cấm theme colors, callout, font nghệ thuật. Tuân thủ tuyệt đối NĐ 30. Không trộn format NĐ 30 với format doanh nghiệp.
3. **TRACK 2 PHẢI DÙNG OFFICECLI:** User chọn [2] → dùng `officecli` cho mọi thao tác. Load sub-skill phù hợp từ `references/skills/`.
4. **HELP TRƯỚC KHI ĐOÁN:** Khi không chắc property name hay value format → chạy `officecli help <format> <element>` thay vì đoán. Một lệnh help tốt hơn 3 lần retry.
5. **SƠ ĐỒ PHẢI SỐNG:** Cấm copy chart/diagram cũ bằng ảnh. Bóc Data (`dump`) rồi tái tạo bằng `add --type chart/diagram`.
6. **EXCEL PHẢI SỐNG:** Mọi ô tính toán dùng Live Formula, không hardcode kết quả.
7. **QA TRƯỚC KHI GIAO:** Chạy `validate` + `view issues` ít nhất 1 vòng. Dùng `view html` hoặc `watch` để kiểm tra visual.
8. **CONTENT-ONLY PHẢI QUA PHÂN TÍCH:** User chỉ đưa MD/text → bắt buộc phân tích content (chia section, map sang element type) trước khi generate. Cấm nhồi 100% văn xuôi vào Excel/Slide.
9. **DOCX PHẢI THEO KHUNG MẶC ĐỊNH:** Body justify + first-line indent 1.25cm + spacing 3pt/3pt + line atLeast 1.3 lần cỡ chữ; bullet dấu gạch `-`, không dùng `•`. Bảng full khổ nội dung. Brand Kit (Track 2) chỉ đắp lớp màu lên khung, không thay đổi thông số khung.
10. **KHỬ DẤU VẾT AI TRONG DẤU CÂU:** Cấm em dash `—` (thay ` - ` hoặc từ nối), cấm dấu hai chấm trong tiêu đề, cấm Oxford comma `, và`. Sau generate phải kiểm tra bằng `officecli set <file> / --find "—"` (phải 0 kết quả).

---

## 6. Workflow Tham chiếu Nhanh

### Tạo Word mới (Track 2 - Thẩm mỹ)

```powershell
# 1. Tạo file + set document defaults
officecli create report.docx
officecli set report.docx / --prop docDefaults.font=Arial --prop docDefaults.fontSize=11pt

# 2. Thêm nội dung
officecli add report.docx /body --type paragraph --prop text="Báo cáo Quý 4" --prop style=Heading1
officecli add report.docx /body --type paragraph --prop text="Doanh thu tăng 25% so với cùng kỳ."

# 3. Thêm bảng
officecli add report.docx /body --type table --prop rows=3 --prop cols=4

# 4. QA
officecli view report.docx issues
officecli validate report.docx
officecli close report.docx
```

### Tạo Slide mới (Track 2)

```powershell
# 1. Tạo + thêm slide
officecli create deck.pptx
officecli add deck.pptx / --type slide --prop title="Q4 Report" --prop background=1A1A2E

# 2. Thêm shape
officecli add deck.pptx '/slide[1]' --type shape --prop text="Revenue grew 25%" --prop x=2cm --prop y=5cm --prop font=Arial --prop size=24 --prop color=FFFFFF

# 3. Thêm chart
officecli add deck.pptx '/slide[1]' --type chart --prop chartType=bar --prop title="Revenue"

# 4. Preview real-time
officecli watch deck.pptx
```

### Tạo Excel mới (Track 2)

```powershell
# 1. Tạo + đổ data
officecli create data.xlsx
officecli set data.xlsx /Sheet1/A1 --prop value="Tên" --prop bold=true
officecli set data.xlsx /Sheet1/B1 --prop value="Doanh thu" --prop bold=true
officecli set data.xlsx /Sheet1/A2 --prop value="Sản phẩm A"
officecli set data.xlsx /Sheet1/B2 --prop value=15000000

# 2. Thêm formula
officecli set data.xlsx /Sheet1/B10 --prop value="=SUM(B2:B9)"

# 3. Thêm chart
officecli add data.xlsx /Sheet1 --type chart --prop chartType=bar --prop source="Sheet1!A1:B9"

# 4. QA
officecli validate data.xlsx
officecli close data.xlsx
```

### Bóc tách file có sẵn (Track 3)

```powershell
# Xem cấu trúc
officecli view existing.docx outline
officecli view existing.docx stats

# Lấy chi tiết element
officecli get existing.docx '/body/p[1]' --depth 2 --json

# Dump toàn bộ (có thể replay bằng batch)
officecli dump existing.docx > backup.json

# Tìm element cụ thể
officecli query existing.docx 'paragraph[style=Heading1]'
officecli query existing.docx 'run[font!=Arial]'
```

---

## Tác giả

**Nguyễn Duy Tùng**
Tư vấn xây dựng Song sinh số Doanh nghiệp (EDT) & Lực lượng Lao động AI (AI Workforce)
Liên hệ: 0904.004.920

Dựa trên [OfficeCLI](https://github.com/iOfficeAI/OfficeCLI) - Apache 2.0 License
