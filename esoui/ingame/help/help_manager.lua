local ZO_Help_Manager = ZO_InitializingCallbackObject:Subclass()

function ZO_Help_Manager:Initialize(...)
    self.overlayScenes = {}
    
    EVENT_MANAGER:RegisterForEvent("Help_Manager", EVENT_GAMEPAD_PREFERRED_MODE_CHANGED, function() self:OnGamepadPreferredModeChanged() end)

    EVENT_MANAGER:RegisterForEvent("Help_Manager", EVENT_TOGGLE_HELP, function() self:ToggleHelp() end)

    local function OnShowSpecificPage(_, helpCategoryIndex, helpIndex)
        -- If we ever want to use this mechanism to show the overlay version we can, but right now there's no use case
        -- so that can be a future change if we decide we need it
        if IsInGamepadPreferredMode() then
            -- ideally we would do a push here, but that is currently not playing
            -- well with opening help from the Crown Store
            -- specifically: attempting to gift from the furniture browser with gifting locked
            HELP_TUTORIALS_ENTRIES_GAMEPAD:Show(helpCategoryIndex, helpIndex)
        else
            HELP:ShowSpecificHelp(helpCategoryIndex, helpIndex)
        end
    end

    EVENT_MANAGER:RegisterForEvent("Help_Manager", EVENT_SHOW_SPECIFIC_HELP_PAGE, OnShowSpecificPage)

    local function OnInterceptCloseAction()
        SCENE_MANAGER:RemoveFragmentGroup(HELP_TUTORIALS_OVERLAY_KEYBOARD_FRAGMENT_GROUP)
        local HANDLED = true
        return HANDLED
    end

    self.overlaySyncObject = GetOrCreateSynchronizingObject("helpOverlay")
    self.overlaySyncObject:SetHandler("OnShown", function()
        local NO_ARG = nil
        -- We want HelpOverlay to get dibs on intercepting the close button before other systems (e.g.: Tribute conceding)
        local PRIORITY = 1
        CLOSE_ACTIONS_INTERCEPT_LAYER_FRAGMENT:RegisterCallback("InterceptCloseAction", OnInterceptCloseAction, NO_ARG, PRIORITY)
    end, "Help_Manager")
    
    self.overlaySyncObject:SetHandler("OnHidden", function()
        CLOSE_ACTIONS_INTERCEPT_LAYER_FRAGMENT:UnregisterCallback("InterceptCloseAction", OnInterceptCloseAction)
    end, "Help_Manager")

    EVENT_MANAGER:RegisterForEvent("Help_Manager", EVENT_GUI_UNLOADING, function()
        while self.overlaySyncObject:IsShown() do
            self.overlaySyncObject:Hide()
        end
    end)

    self.searchCache = nil
    -- Generates a list of helpIds across all categories.
    local function CreateFilterPrimaryKeys()
        local helpIdList = {}
        for categoryIndex = 1, GetNumHelpCategories() do
            for helpIndex = 1, GetNumHelpEntriesWithinCategory(categoryIndex) do
                local helpId = GetHelpId(categoryIndex, helpIndex)
                table.insert(helpIdList, helpId)
            end
        end
        return helpIdList
    end

    -- Shared search for help tutorials
    local helpFilterTargetDescriptor =
    {
        [BACKGROUND_LIST_FILTER_TARGET_HELP_ID] =
        {
            searchFilterList =
            {
                BACKGROUND_LIST_FILTER_TYPE_NAME,
                BACKGROUND_LIST_FILTER_TYPE_DESCRIPTION,
                BACKGROUND_LIST_FILTER_TYPE_SEARCH_KEYWORDS,
            },
            primaryKeys = function()
                -- Cache the list of search keys.
                if self.searchCache == nil then
                    self.searchCache = CreateFilterPrimaryKeys()
                end
                return self.searchCache
            end,
        },
    }
    TEXT_SEARCH_MANAGER:SetupContextTextSearch("helpSearchContext", helpFilterTargetDescriptor)
end

function ZO_Help_Manager:OnGamepadPreferredModeChanged()
    if self:IsShowingOverlayScene() then
        SCENE_MANAGER:RemoveFragmentGroup(HELP_TUTORIALS_OVERLAY_KEYBOARD_FRAGMENT_GROUP)
        ZO_Dialogs_ReleaseDialog("HELP_TUTORIALS_OVERLAY_DIALOG")
    end
end

-- Optionally pass in a data object that can specify arguments and filters
-- sceneInfo =
-- {
--     systemFilters = { UI_SYSTEM_ANTIQUITY_DIGGING, UI_SYSTEM_BATTELGROUND_FINDER },
--     showOverlayConditionalFunction = function() MySceneShouldShowOverlayExample() end,
-- }
function ZO_Help_Manager:AddOverlayScene(sceneName, sceneInfo)
    sceneInfo = sceneInfo or {}
    sceneInfo.systemFilters = sceneInfo.systemFilters or {}
    self.overlayScenes[sceneName] = sceneInfo
end

function ZO_Help_Manager:GetShowingOverlaySceneInfo()
    for sceneName, sceneInfo in pairs(self.overlayScenes) do
        if SCENE_MANAGER:IsShowing(sceneName) and (not sceneInfo.showOverlayConditionalFunction or sceneInfo.showOverlayConditionalFunction())then
            return sceneInfo
        end
    end
    return nil
end

function ZO_Help_Manager:GetShowingOverlaySceneSystemFilters()
    local sceneInfo = self:GetShowingOverlaySceneInfo()
    return sceneInfo and sceneInfo.systemFilters or nil
end

function ZO_Help_Manager:IsShowingOverlayScene()
    return self:GetShowingOverlaySceneInfo() ~= nil
end

function ZO_Help_Manager:ToggleHelp()
    if TUTORIAL_SYSTEM:ShowHelp() then
        return
    end

    if self:IsShowingOverlayScene() then
        self:ToggleHelpOverlay()
        return
    end

    SYSTEMS:GetObject("mainMenu"):ToggleCategory(MENU_CATEGORY_HELP)
end

function ZO_Help_Manager:ToggleHelpOverlay()
    if IsInGamepadPreferredMode() then
        if ZO_Dialogs_IsShowing("HELP_TUTORIALS_OVERLAY_DIALOG") then
            ZO_Dialogs_ReleaseDialog("HELP_TUTORIALS_OVERLAY_DIALOG")
        else
            ZO_Dialogs_ShowGamepadDialog("HELP_TUTORIALS_OVERLAY_DIALOG")
        end
    else
        if HELP_TUTORIALS_FRAGMENT:IsShowing() then
            SCENE_MANAGER:RemoveFragmentGroup(HELP_TUTORIALS_OVERLAY_KEYBOARD_FRAGMENT_GROUP)
        else
            SCENE_MANAGER:AddFragmentGroup(HELP_TUTORIALS_OVERLAY_KEYBOARD_FRAGMENT_GROUP)
        end
    end
end

function ZO_Help_Manager:GetOverlaySyncObject()
    return self.overlaySyncObject
end

HELP_MANAGER = ZO_Help_Manager:New()