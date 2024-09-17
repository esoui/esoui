--[[
    Menubar usage notes:
        A bar of buttons that resize when you mouse over them and act like a radio button group.
        Create a control that inherits from ZO_MenuBarTemplate, and use ZO_MenuBar_AddButton to add buttons to it.

        *   ZO_MenuBar_AddButton takes a table describing the states of the new button:
            buttonData =
            {
                descriptor = Something that uniquely describes the button you want to add (among all the buttons you will add).  Used for removal, auto-selection, etc...
                normal = Path to the image to use for the control when it's in its normal state (unpressed, not moused over)
                pressed = Path to the image to use for the control when it's in its pressed state (the user has pressed LMB while over the control, the highlight is shown when the button is pressed/clicked)
                disabled = Path to the image to use for the control when it's in its disabled state (the control cannot be clicked on/doesn't respond to mouseover: NOT IMPLEMENTED YET)
                highlight = Path to the image to use for the control when the mouse is over it, or its clicked
                callback = A function to call when the user clicks the control (LMB down->up while still inside the control), the callback receives this table as an argument
                statusIcon = Path to the image, or function returning the potential path, to use for the control to denote status of the contents the button links to
                visible = An optional function to call to determine whether this button is currently visible; this function receives this table as its only argument
            }

            Example:
            local menuBar = CreateControlFromVirtual("testBar", GuiRoot, "ZO_MenuBarTemplate")
            menuBar:SetAnchor(TOPRIGHT, GuiRoot, TOPRIGHT, -25, 25)

            local fancyButton =
            {
                descriptor = "fancy",
                normal = "EsoUI/Art/Inventory/inventory_tabIcon_weapons_up.dds",
                pressed = "EsoUI/Art/Inventory/inventory_tabIcon_weapons_down.dds", 
                disabled = "EsoUI/Art/Inventory/inventory_tabIcon_weapons_disabled.dds", 
                highlight = "EsoUI/Art/Inventory/inventory_tabIcon_weapons_over.dds", 
                callback = function(<fancyButton>) ...do stuff... end,
                statusIcon = function() return "EsoUI/Art/Miscellaneous/new_icon.dds" end,
            }

            local newControl = ZO_MenuBar_AddButton(menuBar, fancyButton)

            NOTE: The actual control that was added is returned by this function.  Do whatever you want to it.

        *   If you want to set up the bar to use different button templates, padding, anchoring styles, etc...use:

            Example:
            local barData =
            {
                initialButtonAnchorPoint = RIGHT,       -- LEFT is default, buttons will be laid out left-to-right, RIGHT is opposite
                buttonTemplate = "desiredTemplate",     -- default uses internal template
                buttonPadding = 16,                     -- 0 is default, negatives are fine, this is xOffset on the anchors
                normalSize = 32,                        -- 32 is default, size of the buttons when they are unpressed
                downSize = 50,                          -- 50 is default, size of the buttons when they are moused over/clicked...changes sizes smoothly.
                animationDuration = 180                 -- 180 is default, duration in milliseconds of the resize animation
            }

            ZO_MenuBar_SetData(menuBar, barData)

            NOTE: Calls to ZO_MenuBar_SetData after buttons have been added is not supported.  If the template changes midstream, you're really doing something wrong.  Stop that.

            If you want to create a tab that does not show up on the tab bar, but is selectable programmatically (Ex. trading house sellable items tab)
            You must set the "hidden" value to false, but you must also set "ignoreVisibleCheck" to true.
            this will cause the button to not show up on the tab bar, but if you were to select it using ZO_MenuBar_SelectDescriptor
--]]

--[[
    Menu Button Object
--]]

local ADJUST_SIZE_INSTANT = true
local ADJUST_SIZE_ANIMATED = false

local MenuBarButton = ZO_Object:Subclass()

