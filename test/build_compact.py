"""Compact CoreOnly revision. +Z = impact; -Z = leg. Millimeters."""
import sys,math,json,os
sys.path.append('/Applications/FreeCAD.app/Contents/Resources/lib')
import FreeCAD as A,Part
V=A.Vector
P='/Users/harrylu/Downloads/proj1/test/'
SOURCE=P+'Shinguard_Redesigned_CoreOnly.FCStd'
TARGET=P+'Shinguard_CoreOnly_Compact.FCStd'
S=A.openDocument(SOURCE);D=A.newDocument('Shinguard_CoreOnly_Compact')
D.Label='Compact shinguard - back-mounted electronics'
R=110.;BACK_T=1.5;IMPACT_T=2.4;WALL_T=1.8;FLOOR_CLEAR=.5;ROOF_CLEAR=1.10;SEAT_GAP=.2;SEAM=.25;SPLIT=3.5
L=96.;WIDE=68.;NARROW=50.;CORNER=12.
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
 shape=world(o);components[n]=shape
 points[n]=[v.Point for v in shape.Vertexes]+[f.CenterOfMass for f in shape.Faces]
 needed[n]=max(R+p.z-math.sqrt((R-ROOF_CLEAR)**2-p.y**2) for p in points[n])
 assert abs(shape.Volume-original.Volume)<1e-5
 report['parts'][label]={'name':n,'placement':str(placement),'source_volume_mm3':original.Volume,'volume_mm3':shape.Volume,'geometry_preserved':True,'tilt_degrees':tilt,'required_roof_height_mm':needed[n]}
 note('Positioned '+label+'; roof requirement '+str(round(needed[n],3)))
# Exact rounded trapezoid dimensions before corner rounding: 96 x (68 / 50).
vs=[V(0,-34,-20),V(96,-25,-20),V(96,25,-20),V(0,34,-20)]
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
x=43.;y=-34+9*x/96;normal=V(9,-96,0);normal.normalize()
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
try:impact_skin=valid(impact_skin.makeFillet(.6,impact_skin.Edges),'impact edge rounds')
except Exception as e:note('Skin round fallback: '+str(e))
impact_wall=rim.common(outer_roof).cut(cylinder(R,SPLIT+SEAM))
impact=valid(impact_skin.fuse(impact_wall).removeSplitter(),'impact cap')
impact=valid(impact.cut(slot).removeSplitter(),'impact switch opening')
# Four perimeter fasteners carry shell loads around, rather than through, the PCBs.
fasteners=[(4,-18),(4,18),(92,-12),(92,12)]
for x,y in fasteners:
 boss=Part.makeCylinder(2.8,50,V(x,y,-20)).cut(back_outer).common(cylinder(R,SPLIT)).common(prism)
 back=valid(back.fuse(boss).removeSplitter(),'back fastening boss')
 topboss=Part.makeCylinder(2.8,50,V(x,y,-20)).cut(cylinder(R,SPLIT+SEAM)).common(outer_roof).common(prism)
 impact=valid(impact.fuse(topboss).removeSplitter(),'impact fastening boss')
 # Thread pilot extends to 0.65 mm above the leg-side external surface.
 bottom=math.sqrt(R*R-y*y)-R+.65
 back=back.cut(Part.makeCylinder(.85,30,V(x,y,bottom)))
 impact=impact.cut(Part.makeCylinder(1.2,40,V(x,y,-10)))
 # Fastener heads are not modeled; hardware selection remains a fabrication check.
# Shroud around switch ends joins only the back carrier; provide cover assembly relief.
# Keep 0.3 mm around the cradle where it projects beyond the nominal seam.
clear_cradle=seat.copy()
# A local bounding relief is limited to the switch bay, above the carrier seam.
b=seat.BoundBox
impact=impact.cut(box(b.XMin-.3,b.YMin-.3,b.ZMin-.3,b.XLength+.6,b.YLength+.6,b.ZLength+.6)).removeSplitter()
back=valid(back.removeSplitter(),'finished back');impact=valid(impact.removeSplitter(),'finished impact')
back_obj=feature('BackCarrier','01 - LEG SIDE / back carrier + all electronics frames',back)
cap_obj=feature('ImpactShell','02 - IMPACT SIDE / protective shell',impact)
back_obj.addProperty('App::PropertyLinkList','SupportFeatures','Design');back_obj.SupportFeatures=support_objects
for o in [back_obj,cap_obj]:
 for prop,val in [('Length',L),('NominalWideEnd',WIDE),('NominalNarrowEnd',NARROW),('WrapRadius',R),('SeamGap',SEAM)]:
  o.addProperty('App::PropertyLength',prop,'Design');setattr(o,prop,val);o.setEditorMode(prop,1)
 o.addProperty('App::PropertyString','Role','Design')
