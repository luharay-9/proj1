import sys,math
sys.path.append('/Applications/FreeCAD.app/Contents/Resources/lib')
import FreeCAD as A,Part
V=A.Vector;p='/Users/harrylu/Downloads/proj1/test/'
s=Part.Shape();s.read(p+'reinforced_work/threadtool.brep');s.translate(V(0,0,.225))
post=Part.makeCylinder(3.3,15.8,V(0,0,-10))
post=post.cut(Part.makeCylinder(1.3493670615,9,V(0,0,0))).cut(s)
print('local',post.Volume,post.isValid(),len(post.Solids),len(post.Faces),flush=True)
for rr in [1.4,1.5,1.6]:print(rr,[post.isInside(V(rr,0,z),1e-6,True) for z in [1,1.1,1.2,1.3,1.4]],flush=True)
line=Part.makeLine(V(1.5,0,.5),V(1.5,0,5.3)).common(post)
print('sections',len(line.Edges),[round(e.Length,4) for e in line.Edges],flush=True)
post.exportBrep(p+'reinforced_work/threadedpost.brep')
