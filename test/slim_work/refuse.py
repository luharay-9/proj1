import sys
sys.path.append('/Applications/FreeCAD.app/Contents/Resources/lib')
import FreeCAD as A,Part
s=Part.Shape();s.read('/Users/harrylu/Downloads/proj1/test/slim_work/mount_debug.brep')
a,b=s.Solids
for tol in [0,.001,.01]:
 c=a.fuse(b,tol).removeSplitter()
 print(tol,c.isValid(),len(c.Solids),c.Volume,flush=True)
