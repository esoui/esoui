--[[

Tab Buttons and Tab Button Groups:

These are a combination of a "check button" and a "radio group".  They are typically hung off one of the edges of a window
and used to indicate which sub-panel within the window is currently active.  Usual uses include Chat Channel/Filter management
and Character Pane management (displaying separate panes for skills, gear, pets, etc...)

Usage:

Initialize tab buttons with a type, this determines the textures that will be used as the button switches states (mouseover,
pressed, unpressed...)  Do not set the textures manually.  Valid types are defined in the TAB_DATA table.

Assign a callback function to the tab button so that when pressed or unpressed, it knows what action to take.  Typically the 
tab button only needs to take some action when it's pressed, not when it becomes unpressed; this is up to the system using
the tab buttons.

After creating and initializing a number of tab buttons, add them to a group which will manage their state and call the 
appropriate callbacks as the user interacts with the window.

--]]

-- NOTE: Right and left edge will generally use icons and not labels.
-- When we need to implement them, they probably will need a very custom structure
-- that doesn't need to take advantage of the horizontal resizing of the tab.

local DL_ABOVE = 2
local DL_BELOW = 1

local PRESSED = 1
local UNPRESSED = 2
local DISABLED = 3

local TAB_DATA =
{
    TopEdgeImage =
    {
        UnpressedImage              = "EsoUI/Art/Tabs/tab_top_inactive.dds",
        PressedImage                = "EsoUI/Art/Tabs/tab_chat_active.dds",
        UnpressedMouseOverImage     = "EsoUI/Art/Tabs/tab_top_inactive_mouseOver.dds",
        LeftCoords                  = { left = 0, right = 0.25, top = 0, bottom = 1 },      -- NOTE: Assumes that the left and right slices match for pressed/unpressed
        RightCoords                 = { left = 0.75, right = 1, top = 0, bottom = 1 },
        CenterCoords                = { left = 0.25, right = 0.75, top = 0, bottom = 1 },
        SideSize                    = 12,
        Height                      = 24,
        MinFixedWidth               = 80,
        TooltipPosition             = TOP,
        HasIcon                     = true,
        HasTabMouseOver             = true,
    },

    SimpleIcon =
    {
        SideSize                    = 0,
        TooltipPosition             = TOP,
        HasIcon                     = true,
        HasTabMouseOver             = true,
    },

    CroppedSimpleIcon =
    {
        SideSize                    = -16,
        TooltipPosition             = TOP,
        HasIcon                     = true,
        HasTabMouseOver             = true,
    },

    SimpleIconHighlight =
    {
        SideSize                    = 0,
        TooltipPosition             = TOP,
        HasIcon                     = true,
        HasTabMouseOver             = true,
        HasHighlight                = true,
    },

    QuestJournal =
    {
        UnpressedImage          = "EsoUI/Art/Quest/questJournal_tab_inactive.dds",
        PressedImage            = "EsoUI/Art/Quest/questJournal_tab_active.dds",
        UnpressedMouseOverImage = "EsoUI/Art/Quest/questJournal_tab_inactiveMouseOver.dds",
        DisabledImage           = "EsoUI/Art/Tabs/tab_disabled.dds",
        LeftCoords              = { left = 0, right = 0.25, top = 0.0, bottom = 1 },      -- NOTE: Assumes that the left and right slices match for pressed/unpressed
        RightCoords             = { left = 0.734375, right = 1, top = 0.0, bottom = 1 },
        CenterCoords            = { left = 0.25, right = 0.734375, top = 0.0, bottom = 1 },
        Height                  = 32,
        SideSize                = 16,
        HasIcon                 = true,
        HasTabMouseOver         = true,
    },
    
    FancyBottomEdge =
    {
        UnpressedImage              = "EsoUI/Art/Tabs/bottom_tab_inactive.dds",
        PressedImage                = "EsoUI/Art/Tabs/bottom_tab_active.dds",
        UnpressedMouseOverImage     = "EsoUI/Art/Tabs/bottom_tab_inactive_mouseOver.dds",
        LeftCoords                  = { left = 0, right = 0.203, top = 0, bottom = 0.58 },      -- NOTE: Assumes that the left and right slices match for pressed/unpressed
        RightCoords                 = { left = 0.75, right = 1, top = 0, bottom = 0.58 },
        CenterCoords                = { left = 0.203, right = 0.75, top = 0, bottom = 0.58 },
        SideSize                    = 13,      
        Height                      = 37,
        PressedTextColor            = ZO_ColorDef:New(0.811764, 0.862745, 0.741176, 1.0),
        UnpressedTextColor          = ZO_ColorDef:New(0.498039, 0.643137, 0.769531, 1.0),
        HasTabMouseOver             = true,
        TooltipPosition				= BOTTOM,
    },
    
    FancyBottomEdgeImage =
    {
        UnpressedImage              = "EsoUI/Art/Tabs/bottom_tab_inactive.dds",
        PressedImage                = "EsoUI/Art/Tabs/bottom_tab_active.dds",
        UnpressedMouseOverImage     = "EsoUI/Art/Tabs/bottom_tab_inactive_mouseOver.dds",
        LeftCoords                  = { left = 0, right = 0.203, top = 0, bottom = 0.58 },      -- NOTE: Assumes that the left and right slices match for pressed/unpressed
        RightCoords                 = { left = 0.75, right = 1, top = 0, bottom = 0.58 },
        CenterCoords                = { left = 0.203, right = 0.75, top = 0, bottom = 0.58 },
        SideSize                    = 13,
        HasIcon                     = true,
        HasTabMouseOver             = true,
        TooltipPosition			    = BOTTOM,
    },

    FancyTopEdgeImage =
    {
        UnpressedImage              = "EsoUI/Art/Tabs/tab_top_inactive.dds",
        PressedImage                = "EsoUI/Art/Tabs/tab_top_active.dds",
        UnpressedMouseOverImage     = "EsoUI/Art/Tabs/tab_top_inactive_mouseOver.dds",
        DisabledImage				= "EsoUI/Art/Tabs/tab_top_inactive_disabled.dds",
        LeftCoords                  = { left = 0, right = 0.2344, top = 0, bottom = 1 },      -- NOTE: Assumes that the left and right slices match for pressed/unpressed
        RightCoords                 = { left = 0.75, right = 1, top = 0, bottom = 1 },
        CenterCoords                = { left = 0.2344, right = 0.75, top = 0, bottom = 1 },
        SideSize                    = 16,
        HasIcon                     = true,
        HasTabMouseOver             = true,
        TooltipPosition			    = TOP,
    },

    SimpleText =
    {        
        SideSize                    = 10,
        Height                      = 24,
        PressedTextColor            = ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_SELECTED)),
        UnpressedTextColor          = ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_CONTRAST)),
        UnpressedMouseOverTextColor = ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_HIGHLIGHT)),
        DisabledTextColor           = ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_DISABLED)),
        TooltipPosition             = TOP,
        HasTabMouseOver             = true,
        Font                        = "ZoFontHeader2"
    },

    MainMenuSubcategory =
    {        
        SideSize                    = 5,
        Height                      = 32,
        MinFixedWidth               = 0,
		MaxFixedWidth               = 300,
        PressedTextColor            = ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_SELECTED)),
        UnpressedTextColor          = ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_CONTRAST)),
        UnpressedMouseOverTextColor = ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_HIGHLIGHT)),
        TooltipPosition             = TOP,
        HasTabMouseOver             = true,
        Font                        = "ZoFontHeader3"
    },
}

