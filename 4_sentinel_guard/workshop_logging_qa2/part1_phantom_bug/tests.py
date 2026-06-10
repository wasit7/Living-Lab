from unittest import TestCase
from .models import Wallet


class WalletTransferTest(TestCase):
    def setUp(self):
        self.wallet_a = Wallet(user_id="A001", balance=100)
        self.wallet_b = Wallet(user_id="B002", balance=50)

    def test_transfer_fails_if_insufficient_balance(self):
        with self.assertRaises(ValueError) as context:
            self.wallet_a.transfer(self.wallet_b, 500)
        self.assertEqual(str(context.exception), "Insufficient balance")
        self.assertEqual(self.wallet_a.balance, 100)
        self.assertEqual(self.wallet_b.balance, 50)

    def test_transfer_success_happy_path(self):
        result = self.wallet_a.transfer(self.wallet_b, 40)

        self.assertTrue(result)
        self.assertEqual(self.wallet_a.balance, 60)
        self.assertEqual(self.wallet_b.balance, 90)

    def test_transfer_exact_balance_success(self):
        result = self.wallet_a.transfer(self.wallet_b, 100)

        self.assertTrue(result)
        self.assertEqual(self.wallet_a.balance, 0)
        self.assertEqual(self.wallet_b.balance, 150)

    def test_transfer_fails_if_negative_amount(self):
        with self.assertRaises(ValueError) as context:
            self.wallet_a.transfer(self.wallet_b, -10)

        self.assertEqual(self.wallet_a.balance, 100)
        self.assertEqual(self.wallet_b.balance, 50)
