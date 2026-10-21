import sys,json
sys.path.append('/Applications/FreeCAD.app/Contents/Resources/lib')
import FreeCAD as A,Part,MeshPart,Mesh
P='/Users/harrylu/Downloads/proj1/test/'
d=A.openDocument(P+'Shinguard_Conforming_Wrap_Core.FCStd')
s=d.ImpactShell.Shape
for linear,angular in [(.01,.15),(.03,.2),(.005,.05),(.05,.3)]:
    m=MeshPart.meshFromShape(Shape=s.cleaned(),LinearDeflection=linear,AngularDeflection=angular,Relative=False)
    m.removeDuplicatedPoints();m.removeDuplicatedFacets()
    print(linear,angular,m.CountFacets,m.isSolid(),flush=True)
    if m.isSolid():
        m.write(P+'Wrap_Impact_Shell.stl')
        assert Mesh.Mesh(P+'Wrap_Impact_Shell.stl').isSolid()
        json.dump({'linear_deflection_mm':linear,'angular_deflection_radians':angular,'facets':m.CountFacets,'watertight':True},open(P+'wrap_work/cover_mesh.json','w'),indent=2)
        break
else:raise RuntimeError('No watertight cover export')