function MenuBarButton:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function MenuBarButton:Initialize(button)
    self.m_button = button
    self.m_image = button:GetNamedChild("Image")
    self.m_highlight = button:GetNamedChild("ImageHighlight")
    self.m_statusIcon = button:GetNamedChild("Status")
    self.m_state = BSTATE_DISABLED
    self.m_highlightHidden = true

    self.m_image:SetDimensions(32, 32) -- start out at some default size...
end

function MenuBarButton:Reset()
    if self.m_anim then
        self.m_anim:GetTimeline():Stop()
    end
    self.m_highlightHidden = true
    self.m_statusIcon:SetHidden(true)
    self.m_locked = false
    self:SetState(BSTATE_DISABLED, ADJUST_SIZE_INSTANT)

    local onResetCallback = self.m_buttonData.onResetCallback
    if onResetCallback then
        onResetCallback(self.m_button)
    end
end

function MenuBarButton:UpdateTexturesFromState()
    local state = self.m_state
    local buttonData = self.m_buttonData
    local texture
    if(state == BSTATE_NORMAL) then
        texture = buttonData.normal
    elseif(state == BSTATE_PRESSED) then
        texture = buttonData.pressed
    elseif(state == BSTATE_DISABLED) then
        texture = buttonData.disabled
    end
    if type(texture) == "function" then
        texture = texture(buttonData)
    end

    self.m_image:SetTexture(texture)
    self.m_highlight:SetHidden(self.m_highlightHidden)
end

local legalStates =
{
    [BSTATE_NORMAL] = true,
    [BSTATE_PRESSED] = true,
    [BSTATE_DISABLED] = true,
}

function MenuBarButton:GetState()
    return self.m_state
end

function MenuBarButton:SetState(state, adjustSizeInstant)
    if legalStates[state] and state ~= self.m_state then
        self.m_state = state
        self:UpdateTexturesFromState()

        if adjustSizeInstant then
            local normalSize, downSize = self:GetAnimationData()
            if state == BSTATE_PRESSED then
                self.m_image:SetDimensions(downSize, downSize)
            else
                self.m_image:SetDimensions(normalSize, normalSize)
            end

            if self.m_anim then
                local timeline = self.m_anim:GetTimeline()
                timeline:Stop()
                if state == BSTATE_PRESSED then
                    timeline:SetProgress(0)
                else
                    timeline:SetProgress(1)
                end
            end
        else
            if state == BSTATE_PRESSED then
                self:SizeUp()
            else
                self:SizeDown()
            end
        end
        local buttonData = self.m_buttonData
        if state == BSTATE_NORMAL then
            if buttonData.onButtonStateNormal then
                buttonData.onButtonStateNormal(self.m_button)
            end
        elseif state == BSTATE_PRESSED then
            if buttonData.onButtonStatePressed then
                buttonData.onButtonStatePressed(self.m_button)
            end
        elseif state == BSTATE_DISABLED then
            if buttonData.onButtonStateDisabled then
                buttonData.onButtonStateDisabled(self.m_button)
            end
        end

    end
end

function MenuBarButton:SetHighlightHidden(hidden)
    if hidden ~= self.m_highlightHidden then
        self.m_highlightHidden = hidden
        self:UpdateTexturesFromState()
    end
end

function MenuBarButton:CreateAnim(sizingUp)
    if not self.m_anim then
        self.m_anim = CreateSimpleAnimation(ANIMATION_SIZE, self.m_image)

        local normalSize, downSize, duration = self:GetAnimationData()
        self.m_anim:SetStartAndEndHeight(normalSize, downSize)
        self.m_anim:SetStartAndEndWidth(normalSize, downSize)
        self.m_anim:SetDuration(duration)

        if sizingUp then
            self.m_anim:GetTimeline():PlayInstantlyToStart()
        else
            self.m_anim:GetTimeline():PlayInstantlyToEnd()
        end
    end
end

local SIZING_UP = true
function MenuBarButton:SizeUp()
    self:CreateAnim(SIZING_UP)
    self.m_anim:GetTimeline():PlayForward()
