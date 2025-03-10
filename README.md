# DPIAwareManager
[English](README.md)|[简体中文](README_CN.md)

A DPI-aware manager class for VFP applications.

## Purpose

DPIAwareManager aims to facilitate the use of VFP applications in High DPI monitors.

## The problem

Modern Windows display DPI-unaware VFP applications in High DPI monitors for which a text-scaling is set higher than 100% as it does with any Win32 application.

Windows scales the bitmap of the rendered graphic objects to match the percentage. As a result, the process produces text and graphics not as sharp as the developer initially designed.

In the case of VFP9 applications that use the Report Behavior 90, it also means that reports will have their objects misplaced and incorrectly sized.

## A halfway solution

A VFP9 application can declare itself to be DPI-aware by including a manifest stating so.

This declaration will instruct Windows not to interfere in the rendering of forms and reports. Blurriness and misalignments, as above, won't occur.

But, on the other hand, the application won't honor any display scaling above 100%. In High DPI monitors, set to higher scales, VFP applications will look small and smaller as the percentage increases.

## A more comprehensive solution

The DPIAwareManager class aims to address the problem in its entirety by providing a specific framework that an application may use to manage the scaling of screen and forms objects.

A managed application becomes aware of the conditions of the monitor(s) on which it displays its forms and automatically adjusts the dimensional and positional properties of the graphic objects.

Since the conditions may vary during the execution of the application, the awareness is a continuing process. The user may move the screen or top-level forms to monitors with different scales or change the monitor's text size percentage, and the manager reacts to changes as these as they happen.

The manager tries to be as unobtrusive as possible. Ideally, the application screen and forms won't even notice they've become DPI-aware.

For the cases where this transparency is not possible or desirable, the manager grants a more refined control to the application, the form, or the control.

Reference reading: [High-DPI application development](https://docs.microsoft.com/en-us/windows/win32/hidpi/high-dpi-desktop-application-development-on-windows)

## In use (basics)

DPIAwareManager class definition comes in a single program file. Executing it will be enough to put the class in scope.

To manage a form or the `_Screen` object, call the `Manage()` method. Depending on the application framework, this may proceed in different manners.

```foxpro
* integration with a typical form manager
LOCAL DPI AS DPIAwareManager

m.DPI = CREATEOBJECT("DPIAwareManager")
m.DPI.Manage(_Screen)

DO FORM someform.scx NOSHOW NAME formReference LINKED

m.DPI.Manage(m.FormReference)
m.FormReference.Show()
```

In the absence of a central form manager in the application, forms can initiate their DPI-aware management.

```foxpro
* no form manager, forms are on their own
PUBLIC DPI AS DPIAwareManager

m.DPI = CREATEOBJECT("DPIAwareManager")

DO someform.scx

* In the form's Init() method:
m.DPI.Manage(This)
```

## Reference

Available from the repository's [wiki](https://github.com/atlopes/DPIAwareManager/wiki).

## Quick testing

The manager is per-monitor aware, so you may work with different monitors having different scales.

To experiment, build the project in the testing folder and run the resulting dpi-testing executable.

Important: The executable filename must be "dpi-testing.exe" so that the builder will link the manifest into the executable.

To try with forms of your own, drop a set of self-contained copies in the testing/forms folder. Don't forget to include both SCX and SCT files and note that the testing has no error handler in place.

You may want to try with top-level or in-screen forms. Testing with several top-level forms in different monitors will demonstrate that an application may have forms of different scales running at the same time.

Important note: work in progress. It was not tested outside the particular environment of its development. Things may be missing or not working at all.

## Acknowledgements and credits

- The sizer components of the DPIAwareManager class build on the logic of Irwin Rodriguez's [VFPStretch](https://github.com/Irwin1985/VFPStretch).
- The DPI-Testing application uses [FoxyDialog](http://vfpimaging.blogspot.com/2020/06/foxydialogs-v10-going-much-forward-with.html), by Cesar Chalom, which requires the [VFP2C32](https://github.com/ChristianEhlscheid/vfp2c32) library, by Christian Ehlscheid.
- Graphics by [Icons8](https://icons8.com/), creators of extraordinary iconography.
