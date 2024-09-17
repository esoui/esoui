----------
-- Pane --
----------

local CHAPTER_UPGRADE_REWARD_HEADER_DATA = 1
local CHAPTER_UPGRADE_REWARD_EDITION_HEADER_DATA = 2
local CHAPTER_UPGRADE_REWARD_DATA = 3

ZO_CHAPTER_UPGRADE_GAMEPAD_REWARD_ENTRY_HEADER_HEIGHT = 50
ZO_CHAPTER_UPGRADE_GAMEPAD_REWARD_ENTRY_HEIGHT = 80

ZO_ChapterUpgradePane_Gamepad = ZO_Object.MultiSubclass(ZO_ChapterUpgradePane_Shared, ZO_SortFilterList_Gamepad)

function ZO_ChapterUpgradePane_Gamepad:New(...)
    return ZO_ChapterUpgradePane_Shared.New(self, ...)
end

function ZO_ChapterUpgradePane_Gamepad:Initialize(control)
    ZO_ChapterUpgradePane_Shared.Initialize(self, control)
    ZO_SortFilterList_Gamepad.Initialize(self, control)
end

function ZO_ChapterUpgradePane_Gamepad:InitializeSortFilterList(...)
    ZO_SortFilterList_Gamepad.InitializeSortFilterList(self, ...)

    local function SetupRewardsHeader(control, data)
        control.descriptor:SetText(data.text)
        if control.collectorsLabel and data.collectorsLabelText then
            control.collectorsLabel:SetText(data.collectorsLabelText)
        end
    end

    local function SetupReward(control, data)
        control.icon:SetTexture(data.icon)
        control.displayName:SetText(data.text)
        control.standardCheckMark:SetHidden(not data.isStandardReward)
        control.collectorsCheckMark:SetHidden(not data.isCollectorsReward)
    end

    ZO_ScrollList_AddDataType(self.list, CHAPTER_UPGRADE_REWARD_HEADER_DATA, "ZO_ChapterUpgrade_Gamepad_RewardsEntryHeader", ZO_CHAPTER_UPGRADE_GAMEPAD_REWARD_ENTRY_HEADER_HEIGHT, SetupRewardsHeader)
    ZO_ScrollList_AddDataType(self.list, CHAPTER_UPGRADE_REWARD_EDITION_HEADER_DATA, "ZO_ChapterUpgrade_Gamepad_RewardsEditionEntryHeader", ZO_CHAPTER_UPGRADE_GAMEPAD_REWARD_ENTRY_HEADER_HEIGHT, SetupRewardsHeader)
    ZO_ScrollList_AddDataType(self.list, CHAPTER_UPGRADE_REWARD_DATA, "ZO_ChapterUpgrade_Gamepad_RewardsEntry", ZO_CHAPTER_UPGRADE_GAMEPAD_REWARD_ENTRY_HEIGHT, SetupReward)
    ZO_ScrollList_SetTypeSelectable(self.list, CHAPTER_UPGRADE_REWARD_HEADER_DATA, false)
    ZO_ScrollList_SetTypeSelectable(self.list, CHAPTER_UPGRADE_REWARD_EDITION_HEADER_DATA, false)
    ZO_ScrollList_SetTypeCategoryHeader(self.list, CHAPTER_UPGRADE_REWARD_HEADER_DATA, true)
    ZO_ScrollList_SetTypeCategoryHeader(self.list, CHAPTER_UPGRADE_REWARD_EDITION_HEADER_DATA, true)
end

function ZO_ChapterUpgradePane_Gamepad:ShowSelectedDataTooltip()
    local marketProductId = self:GetSelectedProductId()
    if marketProductId ~= 0 then
        local SHOW_PURCHASABLE_HINT = true
        GAMEPAD_TOOLTIPS:LayoutMarketProduct(GAMEPAD_RIGHT_TOOLTIP, marketProductId, SHOW_PURCHASABLE_HINT)
    end
end

function ZO_ChapterUpgradePane_Gamepad:ShowPreviewIndexTooltip()
    local marketProductId = ITEM_PREVIEW_LIST_HELPER_GAMEPAD:GetCurrentPreviewData()
    if marketProductId then
        local SHOW_PURCHASABLE_HINT = true
        GAMEPAD_TOOLTIPS:LayoutMarketProduct(GAMEPAD_RIGHT_TOOLTIP, marketProductId, SHOW_PURCHASABLE_HINT)
    end
