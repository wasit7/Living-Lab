import json
import time
import random
import os

log_file = "logs/app.log"
methods = ["GET", "POST", "DELETE", "PUT"]
levels = ["info", "warn", "error"]

print("Starting log generation... Press Ctrl+C to stop.")
while True:
    data = {
        "time": time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime()),
        "level": random.choice(levels),
        "method": random.choice(methods),
        "status": random.choice([200, 201, 400, 404, 500]),
        "msg": "API Request Processed",
        "latency_ms": random.randint(10, 500)
    }
    with open(log_file, "a") as f:
        f.write(json.dumps(data) + "\n")
    time.sleep(1)
