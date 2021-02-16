# DPIAwareManager

A DPI-aware manager for VFP applications.

Documentation to follow (but the code is reasonably commented).

The manager is per-monitor aware, so you may work with different monitors having different scales.

To experiment, build the project in the testing folder and run the resulting dpi-testing executable.

Important: The executable filename must be "dpi-testing.exe" so that the builder will link the manifest into the executable.

To try with forms of your own, drop a set of self-contained copies in the testing/forms folder. Don't forget to include both SCX and SCT files and note that the testing has no error handler in place.

You may want to try with top-level or in-screen forms. Testing with several top-level forms will allow the forms to have different scales.

Important note: work in progress. It was not tested outside the particular environment of its development. Things may be missing or not working at all.