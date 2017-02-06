local FRAGMENT_CATEGORY_TITLE = "Title"

-----------------------------
--Fullscreen Effect Fragment
-----------------------------

ZO_FullscreenEffectFragment = ZO_SceneFragment:Subclass()

function ZO_FullscreenEffectFragment:New(effectType, ...)
    local fragment = ZO_SceneFragment.New(self)
    fragment:SetCategory(FRAGMENT_CATEGORY_FULLSCREEN_EFFECT)
    fragment.effectType = effectType
    fragment.params = {...}
    fragment:SetHideOnSceneHidden(true)
    return fragment
end

function ZO_FullscreenEffectFragment:Show()
    SetFullscreenEffect(self.effectType, unpack(self.params))
    self:OnShown()
end

function ZO_FullscreenEffectFragment:Hide()
    SetFullscreenEffect(FULLSCREEN_EFFECT_NONE)
    self:OnHidden()
end

UNIFORM_BLUR_FRAGMENT = ZO_FullscreenEffectFragment:New(FULLSCREEN_EFFECT_UNIFORM_BLUR)

------------------------
--Frame Player Fragment
------------------------

ZO_FramePlayerFragment = ZO_SceneFragment:Subclass()

function ZO_FramePlayerFragment:New()
    local fragment = ZO_SceneFragment.New(self)
    SetFrameLocalPlayerInGameCamera(false)
    return fragment
end

function ZO_FramePlayerFragment:Show()
    SetFrameLocalPlayerInGameCamera(true)
    self:OnShown()
end

function ZO_FramePlayerFragment:Hide()
    SetFrameLocalPlayerInGameCamera(false)
    self:OnHidden()
end

FRAME_PLAYER_FRAGMENT = ZO_FramePlayerFragment:New()

-----------------------------------------
--Frame Player On Scene Hidden Fragment
-----------------------------------------

ZO_FramePlayerOnSceneHiddenFragment = ZO_FramePlayerFragment:Subclass()

function ZO_FramePlayerOnSceneHiddenFragment:New()
    local fragment = ZO_FramePlayerFragment.New(self)
    fragment:SetHideOnSceneHidden(true)
    return fragment
end

function ZO_FramePlayerOnSceneHiddenFragment:Show()
    ZO_FramePlayerFragment.Show(self)
end

function ZO_FramePlayerOnSceneHiddenFragment:Hide()
    ZO_FramePlayerFragment.Hide(self)
end

FRAME_PLAYER_ON_SCENE_HIDDEN_FRAGMENT = ZO_FramePlayerOnSceneHiddenFragment:New()

------------------------
--Normalized Point Fragment
------------------------

ZO_NormalizedPointFragment = ZO_SceneFragment:Subclass()
ZO_NormalizedPointFragment.id = 0

function ZO_NormalizedPointFragment:New(normalizedPointCallback, executeCallback)
    local fragment = ZO_SceneFragment.New(self)
    fragment.id = self.id
    self.id = self.id + 1

    function fragment.UpdateTarget()
        local x, y = normalizedPointCallback()
        local normalizedX, normalizedY = NormalizeUICanvasPoint(x, y)
        executeCallback(normalizedX, normalizedY)
    end

    return fragment
end

function ZO_NormalizedPointFragment:Show()
    self.UpdateTarget()
    EVENT_MANAGER:RegisterForEvent("ZO_FramePlayerTargetFragment"..self.id, EVENT_SCREEN_RESIZED, self.UpdateTarget)
    self:OnShown()
end

function ZO_NormalizedPointFragment:Hide()
    EVENT_MANAGER:UnregisterForEvent("ZO_FramePlayerTargetFragment"..self.id, EVENT_SCREEN_RESIZED)
    self:OnHidden()
end

------------------------
--Character Framing Blur
------------------------

local ZO_CharacterFramingBlur = ZO_NormalizedPointFragment:Subclass()

local function OnNormalizedPointChanged(normalizedX, normalizedY)
    SetFullscreenEffect(FULLSCREEN_EFFECT_CHARACTER_FRAMING_BLUR, normalizedX, normalizedY)
end

function ZO_CharacterFramingBlur:New(normalizedPointCallback)
    local fragment = ZO_NormalizedPointFragment.New(self, normalizedPointCallback, OnNormalizedPointChanged)
    fragment:SetHideOnSceneHidden(true)
    return fragment
end

function ZO_CharacterFramingBlur:Hide()
    SetFullscreenEffect(FULLSCREEN_EFFECT_NONE)
    ZO_NormalizedPointFragment.Hide(self)
end

