# Tighter-wrap shinguard — 21 October 2026

Open `Shinguard_Conforming_Wrap.FCStd`. Print `Wrap_Threaded_Carrier.stl` and `Wrap_Impact_Shell.stl` as separate parts in millimeters. STEP versions are also supplied. The previous `Shinguard_Slim_Cable_Clearance.FCStd` is preserved.

## Fit change

The user's measured side gap was approximately 5–10 mm with the center touching the shin. This revision reduces the transverse leg-contact radius from **150 to 60 mm**. At the widest section, the sides extend approximately **6.8 mm farther toward the shin**, relative to the center. This is a first fit trial based on the gap estimate, not a scan-derived fit.

Print **`Wrap_R60_Fit_Strip.stl` first**. It reproduces the widest leg-contact arc, is 8 mm long along the shin and 2 mm thick, and is already oriented with a flat profile on the build plate. Compare its concave surface against the same location on your shin. Check both edges and the center; a good fit should not depend on forcing the strip against your leg. Padding, if intended, must be included in the fit check. The narrow end will still need checking with the complete carrier.

Length remains **96 mm**, actual maximum width **68.64 mm**, with nominal trapezoid end widths **71 / 53 mm** before corner rounding. The deeper curvature increases the bounding depth to approximately **29.44 mm**, versus 22.28 mm previously. This is primarily the increased wrap depth, not thicker walls. The impact skin remains **3.6 mm nominal**, the back skin **1.5 mm**, and the outline corners remain rounded.

Both shell halves share the tighter curve. Electronics retain their arrangement and their original rigid geometry. Supports, threaded board posts, switch cradle and cover fastener seats are rebuilt for the new curvature. Board tilts are approximately 13.35° (BNO085), 10.87° (ESP32), 12.58° (GPS), and 10.11° (battery), toward their respective sides. Local height adjustments preserve screw depth and electronics clearance.

The small cover perimeter blend is 0.1 mm in this revision. Larger blends produced defective STL triangulation at the tighter curvature; the cover was rebuilt with this smaller blend and checked again. The 12 mm outline corner rounding and curved skins remain.

## Hardware retained from the slim revision

- Board mounts: **M2.5 × 4 mm socket-head cap screws, 0.45 mm pitch, 2 mm hex key**, four per board (eight total). Blind depths are 2.65 mm for BNO085 and 2.73 mm for ESP32; tip clearance is 0.30 mm. Heads seat on the PCB and remain above it by design.
- Shell: **4 × M3 × 8 mm socket-head cap screws, 0.5 mm pitch, 2.5 mm hex key**. Do not substitute the older 10 mm shell screws. Designed tip clearance remains 0.30 mm.

The old description of M2.5 screws with 0.5 mm pitch and a 2.5 mm key was corrected in `Slim_Design_Notes.md`; this revision retains the corrected geometry.

## Verification and limits

Audit results and reproducible scripts are in `wrap_work/` and the `wrap_*.json` reports. The exact final FCStd must pass the native FreeCAD GUI open/render/close test in addition to document-engine checks. Display settings are saved natively, not transplanted from another archive.

Final checks passed: real GUI open/render/close with exit 0 and success marker; ZIP integrity; 335 unchanged electronics leaf shapes; valid single-solid shell halves; zero shell/electronics and hardware-envelope collisions; all twelve physical thread pitches in CAD and carrier STL; watertight carrier, cover, and fit-strip STLs. STL/CAD volume differences are approximately 0.0024% for the carrier and 0.0885% for the cover. Rechecked impact-center sections retain 3.6 mm thickness. PCB contact with mounting posts is intentional.

CAD clearance checks do not establish impact protection, printed thread strength, or fit on the leg. The electronics models do not include the user's actual connected STEMMA cables and bend radii; check routing when trial-assembling the printed carrier. Physical fit and hardware testing remain necessary before use.
