import logging

# TODO Mission 2.2: เปลี่ยนมาใช้ logger แทน print เพื่อให้มี Context ครบถ้วน


class Wallet:
    def __init__(self, user_id, balance):
        self.user_id = user_id
        self.balance = balance

    def transfer(self, target_wallet, amount):
        #  Bad Logging: ขาดบริบทว่าใครโอนให้ใคร
        print("Transfer started")

        # TODO Mission 2.1: เพิ่ม Logic เช็คยอดเงิน

        self.balance -= amount
        target_wallet.balance += amount

        # Bad Logging: ขาดบริบท
        print("Transfer success")
        return True