end

-- Begin ZO_SortFilterList Overrides --

do
    local function AddRewards(scrollData, rewardsData)
        for _, reward in ipairs(rewardsData) do
            local entryData = ZO_GamepadEntryData:New(reward.displayName, reward.icon)
            entryData:SetDataSource(reward)
            table.insert(scrollData, ZO_ScrollList_CreateDataEntry(CHAPTER_UPGRADE_REWARD_DATA, entryData))
        end
    end

    function ZO_ChapterUpgradePane_Gamepad:FilterScrollList()
        -- We don't need to keep a master list around in this class, so ignore BuildMasterList()
        local scrollData = ZO_ScrollList_GetDataList(self.list)
        ZO_ScrollList_Clear(self.list)

        if self.chapterUpgradeData:IsPreRelease() then
            local prePurchaseRewards = self.chapterUpgradeData:GetPrePurchaseRewards()
            if #prePurchaseRewards > 0 then
                local headerData = ZO_GamepadEntryData:New(GetString(SI_CHAPTER_UPGRADE_PREPURCHASE_HEADER))
                table.insert(scrollData, ZO_ScrollList_CreateDataEntry(CHAPTER_UPGRADE_REWARD_HEADER_DATA, headerData))
                AddRewards(scrollData, prePurchaseRewards)
            end
        end
        
        local editionRewards = self.chapterUpgradeData:GetEditionRewards()
        if #editionRewards > 0 then
            local headerData = ZO_GamepadEntryData:New(GetString(SI_CHAPTER_UPGRADE_CHOOSE_EDITION_HEADER))
            local isContentPass = self.chapterUpgradeData:IsContentPass()
            local collectorsLabelText = isContentPass and GetString(SI_CHAPTER_UPGRADE_CONTENT_PASS_COLLECTORS_REWARDS_HEADER) or GetString(SI_CHAPTER_UPGRADE_COLLECTORS_REWARDS_HEADER)
            headerData.collectorsLabelText = collectorsLabelText
            table.insert(scrollData, ZO_ScrollList_CreateDataEntry(CHAPTER_UPGRADE_REWARD_EDITION_HEADER_DATA, headerData))
            AddRewards(scrollData, editionRewards)
        end
    end
end

function ZO_ChapterUpgradePane_Gamepad:UpdateKeybinds()
    ZO_CHAPTER_UPGRADE_GAMEPAD:RefreshKeybinds()
end

function ZO_ChapterUpgradePane_Gamepad:OnSelectionChanged(oldData, newData)
    ZO_SortFilterList_Gamepad.OnSelectionChanged(self, oldData, newData)
    local RETAIN_FRAGMENT = true
    ZO_CHAPTER_UPGRADE_GAMEPAD:RefreshTooltip(RETAIN_FRAGMENT)
end

function ZO_ChapterUpgradePane_Gamepad:GetNarrationText()
    local narrations = {}
    local selectedData = self:GetSelectedData()
    if selectedData then
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(selectedData.text))

        if selectedData.isStandardReward then
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_CHAPTER_UPGRADE_STANDARD_REWARDS_HEADER)))
        end

        if selectedData.isCollectorsReward then
            local isContentPass = self.chapterUpgradeData:IsContentPass()
            local collectorsHeaderText = isContentPass and GetString(SI_CHAPTER_UPGRADE_CONTENT_PASS_COLLECTORS_REWARDS_HEADER) or GetString(SI_CHAPTER_UPGRADE_COLLECTORS_REWARDS_HEADER)
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(collectorsHeaderText))
        end
    end
    return narrations
end

-- End ZO_SortFilterList Overrides --

-- Begin ZO_ChapterUpgradePane_Shared Overrides --

function ZO_ChapterUpgradePane_Gamepad:SetChapterUpgradeData(data)
    ZO_ChapterUpgradePane_Shared.SetChapterUpgradeData(self, data)

    self:RefreshData()
end

function ZO_ChapterUpgradePane_Gamepad:GetSelectedProductId()
    local selectedData = ZO_ScrollList_GetAutoSelectData(self.list)
    if selectedData then
        return selectedData.marketProductId
    end
    return 0
end

function ZO_ChapterUpgradePane_Gamepad:GetItemPreviewListHelper()
    return ITEM_PREVIEW_LIST_HELPER_GAMEPAD
