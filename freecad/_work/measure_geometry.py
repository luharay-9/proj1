import sys
sys.path.append('/Applications/FreeCAD.app/Contents/Resources/lib')
import FreeCAD as A,Part,json
D=A.openDocument('/Users/harrylu/Downloads/proj1/Shinguard CAD.FCStd')
for name in ['Pad002','Part__Feature188','Part__Feature314','Part__Feature315','Part__Feature316','PCB_Component001','Part__Feature355']:
 o=D.getObject(name); print('\nOBJECT',name,o.Label, 'placement',o.Placement)
 if hasattr(o,'Group'): print('CHILDREN',[(x.Name,x.Label) for x in o.Group])
 for i,f in enumerate(o.Shape.Faces):
  if f.Area>10:
   print(i+1,round(f.Area,2),str(f.Surface), 'center',f.CenterOfMass,'normal',f.normalAt(0,0))