local function ZO_TabButton_HandleClickEvent(self, callback, callbackOptions)
    if(not self.tabType) then return end    -- Early out.
    
    local tabData = TAB_DATA[self.tabType]
    
    if(tabData.HasIcon) then
        local icon = GetControl(self,"Icon")      
        if(self.state == UNPRESSED) then
            icon:SetTexture(self.unpressedIcon)            
        else
            icon:SetTexture(self.pressedIcon)            
        end
    end
    
    if(self.state == UNPRESSED) then
        self:SetDrawLevel(DL_BELOW)
        if self.allowLabelColorChanges and tabData.UnpressedTextColor then
            local text = GetControl(self,"Text")
            if text then
                text:SetColor(tabData.UnpressedTextColor:UnpackRGBA()) 
            end
        end
    else
        self:SetDrawLevel(DL_ABOVE)
        if self.allowLabelColorChanges and tabData.PressedTextColor then
            local text = GetControl(self,"Text")
            if text then
                text:SetColor(tabData.PressedTextColor:UnpackRGBA()) 
            end
        end
    end
    
    if(tabData.PressedImage and tabData.UnpressedImage) then
        local left      = GetControl(self, "Left")
        local center    = GetControl(self, "Center")
        local right     = GetControl(self, "Right")
    
        local image         = (self.state == PRESSED) and tabData.PressedImage or tabData.UnpressedImage
        local leftCoords    = tabData.LeftCoords
        local rightCoords   = tabData.RightCoords
        local centerCoords  = tabData.CenterCoords

        left:SetTexture(image)
        left:SetTextureCoords(leftCoords.left, leftCoords.right, leftCoords.top, leftCoords.bottom)
    
        center:SetTexture(image)
        center:SetTextureCoords(centerCoords.left, centerCoords.right, centerCoords.top, centerCoords.bottom)
    
        right:SetTexture(image)
        right:SetTextureCoords(rightCoords.left, rightCoords.right, rightCoords.top, rightCoords.bottom)
    end
    
    if((callbackOptions ~= "preventcall") and (type(callback) == "function"))
    then
        callback(self)
    end