end

-- End ZO_ChapterUpgradePane_Shared Overrides --

------------
-- Screen --
------------

local SELECTION_MODE =
{
    CHAPTER = 1,
    REWARD = 2,
}

ZO_ChapterUpgrade_Gamepad = ZO_Gamepad_ParametricList_Screen:Subclass()

function ZO_ChapterUpgrade_Gamepad:New(...)
    return ZO_Gamepad_ParametricList_Screen.New(self, ...)
end

function ZO_ChapterUpgrade_Gamepad:Initialize(control)
    ZO_GAMEPAD_CHAPTER_UPGRADE_SCENE = ZO_Scene:New("chapterUpgradeGamepad", SCENE_MANAGER)
    local ACTIVATE_ON_SHOW = true
    ZO_Gamepad_ParametricList_Screen.Initialize(self, control, ZO_GAMEPAD_HEADER_TABBAR_DONT_CREATE, ACTIVATE_ON_SHOW, ZO_GAMEPAD_CHAPTER_UPGRADE_SCENE)

    self.headerData =
    {
        titleText = GetString(SI_MAIN_MENU_CHAPTERS),
    }

    ZO_GamepadGenericHeader_RefreshData(self.header, self.headerData)

    self.categoryList = self:GetMainList()
    local rightPaneContentsControl = control:GetNamedChild("RightPaneContents")
    self.chapterUpgradePane = ZO_ChapterUpgradePane_Gamepad:New(rightPaneContentsControl)

    self:InitializeSelectEditionDialog()

    GAMEPAD_CHAPTER_UPGRADE_FRAGMENT = ZO_SimpleSceneFragment:New(control)
    GAMEPAD_CHAPTER_UPGRADE_FRAGMENT:SetHideOnSceneHidden(true)
    GAMEPAD_CHAPTER_UPGRADE_PANE_FRAGMENT = ZO_FadeSceneFragment:New(rightPaneContentsControl)

    ZO_CHAPTER_UPGRADE_MANAGER:RegisterCallback("ChapterUpgradeDataUpdated", function() self:Update() end)

    local function OnRequestShowGamepadChapterUpgrade(eventId, chapterUpgradeId)
        if IsInGamepadPreferredMode() then
            self:RequestShowChapterUpgrade(chapterUpgradeId)
        end
    end

    EVENT_MANAGER:RegisterForEvent("ZO_ChapterUpgrade_Gamepad", EVENT_REQUEST_SHOW_GAMEPAD_CHAPTER_UPGRADE, OnRequestShowGamepadChapterUpgrade)
    EVENT_MANAGER:RegisterForEvent("ZO_ChapterUpgrade_Gamepad", EVENT_COLLECTIBLES_UNLOCK_STATE_CHANGED, function() self:Update() end)

    self.selectionMode = SELECTION_MODE.CHAPTER

    self:InitializePreviewScene()

    local chapterUpgradeSceneGroup = ZO_SceneGroup:New("chapterUpgradeGamepad", "chapterUpgradePreviewGamepad")
    chapterUpgradeSceneGroup:RegisterCallback("StateChange", function(_, newState)
        if newState == SCENE_GROUP_SHOWING then
            self:OnSceneGroupShowing()
        elseif newState == SCENE_GROUP_HIDDEN then
            self:OnSceneGroupHidden()
        end
    end)
    SCENE_MANAGER:AddSceneGroup("gamepad_chapterUpgrade_scenegroup", chapterUpgradeSceneGroup)
end

