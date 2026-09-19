import sys,json,zipfile
sys.path.append('/Applications/FreeCAD.app/Contents/Resources/lib')
import FreeCAD as A,Part
P='/Users/harrylu/Downloads/proj1/test/'
a=A.openDocument(P+'Shinguard_CoreOnly_Compact_Repaired.FCStd')
b=A.openDocument(P+'Shinguard_Compact_Reinforced_Threaded.FCStd')
assert {(o.Name,o.TypeId) for o in a.Objects}=={(o.Name,o.TypeId) for o in b.Objects}
count=0
for old in a.Objects:
 new=b.getObject(old.Name)
 if old.Name in ['BackCarrier','ImpactShell']:continue
 if hasattr(old,'Placement'):assert str(old.Placement)==str(new.Placement),(old.Name,'placement')
 if hasattr(old,'Shape'):
  assert abs(old.Shape.Volume-new.Shape.Volume)<1e-7,(old.Name,'volume')
  assert abs(old.Shape.Area-new.Shape.Area)<1e-7,(old.Name,'area')
  assert str(old.Shape.BoundBox)==str(new.Shape.BoundBox),(old.Name,'bounds')
  count+=1
for n in ['BackCarrier','ImpactShell']:
 s=b.getObject(n).Shape
 assert s.isValid() and len(s.Solids)==1,n
# Vertical rays measure the actual solid thickness across the central strike region.
thick=[]
for x in [10,25,35,43,50,65,85]:
 ray=Part.makeLine(A.Vector(x,0,0),A.Vector(x,0,35))
 sections=ray.common(b.ImpactShell.Shape)
 thick.append({'x_mm':x,'solid_thickness_vertical_mm':sum(e.Length for e in sections.Edges)})
 assert abs(sum(e.Length for e in sections.Edges)-3.6)<.001
with zipfile.ZipFile(P+'Shinguard_Compact_Reinforced_Threaded.FCStd') as z:
 assert z.testzip() is None
 assert 'GuiDocument.xml' not in z.namelist()
r={'object_names_types_preserved':len(a.Objects),'unchanged_shape_objects':count,'electronics_and_supports_unchanged':True,'valid_single_shell_solids':True,'central_skin_measurements':thick,'archive_integrity':True,'saved_gui_payload':False}
json.dump(r,open(P+'reinforced_saved_file_audit.json','w'),indent=2)
print(json.dumps(r,indent=2),flush=True)
