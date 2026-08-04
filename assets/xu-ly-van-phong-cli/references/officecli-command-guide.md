# OfficeCLI - Hướng dẫn Lệnh Chi tiết

Tài liệu tra cứu nhanh cho Agent. Tổ chức theo nghiệp vụ, không theo lệnh.

> **Quy tắc vàng:** Khi không chắc property name hay value format → chạy `officecli help <format> <element>` thay vì đoán.

---

## 1. Cài đặt & Kiểm tra

### Cài đặt trực tuyến (Khuyến nghị)
```powershell
# Cài đặt (Windows)
irm https://d.officecli.ai/install.ps1 | iex
```

### Cài đặt ngoại tuyến (Fallback)
```powershell
# Copy binary từ thư mục tài nguyên của Skill vào system path
$dest = "C:\Users\gabeo\.officecli\bin"
New-Item -ItemType Directory -Path $dest -Force | Out-Null
Copy-Item -Path "C:\Users\gabeo\.gemini\config\skills\xu-ly-van-phong-cli\resources\bin\officecli.exe" -Destination "$dest\officecli.exe" -Force
[Environment]::SetEnvironmentVariable("Path", "$dest;" + [Environment]::GetEnvironmentVariable("Path", "User"), "User")
$env:Path = "$dest;$env:Path"
```

# Kiểm tra
officecli --version

# Xem tất cả commands
officecli help
```

---

## 2. Hệ thống Help (BẮT BUỘC DÙNG)

```powershell
officecli help                                  # Tất cả commands + global options
officecli help docx                             # Danh sách elements của Word
officecli help docx paragraph                   # Full schema: properties, aliases, examples
officecli help docx set paragraph               # Chỉ properties dùng được với `set`
officecli help docx paragraph --json            # Schema dạng JSON (machine-readable)
```

**Alias format:** `word` → `docx`, `excel` → `xlsx`, `ppt`/`powerpoint` → `pptx`

**Verbs:** `add`, `set`, `get`, `query`, `remove`

> **Schema JSON files** nằm tại `references/schemas/` (44 docx + 34 pptx + 41 xlsx) - đọc trực tiếp khi cần tra cứu offline.

---

## 3. Resident Mode - Quản lý Phiên

```powershell
# Mở phiên dài (12 phút idle timeout)
officecli open report.docx

# Thao tác - không cần save giữa chừng
officecli set report.docx '/body/p[1]' --prop text="Updated text"
officecli get report.docx '/body/p[1]' --json   # Luôn thấy edit mới nhất

