exec(open('/Users/harrylu/Downloads/proj1/freecad/measure_geometry.py').read().split('for name in')[0])
for n in ['Part__Feature355','Part__Feature356']:
 s=D.getObject(n).Shape
 print(n,'vertices',[(round(v.Point.x,2),round(v.Point.y,2),round(v.Point.z,2)) for v in s.Vertexes] if n.endswith('355') else s.BoundBox)
for f in D.Pad002.Shape.Faces:
 if isinstance(f.Surface,Part.Cylinder): print('cyl',f.Surface.Center,f.Surface.Axis,f.Surface.Radius)
