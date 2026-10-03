"""Compact CoreOnly revision. +Z = impact; -Z = leg. Millimeters."""
import sys,math,json,os
sys.path.append('/Applications/FreeCAD.app/Contents/Resources/lib')
import FreeCAD as A,Part
V=A.Vector
P='/Users/harrylu/Downloads/proj1/test/'
SOURCE=P+'Shinguard_Compact_Reinforced_Threaded_Ready.FCStd'
TARGET=P+'Shinguard_Slim_Cable_Clearance_Core.FCStd'
S=A.openDocument(SOURCE);D=A.newDocument('Shinguard_Slim_Cable_Clearance')
D.Label='Slim shinguard - deeper M2.5 board mounts / cable clearance'
R=150.;BACK_T=1.5;IMPACT_T=3.6;WALL_T=1.8;FLOOR_CLEAR=.3;ROOF_CLEAR=.8;SEAT_GAP=.2;SEAM=.25;SPLIT=3.5
L=96.;WIDE=71.;NARROW=53.;CORNER=12.
NAMES=['Adafruit_BNO085_STEMMA_QT_v2','_400mAh_Battery_v2','PCB_Component','Adafruit_ESP32_Feather_V2_v2']
layout=[(NAMES[0],'IMU',20,14.2,90,'Part__Feature188'),(NAMES[1],'Battery',54.8,-10.8,-90,'Part__Feature314'),(NAMES[2],'GPS',21,-13.4,0,'Part__Feature316'),(NAMES[3],'ESP32',59,11.6,180,'Part__Feature356')]
report={'source':SOURCE,'units':'mm','coordinates':'+Z impact, -Z leg','parts':{},'checks':{}}
def note(x):print(x,flush=True)
def world(o):
 if hasattr(o,'Group'):
  ss=[world(c) for c in o.Group if c.TypeId not in ['App::Origin','App::Line','App::Plane']]
  return Part.makeCompound([s for s in ss if not s.isNull()])
 if hasattr(o,'Shape'):
  s=o.Shape.copy();s.Placement=o.getGlobalPlacement().multiply(o.Placement.inverse()).multiply(s.Placement);return s
 return Part.Shape()
def valid(s,tag,single=True):
 assert not s.isNull() and s.isValid() and (not single or len(s.Solids)==1),(tag,'invalid',len(s.Solids))
 return s
def box(x,y,z,dx,dy,dz):return Part.makeBox(dx,dy,dz,V(x,y,z))
def feature(n,label,shape):
 o=D.addObject('Part::Feature',n);o.Label=label;o.Shape=shape;return o
def cylinder(radius,offset=0):return Part.makeCylinder(radius,130,V(-15,0,-R+offset),V(1,0,0))
# Components retain exact geometry and topology; only rigid placements change.
components={};points={};needed={}
for n,label,x,y,yaw,board in layout:
 o=D.copyObject(S.getObject(n),True)
 original=world(S.getObject(n));local=original.copy();local.Placement=S.getObject(n).Placement.inverse().multiply(local.Placement)
 b=local.BoundBox;center=V((b.XMin+b.XMax)/2,(b.YMin+b.YMax)/2,0)
 tilt=-math.degrees(math.asin(y/(R+BACK_T)))
 rotation=A.Rotation(V(1,0,0),tilt).multiply(A.Rotation(V(0,0,1),yaw))
 placement=A.Placement(V(x,y,0)-rotation.multVec(center),rotation)
 posed=local.copy();posed.Placement=placement.multiply(local.Placement)
 ps=[v.Point for v in posed.Vertexes]+[f.CenterOfMass for f in posed.Faces]
 rise=max(math.sqrt((R+BACK_T+FLOOR_CLEAR)**2-p.y**2)-R-p.z for p in ps)
 placement.Base.z+=rise;o.Placement=placement
 # Keep 0.8 mm leg-side material under the entire new blind board bore.
 if label in ['IMU','ESP32']:
  bo=D.getObject(board);holes=[]
  for face in bo.Shape.Faces:
   if isinstance(face.Surface,Part.Cylinder) and 1.2<face.Surface.Radius<1.3:
    c=face.Surface.Center;xy=(round(c.x,5),round(c.y,5))
    if xy not in holes:holes.append(xy)
  floorz=bo.Shape.BoundBox.ZMax-4-.3
  gp=bo.getGlobalPlacement()
  fp=[gp.multVec(V(hx+1.45*math.cos(k*math.pi/8),hy+1.45*math.sin(k*math.pi/8),floorz)) for hx,hy in holes for k in range(16)]
  add=max(0,max(math.sqrt((R+.8)**2-p.y*p.y)-R-p.z for p in fp))
  placement.Base.z+=add;o.Placement=placement
  note(label+' raised '+str(round(add,3))+' mm for blind board screw depth')
 shape=world(o);components[n]=shape
 points[n]=[v.Point for v in shape.Vertexes]+[f.CenterOfMass for f in shape.Faces]
 needed[n]=max(R+p.z-math.sqrt((R-ROOF_CLEAR)**2-p.y**2) for p in points[n])
 assert abs(shape.Volume-original.Volume)<1e-5
 report['parts'][label]={'name':n,'placement':str(placement),'source_volume_mm3':original.Volume,'volume_mm3':shape.Volume,'geometry_preserved':True,'tilt_degrees':tilt,'required_roof_height_mm':needed[n]}
 note('Positioned '+label+'; roof requirement '+str(round(needed[n],3)))