function ZO_ChapterUpgrade_Gamepad:InitializeKeybindStripDescriptors()
    -- Category Keybind
    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,

        -- Select
        {
            name = function()
                if self.selectionMode == SELECTION_MODE.CHAPTER then
                    return GetString(SI_GAMEPAD_SELECT_OPTION)
                else
                    return GetString(SI_ITEM_ACTION_PREVIEW)
                end
            end,

            keybind = "UI_SHORTCUT_PRIMARY",

            sound = SOUNDS.GAMEPAD_MENU_FORWARD,

            visible = function()
                return self.chapterUpgradePane:HasEntries()
            end,

            enabled = function()
                return self.selectionMode == SELECTION_MODE.CHAPTER or self.chapterUpgradePane:CanPreviewSelection()
            end,

            callback = function()
                if self.selectionMode == SELECTION_MODE.CHAPTER then
                    self:SwitchView()
                else
                    self:Preview()
                end
            end,
        },
        -- Upgrade
        {
            alignment = KEYBIND_STRIP_ALIGN_CENTER,

            name = function()
                local chapterUpgradeTargetData = self.categoryList:GetTargetData()
                if chapterUpgradeTargetData:IsPreRelease() then
                    return GetString(SI_CHAPTER_UPGRADE_GAMEPAD_PREPURCHASE_KEYBIND)
                else
                    return GetString(SI_CHAPTER_UPGRADE_GAMEPAD_UPGRADE_KEYBIND)
                end
            end,

            keybind = "UI_SHORTCUT_SECONDARY",
            
            visible = function()
                local chapterUpgradeData = self.categoryList:GetTargetData()
                return chapterUpgradeData and not chapterUpgradeData:IsOwned()
            end,

            callback = function()
                ZO_Dialogs_ShowGamepadDialog("GAMEPAD_CHAPTER_UPGRADE_CHOOSE_EDITION", { chapterUpgradeData = self.categoryList:GetTargetData(), })
            end,
        },
        {
            --Ethereal binds show no text, the name field is used to help identify the keybind when debugging. This text does not have to be localized.
            name = "Gamepad Chapter Upgrade Previous Section in List",
            keybind = "UI_SHORTCUT_LEFT_TRIGGER",
            ethereal = true,
            callback = function()
                if ZO_ScrollList_CanScrollUp(self.chapterUpgradePane.list) then
                    ZO_ScrollList_SelectFirstIndexInCategory(self.chapterUpgradePane.list, ZO_SCROLL_SELECT_CATEGORY_PREVIOUS)
                    PlaySound(ZO_PARAMETRIC_SCROLL_MOVEMENT_SOUNDS[ZO_PARAMETRIC_MOVEMENT_TYPES.JUMP_PREVIOUS])
                end
            end,
            enabled = function()
                return self.selectionMode == SELECTION_MODE.REWARD
            end,
        },
        {
            --Ethereal binds show no text, the name field is used to help identify the keybind when debugging. This text does not have to be localized.
            name = "Gamepad Chapter Upgrade Next Section in List",
            keybind = "UI_SHORTCUT_RIGHT_TRIGGER",
            ethereal = true,
            callback = function()
                if ZO_ScrollList_CanScrollDown(self.chapterUpgradePane.list) then
                    ZO_ScrollList_SelectFirstIndexInCategory(self.chapterUpgradePane.list, ZO_SCROLL_SELECT_CATEGORY_NEXT)
                    PlaySound(ZO_PARAMETRIC_SCROLL_MOVEMENT_SOUNDS[ZO_PARAMETRIC_MOVEMENT_TYPES.JUMP_NEXT])
                end
            end,
           enabled = function()
                return self.selectionMode == SELECTION_MODE.REWARD
            end,
        },
    }

    local function BackCallback()
        if self.selectionMode == SELECTION_MODE.CHAPTER then
            SCENE_MANAGER:HideCurrentScene()
        else
            self:SwitchView()
        end
    end

    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.keybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON, BackCallback)

    self.previewKeybindStripDesciptor =
    {
        KEYBIND_STRIP:GetDefaultGamepadBackButtonDescriptor()
    }
end

function ZO_ChapterUpgrade_Gamepad:InitializePreviewScene()
    ZO_GAMEPAD_CHAPTER_UPGRADE_PREVIEW_SCENE = ZO_Scene:New("chapterUpgradePreviewGamepad", SCENE_MANAGER)

    local RefreshTooltipFunction = function() self:RefreshTooltip() end

    local function PreviewSceneOnStateChange(oldState, newState)
        if newState == SCENE_SHOWING then
            KEYBIND_STRIP:AddKeybindButtonGroup(self.previewKeybindStripDesciptor)
            ITEM_PREVIEW_LIST_HELPER_GAMEPAD:RegisterCallback("OnPreviewChanged", RefreshTooltipFunction)
        elseif newState == SCENE_SHOWN then
            --Preventing an out of order issue with the begin preview mode
            self.chapterUpgradePane:PreviewSelection()
        elseif newState == SCENE_HIDDEN then
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.previewKeybindStripDesciptor)
            ITEM_PREVIEW_LIST_HELPER_GAMEPAD:UnregisterCallback("OnPreviewChanged", RefreshTooltipFunction)
        end
    end

    ZO_GAMEPAD_CHAPTER_UPGRADE_PREVIEW_SCENE:RegisterCallback("StateChange", PreviewSceneOnStateChange)
