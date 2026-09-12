import sys,json,zipfile,xml.etree.ElementTree as E
sys.path.append('/Applications/FreeCAD.app/Contents/Resources/lib')
import FreeCAD as A
P='/Users/harrylu/Downloads/proj1/'
S=A.openDocument(P+'Shinguard CAD.FCStd');D=A.openDocument(P+'freecad/Shinguard_Redesigned.FCStd')
names=['Adafruit_BNO085_STEMMA_QT_v2','_400mAh_Battery_v2','PCB_Component','Adafruit_ESP32_Feather_V2_v2']
checks={}
for n in names:
 a=S.getObject(n);b=D.getObject(n)
 assert str(a.Placement)==str(b.Placement)
 assert abs(a.Shape.Volume-b.Shape.Volume)<1e-6
 checks[n]={'placement_preserved':True,'volume_preserved':True,'solid_count':len(b.Shape.Solids)}
for n in ['GuardBase','GuardCover']:
 s=D.getObject(n).Shape;assert s.isValid() and len(s.Solids)==1
 checks[n]={'valid_single_solid':True,'volume_mm3':s.Volume}
with zipfile.ZipFile(P+'freecad/Shinguard_Redesigned.FCStd') as z:
 g=E.fromstring(z.read('GuiDocument.xml'))
 assert g.find("ViewProviderData/ViewProvider[@name='GuardCover']/Properties/Property[@name='Transparency']/Integer").get('value')=='65'
 for n in ['SupportIMU','SupportGPS','SupportBattery','SupportESP32']:
  assert g.find("ViewProviderData/ViewProvider[@name='%s']/Properties/Property[@name='Visibility']/Bool"%n).get('value')=='false'
 checks['display']={'cover_transparency':65,'construction_supports_hidden':True}
json.dump(checks,open(P+'freecad/saved_file_audit.json','w'),indent=2)
print(json.dumps(checks,indent=2))
