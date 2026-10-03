import sys,math,json
sys.path.append('/Applications/FreeCAD.app/Contents/Resources/lib')
import FreeCAD as A,Part,MeshPart
V=A.Vector;p='/Users/harrylu/Downloads/proj1/test/'
d=A.openDocument(p+'Shinguard_Slim_Cable_Clearance_Core.FCStd');old=d.ImpactShell.Shape

def height(x):
 line=Part.makeLine(V(x,0,0),V(x,0,30)).common(old)
 return min(v.Point.z for v in line.Vertexes)
ht,hl=round(height(10),2),round(height(85),2);print('roof',ht,hl,flush=True)
def roof(rad):
 xs=[-12,8/3,52/3,32,32+22/3,32+44/3,54,72,90,108];hs=[ht]*5+[hl]*5
 co=math.sqrt(rad*rad-45*45)/rad
 poles=[[V(x,-45,h-150+rad*co),V(x,0,h-150+rad/co),V(x,45,h-150+rad*co)] for x,h in zip(xs,hs)]
 sf=Part.BSplineSurface();sf.buildFromPolesMultsKnots(poles,[4,3,3,4],[3,3],[-12.,32.,54.,108.],[0.,1.],False,False,3,2,[[1.,co,1.]]*10)
 return sf.toShape().extrude(V(0,0,-55))
vs=[V(0,-35.5,-20),V(96,-26.5,-20),V(96,26.5,-20),V(0,35.5,-20)]
pr=Part.Face(Part.makePolygon(vs+[vs[0]])).extrude(V(0,0,65));pr=pr.makeFillet(12,[e for e in pr.Edges if e.BoundBox.ZLength>64])
skin=roof(153.6).cut(roof(150)).common(pr)
face=min(pr.Faces,key=lambda f:f.CenterOfMass.z);wire=face.OuterWire.copy();wire.translate(V(0,0,20))
interior=Part.Face(wire.makeOffset2D(-1.8,0,False,False,False));interior.translate(V(0,0,-20));interior=interior.extrude(V(0,0,65))
wall=pr.cut(interior).common(roof(153.6)).cut(Part.makeCylinder(150,130,V(-15,0,-146.25),V(1,0,0)))
pl=d.Part__Feature355.Placement
slot=Part.makeBox(12.7,5,10,V(-.5,-4.5,-7));slot.Placement=pl.multiply(slot.Placement)
# Recreate the same conservative switch-cradle assembly relief.
seat=Part.makeBox(13.2,.55,6.6,V(-.75,-4.8,-6.6)).fuse(Part.makeBox(.5,4.3,6.6,V(-.75,-4.8,-6.6))).fuse(Part.makeBox(.5,4.3,6.6,V(11.95,-4.8,-6.6)))
seat.Placement=pl.multiply(seat.Placement)
pts=[V(-.75,-4.8,-6.6),V(12.45,-4.8,-6.6),V(12.45,-4.8,0),V(-.75,-4.8,0)]
plane=Part.Face(Part.makePolygon(pts+[pts[0]]));plane.Placement=pl.multiply(plane.Placement)
seat=seat.fuse(plane.extrude(V(0,0,-20))).cut(Part.makeCylinder(151.25,130,V(-15,0,-150),V(1,0,0))).common(pr)
b=seat.BoundBox;relief=Part.makeBox(b.XLength+.6,b.YLength+.6,b.ZLength+.6,V(b.XMin-.3,b.YMin-.3,b.ZMin-.3))
for fillet in [.3,.2,0]:
 newskin=skin.makeFillet(fillet,skin.Edges) if fillet else skin.copy()
 cap=wall.fuse(newskin).cut(slot).cut(relief).removeSplitter()
 for x,y in [(4,-18),(4,18),(92,-12),(92,12)]:
  floor=math.sqrt(150**2-(abs(y)-1.7)**2)-150+1.1;bearing=floor+.3+8
  top=floor+5.8
  cap=cap.fuse(Part.makeCylinder(3.6,30,V(x,y,top)).common(roof(153.6)).common(pr))
  cap=cap.cut(Part.makeCylinder(3.55,top+20,V(x,y,-20)))
  cap=cap.cut(Part.makeCylinder(1.7,45,V(x,y,-10))).cut(Part.makeCylinder(2.95,30,V(x,y,bearing)))
 cap=cap.removeSplitter()
 mesh=MeshPart.meshFromShape(Shape=cap.cleaned(),LinearDeflection=.02,AngularDeflection=.1,Relative=False)
 mesh.removeDuplicatedPoints();mesh.removeDuplicatedFacets()
 print('fillet',fillet,'valid',cap.isValid(),'solids',len(cap.Solids),'mesh',mesh.isSolid(),'volume delta',cap.Volume-old.Volume,flush=True)
 if mesh.isSolid() and cap.isValid() and len(cap.Solids)==1:
  d.ImpactShell.Shape=cap;d.saveAs(p+'Shinguard_Slim_Cable_Clearance_Core.FCStd')
  mesh.write(p+'Slim_Impact_Shell.stl');cap.exportStep(p+'Slim_Impact_Shell.step')
  json.dump({'edge_fillet_mm':fillet,'previous_edge_fillet_mm':.6,'volume_change_mm3':cap.Volume-old.Volume},open(p+'slim_work/cap_edge_repair.json','w'),indent=2)
  print('CAP REPAIR SUCCESS',flush=True);break
else:raise RuntimeError('No valid watertight candidate')