do
    local function CalculateStandardRightPanelFramingTarget()
        local x = zo_lerp(0, ZO_SharedRightBackground:GetLeft(), .5)
        local y = zo_lerp(ZO_TopBarBackground:GetBottom(), ZO_KeybindStripMungeBackgroundTexture:GetTop(), .55)
        return x, y
    end
    FRAME_TARGET_STANDARD_RIGHT_PANEL_FRAGMENT = ZO_NormalizedPointFragment:New(CalculateStandardRightPanelFramingTarget, SetFrameLocalPlayerTarget)
    FRAME_TARGET_BLUR_STANDARD_RIGHT_PANEL_FRAGMENT = ZO_CharacterFramingBlur:New(CalculateStandardRightPanelFramingTarget)

    local function CalculateFurnitureBrowserFramingTarget()
        local x = zo_lerp(0, ZO_SharedRightBackground:GetLeft(), .45)
        local screenWidth, screenHeight = GuiRoot:GetDimensions()
        local y = zo_lerp(0, screenHeight, .5)
        return x, y
    end
    FRAME_TARGET_FURNITURE_BROWSER_FRAGMENT = ZO_NormalizedPointFragment:New(CalculateFurnitureBrowserFramingTarget, SetFrameLocalPlayerTarget)

    local function CalculateCraftingFramingTarget()
        local x = zo_lerp(ZO_SharedThinLeftPanelBackground:GetRight(), ZO_SharedRightPanelBackground:GetLeft(), .5)
        local y = zo_lerp(0, ZO_KeybindStripMungeBackgroundTexture:GetTop(), .45)
        return x, y
    end
    FRAME_TARGET_CRAFTING_FRAGMENT = ZO_NormalizedPointFragment:New(CalculateCraftingFramingTarget, SetFrameLocalPlayerTarget)
    
    local function CalculateCraftingGamepadFramingTarget()
        local x = zo_lerp(ZO_SharedGamepadNavQuadrant_1_Background:GetRight(), GuiRoot:GetRight(), .5)
        local y = zo_lerp(0, ZO_KeybindStripGamepadBackgroundTexture:GetTop(), .45)
        return x, y
    end
    FRAME_TARGET_CRAFTING_GAMEPAD_FRAGMENT = ZO_NormalizedPointFragment:New(CalculateCraftingGamepadFramingTarget, SetFrameLocalPlayerTarget)

    local function CalculateCenteredFramingTarget()
        local screenWidth, screenHeight = GuiRoot:GetDimensions()
        return screenWidth / 2, .55 * screenHeight
    end
    FRAME_TARGET_CENTERED_FRAGMENT = ZO_NormalizedPointFragment:New(CalculateCenteredFramingTarget, SetFrameLocalPlayerTarget)
    FRAME_TARGET_BLUR_CENTERED_FRAGMENT = ZO_CharacterFramingBlur:New(CalculateCenteredFramingTarget)

    local function CalculateGamepadFramingTarget()
        local screenWidth, screenHeight = GuiRoot:GetDimensions()
        return .65 * screenWidth, .55 * screenHeight
    end
    FRAME_TARGET_GAMEPAD_FRAGMENT = ZO_NormalizedPointFragment:New(CalculateGamepadFramingTarget, SetFrameLocalPlayerTarget)
    FRAME_TARGET_BLUR_GAMEPAD_FRAGMENT = ZO_CharacterFramingBlur:New(CalculateGamepadFramingTarget)

    local function CalculateGamepadLeftFramingTarget()
        local screenWidth, screenHeight = GuiRoot:GetDimensions()
        return .35 * screenWidth, .55 * screenHeight
    end
    FRAME_TARGET_LEFT_GAMEPAD_FRAGMENT = ZO_NormalizedPointFragment:New(CalculateGamepadLeftFramingTarget, SetFrameLocalPlayerTarget)
    FRAME_TARGET_LEFT_BLUR_GAMEPAD_FRAGMENT = ZO_CharacterFramingBlur:New(CalculateGamepadLeftFramingTarget)

    local function CalculateGamepadRightFramingTarget()
        local screenWidth, screenHeight = GuiRoot:GetDimensions()
        return .9 * screenWidth, .55 * screenHeight
    end
    FRAME_TARGET_GAMEPAD_RIGHT_FRAGMENT = ZO_NormalizedPointFragment:New(CalculateGamepadRightFramingTarget, SetFrameLocalPlayerTarget)
    FRAME_TARGET_BLUR_GAMEPAD_RIGHT_FRAGMENT = ZO_CharacterFramingBlur:New(CalculateGamepadRightFramingTarget)

    local function CalculateOffscreenFramingTarget()
        local screenWidth, screenHeight = GuiRoot:GetDimensions()
        return 2 * screenWidth, 0
    end
    FRAME_TARGET_BLUR_FULLSCREEN_FRAGMENT = ZO_CharacterFramingBlur:New(CalculateOffscreenFramingTarget)
end

------------------------
--Frame Emote Fragment
------------------------

ZO_FrameEmoteFragment = ZO_SceneFragment:Subclass()

function ZO_FrameEmoteFragment:New(framingType)
    local fragment = ZO_SceneFragment.New(self)
    fragment.framingType = framingType
    return fragment
end

function ZO_FrameEmoteFragment:Show()
    SetFramingScreenType(self.framingType)
    self:OnShown()
end

function ZO_FrameEmoteFragment:Hide()
    SetFramingScreenType(FRAMING_SCREEN_DEFAULT)
    self:OnHidden()
end

FRAME_EMOTE_FRAGMENT_INVENTORY = ZO_FrameEmoteFragment:New(FRAMING_SCREEN_INVENTORY)
FRAME_EMOTE_FRAGMENT_SKILLS = ZO_FrameEmoteFragment:New(FRAMING_SCREEN_SKILLS)
FRAME_EMOTE_FRAGMENT_JOURNAL = ZO_FrameEmoteFragment:New(FRAMING_SCREEN_JOURNAL)
FRAME_EMOTE_FRAGMENT_MAP = ZO_FrameEmoteFragment:New(FRAMING_SCREEN_MAP)
FRAME_EMOTE_FRAGMENT_SOCIAL = ZO_FrameEmoteFragment:New(FRAMING_SCREEN_SOCIAL)
FRAME_EMOTE_FRAGMENT_AVA = ZO_FrameEmoteFragment:New(FRAMING_SCREEN_AVA)
FRAME_EMOTE_FRAGMENT_SYSTEM = ZO_FrameEmoteFragment:New(FRAMING_SCREEN_SYSTEM)
FRAME_EMOTE_FRAGMENT_LOOT = ZO_FrameEmoteFragment:New(FRAMING_SCREEN_LOOT)
FRAME_EMOTE_FRAGMENT_CHAMPION = ZO_FrameEmoteFragment:New(FRAMING_SCREEN_CHAMPION)
FRAME_EMOTE_FRAGMENT_CROWN_STORE = ZO_FrameEmoteFragment:New(FRAMING_SCREEN_CROWN_STORE)
FRAME_EMOTE_FRAGMENT_CROWN_CRATES = ZO_FrameEmoteFragment:New(FRAMING_SCREEN_CROWN_CRATES)

-------------------------------
--Skills Action Bar Fragment (re-anchors it)
-------------------------------

ZO_SkillsActionBarFragment = ZO_FadeSceneFragment:Subclass()

function ZO_SkillsActionBarFragment:New()
    local fragment = ZO_FadeSceneFragment.New(self, ZO_ActionBar1)
    fragment:RegisterCallback("StateChange", function(...) fragment:OnStateChange(...) end)
    return fragment
end

function ZO_SkillsActionBarFragment:Show()
    ZO_ActionBar1:ClearAnchors()
    ZO_ActionBar1:SetAnchor(BOTTOM, ZO_Skills, BOTTOM, -40, 40)

    ActionButton9:SetHidden(true)
    ZO_ActionBar1KeybindBG:SetHidden(true)

    ZO_FadeSceneFragment.Show(self)
end

function ZO_SkillsActionBarFragment:Hide()
    ZO_FadeSceneFragment.Hide(self)
end

function ZO_SkillsActionBarFragment:OnStateChange(oldState, newState)
    if newState == SCENE_FRAGMENT_HIDDEN then
        ZO_ActionBar1:ClearAnchors()
        ZO_ActionBar_GetAnchor():Set(ZO_ActionBar1)
        ActionButton9:SetHidden(false)
        ZO_ActionBar1KeybindBG:SetHidden(IsInGamepadPreferredMode())
    end
end

-------------------------------
--Set Title Fragment (sets the title on the ZO_SharedTitle control when it becomes active)
-------------------------------

ZO_SetTitleFragment = ZO_SceneFragment:Subclass()

function ZO_SetTitleFragment:New(titleStringId)
    local fragment = ZO_SceneFragment.New(self)
    fragment.title = GetString(titleStringId)
    return fragment
end

