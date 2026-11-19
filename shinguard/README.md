# shinguard

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.


# ShinGuard Hardware Behavior
- CircuitPython 10
- Hardware:
    - the esp32-s3 feather. https://www.adafruit.com/product/5477 
    - a bno085 https://www.adafruit.com/product/4754 
    - a stemma cable https://www.adafruit.com/product/4399 
    - an Adafruit Mini GPS PA1010D https://www.adafruit.com/product/4415
    - and a battery https://www.adafruit.com/product/3898 

### Firmware setup

1. Connect both the BNO085 and PA1010D to the ESP32-S3 Feather's shared
   STEMMA QT I2C bus. The default addresses do not conflict.
2. From the matching CircuitPython library bundle, copy `adafruit_bno08x`,
   `adafruit_ble`, and `adafruit_gps.mpy` (plus their documented dependencies)
   into the board's `CIRCUITPY/lib` directory.
3. Copy `hardware_code/main.py` to the board as `code.py`, then reboot it.
4. Forget/reconnect the ShinGuard in the phone's Bluetooth settings after a
   firmware update so the OS refreshes the BLE characteristic cache.

When the app sends `START`, firmware resets the session counters, begins BNO085
acceleration telemetry, and pairs PA1010D position and speed reports for each
1 Hz GPS fix. The app enters its recording state once it receives a healthy
BNO sample. Each session saves its GPS route in 300-point Firestore chunks,
along with its initial fix, BNO sample count, peak acceleration, top speed,
sprint count, and estimated shots.

Top speed is the highest valid GPS ground speed during the session, in km/h.
The firmware accepts speeds from 0 to 60 km/h. A sprint starts after two
consecutive fixes at or above 20 km/h and ends below 17 km/h. Fix loss, invalid
speed, or a gap over three seconds resets sprint detection. Top speed can be
recorded during a session with zero sprints.

The BNO085 estimates kicks from acceleration jerk and angular speed. It counts
an estimated shot once when a kick reaches both the higher thresholds of
100 m/s³ and 8 rad/s. The estimate measures motion on the instrumented leg.
Its accuracy needs validation against observed shots in outdoor recordings.

The Timeline heatmap uses a north-up local GPS route and 5-meter cells. Each entry
into a cell counts as one visit; staying in the cell adds samples, not visits.
Colors range from green (one visit) through yellow to red (the most repeated area
in that session). Unvisited cells have no heat color. Tap a cell for its counts.
The Route switch shows or hides the recorded path, with gaps where fixes were
more than three seconds apart.

- First Connection:
    1. User logs in and (only AFTER verification) they see an onboarding set of screens which has the following:
        1. Welcome Screen
        2-X. Questionnaire (user metrics, etc); answers can be viewed/editted in the Profile Screen
        Y. Connection prompt in the home screen (uses BLE)
            - auto-connect in subsequent app opens if the devices are detected
    2. Device will be continuously stream data to the app as needed.

- Device Removal:
    1. Manage Device in setings screen

- What the ShinGuard is actually monitoring
    - format raw sensor data to something the app can use
    - flag motion spikes
    - *GPS sensor: field position
    - Estimate kicks and shots from leg motion

- hardware_code folder has the repo copy of the device code
- shinguard folder is the actual flutter app

Case Measurements:
- 10-12 mm max thickness
- Trapezoidal shape
- Height: 9.5 cm
- Width: 5.75 cm at widest point
- Width: 4 cm at narrowest point

Case materials: TPU on outside, PLA on inside
