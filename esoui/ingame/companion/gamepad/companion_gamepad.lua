-------------------------
-- Companion Gamepad
-------------------------
ZO_Companion_Gamepad = ZO_Gamepad_ParametricList_Screen:Subclass()

function ZO_Companion_Gamepad:Initialize(control)
    self.control = control

    COMPANION_GAMEPAD_FRAGMENT = ZO_FadeSceneFragment:New(control)
    COMPANION_GAMEPAD_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_FRAGMENT_SHOWING then
            ZO_OUTFITS_SELECTOR_GAMEPAD:SetCurrentActorCategory(GAMEPLAY_ACTOR_CATEGORY_COMPANION)
            --Manually call OnTargetChanged to ensure the proper logic is run when opening the screen
            local list = self:GetMainList()
            local targetData = list:GetTargetData()
            self:RefreshList()
            self:RefreshTargetTooltip(list, targetData)
            self:RefreshHeader()
        elseif newState == SCENE_FRAGMENT_HIDDEN then
            self:ResetTooltips()
        end
    end)

    COMPANION_ROOT_GAMEPAD_SCENE = ZO_InteractScene:New("companionRootGamepad", SCENE_MANAGER, ZO_COMPANION_MANAGER:GetInteraction())
    COMPANION_ROOT_GAMEPAD_SCENE:AddFragment(COMPANION_GAMEPAD_FRAGMENT)

    local ACTIVATE_ON_SHOW = true
    ZO_Gamepad_ParametricList_Screen.Initialize(self, control, ZO_GAMEPAD_HEADER_TABBAR_DONT_CREATE, ACTIVATE_ON_SHOW, COMPANION_ROOT_GAMEPAD_SCENE)

    local list = self:GetMainList()
    list:AddDataTemplate("ZO_GamepadNewMenuEntryTemplate", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction)

    local function OnOpenCompanionMenu()
        if IsInGamepadPreferredMode() then
            SCENE_MANAGER:Show("companionRootGamepad")
        end
    end

    control:RegisterForEvent(EVENT_OPEN_COMPANION_MENU, OnOpenCompanionMenu)

    GAMEPAD_COMPANION_OUTFITS_SELECTION_SCENE = ZO_InteractScene:New("gamepad_companion_outfits_selection", SCENE_MANAGER, ZO_COMPANION_MANAGER:GetInteraction())
    GAMEPAD_COMPANION_OUTFITS_SELECTION_SCENE:SetInputPreferredMode(INPUT_PREFERRED_MODE_ALWAYS_GAMEPAD)

    local function OnCompanionInfoChanged()
        if COMPANION_GAMEPAD_FRAGMENT:IsShowing() then
            --Manually call OnTargetChanged to ensure the proper logic is run when information is updated
            local list = self:GetMainList()
            local targetData = list:GetTargetData()
            self:RefreshTargetTooltip(list, targetData)
        end
    end

    EVENT_MANAGER:RegisterForEvent("ZO_Companion_Gamepad", EVENT_COMPANION_EXPERIENCE_GAIN, OnCompanionInfoChanged)
    EVENT_MANAGER:RegisterForEvent("ZO_Companion_Gamepad", EVENT_COMPANION_RAPPORT_UPDATE, OnCompanionInfoChanged)

    local function OnRefreshList()
        if COMPANION_GAMEPAD_FRAGMENT:IsShowing() then
            self:RefreshList()
        end
    end

    ZO_COLLECTIBLE_DATA_MANAGER:RegisterCallback("OnCollectibleUpdated", OnRefreshList)
    ZO_COLLECTIBLE_DATA_MANAGER:RegisterCallback("OnCollectionUpdated", OnRefreshList)
end

function ZO_Companion_Gamepad:OnDeferredInitialize()
    self:InitializeHeader()
    self:InitializeList()
    self:SetListsUseTriggerKeybinds(true)
end

function ZO_Companion_Gamepad:PerformUpdate()
   self.dirty = false
end

function ZO_Companion_Gamepad:InitializeHeader()
    self:InitializeOutfitSelector()
    self.headerData =
    {
        titleText = GetString(SI_COMPANION_MENU_ROOT_TITLE),
    }
    ZO_GamepadGenericHeader_Refresh(self.header, self.headerData)
end

function ZO_Companion_Gamepad:InitializeKeybindStripDescriptors()
    self.keybindStripDescriptor =
    {
        -- Select mode.
        {
            keybind = "UI_SHORTCUT_PRIMARY",
            alignment = KEYBIND_STRIP_ALIGN_LEFT,

            name = function()
                return GetString(SI_GAMEPAD_SELECT_OPTION)
            end,
            visible = function()
                if self.outfitSelectorHeaderFocus:IsActive() then
                    return true
                else
                    local targetData = self:GetMainList():GetTargetData()
                    return targetData and targetData.sceneName ~= nil
                end
            end,
            callback = function()
                if self.outfitSelectorHeaderFocus:IsActive() then
                    SCENE_MANAGER:Push("gamepad_companion_outfits_selection")
                else
                    local list = self:GetMainList()
                    local targetData = list:GetTargetData()
                    SCENE_MANAGER:Push(targetData.sceneName)
                end
            end,
        },
    }

    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.keybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON)
end