# Exact rounded trapezoid dimensions before corner rounding: 96 x (68 / 50).
vs=[V(0,-35.5,-20),V(96,-26.5,-20),V(96,26.5,-20),V(0,35.5,-20)]
prism=Part.Face(Part.makePolygon(vs+[vs[0]])).extrude(V(0,0,65))
prism=valid(prism.makeFillet(CORNER,[e for e in prism.Edges if e.BoundBox.ZLength>64]),'outline')
f=min(prism.Faces,key=lambda f:f.CenterOfMass.z);w=f.OuterWire.copy();w.translate(V(0,0,20))
inner=Part.Face(w.makeOffset2D(-WALL_T,0,False,False,False));inner.translate(V(0,0,-20));inner=inner.extrude(V(0,0,65))
assert inner.Volume<prism.Volume
rim=prism.cut(inner)
# Leg-side skin and side rail. All electronics support features join this skin.
back_outer=cylinder(R);back_inner=cylinder(R+BACK_T)
back_skin=valid(back_inner.cut(back_outer).common(prism),'back skin')
back_skin=valid(back_skin.makeFillet(.45,back_skin.Edges),'back skin rounds')
back=valid(back_skin.fuse(rim.common(cylinder(R,SPLIT)).cut(back_outer)).removeSplitter(),'back carrier')
# PCB support frames around the perimeter, cleared for mounting holes and the GPS holder.
support_objects=[]
for n,label,x,y,yaw,board in layout:
 bo=D.getObject(board);bs=world(bo)
 broad=[f for f in bs.Faces if isinstance(f.Surface,Part.Plane) and f.Area>100 and f.normalAt(0,0).z<-.8]
 seating=max(broad,key=lambda f:f.Area)
 down=seating.normalAt(0,0);gap=.3 if label=='Battery' else SEAT_GAP
 land=Part.Face(seating.OuterWire);land.translate(down*gap);raw=land.extrude(V(0,0,-30))
 if label!='Battery':
  b=bo.Shape.BoundBox
  cut=box(b.XMin+2.5,b.YMin+2.5,-40,b.XLength-5,b.YLength-5,80)
  cut.Placement=bo.getGlobalPlacement().multiply(cut.Placement);raw=raw.cut(cut)
  for hf in bs.Faces:
   if isinstance(hf.Surface,Part.Cylinder) and 1.1<hf.Surface.Radius<1.7 and abs(hf.Surface.Axis.dot(down))>.95:
    ax=hf.Surface.Axis;raw=raw.cut(Part.makeCylinder(hf.Surface.Radius,80,hf.Surface.Center-ax*40,ax))
 # Clip support bottoms just into the back sheet to provide a contiguous carrier.
 raw=raw.cut(cylinder(R+BACK_T-.25)).common(inner).removeSplitter()
 # Relieve underside components (GPS holder) using a conservative actual-shape envelope.
 if label=='GPS':
  holder=world(D.getObject('CR1220_2'))
  hb=holder.BoundBox
  raw=raw.cut(box(hb.XMin-.35,hb.YMin-.35,hb.ZMin-.35,hb.XLength+.7,hb.YLength+.7,hb.ZLength+.7)).removeSplitter()
 valid(raw,label+' frame',False)
 so=feature('Support'+label,label+' frame - attached to leg-side carrier',raw)
 so.addProperty('App::PropertyLength','SeatingGap','Design');so.SeatingGap=gap
 so.addProperty('App::PropertyLink','ElectronicComponent','Design');so.ElectronicComponent=D.getObject(n)
 support_objects.append(so)
 back=valid(back.fuse(raw).removeSplitter(),'carrier + '+label)
 note('Back-mounted frame '+label)
