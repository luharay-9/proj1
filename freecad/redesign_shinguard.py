"""Rebuild the guard around the unchanged source electronics. Units: mm.
Run with FreeCAD's Python interpreter or exec this file in the FreeCAD console.
"""
import sys, os, math, json
sys.path.append('/Applications/FreeCAD.app/Contents/Resources/lib')
import FreeCAD as A, Part
V=A.Vector
ROOT='/Users/harrylu/Downloads/proj1'
OUT=ROOT+'/freecad'
S=A.openDocument(ROOT+'/Shinguard CAD.FCStd')
D=A.newDocument('Shinguard_Redesigned')
D.Label='Shinguard - rounded trapezoid sandwich'
NAMES=['Adafruit_BNO085_STEMMA_QT_v2','_400mAh_Battery_v2','PCB_Component','Adafruit_ESP32_Feather_V2_v2']
for n in NAMES+['Part__Feature355']: D.copyObject(S.getObject(n),True)
original={n:str(S.getObject(n).Placement) for n in NAMES}
report={'units':'mm','source':'Shinguard CAD.FCStd','parameters':{},'checks':{},'platforms':[]}
def note(s): print(s,flush=True)
def valid(s,label):
 assert not s.isNull() and s.isValid() and len(s.Solids)==1,(label,'invalid or not single solid',len(s.Solids))
 return s
def box(x,y,z,dx,dy,dz): return Part.makeBox(dx,dy,dz,V(x,y,z))
def world(o):
 s=o.Shape.copy()
 s.Placement=o.getGlobalPlacement().multiply(o.Placement.inverse()).multiply(s.Placement)
 return s
def add(name,label,shape):
 o=D.addObject('PartDesign::Feature',name); o.Label=label; o.Shape=shape
 return o
# Rounded trapezoid: wider proximal end (x=-6), narrower distal end (x=100).
verts=[V(-6,-39,-30),V(100,-30,-30),V(100,30,-30),V(-6,39,-30)]
prism=Part.Face(Part.makePolygon(verts+[verts[0]])).extrude(V(0,0,90))
prism=valid(prism.makeFillet(12,[e for e in prism.Edges if e.BoundBox.ZLength>89]),'rounded outline')
face=min(prism.Faces,key=lambda f:f.CenterOfMass.z)
wire=face.OuterWire.copy(); wire.translate(V(0,0,30))
def outline(inset=0,z=-30,h=90):
 w=wire.copy()
 if inset: w=w.makeOffset2D(-inset,0,False,False,False)
 f=Part.Face(w); f.translate(V(0,0,z)); return f.extrude(V(0,0,h))
