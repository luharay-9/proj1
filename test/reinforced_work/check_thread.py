import sys,json
sys.path.append('/Applications/FreeCAD.app/Contents/Resources/lib')
import FreeCAD as A,Part
p='/Users/harrylu/Downloads/proj1/test/'
d=A.openDocument(p+'Shinguard_Compact_Reinforced_Threaded.FCStd')
r=json.load(open(p+'reinforced_validation.json'))
for row in r['fasteners']:
 x,y=row['xy'];lo=row['blind_floor_z']+.5;hi=row['thread_entry_z']-.5
 line=Part.makeLine(A.Vector(x+1.5,y,lo),A.Vector(x+1.5,y,hi))
 sec=line.common(d.BackCarrier.Shape)
 print(x,y,'thread crest intervals',len(sec.Edges),'lengths',[round(e.Length,5) for e in sec.Edges],flush=True)
