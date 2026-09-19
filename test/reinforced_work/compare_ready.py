import sys
sys.path.append('/Applications/FreeCAD.app/Contents/Resources/lib')
import FreeCAD as A,Part
p='/Users/harrylu/Downloads/proj1/test/'
a=A.openDocument(p+'Shinguard_Compact_Reinforced_Threaded.FCStd');b=A.openDocument(p+'Shinguard_Compact_Reinforced_Threaded_Ready.FCStd')
for o in a.Objects:
 n=b.getObject(o.Name)
 if hasattr(o,'Placement') and str(o.Placement)!=str(n.Placement):print('PLACEMENT',o.Name,o.Placement,n.Placement,flush=True)
 if hasattr(o,'Shape'):
  av,bv=o.Shape.Volume,n.Shape.Volume
  if abs(av-bv)>1e-7 or abs(o.Shape.Area-n.Shape.Area)>1e-7:
   print('SHAPE',o.Name,o.TypeId,'children',len(getattr(o,'Group',[])), 'vol',av,bv,'area',o.Shape.Area,n.Shape.Area,'bounds',o.Shape.BoundBox,n.Shape.BoundBox,flush=True)
