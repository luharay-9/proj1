import sys,json
sys.path.append('/Applications/FreeCAD.app/Contents/Resources/lib')
import FreeCAD as A,Part
P='/Users/harrylu/Downloads/proj1/test/'
S=A.openDocument(P+'Shinguard_Redesigned_CoreOnly.FCStd');D=A.openDocument(P+'_compact_candidate.FCStd')
old=Part.makeCompound([S.GuardBase.Shape,S.GuardCover.Shape]).optimalBoundingBox(False,False)
new=Part.makeCompound([D.BackCarrier.Shape,D.ImpactShell.Shape]).optimalBoundingBox(False,False)
r={'old_envelope_mm':[old.XLength,old.YLength,old.ZLength],'new_envelope_mm':[new.XLength,new.YLength,new.ZLength],'new_min':[new.XMin,new.YMin,new.ZMin],'new_max':[new.XMax,new.YMax,new.ZMax]}
print(r,flush=True);json.dump(r,open(P+'compact_envelope.json','w'),indent=2)
