# Shinguard redesign

Open **Shinguard_Redesigned.FCStd**. The original `../Shinguard CAD.FCStd` is unchanged.

- The IMU, GPS, battery, and ESP32 keep their exact source placements and rotations, including their relative spacing. Their original detailed CAD components and display colors are retained.
- The switch sits on the negative-Y long edge, tangent to the taper. Its slider projects approximately 1.3 mm beyond the side, through a clearance opening. A cradle supports the body.
- Both curved guard surfaces follow the same rounded trapezoid: 106 mm long, nominal end widths 78/60 mm before rounding, 12 mm outline corner radii, and 0.75 mm skin perimeter rounds. Actual maximum width is approximately 75.9 mm. Shell walls are nominally 2.4 mm thick.
- PCB supports follow the original tilted underside planes. Their centers are relieved, leaving perimeter seating frames and the actual mounting-hole clearances. The battery has a broad support beneath its flat underside. All supports join the lower shell.
- Seating gaps allow 0.25 mm insulation/adhesive under PCBs and 0.35 mm under the battery and switch. These interface materials are not separate modeled parts; fit them when assembling.
- The second shell encloses the electronics. Four aligned bosses provide 2.4 mm clearance holes and 1.7 mm pilots for an M2 fastening concept. The nominal seam is 0.4 mm. Screw length, material-dependent pilot sizing, and physical fit still require selection for the manufacturing process.

The cover is saved at **65% transparency** for inspection. Select `02 · Upper guard / removable cover` and press Space to hide/show it. Set its View > Transparency to 0 for the opaque exterior. Hidden `Support...` features are construction records; the visible lower guard already contains these supports.

## Validation

`validation.json` records exact FreeCAD/OpenCascade solid-intersection checks. Both finished shells are valid single solids. No electronics overlap either shell, and the shells do not overlap one another. The main component-to-cover minimum clearances are:

| Component | Clearance |
|---|---:|
| IMU | 4.664 mm |
| Battery | 3.177 mm |
| GPS | 1.746 mm |
| ESP32 | 4.351 mm |
| Switch, at access opening | 0.500 mm |

`Shinguard_Review.png` is rendered from the actual saved CAD geometry. Only its inspection image displaces the cover; the CAD is assembled.

## Files and editing

- `Shinguard_Redesigned.FCStd`: complete assembly.
- `Guard_Base.step`, `Guard_Cover.step`: separate solid exports, millimeters.
- `redesign_shinguard.py`: reproducible FreeCAD build recipe using the original file.
- `package_view.py`: restores source colors, hides construction supports, and sets the review camera and cover transparency after a headless build.
- `render_review.py`: standalone CAD preview renderer.

Shell/support features are native editable boundary-representation solids with recorded design values; the recorded values are not a live parametric sketch system. Change the build recipe and rebuild to change those dimensions coherently. This is a CAD fit/layout revision, without impact testing or material/structural validation.

FreeCAD 1.1.3 crashed during automated GUI inspection. The diagnostic stack identified its macOS `QMacAccessibilityElement` layer. Geometry construction, saved-file verification, and image review were completed independently of that interface.
