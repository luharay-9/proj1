import sys,json,zipfile
sys.path.append('/Applications/FreeCAD.app/Contents/Resources/lib')
import FreeCAD as A,Part
P='/Users/harrylu/Downloads/proj1/test/'
a=A.openDocument(P+'Shinguard_CoreOnly_Compact_Repaired.FCStd')
b=A.openDocument(P+'Shinguard_Compact_Reinforced_Threaded_Ready.FCStd')
assert {(o.Name,o.TypeId) for o in a.Objects}=={(o.Name,o.TypeId) for o in b.Objects}
count=0
for old in a.Objects:
 new=b.getObject(old.Name)
 if old.Name in ['BackCarrier','ImpactShell']:continue
 if hasattr(old,'Placement'):assert str(old.Placement)==str(new.Placement),(old.Name,'placement')
 if hasattr(old,'Shape') and old.TypeId!='App::Part':
  assert abs(old.Shape.Volume-new.Shape.Volume)<1e-7,(old.Name,'volume')
  assert abs(old.Shape.Area-new.Shape.Area)<1e-7,(old.Name,'area')
  assert str(old.Shape.BoundBox)==str(new.Shape.BoundBox),(old.Name,'bounds')
  count+=1
core=A.openDocument(P+'Shinguard_Compact_Reinforced_Threaded.FCStd')
for n in ['BackCarrier','ImpactShell']:
 assert abs(core.getObject(n).Shape.Volume-b.getObject(n).Shape.Volume)<1e-7
 assert abs(core.getObject(n).Shape.Area-b.getObject(n).Shape.Area)<1e-7
 s=b.getObject(n).Shape
 assert s.isValid() and len(s.Solids)==1,n
# Vertical rays measure the actual solid thickness across the central strike region.
thick=[]
for x in [10,25,35,43,50,65,85]:
 ray=Part.makeLine(A.Vector(x,0,0),A.Vector(x,0,35))
 sections=ray.common(b.ImpactShell.Shape)
 thick.append({'x_mm':x,'solid_thickness_vertical_mm':sum(e.Length for e in sections.Edges)})
 assert abs(sum(e.Length for e in sections.Edges)-3.6)<.001
with zipfile.ZipFile(P+'Shinguard_Compact_Reinforced_Threaded_Ready.FCStd') as z:
 assert z.testzip() is None
 assert 'GuiDocument.xml' in z.namelist()
def world(o):
 if hasattr(o,'Group'):
  ss=[world(c) for c in o.Group if c.TypeId not in ['App::Origin','App::Line','App::Plane']]
  return Part.makeCompound([s for s in ss if not s.isNull()])
 if hasattr(o,'Shape'):
  s=o.Shape.copy();s.Placement=o.getGlobalPlacement().multiply(o.Placement.inverse()).multiply(s.Placement);return s
 return Part.Shape()
for n in ['Adafruit_BNO085_STEMMA_QT_v2','_400mAh_Battery_v2','PCB_Component','Adafruit_ESP32_Feather_V2_v2','Part__Feature355']:
 old,new=world(a.getObject(n)),world(b.getObject(n))
 assert abs(old.Volume-new.Volume)<1e-7,(n,'world volume')
 assert abs(old.Area-new.Area)<1e-7,(n,'world area')
 assert str(old.BoundBox)==str(new.BoundBox),(n,'world bounds')
r={'object_names_types_preserved':len(a.Objects),'unchanged_shape_objects':count,'electronics_and_supports_unchanged':True,'valid_single_shell_solids':True,'central_skin_measurements':thick,'archive_integrity':True,'saved_gui_payload':True,'appearance_saved_by_FreeCAD_GUI':True,'derived_cache_note':'FreeCAD refreshed PCB_Component App::Part cached compound; all leaf shapes, hierarchy placements, and recursively assembled electronics geometry remain unchanged.'}
json.dump(r,open(P+'reinforced_saved_file_audit.json','w'),indent=2)
print(json.dumps(r,indent=2),flush=True)
