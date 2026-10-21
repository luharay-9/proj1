"""Build a tighter-wrap revision without changing the saved slim source.

Supply the chosen shin-fit radius explicitly in millimeters. The existing
builder recalculates both skins, rigid component tilts, fitted supports,
blind board posts, and shell fasteners from that radius.
"""
import argparse
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument('--radius-mm', type=float, required=True)
args = parser.parse_args()
if not 50 <= args.radius_mm < 150:
    parser.error('This builder supports wrap radii from 50 to below 150 mm.')

root = Path(__file__).resolve().parents[1]
source_script = root / 'slim_work' / 'build_slim.py'
code = source_script.read_text()
replacements = {
    "SOURCE=P+'Shinguard_Compact_Reinforced_Threaded_Ready.FCStd'":
        "SOURCE=P+'Shinguard_Slim_Cable_Clearance.FCStd'",
    "TARGET=P+'Shinguard_Slim_Cable_Clearance_Core.FCStd'":
        "TARGET=P+'Shinguard_Conforming_Wrap_Core.FCStd'",
    "A.newDocument('Shinguard_Slim_Cable_Clearance')":
        "A.newDocument('Shinguard_Conforming_Wrap')",
    "D.Label='Slim shinguard - deeper M2.5 board mounts / cable clearance'":
        "D.Label='Conforming shinguard - tighter wrap and angled mounts'",
    'R=150.;': f'R={args.radius_mm!r};',
    "P+'slim_work/": "P+'wrap_work/",
    '01 - Slim leg carrier': '01 - Conforming leg carrier',
    '02 - Slim impact cover': '02 - Conforming impact cover',
    'Built slim candidate': 'Built conforming-wrap candidate',
    "'wrap_radius_before_mm':110": "'wrap_radius_before_mm':150",
    'Slim_Threaded_Carrier': 'Wrap_Threaded_Carrier',
    'Slim_Impact_Shell': 'Wrap_Impact_Shell',
    "P+'slim_validation.json'": "P+'wrap_validation.json'",
    'Shape=ob.Shape,LinearDeflection': 'Shape=ob.Shape.cleaned(),LinearDeflection',
    'impact_skin.makeFillet(.3,impact_skin.Edges)': 'impact_skin.makeFillet(.2,impact_skin.Edges)',
}
for old, new in replacements.items():
    if old not in code:
        raise RuntimeError(f'Expected source fragment missing: {old}')
    code = code.replace(old, new)

# Preserve successful geometric measurements even if a later mesh export
# needs its own repair. A saved candidate is not yet a delivered final file.
code = code.replace(
    'import MeshPart\nfor ob,stem',
    "json.dump(report,open(P+'wrap_validation.json','w'),indent=2)\n"
    'import MeshPart\nfor ob,stem',
)
exec(compile(code, str(source_script), 'exec'), {'__name__': '__main__'})
