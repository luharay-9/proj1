import sys
sys.path.append('/Applications/FreeCAD.app/Contents/Resources/lib')
import FreeCAD as A,Part
p='/Users/harrylu/Downloads/proj1/test/slim_work/'
s=Part.Shape();s.read(p+'mount_debug.brep');a,b=s.Solids
print('valid',s.isValid(),a.Volume,b.Volume,'common',a.common(b).Volume,flush=True)
d=a.distToShape(b);print('DIST',d[0],d[1][:3],flush=True)
old=Part.Shape();old.read(p+'before_mounts.brep')
print('old/post overlap',old.common(b).Volume,'oldpost dist',old.distToShape(b)[0],flush=True)
print('fuse old/post',len(old.fuse(b).Solids),flush=True)
