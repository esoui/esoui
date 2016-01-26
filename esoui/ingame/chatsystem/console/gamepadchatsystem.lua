-- Globals
local g_expirationTime = nil

local ZO_GAMEPAD_CHAT_SYSTEM_SECONDS_VISIBLE_UNPINNED = 20
local ZO_GAMEPAD_CHAT_SYSTEM_SECONDS_VISIBLE_PINNED = 10

--
--[[ Chat Container ]]--
--

GamepadChatContainer = SharedChatContainer:Subclass()

function GamepadChatContainer:New(...)
	return SharedChatContainer.New(self, ...)
end

function GamepadChatContainer:Initialize(control, windowPool, tabPool)
	SharedChatContainer.Initialize(self, control, windowPool, tabPool)
	
	self.windowPinned = false

    self:SetAllowSaveSettings(true)
    self:InitializeWindowManagement(control, windowPool, tabPool)
    self:InitializeScrolling(control)
    self:FadeOut()
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
    self.scrollbar:SetHidden(true)
end

local TEXT_OPACITY_WHEN_CLIPPING_QUEST_TRACKER = 0.25
do
    local BG_OPACITY_WHEN_PINNED = 0.2

    function GamepadChatContainer:HandleVisibleTimeExpired()
        if GAMEPAD_TEXT_CHAT_SCENE:IsShowing() then return end

	    if CHAT_SYSTEM:IsWindowPinned() then
            if CHAT_SYSTEM:HasFocus() then
                -- Fade background to low opacity
                local shouldFadeText = FOCUSED_QUEST_TRACKER:IsOverlappingTextChat()
                CHAT_SYSTEM:HideWhenDeactivated(BG_OPACITY_WHEN_PINNED, shouldFadeText, shouldFadeText and TEXT_OPACITY_WHEN_CLIPPING_QUEST_TRACKER)

                local KEEP_TEXT_ENTERED = true
	            CHAT_SYSTEM:CloseTextEntry(KEEP_TEXT_ENTERED)
                CHAT_SYSTEM:SetPinnedAndFaded(true)
            end
	    else
		    -- hide it, not pinned
		    CHAT_SYSTEM:Minimize()
	    end
    end
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

    self:UpdateOverflowArrow()
    self:ApplyInsertIndicator(insertIndex)
    self:SyncScrollToBuffer()
end

local ANCHOR_SETTINGS =
{
	point = BOTTOMRIGHT,
	relPoint = BOTTOMRIGHT,
	x = -96,
	y = -202,

	width = 650,
	height = 400,
}

function GamepadChatContainer:LoadSettings(settings)
    self.control:ClearAnchors()
    self.control:SetAnchor(ANCHOR_SETTINGS.point, nil, ANCHOR_SETTINGS.relPoint, ANCHOR_SETTINGS.x, ANCHOR_SETTINGS.y)
    self.control:SetDimensions(ANCHOR_SETTINGS.width, ANCHOR_SETTINGS.height)

    SharedChatContainer.LoadSettings(self, settings)
end

function GamepadChatContainer:AddEventMessageToWindow(...)
    SharedChatContainer.AddEventMessageToWindow(self, ...)
    self.windowContainer:SetHidden(false)
    self.system:StartVisibilityTimer()
end

function GamepadChatContainer:SetAsPrimary()
    self.primary = true
    self:AnchorOverTextEntry()
end

function GamepadChatContainer:AnchorAboveTextEntry()
    local textEntry = self.system.textEntry
    textEntry.editBg:SetHidden(false)
    textEntry.channelLabel:SetHidden(false)

    self.windowContainer:ClearAnchors()
    self.windowContainer:SetAnchor(TOPLEFT, self.system.control, TOPLEFT)
    self.windowContainer:SetAnchor(BOTTOMRIGHT, textEntry:GetControl(), TOPRIGHT, 36, -3)
    self.windowContainer:SetHidden(false)

    self.system.anchoredOverTextEntry = false
end

function GamepadChatContainer:AnchorOverTextEntry()
    local textEntry = self.system.textEntry
    textEntry.editBg:SetHidden(true )
    textEntry.channelLabel:SetHidden(true)

    self.windowContainer:ClearAnchors()
    self.windowContainer:SetAnchor(TOPLEFT, textEntry:GetControl(), TOPLEFT, 0 , 12)
    self.windowContainer:SetAnchor(BOTTOMRIGHT, textEntry:GetControl(), BOTTOMRIGHT)
    self.windowContainer:SetHidden(true)

    self.system.anchoredOverTextEntry = true
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
    horizontalAlignment = TEXT_ALIGN_RIGHT,
    linesInheritAlpha = true,
    hideTabs = true,
    hideScrollBar = true,

    numBlinks = 1,
    initialFadeAlpha = 1,
    finalFadeAlpha = 0,
    fadeTransitionTime = FADE_TIME_MS,
}