end

local SIZING_DOWN = false
function MenuBarButton:SizeDown()
    self:CreateAnim(SIZING_DOWN)
    self.m_anim:GetTimeline():PlayBackward()
end

function MenuBarButton:SetData(owner, buttonData)
    self.m_buttonData = buttonData
    self.m_menuBar = owner
    local highlight = buttonData.highlight
    if type(highlight) == "function" then
        highlight = highlight(buttonData)
    end
    self.m_highlight:SetTexture(highlight)
    self:SetState(BSTATE_NORMAL, ADJUST_SIZE_INSTANT)
    self:RefreshStatus()
end

function MenuBarButton:MouseEnter()
    if self.m_state ~= BSTATE_PRESSED and self.m_state ~= BSTATE_DISABLED then
        self:SetHighlightHidden(false)
        self:SizeUp()
    end
    return self.m_state ~= BSTATE_DISABLED
end

function MenuBarButton:MouseExit()
    if self.m_state ~= BSTATE_PRESSED and self.m_state ~= BSTATE_DISABLED then
        self:SetHighlightHidden(true)
        self:SizeDown()
    end
    return self.m_state ~= BSTATE_DISABLED
end

function MenuBarButton:Press(adjustSizeInstant)
    if self.m_state ~= BSTATE_DISABLED then
        self:SetState(BSTATE_PRESSED, adjustSizeInstant)
    end
end

function MenuBarButton:UnPress(adjustSizeInstant)
    if self.m_state ~= BSTATE_DISABLED then
        self.m_highlightHidden = true -- batch update, don't allow texture update from this
        self:SetState(BSTATE_NORMAL, adjustSizeInstant)
    end
end

function MenuBarButton:SetEnabled(enabled, adjustSizeInstant)
    if enabled then
        if self.m_state == BSTATE_DISABLED then
            if MouseIsOver(self.m_button) then
                self.m_state = BSTATE_NORMAL
                zo_callHandler(self.m_button, "OnMouseEnter")
            else
                self:SetState(BSTATE_NORMAL, adjustSizeInstant)
            end
        end
    else
        if self.m_state ~= BSTATE_DISABLED then
            if MouseIsOver(self.m_button) then
                zo_callHandler(self.m_button, "OnMouseExit")
            end
            self.m_highlightHidden = true
            self:SetState(BSTATE_DISABLED, adjustSizeInstant)
        end
    end
end

function MenuBarButton:SetLocked(locked)
    self.m_locked = locked
end

local PLAYER_DRIVEN = true
local CODE_DRIVEN = false

function MenuBarButton:Release(upInside, skipAnimation, playerDriven)
    if self.m_locked then
        return
    end

    if self.m_state ~= BSTATE_DISABLED then
        if upInside then
            self.m_menuBar:SetClickedButton(self, skipAnimation)

            local buttonData = self.m_buttonData
            if buttonData.callback then
                buttonData:callback(playerDriven)
            end

            local clickSound = buttonData.clickSound or self.m_menuBar:GetClickSound()
            if clickSound and playerDriven then
                PlaySound(clickSound)
            end
        else
            self:UnPress(skipAnimation)
        end
    end
end

function MenuBarButton:RefreshStatus()
    local buttonData = self.m_buttonData
    if buttonData.statusIcon then
        local textureFile
        if type(buttonData.statusIcon) == "function" then
            textureFile = buttonData.statusIcon()
        else
            textureFile = buttonData.statusIcon
        end

        if textureFile then
            self.m_statusIcon:SetTexture(textureFile)
            self.m_statusIcon:SetHidden(false)
            return
        end
    end
    self.m_statusIcon:SetHidden(true)
end

function MenuBarButton:GetDescriptor()
    return self.m_buttonData and self.m_buttonData.descriptor
end

function MenuBarButton:GetControl()
    return self.m_button
end

