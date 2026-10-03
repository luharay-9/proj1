"""Software z-buffer render of the saved CAD; no GUI or display required."""
import sys,json,math
sys.path.append('/Applications/FreeCAD.app/Contents/Resources/lib')
import FreeCAD as A, Part, MeshPart
import numpy as np
from PIL import Image,ImageDraw,ImageFont
P='/Users/harrylu/Downloads/proj1/test/'
D=A.openDocument(P+'Shinguard_Slim_Cable_Clearance_Core.FCStd')
bounds=Part.makeCompound([D.BackCarrier.Shape,D.ImpactShell.Shape]).optimalBoundingBox(False,False)
report={'dimensions':{'new_envelope_mm':[bounds.XLength,bounds.YLength,bounds.ZLength]}}
def world(o):
 if hasattr(o,'Group'):
  ss=[world(c) for c in o.Group if c.TypeId not in ['App::Origin','App::Line','App::Plane']]
  return Part.makeCompound([s for s in ss if not s.isNull()])
 if hasattr(o,'Shape'):
  s=o.Shape.copy();s.Placement=o.getGlobalPlacement().multiply(o.Placement.inverse()).multiply(s.Placement);return s
 return Part.Shape()
names=['BackCarrier','ImpactShell','Adafruit_BNO085_STEMMA_QT_v2','_400mAh_Battery_v2','PCB_Component','Adafruit_ESP32_Feather_V2_v2','Part__Feature355']
colors=['536975','a8b9c2','2cb49a','c1c8d1','427dc1','299985','f0a83d']
meshes={}
for n,c in zip(names,colors):
 s=world(D.getObject(n))
 mesh=MeshPart.meshFromShape(Shape=s,LinearDeflection=.16,AngularDeflection=.23,Relative=False)
 v,t=mesh.Topology;tri=np.array([[list(v[i]) for i in f] for f in t]);meshes[n]=(tri,np.array([int(c[i:i+2],16) for i in (0,2,4)]))
 print(n,len(tri),flush=True)
