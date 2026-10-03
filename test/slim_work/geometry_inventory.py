import sys,json
sys.path.append('/Applications/FreeCAD.app/Contents/Resources/lib')
import FreeCAD as A,Part
p='/Users/harrylu/Downloads/proj1/test/'
d=A.openDocument(p+'Shinguard_Compact_Reinforced_Threaded_Ready.FCStd')
r=[]
for o in d.Objects:
 if o.TypeId=='App::Part' or o.Name in ['BackCarrier','ImpactShell'] or 'shell' in o.Name.lower() or o.Name.startswith('Support') or 'thread' in o.Label.lower():
  row={'name':o.Name,'type':o.TypeId,'label':o.Label,'children':[c.Name for c in getattr(o,'Group',[])],'placement':str(getattr(o,'Placement',None))}
  if hasattr(o,'Shape'):row.update(volume=o.Shape.Volume,bounds=str(o.Shape.optimalBoundingBox(False,False)))
  r.append(row)
json.dump(r,open(p+'slim_work/inventory.json','w'),indent=2)
for n in ['BackCarrier','ImpactShell']:
 o=d.getObject(n)
 print(n,o.Label,o.Shape.Volume,str(o.Shape.optimalBoundingBox(False,False)),flush=True)
for name in ['Part__Feature188','Part__Feature356']:
 o=d.getObject(name)
 print('BOARD',name,o.Label,o.getGlobalPlacement(),flush=True)
 for f in o.Shape.Faces:
  if isinstance(f.Surface,Part.Cylinder): print('CYL',f.Surface.Radius,f.Surface.Center,f.Surface.Axis,flush=True)
print('objects',len(d.Objects),flush=True)