function MenuBarButton:GetAnimationData()
    local normalSize, downSize, animationDuration = self.m_menuBar:GetAnimationData()
    normalSize = self.m_buttonData.overrideNormalSize or normalSize
    downSize = self.m_buttonData.overrideDownSize or downSize
    return normalSize, downSize, animationDuration
end

--[[
    Menu Bar Controller Object
--]]

local INDEX_BUTTON = 1
local INDEX_POOL_KEY = 2
local INDEX_DESCRIPTOR = 3

local MenuBar = ZO_Object:Subclass()

function MenuBar:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function MenuBar:Initialize(control)
    self.m_buttons = {}
    self.m_control = control
    self.m_point = LEFT
    self.m_relativePoint = RIGHT
    self.m_buttonPadding = 0
    self.m_clickSound = SOUNDS.MENU_BAR_CLICK
end

function MenuBar:GetClickSound()
    return self.m_clickSound
end

function MenuBar:SetClickSound(clickSound)
    self.m_clickSound = clickSound
end

function MenuBar:ClearClickSound()
    self.m_clickSound = nil
end

local function IsVisible(buttonData)
    if buttonData.hidden then
        return false
    else
        return not buttonData.visible or buttonData.visible(buttonData)
    end
end

local function IsEnabled(buttonData)
    return not buttonData.enabled or buttonData.enabled(buttonData)
end

local function GetBarPadding(buttonData)
    return buttonData.barPadding
end

function MenuBar:SelectFirstVisibleButton(skipAnimation)
    for i, button in ipairs(self.m_buttons) do
        local buttonControl = button[INDEX_BUTTON]
        local isVisible = IsVisible(buttonControl.m_object.m_buttonData)

        if isVisible then
            self:SelectDescriptor(button[INDEX_DESCRIPTOR], skipAnimation)
            return
        end
    end
end

function MenuBar:SelectLastVisibleButton(skipAnimation)
    for i = #self.m_buttons, 1, -1 do
        local button = self.m_buttons[i]
        local buttonControl = button[INDEX_BUTTON]
        local isVisible = IsVisible(buttonControl.m_object.m_buttonData)

        if isVisible then
            self:SelectDescriptor(button[INDEX_DESCRIPTOR], skipAnimation)
            return
        end
    end
end

function MenuBar:UpdateButtons(forceSelection)
    self.m_barPool:ReleaseAllObjects()

    local lastVisibleButton
    local lastDivider
    local lastDividerPadding

    for i, button in ipairs(self.m_buttons) do
        local buttonControl = button[INDEX_BUTTON]
        buttonControl:ClearAnchors()
        local buttonData = buttonControl.m_object.m_buttonData

        local isVisible = IsVisible(buttonData)
        buttonControl:SetHidden(not isVisible)
        if buttonData.enabled ~= nil then
            self:SetDescriptorEnabled(buttonData.descriptor, IsEnabled(buttonData))
        end

        if isVisible then
            if lastDivider and lastDividerPadding then
                buttonControl:SetAnchor(self.m_point, lastDivider, self.m_relativePoint, lastDividerPadding)
            elseif lastVisibleButton then
                local previousButtonExtraPadding = buttonData.previousButtonExtraPadding or 0
                buttonControl:SetAnchor(self.m_point, lastVisibleButton, self.m_relativePoint, self.m_buttonPadding + previousButtonExtraPadding)
            else
                buttonControl:SetAnchor(self.m_point, nil, self.m_point, 0, 0)
            end

            lastVisibleButton = buttonControl

            buttonControl.m_object:RefreshStatus()
        end

        local barPadding = GetBarPadding(buttonData)

        if barPadding then
            -- create a bar control and place it next to lastVisibleButton
            -- make sure the next button control is next to the newly created bar
            lastDivider = self.m_barPool:AcquireObject()
            lastDivider:SetAnchor(self.m_point, lastVisibleButton, self.m_relativePoint, barPadding)
            lastDividerPadding = barPadding
        else
            lastDivider = nil
            lastDividerPadding = nil
        end

        buttonControl.m_object:UpdateTexturesFromState()
    end

    if self.m_clickedButton and not IsVisible(self.m_clickedButton.m_buttonData) then
        if forceSelection then
            local SKIP_ANIM = true
            self:SelectFirstVisibleButton(SKIP_ANIM)
        else
            self:ClearSelection()
        end
    end
