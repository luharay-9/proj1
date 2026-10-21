import json
import math
import time

import board
import busio
try:
    import adafruit_gps
except ImportError:
    adafruit_gps = None
from adafruit_ble import BLERadio
from adafruit_ble.advertising import Advertisement
from adafruit_ble.advertising.standard import ProvideServicesAdvertisement
from adafruit_ble.characteristics import Characteristic
from adafruit_ble.services import Service
from adafruit_ble.uuid import VendorUUID
from adafruit_bno08x import (
    BNO_REPORT_ACCELEROMETER,
    BNO_REPORT_GYROSCOPE,
    BNO_REPORT_LINEAR_ACCELERATION,
    BNO_REPORT_MAGNETOMETER,
    BNO_REPORT_ROTATION_VECTOR,
)
from adafruit_bno08x.i2c import BNO08X_I2C


class ShinGuardService(Service):
    uuid = VendorUUID("4f3d0001-6847-4f1f-b4a8-5f12f735d201")

    telemetry = Characteristic(
        uuid=VendorUUID("4f3d0002-6847-4f1f-b4a8-5f12f735d201"),
        properties=Characteristic.READ | Characteristic.NOTIFY,
        max_length=180,
    )

    control = Characteristic(
        uuid=VendorUUID("4f3d0003-6847-4f1f-b4a8-5f12f735d201"),
        properties=Characteristic.READ | Characteristic.WRITE,
        initial_value=b"IDLE",
        max_length=20,
    )


DEVICE_NAME = "ShinGuard"
SAMPLE_INTERVAL = 0.05
REPORT_INTERVAL_US = 50000
MAX_TELEMETRY_BYTES = 180
GPS_UPDATE_INTERVAL_MS = 1000
SPRINT_START_KMH = 20.0
SPRINT_END_KMH = 17.0
KICK_JERK_THRESHOLD = 42.0
KICK_GYRO_THRESHOLD = 5.5


ble = BLERadio()
ble.name = DEVICE_NAME

i2c = busio.I2C(board.SCL, board.SDA, frequency=400000)
bno = BNO08X_I2C(i2c)
bno.enable_feature(BNO_REPORT_ACCELEROMETER, REPORT_INTERVAL_US)
bno.enable_feature(BNO_REPORT_LINEAR_ACCELERATION, REPORT_INTERVAL_US)
bno.enable_feature(BNO_REPORT_GYROSCOPE, REPORT_INTERVAL_US)
bno.enable_feature(BNO_REPORT_MAGNETOMETER, REPORT_INTERVAL_US)
bno.enable_feature(BNO_REPORT_ROTATION_VECTOR, REPORT_INTERVAL_US)
try:
    bno.begin_calibration()
    print("BNO085 dynamic calibration started")
except Exception as error:
    print("BNO085 calibration start failed:", repr(error))

# The PA1010D and BNO085 can share the Feather's STEMMA QT I2C bus. Their
# default addresses are different (0x10 and 0x4A), so no address changes or
# second cable bus are required.
try:
    if adafruit_gps is None:
        raise RuntimeError("adafruit_gps.mpy is not installed")
    gps = adafruit_gps.GPS_GtopI2C(i2c, debug=False)
    gps.send_command(
        b"PMTK314,0,1,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0"
    )
    gps.send_command(b"PMTK220,1000")
    print("PA1010D GPS enabled over I2C")
except Exception as error:
    gps = None
    print("PA1010D GPS unavailable; IMU recording will continue:", repr(error))

service = ShinGuardService()
advertisement = ProvideServicesAdvertisement(service)
advertisement.short_name = "ShinG"

scan_response = Advertisement()
scan_response.complete_name = DEVICE_NAME

print("Board BLE name:", ble.name)
print("BNO085 9-axis reports enabled at", REPORT_INTERVAL_US, "us")
print("Advertisement bytes:", len(bytes(advertisement)), bytes(advertisement))
print("Scan response bytes:", len(bytes(scan_response)), bytes(scan_response))

last_accel = (0.0, 0.0, 0.0)
last_time = time.monotonic()
last_kick_time = 0.0
session_active = False
sprint_count = 0
last_command = "IDLE"
sample_sequence = 0
frame_index = 0
pending_imu_sample = None
initial_gps_position = None
gps_position_pending = False
last_gps_fix = None
last_gps_time = None
sprint_active = False
sprint_candidate_count = 0
sprint_candidate_peak = 0.0
top_sprint_speed = 0.0


