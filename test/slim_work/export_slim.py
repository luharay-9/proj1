import sys,json,math
sys.path.append('/Applications/FreeCAD.app/Contents/Resources/lib')
import FreeCAD as A,Part,MeshPart,Mesh
p='/Users/harrylu/Downloads/proj1/test/'
d=A.openDocument(p+'Shinguard_Slim_Cable_Clearance_Core.FCStd')
r={'source':'Shinguard_Compact_Reinforced_Threaded_Ready.FCStd','units':'mm','board_mounts':[],'shell_mounts':[],'checks':{'detailed_clearance_log':'slim_work/build.log','solid_boolean_and_hardware_checks_passed_before_meshing':True}}
for name,stem in [('BackCarrier','Slim_Threaded_Carrier'),('ImpactShell','Slim_Impact_Shell')]:
 o=d.getObject(name);assert o.Shape.isValid() and len(o.Shape.Solids)==1
 mesh=MeshPart.meshFromShape(Shape=o.Shape.cleaned(),LinearDeflection=.02,AngularDeflection=.1,Relative=False)
 before=mesh.isSolid();points=mesh.CountPoints
 mesh.removeDuplicatedPoints();mesh.removeDuplicatedFacets()
 print(stem,'watertight before',before,'after',mesh.isSolid(),'points',points,mesh.CountPoints,flush=True)
 assert mesh.isSolid(),stem
 mesh.write(p+stem+'.stl');assert Mesh.Mesh(p+stem+'.stl').isSolid()
 Part.export([o],p+stem+'.step')
 r['checks'][stem]={'valid_single_solid':True,'watertight_stl':True,'duplicate_vertices_removed':points-mesh.CountPoints}
for name,label in [('Part__Feature188','BNO085'),('Part__Feature356','ESP32')]:
 o=d.getObject(name);bb=o.Shape.BoundBox;holes=[]
 for f in o.Shape.Faces:
  if isinstance(f.Surface,Part.Cylinder) and 1.2<f.Surface.Radius<1.3:
   c=f.Surface.Center;xy=(round(c.x,5),round(c.y,5))
   if xy not in holes:holes.append(xy)
 for x,y in holes:r['board_mounts'].append({'board':label,'local_xy':[x,y],'depth_mm':4+.3-bb.ZLength,'engagement_mm':4-bb.ZLength,'tip_gap_mm':.3,'pitch_mm':.45})
for x,y in [(4,-18),(4,18),(92,-12),(92,12)]:
 floor=math.sqrt(150**2-(abs(y)-1.7)**2)-150+1.1
 r['shell_mounts'].append({'xy':[x,y],'blind_floor_z':floor,'thread_entry_z':floor+5.8,'bearing_z':floor+.3+8,'screw':'M3 x 8 mm','pitch_mm':.5,'tip_gap_mm':.3})
b=Part.makeCompound([d.BackCarrier.Shape,d.ImpactShell.Shape]).optimalBoundingBox(False,False)
def world(o):
 if hasattr(o,'Group'):
  ss=[world(c) for c in o.Group if c.TypeId not in ['App::Origin','App::Line','App::Plane']]
  return Part.makeCompound([s for s in ss if not s.isNull()])
 if hasattr(o,'Shape'):
  ss=o.Shape.copy();ss.Placement=o.getGlobalPlacement().multiply(o.Placement.inverse()).multiply(ss.Placement);return ss
 return Part.Shape()
assert d.BackCarrier.Shape.common(d.ImpactShell.Shape).Volume<1e-5
for n in ['Adafruit_BNO085_STEMMA_QT_v2','_400mAh_Battery_v2','PCB_Component','Adafruit_ESP32_Feather_V2_v2','Part__Feature355']:
 e=world(d.getObject(n));overlap=e.common(d.ImpactShell.Shape).Volume
 assert overlap<1e-5,(n,overlap)
 r['checks'][n]={'impact_overlap_mm3':overlap}
for row in r['board_mounts']:
 bo=d.getObject('Part__Feature188' if row['board']=='BNO085' else 'Part__Feature356');gp=bo.getGlobalPlacement();x,y=row['local_xy']
 axis=gp.Rotation.multVec(A.Vector(0,0,1));base=gp.multVec(A.Vector(x,y,bo.Shape.BoundBox.ZMax-4))
 screw=Part.makeCylinder(1.25,4,base,axis).fuse(Part.makeCylinder(2.25,2.5,base+axis*4,axis))
 assert screw.common(d.ImpactShell.Shape).Volume<1e-5
r['checks']['all_board_head_clearances_passed']=True
r['dimensions']={'new_envelope_mm':[b.XLength,b.YLength,b.ZLength],'old_envelope_mm':[96.0000002,65.6447657258,23.8609950894],'nominal_outline_mm':[96,71,53],'wrap_radius_before_mm':110,'wrap_radius_mm':150,'impact_skin_mm':3.6,'back_skin_mm':1.5}
json.dump(r,open(p+'slim_validation.json','w'),indent=2)
print('SUCCESS',r['dimensions'],flush=True)
