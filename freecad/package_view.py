"""Preserve source electronics appearance and provide a clean review view."""
import zipfile,xml.etree.ElementTree as E,copy,os
ROOT='/Users/harrylu/Downloads/proj1/'
path=ROOT+'freecad/Shinguard_Redesigned.FCStd'
with zipfile.ZipFile(ROOT+'Shinguard CAD.FCStd') as src,zipfile.ZipFile(path) as dst:
 sg=E.fromstring(src.read('GuiDocument.xml'))
 objects=E.fromstring(dst.read('Document.xml')).find('Objects')
 names=[o.get('name') for o in objects if o.tag=='Object' and o.get('name')]
 g=E.Element('Document',SchemaVersion='1',HasExpansion='1');E.SubElement(g,'Expand',count='0')
 data=E.SubElement(g,'ViewProviderData',Count=str(len(names)))
 refs=set();template=sg.find("ViewProviderData/ViewProvider[@name='Part__Feature355']")
 for i,n in enumerate(names):
  ov=sg.find("ViewProviderData/ViewProvider[@name='%s']"%n)
  v=copy.deepcopy(ov if ov is not None else template)
  v.set('name',n);v.set('expanded','0');v.set('treeRank',str(i))
  props=v.find('Properties')
  vis=props.find("Property[@name='Visibility']/Bool")
  if vis is not None:
   if n.startswith(('Support','Origin','X_Axis','Y_Axis','Z_Axis','XY_Plane','XZ_Plane','YZ_Plane')):vis.set('value','false')
   if n in ['GuardBase','GuardCover','Part__Feature355']:vis.set('value','true')
  tr=props.find("Property[@name='Transparency']/Integer")
  if tr is not None:tr.set('value','65' if n=='GuardCover' else '0')
  if n in ['GuardBase','GuardCover']:
   dm=props.find("Property[@name='DisplayMode']/Integer")
   if dm is not None:dm.set('value','1')
  for elem in v.iter():
   if elem.get('file'):refs.add(elem.get('file'))
  data.append(v)
 # Camera looking down at the assembly; a moderate fixed frame avoids fit issues.
 camera='OrthographicCamera {\n viewportMapping ADJUST_CAMERA\n position 47 -173.205 110\n orientation 1 0 0 1.04719755\n nearDistance 100\n farDistance 320\n aspectRatio 1\n focalDistance 200\n height 145\n}\n'
 E.SubElement(g,'Camera',settings=camera)
 with zipfile.ZipFile(path+'.tmp','w',zipfile.ZIP_DEFLATED) as out:
  for name in dst.namelist():
   if name!='GuiDocument.xml':out.writestr(name,dst.read(name))
  for name in refs:
   if name in src.namelist() and name not in dst.namelist():out.writestr(name,src.read(name))
  out.writestr('GuiDocument.xml',E.tostring(g,encoding='utf-8',xml_declaration=True))
os.replace(path+'.tmp',path)
print('Saved appearance for',len(names),'objects;',len(refs),'appearance resources')
