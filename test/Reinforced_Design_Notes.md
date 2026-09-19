# Reinforced, threaded compact shinguard

Open **Shinguard_Compact_Reinforced_Threaded_Ready.FCStd**. This is the finished revision of `Shinguard_CoreOnly_Compact_Repaired.FCStd`; the source is unchanged.

## What changed

- The entire curved impact skin, including its center, increases from 2.4 to **3.6 mm nominal radial thickness**. Seven centerline sections measure 3.6 mm vertically. Rounded edge treatments remain. Added material is on the outside, preserving the electronics cavity under the strike face.
- The overall assembly envelope is **96 × 65.645 × 23.861 mm**. The depth increases by 1.2 mm. Nominal trapezoid end widths before rounding remain 68 / 50 mm.
- Four enlarged carrier bosses contain real, right-hand **M3 × 0.5 helical internal threads**. They are present in the native CAD, STEP, and STL geometry.
- The impact cover has 3.4 mm clearance holes and 5.9 mm recessed head pockets with flat bearing seats. The cover holes intentionally remain unthreaded so the screws clamp the cover against the threaded carrier.
- Electronics, switch, and support-frame geometry and placements are preserved. All frames remain on the leg side.

## Screws to use

**4 × M3 × 10 mm socket-head cap screws, coarse 0.5 mm pitch, DIN 912 / ISO 4762.** Stainless steel A2 is suitable for a fit trial. Use a **2.5 mm hex key**. The 10 mm length is measured **under the head**; the standard head is 5.5 mm diameter and 3 mm high. Do not substitute countersunk heads or longer screws.

Dimension reference: [Accu M3 × 10 socket-head screw specifications](https://www.accu.co.uk/metric-cap-head-screws/1009931-NBK-SNSP-M3-10).

The modeled engagement is 5.5 mm, including the entry region, with a 0.35 mm lead-in. Screw tips stop 0.3 mm above the blind-bore floor. The blind-bore floor retains at least 1.1 mm of material above the leg-facing surface across the bore diameter. Head pockets are recessed to suit the different local shell heights while using one screw length everywhere. At the curved rim of each distal hole, the specified head edge sits approximately 0.23 mm proud of the neighboring surface; the proximal heads are fully recessed.

## Printable files and fit

- `Reinforced_Impact_Shell.stl` — print the impact cover.
- `Reinforced_Threaded_Carrier.stl` — print the leg-side carrier with integrated threads and electronics frames.
- `M3_Thread_Fit_Coupon.stl` — optional 9 × 9 × 7 mm blind-thread coupon. Print this first and test the selected screw before printing both shells. It checks thread fit only: stop after about 5 mm engagement. A 10 mm screw cannot seat its head in this shallow blind coupon.
- Corresponding STEP files are included for further CAD work.

STL coordinates and dimensions are in millimeters. Import the two shell STL files as separate printable parts; do not export the full assembly with its electronics or duplicate construction supports.

The internal thread has a **0.12 mm radial printing allowance** relative to the basic profile. This is a starting fit allowance, not a verified printer-specific tolerance. For a first test on the pictured 0.4 mm nozzle, try 0.10 mm layers in the threaded region, keep the bore axis vertical, and start the screw by hand. Printed M3 threads are small: coupon fit and retention still require a physical test. Avoid forcing a screw or tightening enough to strip the plastic.

## Verification and limits

Both shells are valid single solids and both STL meshes are watertight. Saved-CAD section checks measure the thread pitch at approximately 0.500000 mm; STL thread sections preserve the repeated crests, with less than 0.001 mm measured pitch deviation. Electronics and screw envelopes have no unintended solid intersections with the shells; the shell halves have no overlapping volume.

Clearance to the cover is 1.098 mm at the battery, 1.420 mm at the controller, and 2.455 mm at the IMU. The GPS has a local 0.700 mm clearance to an enlarged fastener column; its strike-face cavity is unchanged. The exposed switch retains its intended opening. PCB seating gaps remain 0.2 mm and battery seating gap remains 0.3 mm.

The final file was reopened with the FreeCAD document engine and tested in the actual FreeCAD GUI. Display visibility and basic shell colors were saved through FreeCAD and the resulting file was reopened and rendered successfully; electronics display colors may differ from older revisions. Hide `02 - Reinforced impact shell` to inspect the electronics.

These are geometric and file-integrity checks. Printed thread strength, material choice, and impact protection have not been physically validated.
