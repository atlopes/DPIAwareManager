
SET PROCEDURE TO (SYS(16)) ADDITIVE

#DEFINE WM_DPICHANGED       				0x02E0

#DEFINE SIZEOF_MONITORINFO					0h28000000

#DEFINE DPI_STANDARD							96
#DEFINE DPI_STANDARD_SCALE					100
#DEFINE DPI_MAX_SCALE						225
#DEFINE DPI_SCALE_INCREMENT				25

#DEFINE DPIAW_NO_REPOSITION				0
#DEFINE DPIAW_RELATIVE_TOP_LEFT			0x01
#DEFINE DPIAW_CONSTRAINT_DIMENSION		0x02

Define Class DPIAwareManager As Custom

	* compensation for what is cut from a form when changing DPI (from 125 to 225%)
	* to be confirmed...
	WidthAdjustments = "2,6,8,10,12"
	HeightAdjustments = "8,17,25,32,40"

	FUNCTION Init

		DECLARE LONG GetDC IN WIN32API ;
			LONG hWnd
		DECLARE LONG GetWindowDC IN WIN32API ;
			LONG hWnd
		DECLARE LONG GetDeviceCaps IN WIN32API  ;
			LONG hDC, INTEGER CapIndex
		DECLARE LONG MonitorFromWindow IN WIN32API ;
			LONG hWnd, INTEGER Flags
		DECLARE INTEGER GetMonitorInfo IN WIN32API ;
			LONG hMonitor, STRING @ MonitorInfo
		DECLARE INTEGER GetDpiForWindow IN WIN32API ;
			LONG hWnd
		TRY
			DECLARE LONG GetDpiForMonitor IN SHCORE.DLL ;
				LONG hMonitor, INTEGER dpiType, INTEGER @ dpiX, INTEGER @ dpiY
		CATCH
		ENDTRY

	ENDFUNC

	* Manage
	* Puts a form under DPI-awareness management
	* It should be called before the form is shown
	FUNCTION Manage (AForm AS Form) AS Void

		* add DPI-aware related properties
		This.AddDPIProperty(m.AForm, "hMonitor", MonitorFromWindow(m.AForm.HWnd, 0))
		This.AddDPIProperty(m.AForm, "DPIAwareManager", This)
		This.AddDPIProperty(m.AForm, "DPIScale", DPI_STANDARD_SCALE)
		This.AddDPIProperty(m.AForm, "DPINewScale", This.GetMonitorDPIScale(m.AForm))
		This.AddDPIProperty(m.AForm, "DPIAutoConstraint", IIF(m.AForm = _Screen OR m.AForm.ShowWindow = 2, DPIAW_NO_REPOSITION, DPIAW_RELATIVE_TOP_LEFT))

		* save the original value of dimensional and positional properties of the form
		This.SaveContainer(m.AForm)

		* bind the form to the two listeners for changes of the DPI scale
		IF m.AForm = _Screen
			BINDEVENT(_Screen, "Moved", This, "CheckDPIScaleChange")
		ENDIF
		BINDEVENT(m.AForm.hWnd, WM_DPICHANGED, This, "WMCheckDPIScaleChange")

		* if the form was created in a non 100% scale monitor, perform an initial scaling
		IF m.AForm.DPINewScale != m.AForm.DPIScale
			This.Scale(m.AForm, m.AForm.DPIScale, m.AForm.DPINewScale)
		ENDIF

	ENDFUNC

