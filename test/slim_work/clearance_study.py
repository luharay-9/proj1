"""Compact CoreOnly revision. +Z = impact; -Z = leg. Millimeters."""
import sys,math,json,os
sys.path.append('/Applications/FreeCAD.app/Contents/Resources/lib')
import FreeCAD as A,Part
V=A.Vector
P='/Users/harrylu/Downloads/proj1/test/'
SOURCE=P+'Shinguard_Compact_Reinforced_Threaded_Ready.FCStd'
TARGET=P+'Shinguard_CoreOnly_Compact.FCStd'
S=A.openDocument(SOURCE);D=A.newDocument('Shinguard_CoreOnly_Compact')
D.Label='Compact shinguard - back-mounted electronics'
R=150.;BACK_T=1.5;IMPACT_T=3.6;WALL_T=1.8;FLOOR_CLEAR=.3;ROOF_CLEAR=.8;SEAT_GAP=.2;SEAM=.25;SPLIT=3.5
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
 placement.Base.z+=rise+(.5 if label in ['IMU','ESP32'] else 0);o.Placement=placement
 shape=world(o);components[n]=shape
 points[n]=[v.Point for v in shape.Vertexes]+[f.CenterOfMass for f in shape.Faces]
 needed[n]=max(R+p.z-math.sqrt((R-ROOF_CLEAR)**2-p.y**2) for p in points[n])
 assert abs(shape.Volume-original.Volume)<1e-5
 report['parts'][label]={'name':n,'placement':str(placement),'source_volume_mm3':original.Volume,'volume_mm3':shape.Volume,'geometry_preserved':True,'tilt_degrees':tilt,'required_roof_height_mm':needed[n]}
 note('Positioned '+label+'; roof requirement '+str(round(needed[n],3)))

print("ROOF_NEEDS",needed,flush=True)
