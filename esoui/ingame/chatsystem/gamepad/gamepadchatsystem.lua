-- Globals
local g_expirationTime = nil

local ZO_GAMEPAD_CHAT_SYSTEM_SECONDS_VISIBLE_UNPINNED = 20

local function IsChatNarrationEnabled()
    return GetSetting_Bool(SETTING_TYPE_ACCESSIBILITY, ACCESSIBILITY_SETTING_TEXT_CHAT_NARRATION)
end

local function IsZoneChatNarrationEnabled()
    return GetSetting_Bool(SETTING_TYPE_ACCESSIBILITY, ACCESSIBILITY_SETTING_ZONE_CHAT_NARRATION)
end

--
--[[ Chat Container ]]--
--

GamepadChatContainer = SharedChatContainer:Subclass()

function GamepadChatContainer:New(...)
    return SharedChatContainer.New(self, ...)
end

function GamepadChatContainer:Initialize(control, windowPool, tabPool)
    SharedChatContainer.Initialize(self, control, windowPool, tabPool)

    self.hudEnabled = false

    self:SetAllowSaveSettings(true)
    self:InitializeWindowManagement(control, windowPool, tabPool)
    self:InitializeScrolling(control)
end

function GamepadChatContainer:ShowRemoveTabDialog(index)
    -- Design says we don't want more chat containers on console...replace this with a gamepad dialog if we need them later
    SharedChatContainer.ShowRemoveTabDialog(self, index, "CHAT_TAB_REMOVE")
end

function GamepadChatContainer:FadeOut(delay)
    -- doing nothing on purpose
end

function GamepadChatContainer:UpdateInteractivity(isInteractive)
    SharedChatContainer.UpdateInteractivity(self, isInteractive)

    self.control:SetMouseEnabled(false)
end

function GamepadChatContainer:HandleVisibleTimeExpired()
    GAMEPAD_CHAT_SYSTEM:Minimize()
end

function GamepadChatContainer:FadeOutLines()
    for tabIndex = 1, #self.windows do
        local FADE_BEGIN = 3
        local FADE_DURATION = 2

        self.windows[tabIndex].buffer:SetLineFade(FADE_BEGIN, FADE_DURATION)
    end
end

function GamepadChatContainer:PerformLayout()
    SharedChatContainer.PerformLayout(self)

    self:ApplyInsertIndicator()
    self:SyncScrollToBuffer()
end

local ANCHOR_SETTINGS =
{
    point = BOTTOMRIGHT,
    relPoint = BOTTOMRIGHT,
    x = 0,
    y = -215,

    width = 490,
    height = 280,
}

function GamepadChatContainer:LoadSettings(settings)
    self.control:ClearAnchors()
    self.control:SetAnchor(ANCHOR_SETTINGS.point, nil, ANCHOR_SETTINGS.relPoint, ANCHOR_SETTINGS.x, ANCHOR_SETTINGS.y)
    self.control:SetDimensions(ANCHOR_SETTINGS.width, ANCHOR_SETTINGS.height)

    SharedChatContainer.LoadSettings(self, settings)
end

do
    --Any new language specific zone chat categories should be added to this table
    internalassert(OFFICIAL_LANGUAGE_MAX_VALUE == 6)
    local ZONE_CHAT_CATEGORIES =
    {
        [CHAT_CATEGORY_ZONE] = true,
        [CHAT_CATEGORY_ZONE_ENGLISH] = true,
        [CHAT_CATEGORY_ZONE_FRENCH] = true,
        [CHAT_CATEGORY_ZONE_GERMAN] = true,
        [CHAT_CATEGORY_ZONE_JAPANESE] = true,
        [CHAT_CATEGORY_ZONE_RUSSIAN] = true,
        [CHAT_CATEGORY_ZONE_SPANISH] = true,
        [CHAT_CATEGORY_ZONE_CHINESE_S] = true,
    }

    function GamepadChatContainer:AddEventMessageToWindow(window, message, category, narrationMessage, overrideColorDef)
        SharedChatContainer.AddEventMessageToWindow(self, window, message, category, narrationMessage, overrideColorDef)
        self.windowContainer:SetHidden(false)
        self.system:StartVisibilityTimer()
        --Determine if this message will be visible in the chat
        if self.currentBuffer == window.buffer then
            --Only narrate zone chat if the zone chat narration setting is enabled
            if IsZoneChatNarrationEnabled() or not ZONE_CHAT_CATEGORIES[category] then
                local narration = narrationMessage or message
                SCREEN_NARRATION_MANAGER:NarrateChatMessage(narration, category)
            end
        end
    end
end