function ZO_SetTitleFragment:Show()
    local currentScene = SCENE_MANAGER:GetCurrentScene()
    local titleFragment = currentScene:GetFragmentWithCategory(FRAGMENT_CATEGORY_TITLE)
    local titleControl = titleFragment:GetControl()
    GetControl(titleControl, "Label"):SetText(self.title)
    self:OnShown()
end

function ZO_SetTitleFragment:Hide()
    self:OnHidden()
end

----------------------------------------
--Window Sound Fragment
----------------------------------------

ZO_WindowSoundFragment = ZO_SceneFragment:Subclass()

function ZO_WindowSoundFragment:New(showSoundId, hideSoundId)
    local fragment = ZO_SceneFragment.New(self)
    fragment.showSoundId = showSoundId
    fragment.hideSoundId = hideSoundId
    return fragment
end

function ZO_WindowSoundFragment:Show()
    PlaySound(self.showSoundId)
    self:OnShown()
end

function ZO_WindowSoundFragment:Hide()
    --only play the close sound if we're exiting the window UI
    if(SCENE_MANAGER:IsShowingBaseSceneNext()) then
        PlaySound(self.hideSoundId)
    end
    self:OnHidden()
end

----------------------------------------
--Tutorial Trigger Fragment
----------------------------------------

ZO_TutorialTriggerFragment = ZO_SceneFragment:Subclass()

function ZO_TutorialTriggerFragment:New(onShowTutorialTriggerType)
    local fragment = ZO_SceneFragment.New(self)
    assert(onShowTutorialTriggerType)
    fragment.onShowTutorialTriggerType = onShowTutorialTriggerType
    return fragment
end

function ZO_TutorialTriggerFragment:Show()
    TriggerTutorial(self.onShowTutorialTriggerType)
    self:OnShown()
end

function ZO_TutorialTriggerFragment:Hide()
    self:OnHidden()
end

----------------------------------------
--Clear Cursor Fragment
----------------------------------------

local ZO_ClearCursorFragment = ZO_SceneFragment:Subclass()

function ZO_ClearCursorFragment:New()
    local fragment = ZO_SceneFragment.New(self)
    fragment:SetForceRefresh(true)
    return fragment
end

function ZO_ClearCursorFragment:Show()
    self:OnShown()
end

function ZO_ClearCursorFragment:Hide()
    ClearCursor()
    self:OnHidden()
end

------------------------------------
--UI Combat Overlay Fragment
------------------------------------

local ZO_UICombatOverlayFragment = ZO_SceneFragment:Subclass()

function ZO_UICombatOverlayFragment:New()
    local fragment = ZO_SceneFragment.New(self)
    return fragment
end

function ZO_UICombatOverlayFragment:Show()
    ZO_UICombat:SetHidden(false)
    self:OnShown()
end

function ZO_UICombatOverlayFragment:Hide()
    ZO_UICombat:SetHidden(true)
    self:OnHidden()
end

----------------------------------------
--Character Window Fragment
----------------------------------------
ZO_CharacterWindowFragment = ZO_FadeSceneFragment:Subclass()

function ZO_CharacterWindowFragment:New(control, readOnly)
    local fragment = ZO_FadeSceneFragment.New(self, control)
    fragment.readOnly = readOnly
    fragment:RegisterCallback("StateChange", function(...) fragment:OnStateChange(...) end)
    return fragment
end

function ZO_CharacterWindowFragment:OnStateChange(oldState, newState)
    if newState == SCENE_FRAGMENT_SHOWING then
        ZO_Character_SetIsShowingReadOnlyFragment(self.readOnly)
    end
end

----------------------------------------
--End In World Interactions Fragment
----------------------------------------

local ZO_EndInWorldInteractionsFragment = ZO_SceneFragment:Subclass()

function ZO_EndInWorldInteractionsFragment:New(actionLayerName)
    local fragment = ZO_SceneFragment.New(self)
    return fragment
end

function ZO_EndInWorldInteractionsFragment:Show()
    EndInteraction(INTERACTION_FISH)
    EndInteraction(INTERACTION_HARVEST)
    EndInteraction(INTERACTION_SIEGE)
    EndPendingInteraction()
    self:OnShown()
end

function ZO_EndInWorldInteractionsFragment:Hide()
    self:OnHidden()
end

END_IN_WORLD_INTERACTIONS_FRAGMENT = ZO_EndInWorldInteractionsFragment:New()

----------------------------------------
--Minimize Chat Fragment
----------------------------------------

local ZO_MinimizeChatFragment = ZO_SceneFragment:Subclass()

function ZO_MinimizeChatFragment:New(actionLayerName)
    return ZO_SceneFragment.New(self)
end

function ZO_MinimizeChatFragment:Show()
    self.wasChatMaximized = not CHAT_SYSTEM:IsMinimized()
    if self.wasChatMaximized then
        CHAT_SYSTEM:Minimize()
    end
    self:OnShown()
end

function ZO_MinimizeChatFragment:Hide()
    if (self.wasChatMaximized or (CHAT_SYSTEM:IsPinnable() and CHAT_SYSTEM:IsWindowPinned())) and CHAT_SYSTEM:IsMinimized() then
        CHAT_SYSTEM:Maximize()
    end

    self.wasChatMaximized = false
    self:OnHidden()
end

MINIMIZE_CHAT_FRAGMENT = ZO_MinimizeChatFragment:New()

----------------------------------------
--Stop Movement Fragment
----------------------------------------

local ZO_StopMovementFragment = ZO_SceneFragment:Subclass()

function ZO_StopMovementFragment:New()
    return ZO_SceneFragment.New(self)
end

function ZO_StopMovementFragment:Show()
    StopAllMovement()
    self:OnShown()
end

function ZO_StopMovementFragment:Hide()
    self:OnHidden()
end

STOP_MOVEMENT_FRAGMENT = ZO_StopMovementFragment:New()

----------------------------------------
--Hide Mouse While Not Moving Fragment
----------------------------------------

local ZO_HideMouseFragment = ZO_SceneFragment:Subclass()

local ONLY_CONSIDER_MOUSE_VISIBILITY_WHILE_MOVING = true

function ZO_HideMouseFragment:New()
    return ZO_SceneFragment.New(self)
end

function ZO_HideMouseFragment:Show()
    HideMouse(ONLY_CONSIDER_MOUSE_VISIBILITY_WHILE_MOVING)
    self:OnShown()
end

function ZO_HideMouseFragment:Hide()
    ShowMouse(ONLY_CONSIDER_MOUSE_VISIBILITY_WHILE_MOVING)
    self:OnHidden()
end

HIDE_MOUSE_FRAGMENT = ZO_HideMouseFragment:New()

----------------------------------------
-- Keybind Strip
----------------------------------------

local ZO_KeybindStripFragment = ZO_FadeSceneFragment:Subclass()

function ZO_KeybindStripFragment:New(...)
    return ZO_FadeSceneFragment.New(self, ...)
end

