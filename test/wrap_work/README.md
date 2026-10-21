# R60 wrap revision build and validation

The delivered assembly is `../Shinguard_Conforming_Wrap.FCStd`; the source is the untouched `../Shinguard_Slim_Cable_Clearance.FCStd`. Use the root AGENTS.md crash/GUI-testing guidance.

This work used the installed FreeCAD Python runtime at `/Applications/FreeCAD.app/Contents/Resources/bin/python`. Build scripts import FreeCAD without FreeCADGui; GUI macros are run with `/Applications/FreeCAD.app/Contents/Resources/bin/freecad`.

## Reproduction sequence

1. `build_wrap.py --radius-mm 60` derives the R60 model from the existing slim builder. Its clearance checks pass, but its 0.2 mm cover blend fails the watertight mesh assertion. This intermediate file is not the final deliverable.
2. `repair_cap.py` rebuilds the cover with a 0.1 mm blend and exports a watertight STL and STEP. It is specific to this 60 mm radius. See `repair.log` and `cap_edge_repair.json`.
3. `fit_strip.py` exports the widest-section R60 trial strip.
4. `gui_prepare.FCMacro` saves the final document using native view providers; `gui_check.FCMacro` reopens that exact file. Require zero process exit and the corresponding success markers in both logs. Inspect `../Wrap_FreeCAD_GUI.png` as well.
5. `checks.py audit`, `checks.py threads`, `clearances.py`, and `mesh_audit.py` check saved geometry, the twelve threaded mounts, final component/hardware clearances, and mesh validity/volume agreement. `checks.py render` generates the four-panel review image.
6. Run `unzip -t` and inspect `unzip -Z1` on the final FCStd. Its GUI state is intentionally present and was saved natively, not copied from another archive.

`repaired_clearances.log` is the final clearance run. The earlier `final_clearances.log` was interrupted after the cover changed. `export_cover.py` and its log document unsuccessful alternate tessellation attempts; they are not part of the working export path. The original build log's cover assertion is superseded by the successful repair, mesh audit, and final saved-file checks.

No physical fit or impact test has been completed. Print the fit strip before the full enclosure. The user supplied an estimated 5–10 mm side gap; R60 increases edge sag about 6.8 mm at the widest section compared with R150. Physical cable routing remains unverified.
