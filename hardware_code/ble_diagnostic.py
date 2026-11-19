import sys
import time

import board
from adafruit_ble import BLERadio
from adafruit_ble.advertising import Advertisement
from adafruit_ble.advertising.standard import ProvideServicesAdvertisement
from adafruit_ble.services.nordic import UARTService


DEVICE_NAME = "ShinGuard-DIAG"

print("CircuitPython:", sys.implementation.version)
print("Board:", board.board_id)

ble = BLERadio()
ble.name = DEVICE_NAME

# Nordic UART is a known-good standard Adafruit service. This deliberately
# excludes the BNO085 and ShinGuard custom service from the test.
uart = UARTService()
advertisement = ProvideServicesAdvertisement(uart)
advertisement.short_name = "SG-DIAG"

scan_response = Advertisement()
scan_response.complete_name = DEVICE_NAME

print("BLE name:", ble.name)
print("Advertisement bytes:", len(bytes(advertisement)), bytes(advertisement))
print("Scan response bytes:", len(bytes(scan_response)), bytes(scan_response))


def advertise():
    try:
        ble.start_advertising(
            advertisement,
            scan_response=bytes(scan_response),
        )
    except Exception as error:
        print("start_advertising failed:", repr(error))
        raise
    print("Advertising:", ble.advertising)


advertise()
print("Scan for ShinGuard-DIAG in nRF Connect.")

was_connected = False
while True:
    connected = ble.connected
    if connected and not was_connected:
        print("Connected. Peer count:", len(ble.connections))
    elif not connected and was_connected:
        print("Disconnected.")
    if not connected and not ble.advertising:
        advertise()
    was_connected = connected
    time.sleep(0.25)