function GamepadChatContainer:SetAsPrimary()
    self.primary = true

    self.windowContainer:ClearAnchors()
    self.windowContainer:SetAnchor(TOPLEFT, self.system.control, TOPLEFT)
    self.windowContainer:SetAnchor(BOTTOMRIGHT, self.system.textEntry:GetControl(), TOPRIGHT, 0, -3)
end

function GamepadChatContainer:GetChatFont()
    return ZoFontGamepadChat
end

--
--[[ Chat System ]]--
--

ZO_GamepadChatSystem = SharedChatSystem:Subclass()

function ZO_GamepadChatSystem:New(...)
    return SharedChatSystem.New(self, ...)
end

local FADE_TIME_MS = 350

local CONSOLE_SETTINGS =
{
    horizontalAlignment = TEXT_ALIGN_LEFT,
    linesInheritAlpha = true,
    hideTabs = true,
    hideScrollBar = true,

    numBlinks = 1,
    initialFadeAlpha = 1,
    finalFadeAlpha = 0,
    fadeTransitionTime = FADE_TIME_MS,

    chatEditBufferTop = 9,
    chatEditBufferBottom = 8,
}

function ZO_GamepadChatSystem:Initialize(control)
    SharedChatSystem.Initialize(self, control, CONSOLE_SETTINGS)

    self.chatBubble = control:GetNamedChild("ChatBubble")
    self.editControl = control:GetNamedChild("TextEntryEditBox")
    self.newChatFadeAnim = ZO_AlphaAnimation:New(self.chatBubble)

    self.fadeTextEntry = ZO_AlphaAnimation:New(self.textEntry:GetControl())
    self.fadeBackground = ZO_AlphaAnimation:New(control:GetNamedChild("Bg"))
    self.fadeTextEntry:SetMinMaxAlpha(0, 1)
    self.fadeBackground:SetMinMaxAlpha(0, 1)
    self.hasFocus = true

    if IsChatSystemAvailableForCurrentPlatform() then
        -- timer handling
        local function OnUpdate()
            -- do not fade if the user is actively editing text
            if not IsVirtualKeyboardOnScreen() and not self.editControl:HasFocus() then
                if g_expirationTime then
                    if GetFrameTimeSeconds() > g_expirationTime then
                        g_expirationTime = nil

                        for i,container in pairs(self.containers) do
                            container:HandleVisibleTimeExpired()
                        end
                    end
                end
            end
        end

        control:SetHandler("OnUpdate", OnUpdate)
    end

    self.UIModeInputEater =
    {
        UpdateDirectionalInput = function()
            DIRECTIONAL_INPUT:ConsumeAll()
        end
    }
end

local function NewContainerHelper(chat, control, windowPool, tabPool)
    return GamepadChatContainer:New(chat, control, windowPool, tabPool)
end

function ZO_GamepadChatSystem:LoadChatFromSettings()
    SharedChatSystem.LoadChatFromSettings(self, NewContainerHelper)

    local fontSize = self:GetFontSizeFromSetting()
    self:SetFontSize(fontSize)

    self:Minimize()
end

function ZO_GamepadChatSystem:InitializeSharedControlManagement(control)
    SharedChatSystem.InitializeSharedControlManagement(self, control, NewContainerHelper, "ZO_GamepadChatWindowTemplate", "ZO_ChatWindowTab_Gamepad")
end

function ZO_GamepadChatSystem:IsHUDEnabled()
    return self.hudEnabled
end

function ZO_GamepadChatSystem:SetHUDEnabled(setEnabled)
    if self.hudEnabled ~= setEnabled then
        self.hudEnabled = setEnabled
        self:RefreshVisibility()
    end
end

function ZO_GamepadChatSystem:InitializeEventManagement()
    self:InitializeSharedEvents("GamepadChatSystem")

    if IsChatSystemAvailableForCurrentPlatform() then
        local function UpdateHUDEnabledFromSetting()
            local settingValue = GetSetting_Bool(SETTING_TYPE_UI, UI_SETTING_GAMEPAD_CHAT_HUD_ENABLED)
            self:SetHUDEnabled(settingValue)
        end

        local function OnInterfaceSettingChanged(eventCode, settingType, settingId)
            if settingId == UI_SETTING_GAMEPAD_CHAT_HUD_ENABLED then
                UpdateHUDEnabledFromSetting()
            end
        end

        local function OnChatMessageChannel()
            if GAMEPAD_CHAT_SYSTEM:IsMinimized() then
                --Let the player know that a new chat message has arrived
                self:StartNewChatNotification()
            end
        end

        local function OnChatChannelUpdated()
            local channelData, channelTarget = CHAT_ROUTER:GetCurrentChannelData()
            self:SetChannelInternal(channelData.id, channelTarget)
        end

        EVENT_MANAGER:RegisterForEvent("GamepadChatSystem", EVENT_CHAT_MESSAGE_CHANNEL, OnChatMessageChannel)
        EVENT_MANAGER:RegisterForEvent("GamepadChatSystem", EVENT_INTERFACE_SETTING_CHANGED, OnInterfaceSettingChanged)
        EVENT_MANAGER:AddFilterForEvent("GamepadChatSystem", EVENT_INTERFACE_SETTING_CHANGED, REGISTER_FILTER_SETTING_SYSTEM_TYPE, SETTING_TYPE_UI)

        CALLBACK_MANAGER:RegisterCallback("OnChatChannelUpdated", OnChatChannelUpdated)
    end