end

local function SizeButtonToFitText(self)
    local tab = self:GetParent()
    if(not tab.tabType or not TAB_DATA[tab.tabType]) then return end    -- Early out.

    local textWidth, textHeight = self:GetTextDimensions()
    local tabData = TAB_DATA[tab.tabType]
    local width = textWidth + tabData.SideSize * 2

	if tabData.MaxFixedWidth and width > tabData.MaxFixedWidth then
		--Text is too long, resize and continue after the label redraws
		GetControl(tab, "Text"):SetWidth(tabData.MaxFixedWidth - tabData.SideSize * 2)
	else
		width = zo_max(width, tabData.MinFixedWidth or 0)

		tab:SetDimensions(width, tabData.Height)

		self:SetAnchor(TOP, tab, TOP, 0, (tabData.Height - textHeight) / 2 + (tabData.OffsetY or 0))
    
		if tabData.HasHighlight then
			GetControl(tab, "Highlight"):SetTextureCoords(0, 1, 0, 1)
		end

		if tab.tabSizeChangedCallback then
			tab.tabSizeChangedCallback(tab, width, tabData.Height)
		end
	end
end

local function SetTabTextures(self, tabTexture, iconTexture, hasHighlight)
    if tabTexture then
        local center = GetControl(self,"Center")
        local left = GetControl(self, "Left")
        local right = GetControl(self, "Right")

        if center then center:SetTexture(tabTexture) end
        if left then left:SetTexture(tabTexture) end
        if right then right:SetTexture(tabTexture) end
    end

    if iconTexture then
        local highlight = GetControl(self, "Highlight")
        if hasHighlight then
            if highlight then
                highlight:SetHidden(false)
                highlight:SetTexture(iconTexture)
            end
        else
            local icon = GetControl(self, "Icon")
            if icon then icon:SetTexture(iconTexture) end
            if highlight then
                highlight:SetHidden(true)
            end
        end
    end
end

function ZO_TabButton_Select(self, callbackOptions)
    if(self.state == DISABLED) then return end
    
    self.state = PRESSED
    ZO_TabButton_HandleClickEvent(self, self.pressedCallback, callbackOptions)
end

function ZO_TabButton_Unselect(self, callbackOptions)
    if(self.state == DISABLED) then return end
    
    self.state = UNPRESSED
    ZO_TabButton_HandleClickEvent(self, self.unpressedCallback, callbackOptions)    
end

local function SharedTabInit(self, tabType, pressedCallback, unpressedCallback)
    self.tabType = tabType
    self.pressedCallback = pressedCallback
    self.unpressedCallback = unpressedCallback
    
    -- These nil fields are added here for clarity.
    self.state = nil
    self.tabGroup = nil
    
    -- Start tab buttons in the unpressed state, it's still not a member of a tab group
    ZO_TabButton_Unselect(self, "preventcall")
end

function ZO_TabButton_Text_SetFont(self, font)
	local label = GetControl(self,"Text")
    label:SetFont(font)
	label:SetWidth(0)
end

