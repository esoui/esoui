ZO_INTERACTIVE_CHAT_LOG_GAMEPAD_LOG_MAX_SIZE = 200
ZO_INTERACTIVE_CHAT_LOG_GAMEPAD_LOG_LINE_WIDTH = ZO_GAMEPAD_QUADRANT_1_2_3_CONTAINER_WIDTH - (ZO_GAMEPAD_INTERACTIVE_FILTER_HIGHLIGHT_PADDING * 2) --We squeeze in for the highlighting

ZO_InteractiveChatLog_Gamepad = ZO_Object.MultiSubclass(ZO_Gamepad_ParametricList_Screen, ZO_SocialOptionsDialogGamepad, ZO_GamepadMultiFocusArea_Manager)

function ZO_InteractiveChatLog_Gamepad:Initialize(control, scene)
    local ACTIVATE_ON_SHOW = true
    ZO_Gamepad_ParametricList_Screen.Initialize(self, control, ZO_GAMEPAD_HEADER_TABBAR_DONT_CREATE, ACTIVATE_ON_SHOW, scene)
    ZO_SocialOptionsDialogGamepad.Initialize(self)
    ZO_GamepadMultiFocusArea_Manager.Initialize(self)

    local logFragment = ZO_FadeSceneFragment:New(control)
    scene:AddFragment(logFragment)

    self:InitializeHeader()
    self:InitializeControls()
    self:InitializeTextInputSection()
    self:InitializePassiveFocus()
    self:RegisterForEvents()

    --This screen needs to manage the narration a bit differently, so unregister ourselves upon creation
    SCREEN_NARRATION_MANAGER:UnregisterParametricList(self.list)
end

function ZO_InteractiveChatLog_Gamepad:InitializeHeader()
    -- Optional override
end

function ZO_InteractiveChatLog_Gamepad:InitializeControls()
    self.messageEntries = {}
    self.nextMessageId = 1
    self.mask = self.control:GetNamedChild("Mask")
    self.textInputControl = self.mask:GetNamedChild("TextInput")

    self.textControl = self.textInputControl:GetNamedChild("Text")
    self.textEdit = self.textControl:GetNamedChild("EditBox")
    self.textControlHighlight = self.textControl:GetNamedChild("Highlight")

    --Log List--
    local list = self:GetMainList()
    list:SetSelectedItemOffsets(0, 0)
    list:SetAnchorOppositeSide(true)
    list:SetHandleDynamicViewProperties(true)
    list:AddDataTemplate("ZO_InteractiveChatLog_Gamepad_LogLine", function(...) self:SetupLogMessage(...) end, ZO_GamepadMenuEntryTemplateParametricListFunction, function(a, b) return a.data.id == b.data.id end)

    local function HandleListDirectionalInput(result)
        if result == MOVEMENT_CONTROLLER_MOVE_NEXT then
            if list:GetSelectedIndex() == list:GetNumEntries() then
                self:FocusTextInput()
            end
        end
    end

    list:SetCustomDirectionInputHandler(HandleListDirectionalInput)
    list:SetDirectionalInputEnabled(false)
    list:SetSoundEnabled(false)
    self.list = list

    self.moreBelowTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_InteractiveChatLog_Gamepad_MoreBelowAnimation", self.mask:GetNamedChild("MoreBelow"))
end

function ZO_InteractiveChatLog_Gamepad:InitializeTextInputSection()
    --For passive focus switching between text input area and chat entry list
    self.textInputVerticalMovementController = ZO_MovementController:New(MOVEMENT_CONTROLLER_DIRECTION_VERTICAL)

    self:InitializeTextEdit()
end


