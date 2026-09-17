import sys,json
sys.path.append('/Applications/FreeCAD.app/Contents/Resources/lib')
import FreeCAD as A,Part
P='/Users/harrylu/Downloads/proj1/test/'
D=A.openDocument(P+'Shinguard_Redesigned_CoreOnly.FCStd')
r=[]
for o in D.Objects:
 row={'name':o.Name,'label':o.Label,'type':o.TypeId,'parents':[p.Name for p in o.InList]}
 if hasattr(o,'Placement'):row['placement']=str(o.Placement)
 if hasattr(o,'Shape') and not o.Shape.isNull():
  b=o.Shape.BoundBox;row['bounds']=[b.XMin,b.YMin,b.ZMin,b.XMax,b.YMax,b.ZMax];row['solids']=len(o.Shape.Solids);row['volume']=o.Shape.Volume
 if hasattr(o,'Group'):row['group']=[x.Name for x in o.Group]
 r.append(row)
json.dump(r,open(P+'core_inventory.json','w'),indent=2)
print(json.dumps([o for o in r if not o['parents']],indent=2))