function ZO_Companion_Gamepad:InitializeList()
    self.menuData =
    {
        {
            icon = "EsoUI/Art/Companion/Gamepad/gp_companion_icon_overview.dds",
            name = SI_COMPANION_MENU_OVERVIEW_TITLE,
            tooltipFunction = function(data)
                GAMEPAD_TOOLTIPS:LayoutCompanionOverview(GAMEPAD_QUAD_2_3_TOOLTIP, data)
            end,
            tooltipHeaderData = 
            {
                titleText = GetString(SI_COMPANION_MENU_OVERVIEW_TITLE),
            },
        },
        {
            icon = "EsoUI/Art/Companion/Gamepad/gp_companion_icon_inventory.dds",
            name = SI_COMPANION_MENU_EQUIPMENT_TITLE,
            scene = "companionEquipmentGamepad",
            isNewCallback = function()
                return SHARED_INVENTORY:AreAnyItemsNew(ZO_InventoryUtils_DoesNewItemMatchFilterType, ITEMFILTERTYPE_COMPANION, BAG_BACKPACK)
            end,
        },
        {
            icon = "EsoUI/Art/Companion/Gamepad/gp_companion_icon_skills.dds",
            name = SI_COMPANION_MENU_SKILLS_TITLE,
            scene = "companionSkillsGamepad",
            tooltipFunction = function()
                GAMEPAD_TOOLTIPS:SetStatusLabelText(GAMEPAD_LEFT_TOOLTIP, GetString(SI_GAMEPAD_COMPANION_EQUIPPED_SKILLS))
                GAMEPAD_TOOLTIPS:LayoutEquippedCompanionSkillsPreview(GAMEPAD_LEFT_TOOLTIP)
            end,
            isNewCallback = function()
                if COMPANION_SKILLS_DATA_MANAGER:AreAnySkillLinesNew() then
                    return true
                end
                local companionHotbar = ACTION_BAR_ASSIGNMENT_MANAGER:GetHotbar(HOTBAR_CATEGORY_COMPANION)
                if companionHotbar:AreAnySlotsNew() then
                    return true
                end
                return false
            end
        },
        {
            icon = "EsoUI/Art/Companion/Gamepad/gp_companion_icon_collections.dds",
            name = SI_COMPANION_MENU_COLLECTIONS_TITLE,
            scene = "companionCollectionBookGamepad",
            isNewCallback = function()
                return ZO_COLLECTIBLE_DATA_MANAGER:HasAnyNewCompanionCollectibles()
            end,
        },
    }

    self:RefreshList()
end

function ZO_Companion_Gamepad:RefreshList()
    local list = self:GetMainList()
    list:Clear()

    for _, data in ipairs(self.menuData) do
        local entryData = ZO_GamepadEntryData:New(GetString(data.name), data.icon, nil, nil, data.isNewCallback)
        entryData.sceneName = data.scene
        entryData.tooltipFunction = data.tooltipFunction
        entryData.tooltipHeaderData = data.tooltipHeaderData
        entryData:SetIconTintOnSelection(true)
        entryData:SetIconDisabledTintOnSelection(true)
        list:AddEntry("ZO_GamepadNewMenuEntryTemplate", entryData)
    end

    list:Commit()
end

function ZO_Companion_Gamepad:OnTargetChanged(list, selectedData)
    self:RefreshTargetTooltip(list, selectedData)
end

function ZO_Companion_Gamepad:ResetTooltips()
    --We need to reset the tooltip instead of clearing so that the generic header will hide
    GAMEPAD_TOOLTIPS:Reset(GAMEPAD_QUAD_2_3_TOOLTIP)
    GAMEPAD_TOOLTIPS:Reset(GAMEPAD_LEFT_TOOLTIP)
end

function ZO_Companion_Gamepad:RefreshTargetTooltip(list, selectedData)
    self:ResetTooltips()
    if selectedData and selectedData.tooltipFunction then
        if selectedData.tooltipHeaderData then
            GAMEPAD_TOOLTIPS:ShowGenericHeader(GAMEPAD_QUAD_2_3_TOOLTIP, selectedData.tooltipHeaderData)
        end
        selectedData.tooltipFunction(selectedData)
    end
end

function ZO_Companion_Gamepad:InitializeOutfitSelector()
    self.outfitSelectorControl = self.header:GetNamedChild("OutfitSelector")
    self.outfitSelectorNameLabel = self.outfitSelectorControl:GetNamedChild("OutfitName")
    self.outfitSelectorHeaderFocus = ZO_Outfit_Selector_Header_Focus_Gamepad:New(self.outfitSelectorControl)
    self:SetupHeaderFocus(self.outfitSelectorHeaderFocus)
end

function ZO_Companion_Gamepad:OnEnterHeader()
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_Companion_Gamepad:CanEnterHeader()
    return not self.outfitSelectorControl:IsHidden()
end

function ZO_Companion_Gamepad:OnLeaveHeader()
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_Companion_Gamepad:RefreshHeader()
    local currentlyEquippedOutfitIndex = ZO_OUTFIT_MANAGER:GetEquippedOutfitIndex(GAMEPLAY_ACTOR_CATEGORY_COMPANION)
    if currentlyEquippedOutfitIndex then
        local currentOutfit = ZO_OUTFIT_MANAGER:GetOutfitManipulator(GAMEPLAY_ACTOR_CATEGORY_COMPANION, currentlyEquippedOutfitIndex)
        self.outfitSelectorNameLabel:SetText(currentOutfit:GetOutfitName())
    else
        self.outfitSelectorNameLabel:SetText(GetString(SI_NO_OUTFIT_EQUIP_ENTRY))
    end

    self.outfitSelectorHeaderFocus:Update()
    ZO_GamepadGenericHeader_Refresh(self.header, self.headerData)
end

-----------------------------
-- Global XML Functions
-----------------------------

function ZO_Companion_Gamepad_Initialize(control)
    ZO_COMPANION_GAMEPAD = ZO_Companion_Gamepad:New(control)
end