end

function MenuBar:AddButton(buttonData)
    local button, key = self.m_pool:AcquireObject()

    local onInitializeCallback = buttonData.onInitializeCallback
    if onInitializeCallback then
        onInitializeCallback(button)
    end

    button.m_object:SetData(self, buttonData)

    table.insert(self.m_buttons, { button, key, buttonData.descriptor }) -- update constants if order changes!

    self:UpdateButtons()

    return button
end

function MenuBar:ButtonControlIterator()
    local buttons = {}
    for _, button in ipairs(self.m_buttons) do
        table.insert(buttons, button[INDEX_BUTTON])
    end

    return ipairs(buttons)
end

function MenuBar:GetButtonControl(descriptor)
    local buttonObject = self:ButtonObjectForDescriptor(descriptor)
    if buttonObject then
        return buttonObject:GetControl()
    end
end

function MenuBar:ClearButtons()
    self.m_clickedButton = nil
    self.m_lastClickedButton = nil
    self.m_pool:ReleaseAllObjects()
    self.m_barPool:ReleaseAllObjects()
    self.m_buttons = {}
end

function MenuBar:SetAllButtonsEnabled(enabled, skipAnimation)
    if self.allEnabled ~= enabled then
        self.allEnabled = enabled
        
        for i, button in ipairs(self.m_buttons) do
            local buttonControl = button[INDEX_BUTTON]
            buttonControl.m_object:SetEnabled(self.allEnabled, skipAnimation)

            if enabled and buttonControl.m_object == self.m_clickedButton then
                self:SetClickedButton(buttonControl.m_object, skipAnimation)
            else
                buttonControl.m_object:SetLocked(not enabled)
            end
        end
    end
end

function MenuBar:GetSelectedDescriptor()
    return self.m_clickedButton and self.m_clickedButton:GetDescriptor()
end

function MenuBar:GetLastSelectedDescriptor()
    return self.m_lastClickedButton and self.m_lastClickedButton:GetDescriptor()
end

function MenuBar:SetClickedButton(buttonObject, skipAnimation)
    if self.m_clickedButton then
        self.m_clickedButton:SetLocked(false)
        self.m_clickedButton:UnPress(skipAnimation)
        self.m_lastClickedButton = self.m_clickedButton
        self.m_clickedButton = nil
    end

    if buttonObject then
        self.m_clickedButton = buttonObject
        self.m_clickedButton:SetLocked(true)
        self.m_clickedButton:Press(skipAnimation)
    end
end

function MenuBar:RestoreLastClickedButton(skipAnimation)
    if self.m_lastClickedButton then
        self:SetClickedButton(self.m_lastClickedButton, skipAnimation)
    end
end

function MenuBar:SetData(data)
    if self.m_pool ~= nil then
        return
    end

    if data.initialButtonAnchorPoint and data.initialButtonAnchorPoint == RIGHT then
        self.m_point = RIGHT
        self.m_relativePoint = LEFT
    else
        self.m_point = LEFT
        self.m_relativePoint = RIGHT
    end

    self.m_pool = ZO_ControlPool:New(data.buttonTemplate or "ZO_MenuBarButtonTemplate1", self.m_control, "Button")
    self.m_pool:SetCustomResetBehavior(function(control)
        control.m_object:Reset()
    end)

    self.m_barPool = ZO_ControlPool:New(data.barTemplate or "ZO_MenuBarPaddingBarTemplate", self.m_control, "PaddingBar")

    self.m_buttonPadding = data.buttonPadding or 0
    self.m_normalSize = data.normalSize or 32
    self.m_downSize = data.downSize or 50
    self.m_animationDuration = data.animationDuration or 180
