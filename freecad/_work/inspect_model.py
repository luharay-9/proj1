import FreeCAD as App, Part, json
D=App.getDocument('Shinguard_CAD')
rows=[]
for o in D.Objects:
 r={'name':o.Name,'label':o.Label,'type':o.TypeId,'visible':o.ViewObject.Visibility,'parents':[p.Name for p in o.InList]}
 if hasattr(o,'Placement'): r['placement']=str(o.Placement)
 if hasattr(o,'Shape') and not o.Shape.isNull():
  s=o.Shape.copy()
  if hasattr(o,'getGlobalPlacement'): s.Placement=o.getGlobalPlacement().multiply(o.Placement.inverse()).multiply(s.Placement)
  b=s.BoundBox
  r.update(bounds=[b.XMin,b.YMin,b.ZMin,b.XMax,b.YMax,b.ZMax],volume=s.Volume,solids=len(s.Solids))
 if hasattr(o,'Group'): r['group']=[p.Name for p in o.Group]
 rows.append(r)
json.dump(rows,open('/Users/harrylu/Downloads/proj1/freecad/original_inventory.json','w'),indent=2)
App.setActiveDocument(D.Name)
Gui.activeDocument().activeView().viewAxonometric()
Gui.activeDocument().activeView().fitAll()
print('Inventory complete',len(rows),D.FileName)
