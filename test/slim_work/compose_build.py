from pathlib import Path
s=Path('test/build_compact.py').read_text()
s=s[:s.index('# Four perimeter fasteners')]
s=s.replace("SOURCE=P+'Shinguard_Redesigned_CoreOnly.FCStd'","SOURCE=P+'Shinguard_Compact_Reinforced_Threaded_Ready.FCStd'")
s=s.replace("TARGET=P+'Shinguard_CoreOnly_Compact.FCStd'","TARGET=P+'Shinguard_Slim_Cable_Clearance_Core.FCStd'")
s=s.replace("A.newDocument('Shinguard_CoreOnly_Compact')","A.newDocument('Shinguard_Slim_Cable_Clearance')")
s=s.replace("D.Label='Compact shinguard - back-mounted electronics'","D.Label='Slim shinguard - deeper M2.5 board mounts / cable clearance'")
s=s.replace('R=110.;BACK_T=1.5;IMPACT_T=2.4;WALL_T=1.8;FLOOR_CLEAR=.5;ROOF_CLEAR=1.10','R=150.;BACK_T=1.5;IMPACT_T=3.6;WALL_T=1.8;FLOOR_CLEAR=.3;ROOF_CLEAR=.8')
s=s.replace('WIDE=68.;NARROW=50.','WIDE=71.;NARROW=53.')
s=s.replace('V(0,-34,-20),V(96,-25,-20),V(96,25,-20),V(0,34,-20)','V(0,-35.5,-20),V(96,-26.5,-20),V(96,26.5,-20),V(0,35.5,-20)')
s=s.replace('x=43.;y=-34+9*x/96','x=43.;y=-35.5+9*x/96')
s=s.replace(" shape=world(o);components[n]=shape", """ # Keep 0.8 mm leg-side material under the entire new blind board bore.
 if label in ['IMU','ESP32']:
  bo=D.getObject(board);holes=[]
  for face in bo.Shape.Faces:
   if isinstance(face.Surface,Part.Cylinder) and 1.2<face.Surface.Radius<1.3:
    c=face.Surface.Center;xy=(round(c.x,5),round(c.y,5))
    if xy not in holes:holes.append(xy)
  floorz=bo.Shape.BoundBox.ZMax-4-.3
  gp=bo.getGlobalPlacement()
  fp=[gp.multVec(V(hx+1.45*math.cos(k*math.pi/8),hy+1.45*math.sin(k*math.pi/8),floorz)) for hx,hy in holes for k in range(16)]
  add=max(0,max(math.sqrt((R+.8)**2-p.y*p.y)-R-p.z for p in fp))
  placement.Base.z+=add;o.Placement=placement
  note(label+' raised '+str(round(add,3))+' mm for blind board screw depth')
 shape=world(o);components[n]=shape""")
Path('test/slim_work/build_slim.py').write_text(s)