# Long-edge switch, with the actuator remaining outside the sidewall.
switch=D.copyObject(S.Part__Feature355,True)
angle=math.degrees(math.atan2(9,96));rot=A.Rotation(V(0,0,1),angle).multiply(A.Rotation(V(1,0,0),90))
x=43.;y=-35.5+9*x/96;normal=V(9,-96,0);normal.normalize()
# Determine height from the curved back using the lowest switch body corners.
pl=A.Placement(V(x,y,0)-normal*.35-rot.multVec(V(5.85,-2,0)),rot)
switch.Placement=pl;sw=world(switch)
rise=max(math.sqrt((R+BACK_T+.65)**2-v.Point.y**2)-R-v.Point.z for v in sw.Vertexes)
pl.Base.z+=rise;switch.Placement=pl;sw=world(switch);components['Part__Feature355']=sw
slot=box(-.5,-4.5,-7.0,12.7,5.,10.);slot.Placement=pl.multiply(slot.Placement)
back=valid(back.cut(slot).removeSplitter(),'switch slot in carrier')
seat=box(-.75,-4.8,-6.6,13.2,.55,6.6)
seat=seat.fuse(box(-.75,-4.8,-6.6,.5,4.3,6.6)).fuse(box(11.95,-4.8,-6.6,.5,4.3,6.6))
seat.Placement=pl.multiply(seat.Placement)
# Extend a flat cradle bottom down to the leg-side skin.
plane=Part.Face(Part.makePolygon([V(-.75,-4.8,-6.6),V(12.45,-4.8,-6.6),V(12.45,-4.8,0),V(-.75,-4.8,0),V(-.75,-4.8,-6.6)]))
plane.Placement=pl.multiply(plane.Placement)
seat=seat.fuse(plane.extrude(V(0,0,-20))).cut(cylinder(R+BACK_T-.25)).common(prism).removeSplitter()
back=valid(back.fuse(seat).removeSplitter(),'switch cradle')
# Smooth height reduction toward the ankle: GPS row drives the proximal height.
H_TOP=math.ceil(max(needed.values())*20)/20
H_LOW=math.ceil(max(needed[n] for n in [NAMES[1],NAMES[3]])*20)/20
# A smoothstep transitions over 22 mm; section loft interpolates the design profile.
def roof_h(x):
 t=max(0.,min(1.,(x-32.)/22.));return H_TOP+(H_LOW-H_TOP)*t*t*(3-2*t)
# Increase only if finite component samples need extra space under the transition.
extra=max(0,max(R+p.z-math.sqrt((R-ROOF_CLEAR)**2-p.y**2)-roof_h(p.x) for n in NAMES for p in points[n]))
H_TOP+=math.ceil(extra*20)/20;H_LOW+=math.ceil(extra*20)/20
# Rational tensor surface: exact transverse arc and a monotonic cubic height
# transition. This avoids interpolation overshoot between widely spaced lofts.
def roof_volume(rad):
 xs=[-12, 8/3, 52/3, 32, 32+22/3, 32+44/3, 54, 72, 90, 108]
 hs=[H_TOP,H_TOP,H_TOP,H_TOP,H_TOP,H_LOW,H_LOW,H_LOW,H_LOW,H_LOW]
 co=math.sqrt(rad*rad-45*45)/rad
 poles=[];weights=[]
 for x,h in zip(xs,hs):
  poles.append([V(x,-45,h-R+rad*co),V(x,0,h-R+rad/co),V(x,45,h-R+rad*co)])
  weights.append([1.,co,1.])
 surface=Part.BSplineSurface()
 surface.buildFromPolesMultsKnots(poles,[4,3,3,4],[3,3],[-12.,32.,54.,108.],[0.,1.],False,False,3,2,weights)
 return valid(surface.toShape().extrude(V(0,0,-55)),'roof volume')