end

function ZO_ChapterUpgrade_Gamepad:OnSceneGroupShowing()
    ZO_CHAPTER_UPGRADE_MANAGER:RequestPrepurchaseData()
end

function ZO_ChapterUpgrade_Gamepad:OnSceneGroupHidden()
    self.selectionMode = SELECTION_MODE.CHAPTER
end

function ZO_ChapterUpgrade_Gamepad:RefreshActiveList()
    if self.selectionMode == SELECTION_MODE.CHAPTER then
        self.chapterUpgradePane:Deactivate()
        self:ActivateCurrentList()
    else
        self:DeactivateCurrentList()
        self.chapterUpgradePane:Activate()
    end

    self:RefreshTooltip()
end

do
    local function AddChapterUpgradeEntry(list, chapterUpgradeData)
        local entryData = ZO_GamepadEntryData:New(chapterUpgradeData:GetFormattedName(), chapterUpgradeData:GetCollectibleIcon())
        if chapterUpgradeData:IsNew() and not chapterUpgradeData:IsOwned() then
            entryData:SetNew(true)
        end
        entryData:SetDataSource(chapterUpgradeData)
        entryData:SetIconTintOnSelection(true)
        list:AddEntry("ZO_GamepadMenuEntryTemplate", entryData)
    end

    function ZO_ChapterUpgrade_Gamepad:BuildCategories()
        self.categoryList:Clear()

        for index = 1, ZO_CHAPTER_UPGRADE_MANAGER:GetNumChapterUpgrades() do
            local chapterUpgradeData = ZO_CHAPTER_UPGRADE_MANAGER:GetChapterUpgradeDataByIndex(index)
            AddChapterUpgradeEntry(self.categoryList, chapterUpgradeData)
        end

        self.categoryList:Commit()

        -- If we're rebuilding the categories, we rebuilt the rewards as well, so if we're in rewards view we want to come back out to the categories
        if self.selectionMode ~= SELECTION_MODE.CHAPTER then
            self:SwitchView()
        end
    end
end

function ZO_ChapterUpgrade_Gamepad:RefreshTooltip(retainFragment)
    GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_RIGHT_TOOLTIP, retainFragment)

    if self.selectionMode == SELECTION_MODE.CHAPTER then
        local selectedData = self.categoryList:GetSelectedData()
        GAMEPAD_TOOLTIPS:LayoutTitleAndDescriptionTooltip(GAMEPAD_RIGHT_TOOLTIP, selectedData:GetFormattedName(), selectedData:GetSummary())
    elseif ZO_GAMEPAD_CHAPTER_UPGRADE_PREVIEW_SCENE:IsShowing() then
        self.chapterUpgradePane:ShowPreviewIndexTooltip()
    else
        self.chapterUpgradePane:ShowSelectedDataTooltip()
    end
end

function ZO_ChapterUpgrade_Gamepad:SwitchView()
    if self.selectionMode == SELECTION_MODE.CHAPTER then
        self.selectionMode = SELECTION_MODE.REWARD
    else
        self.selectionMode = SELECTION_MODE.CHAPTER
    end

    self:RefreshActiveList()
    self:RefreshKeybinds()
end

function ZO_ChapterUpgrade_Gamepad:Preview()
    SCENE_MANAGER:Push("chapterUpgradePreviewGamepad")
end

function ZO_ChapterUpgrade_Gamepad:TrySelectQueuedChapterUpgrade()
    if self.queuedChapterUpgradeId ~= nil and GetMarketState(MARKET_DISPLAY_GROUP_CHAPTER_UPGRADE) == MARKET_STATE_OPEN then
        local function IsQueuedChapterUpgrade(data)
            return data.chapterUpgradeId == self.queuedChapterUpgradeId
        end
        self.categoryList:SetSelectedDataByEval(IsQueuedChapterUpgrade)
        self.queuedChapterUpgradeId = nil
    end
end