# Verify inward offset despite face orientation.
inner=outline(2.4)
if inner.Volume>prism.Volume: raise RuntimeError('Outline inset expanded')
# Concave lower shell follows a smooth cylindrical shin wrap.
outer_cyl=Part.makeCylinder(73,140,V(-20,0,65),V(1,0,0))
inner_cyl=Part.makeCylinder(70.6,140,V(-20,0,65),V(1,0,0))
base_skin=valid(outer_cyl.cut(inner_cyl).common(prism),'base skin')
# Rounded skin perimeter; cylinder faces provide a smooth ridge across the guard.
base_skin=valid(base_skin.makeFillet(0.75,base_skin.Edges),'base edge rounds')
wall=prism.cut(inner).common(outer_cyl).common(box(-20,-50,-20,140,100,30))
base=valid(base_skin.fuse(wall).removeSplitter(),'base and perimeter wall')
note('Base skin and perimeter created')
# Side switch: longitudinal slider tangent to the tapered, negative-Y long edge.
switch=D.Part__Feature355
old=switch.Placement
angle=math.degrees(math.atan2(9,106))-90
rot=A.Rotation(V(0,0,1),angle)
# Locate front body face 0.4 inside external side, with actuator projecting 1.3.
front=V(111.25005132251823,-29.877116866032264,5)
x=49.; y=-39+9*(x+6)/106
normal=V(9,-106,0); normal.normalize()
target=V(x,y,9)-normal*0.4
transform=A.Placement(target-rot.multVec(front),rot)
switch.Placement=transform.multiply(old)
sw=world(switch)
# Cut a rectangular slot sized for entire slider travel, plus clearance.
# Slot is built in original switch coordinates and rigidly transformed.
slot=box(104.5,-36.227116866,2.5,10,12.7,5)
slot.Placement=transform.multiply(slot.Placement)
base=valid(base.cut(slot).removeSplitter(),'switch opening')
# Compact angled seating platforms. PCB centers relieved; perimeter supports
# retain a 0.25 mm adhesive/insulation gap and avoid all existing board holes.
platforms=[]
for name,board_name,label in [(NAMES[0],'Part__Feature188','IMU'),(NAMES[1],'Part__Feature314','Battery'),(NAMES[2],'Part__Feature316','GPS'),(NAMES[3],'Part__Feature356','ESP32')]:
 board=D.getObject(board_name); bs=world(board)
 faces=[f for f in bs.Faces if isinstance(f.Surface,Part.Plane) and abs(f.normalAt(0,0).z)>.75 and f.Area>100]
 seating=min(faces,key=lambda f:f.CenterOfMass.z)
 down=seating.normalAt(0,0)
 if down.z>0: down=-down
 gap=.35 if label=='Battery' else .25
 # Full underside outline includes mounting-hole clearances.
 land=Part.Face(seating.OuterWire); land.translate(down*gap)
 raw=land.extrude(V(0,0,-30))
 if label!='Battery':
  # Central opening is in the PCB's local axes, leaving a 3 mm support frame.
  local=board.Shape.BoundBox
  cut=box(local.XMin+3,local.YMin+3,-40,local.XLength-6,local.YLength-6,80)
  cut.Placement=board.getGlobalPlacement().multiply(cut.Placement)
  raw=raw.cut(cut)
  # Retain the actual mounting holes; omit small signal vias from the support.
  for hf in bs.Faces:
   if isinstance(hf.Surface,Part.Cylinder) and 1.1<hf.Surface.Radius<1.7:
    axis=hf.Surface.Axis
    if abs(axis.dot(down))>.95:
     raw=raw.cut(Part.makeCylinder(hf.Surface.Radius,80,hf.Surface.Center-axis*40,axis))
 # Clip to lower inner shell; fuse overlaps 0.3 mm into skin for robust union.
 join_cyl=Part.makeCylinder(70.9,140,V(-20,0,65),V(1,0,0))
 p=raw.common(join_cyl).common(inner).removeSplitter()
 valid(p,label+' platform')
 obj=add('Support'+label,label+' fitted support',p)
 obj.addProperty('App::PropertyLength','SeatingGap','Design'); obj.SeatingGap=gap
 obj.addProperty('App::PropertyLink','Component','Design');obj.Component=D.getObject(name)
 platforms.append((obj,p,name))
 base=valid(base.fuse(p).removeSplitter(),'fused '+label)
 report['platforms'].append({'component':label,'volume_mm3':p.Volume,'seating_gap_mm':gap})
 note(label+' support fitted')
# Side switch cradle: flat bottom bed with lateral end stops.
seat=box(104.4,-36.727116866,1.0,7.6,13.7,1.65)
seat=seat.fuse(box(104.4,-36.727116866,1,7.6,.65,5)).fuse(box(104.4,-23.677116866,1,7.6,.65,5))
seat.Placement=transform.multiply(seat.Placement)
seat=seat.common(outer_cyl).common(prism).removeSplitter()
# Add downward supports from cradle to curved base using its projected volume.
seatfoot=box(104.4,-36.727116866,-16,7.6,13.7,18.65)
seatfoot.Placement=transform.multiply(seatfoot.Placement)
seatfoot=seatfoot.common(outer_cyl).common(inner).removeSplitter()
seat=seat.fuse(seatfoot).removeSplitter()
base=valid(base.fuse(seat).removeSplitter(),'switch cradle attached')
# Upper matching curved cover. Its lower skin remains above all electronics.
cover_low_cyl=Part.makeCylinder(90,140,V(-20,0,105.8),V(1,0,0))
cover_high_cyl=Part.makeCylinder(87.6,140,V(-20,0,105.8),V(1,0,0))
cover_skin=valid(cover_low_cyl.cut(cover_high_cyl).common(prism),'cover skin')
cover_skin=valid(cover_skin.makeFillet(.75,cover_skin.Edges),'cover edge rounds')
cover_wall=prism.cut(inner).cut(cover_high_cyl).common(box(-20,-50,10.4,140,100,40))
cover=valid(cover_skin.fuse(cover_wall).removeSplitter(),'cover and wall')
cover=valid(cover.cut(slot).removeSplitter(),'cover switch opening')
# Four aligned screw bosses, kept outside original board envelopes.
fasteners=[(1,-18),(1,18),(94,-16),(94,16)]
for x,y in fasteners:
 boss=Part.makeCylinder(3.5,30,V(x,y,-20)).common(outer_cyl).common(inner)
 # M2 pilot pockets stop short of the leg-facing skin.
 pilot=Part.makeCylinder(.85,7,V(x,y,3))
 boss=boss.cut(pilot)
 base=valid(base.fuse(boss).removeSplitter(),'base screw boss')
 cp=Part.makeCylinder(3.5,30,V(x,y,10.4)).cut(cover_high_cyl).common(prism)
 cp=cp.cut(Part.makeCylinder(1.2,35,V(x,y,10)))
 cover=valid(cover.fuse(cp).removeSplitter(),'cover screw boss')
 cover=cover.cut(Part.makeCylinder(1.2,40,V(x,y,10)))
