import sys
sys.path.append('/Applications/FreeCAD.app/Contents/Resources/lib')
import FreeCAD as A,Part
s=Part.Shape();s.read('/Users/harrylu/Downloads/proj1/test/reinforced_work/threadtool.brep')
print('groove',s.BoundBox,s.Volume,len(s.Faces))
for r in [1.2,1.35,1.4,1.5,1.6]:
 line=Part.makeLine(A.Vector(r,0,.5),A.Vector(r,0,5.5))
 sec=line.common(s)
 print(r,len(sec.Edges),[round(e.Length,5) for e in sec.Edges])
block=Part.makeCylinder(3.3,6)
bore=Part.makeCylinder(1.349367,6)
a=block.cut(bore)
c=a.cut(s)
print('vols',a.Volume,c.Volume,a.Volume-c.Volume,c.isValid())
d=A.newDocument('test');o=d.addObject('Part::Feature','thread');o.Shape=c;d.saveAs('/Users/harrylu/Downloads/proj1/test/reinforced_work/debugthread.FCStd')