def magnitude(values):
    return math.sqrt(sum(component * component for component in values))


def rounded_tuple(values, digits=3):
    return tuple(round(component, digits) for component in values)


def read_bno():
    accel_ok = True
    try:
        accel = bno.acceleration
        if accel is None:
            accel = (0.0, 0.0, 0.0)
            accel_ok = False
    except Exception as error:
        accel = (0.0, 0.0, 0.0)
        accel_ok = False
        print("BNO085 acceleration read failed:", repr(error))

    try:
        linear_accel = bno.linear_acceleration or (0.0, 0.0, 0.0)
    except Exception:
        linear_accel = (0.0, 0.0, 0.0)

    try:
        gyro = bno.gyro or (0.0, 0.0, 0.0)
    except Exception:
        gyro = (0.0, 0.0, 0.0)

    try:
        magnetic = bno.magnetic or (0.0, 0.0, 0.0)
    except Exception:
        magnetic = (0.0, 0.0, 0.0)

    try:
        quat = bno.quaternion or (0.0, 0.0, 0.0, 1.0)
    except Exception:
        quat = (0.0, 0.0, 0.0, 1.0)

    return accel, linear_accel, gyro, magnetic, quat, accel_ok


def update_gps():
    if gps is None:
        return
    try:
        gps.update()
    except Exception as error:
        print("PA1010D update failed:", repr(error))


def capture_initial_gps_position():
    global initial_gps_position, gps_position_pending, last_gps_fix
    global sprint_active, sprint_candidate_count, sprint_candidate_peak
    global sprint_count, top_sprint_speed
    global last_gps_time

    if not session_active or gps is None:
        return
    try:
        if not gps.has_fix:
            sprint_active = False
            sprint_candidate_count = 0
            sprint_candidate_peak = 0.0
            return
        fix = tuple(gps.timestamp_utc) if gps.timestamp_utc else None
        if fix is None or fix == last_gps_fix:
            return
        last_gps_fix = fix
        now = time.monotonic()
        if last_gps_time is None or now - last_gps_time > 3:
            sprint_active = False
            sprint_candidate_count = 0
            sprint_candidate_peak = 0.0
        last_gps_time = now
        speed = gps.speed_knots
        speed_kmh = speed * 1.852 if speed is not None else None
        if speed_kmh is not None and 0 <= speed_kmh <= 60:
            if sprint_active and speed_kmh < SPRINT_END_KMH:
                sprint_active = False
                sprint_candidate_count = 0
                sprint_candidate_peak = 0.0
            if not sprint_active:
                if speed_kmh >= SPRINT_START_KMH:
                    sprint_candidate_count += 1
                    sprint_candidate_peak = max(sprint_candidate_peak, speed_kmh)
                    if sprint_candidate_count >= 2:
                        sprint_active = True
                        sprint_count += 1
                        top_sprint_speed = max(top_sprint_speed, sprint_candidate_peak)
                else:
                    sprint_candidate_count = 0
                    sprint_candidate_peak = 0.0
            if sprint_active:
                top_sprint_speed = max(top_sprint_speed, speed_kmh)
        else:
            speed_kmh = None
            sprint_active = False
            sprint_candidate_count = 0
            sprint_candidate_peak = 0.0
        altitude = gps.altitude_m
        initial_gps_position = {
            "t": round(now, 2),
            "p": (
                round(gps.latitude, 6),
                round(gps.longitude, 6),
                round(altitude, 1) if altitude is not None else None,
            ),
            "sat": gps.satellites or 0,
            "v": round(speed_kmh, 2) if speed_kmh is not None else None,
        }
        gps_position_pending = True
    except Exception as error:
        print("PA1010D fix read failed:", repr(error))