function ZO_TabButton_Text_Initialize(self, tabType, initialText, pressedCallback, unpressedCallback, tabSizeChangedCallback)
    if(not tabType or not TAB_DATA[tabType]) then 
        return 
    end
    
	local tabData = TAB_DATA[tabType]
    local center = GetControl(self, "Center")
    local left = GetControl(self, "Left")
    local right = GetControl(self, "Right")
	local label = GetControl(self, "Text")
    self.allowLabelColorChanges = true
    
    local sideSize = tabData.SideSize or 8
    local height = tabData.Height or 24
    if left then
        left:SetDimensions(sideSize, height)
    end
    if right then
        right:SetDimensions(sideSize, height)
    end
    if center then
        center:SetHeight(height)
    end

    if(not tabData.PressedImage or not tabData.UnpressedImage) then
        if left then
            left:SetHidden(true)
        end
        if right then
            right:SetHidden(true)
        end
        if center then
            center:SetHidden(true)
        end
    end

	if tabData.MaxFixedWidth then
		label:SetWrapMode(TEXT_WRAP_MODE_ELLIPSIS)
	end

    if(tabData.Font) then
        ZO_TabButton_Text_SetFont(self, tabData.Font)
    end

    SharedTabInit(self, tabType, pressedCallback, unpressedCallback) 

	self.tabSizeChangedCallback = tabSizeChangedCallback
    
    initialText = initialText or ""    
    ZO_TabButton_Text_SetText(self, initialText)
end

local ICON_SIZE = 32
function ZO_TabButtonOverrideIconSizeConstant(overrideValue)
    ICON_SIZE = overrideValue
end

function ZO_TabButtonResetIconSizeConstant()
    ICON_SIZE = 32
end

-- Utility to create uniform tab icons that have normal padding and size.
function ZO_CreateUniformIconTabData(sharedDataTable, icon, width, height, pressedIcon, unpressedIcon, mouseoverIcon, disabledIcon)
	width = width or 32
	height = height or 32

	local verticalPadding = (ICON_SIZE - height) / 2
	sharedDataTable.pressedIcon = icon or pressedIcon
	sharedDataTable.unpressedIcon = icon or unpressedIcon
    sharedDataTable.mouseoverIcon = mouseoverIcon
    sharedDataTable.disabledIcon = disabledIcon
	sharedDataTable.width = width
	sharedDataTable.height = height
	sharedDataTable.lowerPadding = verticalPadding
	sharedDataTable.upperPadding = verticalPadding
	
	return sharedDataTable
end

function ZO_TabButton_Icon_Initialize(self, tabType, visualData, pressedCallback, unpressedCallback)   
    self.pressedIcon = visualData.pressedIcon
    self.unpressedIcon = visualData.unpressedIcon
    self.disabledIcon = visualData.disabledIcon
    self.mouseoverIcon = visualData.mouseoverIcon
    self.allowLabelColorChanges = true

    local icon = GetControl(self, "Icon")
    local highlight = GetControl(self, "Highlight")
    local center = GetControl(self, "Center")
    local left = GetControl(self, "Left")
    local right = GetControl(self, "Right")
       
    local lowerPadding = visualData.lowerPadding or 0    
    local upperPadding = visualData.upperPadding or 0
    local width = visualData.width or 32
    local height = visualData.height or 32
    local sideSize = TAB_DATA[tabType].SideSize or 16

    if(icon) then    
        icon:SetTextureCoords(visualData.textureLeft or 0, visualData.textureRight or 1, visualData.textureTop or 0, visualData.textureBottom or 1)
        icon:SetDimensions(width, height)
        icon:ClearAnchors()
        icon:SetAnchor(BOTTOM, center, BOTTOM, 0, -lowerPadding) -- If center is nil, this will just use icon's parent

        if highlight then
            highlight:SetAnchorFill(icon)
        end
    end
    
    local tabHeight = height + lowerPadding + upperPadding

    if center then center:SetHeight(tabHeight) end
    if left then left:SetDimensions(sideSize, tabHeight) end
    if right then right:SetDimensions(sideSize, tabHeight) end
    
    self:SetDimensions(width + (sideSize * 2), tabHeight)
    
    SharedTabInit(self, tabType, pressedCallback, unpressedCallback)
end

function ZO_TabButton_SetTooltipText(tabButton, text, position)
	tabButton.tooltipText = text
	tabButton.tooltipPosition = position
end

function ZO_TabButton_SetMouseEnterHandler(tabButton, mouseEnterHandler)
    ZO_PreHookHandler(tabButton, "OnMouseEnter", mouseEnterHandler)
