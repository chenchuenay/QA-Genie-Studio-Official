#!/usr/bin/env python3
import subprocess
import time
import csv
import os

PACKAGE = "com.enaykumar.qagenie"
ACTIVITY = ".MainActivity"

# Tune these coordinates manually using Developer Options > Pointer Location
COORDS = {
    "module": (540, 405),
    "feature": (540, 699),
    "platform_web": (540, 1077),
    "platform_mobile": (230, 1077),
    "platform_api": (850, 1077),
    "constraints": (540, 1543),
    "generate": (540, 2043),
    "back": (84, 203),
    "got_it": (816, 2208),
}


def adb(cmd):
    subprocess.run(f"adb {cmd}", shell=True)


def tap(x, y):
    adb(f"shell input tap {x} {y}")


def type_text(text):
    escaped = text.replace("'", "\\'")
    adb(f"shell input text '{escaped}'")


def clear():
    adb("shell input keyevent KEYCODE_CTRL_A")
    adb("shell input keyevent KEYCODE_DEL")


def restart_app():
    adb(f"shell am force-stop {PACKAGE}")
    time.sleep(2)
    adb(f"shell am start -n {PACKAGE}/{ACTIVITY}")
    time.sleep(6)
    # Tap "Got it" if dialog appears (use a direct tap)
    tap(*COORDS["got_it"])
    time.sleep(1)


def run_variant(module, feature, platform, constraints):
    print(f"Running: {module}")
    tap(*COORDS["module"])
    time.sleep(1)
    clear()
    type_text(module)
    time.sleep(1)
    tap(*COORDS["feature"])
    time.sleep(1)
    clear()
    type_text(feature)
    time.sleep(1)
    if platform == "Web":
        tap(*COORDS["platform_web"])
    elif platform == "Mobile":
        tap(*COORDS["platform_mobile"])
    elif platform == "API":
        tap(*COORDS["platform_api"])
    time.sleep(1)
    tap(*COORDS["constraints"])
    time.sleep(1)
    clear()
    type_text(constraints)
    time.sleep(1)
    tap(*COORDS["generate"])
    print("Waiting 60 seconds for generation...")
    time.sleep(60)  # hard wait – simplest
    tap(*COORDS["back"])
    time.sleep(2)


def main():
    variants = []
    with open("variants.csv", newline="", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            variants.append(
                (row["module"], row["feature"], row["platform"], row["constraints"])
            )
    restart_app()
    for module, feature, platform, constraints in variants:
        run_variant(module, feature, platform, constraints)
    os.makedirs("dumps", exist_ok=True)
    adb("pull /storage/emulated/0/Download/QA_Genie_Forensics/ ./dumps/")
    print("Done.")


if __name__ == "__main__":
    main()
