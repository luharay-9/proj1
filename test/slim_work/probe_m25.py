import sys,math
sys.path.append('/Applications/FreeCAD.app/Contents/Resources/lib')
import FreeCAD as A,Part
V=A.Vector
s=open('/Users/harrylu/Downloads/proj1/test/slim_work/build_slim.py').read();f=s[s.index('def threaded_post'):s.index('back.exportBrep')]
def valid(s,n):assert s.isValid();return s
exec(f)
for depth in [2.65,2.73,3.6]:
 post,minor,tool=threaded_post(2.5,.45,.08,2.5,depth)
 print('TEMPLATE',depth,post.Volume,len(post.Faces),'tool',tool.Volume,tool.Placement,flush=True)
 for r in [1.1,1.2,1.25,1.3]:
  sec=Part.makeLine(V(r,0,.35),V(r,0,depth-.3)).common(post)
  print(r,len(sec.Edges),[round(e.Length,4) for e in sec.Edges],flush=True)
post,minor,tool=threaded_post(2.5,.45,.08,2.5,2.65)
print('toolbounds',tool.optimalBoundingBox(False,False),'minor',minor,flush=True)
for rr in [1,1.1,1.2,1.25,1.3,1.4]:
 sec=Part.makeLine(V(rr,0,.3),V(rr,0,2.5)).common(tool)
 print('TOOLSEC',rr,len(sec.Edges),[e.Length for e in sec.Edges],flush=True)
for h in [3.15,4.5,6.3]:
 pitch=.45;major=1.33;rb=minor-.06;half=3*pitch/8+.06/math.sqrt(3)
 pts=[V(rb,0,-half),V(major,0,-pitch/16),V(major,0,pitch/16),V(rb,0,half)]
 hel=Part.makeHelix(pitch,h,rb);print('HELSTART',hel.Vertexes[0].Point,flush=True)
 tool=Part.Wire(hel.Edges).makePipeShell([Part.Wire(Part.makePolygon(pts+[pts[0]]).Edges)],True,True)
 for shift in [0,.225]:
  t=tool.copy();t.translate(V(0,0,shift))
  s=Part.makeCylinder(2.5,12.65,V(0,0,-10)).cut(Part.makeCylinder(minor,6)).cut(t)
  print('TEST',h,shift,s.Volume,len(s.Faces),s.isValid(),flush=True)
base=Part.makeCylinder(2.5,12.65,V(0,0,-10));bore=Part.makeCylinder(minor,6)
t=tool.copy();t.translate(V(0,0,.225))
for label,c in [('reverse',base.cut(t).cut(bore)),('fusedtool',base.cut(bore.fuse(t))),('fuzzy',base.cut(bore).cut(t,.0001))]:
 sec=Part.makeLine(V(1.25,0,.35),V(1.25,0,2.35)).common(c)
 print(label,c.Volume,c.isValid(),len(c.Solids),len(sec.Edges),[e.Length for e in sec.Edges],flush=True)
