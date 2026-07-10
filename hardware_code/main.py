import json
import math
import time

import board
import busio
from adafruit_ble import BLERadio
from adafruit_ble.advertising import Advertisement
from adafruit_ble.advertising.standard import ProvideServicesAdvertisement
from adafruit_ble.characteristics import Characteristic
from adafruit_ble.characteristics.string import StringCharacteristic
from adafruit_ble.services import Service
from adafruit_ble.uuid import VendorUUID
from adafruit_bno08x import (
    BNO_REPORT_ACCELEROMETER,
    BNO_REPORT_GYROSCOPE,
    BNO_REPORT_ROTATION_VECTOR,
)
from adafruit_bno08x.i2c import BNO08X_I2C


class ShinGuardService(Service):
    uuid = VendorUUID("4f3d0001-6847-4f1f-b4a8-5f12f735d201")

    telemetry = StringCharacteristic(
        uuid=VendorUUID("4f3d0002-6847-4f1f-b4a8-5f12f735d201"),
        properties=Characteristic.READ | Characteristic.NOTIFY,
    )


DEVICE_NAME = "ShinGuard"
SAMPLE_INTERVAL = 0.05
SPIKE_G_THRESHOLD = 3.1
KICK_JERK_THRESHOLD = 42.0
KICK_GYRO_THRESHOLD = 5.5


ble = BLERadio()
ble.name = DEVICE_NAME

i2c = busio.I2C(board.SCL, board.SDA)
bno = BNO08X_I2C(i2c)
bno.enable_feature(BNO_REPORT_ACCELEROMETER)
bno.enable_feature(BNO_REPORT_GYROSCOPE)
bno.enable_feature(BNO_REPORT_ROTATION_VECTOR)

service = ShinGuardService()
advertisement = ProvideServicesAdvertisement(service)
advertisement.short_name = "ShinG"

scan_response = Advertisement()
scan_response.complete_name = DEVICE_NAME

print("Board BLE name:", ble.name)
print("Advertisement bytes:", len(bytes(advertisement)), bytes(advertisement))
print("Scan response bytes:", len(bytes(scan_response)), bytes(scan_response))

last_accel = (0.0, 0.0, 0.0)
last_time = time.monotonic()
last_kick_time = 0.0


def magnitude(values):
    return math.sqrt(sum(component * component for component in values))


def rounded_tuple(values, digits=3):
    return tuple(round(component, digits) for component in values)


def read_bno():
    try:
        accel = bno.acceleration
    except Exception:
        accel = (0.0, 0.0, 0.0)

    try:
        gyro = bno.gyro
    except Exception:
        gyro = (0.0, 0.0, 0.0)

    try:
        quat = bno.quaternion
    except Exception:
        quat = (0.0, 0.0, 0.0, 1.0)

    return accel, gyro, quat


def build_payload():
    global last_accel, last_time, last_kick_time

    now = time.monotonic()
    dt = max(now - last_time, 0.001)
    accel, gyro, quat = read_bno()

    accel_g = magnitude(accel) / 9.80665
    gyro_mag = magnitude(gyro)
    jerk = magnitude(
        (
            (accel[0] - last_accel[0]) / dt,
            (accel[1] - last_accel[1]) / dt,
            (accel[2] - last_accel[2]) / dt,
        )
    )

    spike = accel_g >= SPIKE_G_THRESHOLD
    kick = (
        jerk >= KICK_JERK_THRESHOLD
        and gyro_mag >= KICK_GYRO_THRESHOLD
        and now - last_kick_time > 0.45
    )
    if kick:
        last_kick_time = now

    last_accel = accel
    last_time = now

    return {
        "t": round(now, 3),
        "accel": rounded_tuple(accel),
        "accel_g": round(accel_g, 3),
        "gyro": rounded_tuple(gyro),
        "gyro_mag": round(gyro_mag, 3),
        "quat": rounded_tuple(quat, 4),
        "jerk": round(jerk, 3),
        "motion_spike": spike,
        "kick": kick,
        "field_position": None,
    }


def advertise_if_needed():
    if not ble.connected and not ble.advertising:
        try:
            # Keep a short name in the primary packet so passive scans can
            # identify us, and put the complete name in the scan response.
            ble.start_advertising(
                advertisement,
                scan_response=bytes(scan_response),
            )
            print("Advertising:", ble.advertising)
        except Exception as error:
            print("BLE advertising failed:", repr(error))
            raise


while True:
    advertise_if_needed()

    if ble.connected:
        payload = json.dumps(build_payload(), separators=(",", ":"))
        service.telemetry = payload

    time.sleep(SAMPLE_INTERVAL)