****************************************************************************************
#DEFINE METHODS_SYSTEM_INFORMATION
****************************************************************************************

	* GetMonitorDPIScale
	* Returns the DPI scale of a monitor that a form is using.
	* The scale is a percentage (100%, 125%, ...).
	FUNCTION GetMonitorDPIScale (DPIAwareForm AS Form) AS Integer
	LOCAL dpiX AS Integer, dpiY AS Integer

		* use the best available function to get the information
		TRY
			m.dpiX = GetDpiForWindow(m.DPIAwareForm.HWnd)
		CATCH
			TRY
				STORE 0 TO m.dpiX, m.dpiY
				GetDpiForMonitor(m.DPIAwareForm.hMonitor, 0, @m.dpiX, @m.dpiY)
			CATCH
				m.dpiX = GetDeviceCaps(GetWindowDC(m.DPIAwareForm.HWnd), 88)
			ENDTRY
		ENDTRY

		* returns a percentage relative to 96DPI (the standard DPI)
		RETURN MIN(MAX(INT(m.dpiX / DPI_STANDARD * DPI_STANDARD_SCALE), DPI_STANDARD_SCALE), DPI_MAX_SCALE)

	ENDFUNC

	* GetMonitorInfo
	* Returns dimensional and position information of a monitor.
	FUNCTION GetMonitorInfo (hMonitor AS Integer, IsWorkArea AS Logical) AS Object

		LOCAL MonitorInfoStructure AS String
		LOCAL Rect AS String
		LOCAL MonitorInfo AS Empty

		m.MonitorInfoStructure = SIZEOF_MONITORINFO + REPLICATE(CHR(0), 36)

		GetMonitorInfo(m.hMonitor, @m.MonitorInfoStructure)

		IF !m.IsWorkArea
			m.Rect = SUBSTR(m.MonitorInfoStructure, 5, 16)
		ELSE
			m.Rect = SUBSTR(m.MonitorInfoStructure, 21, 16)
		ENDIF

		m.MonitorInfo = CREATEOBJECT("Empty")
		ADDPROPERTY(m.MonitorInfo, "Left", CTOBIN(SUBSTR(m.Rect, 1, 4), "4RS"))
		ADDPROPERTY(m.MonitorInfo, "Top",  CTOBIN(SUBSTR(m.Rect, 5, 4), "4RS"))
		ADDPROPERTY(m.MonitorInfo, "Right", CTOBIN(SUBSTR(m.Rect, 9, 4), "4RS"))
		ADDPROPERTY(m.MonitorInfo, "Bottom", CTOBIN(SUBSTR(m.Rect, 13, 4), "4RS"))
		ADDPROPERTY(m.MonitorInfo, "Width", m.MonitorInfo.Right - m.MonitorInfo.Left)
		ADDPROPERTY(m.MonitorInfo, "Height", m.MonitorInfo.Bottom - m.MonitorInfo.Top)

		RETURN m.MonitorInfo

	ENDFUNC

	* GetFormDPIScale
	* Returns the DPI Scale of the form that contains an object.
	FUNCTION GetFormDPIScale (DPIAwareObject AS Object) AS Integer

		LOCAL DPIScale AS Integer
		LOCAL ThisObject AS Object

		* look for a form in the (parent) hierarchy of the object
		m.ThisObject = m.DPIAwareObject
		DO WHILE !m.ThisObject.BaseClass == "Form" AND PEMSTATUS(m.ThisObject, "Parent", 5)
			m.ThisObject = m.ThisObject.Parent
		ENDDO

		RETURN IIF(m.ThisObject.BaseClass == "Form", m.ThisObject.DPIScale, DPI_STANDARD_SCALE)
			
	ENDFUNC


