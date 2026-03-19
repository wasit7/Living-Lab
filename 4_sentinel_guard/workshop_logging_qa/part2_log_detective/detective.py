import json
from collections import Counter


def load_logs():
    with open("production_logs.json", "r", encoding="utf-8") as file:
        return json.load(file)


logs = load_logs()
print(f"✅ โหลด Log สำเร็จทั้งหมด {len(logs)} รายการ\n")

# ==========================================
# Mission 1: The Filter (กรองหาผู้ต้องสงสัย)
# ==========================================
print("--- Mission 1: The Filter ---")

# TODO: ดึงเฉพาะ Log ที่มี level เป็น "ERROR" มาเก็บไว้ใน List ชื่อ error_logs
error_logs = []

print(f"พบ Error ทั้งหมด: {len(error_logs)} รายการ\n")

# ==========================================
# Mission 2: Root Cause Analysis (หาต้นตอ)
# ==========================================
print("--- Mission 2: Root Cause Analysis ---")

# TODO: วิเคราะห์จาก error_logs ว่าเหตุการณ์ (event) อะไรที่พังบ่อยสุด?
# TODO: เฉพาะ event "checkout_failed" สาเหตุ (reason) หลักคืออะไร?

# ไกด์: ลองใช้ for loop หรือ List Comprehension ดึงค่าออกมา แล้วใช้ Counter() ช่วยนับ


# ==========================================
# Mission 3: The Alert Logic (ยามเฝ้าระบบ)
# ==========================================
print("\n--- Mission 3: The Alert Logic ---")


def check_alert(error_list):
    # TODO: สร้างตรรกะแจ้งเตือน
    # ถ้านับเจอ event "checkout_failed" ที่มี reason "timeout" เกิน 2 ครั้ง
    # ให้ print แจ้งเตือน "CRITICAL ALERT: Payment Gateway อาจจะล่ม! พบ Timeout ... ครั้ง"
    # ถ้าไม่ถึงเกณฑ์ ให้ print ✅ "ระบบยังอยู่ในเกณฑ์ปกติ"
    pass


check_alert(error_logs)