function ZO_KeybindStripFragment:Show()
    KEYBIND_STRIP:SetStyle(KEYBIND_STRIP_STANDARD_STYLE)
    ZO_FadeSceneFragment.Show(self)
end

function ZO_KeybindStripFragment:Hide()
    ZO_FadeSceneFragment.Hide(self)
end

KEYBIND_STRIP_FADE_FRAGMENT = ZO_KeybindStripFragment:New(ZO_KeybindStripControl)
KEYBIND_STRIP_FADE_FRAGMENT:AddInstantScene(CROWN_CRATE_KEYBOARD_SCENE)

----------------------------------------
-- Champion Keybind Strip
----------------------------------------

local ZO_ChampionKeybindStripFragment = ZO_FadeSceneFragment:Subclass()

function ZO_ChampionKeybindStripFragment:New(...)
    return ZO_FadeSceneFragment.New(self, ...)
end

function ZO_ChampionKeybindStripFragment:Show()
    KEYBIND_STRIP:SetStyle(KEYBIND_STRIP_CHAMPION_KEYBOARD_STYLE)
    ZO_FadeSceneFragment.Show(self)
end

function ZO_ChampionKeybindStripFragment:Hide()
    ZO_FadeSceneFragment.Hide(self)
end

CHAMPION_KEYBIND_STRIP_FADE_FRAGMENT = ZO_ChampionKeybindStripFragment:New(ZO_KeybindStripControl)

----------------------------------------
-- Gamepad Keybind Strip
----------------------------------------

local ZO_GamepadKeybindStripFragment = ZO_TranslateFromBottomSceneFragment:Subclass()

function ZO_GamepadKeybindStripFragment:New(...)
    return ZO_TranslateFromBottomSceneFragment.New(self, ...)
end

function ZO_GamepadKeybindStripFragment:Show()
    KEYBIND_STRIP:SetStyle(KEYBIND_STRIP_GAMEPAD_STYLE)
    ZO_TranslateFromBottomSceneFragment.Show(self)
end

function ZO_GamepadKeybindStripFragment:Hide()
    ZO_TranslateFromBottomSceneFragment.Hide(self)
end

KEYBIND_STRIP_GAMEPAD_FRAGMENT = ZO_GamepadKeybindStripFragment:New(ZO_KeybindStripControl)
KEYBIND_STRIP_GAMEPAD_FRAGMENT:AddInstantScene(CROWN_CRATE_GAMEPAD_SCENE)

----------------------------------------
-- Item Preview Fragment
----------------------------------------

local ZO_ItemPreviewFragment = ZO_SceneFragment:Subclass()

function ZO_ItemPreviewFragment:New()
    return ZO_SceneFragment.New(self)
end

function ZO_ItemPreviewFragment:Show()
    BeginPreviewMode()
    self:OnShown()
end

function ZO_ItemPreviewFragment:Hide()
    EndPreviewMode()
    self:OnHidden()
end

ITEM_PREVIEW_FRAGMENT = ZO_ItemPreviewFragment:New()

----------------------------------------
-- Market Keybind Strip Background
----------------------------------------

local ZO_MarketKeybindStripBackgroundFragment = ZO_FadeSceneFragment:Subclass()

function ZO_MarketKeybindStripBackgroundFragment:New(...)
    return ZO_FadeSceneFragment.New(self, ...)
end

function ZO_MarketKeybindStripBackgroundFragment:Show()
    KEYBIND_STRIP:SetBackgroundStyle(KEYBIND_STRIP_STANDARD_STYLE)
    ZO_FadeSceneFragment.Show(self)
end

function ZO_MarketKeybindStripBackgroundFragment:Hide()
    ZO_FadeSceneFragment.Hide(self)
end

MARKET_KEYBIND_STRIP_MUNGE_BACKDROP_FRAGMENT = ZO_MarketKeybindStripBackgroundFragment:New(ZO_KeybindStripMungeBackground)

----------------------------------------
-- Show Market Fragment
----------------------------------------

local ShowMarketFragment = ZO_SceneFragment:Subclass()

function ShowMarketFragment:New(...)
    return ZO_SceneFragment.New(self, ...)
end

function ShowMarketFragment:Show()
    self:OnShown()
    -- This call needs to be after OnShown so we are in the correct state to show
    -- the new scene
    SYSTEMS:GetObject("mainMenu"):ShowCategory(MENU_CATEGORY_MARKET)
end

function ShowMarketFragment:Hide()
    self:OnHidden()
end

SHOW_MARKET_FRAGMENT = ShowMarketFragment:New()

-------------------------------------------------
-- Suppress Collectible Notifications Fragment
-------------------------------------------------

local SuppressCollectibleNotificationsFragment = ZO_SceneFragment:Subclass()

function SuppressCollectibleNotificationsFragment:New(...)
    return ZO_SceneFragment.New(self, ...)
end

function SuppressCollectibleNotificationsFragment:Show()
    if NOTIFICATIONS then
        NOTIFICATIONS:SuppressNotificationsByEvent(EVENT_COLLECTIBLE_NOTIFICATION_NEW)
    end
    if GAMEPAD_NOTIFICATIONS then
        GAMEPAD_NOTIFICATIONS:SuppressNotificationsByEvent(EVENT_COLLECTIBLE_NOTIFICATION_NEW)
    end
    self:OnShown()
end

function SuppressCollectibleNotificationsFragment:Hide()
    if NOTIFICATIONS then
        NOTIFICATIONS:ResumeNotificationsByEvent(EVENT_COLLECTIBLE_NOTIFICATION_NEW)
    end
    if GAMEPAD_NOTIFICATIONS then
        GAMEPAD_NOTIFICATIONS:ResumeNotificationsByEvent(EVENT_COLLECTIBLE_NOTIFICATION_NEW)
    end
    self:OnHidden()
end

SUPPRESS_COLLECTIBLE_NOTIFICATIONS_FRAGMENT = SuppressCollectibleNotificationsFragment:New()

-------------------------------------------------
-- Suppress Collectible Announcements Fragment
-------------------------------------------------

local SuppressCollectibleAnnouncementsFragment = ZO_SceneFragment:Subclass()

function SuppressCollectibleAnnouncementsFragment:New(...)
    return ZO_SceneFragment.New(self, ...)
end

function SuppressCollectibleAnnouncementsFragment:Show()
    CENTER_SCREEN_ANNOUNCE:SupressAnnouncementByEvent(EVENT_COLLECTIBLE_UPDATED)
    self:OnShown()
end

function SuppressCollectibleAnnouncementsFragment:Hide()
    CENTER_SCREEN_ANNOUNCE:ResumeAnnouncementByEvent(EVENT_COLLECTIBLE_UPDATED)
    self:OnHidden()
end

SUPPRESS_COLLECTIBLE_ANNOUNCEMENTS_FRAGMENT = SuppressCollectibleAnnouncementsFragment:New()