W,H=1000,690
view=np.array([1,-.35,1.5]);view/=np.linalg.norm(view)
right=np.cross([0,0,1],view);right/=np.linalg.norm(right);up=np.cross(view,right)
light=np.array([-.4,-.6,1]);light/=np.linalg.norm(light)
views=[('ASSEMBLED: IMPACT FACE',True,False,False),('IMPACT CAP REMOVED: ELECTRONICS ON BACK',False,False,False),('LEG-SIDE CARRIER WITH FITTED FRAMES',False,False,True),('BOARD MOUNT SECTION: M2.5 x 4 SCREW SEATING',True,True,False)]
canvas=Image.new('RGB',(2200,1710),'#f5f7f9');draw=ImageDraw.Draw(canvas)
font='/System/Library/Fonts/Supplemental/Arial.ttf';bold='/System/Library/Fonts/Supplemental/Arial Bold.ttf'
draw.text((70,45),'Slim shinguard | Deeper board mounts + cable space',font=ImageFont.truetype(bold,44),fill='#183442')
draw.text((72,116),f"96 mm long | 71 / 53 mm nominal end widths | {report['dimensions']['new_envelope_mm'][2]:.1f} mm total depth",font=ImageFont.truetype(font,25),fill='#536975')
for idx,(title,cover,explode,bare) in enumerate(views):
 ts=[];cs=[]
 view=np.array([.4,-2,.55] if idx==3 else [1,-.35,1.5]);view/=np.linalg.norm(view)
 right=np.cross([0,0,1],view);right/=np.linalg.norm(right);up=np.cross(view,right)
 panel_meshes=meshes
 if idx==3:
  panel_meshes={}
  bo=D.getObject('Part__Feature188');gp=bo.getGlobalPlacement()
  local_origin=A.Placement(A.Vector(10.16,-8.89,0),A.Rotation())
  inverse=gp.multiply(local_origin).inverse()
  crop=Part.makeBox(6,3.2,10,A.Vector(-3,0,-4.5))
  for n in ['BackCarrier','Adafruit_BNO085_STEMMA_QT_v2']:
   shape=world(D.getObject(n));shape.Placement=inverse.multiply(shape.Placement)
   shape=shape.common(crop)
   mesh=MeshPart.meshFromShape(Shape=shape,LinearDeflection=.018,AngularDeflection=.1,Relative=False)
   v,t=mesh.Topology
   panel_meshes[n]=(np.array([[list(v[i]) for i in f] for f in t]),meshes[n][1])
  screw=Part.makeCylinder(1.25,4,A.Vector(0,0,-2.35)).fuse(Part.makeCylinder(2.25,2.5,A.Vector(0,0,1.65))).common(crop)
  mesh=MeshPart.meshFromShape(Shape=screw,LinearDeflection=.018,AngularDeflection=.1,Relative=False)
  v,t=mesh.Topology
  panel_meshes['ScrewEnvelope']=(np.array([[list(v[i]) for i in f] for f in t]),np.array([220,157,54]))
 for n,(tri,col) in panel_meshes.items():
  if n=='ImpactShell' and not cover:continue
  if bare and n!='BackCarrier':continue
  tri=tri.copy()
  if n=='ImpactShell' and explode and idx!=3:tri[:,:,2]+=42
  norms=np.cross(tri[:,1]-tri[:,0],tri[:,2]-tri[:,0]);norms/=np.maximum(np.linalg.norm(norms,axis=1)[:,None],1e-12)
  shades=.52+.48*np.maximum(0,norms@light)
  ts.append(tri);cs.append(np.clip(col[None,:]*shades[:,None],0,255))
 tri=np.concatenate(ts);colors=np.concatenate(cs)
 xy=np.stack([tri@right,-tri@up],axis=-1);depth=tri@view
 mn=xy.min((0,1));mx=xy.max((0,1));scale=min((W-110)/(mx[0]-mn[0]),(H-80)/(mx[1]-mn[1]))
 xy=(xy-(mx+mn)/2)*scale+np.array([W/2,H/2])
 buf=np.full((H,W),-np.inf);img=np.full((H,W,3),[245,247,249],dtype=np.uint8)
 for p,z,col in zip(xy,depth,colors):
  x0=max(0,int(np.floor(p[:,0].min())));x1=min(W-1,int(np.ceil(p[:,0].max())))
  y0=max(0,int(np.floor(p[:,1].min())));y1=min(H-1,int(np.ceil(p[:,1].max())))
  if x1<x0 or y1<y0:continue
  den=(p[1,1]-p[2,1])*(p[0,0]-p[2,0])+(p[2,0]-p[1,0])*(p[0,1]-p[2,1])
  if abs(den)<1e-9:continue
  xx,yy=np.meshgrid(np.arange(x0,x1+1)+.5,np.arange(y0,y1+1)+.5)
  a=((p[1,1]-p[2,1])*(xx-p[2,0])+(p[2,0]-p[1,0])*(yy-p[2,1]))/den
  b=((p[2,1]-p[0,1])*(xx-p[2,0])+(p[0,0]-p[2,0])*(yy-p[2,1]))/den
  c=1-a-b;zz=a*z[0]+b*z[1]+c*z[2]
  region=buf[y0:y1+1,x0:x1+1];mask=(a>=-1e-7)&(b>=-1e-7)&(c>=-1e-7)&(zz>region)
  region[mask]=zz[mask];img[y0:y1+1,x0:x1+1][mask]=col.astype(np.uint8)
 panel=Image.fromarray(img);x=65+(idx%2)*1060;y=225+(idx//2)*715
 canvas.paste(panel,(x,y));draw.text((x+15,y-38),title,font=ImageFont.truetype(bold,23),fill='#263a47')
 print('Rendered',title,flush=True)
draw.text((75,1645),'3.6 mm impact skin | Board screws: M2.5 x 4 (0.45 pitch) | Shell screws: M3 x 8 (0.5 pitch)',font=ImageFont.truetype(font,23),fill='#536975')
canvas.save(P+'Slim_Review.png')
print('RENDER COMPLETE',flush=True)
