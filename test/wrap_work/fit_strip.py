"""Export a small 60 mm-radius contact strip, oriented flat for printing."""
import sys
from pathlib import Path
sys.path.append('/Applications/FreeCAD.app/Contents/Resources/lib')
import FreeCAD as App
import Part, MeshPart, Mesh

root = Path(__file__).resolve().parents[1]
V = App.Vector
radius = 60.0
width = 68.64476218051665
strip = Part.makeCylinder(radius + 2, 8, V(0, 0, -radius), V(1, 0, 0))
strip = strip.cut(Part.makeCylinder(radius, 8, V(0, 0, -radius), V(1, 0, 0)))
strip = strip.common(Part.makeBox(8, width, 25, V(0, -width / 2, -20)))
assert strip.isValid() and len(strip.Solids) == 1
strip.rotate(V(0, 0, 0), V(0, 1, 0), 90)
strip.translate(V(0, 0, 8))
mesh = MeshPart.meshFromShape(Shape=strip, LinearDeflection=.02,
                              AngularDeflection=.1, Relative=False)
mesh.removeDuplicatedPoints()
assert mesh.isSolid()
output = root / 'Wrap_R60_Fit_Strip.stl'
mesh.write(str(output))
assert Mesh.Mesh(str(output)).isSolid()
print('PASS: radius 60 mm, width %.3f mm, strip depth 8 mm' % width, flush=True)
