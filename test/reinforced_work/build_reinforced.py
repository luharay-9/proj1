"""Reinforce the repaired compact model, preserving all electronics and supports."""
import sys,math,json,os
sys.path.append('/Applications/FreeCAD.app/Contents/Resources/lib')
import FreeCAD as A,Part,MeshPart
V=A.Vector
P='/Users/harrylu/Downloads/proj1/test/'
OUT=P+'Shinguard_Compact_Reinforced_Threaded.FCStd'
D=A.openDocument(P+'Shinguard_CoreOnly_Compact_Repaired.FCStd')
D.Label='Compact shinguard - reinforced / M3 threaded'
R=110.;THICK=3.6
report={'source':'Shinguard_CoreOnly_Compact_Repaired.FCStd','units':'mm','hardware':{'quantity':4,'size':'M3 x 10 mm','pitch':.5,'head':'ISO 4762 / DIN 912 socket head; 5.5 mm diameter, 3 mm height','hex_key_mm':2.5,'thread_radial_print_allowance_mm':.12,'thread_hand':'right','engagement_nominal_mm':5.5,'counterbore_diameter_mm':5.9,'cover_clearance_diameter_mm':3.4},'checks':{},'fasteners':[]}
def note(s):print(s,flush=True)
def valid(s,n):
 assert s.isValid() and len(s.Solids)==1,(n,s.isValid(),len(s.Solids))
 note(n+' valid');return s

def world(o):
 if hasattr(o,'Group'):
  shapes=[world(c) for c in o.Group if c.TypeId not in ['App::Origin','App::Line','App::Plane']]
  return Part.makeCompound([s for s in shapes if not s.isNull()])
 if hasattr(o,'Shape'):
  s=o.Shape.copy();s.Placement=o.getGlobalPlacement().multiply(o.Placement.inverse()).multiply(s.Placement);return s
 return Part.Shape()
def cyl(rad):return Part.makeCylinder(rad,130,V(-15,0,-R),V(1,0,0))
def roof(rad):
 xs=[-12,8/3,52/3,32,32+22/3,32+44/3,54,72,90,108]
 hs=[15.25]*5+[11.05]*5
 co=math.sqrt(rad*rad-45*45)/rad
 poles=[[V(x,-45,h-R+rad*co),V(x,0,h-R+rad/co),V(x,45,h-R+rad*co)] for x,h in zip(xs,hs)]
 surface=Part.BSplineSurface();surface.buildFromPolesMultsKnots(poles,[4,3,3,4],[3,3],[-12.,32.,54.,108.],[0.,1.],False,False,3,2,[[1.,co,1.]]*10)
 return surface.toShape().extrude(V(0,0,-55))
vs=[V(0,-34,-20),V(96,-25,-20),V(96,25,-20),V(0,34,-20)]
prism=Part.Face(Part.makePolygon(vs+[vs[0]])).extrude(V(0,0,65))
prism=prism.makeFillet(12,[e for e in prism.Edges if e.BoundBox.ZLength>64])
back=D.BackCarrier.Shape.copy();impact=D.ImpactShell.Shape.copy()
oldback=back.copy();oldcap=impact.copy()
outer=roof(R+THICK)
skin=valid(outer.cut(roof(R)).common(prism),'3.6 mm continuous skin')
skin=valid(skin.makeFillet(.6,skin.Edges),'rounded reinforced skin')
impact=valid(impact.fuse(skin).removeSplitter(),'reinforced cap')
# An ISO 60-degree internal thread with flattened roots and 0.12 mm radial print allowance.
pitch=.5;rmin=1.5-.541265877*pitch+.12;rmaj=1.5+.12;rb=rmin-.06
pts=[V(rb,0,-.1875-.06/math.sqrt(3)),V(rmaj,0,-.03125),V(rmaj,0,.03125),V(rb,0,.1875+.06/math.sqrt(3))]
profile=Part.Wire(Part.makePolygon(pts+[pts[0]]).Edges)
helix=Part.makeHelix(pitch,6.5,rb)
groove=valid(Part.Wire(helix.Edges).makePipeShell([profile],True,True),'helical thread cutter')
# Cut each threaded boss at the origin before placing it. OCCT loses the groove
# when a translated swept cutter is first clipped by a coaxial cylinder.
local_groove=groove.copy();local_groove.translate(V(0,0,.225))
local_post=Part.makeCylinder(3.3,15.8,V(0,0,-10)).cut(Part.makeCylinder(rmin,9))
local_post=local_post.cut(local_groove).cut(Part.makeCone(rmin,rmin+.35,.35,V(0,0,5.45))).removeSplitter()
valid(local_post,'independently modeled threaded boss')
crest_check=Part.makeLine(V(1.5,0,.5),V(1.5,0,5.3)).common(local_post)
assert len(crest_check.Edges)>=9,('thread crests absent',len(crest_check.Edges))
screw_envelopes=[]
for i,(x,y) in enumerate([(4,-18),(4,18),(92,-12),(92,12)],1):
 # Blind bore has >=1.1 mm back skin beneath its whole diameter.
 floor=math.sqrt(R*R-(abs(y)-1.7)**2)-R+1.1
 tip=floor+.3;top=floor+5.8;bearing=tip+10
 post=local_post.copy();post.translate(V(x,y,floor))
 post=post.cut(cyl(R)).common(prism)
 back=back.cut(Part.makeCylinder(3.299,50,V(x,y,-20)))
 back=valid(back.fuse(post).removeSplitter(),'carrier boss '+str(i))
 # Broader cap column, pocketed to locate over the carrier post and meet its flat top.
 column=Part.makeCylinder(3.6,30,V(x,y,top)).common(outer).common(prism)
 impact=impact.fuse(column).cut(Part.makeCylinder(3.55,top+20,V(x,y,-20)))
 impact=impact.cut(Part.makeCylinder(1.7,45,V(x,y,-10)))
 impact=impact.cut(Part.makeCylinder(2.95,30,V(x,y,bearing))).removeSplitter()
 valid(impact,'counterbored cap '+str(i))
 crest=Part.makeLine(V(x+1.5,y,floor+.5),V(x+1.5,y,floor+5.3)).common(back)
 assert len(crest.Edges)>=9,('missing modeled crests',i,len(crest.Edges))
 valid(back,'M3 female thread '+str(i))
 screw=Part.makeCylinder(1.5,10,V(x,y,tip)).fuse(Part.makeCylinder(2.75,3,V(x,y,bearing)))
 screw_envelopes.append(screw)
 report['fasteners'].append({'xy':[x,y],'blind_floor_z':floor,'screw_tip_z':tip,'thread_entry_z':top,'head_bearing_z':bearing,'head_top_z':bearing+3,'engagement_mm':top-tip,'full_thread_depth_after_leadin_mm':5.45,'bottom_tip_gap_mm':.3})
 note('Finished thread '+str(i))
