import sys,json
sys.path.append('/Applications/FreeCAD.app/Contents/Resources/lib')
import FreeCAD as A,Part
P='/Users/harrylu/Downloads/proj1/'
S=A.openDocument(P+'Shinguard CAD.FCStd');old=A.openDocument(P+'freecad/Shinguard_Redesigned.FCStd')
def bb(s):
 b=s.BoundBox;return [b.XMin,b.YMin,b.ZMin,b.XMax,b.YMax,b.ZMax]
for n in ['Adafruit_BNO085_STEMMA_QT_v2','_400mAh_Battery_v2','PCB_Component','Adafruit_ESP32_Feather_V2_v2','Part__Feature355']:
 o=S.getObject(n);s=o.Shape.copy();s.Placement=o.Placement.inverse().multiply(s.Placement)
 print(n,'intrinsic bounds',bb(s),'placement',o.Placement)
print('Old assembly',bb(Part.makeCompound([old.GuardBase.Shape,old.GuardCover.Shape])))