end

function ZO_GamepadChatSystem:StartTextEntry(text, channel, target, dontShowHUDWindow)
    if ZO_Dialogs_IsShowingDialog() then
        return
    end

    -- if we are in a scene that's blocking chat, we don't want to activate the chat whatsoever
    -- this fixes issues where the chat is showing, but not active, when we enter a scene that blocks chat
    if self:ShouldTextEntryBeBlocked() then
        return
    end

    if not dontShowHUDWindow then
        --As a convenience, auto enable the HUD if the user uses any shortcut to start chatting in the HUD
        SetSetting(SETTING_TYPE_UI, UI_SETTING_GAMEPAD_CHAT_HUD_ENABLED, "true")
        self:SetHUDEnabled(true)
    end

    SharedChatSystem.StartTextEntry(self, text, channel, target, dontShowHUDWindow)

    if not dontShowHUDWindow then
        self.textEntry:GetEditControl():TakeFocus()
    end
end

function ZO_GamepadChatSystem:CloseTextEntry(keepText)
    SharedChatSystem.CloseTextEntry(self, keepText)
    if DIRECTIONAL_INPUT:IsListening(self.UIModeInputEater) then
        ZO_GamepadEditBox_FocusLost(self.textEntry:GetEditControl())
        RemoveActionLayerByName("GamepadChatSystem")
        DIRECTIONAL_INPUT:Deactivate(self.UIModeInputEater)
    end
end

function ZO_GamepadChatSystem:OnTextEntryFocusGained()
    DIRECTIONAL_INPUT:Activate(self.UIModeInputEater, self.control)
    PushActionLayerByName("GamepadChatSystem")
    ZO_GamepadEditBox_FocusGained(self.textEntry:GetEditControl())
end

-- handle this so we don't minimize the window due to the fadeout timer while the user is typing
function ZO_GamepadChatSystem:OnTextEntryChanged(newText)
    SharedChatSystem.OnTextEntryChanged(self, newText)

    self:StartVisibilityTimer()
end

function ZO_GamepadChatSystem:ResetContainerPositionAndSize(container)
    container:LoadSettings()
end

function ZO_GamepadChatSystem:Maximize()
    if self.loaded and self.hudEnabled and (self.isMinimized or not self.hasFocus or self.isPinnedAndFaded) then
        if self.newChatFadeAnim and self.newChatFadeAnim:IsPlaying() then
            self.newChatFadeAnim:Stop()
            self.chatBubble:SetAlpha(1)
        end

        self:StartVisibilityTimer()

        local textEntry = self.textEntry

        textEntry.editBg:SetHidden(false)
        textEntry.channelLabel:SetHidden(false)

        self.primaryContainer.windowContainer:SetHidden(false)

        -- force this stuff to fade-in - it could've faded out if the player was using chat outside of the screen version
        for i,container in pairs(self.containers) do
            container:FadeIn()

            for tabIndex = 1, #container.windows do
                container.windows[tabIndex].buffer:ShowFadedLines()

                local NEVER_FADE = 0
                container.windows[tabIndex].buffer:SetLineFade(NEVER_FADE, NEVER_FADE)
            end
        end

        self.fadeTextEntry:FadeIn(0, FADE_TIME_MS)
        self.fadeBackground:FadeIn(0, FADE_TIME_MS)

        self.isMinimized = false
        self.hasFocus = true
        self.isPinnedAndFaded = false

        CALLBACK_MANAGER:FireCallbacks("GamepadChatSystemActiveOnScreen")
    end
end

function ZO_GamepadChatSystem:HideWhenDeactivated(fadeBgAlpha, fadeText, fadeTextAlpha)
    if fadeText then
        self.fadeTextEntry:SetMinMaxAlpha(fadeTextAlpha or 0, 1)
        self.fadeTextEntry:FadeOut(0, FADE_TIME_MS)
    end

    self.fadeBackground:SetMinMaxAlpha(fadeBgAlpha or 0, 1)
    self.fadeBackground:FadeOut(0, FADE_TIME_MS)