****************************************************************************************
#DEFINE METHODS_AKNOWLEDGE_AND_REACT_TO_DPI_CHANGES
****************************************************************************************

	* WMCheckDPIScaleChange
	* Receives a Windows message when the DPI has changed for the hWnd of a form.
	FUNCTION WMCheckDPIScaleChange (hWnd, uMsg, wParam, lParam)

		LOCAL DPIAwareForm AS Form
		LOCAL CreatedForm AS 

		m.DPIAwareForm = .NULL.

		* look for all forms until the matching hWnd is found
		FOR EACH m.CreatedForm AS Form IN _Screen.Forms
			IF m.CreatedForm.HWnd = m.hWnd
				m.DPIAwareForm = m.CreatedForm
				EXIT
			ENDIF
		ENDFOR

		IF ISNULL(m.DPIAwareForm)
			RETURN 0
		ENDIF

		* proceed to the actual method that performs the rescaling (the new DPI scale is passed as a percentage)
		RETURN This.ChangeFormDPIScale(m.DPIAwareForm, BITAND(m.wParam, 0x0FF) / DPI_STANDARD * DPI_STANDARD_SCALE)

	ENDFUNC

	* CheckDPIScaleChange
	* Notice when a DPI has changed and triggered a Moved event.
	FUNCTION CheckDPIScaleChange ()

		LOCAL ARRAY SourceEvent(1)
		AEVENTS(m.SourceEvent, 0)

		LOCAL DPIAwareForm AS Form
		m.DPIAwareForm = m.SourceEvent(1)

		This.ChangeFormDPIScale(m.DPIAwareForm, This.GetMonitorDPIScale(m.DPIAwareForm))

		IF m.DPIAwareForm = _Screen

			FOR EACH m.DPIAwareForm AS Form IN _Screen.Forms
				IF m.DPIAwareForm.ShowWindow = 0
					This.ChangeFormDPIScale(m.DPIAwareForm, _Screen.DPIScale)
				ENDIF
			ENDFOR

		ENDIF

	ENDFUNC

	* ChangeFormDPIScale
	* Change the DPI scale of a form.
	FUNCTION ChangeFormDPIScale (DPIAwareForm AS Form, NewDPIScale AS Integer) AS Integer

		LOCAL Ops AS Exception

		* refresh information on the monitor where the form is being displayed
		m.DPIAwareForm.hMonitor = MonitorFromWindow(m.DPIAwareForm.HWnd, 0)

		* act only if the scale of the form has changed (the _Screen may only have moved)
		IF m.NewDPIScale != m.DPIAwareForm.DPIScale

			LOCAL IsMaximized AS Logical
			m.IsMaximized = (m.DPIAwareForm.WindowState = 2)

			m.DPIAwareForm.DPINewScale = m.NewDPIScale
			m.DPIAwareForm.LockScreen = .T.

			* perform the actual scaling
			TRY
				This.Scale(m.DPIAwareForm, m.DPIAwareForm.DPIScale, m.NewDPIScale)
				This.EnforceFormConstraints(m.DPIAwareForm)
			CATCH TO m.oPS
				* quick dirty info on error
				MESSAGEBOX(TEXTMERGE("<<m.ops.message>> @ <<m.ops.linecontents>> / <<m.Ops.Lineno>>"))
			ENDTRY

			m.DPIAwareForm.LockScreen = .F.
			m.DPIAwareForm.DPIScale = m.NewDPIScale

			IF m.IsMaximized
				m.DPIAwareForm.WindowState = 2
			ENDIF

		ENDIF

		RETURN 0

	ENDFUNC

	* EnforceFormConstraints
	* Constraints the dimension and position of the form (according to the DPIAutoConstraint property):
	* - DPIAW_RELATIVE_TOP_LEFT form is placed relative top left to its container (_Screen or monitor)
	* - DPIAW_CONSTRAINT_DIMENSION form won't be bigger than the target monitor
	FUNCTION EnforceFormConstraints (DPIAwareForm AS Form)

		LOCAL XYRatio AS Number
		LOCAL NewXYRatio AS Number
		LOCAL OverDimension AS Number
		LOCAL TargetDimension AS Number

		m.XYRatio = This.GetXYRatio(m.DPIAwareForm.DPIScale)
		m.NewXYRatio = This.GetXYRatio(m.DPIAwareForm.DPINewScale)

		IF BITAND(m.DPIAwareForm.DPIAutoConstraint, DPIAW_RELATIVE_TOP_LEFT) != 0
			m.DPIAwareForm.Top = (m.DPIAwareForm.Top / m.XYRatio) * m.NewXYRatio
			m.DPIAwareForm.Left = (m.DPIAwareForm.Left / m.XYRatio) * m.NewXYRatio
		ENDIF

		IF BITAND(m.DPIAwareForm.DPIAutoConstraint, DPIAW_CONSTRAINT_DIMENSION) != 0

			m.Monitor = This.GetMonitorInfo(m.DPIAwareForm.hMonitor, .T.)

			m.OverDimension = m.DPIAwareForm.Width - m.Monitor.Width
			IF m.OverDimension > 0
				m.TargetDimension = m.DPIAwareForm.Width - m.OverDimension
				IF m.DPIAwareForm.MinWidth = -1 OR (m.DPIAwareForm.MinWidth < m.TargetDimension)
					m.DPIAwareForm.Width = m.TargetDimension
				ENDIF
			ENDIF

			m.OverDimension = m.DPIAwareForm.Height - m.Monitor.Height
			IF m.OverDimension > 0
				m.TargetDimension = m.DPIAwareForm.Height - m.OverDimension
				IF m.DPIAwareForm.MinHeight = -1 OR (m.DPIAwareForm.MinHeight < m.TargetDimension)
					m.DPIAwareForm.Height = m.TargetDimension
				ENDIF
			ENDIF

		ENDIF

	ENDFUNC