# Base screw pilots must also cut shared wall regions.
for x,y in fasteners: base=base.cut(Part.makeCylinder(.85,7,V(x,y,3)))
base=valid(base.removeSplitter(),'finished base')
cover=valid(cover.removeSplitter(),'finished cover')
base_obj=add('GuardBase','01 · Lower guard + fitted supports',base)
cover_obj=add('GuardCover','02 · Upper guard / removable cover',cover)
for o in [base_obj,cover_obj]:
 for prop,value in [('WallThickness',2.4),('OutlineCornerRadius',12),('PerimeterEdgeRadius',.75)]:
  o.addProperty('App::PropertyLength',prop,'Design');setattr(o,prop,value)
base_obj.addProperty('App::PropertyLinkList','SupportFeatures','Design');base_obj.SupportFeatures=[o for o,p,n in platforms]
cover_obj.addProperty('App::PropertyLength','SeamGap','Design');cover_obj.SeamGap=.4
cover_obj.addProperty('App::PropertyString','Fasteners','Design');cover_obj.Fasteners='4 x M2; 2.4 mm clearance / 1.7 mm pilot; select length after material/tap choice'
report['parameters']={'outline_length_mm':106,'nominal_wide_end_mm':78,'nominal_narrow_end_mm':60,'corner_radius_mm':12,'edge_radius_mm':.75,'shell_thickness_mm':2.4,'cover_seam_mm':.4,'base_curvature_radius_mm':73,'cover_curvature_radius_mm':90}
D.recompute()
D.saveAs(OUT+'/Shinguard_Candidate.FCStd')
# Exact solid interference tests against all original electronics assemblies.
for n in NAMES+['Part__Feature355']:
 e=world(D.getObject(n)); row={}
 for label,s in [('base',base),('cover',cover)]:
  volume=e.common(s).Volume
  dist=e.distToShape(s)[0]
  row[label]={'overlap_mm3':volume,'minimum_clearance_mm':dist}
  assert abs(volume)<1e-5,(n,label,'collision',volume)
 report['checks'][n]=row
 note('Clearance verified: '+n+' '+str(row))
report['checks']['shells_overlap_mm3']=base.common(cover).Volume
note('Shell overlap: '+str(report['checks']['shells_overlap_mm3'])+' '+str(base.common(cover).BoundBox))
assert abs(report['checks']['shells_overlap_mm3'])<1e-5
report['checks']['placements_unchanged']={n:str(D.getObject(n).Placement)==original[n] for n in NAMES}
assert all(report['checks']['placements_unchanged'].values())
report['checks']['base_valid']=base.isValid(); report['checks']['cover_valid']=cover.isValid()
report['switch']={'placement':str(switch.Placement),'actuator_projection_mm':1.3,'edge':'negative Y long side'}
D.recompute()
D.saveAs(OUT+'/Shinguard_Redesigned.FCStd')
# Portable native-kernel exports for fabrication and interchange.
Part.export([base_obj],OUT+'/Guard_Base.step'); Part.export([cover_obj],OUT+'/Guard_Cover.step')
json.dump(report,open(OUT+'/validation.json','w'),indent=2)
note('SUCCESS: saved redesigned guard and geometry validation')