--------------------------------------
--General Fragment Declarations
--------------------------------------

INVENTORY_FRAGMENT:AddDependencies(
    BACKPACK_DEFAULT_LAYOUT_FRAGMENT, 
    BACKPACK_BANK_LAYOUT_FRAGMENT,
    BACKPACK_GUILD_BANK_LAYOUT_FRAGMENT,
    BACKPACK_TRADING_HOUSE_LAYOUT_FRAGMENT, 
    BACKPACK_MAIL_LAYOUT_FRAGMENT, 
    BACKPACK_PLAYER_TRADE_LAYOUT_FRAGMENT, 
    BACKPACK_MENU_BAR_LAYOUT_FRAGMENT, 
    BACKPACK_STORE_LAYOUT_FRAGMENT,
    BACKPACK_FENCE_LAYOUT_FRAGMENT,
    BACKPACK_LAUNDER_LAYOUT_FRAGMENT
)

SKILLS_ACTION_BAR_FRAGMENT = ZO_SkillsActionBarFragment:New()

CLEAR_CURSOR_FRAGMENT = ZO_ClearCursorFragment:New()
UI_COMBAT_OVERLAY_FRAGMENT = ZO_UICombatOverlayFragment:New()

KEYBIND_STRIP_MUNGE_BACKDROP_FRAGMENT = ZO_FadeSceneFragment:New(ZO_KeybindStripMungeBackground)
KEYBIND_STRIP_MUNGE_BACKDROP_FRAGMENT:AddInstantScene(CROWN_CRATE_KEYBOARD_SCENE)

KEYBIND_STRIP_GAMEPAD_BACKDROP_FRAGMENT = ZO_FadeSceneFragment:New(ZO_KeybindStripGamepadBackground)
KEYBIND_STRIP_GAMEPAD_BACKDROP_FRAGMENT:AddInstantScene(CROWN_CRATE_GAMEPAD_SCENE)

RIGHT_PANEL_BG_FRAGMENT = ZO_FadeSceneFragment:New(ZO_SharedRightPanelBackground)
RIGHT_BG_FRAGMENT = ZO_FadeSceneFragment:New(ZO_SharedRightBackground)
STATS_BG_FRAGMENT = ZO_FadeSceneFragment:New(ZO_SharedStatsBackground)
WIDE_RIGHT_BG_FRAGMENT = ZO_FadeSceneFragment:New(ZO_SharedWideRightBackground)
LEFT_PANEL_BG_FRAGMENT = ZO_FadeSceneFragment:New(ZO_SharedLeftPanelBackground)
THIN_LEFT_PANEL_BG_FRAGMENT = ZO_FadeSceneFragment:New(ZO_SharedThinLeftPanelBackground)
WIDE_LEFT_PANEL_BG_FRAGMENT = ZO_FadeSceneFragment:New(ZO_SharedWideLeftPanelBackground)
MEDIUM_LEFT_PANEL_BG_FRAGMENT = ZO_FadeSceneFragment:New(ZO_SharedMediumLeftPanelBackground)
TREE_UNDERLAY_FRAGMENT = ZO_FadeSceneFragment:New(ZO_SharedTreeUnderlay)
TOP_BAR_FRAGMENT = ZO_FadeSceneFragment:New(ZO_TopBar)

TITLE_FRAGMENT = ZO_FadeSceneFragment:New(ZO_SharedTitle)
TITLE_FRAGMENT:SetCategory(FRAGMENT_CATEGORY_TITLE)

MAIL_INBOX_FRAGMENT = ZO_FadeSceneFragment:New(ZO_MailInbox)
MAIL_SEND_FRAGMENT = ZO_FadeSceneFragment:New(ZO_MailSend)
MAIL_TITLE_FRAGMENT = ZO_SetTitleFragment:New(SI_WINDOW_TITLE_MAIL)

GAMEPAD_TRADE_FRAGMENT = ZO_FadeSceneFragment:New(ZO_Trade_Gamepad)
LOCKPICK_FRAGMENT = ZO_FadeSceneFragment:New(ZO_LockpickPanel)
SKILLS_FRAGMENT = ZO_FadeSceneFragment:New(ZO_Skills)
CHARACTER_WINDOW_STATS_FRAGMENT = ZO_FadeSceneFragment:New(ZO_CharacterWindowStats)
CHARACTER_WINDOW_FRAGMENT = ZO_CharacterWindowFragment:New(ZO_Character, false)
READ_ONLY_CHARACTER_WINDOW_FRAGMENT = ZO_CharacterWindowFragment:New(ZO_Character, true)

GAMEPAD_GENERIC_FOOTER_FRAGMENT = ZO_FadeSceneFragment:New(ZO_GenericFooter_Gamepad)

PLAYER_PROGRESS_BAR_FRAGMENT = ZO_PlayerProgressBarFragment:New()
PLAYER_PROGRESS_BAR_CURRENT_FRAGMENT = ZO_PlayerProgressBarCurrentFragment:New()
PLAYER_PROGRESS_BAR_GAMEPAD_HIDE_NAME_LOCATION_FRAGMENT = ZO_GamepadPlayerProgressBarHideNameLocationFragment:New()
PLAYER_PROGRESS_BAR_GAMEPAD_HIDE_NAME_LOCATION_FRAGMENT:SetHideOnSceneHidden(true)
PLAYER_PROGRESS_BAR_GAMEPAD_NAME_LOCATION_ANCHOR_FRAGMENT = ZO_GamepadPlayerProgressBarNameLocationAnchor_Initialize(GAMEPAD_PLAYER_PROGRESS_BAR_NAME_LOCATION, PLAYER_PROGRESS_BAR)

QUEST_JOURNAL_FRAGMENT = ZO_FadeSceneFragment:New(ZO_QuestJournal)
COLLECTIONS_BOOK_FRAGMENT = ZO_FadeSceneFragment:New(ZO_CollectionsBook)
LEADERBOARDS_FRAGMENT = ZO_FadeSceneFragment:New(ZO_Leaderboards)
LORE_LIBRARY_FRAGMENT = ZO_FadeSceneFragment:New(ZO_LoreLibrary)
LORE_READER_FRAGMENT = ZO_FadeSceneFragment:New(ZO_LoreReader)
TREASURE_MAP_FRAGMENT = ZO_FadeSceneFragment:New(ZO_TreasureMap)
BANK_MENU_FRAGMENT = ZO_FadeSceneFragment:New(ZO_PlayerBankMenu)
GUILD_BANK_MENU_FRAGMENT = ZO_FadeSceneFragment:New(ZO_GuildBankMenu)
INTERACT_FRAGMENT = ZO_FadeSceneFragment:New(ZO_InteractWindow)
GAMEPAD_INTERACT_FRAGMENT = ZO_FadeSceneFragment:New(ZO_InteractWindow_Gamepad)
STORE_MENU_FRAGMENT = ZO_FadeSceneFragment:New(ZO_StoreWindowMenu)
FENCE_MENU_FRAGMENT = ZO_FadeSceneFragment:New(ZO_Fence_Keyboard_WindowMenu)
HELP_TUTORIALS_FRAGMENT = ZO_FadeSceneFragment:New(ZO_Help)

