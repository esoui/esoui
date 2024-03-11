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
        TooltipPosition             = BOTTOM,
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
        TooltipPosition             = BOTTOM,
    },

    FancyTopEdgeImage =
    {
        UnpressedImage              = "EsoUI/Art/Tabs/tab_top_inactive.dds",
        PressedImage                = "EsoUI/Art/Tabs/tab_top_active.dds",
        UnpressedMouseOverImage     = "EsoUI/Art/Tabs/tab_top_inactive_mouseOver.dds",
        DisabledImage               = "EsoUI/Art/Tabs/tab_top_inactive_disabled.dds",
        LeftCoords                  = { left = 0, right = 0.2344, top = 0, bottom = 1 },      -- NOTE: Assumes that the left and right slices match for pressed/unpressed
        RightCoords                 = { left = 0.75, right = 1, top = 0, bottom = 1 },
        CenterCoords                = { left = 0.2344, right = 0.75, top = 0, bottom = 1 },
        SideSize                    = 16,
        HasIcon                     = true,
        HasTabMouseOver             = true,
        TooltipPosition             = TOP,
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

local function ZO_TabButton_HandleClickEvent(control, callback, callbackOptions)
    -- Early out.
    if not control.tabType then 
        return
    end

    local tabData = TAB_DATA[control.tabType]

    if tabData.HasIcon then
        local icon = control:GetNamedChild("Icon")
        if control.state == UNPRESSED then
            icon:SetTexture(control.unpressedIcon)
        else
            icon:SetTexture(control.pressedIcon)
        end
    end

    if control.state == UNPRESSED then
        control:SetDrawLevel(DL_BELOW)
        if control.allowLabelColorChanges and tabData.UnpressedTextColor then
            local text = control:GetNamedChild("Text")
            if text then
                text:SetColor(tabData.UnpressedTextColor:UnpackRGBA()) 
            end
        end
    else
        control:SetDrawLevel(DL_ABOVE)
        if control.allowLabelColorChanges and tabData.PressedTextColor then
            local text = control:GetNamedChild("Text")
            if text then
                text:SetColor(tabData.PressedTextColor:UnpackRGBA()) 
            end
        end
    end

    if tabData.PressedImage and tabData.UnpressedImage then
        local left = control:GetNamedChild("Left")
        local center = control:GetNamedChild("Center")
        local right = control:GetNamedChild("Right")

        local image = control.state == PRESSED and tabData.PressedImage or tabData.UnpressedImage
        local leftCoords = tabData.LeftCoords
        local rightCoords = tabData.RightCoords
        local centerCoords = tabData.CenterCoords

        left:SetTexture(image)
        left:SetTextureCoords(leftCoords.left, leftCoords.right, leftCoords.top, leftCoords.bottom)

        center:SetTexture(image)
        center:SetTextureCoords(centerCoords.left, centerCoords.right, centerCoords.top, centerCoords.bottom)

        right:SetTexture(image)
        right:SetTextureCoords(rightCoords.left, rightCoords.right, rightCoords.top, rightCoords.bottom)
    end
    
    if callbackOptions ~= "preventcall" and type(callback) == "function" then
        callback(control)
    end
end

local function SizeButtonToFitText(label)
    local tab = label:GetParent()
    -- Early out.
    if not tab.tabType or not TAB_DATA[tab.tabType] then
        return 
    end

    local textWidth, textHeight = label:GetTextDimensions()
    local tabData = TAB_DATA[tab.tabType]
    local width = textWidth + tabData.SideSize * 2

    if tabData.MaxFixedWidth and width > tabData.MaxFixedWidth then
        --Text is too long, resize and continue after the label redraws
        tab:GetNamedChild("Text"):SetWidth(tabData.MaxFixedWidth - tabData.SideSize * 2)
    else
        width = zo_max(width, tabData.MinFixedWidth or 0)

        tab:SetDimensions(width, tabData.Height)

        label:SetAnchor(TOP, tab, TOP, 0, (tabData.Height - textHeight) / 2 + (tabData.OffsetY or 0))

        if tabData.HasHighlight then
            tab:GetNamedChild("Highlight"):SetTextureCoords(0, 1, 0, 1)
        end

        if tab.tabSizeChangedCallback then
            tab.tabSizeChangedCallback(tab, width, tabData.Height)
        end
    end
end

local function SetTabTextures(control, tabTexture, iconTexture, hasHighlight)
    if tabTexture then
        local center = control:GetNamedChild("Center")
        local left = control:GetNamedChild("Left")
        local right = control:GetNamedChild("Right")

        if center then 
            center:SetTexture(tabTexture)
        end

        if left then
            left:SetTexture(tabTexture)
        end

        if right then
            right:SetTexture(tabTexture)
        end
    end

    if iconTexture then
        local highlight = control:GetNamedChild("Highlight")
        if hasHighlight then
            if highlight then
                highlight:SetHidden(false)
                highlight:SetTexture(iconTexture)
            end
        else
            local icon = control:GetNamedChild("Icon")
            if icon then
                icon:SetTexture(iconTexture)
            end
            if highlight then
                highlight:SetHidden(true)
            end
        end
    end
end

function ZO_TabButton_Select(tabButton, callbackOptions)
    if tabButton.state == DISABLED then
        return
    end

    tabButton.state = PRESSED
    ZO_TabButton_HandleClickEvent(tabButton, tabButton.pressedCallback, callbackOptions)
end

function ZO_TabButton_Unselect(tabButton, callbackOptions)
    if tabButton.state == DISABLED then
        return
    end

    tabButton.state = UNPRESSED
    ZO_TabButton_HandleClickEvent(tabButton, tabButton.unpressedCallback, callbackOptions)
end

local function SharedTabInit(tabButton, tabType, pressedCallback, unpressedCallback)
    tabButton.tabType = tabType
    tabButton.pressedCallback = pressedCallback
    tabButton.unpressedCallback = unpressedCallback

    -- These nil fields are added here for clarity.
    tabButton.state = nil
    tabButton.tabGroup = nil

    -- Start tab buttons in the unpressed state, it's still not a member of a tab group
    ZO_TabButton_Unselect(tabButton, "preventcall")
end

function ZO_TabButton_Text_SetFont(tabButton, font)
    local label = tabButton:GetNamedChild("Text")
    label:SetFont(font)
    label:SetWidth(0)
end

function ZO_TabButton_Text_Initialize(control, tabType, initialText, pressedCallback, unpressedCallback, tabSizeChangedCallback)
    if not tabType or not TAB_DATA[tabType] then
        return
    end
    
    local tabData = TAB_DATA[tabType]
    local center = control:GetNamedChild("Center")
    local left = control:GetNamedChild("Left")
    local right = control:GetNamedChild("Right")
    local label = control:GetNamedChild("Text")
    control.allowLabelColorChanges = true
    
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

    if not tabData.PressedImage or not tabData.UnpressedImage then
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

    if tabData.Font then
        ZO_TabButton_Text_SetFont(control, tabData.Font)
    end

    SharedTabInit(control, tabType, pressedCallback, unpressedCallback) 
    control.tabSizeChangedCallback = tabSizeChangedCallback
    initialText = initialText or ""
    ZO_TabButton_Text_SetText(control, initialText)
end

do
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
end

function ZO_TabButton_Icon_Initialize(tabButton, tabType, visualData, pressedCallback, unpressedCallback)   
    tabButton.pressedIcon = visualData.pressedIcon
    tabButton.unpressedIcon = visualData.unpressedIcon
    tabButton.disabledIcon = visualData.disabledIcon
    tabButton.mouseoverIcon = visualData.mouseoverIcon
    tabButton.allowLabelColorChanges = true

    local icon = tabButton:GetNamedChild("Icon")
    local highlight = tabButton:GetNamedChild("Highlight")
    local center = tabButton:GetNamedChild("Center")
    local left = tabButton:GetNamedChild("Left")
    local right = tabButton:GetNamedChild("Right")

    local lowerPadding = visualData.lowerPadding or 0
    local upperPadding = visualData.upperPadding or 0
    local width = visualData.width or 32
    local height = visualData.height or 32
    local sideSize = TAB_DATA[tabType].SideSize or 16

    if icon then
        local leftCoord = visualData.textureLeft or 0
        local rightCoord = visualData.textureRight or 1
        local topCoord = visualData.textureTop or 0
        local bottomCoord = visualData.textureBottom or 1

        icon:SetTextureCoords(leftCoord, rightCoord, topCoord, bottomCoord)
        icon:SetDimensions(width, height)
        icon:ClearAnchors()
        --If center is nil, this will just use icon's parent
        icon:SetAnchor(BOTTOM, center, BOTTOM, 0, -lowerPadding)

        if highlight then
            highlight:SetAnchorFill(icon)
        end
    end
    
    local tabHeight = height + lowerPadding + upperPadding

    if center then
        center:SetHeight(tabHeight)
    end

    if left then
        left:SetDimensions(sideSize, tabHeight)
    end

    if right then
        right:SetDimensions(sideSize, tabHeight)
    end

    tabButton:SetDimensions(width + (sideSize * 2), tabHeight)
    SharedTabInit(tabButton, tabType, pressedCallback, unpressedCallback)
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

function ZO_TabButton_OnMouseEnter(tabButton)
    if tabButton.state == DISABLED or not tabButton.tabType then 
        return 
    end

    local tabData = TAB_DATA[tabButton.tabType]

    if tabData.HasHighlight then
        tabButton:GetNamedChild("Highlight"):SetHidden(false)
    end

    if tabButton.tooltipText then
        local tooltipPos = tabButton.tooltipPosition or tabData.TooltipPosition
        if tooltipPos == TOP then
            InitializeTooltip(InformationTooltip, tabButton, BOTTOM, 0, -2)
        else
            InitializeTooltip(InformationTooltip, tabButton, TOP, 0, 2)
        end
        SetTooltipText(InformationTooltip, tabButton.tooltipText)
    end

    --Only unpressed tabs get mouse over effects
    if tabButton.state == UNPRESSED then
        if tabData.HasTabMouseOver then
            SetTabTextures(tabButton, tabData.UnpressedMouseOverImage, tabButton.mouseoverIcon, tabData.HasHighlight)
        end

        if tabButton.allowLabelColorChanges and tabData.UnpressedMouseOverTextColor then
            tabButton:GetNamedChild("Text"):SetColor(tabData.UnpressedMouseOverTextColor:UnpackRGBA())
        end
    end
end

function ZO_TabButton_OnMouseExit(tabButton)
    if tabButton.state == DISABLED or not tabButton.tabType then
        return
    end

    local tabData = TAB_DATA[tabButton.tabType]

    if tabData.HasHighlight then
        tabButton:GetNamedChild("Highlight"):SetHidden(true)
    end

    if tabButton.tooltipText then
        SetTooltipText(InformationTooltip)
    end

    --Only unpressed tabs get mouse over effects
    if tabButton.state == UNPRESSED then
        if tabData.HasTabMouseOver then
            SetTabTextures(tabButton, tabData.UnpressedImage, tabButton.unpressedIcon)
        end

        if tabButton.allowLabelColorChanges and tabData.UnpressedMouseOverTextColor then
            tabButton:GetNamedChild("Text"):SetColor(tabData.UnpressedTextColor:UnpackRGBA())
        end
    end
end

function ZO_TabButton_IsDisabled(tabButton)
    return tabButton.state == DISABLED
end

function ZO_TabButton_SetDisabled(tabButton, disabled)
    -- Early out. 
    if not tabButton.tabType then
        return
    end

    if ZO_TabButton_IsDisabled(tabButton) == disabled then
        return
    end

    local tabData = TAB_DATA[tabButton.tabType]
    if disabled then
        -- NOTE: For now it is the caller's responsibility to make sure that any unpressedCallback gets called as a result of setting this to the disabled state.
        tabButton.state = DISABLED

        if tabData.HasHighlight then
            tabButton:GetNamedChild("Highlight"):SetHidden(true)
        end

        if tabData.HasIcon and tabButton.disabledIcon then
            local icon = tabButton:GetNamedChild("Icon")
            icon:SetTexture(tabButton.disabledIcon)
        end

        SetTabTextures(tabButton, tabData.DisabledImage)

        if tabButton.allowLabelColorChanges and tabData.DisabledTextColor then
            tabButton:GetNamedChild("Text"):SetColor(tabData.DisabledTextColor:UnpackRGBA())
        end
    else
        --Always revert back to unpressed
        tabButton.state = UNPRESSED

        if tabData.HasIcon and tabButton.unpressedIcon then
            local icon = tabButton:GetNamedChild("Icon")
            icon:SetTexture(tabButton.unpressedIcon)
        end

        SetTabTextures(tabButton, tabData.UnpressedImage)

        if tabButton.allowLabelColorChanges and tabData.UnpressedTextColor then
            tabButton:GetNamedChild("Text"):SetColor(tabData.UnpressedTextColor:UnpackRGBA())
        end
        
        if MouseIsOver(tabButton) then
            ZO_TabButton_OnMouseEnter(tabButton)
        else
            ZO_TabButton_OnMouseExit(tabButton)
        end
    end
end

function ZO_TabButton_Text_SetText(control, text)
    local label = control:GetNamedChild("Text")
    label:SetWidth(0)
    label:SetText(text)
    SizeButtonToFitText(label)
end

function ZO_TabButton_Text_GetText(control)
    return control:GetNamedChild("Text"):GetText()
end

function ZO_TabButton_Text_SetTextColor(control, color)
    if control.allowLabelColorChanges then
        local label = control:GetNamedChild("Text")
        label:SetColor(color:UnpackRGBA())
    end
end

function ZO_TabButton_Text_AllowColorChanges(control, allow)
    control.allowLabelColorChanges = allow
end

function ZO_TabButton_Text_RestoreDefaultColors(control)
    local tabData = TAB_DATA[control.tabType]
    local label = control:GetNamedChild("Text")
    control.allowLabelColorChanges = true

    if control.state == UNPRESSED then
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

ZO_TabButtonGroup = ZO_InitializingObject:Subclass()

function ZO_TabButtonGroup:Initialize()
    --m_Buttons will be keyed by a tabButton control, and the stored value is either a handler function, or the same as the key.
    self.m_Buttons = {}
end

function ZO_TabButtonGroup:HandleMouseDown(tabButton, buttonId)
    -- Left mouse press will select a tab (if it's not pressed)
    -- Right mouse press will be given the chance to open a context menu (coming soon...)
    if buttonId == 1 then
        if tabButton.state == PRESSED or tabButton.state == DISABLED then
            --Early out, the button was already pressed
            return
        end

        -- Set all buttons in the group to unpressed, and unlocked.
        for currentTabButton, mouseDownHandler in pairs(self.m_Buttons) do
            -- Only unpress the button that was pressed, and call its callback.
            -- Do not do anything with buttons that were already unpressed.
            if currentTabButton.state == PRESSED then
                ZO_TabButton_Unselect(currentTabButton)
            end
        end

        -- Select the new tab button
        ZO_TabButton_Select(tabButton)
    end
end

function ZO_TabButtonGroup:Add(tabButton)
    if tabButton then
        if self.m_Buttons[tabButton] == nil then
            -- Remember the original handler so that its call can be forced.
            -- NOTE: The TabButton template will generally take action on mouse down, not on a full click.
            -- This has to do with the fact that it's currently implemented as a label.
            local originalHandler = tabButton:GetHandler("OnMouseDown")
            self.m_Buttons[tabButton] = originalHandler or tabButton
            -- This throws away return values from the original function, which is most likely ok in the case of a click handler.
            local function NewHandler(button, id)
                if originalHandler then
                    originalHandler(button, id)
                end
                self:HandleMouseDown(button, id)
            end
            tabButton:SetHandler("OnMouseDown", NewHandler)
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
    if self.m_Buttons[tabButton] then
       tabButton:GetHandler("OnMouseDown")(tabButton, 1)
    end
end

function ZO_TabButtonGroup:GetClickedButton()
    for currentTabButton, mouseDownHandler in pairs(self.m_Buttons) do
        if currentTabButton.state == PRESSED then
            return currentTabButton
        end
    end
    return nil
end