inner_roof=roof_volume(R);outer_roof=roof_volume(R+IMPACT_T)
impact_skin=valid(outer_roof.cut(inner_roof).common(prism),'impact skin')
try:impact_skin=valid(impact_skin.makeFillet(.3,impact_skin.Edges),'impact edge rounds')
except Exception as e:note('Skin round fallback: '+str(e))
impact_wall=rim.common(outer_roof).cut(cylinder(R,SPLIT+SEAM))
impact=valid(impact_skin.fuse(impact_wall).removeSplitter(),'impact cap')
impact=valid(impact.cut(slot).removeSplitter(),'impact switch opening')
# Physical 60-degree right-hand thread factory. Do the sweep cut at the origin.
def threaded_post(diameter,pitch,allowance,outer_radius,depth):
 minor=diameter/2-.541265877*pitch+allowance;major=diameter/2+allowance;rb=minor-.06
 half=3*pitch/8+.06/math.sqrt(3)
 pts=[V(rb,0,-half),V(major,0,-pitch/16),V(major,0,pitch/16),V(rb,0,half)]
 profile=Part.Wire(Part.makePolygon(pts+[pts[0]]).Edges)
 helix=Part.makeHelix(pitch,math.ceil((depth+.5)/pitch)*pitch,rb)
 tool=Part.Wire(helix.Edges).makePipeShell([profile],True,True)
 tool.translate(V(0,0,pitch/2))
 post=Part.makeCylinder(outer_radius,depth+10,V(0,0,-10))
 post=post.cut(tool).cut(Part.makeCylinder(minor,depth+3))
 post=post.cut(Part.makeCone(minor,major+.1,.25,V(0,0,depth-.25))).removeSplitter()
 valid(post,'threaded local post')
 return post,minor,tool
back.exportBrep(P+'slim_work/before_mounts.brep')
report['board_mounts']=[];board_screws=[]
# Fill the mount holes with full-height blind threaded posts aligned to the PCBs.
for board,label in [('Part__Feature188','BNO085'),('Part__Feature356','ESP32')]:
 bo=D.getObject(board);gp=bo.getGlobalPlacement();bb=bo.Shape.BoundBox
 floor=bb.ZMax-4-.3;depth=bb.ZMin-floor
 local,minor,groove=threaded_post(2.5,.45,.08,2.5,depth);holes=[]
 for f in bo.Shape.Faces:
  if isinstance(f.Surface,Part.Cylinder) and 1.2<f.Surface.Radius<1.3:
   c=f.Surface.Center;xy=(round(c.x,5),round(c.y,5))
   if xy not in holes:holes.append(xy)
 for x,y in holes:
  pl=gp.multiply(A.Placement(V(x,y,floor),A.Rotation()))
  # Fuse a simple analytic post first; cut its thread in its own axial frame.
  post=Part.makeCylinder(2.5,depth+10,V(0,0,-10))
  post.Placement=pl.multiply(post.Placement)
  post=post.cut(back_outer).common(inner)
  joined=back.fuse(post).removeSplitter()
  valid(joined,label+' solid mount')
  localback=joined.copy();localback.Placement=pl.inverse().multiply(localback.Placement)
  localback=localback.cut(groove).cut(Part.makeCylinder(minor,depth+3))
  localback=localback.cut(Part.makeCone(minor,1.43,.25,V(0,0,depth-.25))).removeSplitter()
  back=localback.copy();back.Placement=pl.multiply(back.Placement)
  valid(back,label+' threaded mount')
  axis=gp.Rotation.multVec(V(0,0,1));base=gp.multVec(V(x,y,bb.ZMax-4))
  screw=Part.makeCylinder(1.25,4,base,axis).fuse(Part.makeCylinder(2.25,2.5,base+axis*4,axis))
  board_screws.append((label,screw))
  probe=Part.makeLine(pl.multVec(V(1.25,0,.35)),pl.multVec(V(1.25,0,depth-.3))).common(back)
  assert len(probe.Edges)>=3,('missing board thread',label,x,y)
  report['board_mounts'].append({'board':label,'local_xy':[x,y],'placement':str(pl),'depth_mm':depth,'engagement_mm':4-bb.ZLength,'tip_gap_mm':.3,'pitch_mm':.45,'measured_crest_intervals':len(probe.Edges)})
 note('Finished M2.5 x 4 mounts for '+label)
# Four shell fasteners: shortened M3 x 8 screws keep their heads recessed.
report['shell_mounts']=[];shell_screws=[]
local,_,_=threaded_post(3,.5,.12,3.3,5.8)
for x,y in [(4,-18),(4,18),(92,-12),(92,12)]:
 floor=math.sqrt(R*R-(abs(y)-1.7)**2)-R+1.1;top=floor+5.8;bearing=floor+.3+8
 post=local.copy();post.translate(V(x,y,floor));post=post.cut(back_outer).common(prism)
 back=back.cut(Part.makeCylinder(1.8,50,V(x,y,-20))).fuse(post).removeSplitter();valid(back,'shell post')
 impact=impact.fuse(Part.makeCylinder(3.6,30,V(x,y,top)).common(outer_roof).common(prism))
 impact=impact.cut(Part.makeCylinder(3.55,top+20,V(x,y,-20)))
 impact=impact.cut(Part.makeCylinder(1.7,45,V(x,y,-10))).cut(Part.makeCylinder(2.95,30,V(x,y,bearing))).removeSplitter()
 screw=Part.makeCylinder(1.5,8,V(x,y,floor+.3)).fuse(Part.makeCylinder(2.75,3,V(x,y,bearing)))
 shell_screws.append(screw)
 report['shell_mounts'].append({'xy':[x,y],'blind_floor_z':floor,'thread_entry_z':top,'bearing_z':bearing,'screw':'M3 x 8 mm','pitch_mm':.5,'tip_gap_mm':.3})