# Save khi cần đưa file cho tool khác
officecli save report.docx            # Flush, giữ resident
officecli close report.docx           # Flush + giải phóng
```

**Auto-resident:** Mọi lệnh tự khởi resident (60s idle). Không cần `open` cho thao tác ngắn.

**Biến môi trường:**
- `OFFICECLI_NO_AUTO_RESIDENT=1` - Tắt auto-start
- `OFFICECLI_RESIDENT_FLUSH=each` - Flush sau mỗi mutation

---

## 4. Tạo File Mới

```powershell
officecli create <file>               # Tạo blank theo extension (.docx/.xlsx/.pptx)
officecli create doc.docx --minimal   # Scaffold OOXML tối thiểu (docx)
officecli create doc.docx --locale ar-SA  # Locale cụ thể (auto-enable RTL)
```

---

## 5. Đọc & Phân tích

### 5.1 View Modes

```powershell
officecli view <file> outline         # Cấu trúc tài liệu
officecli view <file> stats           # Thống kê (trang, từ, shapes)
officecli view <file> text            # Text thuần (--start N --end N, --max-lines N)
officecli view <file> annotated       # Text kèm format annotations
officecli view <file> issues          # Lỗi format/content/structure
officecli view <file> html            # HTML snapshot (--browser để mở trình duyệt)
officecli view <file> screenshot -o out.png  # PNG (--screenshot-width/height)
officecli view <file> svg             # SVG (pptx slide)
```

**Issues filtering:**
```powershell
officecli view <file> issues --type format     # Chỉ lỗi format
officecli view <file> issues --type content    # Chỉ lỗi nội dung
officecli view <file> issues --type structure  # Chỉ lỗi cấu trúc
officecli view <file> issues --limit 10        # Giới hạn kết quả
```

### 5.2 Get - Lấy Chi tiết Element

```powershell
officecli get <file> <path> --depth N [--json]
```

**Path examples:**
```
/body/p[3]                           # Word: paragraph thứ 3
/body/tbl[1]                         # Word: table đầu tiên
/slide[1]                            # PPT: slide đầu tiên
/slide[1]/shape[2]                   # PPT: shape thứ 2 trên slide 1
/Sheet1/A1                           # Excel: ô A1
/Sheet1/B2:D10                       # Excel: range
```

**Stable ID paths** (ưu tiên trong multi-step):
```
/slide[1]/shape[@id=550950021]       # PPT shape by ID
/slide[1]/shape[@name=Title 1]       # PPT shape by name
/body/p[@paraId=1A2B3C4D]           # Word paragraph by ID
```

**Đọc selection từ Watch:**
```powershell
officecli get <file> selected [--json]  # Lấy element user click trong browser
```

### 5.3 Query - Tìm Kiếm CSS-like

```powershell
officecli query <file> '<selector>'
```

**Selector syntax:**
| Selector | Ý nghĩa |
|---|---|
| `[attr=value]` | Bằng |
| `[attr!=value]` | Khác |
| `[attr~=text]` | Chứa text |
| `[attr>=value]` | Lớn hơn hoặc bằng |
| `[attr<=value]` | Nhỏ hơn hoặc bằng |
| `:contains("text")` | Chứa text |
| `:empty` | Rỗng |
| `:has(formula)` | Có formula |
| `:no-alt` | Không có alt text |

**Boolean operators:**
```powershell
officecli query data.xlsx 'cell[value>5000 or value<100]'
officecli query data.xlsx 'cell[(type=Number or type=Date) and value>0]'
```

**Excel row-by-column-name:**
```powershell
officecli query data.xlsx 'Sheet1!row[Salary>5000]'
officecli query data.xlsx 'Sheet1!row[Salary>5000 and Region=EMEA]'
```

**Word/PPT examples:**
```powershell
officecli query report.docx 'paragraph[style=Normal] > run[font!=Arial]'
officecli query slides.pptx 'shape[fill=FF0000]'
officecli query report.docx 'revision[revision.type=ins]'
```

### 5.4 Validate & Dump

```powershell
officecli validate <file>             # Validate against OpenXML schema

officecli dump <file> [<path>]        # Xuất JSON batch có thể replay
# path examples: /body, /body/p[N], /theme, /styles, /SheetName
```

---

## 6. Chỉnh sửa Nội dung

### 6.1 Set - Sửa Thuộc tính

```powershell
officecli set <file> <path> --prop key=value [--prop ...]
```

**Value formats:**

| Loại | Format | Ví dụ |
|---|---|---|
| Colors | Hex, named, RGB, theme | `FF0000`, `#FF0000`, `red`, `rgb(255,0,0)`, `accent1..accent6` |
| Spacing | Đơn vị | `12pt`, `0.5cm`, `1.5x`, `150%` |
| Dimensions | EMU hoặc đơn vị | `914400`, `2.54cm`, `1in`, `72pt`, `96px` |

**Dotted-attr aliases:**
```powershell
--prop font.color=red --prop font.bold=true --prop font.size=14pt
```

### 6.2 Find & Replace

```powershell
# Format text tìm được (auto-splits runs)
officecli set doc.docx '/body/p[1]' --find weather --prop bold=true --prop color=red

# Regex
officecli set doc.docx '/body/p[1]' --find '\d+%' --prop regex=true --prop color=red

# Replace text (/ = toàn document)
officecli set doc.docx / --find draft --replace final

# Tracked changes (Word)
officecli set doc.docx / --find draft --replace final --prop revision.author=Alice

# Case-insensitive
officecli set doc.docx / --find '(?i)error' --prop regex=true --prop color=red

# PPT - cùng cú pháp
officecli set slides.pptx / --find draft --replace final
```

**Scope:** `/` = toàn document, `/body/p[1]` = element cụ thể, `/header[1]` = header

