#!/bin/bash

BASE_DIR="workshop_logging_qa"

echo "🚀 กำลังสร้างโครงสร้างโฟลเดอร์สำหรับ Workshop..."

# 1. สร้างโฟลเดอร์
mkdir -p $BASE_DIR/part1_phantom_bug
mkdir -p $BASE_DIR/part2_log_detective

# 2. สร้างไฟล์ README.md
cat << 'EOF' > $BASE_DIR/README.md
# 🛠️ Workshop: Software Logging & Automated QA

ยินดีต้อนรับสู่ Workshop! ภารกิจของคุณแบ่งออกเป็น 2 ส่วน:

## Part 1: The Phantom Transfer Bug
ตามล่าหาบั๊กเงินติดลบ และเขียน Unit Test ดักจับมัน!
- **ไฟล์ที่ต้องแก้:** `part1_phantom_bug/models.py` และ `part1_phantom_bug/tests.py`
- **วิธีรัน Test:**
  รันคำสั่งนี้ที่โฟลเดอร์หลัก:
  `python -m unittest part1_phantom_bug.tests`

## Part 2: Log Detective
สวมวิญญาณนักสืบ วิเคราะห์ Log ที่พังเพื่อหาต้นตอ
- **ไฟล์ที่ต้องแก้:** `part2_log_detective/detective.py`
- **วิธีรัน Script:**
  เข้าไปที่โฟลเดอร์ `part2_log_detective` แล้วรัน:
  `python detective.py`

ขอให้สนุกกับการกู้ชีพโค้ด! 🐛💥
EOF

# 3. สร้างไฟล์สำหรับ Part 1 (The Phantom Bug)
touch $BASE_DIR/part1_phantom_bug/__init__.py

cat << 'EOF' > $BASE_DIR/part1_phantom_bug/models.py
import logging

# TODO Mission 2.2: เปลี่ยนมาใช้ logger แทน print เพื่อให้มี Context ครบถ้วน
# ไกด์: logger = logging.getLogger(__name__)

class Wallet:
    def __init__(self, user_id, balance):
        self.user_id = user_id
        self.balance = balance

    def transfer(self, target_wallet, amount):
        # ❌ Bad Logging: ขาดบริบทว่าใครโอนให้ใคร
        print("Transfer started")

        # 🐛 Bug ซ่อนอยู่ตรงนี้: โอนเงินโดยไม่เช็คยอดคงเหลือ!
        # TODO Mission 2.1: เพิ่ม Logic เช็คยอดเงิน
        # ถ้าเงินไม่พอ (self.balance < amount) ให้โยน Error: raise ValueError("Insufficient balance")

        self.balance -= amount
        target_wallet.balance += amount

        # ❌ Bad Logging: ขาดบริบท
        print("Transfer success")
        return True
EOF

cat << 'EOF' > $BASE_DIR/part1_phantom_bug/tests.py
from unittest import TestCase
from .models import Wallet

class WalletTransferTest(TestCase):
    def setUp(self):
        # Arrange: เตรียมข้อมูลเบื้องต้นก่อนเริ่มเทสต์
        self.wallet_a = Wallet(user_id="A001", balance=100)
        self.wallet_b = Wallet(user_id="B002", balance=50)

    def test_transfer_fails_if_insufficient_balance(self):
        # TODO Mission 1: เขียน Unit Test ตามโจทย์
        # 1. จำลองสถานการณ์ให้ A โอนให้ B จำนวน 500 บาท
        # 2. ใช้ Assert ตรวจสอบว่าต้องเกิด ValueError ขึ้น (ไกด์: with self.assertRaises(ValueError): )
        # 3. ใช้ Assert ตรวจสอบว่ายอดเงินของ A ต้องเหลือ 100 และ B ต้องเหลือ 50 เท่าเดิม!

        pass # ลบบรรทัดนี้ทิ้งแล้วเริ่มเขียนโค้ดได้เลย
EOF

# 4. สร้างไฟล์สำหรับ Part 2 (Log Detective)
cat << 'EOF' > $BASE_DIR/part2_log_detective/production_logs.json
[
  {"timestamp": "2026-03-18T10:00:01Z", "level": "INFO", "event": "login", "user_id": "U001", "ip": "192.168.1.10", "correlation_id": "req-001"},
  {"timestamp": "2026-03-18T10:00:05Z", "level": "INFO", "event": "add_to_cart", "user_id": "U001", "item": "iPhone 16", "correlation_id": "req-002"},
  {"timestamp": "2026-03-18T10:00:08Z", "level": "ERROR", "event": "checkout_failed", "user_id": "U001", "reason": "timeout", "correlation_id": "req-003"},
  {"timestamp": "2026-03-18T10:01:10Z", "level": "INFO", "event": "login", "user_id": "U002", "ip": "192.168.1.15", "correlation_id": "req-004"},
  {"timestamp": "2026-03-18T10:01:15Z", "level": "ERROR", "event": "checkout_failed", "user_id": "U002", "reason": "insufficient_funds", "correlation_id": "req-005"},
  {"timestamp": "2026-03-18T10:02:00Z", "level": "ERROR", "event": "checkout_failed", "user_id": "U003", "reason": "timeout", "correlation_id": "req-006"},
  {"timestamp": "2026-03-18T10:02:05Z", "level": "ERROR", "event": "database_connection_lost", "service": "payment_db", "correlation_id": "req-007"},
  {"timestamp": "2026-03-18T10:02:10Z", "level": "ERROR", "event": "checkout_failed", "user_id": "U004", "reason": "timeout", "correlation_id": "req-008"}
]
EOF

cat << 'EOF' > $BASE_DIR/part2_log_detective/detective.py
import json
from collections import Counter

def load_logs():
    with open('production_logs.json', 'r', encoding='utf-8') as file:
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
    # ให้ print แจ้งเตือน 🚨 "CRITICAL ALERT: Payment Gateway อาจจะล่ม! พบ Timeout ... ครั้ง"
    # ถ้าไม่ถึงเกณฑ์ ให้ print ✅ "ระบบยังอยู่ในเกณฑ์ปกติ"
    pass

check_alert(error_logs)
EOF

echo "✅ สร้างไฟล์โครงสร้างทั้งหมดเรียบร้อยแล้ว!"
echo "📂 โฟลเดอร์เป้าหมาย: ./$BASE_DIR"
echo "👉 ขั้นตอนต่อไป: cd $BASE_DIR แล้วเริ่มลุยได้เลย!"