function ZO_InteractiveChatLog_Gamepad:InitializeTextEdit()
    local function TextEditFocusGained()
        self.textInputAreaFocalArea:Deactivate()
        ZO_GamepadEditBox_FocusGained(self.textEdit)
    end

    local function TextEditFocusLost()
        ZO_GamepadEditBox_FocusLost(self.textEdit)
        self:FocusTextInput()
    end

    local function TextEditTextChanged()
        if self.textInputAreaFocalArea:IsFocused() then
            self.textInputAreaFocalArea:UpdateKeybinds()
        end
    end

    self.textEdit:SetHandler("OnFocusGained", TextEditFocusGained)
    self.textEdit:SetHandler("OnFocusLost", TextEditFocusLost)
    self.textEdit:SetHandler("OnTextChanged", TextEditTextChanged)
end

function ZO_InteractiveChatLog_Gamepad:InitializePassiveFocus()
    --Passive Area Focus--
    local function TextInputAreaActivateCallback()
        self:OnTextInputAreaActivated()
    end

    local function TextInputAreaDeactivateCallback()
        self:OnTextInputAreaDeactivated()
    end

    self.textInputAreaFocalArea = ZO_GamepadMultiFocusArea_Base:New(self, TextInputAreaActivateCallback, TextInputAreaDeactivateCallback)

    local function ChatEntryPanelActivateCallback()
        self:OnChatEntryPanelActivated()
    end

    local function ChatEntryPanelDeactivateCallback()
        self:OnChatEntryPanelDeactivated()
    end
    self.chatEntryPanelFocalArea = ZO_GamepadMultiFocusArea_Base:New(self, ChatEntryPanelActivateCallback, ChatEntryPanelDeactivateCallback)

    self:AddNextFocusArea(self.chatEntryPanelFocalArea)
    self:AddNextFocusArea(self.textInputAreaFocalArea)
end

function ZO_InteractiveChatLog_Gamepad:RegisterForEvents()
    local function OnScreenResized()
        self:OnScreenResized()
    end

    self.control:RegisterForEvent(EVENT_SCREEN_RESIZED, OnScreenResized)
end

function ZO_InteractiveChatLog_Gamepad:InitializeFocusKeybinds()
    -- Optional override
end

-- ZO_Gamepad_ParametricList_Screen Overrides

function ZO_InteractiveChatLog_Gamepad:OnDeferredInitialize()
    self:ReadjustFixedCenterOffset()
    self:InitializeFocusKeybinds()
end

function ZO_InteractiveChatLog_Gamepad:PerformUpdate()
    self.dirty = false
end

function ZO_InteractiveChatLog_Gamepad:OnShow()
    self.list:RefreshVisible()
    self:FocusTextInput()
end

function ZO_InteractiveChatLog_Gamepad:OnHiding()
    if self.currentFocalArea then
        self.currentFocalArea:Deactivate()
    end
end

function ZO_InteractiveChatLog_Gamepad:OnTargetChanged(list, targetData, oldTargetData, reachedTarget, targetSelectedIndex)
    self:RefreshMoreBelow(targetSelectedIndex)
    self:SetupOptions(targetData)
    if self.chatEntryPanelFocalArea:IsFocused() then
        self.chatEntryPanelFocalArea:UpdateKeybinds()
    end
end

-- End ZO_Gamepad_ParametricList_Screen Overrides

-- ZO_GamepadMultiFocusArea_Manager Overrides

function ZO_InteractiveChatLog_Gamepad:UpdateDirectionalInput()
    --We don't want to change focus to the chat entry area if there are no entries to scroll through
    if self.list:GetNumEntries() > 0 then
        local result = self.textInputVerticalMovementController:CheckMovement()
        if result == MOVEMENT_CONTROLLER_MOVE_PREVIOUS then
            self.textInputAreaFocalArea:HandleMovePrevious()
        end
    end
end

-- End ZO_GamepadMultiFocusArea_Manager Overrides

-- ZO_SocialOptionsDialogGamepad Overrides

-- We expect child classes to override these functions, but this class doesn't alter their behavior
-- Leaving these here as comments to make it easier to find the source of these functions
--function ZO_InteractiveChatLog_Gamepad:SetupOptions(socialData)
--function ZO_InteractiveChatLog_Gamepad:BuildOptionsList()

