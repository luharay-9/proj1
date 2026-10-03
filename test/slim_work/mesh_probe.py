import sys,collections,json
sys.path.append('/Applications/FreeCAD.app/Contents/Resources/lib')
import FreeCAD as A,Part,MeshPart
p='/Users/harrylu/Downloads/proj1/test/'
d=A.openDocument(p+'Shinguard_Slim_Cable_Clearance_Core.FCStd')
m=MeshPart.meshFromShape(Shape=d.BackCarrier.Shape,LinearDeflection=.02,AngularDeflection=.1,Relative=False)
print('solid',m.isSolid(),'facets',m.CountFacets,'methods',[n for n in dir(m) if any(w in n.lower() for w in ['merge','duplic','repair','bound','hole','degen','manifold'])],flush=True)
v,t=m.Topology;counts=collections.Counter(tuple(sorted(e)) for f in t for e in [(f[0],f[1]),(f[1],f[2]),(f[2],f[0])])
for val in [1,3,4]:
 bad=[(list(v[a]),list(v[b])) for (a,b),c in counts.items() if c==val]
 print('edges',val,len(bad),'sample',bad[:5],flush=True)
m.write(p+'slim_work/carrier_mesh_initial.stl')
