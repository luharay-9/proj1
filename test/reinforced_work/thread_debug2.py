import sys,math,json
sys.path.append('/Applications/FreeCAD.app/Contents/Resources/lib')
import FreeCAD as A,Part
V=A.Vector;p='/Users/harrylu/Downloads/proj1/test/'
d=A.openDocument(p+'Shinguard_Compact_Reinforced_Threaded.FCStd')
r=json.load(open(p+'reinforced_validation.json'))
row=r['fasteners'][0];x,y=row['xy'];floor=row['blind_floor_z']
s=Part.Shape();s.read(p+'reinforced_work/threadtool.brep');s.translate(V(x,y,floor+.05))
clip=Part.makeCylinder(2,8,V(x,y,floor))
c=s.common(clip)
print('translated',s.Volume,'clipped',c.Volume,c.isNull(),c.isValid(),len(c.Solids),str(c.BoundBox),flush=True)
back=d.BackCarrier.Shape
print('intersect',back.common(s).Volume,'clip intersect',back.common(c).Volume,flush=True)
cut=back.cut(s)
print('cutdiff',back.Volume-cut.Volume,cut.isValid(),flush=True)
for n,obj in [('tool',s),('clipped',c),('final',cut)]:
 l=Part.makeLine(V(x+1.5,y,floor+.5),V(x+1.5,y,floor+5.3)).common(obj)
 print(n,len(l.Edges),[e.Length for e in l.Edges],flush=True)
