# Slim shinguard with deeper board mounts

Open **Shinguard_Slim_Cable_Clearance.FCStd**. Print **Slim_Threaded_Carrier.stl** and **Slim_Impact_Shell.stl**. Corresponding STEP files are supplied. The previous source file is preserved.

## Dimensions and fit

- Overall depth: **22.28 mm**, previously **23.86 mm** — reduced by **1.58 mm**.
- Actual maximum width: **68.64 mm**, previously **65.64 mm** — approximately **1.5 mm extra on each side** for cable space. Nominal trapezoid end widths before rounding are 71 / 53 mm.
- Length remains **96 mm**.
- Impact skin remains **3.6 mm nominal thickness**, including the center. Leg-side skin remains 1.5 mm. The small cover edge blend is now 0.3 mm; the 12 mm outline corner rounds remain.
- Transverse wrap radius changes from **110 to 150 mm**, giving a shallower curve. This, together with reduced unused interior clearance, provides the depth reduction. The fit against the leg will therefore be flatter than the previous revision.
- Electronics keep their arrangement and original part geometry. The BNO085 and ESP32 sit on slightly taller supports so their screws have enough insertion depth. The switch remains on the long edge.

## Board screws: BNO085 and ESP32 Feather

Use **M2.5 × 4 mm socket-head cap screws**, **0.45 mm pitch**, DIN 912 / ISO 4762, with a **2 mm hex key**. There are four mounting positions per board, eight total if all positions are used.

The earlier combination of M2.5 with 0.5 mm pitch and a 2.5 mm hex key was inconsistent. Standard M2.5 socket-head screws use 0.45 mm pitch and a 2 mm key. The screw head is 4.5 mm diameter and 2.5 mm high. [Manufacturer specification](https://www.accu.co.uk/metric-cap-head-screws/3802-SSCF-M2-5-4-A2).

The new posts contact the PCB underside at each mounting hole and contain physical helical threads aligned to the board. Designed engagement is **2.35 mm for BNO085** and **2.43 mm for ESP32**, with **0.30 mm clearance below each screw tip**. Blind-hole depths are 2.65 and 2.73 mm respectively. Approximately 0.8 mm of leg-side material is retained beneath the bores. Internal threads have a 0.08 mm radial print allowance.

The screw head should seat directly on the PCB with no exposed shank between the head and board. The 2.5 mm-tall head itself remains above the PCB, as intended for a socket-head screw. The CAD has sufficient space above these heads; the PCB is not countersunk or modified.

## Shell screws

This slimmer revision uses **4 × M3 × 8 mm socket-head cap screws**, **0.5 mm pitch**, with a **2.5 mm hex key**. These are separate from the board screws. **Use the new 8 mm length rather than the previous 10 mm shell screws.** The shorter screws match the recessed cover seats and maintain a 0.3 mm blind-tip clearance. Shell thread engagement remains 5.5 mm.

## Printing and verification

Import the two STL files as separate millimeter-scale parts. Do not print the electronic reference parts or hidden construction supports from the full assembly.

Both shell meshes were checked as watertight. The carrier export needed one duplicate mesh vertex welded; no intentional geometry was removed. The cover was rebuilt with the smaller edge blend to obtain a clean mesh. Actual thread crests and pitch are checked in the CAD and STL exports. Electronics and screw-head envelopes have no unintended collisions with the enclosure; mounting-post contact with the boards is intentional.

For the small M2.5 threads, a 0.10 mm layer height in the threaded region is a reasonable starting trial. Check screw fit gently before installing the electronics; printer/material tolerances still need physical validation. The extra width is cable-routing allowance, not a verified model of your particular plugged-in STEMMA cable and bend radius.

The final file is reopened with the FreeCAD document engine and tested in the actual GUI. Its display settings are saved through FreeCAD, not copied from an older archive. Fit on the leg, printed fastener strength, cable bend clearance, and impact performance still require physical testing.