WORLD_MAP_CORNER_FRAGMENT = ZO_FadeSceneFragment:New(ZO_WorldMapCorner)
WORLD_MAP_INFO_BG_FRAGMENT = ZO_FadeSceneFragment:New(ZO_WorldMapInfoFootPrintBackground)
GAMEPAD_WORLD_MAP_HEADER_FRAGMENT = ZO_FadeSceneFragment:New(ZO_WorldMapHeader_Gamepad)

ALLIANCE_WAR_TITLE_FRAGMENT = ZO_SetTitleFragment:New(SI_AVA_MENU_ALLIANCE_WAR_GROUP)
CAMPAIGN_BROWSER_FRAGMENT = ZO_FadeSceneFragment:New(ZO_CampaignBrowser)
CAMPAIGN_AVA_RANK_FRAGMENT = ZO_FadeSceneFragment:New(ZO_CampaignAvARank)
CURRENT_CAMPAIGNS_FRAGMENT = ZO_FadeSceneFragment:New(ZO_CurrentCampaigns)
CAMPAIGN_OVERVIEW_FRAGMENT = ZO_FadeSceneFragment:New(ZO_CampaignOverview)

NOTIFICATIONS_FRAGMENT = ZO_FadeSceneFragment:New(ZO_Notifications)
NOTIFICATIONS_TITLE_FRAGMENT = ZO_SetTitleFragment:New(SI_SOCIAL_MENU_NOTIFICATIONS)

TRADING_HOUSE_FRAGMENT = ZO_FadeSceneFragment:New(ZO_TradingHouse)

PLAYER_TRADE_TITLE_FRAGMENT = ZO_SetTitleFragment:New(SI_WINDOW_TITLE_TRADE)

FRIENDS_LIST_FRAGMENT = ZO_FadeSceneFragment:New(ZO_KeyboardFriendsList)
IGNORE_LIST_FRAGMENT = ZO_FadeSceneFragment:New(ZO_KeyboardIgnoreList)
CONTACTS_TITLE_FRAGMENT = ZO_SetTitleFragment:New(SI_SOCIAL_MENU_CONTACTS)
DISPLAY_NAME_FRAGMENT = ZO_FadeSceneFragment:New(ZO_DisplayName)
FRIENDS_ONLINE_FRAGMENT = ZO_FadeSceneFragment:New(ZO_FriendsOnline)

GROUP_TITLE_FRAGMENT = ZO_SetTitleFragment:New(SI_SOCIAL_MENU_GROUP)
GROUP_CENTER_INFO_FRAGMENT = ZO_FadeSceneFragment:New(ZO_GroupCenterInfo)
SEARCHING_FOR_GROUP_FRAGMENT = ZO_FadeSceneFragment:New(ZO_SearchingForGroup)

GUILD_SELECTOR_FRAGMENT = ZO_FadeSceneFragment:New(ZO_GuildSelector)
GUILD_HOME_FRAGMENT = ZO_FadeSceneFragment:New(ZO_GuildHome)
GUILD_ROSTER_FRAGMENT = ZO_FadeSceneFragment:New(ZO_GuildRoster)
GUILD_RANKS_FRAGMENT = ZO_FadeSceneFragment:New(ZO_GuildRanks)
GUILD_HISTORY_FRAGMENT = ZO_FadeSceneFragment:New(ZO_GuildHistory)
GUILD_CREATE_FRAGMENT = ZO_FadeSceneFragment:New(ZO_GuildCreate)
GUILD_SHARED_INFO_FRAGMENT = ZO_FadeSceneFragment:New(ZO_GuildSharedInfo)
GUILD_HERALDRY_FRAGMENT = ZO_FadeSceneFragment:New(ZO_GuildHeraldry)

CROWN_CRATES_FRAGMENT = ZO_SimpleSceneFragment:New(ZO_CrownCratesTopLevel)

HOUSING_FURNITURE_BROWSER_TITLE_FRAGMENT = ZO_SetTitleFragment:New(SI_HOUSING_BROWSER_TITLE)

--Gamepad fragments
local ALWAYS_ANIMATE = true

ALCHEMY_FRAGMENT = ZO_FadeSceneFragment:New(ZO_AlchemyTopLevel)
ENCHANTING_FRAGMENT = ZO_FadeSceneFragment:New(ZO_EnchantingTopLevel)
SMITHING_FRAGMENT = ZO_FadeSceneFragment:New(ZO_SmithingTopLevel)

SKILLS_TITLE_FRAGMENT = ZO_SetTitleFragment:New(SI_WINDOW_TITLE_SKILLS)
STATS_FRAGMENT = ZO_FadeSceneFragment:New(ZO_StatsPanel)

COLLECTIONS_TITLE_FRAGMENT = ZO_SetTitleFragment:New(SI_COLLECTIONS_MENU_ROOT_TITLE)
JOURNAL_TITLE_FRAGMENT = ZO_SetTitleFragment:New(SI_QUEST_JOURNAL_MENU_JOURNAL)
HELP_TITLE_FRAGMENT = ZO_SetTitleFragment:New(SI_HELP_TITLE)

CHAMPION_PERKS_CONSTELLATIONS_FRAGMENT = ZO_FadeSceneFragment:New(ZO_ChampionPerks)

PLAYER_MENU_FRAGMENT = ZO_SimpleSceneFragment:New(ZO_MainMenu_Gamepad)
PLAYER_MENU_FRAGMENT:SetHideOnSceneHidden(true)

OPTIONS_MENU_INFO_PANEL_FRAGMENT = ZO_FadeSceneFragment:New(ZO_GamepadOptionsTopLevelInfoPanel)

-- Quadrant System Gamepad Grid Backgrounds: DO NOT BLOAT! --
    
