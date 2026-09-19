"""Software z-buffer render of the saved CAD; no GUI or display required."""
import sys,json,math
sys.path.append('/Applications/FreeCAD.app/Contents/Resources/lib')
import FreeCAD as A, Part, MeshPart
import numpy as np
from PIL import Image,ImageDraw,ImageFont
P='/Users/harrylu/Downloads/proj1/test/'
D=A.openDocument(P+'Shinguard_Compact_Reinforced_Threaded.FCStd')
report=json.load(open(P+'reinforced_validation.json'))
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
views=[('ASSEMBLED: IMPACT FACE',True,False,False),('IMPACT CAP REMOVED: ELECTRONICS ON BACK',False,False,False),('LEG-SIDE CARRIER WITH FITTED FRAMES',False,False,True),('FASTENER SECTION: MODELED HELICAL THREAD',True,True,False)]
canvas=Image.new('RGB',(2200,1710),'#f5f7f9');draw=ImageDraw.Draw(canvas)
font='/System/Library/Fonts/Supplemental/Arial.ttf';bold='/System/Library/Fonts/Supplemental/Arial Bold.ttf'
draw.text((70,45),'Reinforced shinguard | Modeled M3 screw threads',font=ImageFont.truetype(bold,44),fill='#183442')
draw.text((72,116),f"96 mm long | 68 / 50 mm nominal end widths | {report['dimensions']['envelope_mm'][2]:.1f} mm total depth",font=ImageFont.truetype(font,25),fill='#536975')
for idx,(title,cover,explode,bare) in enumerate(views):
 ts=[];cs=[]
 view=np.array([.4,-2,.55] if idx==3 else [1,-.35,1.5]);view/=np.linalg.norm(view)
 right=np.cross([0,0,1],view);right/=np.linalg.norm(right);up=np.cross(view,right)
 panel_meshes=meshes
 if idx==3:
  panel_meshes={}
  crop=Part.makeBox(8,4,23,A.Vector(0,-18,-3))
  for n in ['BackCarrier','ImpactShell']:
   shape=world(D.getObject(n)).common(crop)
   mesh=MeshPart.meshFromShape(Shape=shape,LinearDeflection=.018,AngularDeflection=.1,Relative=False)
   v,t=mesh.Topology
   panel_meshes[n]=(np.array([[list(v[i]) for i in f] for f in t]),meshes[n][1])
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
draw.text((75,1645),'3.6 mm impact skin | 4 x M3 x 10 mm socket-head screws | 0.5 mm pitch | electronics unchanged',font=ImageFont.truetype(font,23),fill='#536975')
canvas.save(P+'Reinforced_Review.png')
print('RENDER COMPLETE',flush=True)
