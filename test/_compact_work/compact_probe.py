import sys,math,json
sys.path.append('/Applications/FreeCAD.app/Contents/Resources/lib')
import FreeCAD as A,Part
V=A.Vector
P='/Users/harrylu/Downloads/proj1/test/'
S=A.openDocument(P+'Shinguard_Redesigned_CoreOnly.FCStd')
NAMES=['Adafruit_BNO085_STEMMA_QT_v2','_400mAh_Battery_v2','PCB_Component','Adafruit_ESP32_Feather_V2_v2']
def world(o):
 if hasattr(o,'Group'):
  shapes=[world(c) for c in o.Group if c.TypeId not in ['App::Origin','App::Line','App::Plane']]
  return Part.makeCompound([s for s in shapes if not s.isNull()])
 if hasattr(o,'Shape'):
  s=o.Shape.copy();s.Placement=o.getGlobalPlacement().multiply(o.Placement.inverse()).multiply(s.Placement);return s
 return Part.Shape()
for n in NAMES:
 s=world(S.getObject(n));s.Placement=S.getObject(n).Placement.inverse().multiply(s.Placement)
 print(n,s.BoundBox,s.Volume,len(s.Solids))
print('done')
layout=[(NAMES[0],20,14.2,90),(NAMES[1],64,-10.8,-90),(NAMES[2],21,-13.4,0),(NAMES[3],61,11.6,180)]
for R in [73,90,110]:
 print('RADIUS',R)
 H=0
 for n,x,y,yaw in layout:
  o=S.getObject(n);s=world(o);s.Placement=o.Placement.inverse().multiply(s.Placement)
  b=s.BoundBox;c=V((b.XMin+b.XMax)/2,(b.YMin+b.YMax)/2,0)
  tilt=-math.degrees(math.asin(y/(R+1.5)))
  r=A.Rotation(V(1,0,0),tilt).multiply(A.Rotation(V(0,0,1),yaw));pl=A.Placement(V(x,y,0)-r.multVec(c),r)
  s.Placement=pl.multiply(s.Placement)
  pts=[v.Point for v in s.Vertexes]+[f.CenterOfMass for f in s.Faces]
  dz=max(math.sqrt((R+1.5+.8)**2-p.y**2)-R-p.z for p in pts)
  hc=max(R+p.z+dz-math.sqrt((R-1.05)**2-p.y**2) for p in pts)
  H=max(H,hc);print(n,'raise',round(dz,2),'inner roof',round(hc,2),'tilt',round(tilt,2))
 print('Peak depth',H+2.4,'overall envelope',H+2.4+R-math.sqrt(R**2-33**2))