### 6.3 Set Document-level Properties

```powershell
# Word
officecli set doc.docx / --prop docDefaults.font=Arial --prop docDefaults.fontSize=11pt
officecli set doc.docx / --prop protection=forms --prop evenAndOddHeaders=true

# Excel
officecli set data.xlsx / --prop calc.mode=manual --prop calc.refMode=r1c1

# PPT
officecli set slides.pptx / --prop defaultFont=Arial --prop show.loop=true
```

### 6.4 Sort (Excel)

```powershell
officecli set data.xlsx /Sheet1 --prop sort="C desc" --prop sortHeader=true
officecli set data.xlsx '/Sheet1/A1:D100' --prop sort="A asc, B desc" --prop sortHeader=true
```

---

## 7. Thêm Elements

### 7.1 Add - Cú pháp Chung

```powershell
officecli add <file> <parent> --type <type> [--prop ...]
officecli add <file> <parent> --type <type> --after <path>    # Chèn sau
officecli add <file> <parent> --type <type> --before <path>   # Chèn trước
officecli add <file> <parent> --type <type> --index N         # Vị trí (0-based)
officecli add <file> <parent> --from '<path>'                 # Clone element
```

### 7.2 Word Elements

```powershell
# Paragraph
officecli add doc.docx /body --type paragraph --prop text="Nội dung" --prop style=Heading1

# Table
officecli add doc.docx /body --type table --prop rows=3 --prop cols=4

# Image
officecli add doc.docx /body --type image --prop src=logo.png --prop width=5cm

# Chart
officecli add doc.docx /body --type chart --prop chartType=bar --prop title="Revenue"

# Diagram (Mermaid → native shapes)
officecli add doc.docx /body --type diagram --prop mermaid="graph LR; A-->B"

# Header/Footer
officecli add doc.docx / --type header --prop text="Company Name"

# Section break
officecli add doc.docx /body --type section --prop type=nextPage

# TOC
officecli add doc.docx /body --type toc

# Comment
officecli add doc.docx '/body/p[1]' --type comment --prop text="Review needed" --prop author=Alice

# Watermark
officecli add doc.docx / --type watermark --prop text=DRAFT

# Equation (LaTeX input)
officecli add doc.docx /body --type equation --prop latex="E=mc^2"

# Hyperlink
officecli add doc.docx '/body/p[1]' --type hyperlink --prop text="Click here" --prop url="https://example.com"

# Text-anchored insert
officecli add doc.docx '/body/p[1]' --type run --after find:weather --prop text=" (sunny)"
```

### 7.3 PowerPoint Elements

```powershell
# Slide
officecli add deck.pptx / --type slide --prop title="Q4 Report" --prop background=1A1A2E

# Shape
officecli add deck.pptx '/slide[1]' --type shape --prop text="Hello" --prop x=2cm --prop y=5cm --prop font=Arial --prop size=24 --prop color=FFFFFF

# Picture
officecli add deck.pptx '/slide[1]' --type picture --prop src=image.png --prop x=3cm --prop y=4cm --prop width=10cm

# Chart
officecli add deck.pptx '/slide[1]' --type chart --prop chartType=bar --prop title="Revenue" --prop anchor=x,y,w,h

# Table
officecli add deck.pptx '/slide[1]' --type table --prop rows=4 --prop cols=3 --prop x=1cm --prop y=3cm

# Connector
officecli add deck.pptx '/slide[1]' --type connector --prop from="/slide[1]/shape[@name=Start]" --prop to="/slide[1]/shape[@name=End]"

# Animation
officecli add deck.pptx '/slide[1]/shape[2]' --type animation --prop preset=fadeIn

# Transition
officecli add deck.pptx '/slide[1]' --type transition --prop preset=morph

# Notes
officecli add deck.pptx '/slide[1]' --type notes --prop text="Speaker notes here"

# Video/Audio
officecli add deck.pptx '/slide[1]' --type video --prop src=demo.mp4 --prop autoStart=true

# 3D Model
officecli add deck.pptx '/slide[1]' --type model3d --prop src=model.glb

# Diagram (Mermaid)
officecli add deck.pptx '/slide[1]' --type diagram --prop mermaid="graph LR; A-->B"
```