GAMEPAD_NAV_QUADRANT_1_BACKGROUND_FRAGMENT = ZO_TranslateFromLeftSceneFragment:New(ZO_SharedGamepadNavQuadrant_1_Background)
ZO_BackgroundFragment:Mixin(GAMEPAD_NAV_QUADRANT_1_BACKGROUND_FRAGMENT)
GAMEPAD_NAV_QUADRANT_1_INSTANT_BACKGROUND_FRAGMENT = ZO_SimpleSceneFragment:New(ZO_SharedGamepadNavQuadrant_1_Background)
GAMEPAD_NAV_QUADRANT_2_BACKGROUND_FRAGMENT = ZO_FadeSceneFragment:New(ZO_SharedGamepadNavQuadrant_2_Background)
ZO_BackgroundFragment:Mixin(GAMEPAD_NAV_QUADRANT_2_BACKGROUND_FRAGMENT)
GAMEPAD_NAV_QUADRANT_1_2_BACKGROUND_FRAGMENT = ZO_TranslateFromLeftSceneFragment:New(ZO_SharedGamepadNavQuadrant_1_2_Background)
ZO_BackgroundFragment:Mixin(GAMEPAD_NAV_QUADRANT_1_2_BACKGROUND_FRAGMENT)
GAMEPAD_NAV_QUADRANT_4_BACKGROUND_FRAGMENT = ZO_FadeSceneFragment:New(ZO_SharedGamepadNavQuadrant_4_Background)
ZO_BackgroundFragment:Mixin(GAMEPAD_NAV_QUADRANT_4_BACKGROUND_FRAGMENT)
GAMEPAD_NAV_QUADRANT_2_3_BACKGROUND_FRAGMENT = ZO_FadeSceneFragment:New(ZO_SharedGamepadNavQuadrant_2_3_Background, ALWAYS_ANIMATE)
ZO_BackgroundFragment:Mixin(GAMEPAD_NAV_QUADRANT_2_3_BACKGROUND_FRAGMENT)
GAMEPAD_NAV_QUADRANT_2_3_4_BACKGROUND_FRAGMENT = ZO_FadeSceneFragment:New(ZO_SharedGamepadNavQuadrant_2_3_4_Background, ALWAYS_ANIMATE)
GAMEPAD_NAV_QUADRANT_1_2_3_BACKGROUND_FRAGMENT = ZO_TranslateFromLeftSceneFragment:New(ZO_SharedGamepadNavQuadrant_1_2_3_Background)

GAMEPAD_NAV_QUADRANT_2_3_4_ITEM_PREVIEW_OPTIONS_FRAGMENT = ZO_ItemPreviewOptionsFragment:New({
    paddingLeft = ZO_GAMEPAD_PANEL_WIDTH + ZO_GAMEPAD_SAFE_ZONE_INSET_X,
    paddingRight = 0,
    dynamicFramingConsumedWidth = 1150,
    dynamicFramingConsumedHeight = 400,
    forcePreparePreview = false,
    previewBufferMS = 300
})

FURNITURE_BROWSER_GAMEPAD_ITEM_PREVIEW_OPTIONS_FRAGMENT = ZO_ItemPreviewOptionsFragment:New({
    paddingLeft = ZO_GAMEPAD_PANEL_WIDTH + ZO_GAMEPAD_SAFE_ZONE_INSET_X,
    paddingRight = ZO_GAMEPAD_PANEL_WIDTH + ZO_GAMEPAD_SAFE_ZONE_INSET_X,
    dynamicFramingConsumedWidth = 1200,
    dynamicFramingConsumedHeight = 400,
    forcePreparePreview = false,
    previewInEmptyWorld = true,
    previewBufferMS = 300
})

-- END Quadrant System Gamepad Grid Backgrounds: DO NOT BLOAT! --

GAMEPAD_PROVISIONER_FRAGMENT = ZO_SimpleSceneFragment:New(ZO_GamepadProvisionerTopLevel)
GAMEPAD_PROVISIONER_FRAGMENT:SetHideOnSceneHidden(true)
GAMEPAD_PROVISIONER_RECIPELIST_FRAGMENT = ZO_CreateQuadrantConveyorFragment(ZO_GamepadProvisionerTopLevelContainerRecipe)
GAMEPAD_PROVISIONER_OPTIONS_FRAGMENT = ZO_CreateQuadrantConveyorFragment(ZO_GamepadProvisionerTopLevelContainerOptions)

GAMEPAD_VENDOR_FRAGMENT = ZO_SimpleSceneFragment:New(ZO_StoreWindow_Gamepad)
GAMEPAD_FENCE_FRAGMENT = ZO_SimpleSceneFragment:New(ZO_FenceWindow_Gamepad)

GAMEPAD_BANKING_FRAGMENT = ZO_SimpleSceneFragment:New(ZO_GamepadBankingTopLevel)

GAMEPAD_GUILD_BANK_FRAGMENT = ZO_SimpleSceneFragment:New(ZO_GuildBankTopLevel_Gamepad)
GAMEPAD_GUILD_BANK_FRAGMENT:SetHideOnSceneHidden(true)

GAMEPAD_GUILD_BANK_WITHDRAW_DEPOSIT_GOLD_FRAGMENT = ZO_SimpleSceneFragment:New(ZO_GuildBankWithdrawDepositGoldTopLevel_Gamepad)
GAMEPAD_GUILD_BANK_ERROR_FRAGMENT = ZO_SimpleSceneFragment:New(ZO_GuildBankErrorTopLevel_Gamepad)

GAMEPAD_GUILD_KIOSK_PURCHASE_FRAGMENT = ZO_CreateQuadrantConveyorFragment(ZO_Gamepad_GuildKiosk_Purchase)
GAMEPAD_GUILD_KIOSK_BID_FRAGMENT = ZO_CreateQuadrantConveyorFragment(ZO_Gamepad_GuildKiosk_Bid)

GAMEPAD_TRADING_HOUSE_FRAGMENT = ZO_CreateQuadrantConveyorFragment(ZO_TradingHouse_Gamepad)
GAMEPAD_TRADING_HOUSE_CREATE_LISTING_FRAGMENT = ZO_CreateQuadrantConveyorFragment(ZO_TradingHouse_CreateListing_Gamepad)

