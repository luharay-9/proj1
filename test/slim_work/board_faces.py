import sys
sys.path.append('/Applications/FreeCAD.app/Contents/Resources/lib')
import FreeCAD as A,Part
D=A.openDocument('/Users/harrylu/Downloads/proj1/test/Shinguard_Compact_Reinforced_Threaded_Ready.FCStd')
for n in ['Part__Feature188','Part__Feature356']:
 s=D.getObject(n).Shape;b=s.BoundBox
 print(n,b.ZMin,b.ZMax,[(round(f.Area,2),round(f.CenterOfMass.z,4),f.normalAt(0,0).z) for f in s.Faces if isinstance(f.Surface,Part.Plane) and f.Area>100],flush=True)
