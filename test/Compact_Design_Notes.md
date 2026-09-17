# Compact shinguard — CoreOnly revision

Source: `Shinguard_Redesigned_CoreOnly.FCStd` in this `test` folder.
Revised assembly: **`Shinguard_CoreOnly_Compact.FCStd`**.

## Size

| Dimension | Source | Compact revision |
|---|---:|---:|
| Length | 106 mm | **96 mm** |
| Nominal wide end, before corner rounding | 78 mm | **68 mm** |
| Nominal narrow end, before corner rounding | 60 mm | **50 mm** |
| Maximum rounded-outline width | 75.88 mm | **65.64 mm** |
| Overall shell depth, including curvature | 34.84 mm | **22.66 mm** |
| Centerline depth at GPS end | — | **17.65 mm** |
| Centerline depth at lower end | — | **13.45 mm** |

The total envelope and the local shell-to-shell depth are different measurements. The old CAD's full Z envelope was 34.84 mm; approximately 27 mm describes only part of that curved assembly. The compact model is about 35% smaller in total shell depth. Measurements exclude unmodeled fastening hardware, cables, adhesives, and external comfort padding.

The wrap is shallower (110 mm radius) to reduce total bulk. The 12 mm outline corner rounds are retained, with 0.6 mm impact-skin edge rounds and 0.45 mm back-skin edge rounds. The smoothly tapered cover follows the taller GPS region and drops toward the thinner lower electronics. The GPS's approximately 12.01 mm intrinsic stack is the dominant minimum-depth constraint.

## Mounting and orientation

- **+Z is outward, toward impacts.** `02 - IMPACT SIDE / protective shell` is the separate impact cap.
- **-Z is inward, toward the leg.** `01 - LEG SIDE / back carrier + all electronics frames` holds the IMU, GPS, controller, battery, and side switch.
- Every frame is part of the single-solid leg-side carrier. No electronics frame attaches to the impact shell.
- All original electronic solids are preserved at full size. Their positions and angles are changed to pack them more closely and follow the back shell. The main boards, battery, and side switch remain separate items.
- The battery moves closer to the GPS, and the controller moves closer to the IMU. The electronics are not stacked.
- The side switch retains an external slider opening and a cradle on the leg-side carrier.

The proposed impact skin is nominally 2.4 mm radially across the wrap; its thickness normal to the longitudinal taper is approximately 2.3 mm or more away from perimeter rounds and openings. The back skin is 1.5 mm and the side rails are 1.8 mm. Four perimeter M2 fastening positions join the shells; choose suitable hardware and check head projection before manufacturing.

## Clearances and validation

`compact_validation.json` records the numerical checks. The main electronics have at least **1.0 mm clearance from the impact cap**. The switch has a smaller operating clearance at its intentional side opening. Both shells are valid single solids, do not overlap each other, and do not intersect the electronics. Electronics are also checked against one another.

The PCB seating interfaces allow 0.2 mm insulating adhesive; the battery seating interface allows 0.3 mm. Fit these interface materials during assembly. GPS underside-holder relief keeps that holder clear of the support frame. Cable routing and connector service access must be checked with the actual harness.

The IMU mounting angle has changed; account for the revised orientation in calibration or software that assumes the previous sensor axes. Firmware is unchanged.

These are geometric fit checks. Material choice, impact deflection, retention under impact, and comfort require prototype testing; this CAD revision is not an impact-protection certification.

## Inspect and edit

The impact cap is saved at 65% transparency. Select it and press Space to hide/show it. Set View > Transparency to 0 to see the opaque exterior. The hidden `Support...` items are construction records; the visible back carrier already includes all frames.

- `Compact_Review.png`: actual CAD render, including an exploded inspection view. The saved assembly is closed.
- `Compact_Leg_Side_Carrier.step` and `Compact_Impact_Shell.step`: separate solid exports in millimeters.
- `build_compact.py`: reproducible geometry and verification recipe from the CoreOnly source.
- `package_compact.py`: restores source electronics colors and review visibility.
- `render_compact.py`: renders the saved CAD without the FreeCAD GUI.

The model uses native B-rep features and preserves the source electronics hierarchy. Shell design-value properties are read-only records, not live sketch constraints; revise the build recipe to change dimensions coherently. The source CoreOnly file is unchanged.