back_obj.Role='Leg-facing bottom shell. All five electronics mount to this carrier.'
cap_obj.Role='Outward-facing impact shell. No electronics supports attach to this surface.'
D.recompute();D.saveAs(P+'_compact_candidate.FCStd')
note('Built compact geometry; checking exact collisions')
# Final verification: shell solids, electronic collision, pair clearance, support connection.
for n,e in components.items():
 row={}
 for label,s in [('back_carrier',back),('impact_shell',impact)]:
  overlap=e.common(s).Volume;distance=e.distToShape(s)[0]
  row[label]={'intersection_mm3':overlap,'clearance_mm':distance}
  assert abs(overlap)<1e-5,(n,label,overlap)
  if label=='impact_shell' and n!='Part__Feature355':assert distance>=1.0,(n,'insufficient impact clearance',distance)
 report['checks'][n]=row;note(n+' '+str(row))
 report['checks'][n]['retained_inside_outline_mm3']=e.cut(prism).Volume if n!='Part__Feature355' else None
 if n!='Part__Feature355':assert abs(e.cut(prism).Volume)<1e-5,(n,'outside outline')
for i,n in enumerate(components):
 for m in list(components)[i+1:]:
  overlap=components[n].common(components[m]).Volume;distance=components[n].distToShape(components[m])[0]
  assert abs(overlap)<1e-5,(n,m,'electronic collision',overlap)
  report['checks'][n+' / '+m]={'intersection_mm3':overlap,'clearance_mm':distance}
assert back.common(impact).Volume<1e-5,('shell overlap',back.common(impact).Volume)
for so in support_objects:
 assert so.Shape.common(impact).Volume<1e-5
 assert so.Shape.cut(back).Volume<1e-5
 # Every support must belong to the single-solid back carrier.
report['checks']['shells']={'back_valid':back.isValid(),'impact_valid':impact.isValid(),'back_solids':len(back.Solids),'impact_solids':len(impact.Solids),'intersection_mm3':back.common(impact).Volume,'all_supports_on_back':True}
old=Part.makeCompound([S.GuardBase.Shape,S.GuardCover.Shape]).optimalBoundingBox(False,False)
new=Part.makeCompound([back,impact]).optimalBoundingBox(False,False)
report['dimensions']={'old_envelope_mm':[old.XLength,old.YLength,old.ZLength],'new_envelope_mm':[new.XLength,new.YLength,new.ZLength],'nominal_outline_before_mm':[106,78,60],'nominal_outline_after_mm':[L,WIDE,NARROW],'proximal_center_depth_mm':H_TOP+IMPACT_T,'distal_center_depth_mm':H_LOW+IMPACT_T,'impact_skin_nominal_radial_mm':IMPACT_T,'back_skin_mm':BACK_T,'sidewall_mm':WALL_T,'wrap_radius_mm':R,'minimum_requested_impact_gap_mm':1,'seam_mm':SEAM}
report['roof_profile']={'high':H_TOP,'low':H_LOW,'transition_x_mm':[32,54]}
report['limitations']=['Clearances are CAD fit checks; impact performance is not certified.','0.2 mm PCB and 0.3 mm battery seating interfaces require insulating adhesive.','Fastener choice, cable routing, and physical fit remain fabrication checks.']
# Seed modest display meshes; exact B-rep geometry is unchanged.
import MeshPart
for so in [back_obj,cap_obj]: MeshPart.meshFromShape(Shape=so.Shape,LinearDeflection=.1,AngularDeflection=.2,Relative=False)
D.recompute();D.saveAs(TARGET)
Part.export([back_obj],P+'Compact_Leg_Side_Carrier.step');Part.export([cap_obj],P+'Compact_Impact_Shell.step')
json.dump(report,open(P+'compact_validation.json','w'),indent=2)
note('SUCCESS '+str(report['dimensions']))
