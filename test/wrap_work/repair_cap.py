from pathlib import Path
p=Path(__file__).resolve().parents[1]
code=(p/'slim_work/repair_cap.py').read_text()
for a,b in [('Shinguard_Slim_Cable_Clearance_Core','Shinguard_Conforming_Wrap_Core'),('Slim_Impact_Shell','Wrap_Impact_Shell'),('slim_work/','wrap_work/'),('153.6','63.6'),('151.25','61.25'),('146.25','56.25'),('150','60'),('[.3,.2,0]','[.1]'),("'previous_edge_fillet_mm':.6","'previous_edge_fillet_mm':.2")]:
    code=code.replace(a,b)
code=code.replace('cap=wall.fuse(newskin).cut(slot).cut(relief).removeSplitter()', 'cap=newskin.fuse(wall).removeSplitter().cut(slot).removeSplitter()')
code=code.replace('cap=cap.removeSplitter()', 'cap=cap.cut(relief).removeSplitter()')
exec(compile(code,__file__,'exec'))
