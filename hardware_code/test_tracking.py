import ast
import pathlib
import types
import unittest


class TrackingTest(unittest.TestCase):
    def setUp(self):
        # Exercise firmware functions without importing physical board drivers.
        source = pathlib.Path(__file__).with_name('main.py').read_text()
        tree = ast.parse(source)
        names = {'capture_initial_gps_position', 'build_initial_position_payload'}
        functions = ast.Module(body=[node for node in tree.body
            if isinstance(node, ast.FunctionDef) and node.name in names], type_ignores=[])
        import json
        self.clock = 0
        self.gps = types.SimpleNamespace(has_fix=True, timestamp_utc=None,
            speed_knots=0, latitude=37, longitude=-122, altitude_m=5, satellites=8)
        self.state = dict(gps=self.gps, time=types.SimpleNamespace(monotonic=lambda: self.clock),
            json=json, session_active=True, initial_gps_position=None,
            gps_position_pending=False, last_gps_fix=None, last_gps_time=None,
            sprint_active=False, sprint_candidate_count=0, sprint_candidate_peak=0,
            sprint_count=0, top_sprint_speed=0, SPRINT_START_KMH=20,
            SPRINT_END_KMH=17, MAX_TELEMETRY_BYTES=180)
        exec(compile(functions, 'main.py', 'exec'), self.state)

    def fix(self, speed, second):
        self.clock = second
        self.gps.timestamp_utc = (second,)
        self.gps.speed_knots = speed / 1.852
        self.state['capture_initial_gps_position']()

    def test_fastest_sprint_and_fresh_route_frames(self):
        for second, speed in enumerate([10, 22, 24, 30, 16, 21, 23, 25, 10]):
            self.fix(speed, second)
            payload = self.state['build_initial_position_payload']()
            self.assertIsNotNone(payload)
            self.assertLessEqual(len(payload), 180)
        self.assertEqual(self.state['sprint_count'], 2)
        self.assertAlmostEqual(self.state['top_sprint_speed'], 30)
        self.state['capture_initial_gps_position']()
        self.assertIsNone(self.state['build_initial_position_payload']())

    def test_one_spike_and_gaps_do_not_make_a_sprint(self):
        self.fix(30, 0)
        self.fix(10, 1)
        self.fix(22, 2)
        self.fix(23, 8)
        self.assertEqual(self.state['sprint_count'], 0)
        self.assertEqual(self.state['top_sprint_speed'], 0)
        self.gps.has_fix = False
        self.state['capture_initial_gps_position']()
        self.assertFalse(self.state['sprint_active'])


if __name__ == '__main__':
    unittest.main()
