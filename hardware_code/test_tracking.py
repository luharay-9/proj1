import ast
import json
import math
import pathlib
import types
import unittest
from collections import deque


class FakeGPS:
    def __init__(self):
        self.sentences = deque()
        self.has_fix = False
        self.speed_knots = None
        self.latitude = 37.0
        self.longitude = -122.0
        self.altitude_m = None
        self.satellites = 0

    def update(self):
        if not self.sentences:
            return False
        kind, utc, value = self.sentences.popleft()
        self.nmea_sentence = '$GN{},{}.000,other fields'.format(kind, utc)
        self.has_fix = value is not None
        if kind == 'GGA' and self.has_fix:
            self.latitude, self.altitude_m, self.satellites = value
        if kind == 'RMC' and self.has_fix:
            self.speed_knots = value / 1.852
        return True


class TrackingTest(unittest.TestCase):
    def setUp(self):
        # Run the firmware loop and its real functions with simulated hardware.
        source = pathlib.Path(__file__).with_name('main.py').read_text()
        tree = ast.parse(source)
        tree.body = [
            node for node in tree.body
            if isinstance(node, ast.FunctionDef) or (
                isinstance(node, ast.Assign)
                and isinstance(node.targets[0], ast.Name)
                and isinstance(node.value, ast.Constant)
            )
        ]
        self.clock = 0
        self.gps = FakeGPS()
        self.bno = types.SimpleNamespace(
            acceleration=(0, 0, 9.81), linear_acceleration=(0, 0, 0),
            gyro=(0, 0, 0), magnetic=(3, 5, -30), quaternion=(0, 0, 0, 1),
        )
        self.service = types.SimpleNamespace(control=b'START', telemetry=None)
        self.ble = types.SimpleNamespace(connected=True, advertising=False)
        self.state = dict(
            json=json, math=math, time=types.SimpleNamespace(monotonic=lambda: self.clock),
        )
        exec(compile(tree, 'main.py', 'exec'), self.state)
        self.state.update(
            gps=self.gps, bno=self.bno, ble=self.ble, service=self.service,
            advertisement=object(), scan_response=b'',
        )

    def tick(self, second):
        self.clock = second
        self.service.telemetry = None
        self.state['run_once']()
        if self.service.telemetry is None:
            return None
        self.assertLessEqual(len(self.service.telemetry), 180)
        return json.loads(self.service.telemetry)

    def fix(self, speed, second, *, rmc_first=False):
        utc = '{:02}{:02}{:02}'.format(second // 3600, second // 60 % 60, second % 60)
        gga = ('GGA', utc, (37 + second / 10000, second, 8))
        rmc = ('RMC', utc, speed)
        self.gps.sentences.extend((rmc, gga) if rmc_first else (gga, rmc))
        self.assertNotEqual(self.tick(second)['f'], 2)
        packet = self.tick(second + .05)
        self.assertEqual(packet['f'], 2)
        self.assertEqual(packet['p'], [37 + second / 10000, -122, second])
        self.assertEqual(packet['sat'], 8)
        return packet

    def test_fixes_pair_the_current_speed_and_position_in_either_order(self):
        self.assertEqual(self.fix(12, 0)['v'], 12)
        second = self.fix(24, 1, rmc_first=True)
        self.assertEqual(second['v'], 24)
        self.assertEqual(second['ts'], 24)
        self.assertEqual(second['sc'], 0)
        self.assertEqual(self.fix(10, 2)['ts'], 24)

        self.gps.sentences.extend((('GGA', '000002', (37, 0, 8)), ('RMC', '000002', 60)))
        for second in (2.2, 2.25):
            self.assertNotEqual(self.tick(second)['f'], 2)
        self.assertEqual(self.state['top_speed'], 24)

    def test_sprints_require_consecutive_valid_fixes_and_use_hysteresis(self):
        speeds = [30, 10, 20, 23, 18, 24, 16, 21, 23, 25, 10]
        counts = [0, 0, 0, 1, 1, 1, 1, 1, 2, 2, 2]
        self.assertEqual([self.fix(speed, t)['sc'] for t, speed in enumerate(speeds)], counts)
        self.assertEqual(self.state['top_speed'], 30)

    def test_invalid_speed_fix_loss_and_time_gaps_break_sprint_candidates(self):
        self.fix(24, 0)
        self.assertIsNone(self.fix(100, 1)['v'])
        self.assertEqual(self.fix(25, 2)['sc'], 0)
        self.gps.sentences.append(('GGA', '000003', None))
        self.assertNotEqual(self.tick(3)['f'], 2)
        self.assertEqual(self.fix(25, 4)['sc'], 0)
        self.assertEqual(self.fix(25, 8)['sc'], 0)
        self.assertEqual(self.fix(25, 9)['sc'], 1)
        self.assertEqual(self.state['top_speed'], 25)

    def test_shots_count_once_per_kick_and_reset_between_sessions(self):
        self.bno.gyro = (10, 0, 0)
        self.assertEqual(self.tick(2)['sh'], 0)  # No previous reading for jerk.
        self.bno.acceleration = (3, 0, 9.81)  # Ordinary kick, then a stronger swing.
        packet = self.tick(2.05)
        self.assertEqual((packet['kc'], packet['sh']), (1, 0))
        self.bno.acceleration = (12, 0, 9.81)
        packet = self.tick(2.1)
        self.assertEqual((packet['kc'], packet['sh']), (1, 1))
        self.bno.acceleration = (24, 0, 9.81)
        self.assertEqual(self.tick(2.15)['sh'], 1)
        self.tick(2.6)  # A dropped reading interval cannot generate jerk.
        self.bno.acceleration = (40, 0, 9.81)
        self.assertEqual(self.tick(2.65)['sh'], 2)

        self.service.control = b'\xff'  # Malformed commands leave recording active.
        self.assertIsNotNone(self.tick(2.7))
        self.ble.connected = False
        self.ble.advertising = True
        self.assertIsNone(self.tick(3))
        self.assertEqual(self.service.control, b'IDLE')
        self.ble.connected = True
        self.assertIsNone(self.tick(3.1))
        self.service.control = b'START'
        packet = self.tick(3.2)
        self.assertEqual((packet['n'], packet['sh'], packet['kc']), (1, 0, 0))

    def test_missing_acceleration_does_not_create_a_kick_on_recovery(self):
        self.tick(1)
        self.bno.acceleration = (math.nan, 0, 0)
        self.tick(1.05)
        self.bno.acceleration = (30, 0, 0)
        self.bno.gyro = (10, 0, 0)
        self.assertEqual(self.tick(1.1)['kc'], 0)

    def test_retries_advertising_and_clears_unprocessed_start_on_disconnect(self):
        attempts = []

        def start_advertising(advertisement, *, scan_response):
            attempts.append(self.clock)
            if len(attempts) == 1:
                raise OSError("temporary BLE failure")
            self.ble.advertising = True

        self.ble.start_advertising = start_advertising
        self.ble.connected = False
        self.assertIsNone(self.tick(0))
        self.assertEqual(self.service.control, b'IDLE')
        self.tick(.05)
        self.tick(1)
        self.assertEqual(attempts, [0, 1])
        self.ble.connected = True
        self.assertIsNone(self.tick(1.05))

    def test_recording_exceeds_reported_sample_count_and_frames_stay_paired(self):
        imu_samples = 0
        gps_frames = 0
        for tick in range(1400):
            if tick % 20 == 0:
                utc = '00{:02}{:02}'.format(tick // 1200, tick // 20 % 60)
                self.gps.sentences.extend((('GGA', utc, (37, 5, 8)), ('RMC', utc, 30)))
            packet = self.tick(tick * .05)
            if packet['f'] == 0:
                sequence = packet['n']
            elif packet['f'] == 1:
                self.assertEqual(packet['n'], sequence)
                imu_samples += 1
            else:
                gps_frames += 1
        self.assertGreater(imu_samples, 507)
        self.assertEqual(gps_frames, 70)
        self.assertEqual(self.state['sprint_count'], 1)


if __name__ == '__main__':
    unittest.main()
