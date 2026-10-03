import sys
sys.path.append('/Applications/FreeCAD.app/Contents/Resources/lib')
import FreeCAD as A,Part,Mesh,MeshPart
p='/Users/harrylu/Downloads/proj1/test/'
d=A.openDocument(p+'Shinguard_Slim_Cable_Clearance_Core.FCStd');s=d.ImpactShell.Shape
print('clean methods',[n for n in dir(s) if 'clean' in n.lower()],flush=True)
for tol,ang in [(.01,.08),(.03,.15),(.005,.05)]:
 c=s.cleaned()
 m=MeshPart.meshFromShape(Shape=c,LinearDeflection=tol,AngularDeflection=ang,Relative=False)
 m.removeDuplicatedPoints();m.removeDuplicatedFacets()
 print(tol,m.CountFacets,m.isSolid(),flush=True)
 if m.isSolid():m.write(p+'Slim_Impact_Shell.stl');break