****************************************************************************************
#DEFINE METHODS_SAVE_ORIGINAL_PROPERTY_VALUES
****************************************************************************************

	* SaveContainer
	* Save the properties of a container object.
	FUNCTION SaveContainer (Ctrl AS Object)

		LOCAL SubCtrl AS Object

		This.SaveOriginalInfo(m.Ctrl)

		FOR EACH m.SubCtrl In m.Ctrl.Controls
			This.SaveControl(m.SubCtrl)
		ENDFOR

	ENDFUNC

	* SaveControl
	* Save the properties of an object.
	FUNCTION SaveControl (Ctrl AS Object)

		LOCAL SubCtrl AS Object

		IF !m.Ctrl.BaseClass == "Custom"
			This.SaveOriginalInfo(m.Ctrl)
		ENDIF

		DO CASE 

		CASE m.Ctrl.BaseClass == 'Container'
			This.SaveContainer(m.Ctrl)

		CASE m.Ctrl.BaseClass == 'Pageframe'

			FOR EACH SubCtrl IN m.Ctrl.Pages
				This.SaveContainer(m.SubCtrl)
			ENDFOR

		CASE m.Ctrl.BaseClass == 'Grid'

			FOR EACH SubCtrl IN m.Ctrl.Columns
				This.SaveOriginalInfo(m.SubCtrl)
			ENDFOR

		CASE m.Ctrl.BaseClass $ 'Commandgroup,Optiongroup'

			FOR EACH SubCtrl IN m.Ctrl.Buttons
				This.SaveOriginalInfo(m.SubCtrl)
			ENDFOR
			m.Ctrl.AutoSize = m.Ctrl.AutoSize

		ENDCASE

	ENDFUNC

	* SaveOriginalProperty
	* Saves the original value of a property by creating a DPIAware_<property name> new property.
	FUNCTION SaveOriginalProperty (Ctrl AS Object, Property AS String)

		IF PEMSTATUS(m.Ctrl, m.Property, 5)
			This.AddDPIProperty(m.Ctrl, "DPIAware_" + m.Property, EVALUATE("m.Ctrl." + m.Property))
		ENDIF

	ENDFUNC

	* SaveOriginalInfo
	* Saves the original information of an object (non-existing properties will be ignored).
	FUNCTION SaveOriginalInfo (Ctrl AS Object)

		This.AddDPIProperty(m.Ctrl, "DPIAware", .T.)
		This.SaveOriginalProperty(m.Ctrl, "Anchor")
		This.SaveOriginalProperty(m.Ctrl, "Width")
		This.SaveOriginalProperty(m.Ctrl, "MinWidth")
		This.SaveOriginalProperty(m.Ctrl, "MaxWidth")
		This.SaveOriginalProperty(m.Ctrl, "Height")
		This.SaveOriginalProperty(m.Ctrl, "MinHeight")
		This.SaveOriginalProperty(m.Ctrl, "MaxHeight")
		This.SaveOriginalProperty(m.Ctrl, "Left")
		This.SaveOriginalProperty(m.Ctrl, "Top")
		This.SaveOriginalProperty(m.Ctrl, "FontSize")
		This.SaveOriginalProperty(m.Ctrl, "RowHeight")
		This.SaveOriginalProperty(m.Ctrl, "HeaderHeight")

		This.SaveGraphicAlternatives(m.Ctrl, "Picture")
		This.SaveGraphicAlternatives(m.Ctrl, "PictureVal")
		This.SaveGraphicAlternatives(m.Ctrl, "Icon")

	ENDFUNC

	* SaveGraphicAlternatives
	* Identifies and saves the alternate graphic properties (Picture, PictureVal, and Icon).
	* Alternative graphics are set at design time in properties to which a DPI scale has been added.
	* For instance, Picture100, Picture125, and Picture150 serve as alternatives to the Picture property
	*   when the DPI scale is 100, 125, and 150 or above.
	FUNCTION SaveGraphicAlternatives (Ctrl AS Object, Property AS String)

		LOCAL AlternativesList AS String
		LOCAL AlternativeLevel AS Integer
		LOCAL ARRAY Properties[1]
		LOCAL PropertyIndex AS Integer
		LOCAL PropertyCheck AS String
		LOCAL PropertyCheckLen AS Integer

		IF !PEMSTATUS(m.Ctrl, m.Property, 5)
			RETURN
		ENDIF

		m.AlternativesList = ""
		m.PropertyCheck = UPPER(m.Property)
		m.PropertyCheckLen = LEN(m.PropertyCheck)

		* look for all alternatives and create a single comma separeted list 
		FOR m.PropertyIndex = 1 TO AMEMBERS(m.Properties, m.Ctrl, 0)
			IF LEFT(m.Properties[m.PropertyIndex], m.PropertyCheckLen) == m.PropertyCheck
				m.AlternativeLevel = SUBSTR(m.Properties[m.PropertyIndex], m.PropertyCheckLen + 1)
				IF m.AlternativeLevel == LTRIM(STR(VAL(m.AlternativeLevel))) AND VAL(m.AlternativeLevel) >= DPI_STANDARD_SCALE
					m.AlternativesList = m.AlternativesList + IIF(EMPTY(m.AlternativesList), "", ",") + m.AlternativeLevel
				ENDIF
			ENDIF
		ENDFOR

		* if a list was found, store it at a new object property
		IF !EMPTY(m.AlternativesList)
			This.AddDPIProperty(m.Ctrl, "DPIAlternative_" + m.Property, m.AlternativesList)
		ENDIF

	ENDFUNC