end

local FADE_TEXT = true

function ZO_GamepadChatSystem:Minimize()
    if self.loaded then
        self:HideWhenDeactivated(nil, FADE_TEXT)
        local KEEP_TEXT_ENTERED = true
        self:CloseTextEntry(KEEP_TEXT_ENTERED)

        local textEntry = self.textEntry
        textEntry.editBg:SetHidden(true)
        textEntry.channelLabel:SetHidden(true)

        self.primaryContainer.windowContainer:SetHidden(true)

        self.isMinimized = true
    end
end

function ZO_GamepadChatSystem:HasFocus()
    return self.hasFocus
end

function ZO_GamepadChatSystem:SetPinnedAndFaded(pinnedAndFaded)
    self.isPinnedAndFaded = pinnedAndFaded
end

function ZO_GamepadChatSystem:FadeOutWindowContainers(minAlpha)
    for _, container in pairs(self.containers) do
        container:SetMinAlpha(minAlpha)
        SharedChatContainer.FadeOut(container, 0)
    end
end

function ZO_GamepadChatSystem:StartVisibilityTimer()
    local secondsToExpire = ZO_GAMEPAD_CHAT_SYSTEM_SECONDS_VISIBLE_UNPINNED
    g_expirationTime = GetFrameTimeSeconds() + secondsToExpire
end

do
    local FILTERED_OUT_CATEGORIES =
    {
        [CHAT_CATEGORY_MONSTER_SAY] = true,
        [CHAT_CATEGORY_MONSTER_YELL] = true,
        [CHAT_CATEGORY_MONSTER_EMOTE] = true,
        [CHAT_CATEGORY_MONSTER_WHISPER] = true,
    }

    function ZO_GamepadChatSystem:OnFormattedChatMessage(message, category, targetChannel, fromDisplayName, rawMessageText, narrationMessage, overrideColorDef)
        if FILTERED_OUT_CATEGORIES[category] then
            return
        end

        SharedChatSystem.OnFormattedChatMessage(self, message, category, targetChannel, fromDisplayName, rawMessageText, narrationMessage, overrideColorDef)

        if not self.isMinimized then
            self:Maximize()
        end
    end
end

function ZO_GamepadChatSystem:GetFont()
    return ZoFontGamepadEditChat
end

function ZO_GamepadChatSystem:GetFontSizeString(fontSize)
    return string.format("$(GP_%d)", fontSize)
end

function ZO_GamepadChatSystem:GetFontSizeFromSetting()
    return GetGamepadChatFontSize()
end

function ZO_GamepadChatSystem:SetChannel(newChannel, channelTarget)
    if newChannel == CHAT_CHANNEL_WHISPER or newChannel == CHAT_CHANNEL_WHISPER_SENT then
        if channelTarget and channelTarget ~= "" then
            channelTarget = DecorateDisplayName(channelTarget)
        end
    end

    SharedChatSystem.SetChannel(self, newChannel, channelTarget)
end

-- override
function ZO_GamepadChatSystem:ShouldOnlyShowOnHUD()
    return true
end

--override
function ZO_GamepadChatSystem:OnPlayerActivated()
    if not IsChatSystemAvailableForCurrentPlatform() then
        return
    end
    local settingValue = GetSetting_Bool(SETTING_TYPE_UI, UI_SETTING_GAMEPAD_CHAT_HUD_ENABLED)
    self:SetHUDEnabled(settingValue)
end

-- override
function ZO_GamepadChatSystem:IsHidden()
    if not IsChatSystemAvailableForCurrentPlatform() then
        return true
    end

    -- On platforms with both chat systems, hide on the opposite UI mode
    if ZO_ChatSystem_ShouldUseKeyboardChatSystem() then
        return true
    end

    -- Show the chat system on the HUD, but only if the player has opted in
    if self:IsHUDEnabled() and HUD_FRAGMENT:IsShowing() then
        return false
    end

    -- TODO: if you directly interact with the chat menu, by for example using
    -- enter key, we will automatically show the chat window until visibility is
    -- refreshed. This is the Intended(tm) behavior, but it's not reflected explicitly in these rules anywhere

    return true
end

--[[ XML Functions ]]--
function ZO_GamepadTextChat_OnInitialize(control)
    if ZO_ChatSystem_DoesPlatformUseGamepadChatSystem() then
        GAMEPAD_CHAT_SYSTEM = ZO_GamepadChatSystem:New(control)
        SYSTEMS:RegisterGamepadObject("ChatSystem", GAMEPAD_CHAT_SYSTEM)
    end
end