--Sounds
INVENTORY_WINDOW_SOUNDS = ZO_WindowSoundFragment:New(SOUNDS.BACKPACK_WINDOW_OPEN, SOUNDS.BACKPACK_WINDOW_CLOSE)
CHARACTER_WINDOW_SOUNDS = ZO_WindowSoundFragment:New(SOUNDS.CHARACTER_WINDOW_OPEN, SOUNDS.CHARACTER_WINDOW_CLOSE)
SKILLS_WINDOW_SOUNDS = ZO_WindowSoundFragment:New(SOUNDS.SKILLS_WINDOW_OPEN, SOUNDS.SKILLS_WINDOW_CLOSE)
CODEX_WINDOW_SOUNDS = ZO_WindowSoundFragment:New(SOUNDS.CODEX_WINDOW_OPEN, SOUNDS.CODEX_WINDOW_CLOSE)
MAP_WINDOW_SOUNDS = ZO_WindowSoundFragment:New(SOUNDS.MAP_WINDOW_OPEN, SOUNDS.MAP_WINDOW_CLOSE)
CONTACTS_WINDOW_SOUNDS = ZO_WindowSoundFragment:New(SOUNDS.CONTACTS_WINDOW_OPEN, SOUNDS.CONTACTS_WINDOW_CLOSE)
GROUP_WINDOW_SOUNDS = ZO_WindowSoundFragment:New(SOUNDS.GROUP_WINDOW_OPEN, SOUNDS.GROUP_WINDOW_CLOSE)
MAIL_WINDOW_SOUNDS = ZO_WindowSoundFragment:New(SOUNDS.MAIL_WINDOW_OPEN, SOUNDS.MAIL_WINDOW_CLOSE)
GUILD_WINDOW_SOUNDS = ZO_WindowSoundFragment:New(SOUNDS.GUILD_WINDOW_OPEN, SOUNDS.GUILD_WINDOW_CLOSE)
NOTIFICATIONS_WINDOW_SOUNDS = ZO_WindowSoundFragment:New(SOUNDS.NOTIFICATIONS_WINDOW_OPEN, SOUNDS.NOTIFICATIONS_WINDOW_CLOSE)
ALLIANCE_WAR_WINDOW_SOUNDS = ZO_WindowSoundFragment:New(SOUNDS.ALLIANCE_WAR_WINDOW_OPEN, SOUNDS.ALLIANCE_WAR_WINDOW_CLOSE)
HELP_WINDOW_SOUNDS = ZO_WindowSoundFragment:New(SOUNDS.HELP_WINDOW_OPEN, SOUNDS.HELP_WINDOW_CLOSE)
SYSTEM_WINDOW_SOUNDS = ZO_WindowSoundFragment:New(SOUNDS.SYSTEM_WINDOW_OPEN, SOUNDS.SYSTEM_WINDOW_CLOSE)
BANK_WINDOW_SOUNDS = ZO_WindowSoundFragment:New(SOUNDS.BANK_WINDOW_OPEN, SOUNDS.BANK_WINDOW_CLOSE)
STORE_WINDOW_SOUNDS = ZO_WindowSoundFragment:New(SOUNDS.STORE_WINDOW_OPEN, SOUNDS.STORE_WINDOW_CLOSE)
TRADE_WINDOW_SOUNDS = ZO_WindowSoundFragment:New(SOUNDS.TRADE_WINDOW_OPEN, SOUNDS.TRADE_WINDOW_CLOSE)
INTERACT_WINDOW_SOUNDS = ZO_WindowSoundFragment:New(SOUNDS.INTERACT_WINDOW_OPEN, SOUNDS.INTERACT_WINDOW_CLOSE)
TREASURE_MAP_SOUNDS = ZO_WindowSoundFragment:New(SOUNDS.TREASURE_MAP_OPEN, SOUNDS.TREASURE_MAP_CLOSE)
TRADING_HOUSE_WINDOW_SOUNDS = ZO_WindowSoundFragment:New(SOUNDS.TRADING_HOUSE_WINDOW_OPEN, SOUNDS.TRADING_HOUSE_WINDOW_CLOSE)
CHAMPION_WINDOW_SOUNDS = ZO_WindowSoundFragment:New(SOUNDS.CHAMPION_WINDOW_OPENED, SOUNDS.CHAMPION_WINDOW_CLOSED)
MARKET_WINDOW_SOUNDS = ZO_WindowSoundFragment:New(SOUNDS.MARKET_WINDOW_OPENED, SOUNDS.MARKET_WINDOW_CLOSED)
COLLECTIONS_WINDOW_SOUNDS = ZO_WindowSoundFragment:New(SOUNDS.COLLECTIONS_WINDOW_OPEN, SOUNDS.COLLECTIONS_WINDOW_CLOSE)
CROWN_CRATES_GEMIFICATION_WINDOW_SOUNDS = ZO_WindowSoundFragment:New(SOUNDS.DEFAULT_WINDOW_OPEN, SOUNDS.DEFAULT_WINDOW_CLOSE)

--Action Layers
UI_SHORTCUTS_ACTION_LAYER_FRAGMENT = ZO_ActionLayerFragment:New(GetString(SI_KEYBINDINGS_LAYER_USER_INTERFACE_SHORTCUTS))
SIEGE_ACTION_LAYER_FRAGMENT = ZO_ActionLayerFragment:New(GetString(SI_KEYBINDINGS_LAYER_SIEGE))
GUILD_SELECTOR_ACTION_LAYER_FRAGMENT = ZO_ActionLayerFragment:New("Guild")
MOUSE_UI_MODE_FRAGMENT = ZO_ActionLayerFragment:New("MouseUIMode")
GAMEPAD_UI_MODE_FRAGMENT = ZO_ActionLayerFragment:New("GamepadUIMode")
GAMEPAD_ACTION_LAYER_FRAGMENT = ZO_ActionLayerFragment:New("GamepadActions")
HOUSING_EDITOR_HUD_ACTION_LAYER_FRAGMENT = ZO_ActionLayerFragment:New(GetString(SI_KEYBINDINGS_LAYER_HOUSING_EDITOR))

--Intercept Layer
INTERACT_WINDOW_KEYBIND_INTERCEPT_LAYER_FRAGMENT = ZO_ActionLayerFragment:New("SceneChangeInterceptLayer")
INTERACT_WINDOW_KEYBIND_INTERCEPT_LAYER_FRAGMENT:SetConditional(function()
        return IsUnderArrest()
    end)

-- Preview Intercept Layer
PREVIEW_KEYBIND_INTERCEPT_LAYER_FRAGMENT = ZO_ActionLayerFragment:New("PreviewInterceptLayer")

--Crafting window keybind intercept layer
ZO_CraftingWindowKeybindInterceptLayerFragment = ZO_ActionLayerFragment:Subclass()

function ZO_CraftingWindowKeybindInterceptLayerFragment:New(actionLayerName)
    local fragment = ZO_ActionLayerFragment.New(self, actionLayerName)

    CALLBACK_MANAGER:RegisterCallback("CraftingAnimationsStarted", function()
        fragment:Refresh()
    end)
    CALLBACK_MANAGER:RegisterCallback("CraftingAnimationsStopped", function()
        fragment:Refresh()
    end)

    return fragment
end

CRAFTING_WINDOW_KEYBIND_INTERCEPT_LAYER_FRAGMENT = ZO_CraftingWindowKeybindInterceptLayerFragment:New("SceneChangeInterceptLayer")
CRAFTING_WINDOW_KEYBIND_INTERCEPT_LAYER_FRAGMENT:SetConditional(function()
        return ZO_CraftingUtils_IsPerformingCraftProcess()
    end)

--Shared Tutorials
LOCKPICK_TUTORIAL_FRAGMENT = ZO_TutorialTriggerFragment:New(TUTORIAL_TRIGGER_LOCKPICKING_OPENED)

HOUSING_EDITOR_HUD_FRAGMENT = ZO_HousingEditorHUDFragment:New()
HOUSING_EDITOR_ACTION_BAR_FRAGMENT = ZO_FadeSceneFragment:New(ZO_HousingEditorActionBarTopLevel)