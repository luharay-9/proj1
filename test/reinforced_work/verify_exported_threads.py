import sys,json,numpy as np
sys.path.append('/Applications/FreeCAD.app/Contents/Resources/lib')
import FreeCAD as A,Part,Mesh
P='/Users/harrylu/Downloads/proj1/test/'
d=A.openDocument(P+'Shinguard_Compact_Reinforced_Threaded.FCStd')
r=json.load(open(P+'reinforced_validation.json'))
mesh=Mesh.Mesh(P+'Reinforced_Threaded_Carrier.stl')
v,t=mesh.Topology
tri=np.array([[list(v[i]) for i in f] for f in t])
checks=[]
for row in r['fasteners']:
 x,y=row['xy'];x+=1.5;lo=row['blind_floor_z']+.5;hi=row['thread_entry_z']-.5
 sec=Part.makeLine(A.Vector(x,y,lo),A.Vector(x,y,hi)).common(d.BackCarrier.Shape)
 centers=sorted(e.CenterOfMass.z for e in sec.Edges)
 steps=np.diff(centers[1:-1]);assert len(centers)>=9 and np.max(abs(steps-.5))<.0001
 # Intersect the exported STL with the same vertical ray at the engagement radius.
 t=tri[(tri[:,:,0].min(1)<=x)&(tri[:,:,0].max(1)>=x)&(tri[:,:,1].min(1)<=y)&(tri[:,:,1].max(1)>=y)]
 a=t[:,1,:2]-t[:,0,:2];b=t[:,2,:2]-t[:,0,:2];q=np.array([x,y])-t[:,0,:2]
 den=a[:,0]*b[:,1]-a[:,1]*b[:,0];good=np.abs(den)>1e-12
 a=a[good];b=b[good];q=q[good];t=t[good];den=den[good]
 u=(q[:,0]*b[:,1]-q[:,1]*b[:,0])/den;w=(a[:,0]*q[:,1]-a[:,1]*q[:,0])/den
 good=(u>=-1e-6)&(w>=-1e-6)&(u+w<=1+1e-6)
 z=t[:,0,2]+u*(t[:,1,2]-t[:,0,2])+w*(t[:,2,2]-t[:,0,2]);z=sorted(z[good&(z>lo)&(z<hi)])
 unique=[]
 for zz in z:
  if not unique or zz-unique[-1]>.0001:unique.append(float(zz))
 assert len(unique)>=18,('STL thread not present',row['xy'],unique)
 pitch_errors=abs(np.array(unique[2:])-np.array(unique[:-2])-.5)
 assert pitch_errors.max()<.025,('STL pitch error',pitch_errors.max())
 checks.append({'xy':row['xy'],'cad_crest_intervals':len(centers),'cad_measured_pitch_mm':float(np.mean(steps)),'stl_thread_surface_crossings':len(unique),'stl_max_pitch_error_mm':float(pitch_errors.max())})
assert mesh.isSolid()
json.dump({'threads':checks,'carrier_stl_watertight':True},open(P+'reinforced_thread_audit.json','w'),indent=2)
print(json.dumps(checks,indent=2),flush=True)