function ZO_GamepadChatSystem:Initialize(control)
	SharedChatSystem.Initialize(self, control, CONSOLE_SETTINGS)

    self.chatBubble = control:GetNamedChild("ChatBubble")
    self.newChatFadeAnim = ZO_AlphaAnimation:New(self.chatBubble)

    self.fadeTextEntry = ZO_AlphaAnimation:New(self.textEntry:GetControl())
    self.fadeBackground = ZO_AlphaAnimation:New(control:GetNamedChild("Bg"))
    self.fadeTextEntry:SetMinMaxAlpha(0, 1)
    self.fadeBackground:SetMinMaxAlpha(0, 1)
    self.hasFocus = true
    
    GAMEPAD_TEXT_CHAT_SCENE = ZO_Scene:New("gamepad_text_chat", SCENE_MANAGER)

    if IsChatSystemAvailableForCurrentPlatform() then
        self:InitializeKeybindStrip()

        GAMEPAD_TEXT_CHAT_SCENE:RegisterCallback("StateChange", function(oldState, newState)
            if newState == SCENE_SHOWING then
                self:Maximize()

                KEYBIND_STRIP:RemoveDefaultExit()
                KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
            elseif newState == SCENE_HIDDEN then
                KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
                KEYBIND_STRIP:RestoreDefaultExit()

                self:StartVisibilityTimer()
            end
        end)
        
        -- timer handling
        local function OnUpdate()
            -- do not fade if the virtual keyboard is open
            if(not IsVirtualKeyboardOnscreen()) then
                if g_expirationTime and (not self.isMinimized or (self.anchoredOverTextEntry and not self:IsWindowPinned())) then
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

	self:SetupFonts()

	self:Minimize()
end

function ZO_GamepadChatSystem:InitializeSharedControlManagement(control)
	SharedChatSystem.InitializeSharedControlManagement(self, control, NewContainerHelper)
end

function ZO_GamepadChatSystem:InitializeKeybindStrip()
	self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,

		-- back options
		{
			keybind = "UI_SHORTCUT_EXIT",
            ethereal = true,
			order = -10000,
			callback = function()
				SCENE_MANAGER:ShowBaseScene()
			end,
		},

		{
			name = GetString(SI_GAMEPAD_BACK_OPTION),
			keybind = "UI_SHORTCUT_NEGATIVE",
			order = -10000,
			callback = function()
				SCENE_MANAGER:HideCurrentScene()
			end,
        },

		-- Enter text
        {
            name = function()
                return GetString(SI_GAMEPAD_ENTER_TEXT)
            end,
            keybind = "UI_SHORTCUT_PRIMARY",
            callback = function()
                self:StartTextEntry()
            end,
            sound = SOUNDS.EDIT_CLICK,
        },

		-- Pin / unpin chat window
		{
            name = function()
				return self:IsWindowPinned() and GetString(SI_GAMEPAD_UNPIN_CHAT_WINDOW) or GetString(SI_GAMEPAD_PIN_CHAT_WINDOW)
            end,
            keybind = "UI_SHORTCUT_TERTIARY",
            callback = function()
				self:SetWindowPinned(not self:IsWindowPinned())
            end,
            sound = SOUNDS.DEFAULT_CLICK,
        },
	}

    --small keybind with just a back button to minimize the chat box when it is opened during UI mode
    self.closeDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,

		{
			name = GetString(SI_GAMEPAD_CLOSE_CHAT_WINDOW),
			keybind = "UI_SHORTCUT_NEGATIVE",
			callback = function()
			    self:Minimize()
			end,
		},
		{
			ethereal = true,
			keybind = "DIALOG_NEGATIVE",
			callback = function()
			    self:Minimize()
			end,
		},
    }
end

function ZO_GamepadChatSystem:IsWindowPinned()
	return self.windowPinned
end

function ZO_GamepadChatSystem:SetWindowPinned(setPinned)
	self.windowPinned = setPinned

    MAIN_MENU_GAMEPAD:RefreshLists()
	KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_GamepadChatSystem:SetupFonts()
	local consoleFont = "ZoFontGamepad34"
	self:SetAllFonts(consoleFont)
end

function ZO_GamepadChatSystem:InitializeEventManagement()
    SharedChatSystem.InitializeEventManagement(self)

    if IsChatSystemAvailableForCurrentPlatform() then
        local function OnPlayerActivated()
            if CHAT_SYSTEM:IsWindowPinned() then
                self:Maximize()
            end
        end

        local function OnChatMessageChannel()
            if not CHAT_SYSTEM:IsWindowPinned() and CHAT_SYSTEM:IsMinimized() then
                --Let the player know that a new chat message has arrived
                self:StartNewChatNotification()
            end
        end

        EVENT_MANAGER:RegisterForEvent("GamepadChatSystem", EVENT_PLAYER_ACTIVATED, OnPlayerActivated)
        EVENT_MANAGER:RegisterForEvent("GamepadChatSystem", EVENT_CHAT_MESSAGE_CHANNEL, OnChatMessageChannel)

        local FADE_IN_OVER_TRACKER = true
        CALLBACK_MANAGER:RegisterCallback("QuestTrackerUpdatedOnScreen", function() self:TryFadeOut() end)
        CALLBACK_MANAGER:RegisterCallback("QuestTrackerUpdatedOnScreen", function() self:TryFadeIn() end)
        CALLBACK_MANAGER:RegisterCallback("QuestTrackerFadedOutOnScreen", function() self:TryFadeIn(FADE_IN_OVER_TRACKER) end)
    end
