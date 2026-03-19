from unittest import TestCase
from .models import Wallet

class WalletTransferTest(TestCase):
    def setUp(self):
        # Arrange: เตรียมข้อมูลเบื้องต้นก่อนเริ่มเทสต์
        self.wallet_a = Wallet(user_id="A001", balance=100)
        self.wallet_b = Wallet(user_id="B002", balance=50)

    def test_transfer_fails_if_insufficient_balance(self):
        # TODO Mission 1: เขียน Unit Test ตามโจทย์
        pass

    def test_transfer_success_happy_path(self):
        # TODO Mission 1: เขียน Unit Test ตามโจทย
        pass

    def test_transfer_exact_balance_success(self):
        # TODO Mission 1: เขียน Unit Test ตามโจทย์
        pass

    def test_transfer_fails_if_negative_amount(self):
        # TODO Mission 1: เขียน Unit Test ตามโจทย์
        pass