import os
import sys
import subprocess
import shutil
import json
from pathlib import Path

def run_formatter(script_name, *args):
    script_path = Path(__file__).parent / "formatters" / script_name
    cmd = [sys.executable, str(script_path)] + list(args)
    result = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8")
    if result.stdout:
        print(result.stdout)
    if result.stderr:
        print(result.stderr, file=sys.stderr)
    return result.returncode == 0

def export_docx(processing_dir_path):
    """
    Orchestrator script:
    Gọi tuần tự các layer script trong thư mục formatters/
    Temp files lưu trong 02.process/, final output lưu trong 03.output/.
    File cuối cùng đặt tên theo tên tài liệu gốc.
    """
    processing_dir = Path(processing_dir_path)
    process_dir = processing_dir / "02.process"
    output_dir = processing_dir / "03.output"
    format_spec_path = process_dir / "format_spec.json"
    
    if not format_spec_path.exists():
        print(f"[FAIL] Không tìm thấy {format_spec_path}. Chạy analyze_format.py trước.")
        return False
    
    output_dir.mkdir(parents=True, exist_ok=True)
    
    # Xác định tên tài liệu gốc từ tên thư mục processing
    # Ví dụ: "di-19-TTr-UBND.signed_processing" → "di-19-TTr-UBND.signed"
    dir_name = processing_dir.name
    if dir_name.endswith("_processing"):
        doc_basename = dir_name[:-len("_processing")]
    else:
        doc_basename = dir_name
    
    final_docx = output_dir / f"{doc_basename}.docx"
    final_md = output_dir / f"{doc_basename}.md"
    
    # Temporary files trong 02.process/
    temp0 = process_dir / "temp0.docx"
    temp1 = process_dir / "temp1.docx"
    temp2 = process_dir / "temp2.docx"
    temp3 = process_dir / "temp3.docx"
    temp4 = process_dir / "temp4.docx"
    
    print("=== LAYER 0: PANDOC GENERATION ===")
    if not run_formatter("00_pandoc.py", str(processing_dir), str(temp0)): 
        print("[FAIL] Lỗi ở Layer 0")
        return False
    
    print("=== LAYER 1: PAGE LAYOUT ===")
    shutil.copy(temp0, temp1)
    if not run_formatter("01_layout.py", str(temp1), str(format_spec_path)): 
        print("[FAIL] Lỗi ở Layer 1")
        return False
    
    print("=== LAYER 2: STRUCTURE ===")
    with open(format_spec_path, "r", encoding="utf-8") as f:
        format_spec = json.load(f)
        
    shutil.copy(temp1, temp2)
    # Tái cấu trúc bảng NĐ30 chỉ chạy nếu doc_type là hanh_chinh_nd30
    if format_spec.get("doc_type") == "hanh_chinh_nd30":
        if not run_formatter("02_structure.py", str(temp2)): 
            print("[FAIL] Lỗi ở Layer 2")
            return False
    else:
        print("[INFO] Bỏ qua Layer 2 (không phải NĐ 30)")
    
    print("=== LAYER 3: BLOCK FORMAT ===")
    shutil.copy(temp2, temp3)
    if not run_formatter("03_block.py", str(temp3), str(format_spec_path)): 
        print("[FAIL] Lỗi ở Layer 3")
        return False
    
    print("=== LAYER 4: TYPOGRAPHY ===")
    shutil.copy(temp3, temp4)
    if not run_formatter("04_typography.py", str(temp4), str(format_spec_path)): 
        print("[FAIL] Lỗi ở Layer 4")
        return False
    
    # Di chuyển file cuối cùng ra 03.output/ với tên tài liệu gốc
    shutil.move(temp4, final_docx)
    
    # Copy MERGED.md từ 02.process/ sang 03.output/ với tên tài liệu gốc
    merged_md = process_dir / "MERGED.md"
    if merged_md.exists():
        shutil.copy2(merged_md, final_md)
    
    print(f"\n[OK] Pipeline hoàn tất.")
    print(f"  DOCX: {final_docx}")
    print(f"  MD:   {final_md}")
    return True

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Usage: python export_docx.py <processing_dir>")
        sys.exit(1)
        
    export_docx(sys.argv[1])
