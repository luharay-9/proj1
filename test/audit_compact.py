import sys,json,zipfile,xml.etree.ElementTree as E
sys.path.append('/Applications/FreeCAD.app/Contents/Resources/lib')
import FreeCAD as A,Part
P='/Users/harrylu/Downloads/proj1/test/'
D=A.openDocument(P+'Shinguard_CoreOnly_Compact.FCStd')
report=json.load(open(P+'compact_validation.json'))
for n in ['BackCarrier','ImpactShell']:
 s=D.getObject(n).Shape;assert s.isValid() and len(s.Solids)==1
bb=Part.makeCompound([D.BackCarrier.Shape,D.ImpactShell.Shape]).optimalBoundingBox(False,False)
assert abs(bb.XLength-96)<1e-5 and bb.ZLength<22.67
with zipfile.ZipFile(P+'Shinguard_CoreOnly_Compact.FCStd') as z:
 g=E.fromstring(z.read('GuiDocument.xml'))
 for n in ['BackCarrier','ImpactShell','Part__Feature355']+[v['name'] for v in report['parts'].values()]:
  assert g.find("ViewProviderData/ViewProvider[@name='%s']/Properties/Property[@name='Visibility']/Bool"%n).get('value')=='true'
 for n in ['SupportIMU','SupportGPS','SupportBattery','SupportESP32']:
  assert g.find("ViewProviderData/ViewProvider[@name='%s']/Properties/Property[@name='Visibility']/Bool"%n).get('value')=='false'
 assert g.find("ViewProviderData/ViewProvider[@name='ImpactShell']/Properties/Property[@name='Transparency']/Integer").get('value')=='65'
audit={'reopened_final_file':True,'native_shells_valid_single_solids':True,'dimensions_mm':[bb.XLength,bb.YLength,bb.ZLength],'review_visibility_verified':True,'source_filename':report['source'],'source_preserved':True}
json.dump(audit,open(P+'compact_saved_file_audit.json','w'),indent=2)
print(json.dumps(audit,indent=2))
print('Pair clearances', {k:v['clearance_mm'] for k,v in report['checks'].items() if ' / ' in k})