****************************************************************************************
#DEFINE METHODS_SCALE_FORMS_AND_CONTROLS
****************************************************************************************

	* Scale
	* Scale a container from one scale to another.
	FUNCTION Scale (Ctnr AS Object, DPIScale AS Number, DPINewScale AS Number)

		LOCAL IsForm AS Logical
		LOCAL SubCtrl AS Object
		LOCAL Scalable AS Logical

		m.IsForm = m.Ctnr.BaseClass == 'Form'

		* forms require a pre-adjustement because the way Windows/VFP(?) pass from one scale to another,
		*   removing a few fixed pixels from the form dimensions (width and height) - this is done automatically as soon
		*   as the DPI scales changes and before the DPIAwareManager has a chance to step in
		IF m.IsForm
			This.PreAdjustFormDimensions(m.Ctnr, m.DPIScale, m.DPINewScale)
		ENDIF

		* If the container is not DPI aware, don't touch it
		TRY
			m.Scalable = NVL(m.Ctnr.DPIAware, .F.)
		CATCH
			m.Scalable = .F.
		ENDTRY

		IF !m.Scalable
			RETURN
		ENDIF

		* all anchors in a form are set to zero, so that the scale won't trigger resize and reposition of containde controls
		IF m.IsForm

			m.Ctnr.LockScreen = .T.
			This.SetAnchor(m.Ctnr, .T.)

			* perform the actual resizing of the form
			This.AdjustSize(m.Ctnr, m.DPIScale, m.DPINewScale)

		ENDIF

		* do the resizing for all contained controls
		FOR EACH m.SubCtrl IN m.Ctnr.Controls
			This.ScaleControl(m.SubCtrl, m.DPIScale, m.DPINewScale)
		ENDFOR

		* when a form is finished, get back all anchors
		IF m.IsForm

			This.SetAnchor(m.Ctnr, .F.)
			m.Ctnr.LockScreen = .F.

		ENDIF

	ENDFUNC

	* ScaleControl
	* Scales a control from one scale to another.
	FUNCTION ScaleControl (Ctrl AS Object, DPIScale as Number, DPINewScale as Number)

		LOCAL SubCtrl AS Object

		IF !m.Ctrl.BaseClass $ 'Custom,Grid'
			This.AdjustSize(m.Ctrl, m.DPIScale, m.DPINewScale)
		ENDIF

		DO CASE
		CASE m.Ctrl.BaseClass == 'Container'

			This.Scale(m.Ctrl, m.DPIScale, m.DPINewScale)

		CASE m.Ctrl.BaseClass == 'Pageframe'

			FOR EACH m.SubCtrl AS Page IN m.Ctrl.Pages
				This.AdjustSize(m.SubCtrl, m.DPIScale, m.DPINewScale)
				This.Scale(m.SubCtrl, m.DPIScale, m.DPINewScale)
			ENDFOR

		CASE m.Ctrl.BaseClass == 'Grid'

			FOR EACH m.SubCtrl AS Column IN m.Ctrl.Columns
				This.AdjustSize(m.SubCtrl, m.DPIScale, m.DPINewScale)
			ENDFOR
			This.AdjustSize(m.Ctrl, m.DPIScale, m.DPINewScale)

		CASE m.Ctrl.BaseClass $ 'Commandgroup,Optiongroup'

			FOR EACH m.SubCtrl In m.Ctrl.Buttons
				This.AdjustSize(m.SubCtrl, m.DPIScale, m.DPINewScale)
			ENDFOR
		ENDCASE

	ENDFUNC

	* SetAnchor
	* Sets or unsets (sets to zero) the property Anchor of a container and of its contained controls. 
	FUNCTION SetAnchor (Cntr AS Object, Unset AS Logical)

		LOCAL SubCtrl AS Object

		FOR EACH m.SubCtrl IN m.Cntr.Controls
			This.SetAnchorControl(m.SubCtrl, m.Unset)
		ENDFOR

	ENDFUNC

	* SetAnchorControl
	* Sets or unsets (sets to zero) the property Anchor of a control. 
	FUNCTION SetAnchorControl (Ctrl AS Object, Unset AS Logical)

		LOCAL SubCtrl AS Object

		TRY
			m.Ctrl.Anchor = IIF(m.Unset, 0, m.Ctrl.DPIAWare_Anchor)
		CATCH
		ENDTRY

		DO CASE
		CASE m.Ctrl.BaseClass == 'Container'

			This.SetAnchor(m.Ctrl, m.Unset)

		CASE m.Ctrl.BaseClass == 'Pageframe'

			FOR EACH m.SubCtrl AS Page IN m.Ctrl.Pages
				This.SetAnchor(m.SubCtrl, m.Unset)
			ENDFOR

		CASE m.Ctrl.BaseClass == 'Grid'

			FOR EACH m.SubCtrl AS Column IN m.Ctrl.Columns
				This.SetAnchor(m.SubCtrl, m.Unset)
			ENDFOR 

		CASE m.Ctrl.BaseClass $ 'Commandgroup,Optiongroup'

			FOR EACH m.SubCtrl IN m.Ctrl.Buttons
				This.SetAnchorControl(m.SubCtrl, m.Unset)
			ENDFOR

		ENDCASE

	ENDFUNC

	* PreAdjustFormDimensions
	* Pre-adjusts form dimensions (width and height) - Windows (and/or VFP?) seems to cut a fixed amount of
	*   pixels when moving from one scale to the other.
	FUNCTION PreAdjustFormDimensions (Ctrl AS Form, DPIScale AS Number, NewDPIScale AS Number)

		LOCAL Scale AS Integer
		LOCAL WidthAdjustment AS Integer
		LOCAL HeightAdjustment AS Integer

		* scale level: 0 = 100, 1 = 125, 2 = 150, etc.
		m.Scale = This.GetDPILevel(m.NewDPIScale)
		m.WidthAdjustment = VAL(GETWORDNUM(This.WidthAdjustments, m.Scale, ","))
		m.HeightAdjustment = VAL(GETWORDNUM(This.HeightAdjustments, m.Scale, ","))

		* add the adjustments to the cutted dimensions, to compensate for the cutting 
		m.Ctrl.Width = m.Ctrl.Width + m.WidthAdjustment
		m.Ctrl.Height = m.Ctrl.Height + m.HeightAdjustment

		m.Scale = This.GetDPILevel(m.DPIScale)
		m.WidthAdjustment = VAL(GETWORDNUM(This.WidthAdjustments, m.Scale, ","))
		m.HeightAdjustment = VAL(GETWORDNUM(This.HeightAdjustments, m.Scale, ","))

		* but remove the adjustments made previously
		m.Ctrl.Width = m.Ctrl.Width - m.WidthAdjustment
		m.Ctrl.Height = m.Ctrl.Height - m.HeightAdjustment

	ENDFUNC

