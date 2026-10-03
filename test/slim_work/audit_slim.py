import sys,json,zipfile,hashlib
sys.path.append('/Applications/FreeCAD.app/Contents/Resources/lib')
import FreeCAD as A,Part
P='/Users/harrylu/Downloads/proj1/test/'
s=A.openDocument(P+'Shinguard_Compact_Reinforced_Threaded_Ready.FCStd')
c=A.openDocument(P+'Shinguard_Slim_Cable_Clearance_Core.FCStd')
d=A.openDocument(P+'Shinguard_Slim_Cable_Clearance.FCStd')
assert {(o.Name,o.TypeId) for o in c.Objects}=={(o.Name,o.TypeId) for o in d.Objects}
leaf=0
for o in s.Objects:
 if o.Name.startswith('Support') or o.Name in ['BackCarrier','ImpactShell'] or o.TypeId=='App::Part':continue
 n=d.getObject(o.Name);assert n is not None,o.Name
 if hasattr(o,'Shape'):
  assert abs(o.Shape.Volume-n.Shape.Volume)<1e-6,(o.Name,'volume')
  assert abs(o.Shape.Area-n.Shape.Area)<1e-6,(o.Name,'area')
  leaf+=1
for o in c.Objects:
 n=d.getObject(o.Name)
 if hasattr(o,'Placement'):assert str(o.Placement)==str(n.Placement),o.Name
 if hasattr(o,'Shape') and o.TypeId!='App::Part':
  assert abs(o.Shape.Volume-n.Shape.Volume)<1e-6,(o.Name,'GUI changed volume')
  assert abs(o.Shape.Area-n.Shape.Area)<1e-6,(o.Name,'GUI changed area')
for n in ['BackCarrier','ImpactShell']:
 shape=d.getObject(n).Shape;assert shape.isValid() and len(shape.Solids)==1
assert d.BackCarrier.Shape.common(d.ImpactShell.Shape).Volume<1e-5
b=Part.makeCompound([d.BackCarrier.Shape,d.ImpactShell.Shape]).optimalBoundingBox(False,False)
measures=[]
for x in [10,25,35,43,50,65,85]:
 line=Part.makeLine(A.Vector(x,0,0),A.Vector(x,0,35)).common(d.ImpactShell.Shape)
 thickness=sum(e.Length for e in line.Edges)
 assert abs(thickness-3.6)<.001
 measures.append({'x':x,'vertical_center_skin_mm':thickness})
path=P+'Shinguard_Slim_Cable_Clearance.FCStd'
with zipfile.ZipFile(path) as z:assert z.testzip() is None;assert 'GuiDocument.xml' in z.namelist()
r={'final_file':path,'unchanged_electronic_leaf_shapes':leaf,'GUI_save_geometry_unchanged':True,'valid_single_shell_solids':True,'shell_overlap_mm3':0,'envelope_mm':[b.XLength,b.YLength,b.ZLength],'skin_sections':measures,'sha256':hashlib.sha256(open(path,'rb').read()).hexdigest(),'GUI_state_saved_natively':True}
json.dump(r,open(P+'slim_saved_file_audit.json','w'),indent=2)
print('PASS final saved geometry',r['envelope_mm'],flush=True)