end

function ZO_TabButton_SetMouseExitHandler(tabButton, mouseExitHandler)
    ZO_PreHookHandler(tabButton, "OnMouseExit", mouseExitHandler)
end

function ZO_TabButton_OnMouseEnter(self)
    if(self.state == DISABLED) then return end

    local tabData = TAB_DATA[self.tabType]
    
    if(tabData.HasHighlight) then
        GetControl(self, "Highlight"):SetHidden(false)
    end
    
    if(self.tooltipText) then
        local tooltipPos = self.tooltipPosition or tabData.TooltipPosition
    	if(tooltipPos == TOP) then
            InitializeTooltip(InformationTooltip, self, BOTTOM, 0, -2)   
		else
            InitializeTooltip(InformationTooltip, self, TOP, 0, 2)   
		end   
        
		SetTooltipText(InformationTooltip, self.tooltipText)
    end
    
    --only unpressed tabs get mouse over effects
    if(self.state == UNPRESSED) then
        if(tabData.HasTabMouseOver) then
            SetTabTextures(self, tabData.UnpressedMouseOverImage, self.mouseoverIcon, tabData.HasHighlight)
        end

        if(self.allowLabelColorChanges and tabData.UnpressedMouseOverTextColor) then
            GetControl(self, "Text"):SetColor(tabData.UnpressedMouseOverTextColor:UnpackRGBA())
        end
    end
end

function ZO_TabButton_OnMouseExit(self)
    if(self.state == DISABLED) then return end
    
    if(not self.tabType) then return end    -- Early out.    
    local tabData = TAB_DATA[self.tabType]
    
    if(tabData.HasHighlight) then
        GetControl(self, "Highlight"):SetHidden(true)
    end
    
    if(self.tooltipText) then
		SetTooltipText(InformationTooltip)
    end
    
    --only unpressed tabs get mouse over effects
    if(self.state == UNPRESSED) then
        if(tabData.HasTabMouseOver) then       
            SetTabTextures(self, tabData.UnpressedImage, self.unpressedIcon)
        end

        if(self.allowLabelColorChanges and tabData.UnpressedMouseOverTextColor) then
            GetControl(self, "Text"):SetColor(tabData.UnpressedTextColor:UnpackRGBA())
        end
    end
end

function ZO_TabButton_IsDisabled(self)
	return self.state == DISABLED
end

function ZO_TabButton_SetDisabled(self, disabled)
    if(not self.tabType) then return end    -- Early out.    
    local tabData = TAB_DATA[self.tabType]

    if ZO_TabButton_IsDisabled(self) == disabled then
        return
    end
    
    if(disabled)
    then
        -- NOTE: For now it is the caller's responsibility to make sure that any unpressedCallback gets called as a result of setting this to the disabled state.
        self.state = DISABLED
        
        if(tabData.HasHighlight) then
            GetControl(self, "Highlight"):SetHidden(true)
        end
        
        if(tabData.HasIcon and self.disabledIcon) then
			local icon = GetControl(self,"Icon")
			icon:SetTexture(self.disabledIcon)
        end
        
        SetTabTextures(self, tabData.DisabledImage)

        if(self.allowLabelColorChanges and tabData.DisabledTextColor) then
            GetControl(self, "Text"):SetColor(tabData.DisabledTextColor:UnpackRGBA())
        end
    else
        self.state = UNPRESSED -- always revert back to unpressed
        
        if(tabData.HasIcon and self.unpressedIcon) then
			local icon = GetControl(self,"Icon")
			icon:SetTexture(self.unpressedIcon)
        end
        
        SetTabTextures(self, tabData.UnpressedImage)

        if(self.allowLabelColorChanges and tabData.UnpressedTextColor) then
            GetControl(self, "Text"):SetColor(tabData.UnpressedTextColor:UnpackRGBA())
        end
        
        if(MouseIsOver(self))
        then
            ZO_TabButton_OnMouseEnter(self)
        else
            ZO_TabButton_OnMouseExit(self)    
        end
    end
end

function ZO_TabButton_Text_SetText(self, text)
	local label = GetControl(self, "Text")
	label:SetWidth(0)
    label:SetText(text)
    SizeButtonToFitText(label)
end

function ZO_TabButton_Text_GetText(self)
    return GetControl(self, "Text"):GetText()
