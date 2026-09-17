exec(open('/Users/harrylu/Downloads/proj1/test/compact_probe.py').read().split('for n in NAMES:')[0])
D=A.openDocument(P+'_compact_candidate.FCStd')
for n in NAMES+['Part__Feature355']:
 s=world(D.getObject(n))
 for n2 in ['BackCarrier','ImpactShell']:
  cap=D.getObject(n2).Shape;over=s.common(cap)
  dist=s.distToShape(cap)
  print(n,n2,'intersect',over.Volume,over.BoundBox,'distance',dist[0],dist[1][:1],flush=True)
print('shell overlap',D.BackCarrier.Shape.common(D.ImpactShell.Shape).Volume)
for x in [20,40,50,60,70,80]:
 line=Part.makeLine(V(x,-10,-10),V(x,-10,25));print('roof at',x,[(v.Point.x,v.Point.y,v.Point.z) for v in D.ImpactShell.Shape.section(line).Vertexes])