end

function MenuBar:ButtonObjectForDescriptor(descriptor)
    for _, data in ipairs(self.m_buttons) do
        if data[INDEX_DESCRIPTOR] == descriptor then
            return data[INDEX_BUTTON].m_object
        end
    end
end

function MenuBar:SelectDescriptor(descriptor, skipAnimation, reselectIfSelected)
    local buttonObject = self:ButtonObjectForDescriptor(descriptor)
    if buttonObject then
        if IsVisible(buttonObject.m_buttonData) or buttonObject.m_buttonData.ignoreVisibleCheck then
            if (self.m_clickedButton and (self.m_clickedButton.m_buttonData == buttonObject.m_buttonData)) and not reselectIfSelected then
                return
            end

            self:SetClickedButton(nil, skipAnimation) -- reset

            -- TODO: use xml api?
            if not skipAnimation then
                buttonObject:MouseEnter()
            end

            buttonObject:Release(true, skipAnimation, CODE_DRIVEN)

            return true
        end
    end

    return false
end

function MenuBar:ClearSelection()
    self:SetClickedButton(nil, ADJUST_SIZE_INSTANT) -- reset
end

function MenuBar:SetDescriptorEnabled(descriptor, enabled)
    local buttonObject = self:ButtonObjectForDescriptor(descriptor)
    if(buttonObject) then
        local currentState = buttonObject:GetState()
        if(enabled and currentState == BSTATE_DISABLED) then
            buttonObject:SetState(BSTATE_NORMAL, ADJUST_SIZE_INSTANT)
        elseif(not enabled) then
            buttonObject:SetState(BSTATE_DISABLED, ADJUST_SIZE_INSTANT)
        end
    end
end

function MenuBar:GetAnimationData()
    return self.m_normalSize, self.m_downSize, self.m_animationDuration
end
--[[
    XML/External API for Menu Button
--]]

function ZO_MenuBarButtonTemplate_OnInitialized(self)
    self.m_object = MenuBarButton:New(self)
end

function ZO_MenuBarButtonTemplate_OnMouseEnter(self)
    return self.m_object:MouseEnter()
end

function ZO_MenuBarButtonTemplate_OnMouseExit(self)
    return self.m_object:MouseExit()
end

function ZO_MenuBarButtonTemplate_OnPress(self, button)
    if button == MOUSE_BUTTON_INDEX_LEFT then
        self.m_object:Press()
    end
end

function ZO_MenuBarButtonTemplate_OnMouseUp(self, button, upInside)
    if button == MOUSE_BUTTON_INDEX_LEFT then
        self.m_object:Release(upInside, ADJUST_SIZE_ANIMATED, PLAYER_DRIVEN)
    end
end

function ZO_MenuBarButtonTemplate_GetData(self)
    return self.m_object.m_buttonData
end

--[[
    XML/External API for Menu Bar
--]]

function ZO_MenuBar_OnInitialized(self)
    self.m_object = MenuBar:New(self)
end

function ZO_MenuBar_SetData(self, data)
    self.m_object:SetData(data)
end

function ZO_MenuBar_AddButton(self, buttonData)
    return self.m_object:AddButton(buttonData)
end

function ZO_MenuBar_GenerateButtonTabData(name, descriptor, normal, pressed, highlight, disabled, customTooltipFunction, alwaysShowTooltip, playerDrivenCallback)
    return {
        activeTabText = name,
        categoryName = name,

        descriptor = descriptor,
        normal = normal,
        pressed = pressed,
        highlight = highlight,
        disabled = disabled,
        CustomTooltipFunction = customTooltipFunction,
        alwaysShowTooltip = alwaysShowTooltip ~= false,
        callback = function(tabData, playerDriven)
            if playerDriven then
                playerDrivenCallback(tabData)
            end
        end,
    }