def build_sample():
    global last_accel, last_time, last_kick_time
    global sample_sequence

    now = time.monotonic()
    dt = max(now - last_time, 0.001)
    accel, linear_accel, gyro, magnetic, quat, accel_ok = read_bno()

    accel_g = magnitude(accel) / 9.80665
    gyro_mag = magnitude(gyro)
    jerk = magnitude(
        (
            (accel[0] - last_accel[0]) / dt,
            (accel[1] - last_accel[1]) / dt,
            (accel[2] - last_accel[2]) / dt,
        )
    )

    sprint_event = False

    kick = (
        session_active
        and jerk >= KICK_JERK_THRESHOLD
        and gyro_mag >= KICK_GYRO_THRESHOLD
        and now - last_kick_time > 0.45
    )
    if kick:
        last_kick_time = now

    last_accel = accel
    last_time = now
    sample_sequence += 1

    return {
        "n": sample_sequence,
        "t": round(now, 2),
        "a": rounded_tuple(accel, 2),
        "l": rounded_tuple(linear_accel, 2),
        "w": rounded_tuple(gyro, 3),
        "m": rounded_tuple(magnetic, 2),
        "q": rounded_tuple(quat, 4),
        "g": round(accel_g, 2),
        "sp": 1 if sprint_event else 0,
        "sc": sprint_count,
        "k": 1 if kick else 0,
        "ok": 1 if accel_ok else 0,
    }


def build_payload(sample):
    global frame_index

    if frame_index == 0:
        payload = {
            "f": 0,
            "n": sample["n"],
            "t": sample["t"],
            "a": sample["a"],
            "l": sample["l"],
            "w": sample["w"],
            "sp": sample["sp"],
            "sc": sample["sc"],
            "ok": sample["ok"],
            "ts": round(top_sprint_speed, 2),
        }
    else:
        payload = {
            "f": 1,
            "n": sample["n"],
            "t": sample["t"],
            "m": sample["m"],
            "q": sample["q"],
            "g": sample["g"],
            "sp": sample["sp"],
            "sc": sample["sc"],
            "k": sample["k"],
            "ts": round(top_sprint_speed, 2),
        }

    frame_index = 1 - frame_index
    encoded = json.dumps(payload, separators=(",", ":")).encode("utf-8")
    if len(encoded) > MAX_TELEMETRY_BYTES:
        print("Telemetry frame too large:", len(encoded))
        return None
    return encoded


def build_initial_position_payload():
    global gps_position_pending

    if not gps_position_pending or initial_gps_position is None:
        return None
    payload = {
        "f": 2,
        "t": initial_gps_position["t"],
        "p": initial_gps_position["p"],
        "sat": initial_gps_position["sat"],
        "v": initial_gps_position["v"],
        "sc": sprint_count,
        "ts": round(top_sprint_speed, 2),
    }
    encoded = json.dumps(payload, separators=(",", ":")).encode("utf-8")
    if len(encoded) > MAX_TELEMETRY_BYTES:
        print("GPS telemetry frame too large:", len(encoded))
        return None
    gps_position_pending = False
    return encoded


def handle_session_command():
    global last_command, session_active, sprint_count
    global sample_sequence, frame_index, pending_imu_sample
    global last_time, last_accel
    global initial_gps_position, gps_position_pending
    global last_gps_fix, sprint_active, sprint_candidate_count
    global sprint_candidate_peak, top_sprint_speed
    global last_gps_time

    command = bytes(service.control).decode("utf-8").strip().upper()
    if command == last_command:
        return

    last_command = command
    if command == "START":
        session_active = True
        sprint_count = 0
        sample_sequence = 0
        frame_index = 0
        pending_imu_sample = None
        last_time = time.monotonic()
        last_accel = (0.0, 0.0, 0.0)
        initial_gps_position = None
        gps_position_pending = False
        last_gps_fix = None
        last_gps_time = None
        sprint_active = False
        sprint_candidate_count = 0
        sprint_candidate_peak = 0.0
        top_sprint_speed = 0.0
        capture_initial_gps_position()
        print("Session started")
    elif command in ("STOP", "IDLE"):
        if session_active:
            print("Session stopped. Sprints:", sprint_count)
        session_active = False


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
    update_gps()

    if ble.connected:
        handle_session_command()
        if session_active:
            capture_initial_gps_position()
            payload = build_initial_position_payload()
            if payload is None:
                if frame_index == 0 or pending_imu_sample is None:
                    pending_imu_sample = build_sample()
                payload = build_payload(pending_imu_sample)
                if frame_index == 0:
                    pending_imu_sample = None
            if payload is not None:
                service.telemetry = payload
    elif session_active:
        session_active = False
        last_command = "IDLE"
        service.control = b"IDLE"
        print("Session cancelled because BLE disconnected")

    time.sleep(SAMPLE_INTERVAL)