D.BackCarrier.Shape=valid(back,'final back carrier');D.ImpactShell.Shape=valid(impact,'final cap')
D.BackCarrier.Label='01 - Leg-side carrier / four modeled M3 threads'
D.ImpactShell.Label='02 - Reinforced impact shell / recessed M3 clearance holes'
for ob in [D.BackCarrier,D.ImpactShell]:
 for name,value in [('Fastener','4 x M3 x 10 mm socket cap, ISO 4762, 0.5 mm pitch'),('Revision','3.6 mm impact skin; modeled helical threads; electronics unchanged')]:
  if name not in ob.PropertiesList:ob.addProperty('App::PropertyString',name,'Reinforcement')
  setattr(ob,name,value)
for name,value in [('ImpactSkinNominal',3.6),('ThreadPitch',.5),('ThreadRadialAllowance',.12),('ThreadEngagement',5.5)]:
 ob=D.ImpactShell if name.startswith('Impact') else D.BackCarrier
 if name not in ob.PropertiesList:ob.addProperty('App::PropertyLength',name,'Reinforcement')
 setattr(ob,name,value)
D.recompute();D.saveAs(OUT)
note('Saved native candidate; checking collisions')
names=['Adafruit_BNO085_STEMMA_QT_v2','_400mAh_Battery_v2','PCB_Component','Adafruit_ESP32_Feather_V2_v2','Part__Feature355']
for n in names:
 e=world(D.getObject(n));row={}
 for name,s in [('carrier',back),('impact_shell',impact)]:
  overlap=e.common(s).Volume
  assert abs(overlap)<1e-5,(n,name,overlap)
  distance=e.distToShape(s)[0]
  row[name]={'overlap_mm3':overlap,'clearance_mm':distance}
  note(n+' '+name+' gap '+str(distance))
 for j,screw in enumerate(screw_envelopes):
  assert e.common(screw).Volume<1e-5,(n,'screw',j)
 row['screw_hardware_overlap_mm3']=0
 report['checks'][n]=row
common=back.common(impact).Volume
assert common<1e-5,('shells intersect',common)
report['checks']['shell_overlap_mm3']=common
# Recheck carrier support retention and unchanged electronics.
for o in D.Objects:
 if o.Name.startswith('Support'):
  assert o.Shape.cut(back).Volume<1e-5
for i,screw in enumerate(screw_envelopes):
 # Clearance-only upper shank + head must not collide with cover.
 assert screw.common(impact).Volume<1e-5,('screw cover',i)
report['checks']['upper_screw_clearance_passed']=True
b=Part.makeCompound([back,impact]).optimalBoundingBox(False,False)
report['dimensions']={'envelope_mm':[b.XLength,b.YLength,b.ZLength],'nominal_impact_skin_mm':3.6,'previous_impact_skin_mm':2.4,'depth_increase_mm':1.2,'nominal_outline_mm':[96,68,50]}
report['checks']['valid_single_solids']={'carrier':back.isValid() and len(back.Solids)==1,'impact_shell':impact.isValid() and len(impact.Solids)==1}
for ob,stem in [(D.BackCarrier,'Reinforced_Threaded_Carrier'),(D.ImpactShell,'Reinforced_Impact_Shell')]:
 Part.export([ob],P+stem+'.step')
 mesh=MeshPart.meshFromShape(Shape=ob.Shape,LinearDeflection=.025,AngularDeflection=.12,Relative=False)
 assert mesh.isSolid(),('mesh not solid',stem)
 mesh.write(P+stem+'.stl');note('Exported '+stem+' '+str(mesh.CountFacets)+' triangles')
D.recompute();D.save()
# Small optional coupon uses the same modeled bore, helix, and lead-in.
coupon=Part.makeBox(9,9,7,V(-4.5,-4.5,0))
cg=groove.copy();cg.translate(V(0,0,1.425))
coupon=coupon.cut(Part.makeCylinder(rmin,8,V(0,0,1.2))).cut(cg)
coupon=valid(coupon.cut(Part.makeCone(rmin,rmin+.35,.35,V(0,0,6.65))).removeSplitter(),'M3 thread fit coupon')
MeshPart.meshFromShape(Shape=coupon,LinearDeflection=.015,AngularDeflection=.10,Relative=False).write(P+'M3_Thread_Fit_Coupon.stl')
json.dump(report,open(P+'reinforced_validation.json','w'),indent=2)
note('SUCCESS '+str(report['dimensions']))
