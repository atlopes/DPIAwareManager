_Screen.Icon = "Fox-64.ico"
_Screen.Caption = "DPI Testing"

* CTRL+D on a form displays its dimensions
ON KEY LABEL CTRL+D Dimensions()

* incorporate FoxyDialog(), by Cesar Chalom
SET PROCEDURE TO FoxyDialog ADDITIVE

* put the class in scope
DO DPIAwareManager.prg

* make it public just to let forms put themselves under DPI-aware management
PUBLIC DPI AS DPIAwareManager

m.DPI = CREATEOBJECT("DPIAwareManager")
* the VFP screen will be managed
m.DPI.Manage(_Screen)
* and we'll want to see a log
m.DPI.Logging = .T.

CREATE CURSOR DPIAwareManagerLog ;
	(PK Int AutoInc, ;
		ControlName Varchar(60), ClassName Varchar(60), Property Varchar(32), ;
		Original Varchar(254), ;
		Ratio Double, NewRatio Double, ;
		FixedProperty Logical, ;
		ScaledBefore Varchar(254), Calculated Varchar(254), Stored Varchar(254))

* create a screen extension manager to demonstrate a DPI-aware menu
_Screen.AddObject("DPIAwareScreenManager", "ScreenManager")
* and use it to hook into the manager logging
BINDEVENT(m.DPI, "Log", _Screen.DPIAwareScreenManager, "LogChange")

* a new menu pad to extend the system menu
DEFINE PAD padDPIAware OF _MSYSMENU PROMPT "DPIAware"
DEFINE POPUP popDPIAware MARGIN RELATIVE FONT "Segoe UI", 9
ON PAD padDPIAware OF _MSYSMENU ACTIVATE POPUP popDPIAware
DEFINE BAR 1 OF popDPIAware PROMPT "DPI-aware menu bars"
DEFINE BAR 2 OF popDPIAware PROMPT "Current scale: 100%"

ACTIVATE SCREEN

* attention! the browse window is not manageable
BROWSE NOWAIT LAST

* incorporate additional testing in forms and unmanagedforms folders
SET PATH TO forms;unmanagedforms ADDITIVE

LOCAL ARRAY ManagedForms[2], UnmanagedForms[1]

* a basic form with info - shown in screen
DO FORM "monitor dpi in screen.scx" NAME m.ManagedForms[1] LINKED NOSHOW

* manage and display it
m.DPI.Manage(m.ManagedForms[1])
m.ManagedForms[1].Show()

* other form to hold information about available displays - shown as top level form
DO FORM "information on displays.scx" NAME m.ManagedForms[2] LINKED NOSHOW

* as above
m.DPI.Manage(m.ManagedForms[2])
m.ManagedForms[2].Show()

ACTIVATE SCREEN

LOCAL ARRAY SCX[1]
LOCAL NumSCX AS Integer
LOCAL Base AS Integer
LOCAL Term AS Terminator

m.Base = ALEN(m.ManagedForms)

m.Term = CREATEOBJECT("Terminator")

* go through all the test forms in the forms folder

FOR m.NumSCX = 1 TO ADIR(m.SCX, "forms\*.scx")

	DIMENSION m.ManagedForms[m.NumSCX + m.Base]

	* instantiate the form
	DO FORM ("forms\" + m.SCX[m.NumSCX, 1]) NAME m.ManagedForms[m.NumSCX + m.Base] LINKED NOSHOW

	* terminate the test application whem a form is closed
	BINDEVENT(m.ManagedForms[m.NumSCX + m.Base], "Destroy", m.Term, "Done")

	* manage and show the form
	m.DPI.Manage(m.ManagedForms[m.NumSCX + m.Base])
	m.ManagedForms[m.NumSCX + m.Base].Show()

	ACTIVATE SCREEN

ENDFOR

* go through all the unmanaged test forms in the unmanagedforms folder

FOR m.NumSCX = 1 TO ADIR(m.SCX, "unmanagedforms\*.scx")

	DIMENSION m.UnmanagedForms[m.NumSCX]

	* instantiate the form
	DO FORM ("unmanagedforms\" + m.SCX[m.NumSCX, 1]) NAME m.UnmanagedForms[m.NumSCX] LINKED NOSHOW

	* terminate the test application whem a form is closed
	BINDEVENT(m.UnmanagedForms[m.NumSCX], "Destroy", m.Term, "Done")

	* show the form, but don't manage it
	m.UnmanagedForms[m.NumSCX].Show()

	ACTIVATE SCREEN

ENDFOR

* remember how to quit, and display the type of DPI awareness of our application
LOCAL ARRAY AwarenessTypes[4]
m.AwarenessTypes[1] = "PROCESS_DPI_UNAWARE"
m.AwarenessTypes[2] = "PROCESS_SYSTEM_DPI_AWARE"
m.AwarenessTypes[3] = "PROCESS_PER_MONITOR_DPI_AWARE"
m.AwarenessTypes[4] = "UNKNOWN"

MESSAGEBOX("Close a window to quit!" + 0h0d0d + ;
	"Awareness type: " + m.AwarenessTypes[MIN(MAX(m.DPI.AwarenessType, 0), 3) + 1], 64, "DPI-Testing")

READ EVENTS


PROCEDURE Dimensions ()

	LOCAL ARRAY ObjInto(1)
	LOCAL DF AS Form

	IF AMOUSEOBJ(m.ObjInto, 1) != 0
		m.DF = m.ObjInto(2)
		MESSAGEBOX(TEXTMERGE("<<m.DF.Name>>: Width = <<m.DF.Width>>, Height = <<m.DF.Height>>"))
	ENDIF

ENDPROC

DEFINE CLASS Terminator AS Custom

	FUNCTION Done
		CLEAR EVENTS
	ENDFUNC

ENDDEFINE

DEFINE CLASS ScreenManager AS DPIAwareScreenManager OF ../source/dpiawaremanager.prg

	FUNCTION SelfManage (DPIScale AS Integer, DPINewScale AS Integer)

		LOCAL NewFontSize AS Integer

		m.NewFontSize = ROUND(9 * m.DPINewScale / 100, 0)

		DEFINE POPUP popDPIAware MARGIN RELATIVE FONT "Segoe UI", m.NewFontSize
		DEFINE BAR 1 OF popDPIAware PROMPT "DPI-aware menu bars"
		DEFINE BAR 2 OF popDPIAware PROMPT TEXTMERGE("Current scale: <<m.DPINewScale>>%")

	ENDFUNC

	FUNCTION LogChange (ControlName AS String, ClassName AS String, Property AS String, ;
				Original AS String, Ratio AS Double, NewRatio AS Double, ;
				FixedProperty AS Logical, ;
				ScaledBefore AS String, Calculated AS String, Stored AS String)

		INSERT INTO DPIAwareManagerLog (ControlName, ClassName, Property, ;
					Original, Ratio, NewRatio, ;
					FixedProperty, ;
					ScaledBefore, Calculated, Stored) ;
				VALUES (m.ControlName, m.ClassName, m.Property, ;
					m.Original, m.Ratio, m.NewRatio, ;
					m.FixedProperty, ;
					m.ScaledBefore, m.Calculated, m.Stored)

	ENDFUNC

ENDDEFINE


