import sys,json
sys.path.append('/Applications/FreeCAD.app/Contents/Resources/lib')
import FreeCAD as A,Mesh
P='/Users/harrylu/Downloads/proj1/test/'
d=A.openDocument(P+'Shinguard_Conforming_Wrap.FCStd')
rows=[]
for name,stem in [('BackCarrier','Wrap_Threaded_Carrier'),('ImpactShell','Wrap_Impact_Shell')]:
    s=d.getObject(name).Shape;m=Mesh.Mesh(P+stem+'.stl')
    err=abs(m.Volume-s.Volume)/s.Volume
    assert m.isSolid() and err<.005,(stem,err)
    rows.append({'file':stem+'.stl','watertight':True,'facets':m.CountFacets,'CAD_volume_mm3':s.Volume,'STL_volume_mm3':m.Volume,'relative_volume_error':err})
json.dump(rows,open(P+'wrap_mesh_audit.json','w'),indent=2)
print('PASS mesh volume agreement',rows,flush=True)