### 7.4 Excel Elements

```powershell
# Set cell values
officecli set data.xlsx /Sheet1/A1 --prop value="Name" --prop bold=true
officecli set data.xlsx /Sheet1/B2 --prop value=15000 --prop numberFormat="#,##0"

# Add row
officecli add data.xlsx /Sheet1 --type row --index 5

# Add column
officecli add data.xlsx /Sheet1 --type col --index 3

# Add sheet
officecli add data.xlsx / --type sheet --prop name="Summary"

# Chart
officecli add data.xlsx /Sheet1 --type chart --prop chartType=bar --prop source="Sheet1!A1:B10" --prop title="Sales"

# Pivot table
officecli add data.xlsx /Sheet1 --type pivottable --prop source="Sheet1!A1:E100" --prop rows=Region,Category --prop cols=Year --prop values="Sales:sum,Qty:count"

# Sparkline
officecli add data.xlsx /Sheet1 --type sparkline --prop source="B2:M2" --prop target=N2 --prop type=line

# Conditional formatting
officecli add data.xlsx /Sheet1 --type conditionalformatting --prop range="B2:B100" --prop type=databar

# Data validation
officecli add data.xlsx /Sheet1 --type validation --prop range="C2:C100" --prop type=list --prop formula="Yes,No,Maybe"

# Named range
officecli add data.xlsx / --type namedrange --prop name=SalesData --prop ref="Sheet1!A1:B100"

# Table (ListObject)
officecli add data.xlsx /Sheet1 --type table --prop range="A1:D100" --prop name=SalesTable

# Image
officecli add data.xlsx /Sheet1 --type image --prop src=chart.png --prop x=5cm --prop y=10cm

# Comment
officecli add data.xlsx /Sheet1/A1 --type comment --prop text="Check this value"

# Merge cells
officecli set data.xlsx /Sheet1/A1 --prop merge="A1:D1"
```

---

## 8. Thao tác Cấu trúc

### 8.1 Move, Swap, Remove

```powershell
# Move
officecli move <file> <path> [--to <parent>] [--index N] [--after <path>] [--before <path>]

# Swap
officecli swap <file> <path1> <path2>

# Remove
officecli remove <file> '<path>'

# Remove với shift (Excel)
officecli remove data.xlsx /Sheet1/B5 --shift left
officecli remove data.xlsx /Sheet1/B5 --shift up
```

### 8.2 Batch - Nhiều Lệnh Một Lượt

```powershell
# Inline JSON
officecli batch data.xlsx --commands '[
  {"command":"set","path":"/Sheet1/A1","props":{"value":"Name","bold":"true"}},
  {"command":"set","path":"/Sheet1/B1","props":{"value":"Score","bold":"true"}}
]' --json

# Pipe JSON
echo '[...]' | officecli batch data.xlsx --json

# Từ file
officecli batch data.xlsx --input updates.json --json

# Options
# --stop-on-error  Dừng ở lỗi đầu tiên (mặc định: tiếp tục)
# --force          Bypass docx protection
```

**Supported ops:** `add`, `set`, `get`, `query`, `remove`, `move`, `swap`, `view`, `raw`, `raw-set`, `validate`

**Fields:** `command`/`op`, `path`, `parent`, `type`, `from`, `to`, `index`, `after`, `before`, `props`, `selector`, `mode`, `depth`, `part`, `xpath`, `action`, `xml`

### 8.3 Clone

```powershell
officecli add <file> / --from '/slide[1]'      # Clone slide (kèm relationships)
officecli add <file> /body --from '/body/tbl[1]' # Clone table
```

---

## 9. Raw XML (L3)

Chỉ dùng khi L2 không đáp ứng.

```powershell
# Xem raw XML
officecli raw <file> <part>

# Sửa raw XML
officecli raw-set <file> <part> --xpath "..." --action replace --xml '<w:p>...</w:p>'

# Tạo document part mới
officecli add-part <file> <parent>    # Returns rId
```

**Actions:** `append`, `prepend`, `insertbefore`, `insertafter`, `replace`, `remove`, `setattr`

---

## 10. Watch & Preview