end

function ZO_TabButton_Text_SetTextColor(self, color)
    if(self.allowLabelColorChanges) then
	    local label = GetControl(self, "Text")
        label:SetColor(color:UnpackRGBA())
    end
end

function ZO_TabButton_Text_AllowColorChanges(self, allow)
    self.allowLabelColorChanges = allow
end

function ZO_TabButton_Text_RestoreDefaultColors(self)
    local tabData = TAB_DATA[self.tabType]
	local label = GetControl(self, "Text")
    self.allowLabelColorChanges = true

    if(self.state == UNPRESSED) then
        label:SetColor(tabData.UnpressedTextColor:UnpackRGBA())
    else
        label:SetColor(tabData.PressedTextColor:UnpackRGBA())
    end
end

--[[
    TabButtonGroup implementation.  This is modified from the radio button group because the
    base tab button definition uses a label and a custom texturing method.  It's probably overkill
    to abstract the "group management" concept away from radio button group and have both
    tab and radio button groups inherit from that base.
    
    This will probably continue to be reworked.
--]]

ZO_TabButtonGroup = ZO_Object:Subclass()

function ZO_TabButtonGroup:New()
    local group = ZO_Object.New(self)
    
    group.m_Buttons = {} -- m_Buttons will be keyed by a tabButton control, and the stored value is either a handler function, or the same as the key.
    
    return group    
end

function ZO_TabButtonGroup:HandleMouseDown(tabButton, buttonId)
    -- Left mouse press will select a tab (if it's not pressed)
    -- Right mouse press will be given the chance to open a context menu (coming soon...)
    if(buttonId == 1)
    then
        if(tabButton.state == PRESSED or tabButton.state == DISABLED)
        then
            return -- early out, the button was already pressed
        end 
        
        -- Set all buttons in the group to unpressed, and unlocked.
        for currentTabButton, mouseDownHandler in pairs(self.m_Buttons)
        do
            -- Only unpress the button that was pressed, and call its callback.
            -- Do not do anything with buttons that were already unpressed.
            if(currentTabButton.state == PRESSED)
            then
                ZO_TabButton_Unselect(currentTabButton)
            end
        end
        
        -- Select the new tab button
        ZO_TabButton_Select(tabButton)
    end
end

function ZO_TabButtonGroup:Add(tabButton)
    if(tabButton)
    then
        if(self.m_Buttons[tabButton] == nil)
        then
            -- Remember the original handler so that its call can be forced.
            -- NOTE: The TabButton template will generally take action on mouse down, not on a full click.
            -- This has to do with the fact that it's currently implemented as a label.
            local originalHandler = tabButton:GetHandler("OnMouseDown")
            self.m_Buttons[tabButton] = originalHandler or tabButton
            
            -- This throws away return values from the original function, which is most likely ok in the case of a click handler.
            local newHandler =  function(b, id)
                                    if(originalHandler)
                                    then
                                        originalHandler(b, id)
                                    end
                                    
                                    self:HandleMouseDown(b, id)
                                end
                                
            tabButton:SetHandler("OnMouseDown", newHandler)
        end
    end
end

function ZO_TabButtonGroup:Remove(tabButton)
    if self.m_Buttons[tabButton] then 
        ZO_TabButton_Unselect(tabButton, "preventcall")
                
        local originalHandler = self.m_Buttons[tabButton]
        
        if type(originalHandler) == "function" then
            tabButton:SetHandler("OnMouseDown", originalHandler)
        else
            -- Need to clear out our handler in this case, otherwise
            -- adding this tab to another group will call two tab group handlers
            tabButton:SetHandler("OnMouseDown", nil)
        end
        
        self.m_Buttons[tabButton] = nil
    end
end

function ZO_TabButtonGroup:Clear()
    for tabButton in pairs(self.m_Buttons) do
        self:Remove(tabButton)      
    end
end

function ZO_TabButtonGroup:SetClickedButton(tabButton)
    if(self.m_Buttons[tabButton])
    then
       tabButton:GetHandler("OnMouseDown")(tabButton, 1)
    end
end

function ZO_TabButtonGroup:GetClickedButton()
    for currentTabButton, mouseDownHandler in pairs(self.m_Buttons) do
        if(currentTabButton.state == PRESSED) then
            return currentTabButton
        end
	end
	return nil
end