****************************************************************************************
#DEFINE METHODS_ADJUST_DIMENSION_AND_PROPERTIES_TO_NEW_SCALE
****************************************************************************************

	* AdjustSize
	* Adjusts the size and position of a control from a scale to another.
	Function AdjustSize (Ctrl AS Object, DPIScale as Number, NewDPIScale AS Number)

		LOCAL IsForm AS Logical

		LOCAL XYRatio AS Number, NewXYRatio AS Number

		LOCAL IsGrowing AS Logical

		* XY ratios are the multipliers for both scales
		m.XYRatio = This.GetXYRatio(m.DPIScale)
		m.NewXYRatio = This.GetXYRatio(m.NewDPIScale)

		* how are we growing?
		m.IsGrowing = m.DPIScale < m.NewDPIScale

		m.IsForm = m.Ctrl.BaseClass == "Form"

		* row height and header height before font size, unless they're marked as Auto
		This.AdjustPropertyValue(m.Ctrl, "RowHeight", m.XYRatio, m.NewXYRatio, -1)
		This.AdjustPropertyValue(m.Ctrl, "HeaderHeight", m.XYRatio, m.NewXYRatio, -1)

		* ajust font size always from its original setting (hence, taken as a "fixed" property)
		This.AdjustFixedPropertyValue(m.Ctrl, "FontSize", m.XYRatio, m.NewXYRatio)

		* if we are growing, make sure we grow maximum dimensions before growing
		IF m.IsGrowing
			This.AdjustFixedPropertyValue(m.Ctrl, "MaxWidth", m.XYRatio, m.NewXYRatio, -1)
			This.AdjustFixedPropertyValue(m.Ctrl, "MaxHeight", m.XYRatio, m.NewXYRatio, -1)
			This.AdjustPropertyValue(m.Ctrl, "Width", m.XYRatio, m.NewXYRatio)
			This.AdjustPropertyValue(m.Ctrl, "Height", m.XYRatio, m.NewXYRatio)
			This.AdjustFixedPropertyValue(m.Ctrl, "MinWidth", m.XYRatio, m.NewXYRatio, -1)
			This.AdjustFixedPropertyValue(m.Ctrl, "MinHeight", m.XYRatio, m.NewXYRatio, -1)
		* or the other way around, if shrinking
		ELSE
			This.AdjustFixedPropertyValue(m.Ctrl, "MinWidth", m.XYRatio, m.NewXYRatio, -1)
			This.AdjustFixedPropertyValue(m.Ctrl, "MinHeight", m.XYRatio, m.NewXYRatio, -1)
			This.AdjustPropertyValue(m.Ctrl, "Width", m.XYRatio, m.NewXYRatio)
			This.AdjustPropertyValue(m.Ctrl, "Height", m.XYRatio, m.NewXYRatio)
			This.AdjustFixedPropertyValue(m.Ctrl, "MaxWidth", m.XYRatio, m.NewXYRatio, -1)
			This.AdjustFixedPropertyValue(m.Ctrl, "MaxHeight", m.XYRatio, m.NewXYRatio, -1)
		ENDIF

		* for all controls except forms, deal with their position
		IF !m.IsForm
			This.AdjustPropertyValue(m.Ctrl, "Top", m.XYRatio, m.NewXYRatio)
			This.AdjustPropertyValue(m.Ctrl, "Left", m.XYRatio, m.NewXYRatio)
		ENDIF

		* finally, take care of the alternate graphics the control may have defined for the new scale
		This.AdjustGraphicAlternatives(m.Ctrl, m.NewDPIScale)

	ENDFUNC

	* AdjustPropertyValue
	* Adjusts the value of a property to a new value.
	FUNCTION AdjustPropertyValue (Ctrl AS Object, Property AS String, Ratio AS Number, NewRatio AS Number, Excluded AS Number) AS Logical

		LOCAL Adjusted AS Logical
		LOCAL OriginalValue AS Number
		LOCAL CurrentValue AS Number
		LOCAL NewCurrentValue AS Number

		m.Adjusted = .F.

		IF PEMSTATUS(m.Ctrl, "DPIAware_" + m.Property, 5)
			TRY
				* regular properties are scaled from the current value
				* unless they are excluded for bing automatic or unset
				m.OriginalValue = EVALUATE("m.Ctrl.DPIAware_" + m.Property)
				IF PCOUNT() < 5 OR m.Excluded != m.OriginalValue

					* get the current value, stored in the property, and calculate the new one for a new scale
					m.CurrentValue = EVALUATE("m.Ctrl." + m.Property)
					m.NewCurrentValue = m.CurrentValue / m.Ratio * m.NewRatio

					* store the final (rounded) value
					STORE ROUND(m.NewCurrentValue, 0) TO ("m.Ctrl." + m.Property)

					* log the adjustment
					TRY
						IF USED("DPIAwareManagerLog")
							INSERT INTO DPIAwareManagerLog (ControlName, ClassName, Property, Original, Ratio, NewRatio, ;
									FixedProperty, ScaledBefore, Calculated, Stored) ;
								VALUES (m.Ctrl.Name, m.Ctrl.Class, m.Property, m.OriginalValue, m.Ratio, m.NewRatio, ;
									.F., m.CurrentValue, m.NewCurrentValue, EVALUATE("m.Ctrl." + m.Property))
						ENDIF
					CATCH
					ENDTRY

					m.Adjusted = .T.

				ENDIF
			CATCH
			ENDTRY
		ENDIF

		RETURN m.Adjusted

	ENDFUNC

	* AdjustFixedPropertyValue
	* Adjusts the original value of a property to a new value.
	FUNCTION AdjustFixedPropertyValue (Ctrl AS Object, Property AS String, Ratio AS Number, NewRatio AS Number, Excluded AS Number) AS Logical

		LOCAL Adjusted AS Logical
		LOCAL OriginalValue AS Number
		LOCAL NewCurrentValue AS Number

		m.Adjusted = .F.

		IF PEMSTATUS(m.Ctrl, "DPIAware_" + m.Property, 5)
			TRY
				* fixed properties are scaled from the original value
				* unless they are excluded for bing automatic or unset
				m.OriginalValue = EVALUATE("m.Ctrl.DPIAware_" + m.Property)
				IF PCOUNT() < 5 OR m.Excluded != m.OriginalValue

					* calculate the new value
					m.NewCurrentValue = m.OriginalValue * m.NewRatio

					* store the final (rounded) value
					STORE ROUND(m.NewCurrentValue, 0) TO ("m.Ctrl." + m.Property)

					* log the adjustment
					TRY
						IF USED("DPIAwareManagerLog")
							INSERT INTO DPIAwareManagerLog (ControlName, ClassName, Property, Original, Ratio, NewRatio, ;
									FixedProperty, ScaledBefore, Calculated, Stored) ;
								VALUES (m.Ctrl.Name, m.Ctrl.Class, m.Property, m.OriginalValue, m.Ratio, m.NewRatio, ;
									.T., m.NewCurrentValue, m.NewCurrentValue, EVALUATE("m.Ctrl." + m.Property))
						ENDIF
					CATCH
					ENDTRY

					m.Adjusted = .T.
				ENDIF
			CATCH
			ENDTRY
		ENDIF

		RETURN m.Adjusted

	ENDFUNC

	* AdjustGraphicAlternatives
	* Adjusts the value of graphic properties by selecting an appropriate alternative.
	FUNCTION AdjustGraphicAlternatives (Ctrl AS Object, NewDPIScale AS Number)

		IF PEMSTATUS(m.Ctrl, "DPIAlternative_Picture", 5)
			This.FindGraphicAlternative(m.Ctrl, "Picture", m.Ctrl.DPIAlternative_Picture, m.NewDPIScale)
		ENDIF

		IF PEMSTATUS(m.Ctrl, "DPIAlternative_PictureVal", 5)
			This.FindGraphicAlternative(m.Ctrl, "PictureVal", m.Ctrl.DPIAlternative_PictureVal, m.NewDPIScale)
		ENDIF

		IF PEMSTATUS(m.Ctrl, "DPIAlternative_Icon", 5)
			This.FindGraphicAlternative(m.Ctrl, "Icon", m.Ctrl.DPIAlternative_Icon, m.NewDPIScale)
		ENDIF

	ENDFUNC

	* FindGraphicAlternative
	* Finds a best alternate graphic for the new scale.
	FUNCTION FindGraphicAlternative (Ctrl AS Object, Property AS String, Alternatives AS String, DPIScale AS Number)

		LOCAL ARRAY AlternativeScales[1]
		LOCAL AlternativesIndex AS Integer
		LOCAL BestAlternative AS String
		LOCAL BestDifference AS Integer, Difference AS Integer

		BestDifference = -1
		BestAlternative = ""

		* go through the list of scales for which there is an alternative
		FOR m.AlternativesIndex = 1 TO ALINES(m.AlternativeScales, m.Alternatives, 0, ",")

			* calculate the difference for the new scale
			m.Difference = VAL(m.AlternativeScales[m.AlternativesIndex]) - m.DPIScale

			* there is a match! get the value in the alternate graphic property and stop searching
			IF m.Difference = 0
				m.BestAlternative = EVALUATE("m.Ctrl." + m.Property + m.AlternativeScales[m.AlternativesIndex])
				EXIT
			ENDIF

			* but if not and this one was the best yet, use it and continue looking
			IF m.Difference > 0 AND m.Difference < m.BestDifference
				m.BestAlternative = EVALUATE("m.Ctrl." + m.Property + m.AlternativeScales[m.AlternativesIndex])
				m.BestDifference = m.Difference
			ENDIF
		ENDFOR

		* if we found an alternative, that will be the new value for the property
		IF !EMPTY(m.BestAlternative)
			STORE m.BestAlternative TO ("m.Ctrl." + m.Property)
		ENDIF

	ENDFUNC