-- End ZO_SocialOptionsDialogGamepad Overrides

function ZO_InteractiveChatLog_Gamepad:FocusTextInput()
    if self.scene:IsShowing() then
        if self.currentFocalArea ~= self.textInputAreaFocalArea then
            if self.currentFocalArea then
                self.currentFocalArea:Deactivate()
            end
            self.currentFocalArea = self.textInputAreaFocalArea
        end
        self.currentFocalArea:Activate()
    end
end

do
    local FIXED_CENTER_OFFSET_PADDING = 37

    function ZO_InteractiveChatLog_Gamepad:ReadjustFixedCenterOffset()
        local scrollHeight = self.list.control:GetHeight()
        local fixedCenterOffset = scrollHeight / 2 - FIXED_CENTER_OFFSET_PADDING
        self.list:SetFixedCenterOffset(fixedCenterOffset)
    end
end

function ZO_InteractiveChatLog_Gamepad:SetupLogMessage(control, data, selected, reselectingDuringRebuild, enabled, active)
    ZO_SharedGamepadEntry_OnSetup(control, data, selected, reselectingDuringRebuild, enabled, active)
    
    -- Optional override
end

function ZO_InteractiveChatLog_Gamepad:RefreshMoreBelow(targetSelectedIndex)
    local isMoreBelow = targetSelectedIndex < self.list:GetNumItems()
    if isMoreBelow then
        self.moreBelowTimeline:PlayForward()
    else
        self.moreBelowTimeline:PlayBackward()
    end
end

function ZO_InteractiveChatLog_Gamepad:BuildChatList()
    self.list:Clear()

    for i, entry in ipairs(self.messageEntries) do
        self.list:AddEntry("ZO_InteractiveChatLog_Gamepad_LogLine", entry)
    end

    self.list:Commit()
end

function ZO_InteractiveChatLog_Gamepad:OnScreenResized()
    self:ReadjustFixedCenterOffset()
end

function ZO_InteractiveChatLog_Gamepad:OnTextInputAreaActivated()
    DIRECTIONAL_INPUT:Activate(self, self.textInputControl)
end

function ZO_InteractiveChatLog_Gamepad:OnTextInputAreaDeactivated()
    DIRECTIONAL_INPUT:Deactivate(self)
end

function ZO_InteractiveChatLog_Gamepad:OnChatEntryPanelActivated()
    local function EnableChatDirectionalInputLater()
        if self.chatEntryPanelFocalArea:IsFocused() then
            self.list:SetDirectionalInputEnabled(true)
        end
    end

    --Wait until we are actually navigating the chat panel before we start caring about narrating it
    SCREEN_NARRATION_MANAGER:RegisterParametricListScreen(self.list, self)
    SCREEN_NARRATION_MANAGER:QueueParametricListEntry(self.list)

    --We want the chat entry list to wait a moment before it starts processing the input
    --Otherwise it will move immediately on the next frame after gaining focus
    zo_callLater(EnableChatDirectionalInputLater, 200)
    self.list:RefreshVisible()
    self.list:SetSoundEnabled(true)
end

function ZO_InteractiveChatLog_Gamepad:OnChatEntryPanelDeactivated()
    --Once we leave the chat panel we no longer want to narrate anything in it, so unregister ourselves again
    SCREEN_NARRATION_MANAGER:UnregisterParametricList(self.list)
    self.list:SetDirectionalInputEnabled(false)
    self.list:RefreshVisible()
    self.list:SetSoundEnabled(false)
end

--------------
--Global XML--
--------------

do
    local function GetHeight(self)
        return self.label:GetTextHeight()
    end

    function ZO_InteractiveChatLog_Gamepad_LogLine_OnInitialized(self)
        ZO_SharedGamepadEntry_OnInitialized(self)
        self.GetHeight = GetHeight
        self.label = self:GetNamedChild("Label")
    end
end
