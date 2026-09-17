# FreeCAD project guidance

These instructions apply to the FreeCAD files and build scripts at the repository root, in `freecad/`, and in `test/`. The Flutter app in `shinguard/` is separate.

## Crash history and what was actually verified

- On this Mac, FreeCAD 1.1.3 loaded both `test/Shinguard_Redesigned_Repaired.FCStd` and `test/Shinguard_CoreOnly_Compact.FCStd` with its document engine, but each crashed with GUI exit code 139 while opening/rendering. A successful `App.openDocument()` or `unzip -t` is **not** proof that an FCStd file is safe to open interactively.
- Resaving each file with FreeCAD's document engine **without importing `FreeCADGui`** produced a core-only copy that passed a real GUI open/render/close smoke test. The verified compact output is `test/Shinguard_CoreOnly_Compact_Repaired.FCStd`.
- For the compact repair, all 377 object names and types matched the input. All 341 shape-bearing objects matched in volume, area, and bounding-box coordinates (tolerance `1e-7`). The repaired archive had no `GuiDocument.xml` or copied appearance arrays. This establishes model-data preservation by those checks, not that every visual setting was preserved.
- The exact malformed GUI item was **not** isolated. Do not describe the root cause as a particular color, object, or BREP. The saved GUI/view-provider payload is the observed differentiator in this failure.

## When changing or packaging the CAD

1. Keep the source FCStd untouched. Write a new candidate/repaired file; do not overwrite the only good copy.
2. Build/edit the geometry in FreeCAD, then reopen the saved candidate with FreeCAD's document engine. Check object names/types, required solids, validity, dimensions, intersections, and clearances appropriate to the design. For a repair that should not change geometry, compare every shape-bearing object with the source (at least volume, area, and bounding box).
3. Check the FCStd archive with `unzip -t` and inspect its members with `unzip -Z1`. FCStd is a ZIP container; a `GuiDocument.xml` plus `ShapeAppearance*`, `LineColorArray*`, and `PointColorArray*` entries indicates saved GUI state. A filename containing `CoreOnly` does **not** guarantee those entries are absent.
4. Run a **real FreeCAD GUI** open/render/close test on the exact final FCStd file. A minimal FreeCAD GUI script should call `App.openDocument(path)`, `Gui.activeDocument().activeView().fitAll()`, `Gui.updateGui()`, print a success marker, and use a short Qt timer to quit. Require a zero exit status **and** the marker. A headless document load, STEP export, or static render alone is insufficient.
5. If GUI opening crashes but the core model loads, make a separate core-only candidate with `freecadcmd`: open the input using `FreeCAD`, call `doc.saveAs(output)`, and close the document. Do not import `FreeCADGui` during that save. Recheck archive integrity, object/geometry preservation, and the GUI smoke test before handing it off.
6. Tell the user when core-only repair resets display state. Colors, transparency, visibility, tree expansion, and camera settings may need to be restored. Restore such settings only through a tested FreeCAD GUI save path, and retest the resulting file; do not assume that copying them back is safe.

## Avoid these failure modes

- Do not transplant or synthesize `GuiDocument.xml` and appearance-array members from another FCStd and consider the job complete after XML/archive checks. `test/package_compact.py` uses this pattern; its output `test/Shinguard_CoreOnly_Compact.FCStd` passed core loading but reproducibly crashed in the GUI. If that packaging step is changed or rerun, its output must pass the GUI smoke test before use.
- Do not blindly run old build/package scripts: several have machine-specific absolute paths and may target existing files. Inspect input and output paths first.
- Do not infer that an auxiliary warning about the absent 3Dconnexion framework caused this crash. That warning appeared during both crashing and successful GUI runs.
- Do not claim manufacturing readiness from geometric checks alone. The design notes document unresolved hardware, fit, impact, and material validation.

The working repair pattern is deliberately conservative: preserve and verify the model first, discard suspect saved view state only when needed, and validate the **final artifact** in the GUI.