function ZO_ChapterUpgrade_Gamepad:RequestShowChapterUpgrade(chapterUpgradeId)
    self.queuedChapterUpgradeId = chapterUpgradeId
    if SCENE_MANAGER:IsShowing("chapterUpgradeGamepad") then
        if self.selectionMode == SELECTION_MODE.CHAPTER then
            self:TrySelectQueuedChapterUpgrade()
        end
    else
        SCENE_MANAGER:Show("chapterUpgradeGamepad")
    end
end

function ZO_ChapterUpgrade_Gamepad:InitializeSelectEditionDialog()
    ZO_Dialogs_RegisterCustomDialog("GAMEPAD_CHAPTER_UPGRADE_CHOOSE_EDITION",
    {
        canQueue = true,
        gamepadInfo = 
        {
            dialogType = GAMEPAD_DIALOGS.PARAMETRIC,
        },

        setup = function(dialog)
            dialog:setupFunc()
        end,

        title =
        {
            text = SI_CHAPTER_UPGRADE_GAMEPAD_SELECT_EDITION_DIALOG_TITLE,
        },

        parametricList =
        {
            -- Collector's
            {
                template = "ZO_GamepadMenuEntryTemplate",
                templateData =
                {
                    text = function(dialog)
                        if dialog.data.chapterUpgradeData:IsContentPass() then
                            return GetString(SI_CHAPTER_UPGRADE_CONTENT_PASS_GAMEPAD_SELECT_EDITION_DIALOG_COLLECTORS_ENTRY)
                        else
                            return GetString(SI_CHAPTER_UPGRADE_GAMEPAD_SELECT_EDITION_DIALOG_COLLECTORS_ENTRY)
                        end
                    end,
                    setup = ZO_SharedGamepadEntry_OnSetup,
                    isCollectorsEdition = true,
                },
            },
            -- Standard
            {
                template = "ZO_GamepadMenuEntryTemplate",
                templateData =
                {
                    text = GetString(SI_CHAPTER_UPGRADE_GAMEPAD_SELECT_EDITION_DIALOG_STANDARD_ENTRY),
                    setup = ZO_SharedGamepadEntry_OnSetup,
                    isCollectorsEdition = false,
                },
            },
        },
        buttons =
        {
            {
                keybind = "DIALOG_PRIMARY",
                text = SI_GAMEPAD_SELECT_OPTION,
                callback =  function(dialog)
                    local entryData = dialog.entryList:GetTargetData()
                    if dialog.data.chapterUpgradeData:IsPreRelease() then
                        ZO_ShowChapterPrepurchasePlatformDialog(dialog.data.chapterUpgradeData:GetChapterUpgradeId(), entryData.isCollectorsEdition, CHAPTER_UPGRADE_SOURCE_IN_GAME)
                    else
                        ZO_ShowChapterUpgradePlatformDialog(entryData.isCollectorsEdition, CHAPTER_UPGRADE_SOURCE_IN_GAME)
                    end
                end,
            },

            {
                keybind = "DIALOG_NEGATIVE",
                text = SI_DIALOG_CANCEL,
            },
        }
    })
end

-- Begin ZO_Gamepad_ParametricList_Screen Overrides --


function ZO_ChapterUpgrade_Gamepad:OnShowing()
    ZO_Gamepad_ParametricList_Screen.OnShowing(self)

    self:RefreshActiveList()
    self:TrySelectQueuedChapterUpgrade()
end

function ZO_ChapterUpgrade_Gamepad:OnHiding()
    self.chapterUpgradePane:Deactivate()
    GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_RIGHT_TOOLTIP)
end

function ZO_ChapterUpgrade_Gamepad:PerformUpdate()
    self:BuildCategories()
    self:TrySelectQueuedChapterUpgrade()
    self.dirty = false
end

function ZO_ChapterUpgrade_Gamepad:OnSelectionChanged(list, selectedData, oldSelectedData)
    self.chapterUpgradePane:SetChapterUpgradeData(selectedData)
        
    local RETAIN_FRAGMENT = true
    self:RefreshTooltip(RETAIN_FRAGMENT)
end

-- End ZO_Gamepad_ParametricList_Screen Overrides --

-- Begin Global XML Functions --

function ZO_ChapterUpgrade_Gamepad_OnInitialize(control)
    ZO_CHAPTER_UPGRADE_GAMEPAD = ZO_ChapterUpgrade_Gamepad:New(control)
end

-- End Global XML Functions --
