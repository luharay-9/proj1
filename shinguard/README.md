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
    - and a battery https://www.adafruit.com/product/3898 

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
    - Detect when the ball is kicked

- hardware_code folder has the repo copy of the device code
- shinguard folder is the actual flutter app