```powershell
officecli watch <file> [--port N]     # Live preview (default: 26315)
officecli unwatch <file>              # Stop
officecli goto <file> <path>          # Scroll browser đến element

# Đọc selection
officecli get <file> selected --json  # Lấy element user đã click
```

**Marks - Đề xuất chỉnh sửa chờ duyệt:**
```powershell
officecli mark <file> <path> --prop find="error" --prop color=red --prop note="Fix this"
officecli get-marks <file> --json
officecli unmark <file> --all
```

---

## 11. Specialized Skills (load_skill)

```powershell
officecli load_skill <name>           # In ra SKILL.md chuyên biệt
```

| Tên | Khi nào dùng |
|---|---|
| `word` | Báo cáo, thư, đề xuất, tài liệu chung |
| `academic-paper` | Luận văn, bài báo khoa học (APA/Chicago/IEEE/MLA) |
| `pptx` | Slide board review, sales deck, all-hands |
| `pitch-deck` | **Chỉ fundraising** (seed, Series A-C, SAFE) |
| `morph-ppt` | Cinematic Morph animation |
| `morph-ppt-3d` | 3D Morph (GLB models, camera moves) |
| `excel` | Bảng tính chung, formulas, pivots |
| `financial-model` | Mô hình tài chính, scenarios, projections |
| `data-dashboard` | CSV/data → KPI dashboard với charts + sparklines |

> Sub-skill đã có sẵn tại `references/skills/` - đọc SKILL.md tương ứng thay vì chạy `load_skill`.

---

## 12. Bảng Tra Nhanh

### Index Convention

| Context | Convention | Ví dụ |
|---|---|---|
| Path `[N]` | **1-based** (XPath) | `/body/p[3]` = paragraph 3 |
| `--index N` | **0-based** (array) | `--index 0` = vị trí đầu |
| `--index N` cho row/col (Excel) | **1-based** | `--index 5` = row 5 |

### Common Pitfalls

| Sai | Đúng |
|---|---|
| `--name "foo"` | `--prop name="foo"` - mọi attribute qua `--prop` |
| Path không quote `[N]` | Luôn quote: `'/slide[1]'` |
| PPT `shape[1]` cho content | `shape[1]` thường là title. Dùng `shape[2]+` |
| Đoán property name | Chạy `officecli help <format> <element>` |
| Sửa file đang mở bởi Office | Đóng file trong PowerPoint/Word trước |
| `\n` trong shell | Dùng `\\n` cho newlines |
| `$` trong text | Dùng single quotes: `--prop text='$15M'` |
| Save giữa workflow officecli | Không cần - officecli reads luôn thấy latest |

### PowerShell-Specific Notes

```powershell
# PowerShell dùng backtick thay backslash cho multi-line
officecli add deck.pptx '/slide[1]' --type shape `
  --prop text="Hello" `
  --prop x=2cm --prop y=5cm

# Escape dấu ngoặc kép trong --prop
officecli set doc.docx '/body/p[1]' --prop text='He said "hello"'

# Pipe JSON trong PowerShell
'[{"command":"set","path":"/Sheet1/A1","props":{"value":"Done"}}]' | officecli batch data.xlsx --json
```

---

## 13. Tham chiếu Schema Files

Khi cần tra cứu chi tiết properties của một element, đọc file JSON tương ứng:

```
references/schemas/docx/paragraph.json    # 43KB - mọi props của Word paragraph
references/schemas/docx/table.json        # Table properties
references/schemas/docx/run.json          # Run (text run) properties
references/schemas/pptx/shape.json        # 43KB - PPT shape properties
references/schemas/pptx/slide.json        # Slide properties
references/schemas/pptx/chart.json        # Chart properties
references/schemas/xlsx/cell.json         # 22KB - Excel cell properties
references/schemas/xlsx/sheet.json        # Sheet properties
references/schemas/xlsx/pivottable.json   # Pivot table properties
references/schemas/_shared/chart.json     # 41KB - Shared chart schema (all formats)
```

Mỗi file JSON chứa:
- **Properties**: Tên, loại, alias, giá trị mặc định
- **Examples**: Ví dụ cụ thể cho từng property
- **Readbacks**: Giá trị trả về khi `get`
