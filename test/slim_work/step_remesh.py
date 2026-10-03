import sys
sys.path.append('/Applications/FreeCAD.app/Contents/Resources/lib')
import FreeCAD as A,Part,MeshPart
p='/Users/harrylu/Downloads/proj1/test/'
d=A.openDocument(p+'Shinguard_Slim_Cable_Clearance_Core.FCStd');s=d.ImpactShell.Shape
try:print('BOPcheck',s.check(True),flush=True)
except Exception as e:print('BOP ERROR',str(e),flush=True)
s.exportStep(p+'Slim_Impact_Shell.step')
r=Part.read(p+'Slim_Impact_Shell.step')
print('STEP reimport',r.isValid(),len(r.Solids),r.Volume-s.Volume,flush=True)
m=MeshPart.meshFromShape(Shape=r.cleaned(),LinearDeflection=.02,AngularDeflection=.1,Relative=False)
m.removeDuplicatedPoints();m.removeDuplicatedFacets()
print('remesh',m.isSolid(),m.CountFacets,flush=True)
if m.isSolid():m.write(p+'Slim_Impact_Shell.stl')
