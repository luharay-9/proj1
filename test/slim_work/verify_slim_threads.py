import sys,json,numpy as np
sys.path.append('/Applications/FreeCAD.app/Contents/Resources/lib')
import FreeCAD as A,Part,Mesh
P='/Users/harrylu/Downloads/proj1/test/'
d=A.openDocument(P+'Shinguard_Slim_Cable_Clearance_Core.FCStd')
r=json.load(open(P+'slim_validation.json'))
mesh=Mesh.Mesh(P+'Slim_Threaded_Carrier.stl');v,t=mesh.Topology
tri=np.array([[list(v[i]) for i in f] for f in t]);e1=tri[:,1]-tri[:,0];e2=tri[:,2]-tri[:,0]
checks=[]
def verify(start,axis,length,pitch,name):
 line=Part.makeLine(start,start+axis*length).common(d.BackCarrier.Shape)
 cs=sorted((e.CenterOfMass-start).dot(axis) for e in line.Edges)
 steps=np.diff(cs[1:-1]);assert len(cs)>=3
 if len(steps):assert np.max(abs(steps-pitch))<.001,(name,steps)
 origin=np.array(list(start));direction=np.array(list(axis))
 h=np.cross(direction,e2);det=np.sum(e1*h,axis=1);good=abs(det)>1e-10
 inv=np.zeros(len(det));inv[good]=1/det[good];s=origin-tri[:,0]
 u=inv*np.sum(s*h,axis=1);q=np.cross(s,e1);vv=inv*np.sum(direction*q,axis=1);tt=inv*np.sum(e2*q,axis=1)
 hit=tt[good&(u>=-1e-6)&(vv>=-1e-6)&(u+vv<=1+1e-6)&(tt>0)&(tt<length)]
 unique=[]
 for z in sorted(hit):
  if not unique or z-unique[-1]>.0001:unique.append(float(z))
 assert len(unique)>=6,(name,unique)
 err=abs(np.array(unique[2:])-np.array(unique[:-2])-pitch)
 assert max(err)<.025,(name,err)
 checks.append({'mount':name,'cad_crest_intervals':len(cs),'pitch_mm':pitch,'stl_crossings':len(unique),'stl_max_pitch_error_mm':float(max(err))})
for row in r['board_mounts']:
 bo=d.getObject('Part__Feature188' if row['board']=='BNO085' else 'Part__Feature356')
 gp=bo.getGlobalPlacement();floor=bo.Shape.BoundBox.ZMax-4-.3;x,y=row['local_xy']
 start=gp.multVec(A.Vector(x+1.25,y,floor+.35));axis=gp.Rotation.multVec(A.Vector(0,0,1))
 verify(start,axis,row['depth_mm']-.65,.45,row['board']+' '+str(row['local_xy']))
for row in r['shell_mounts']:
 x,y=row['xy'];verify(A.Vector(x+1.5,y,row['blind_floor_z']+.5),A.Vector(0,0,1),4.8,.5,'Shell '+str(row['xy']))
assert mesh.isSolid()
json.dump({'threads':checks,'watertight_carrier':True},open(P+'slim_thread_audit.json','w'),indent=2)
print('PASS',len(checks),'threaded mounts verified in CAD and STL',flush=True)