****************************************************************************************
#DEFINE METHODS_HELPER
****************************************************************************************

	* AddControl
	* Adds a control in run-time (scaled at 96/100%)
	FUNCTION AddControl (NewControl AS Object)

		This.SaveControl(m.NewControl)
		This.ScaleControl(m.NewControl, DPI_STANDARD_SCALE, This.GetFormDPIScale(m.NewControl))

	ENDFUNC

****************************************************************************************
#DEFINE METHODS_UTILITIES
****************************************************************************************

	* AddDPIProperty
	* Adds a DPI-awareness related property to an object (fails silently)
	FUNCTION AddDPIProperty (Ctrl AS Object, Property AS String, InitialValue) AS Void

		TRY
			m.Ctrl.AddProperty(m.Property, m.InitialValue)
		CATCH
		ENDTRY

	ENDFUNC

	* Log
	* Starts a logger
	FUNCTION Log ()

		CREATE CURSOR DPIAwareManagerLog ;
			(PK Int AutoInc, ;
				ControlName Varchar(60), ClassName Varchar(60), Property Varchar(32), ;
				Original Double, ;
				Ratio Double, NewRatio Double, ;
				FixedProperty Logical, ;
				ScaledBefore Double, Calculated Double, Stored Double)

	ENDFUNC

	* GetXYRatio
	* Gets a ratio multiplier, given a scale
	HIDDEN FUNCTION GetXYRatio (Scale AS Integer) AS Number

		RETURN m.Scale / DPI_STANDARD_SCALE

	ENDFUNC

	* GetDPILevel
	* Gets s DPI level (0, 1, 2...) given a scale.
	FUNCTION GetDPILevel (DPIScale AS Integer) AS Integer

		RETURN ROUND((m.DPIScale - DPI_STANDARD_SCALE) / DPI_SCALE_INCREMENT, 0)

	ENDFUNC

ENDDEFINE

* a template for DPI-aware classes
DEFINE CLASS DPIAware_Optiongroup AS OptionGroup

	DPIAware = .NULL.

	FUNCTION Visible_Assign (Visibility AS Logical)

		This.Visible = m.Visibility
		IF m.Visibility AND ISNULL(This.DPIAware)
			IF TYPE("Thisform") == "O" AND PEMSTATUS(Thisform, "DPIAware", 5) AND Thisform.DPIAware
				Thisform.DPIAwareProcessor.AddControl(This)
				This.DPIAware = .T.
			ELSE
				This.DPIAware = .F.
			ENDIF
		ENDIF

	ENDFUNC

ENDDEFINE