# Preserve switch assembly relief.
b=seat.BoundBox
impact=impact.cut(box(b.XMin-.3,b.YMin-.3,b.ZMin-.3,b.XLength+.6,b.YLength+.6,b.ZLength+.6)).removeSplitter()
back=valid(back,'finished back');impact=valid(impact,'finished impact')
back_obj=feature('BackCarrier','01 - Slim leg carrier / M2.5 board threads + M3 shell threads',back)
cap_obj=feature('ImpactShell','02 - Slim impact cover / reinforced 3.6 mm skin',impact)
# Construction supports represent the final material after post replacement.
for o in support_objects:o.Shape=o.Shape.common(back)
for ob in [back_obj,cap_obj]:
 for prop,val in [('Length',L),('NominalWideEnd',WIDE),('NominalNarrowEnd',NARROW),('WrapRadius',R),('ImpactSkin',IMPACT_T)]:
  ob.addProperty('App::PropertyLength',prop,'Design');setattr(ob,prop,val)
 ob.addProperty('App::PropertyString','Hardware','Design');ob.Hardware='Boards: M2.5 x 4, pitch 0.45. Shell: M3 x 8, pitch 0.5.'
D.recompute();D.saveAs(TARGET)
note('Built slim candidate; checking electronics and hardware')
for n,e in components.items():
 row={}
 for label,s in [('back_carrier',back),('impact_shell',impact)]:
  overlap=e.common(s).Volume;distance=e.distToShape(s)[0]
  assert abs(overlap)<1e-5,(n,label,overlap)
  row[label]={'intersection_mm3':overlap,'clearance_mm':distance}
  note(n+' '+label+' gap '+str(round(distance,4)))
 report['checks'][n]=row
for i,(label,screw) in enumerate(board_screws):
 assert screw.common(impact).Volume<1e-5,('board screw cap collision',i)
 for n,e in components.items():assert screw.common(e).Volume<1e-5,('screw electronics',i,n,screw.common(e).Volume)
 # The pilot-core cylinder represents the unobstructed tip/neck path; threads interlock intentionally.
 report['board_mounts'][i]['cap_head_clearance_mm']=screw.distToShape(impact)[0]
for s in shell_screws:
 assert s.common(impact).Volume<1e-5
 for e in components.values():assert s.common(e).Volume<1e-5
assert back.common(impact).Volume<1e-5
for i,(n,e) in enumerate(components.items()):
 for m in list(components)[i+1:]:assert e.common(components[m]).Volume<1e-5,(n,m,'collision')
old=Part.makeCompound([S.BackCarrier.Shape,S.ImpactShell.Shape]).optimalBoundingBox(False,False)
new=Part.makeCompound([back,impact]).optimalBoundingBox(False,False)
report['dimensions']={'old_envelope_mm':[old.XLength,old.YLength,old.ZLength],'new_envelope_mm':[new.XLength,new.YLength,new.ZLength],'nominal_outline_mm':[96,71,53],'wrap_radius_before_mm':110,'wrap_radius_mm':R,'impact_skin_mm':3.6,'back_skin_mm':1.5,'roof_high_mm':H_TOP,'roof_low_mm':H_LOW}
report['checks']['shells']={'both_valid_single_solids':True,'shell_overlap_mm3':0,'board_and_shell_screw_collisions_mm3':0}
import MeshPart
for ob,stem in [(back_obj,'Slim_Threaded_Carrier'),(cap_obj,'Slim_Impact_Shell')]:
 Part.export([ob],P+stem+'.step')
 mesh=MeshPart.meshFromShape(Shape=ob.Shape,LinearDeflection=.02,AngularDeflection=.1,Relative=False)
 mesh.removeDuplicatedPoints();mesh.removeDuplicatedFacets()
 assert mesh.isSolid(),stem
 mesh.write(P+stem+'.stl');note('Exported '+stem)
D.save()
json.dump(report,open(P+'slim_validation.json','w'),indent=2)
note('SUCCESS '+str(report['dimensions']))
