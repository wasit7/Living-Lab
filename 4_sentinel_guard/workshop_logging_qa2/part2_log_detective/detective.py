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

# ใช้ List Comprehension ดึงเฉพาะ Log ที่ระดับ ERROR
error_logs = [log for log in logs if log.get("level") == "ERROR"]

print(f"พบ Error ทั้งหมด: {len(error_logs)} รายการ\n")
# Output: พบ Error ทั้งหมด: 5 รายการ


# ==========================================
# Mission 2: Root Cause Analysis (หาต้นตอ)
# ==========================================
print("--- Mission 2: Root Cause Analysis ---")

# 1. หาเหตุการณ์ (event) ที่พังบ่อยสุด
event_counts = Counter(log.get("event") for log in error_logs)
print(f"เหตุการณ์ที่ Error บ่อยสุด: {event_counts.most_common(1)[0]}")

# 2. หาสาเหตุ (reason) ของ checkout_failed
checkout_errors = [
    log.get("reason") for log in error_logs if log.get("event") == "checkout_failed"
]
reason_counts = Counter(checkout_errors)
print(f"สาเหตุการจ่ายเงินพัง (Reason): {reason_counts}\n")
# Output: สาเหตุการจ่ายเงินพัง (Reason): Counter({'timeout': 3, 'insufficient_funds': 1})


# ==========================================
# Mission 3: The Alert Logic (ยามเฝ้าระบบ)
# ==========================================
print("--- Mission 3: The Alert Logic ---")


def check_alert(error_list):
    timeout_count = 0

    # วนลูปนับจำนวน timeout
    for log in error_list:
        if log.get("event") == "checkout_failed" and log.get("reason") == "timeout":
            timeout_count += 1

    # ตรรกะการแจ้งเตือน
    if timeout_count > 2:
        print(
            f"🚨 CRITICAL ALERT: Payment Gateway อาจจะล่ม! พบ Timeout {timeout_count} ครั้ง 🚨"
        )
    else:
        print("✅ ระบบยังอยู่ในเกณฑ์ปกติ")


check_alert(error_logs)
# Output: 🚨 CRITICAL ALERT: Payment Gateway อาจจะล่ม! พบ Timeout 3 ครั้ง 🚨
