"""Recheck the final saved assembly and the exported shell meshes."""
import sys,json
sys.path.append('/Applications/FreeCAD.app/Contents/Resources/lib')
import FreeCAD as A,Part,Mesh
P='/Users/harrylu/Downloads/proj1/test/'
d=A.openDocument(P+'Shinguard_Conforming_Wrap.FCStd')
r=json.load(open(P+'wrap_validation.json'))
def world(o):
    if hasattr(o,'Group'):
        ss=[world(c) for c in o.Group if c.TypeId not in ['App::Origin','App::Line','App::Plane']]
        return Part.makeCompound([s for s in ss if not s.isNull()])
    if hasattr(o,'Shape'):
        s=o.Shape.copy()
        s.Placement=o.getGlobalPlacement().multiply(o.Placement.inverse()).multiply(s.Placement)
        return s
    return Part.Shape()
names=[v['name'] for v in r['parts'].values()]+['Part__Feature355']
components={n:world(d.getObject(n)) for n in names}
cap=d.ImpactShell.Shape;back=d.BackCarrier.Shape
out={}
for n,e in components.items():
    out[n]={}
    for label,s in [('carrier',back),('cover',cap)]:
        overlap=e.common(s).Volume;gap=e.distToShape(s)[0]
        assert abs(overlap)<1e-5,(n,label,overlap)
        out[n][label]={'overlap_mm3':overlap,'gap_mm':gap}
    print('PASS clearance',n,flush=True)
for row in r['board_mounts']:
    o=d.getObject('Part__Feature188' if row['board']=='BNO085' else 'Part__Feature356')
    x,y=row['local_xy'];z=o.Shape.BoundBox.ZMax
    screw=Part.makeCylinder(1.25,4,A.Vector(x,y,z-4)).fuse(Part.makeCylinder(2.25,2.5,A.Vector(x,y,z)))
    screw.Placement=o.getGlobalPlacement().multiply(screw.Placement)
    assert screw.common(cap).Volume<1e-5
    for e in components.values():assert screw.common(e).Volume<1e-5
for row in r['shell_mounts']:
    x,y=row['xy'];z=row['blind_floor_z']+.3
    screw=Part.makeCylinder(1.5,8,A.Vector(x,y,z)).fuse(Part.makeCylinder(2.75,3,A.Vector(x,y,z+8)))
    assert screw.common(cap).Volume<1e-5
    for e in components.values():assert screw.common(e).Volume<1e-5
for i,n in enumerate(names):
    for m in names[i+1:]:assert components[n].common(components[m]).Volume<1e-5
for stem in ['Wrap_Threaded_Carrier','Wrap_Impact_Shell','Wrap_R60_Fit_Strip']:
    mesh=Mesh.Mesh(P+stem+'.stl');assert mesh.isSolid(),stem
json.dump({'final_saved_file_clearances':out,'hardware_collision_checks_passed':True,'all_three_stls_watertight':True},open(P+'wrap_final_clearances.json','w'),indent=2)
print('PASS final clearances and all three STL meshes',flush=True)