end

function ZO_GamepadChatSystem:StartTextEntry(text, channel, target)
	self:Maximize()
    SharedChatSystem.StartTextEntry(self, text, channel, target)
    
    self.textEntry:GetEditControl():TakeFocus()

    if(not self.addedChatCloseKeybinds and SCENE_MANAGER:IsInUIMode() and not SCENE_MANAGER:IsShowing("gamepad_text_chat")) then
        self.m_keybindState = KEYBIND_STRIP:PushKeybindGroupState()
        KEYBIND_STRIP:RemoveDefaultExit(self.m_keybindState)
        KEYBIND_STRIP:AddKeybindButtonGroup(self.closeDescriptor, self.m_keybindState)
        DIRECTIONAL_INPUT:Activate(self.UIModeInputEater, self.control)
        self.addedChatCloseKeybinds = true
    end
end

function ZO_GamepadChatSystem:StartTimerIfNecessary()
	-- if we're not in the gamepad screen, just start the timer, otherwise stop it so we don't fade out mid-scene
	if not SCENE_MANAGER:IsShowing("gamepad_text_chat") then
		self:StartVisibilityTimer()
	else
		g_expirationTime = nil
	end
end

function ZO_GamepadChatSystem:RemoveChatCloseKeybind()
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.closeDescriptor, self.m_keybindState)
    KEYBIND_STRIP:RestoreDefaultExit(self.m_keybindState)
    KEYBIND_STRIP:PopKeybindGroupState()
    self.addedChatCloseKeybinds = false
    DIRECTIONAL_INPUT:Deactivate(self.UIModeInputEater)
end

function ZO_GamepadChatSystem:CloseTextEntry(keepText)
    SharedChatSystem.CloseTextEntry(self, keepText)
    if self.addedChatCloseKeybinds then
        self:RemoveChatCloseKeybind()
    end
end

-- handle this so we don't minimize the window due to the fadeout timer while the user is typing
function ZO_GamepadChatSystem:OnTextEntryChanged(newText)
	SharedChatSystem.OnTextEntryChanged(self, newText)

	self:StartTimerIfNecessary()
end

function ZO_GamepadChatSystem:ResetContainerPositionAndSize(container)
	container:LoadSettings()
end

function ZO_GamepadChatSystem:Maximize()
    if self.loaded and (self.isMinimized or not self.hasFocus or self.isPinnedAndFaded) then
        if self.newChatFadeAnim and self.newChatFadeAnim:IsPlaying() then
            self.newChatFadeAnim:Stop()
            self.chatBubble:SetAlpha(1)
        end

	    self:StartTimerIfNecessary()

        if self.anchoredOverTextEntry then
            self.primaryContainer:AnchorAboveTextEntry()
        end

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
        self.primaryContainer:AnchorOverTextEntry()

        if(self.addedChatCloseKeybinds) then
            self:RemoveChatCloseKeybind()
        end

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

function ZO_GamepadChatSystem:TryFadeOut()
    if not self.isMinimized and FOCUSED_QUEST_TRACKER:IsOverlappingTextChat() then
        self:HideWhenDeactivated(nil, FADE_TEXT, TEXT_OPACITY_WHEN_CLIPPING_QUEST_TRACKER)
        self:FadeOutWindowContainers(TEXT_OPACITY_WHEN_CLIPPING_QUEST_TRACKER)
        self.hasFocus = false
    end
end

function ZO_GamepadChatSystem:TryFadeIn(forceFadeIn)
    if not self.isMinimized and not self.hasFocus and (forceFadeIn or not FOCUSED_QUEST_TRACKER:IsOverlappingTextChat()) then
        self:Maximize()
    end
end

function ZO_GamepadChatSystem:StartVisibilityTimer()
    local secondsToExpire = ZO_GAMEPAD_CHAT_SYSTEM_SECONDS_VISIBLE_UNPINNED

    if self:IsWindowPinned() then
        secondsToExpire = ZO_GAMEPAD_CHAT_SYSTEM_SECONDS_VISIBLE_PINNED
    end

	g_expirationTime = GetFrameTimeSeconds() + secondsToExpire
end

function ZO_GamepadChatSystem:IsPinnable()
    return true
end

function ZO_GamepadChatSystem:OnChatEvent(...)
    SharedChatSystem.OnChatEvent(self, ...)

    if not self.isMinimized then
        self:Maximize()
    end
end

function ZO_GamepadChatSystem:GetFont()
    return ZoFontGamepadEditChat
end

--[[ XML Functions ]]--
function ZO_GamepadTextChat_OnInitialize(control)
    CHAT_SYSTEM = ZO_GamepadChatSystem:New(control)
end