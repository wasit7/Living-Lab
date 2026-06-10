import logging

logger = logging.getLogger(__name__)

logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(name)s - %(levelname)s - %(message)s")

class Wallet:
    def __init__(self, user_id, balance):
        self.user_id = user_id
        self.balance = balance

    def transfer(self, target_wallet, amount):
        # 0. Security Check: ป้องกันโอนเงินยอดติดลบ หรือ 0 บาท
        if amount <= 0:
            logger.warning(
                "Transfer failed: Invalid amount",
                extra={
                    "sender_id": self.user_id,
                    "target_id": target_wallet.user_id,
                    "attempt_amount": amount,
                    "reason": "amount_must_be_strictly_positive",
                },
            )
            raise ValueError("Transfer amount must be positive")

        # 1. เช็คยอดเงินก่อนโอน
        if self.balance < amount:
            logger.error(
                "Transfer failed: Insufficient balance",
                extra={
                    "sender_id": self.user_id,
                    "target_id": target_wallet.user_id,
                    "attempt_amount": amount,
                    "current_balance": self.balance,
                },
            )
            raise ValueError("Insufficient balance")

        # 2. หักเงินและเพิ่มเงิน
        self.balance -= amount
        target_wallet.balance += amount
        logger.info(
            "Transfer success",
            extra={
                "sender_id": self.user_id,
                "target_id": target_wallet.user_id,
                "amount": amount,
            },
        )
        return True
