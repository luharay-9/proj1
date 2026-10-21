"""Run proven checks/rendering against this revision's artifacts."""
import sys
from pathlib import Path
p=Path(__file__).resolve().parents[1]
mode=sys.argv[1]
scripts={'audit':'audit_slim.py','threads':'verify_slim_threads.py','render':'render_slim.py'}
code=(p/'slim_work'/scripts[mode]).read_text()
code=code.replace('Shinguard_Compact_Reinforced_Threaded_Ready.FCStd','SOURCE_REVISION.FCStd')
for a,b in [('Shinguard_Slim_Cable_Clearance','Shinguard_Conforming_Wrap'),('Slim_','Wrap_'),('slim_','wrap_'),('Slim shinguard | Deeper board mounts + cable space','Tighter wrap | Matching shell and angled mounts')]:
    code=code.replace(a,b)
code=code.replace('SOURCE_REVISION.FCStd','Shinguard_Slim_Cable_Clearance.FCStd')
exec(compile(code,__file__,'exec'))
