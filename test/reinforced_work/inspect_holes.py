import sys,json
sys.path.append('/Applications/FreeCAD.app/Contents/Resources/lib')
import FreeCAD as A,Part
p='/Users/harrylu/Downloads/proj1/test/'
d=A.openDocument(p+'Shinguard_Compact_Reinforced_Threaded.FCStd');s=d.BackCarrier.Shape
print('placement',d.BackCarrier.Placement,s.Placement,'faces',len(s.Faces),'solids',len(s.Solids),'vol',s.Volume,flush=True)
for r in [0,.8,1.0,1.2,1.34,1.4,1.5,1.6,1.7]:
 print(r,[s.isInside(A.Vector(4+r,-18,z),1e-6,True) for z in [1,1.1,1.2,1.3,1.4]],flush=True)
