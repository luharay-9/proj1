import sys,json
sys.path.append('/Applications/FreeCAD.app/Contents/Resources/lib')
import FreeCAD as A,Part
p='/Users/harrylu/Downloads/proj1/test/'
d=A.openDocument(p+'Shinguard_Compact_Reinforced_Threaded_Ready.FCStd')
for n in ['Part__Feature188','Part__Feature356']:
 o=d.getObject(n);pl=o.getGlobalPlacement();axis=pl.Rotation.multVec(A.Vector(0,0,1));found=set()
 print('BOARD',n,'local thickness',o.Shape.BoundBox.ZLength,flush=True)
 for f in o.Shape.Faces:
  if isinstance(f.Surface,Part.Cylinder) and 1.2<f.Surface.Radius<1.3:
   c=f.Surface.Center;k=tuple(round(v,4) for v in [c.x,c.y])
   if k in found:continue
   found.add(k);base=pl.multVec(A.Vector(c.x,c.y,0))
   line=Part.makeLine(base-axis*10,base+axis*4)
   sec=line.common(d.BackCarrier.Shape)
   print('hole',k,'world',base,'carrier material',[(round((e.Vertexes[0].Point-base).dot(axis),3),round((e.Vertexes[-1].Point-base).dot(axis),3)) for e in sec.Edges],flush=True)
