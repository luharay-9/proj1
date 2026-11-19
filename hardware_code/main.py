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


MAX_TELEMETRY_BYTES = 180


class ShinGuardService(Service):
    uuid = VendorUUID("4f3d0001-6847-4f1f-b4a8-5f12f735d201")

    telemetry = Characteristic(
        uuid=VendorUUID("4f3d0002-6847-4f1f-b4a8-5f12f735d201"),
        properties=Characteristic.READ | Characteristic.NOTIFY,
        max_length=MAX_TELEMETRY_BYTES,
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
GPS_FIX_GAP_SECONDS = 3
MAX_SPEED_KMH = 60.0
SPRINT_START_KMH = 20.0
SPRINT_END_KMH = 17.0
KICK_JERK_THRESHOLD = 42.0
KICK_GYRO_THRESHOLD = 5.5
KICK_COOLDOWN_SECONDS = 0.45
# Provisional thresholds for a high-intensity kick from the instrumented leg.
SHOT_JERK_THRESHOLD = 100.0
SHOT_GYRO_THRESHOLD = 8.0


ble = BLERadio()
ble.name = DEVICE_NAME

try:
    i2c = busio.I2C(board.SCL, board.SDA, frequency=400000)
except Exception as error:
    i2c = None
    print("Sensor bus unavailable:", repr(error))

bno = None
if i2c is not None:
    try:
        bno = BNO08X_I2C(i2c)
        bno.enable_feature(BNO_REPORT_ACCELEROMETER, REPORT_INTERVAL_US)
        bno.enable_feature(BNO_REPORT_LINEAR_ACCELERATION, REPORT_INTERVAL_US)
        bno.enable_feature(BNO_REPORT_GYROSCOPE, REPORT_INTERVAL_US)
        bno.enable_feature(BNO_REPORT_MAGNETOMETER, REPORT_INTERVAL_US)
        bno.enable_feature(BNO_REPORT_ROTATION_VECTOR, REPORT_INTERVAL_US)
        print("BNO085 9-axis reports enabled at", REPORT_INTERVAL_US, "us")
    except Exception as error:
        bno = None
        print("BNO085 setup failed:", repr(error))
    if bno is not None:
        try:
            bno.begin_calibration()
            print("BNO085 dynamic calibration started")
        except Exception as error:
            print("BNO085 calibration start failed:", repr(error))

# The PA1010D and BNO085 can share the Feather's STEMMA QT I2C bus. Their
# default addresses are different (0x10 and 0x4A), so no address changes or
# second cable bus are required.
gps = None
if i2c is not None:
    try:
        if adafruit_gps is None:
            raise RuntimeError("adafruit_gps.mpy is not installed")
        gps = adafruit_gps.GPS_GtopI2C(i2c, debug=False, timeout=0.02)
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
print("Advertisement bytes:", len(bytes(advertisement)), bytes(advertisement))
print("Scan response bytes:", len(bytes(scan_response)), bytes(scan_response))

last_accel = None
last_time = None
last_kick_time = None
kick_active = False
shot_pending = False
kick_count = 0
shot_count = 0
session_active = False
sprint_count = 0
sample_sequence = 0
frame_index = 0
pending_imu_sample = None
pending_gps_position = None
next_advertise_attempt = 0.0
gps_sentence_type = None
gps_sentence_time = None
gps_sentence_received_at = None
last_gps_fix = None
last_gps_time = None
sprint_active = False
sprint_candidate_count = 0
top_speed = 0.0


def magnitude(values):
    return math.sqrt(sum(component * component for component in values))


def rounded_tuple(values, digits=3):
    return tuple(round(component, digits) for component in values)


def read_bno_report(name, length):
    try:
        report = getattr(bno, name)
        if (report is not None and len(report) == length
                and all(math.isfinite(value) for value in report)):
            return report
    except Exception as error:
        if name == "acceleration" and last_accel is not None:
            print("BNO085 acceleration read failed:", repr(error))
    return None


def update_gps():
    global gps_sentence_type, gps_sentence_time, gps_sentence_received_at

    if gps is None:
        return
    try:
        if not gps.update():
            return
        # GGA supplies fix quality and altitude. RMC supplies ground speed.
        # Both update the driver's timestamp, so wait for the matching pair.
        sentence = gps.nmea_sentence
        sentence_type = sentence[3:6]
        if sentence_type not in ("GGA", "RMC"):
            return
        if not gps.has_fix:
            gps_sentence_type = None
            reset_sprint()
            return
        fix_time = sentence.split(",", 2)[1][:6]
        if len(fix_time) != 6 or not fix_time.isdigit():
            return
        now = time.monotonic()
        if (gps_sentence_type is not None
                and gps_sentence_type != sentence_type
                and gps_sentence_time == fix_time
                and now - gps_sentence_received_at <= GPS_FIX_GAP_SECONDS):
            if session_active:
                capture_gps_fix(fix_time, now)
            gps_sentence_type = None
        else:
            gps_sentence_type = sentence_type
            gps_sentence_time = fix_time
            gps_sentence_received_at = now
    except Exception as error:
        print("PA1010D update failed:", repr(error))


def reset_sprint():
    global sprint_active, sprint_candidate_count

    sprint_active = False
    sprint_candidate_count = 0


def capture_gps_fix(fix_time, now):
    global pending_gps_position, last_gps_fix, last_gps_time, top_speed
    global sprint_active, sprint_candidate_count, sprint_count

    if fix_time == last_gps_fix:
        return
    latitude = gps.latitude
    longitude = gps.longitude
    if (latitude is None or longitude is None
            or not (-90 <= latitude <= 90 and -180 <= longitude <= 180)):
        reset_sprint()
        return

    if last_gps_time is None or now - last_gps_time > GPS_FIX_GAP_SECONDS:
        reset_sprint()
    last_gps_fix = fix_time
    last_gps_time = now
    speed = gps.speed_knots
    speed_kmh = speed * 1.852 if speed is not None else None
    if speed_kmh is None or not 0 <= speed_kmh <= MAX_SPEED_KMH:
        speed_kmh = None
        reset_sprint()
    else:
        top_speed = max(top_speed, speed_kmh)
        if sprint_active:
            if speed_kmh < SPRINT_END_KMH:
                reset_sprint()
        elif speed_kmh >= SPRINT_START_KMH:
            sprint_candidate_count += 1
            if sprint_candidate_count == 2:
                sprint_active = True
                sprint_count += 1
        else:
            sprint_candidate_count = 0

    altitude = gps.altitude_m
    pending_gps_position = {
        "t": round(now, 2),
        "p": (
            round(latitude, 6),
            round(longitude, 6),
            round(altitude, 1) if altitude is not None and math.isfinite(altitude) else None,
        ),
        "sat": gps.satellites or 0,
        "v": round(speed_kmh, 2) if speed_kmh is not None else None,
    }


def build_sample():
    global last_accel, last_time, last_kick_time
    global kick_active, shot_pending, kick_count, shot_count
    global sample_sequence

    now = time.monotonic()
    zero = (0.0, 0.0, 0.0)
    accel, linear_accel, gyro, magnetic = None, zero, None, zero
    quat = (0.0, 0.0, 0.0, 1.0)
    if bno is not None:
        accel = read_bno_report("acceleration", 3)
        linear_accel = read_bno_report("linear_acceleration", 3) or zero
        gyro = read_bno_report("gyro", 3)
        magnetic = read_bno_report("magnetic", 3) or zero
        quat = read_bno_report("quaternion", 4) or quat

    accel_g = magnitude(accel) / 9.80665 if accel is not None else 0.0
    gyro_mag = magnitude(gyro) if gyro is not None else 0.0
    jerk = 0.0
    if accel is not None and last_accel is not None:
        dt = now - last_time
        if 0 < dt <= 3 * SAMPLE_INTERVAL:
            delta = (
                accel[0] - last_accel[0],
                accel[1] - last_accel[1],
                accel[2] - last_accel[2],
            )
            jerk = magnitude(delta) / dt

    kick_motion = jerk >= KICK_JERK_THRESHOLD and gyro_mag >= KICK_GYRO_THRESHOLD
    kick = (
        session_active
        and kick_motion
        and not kick_active
        and (last_kick_time is None or now - last_kick_time >= KICK_COOLDOWN_SECONDS)
    )
    if kick:
        last_kick_time = now
        kick_count += 1
        shot_pending = True
    if not kick_motion:
        shot_pending = False
    if (shot_pending and jerk >= SHOT_JERK_THRESHOLD
            and gyro_mag >= SHOT_GYRO_THRESHOLD):
        shot_count += 1
        shot_pending = False

    kick_active = kick_motion
    last_accel = accel
    last_time = now
    sample_sequence += 1

    return {
        "n": sample_sequence,
        "t": round(now, 2),
        "a": rounded_tuple(accel or zero, 2),
        "l": rounded_tuple(linear_accel, 2),
        "w": rounded_tuple(gyro or zero, 3),
        "m": rounded_tuple(magnetic, 2),
        "q": rounded_tuple(quat, 4),
        "g": round(accel_g, 2),
        "k": 1 if kick else 0,
        "ok": 1 if accel is not None else 0,
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
            "ok": sample["ok"],
        }
    else:
        payload = {
            "f": 1,
            "n": sample["n"],
            "t": sample["t"],
            "m": sample["m"],
            "q": sample["q"],
            "g": sample["g"],
            "k": sample["k"],
        }

    frame_index = 1 - frame_index
    return encode_telemetry(payload)


def build_gps_payload():
    global pending_gps_position

    if pending_gps_position is None:
        return None
    payload = pending_gps_position
    pending_gps_position = None
    payload["f"] = 2
    return encode_telemetry(payload)


def encode_telemetry(payload):
    payload["sc"] = sprint_count
    payload["ts"] = round(top_speed, 2)
    payload["kc"] = kick_count
    payload["sh"] = shot_count
    encoded = json.dumps(payload, separators=(",", ":")).encode("utf-8")
    if len(encoded) > MAX_TELEMETRY_BYTES:
        print("Telemetry frame too large:", len(encoded))
        return None
    return encoded


def handle_session_command():
    global session_active, sprint_count, kick_count, shot_count
    global sample_sequence, frame_index, pending_imu_sample
    global last_time, last_accel, last_kick_time, kick_active, shot_pending
    global pending_gps_position, gps_sentence_type
    global last_gps_fix, last_gps_time, top_speed

    command = bytes(service.control).strip().upper()
    if command == b"START" and not session_active:
        session_active = True
        sprint_count = 0
        kick_count = 0
        shot_count = 0
        sample_sequence = 0
        frame_index = 0
        pending_imu_sample = None
        last_time = None
        last_accel = None
        last_kick_time = None
        kick_active = False
        shot_pending = False
        pending_gps_position = None
        gps_sentence_type = None
        last_gps_fix = None
        last_gps_time = None
        reset_sprint()
        top_speed = 0.0
        print("Session started")
    elif session_active and command in (b"STOP", b"IDLE"):
        session_active = False
        print("Session stopped. Sprints:", sprint_count, "Estimated shots:", shot_count)


def advertise_if_needed():
    global next_advertise_attempt

    now = time.monotonic()
    if ble.advertising or now < next_advertise_attempt:
        return
    try:
        # Use the scan response to fit the complete name alongside the service UUID.
        ble.start_advertising(advertisement, scan_response=bytes(scan_response))
        print("Advertising:", ble.advertising)
    except (OSError, RuntimeError, MemoryError) as error:
        next_advertise_attempt = now + 1
        print("BLE advertising failed:", repr(error))


def run_once():
    global session_active, pending_imu_sample

    if ble.connected:
        handle_session_command()
        update_gps()
        if session_active:
            # Sample at the sensor rate even when the BLE slot is used by GPS
            # or by the second notification for an earlier IMU sample.
            sample = build_sample()
            payload = build_gps_payload()
            if payload is None:
                if frame_index == 0:
                    pending_imu_sample = sample
                payload = build_payload(pending_imu_sample)
                if frame_index == 0:
                    pending_imu_sample = None
            if payload is not None:
                try:
                    service.telemetry = payload
                except (OSError, RuntimeError, MemoryError) as error:
                    print("BLE telemetry write failed:", repr(error))
    else:
        if session_active:
            session_active = False
            print("Session cancelled because BLE disconnected")
        if bytes(service.control) != b"IDLE":
            service.control = b"IDLE"
        advertise_if_needed()
        update_gps()


while True:
    loop_start = time.monotonic()
    run_once()
    time.sleep(max(0.0, SAMPLE_INTERVAL - (time.monotonic() - loop_start)))