end

function ZO_MenuBar_GetButtonControl(self, descriptor)
    return self.m_object:GetButtonControl(descriptor)
end

function ZO_MenuBar_UpdateButtons(self, forceSelection)
    return self.m_object:UpdateButtons(forceSelection)
end

function ZO_MenuBar_ButtonControlIterator(self)
    return self.m_object:ButtonControlIterator()
end

function ZO_MenuBar_ClearButtons(self)
    self.m_object:ClearButtons()
end

function ZO_MenuBar_SelectDescriptor(self, descriptor, skipAnimation, reselectIfSelected)
    return self.m_object:SelectDescriptor(descriptor, skipAnimation, reselectIfSelected)
end

function ZO_MenuBar_SelectFirstVisibleButton(self, skipAnimation)
    return self.m_object:SelectFirstVisibleButton(skipAnimation)
end

function ZO_MenuBar_SelectLastVisibleButton(self, skipAnimation)
    return self.m_object:SelectLastVisibleButton(skipAnimation)
end

function ZO_MenuBar_SetDescriptorEnabled(self, descriptor, enabled)
    self.m_object:SetDescriptorEnabled(descriptor, enabled)
end

function ZO_MenuBar_GetSelectedDescriptor(self)
    return self.m_object:GetSelectedDescriptor()
end

function ZO_MenuBar_GetLastSelectedDescriptor(self)
    return self.m_object:GetLastSelectedDescriptor()
end

function ZO_MenuBar_ClearSelection(self)
    self.m_object:ClearSelection()
end

function ZO_MenuBar_SetAllButtonsEnabled(self, enabled, skipAnimation)
    self.m_object:SetAllButtonsEnabled(enabled, skipAnimation)
end

function ZO_MenuBar_SetClickSound(self, clickSound)
    self.m_object:SetClickSound(clickSound)
end

function ZO_MenuBar_ClearClickSound(self)
    self.m_object:ClearClickSound()
end

function ZO_MenuBar_RestoreLastClickedButton(self, skipAnimation)
    self.m_object:RestoreLastClickedButton(skipAnimation)
end

--ZO_LabelButtonBar

function ZO_MenuBarTooltipButton_OnMouseEnter(self)
    local buttonData = ZO_MenuBarButtonTemplate_GetData(self)
    if ZO_MenuBarButtonTemplate_OnMouseEnter(self) or buttonData.alwaysShowTooltip then
        InitializeTooltip(InformationTooltip, self, BOTTOM, 0, -10)
        if buttonData.CustomTooltipFunction then
            buttonData.CustomTooltipFunction(InformationTooltip)
        else
            local name = buttonData.categoryName
            if type(buttonData.categoryName) == "number" then
                name = GetString(buttonData.categoryName)
            end
            SetTooltipText(InformationTooltip, zo_strformat(SI_MENU_BAR_TOOLTIP, name))
        end
    end
end

function ZO_MenuBarTooltipButton_OnMouseExit(self)
    local buttonData = ZO_MenuBarButtonTemplate_GetData(self)
    if ZO_MenuBarButtonTemplate_OnMouseExit(self) or buttonData.alwaysShowTooltip  then
        ClearTooltip(InformationTooltip)
    end
end

function ZO_MenuBarButtonTemplateWithTooltip_OnMouseEnter(self)
    if ZO_MenuBarButtonTemplate_OnMouseEnter(self) then
        local buttonData = ZO_MenuBarButtonTemplate_GetData(self)
        if buttonData.tooltip then
            InitializeTooltip(InformationTooltip, self, BOTTOM, 0, -10)
            SetTooltipText(InformationTooltip, zo_strformat(SI_MENU_BAR_TOOLTIP, GetString(buttonData.tooltip)))
        end
    end
end

function ZO_MenuBarButtonTemplateWithTooltip_OnMouseExit(self)
    ZO_MenuBarTooltipButton_OnMouseExit(self)
end