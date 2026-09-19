import sys,json
sys.path.append('/Applications/FreeCAD.app/Contents/Resources/lib')
import FreeCAD as A,Part
P='/Users/harrylu/Downloads/proj1/test/'
for file in ['Shinguard_CoreOnly_Compact.FCStd','Shinguard_CoreOnly_Compact_Repaired.FCStd']:
 d=A.openDocument(P+file)
 print(file,len(d.Objects),flush=True)
 for n in ['BackCarrier','ImpactShell']:
  o=d.getObject(n);print(n,o.Shape.isValid(),o.Shape.Volume,str(o.Shape.optimalBoundingBox(False,False)),flush=True)
 A.closeDocument(d.Name)
p=.5;rmin=1.5-0.541265877*p+.12;rmaj=1.62;rb=rmin-.06
pts=[A.Vector(rb,0,-.1875-.06/3**.5),A.Vector(rmaj,0,-.03125),A.Vector(rmaj,0,.03125),A.Vector(rb,0,.1875+.06/3**.5)]
w=Part.makePolygon(pts+[pts[0]])
h=Part.makeHelix(p,6,rb)
s=Part.Wire(h.Edges).makePipeShell([Part.Wire(w.Edges)],True,True)
print('threadtool',s.isValid(),len(s.Solids),s.Volume,flush=True)
s.exportBrep(P+'reinforced_work/threadtool.brep')
