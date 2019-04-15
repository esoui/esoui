local CONFIRM_SCENE_NAME = "gamepad_smithing_research_confirm"
local CONFIRM_TEMPLATE_NAME = "ZO_GamepadSubMenuEntryTemplate"
ZO_GAMEPAD_CONFIRM_CANCEL_RESEARCH_DIALOG = "GAMEPAD_CONFIRM_CANCEL_RESEARCH"

ZO_GamepadSmithingResearch = ZO_SharedSmithingResearch:Subclass()

function ZO_GamepadSmithingResearch:New(...)
    return ZO_SharedSmithingResearch.New(self, ...)
end

function ZO_GamepadSmithingResearch:Initialize(panelContent, owner, scene)
    local researchPanel = panelContent:GetNamedChild("Research")
    ZO_SharedSmithingResearch.Initialize(self, researchPanel, owner, "ZO_GamepadSmithingResearchSlot")

    self.panelContent = panelContent

    scene:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWING then
            self:PerformDeferredInitialization()
            KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
            local tabBarEntries = self:GenerateTabBarEntries()
            self.focus:Activate()

            self.owner:SetEnableSkillBar(true)

            local savedFilter = self.typeFilter

            local titleString = ZO_GamepadCraftingUtils_GetLineNameForCraftingType(GetCraftingInteractionType())

            ZO_GamepadCraftingUtils_SetupGenericHeader(self.owner, titleString, tabBarEntries)
            ZO_GamepadCraftingUtils_RefreshGenericHeader(self.owner)

            self:SetupTabBar(tabBarEntries, savedFilter)

            self:Refresh()
        elseif newState == SCENE_HIDING then
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
            self.focus:Deactivate()
            self.owner:SetEnableSkillBar(false)
            ZO_GamepadGenericHeader_Deactivate(self.owner.header)
            GAMEPAD_TOOLTIPS:Reset(GAMEPAD_LEFT_TOOLTIP)
        end
    end)

    GAMEPAD_SMITHING_RESEARCH_CONFIRM_SCENE = self.owner:CreateInteractScene(CONFIRM_SCENE_NAME)
    GAMEPAD_SMITHING_RESEARCH_CONFIRM_SCENE:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWING then
            local function AddEntry(data)
                local entry = ZO_GamepadEntryData:New(data.name)
                entry:InitializeCraftingInventoryVisualData(data.bag, data.index, data.stack)
                self.confirmList:AddEntry(CONFIRM_TEMPLATE_NAME, entry)
            end

            local function IsResearchableItem(bagId, slotIndex)
                return ZO_SharedSmithingResearch.IsResearchableItem(bagId, slotIndex, self.confirmCraftingType, self.confirmResearchLineIndex, self.confirmTraitIndex)
            end

            local confirmPanel = self.panelContent:GetNamedChild("Confirm")
            confirmPanel:GetNamedChild("SelectionText"):SetText(GetString(SI_GAMEPAD_SMITHING_RESEARCH_SELECT_ITEM))

            self.confirmList:Clear()

            local virtualInventoryList = PLAYER_INVENTORY:GenerateListOfVirtualStackedItems(INVENTORY_BACKPACK, IsResearchableItem)
            PLAYER_INVENTORY:GenerateListOfVirtualStackedItems(INVENTORY_BANK, IsResearchableItem, virtualInventoryList)

            for itemId, itemInfo in pairs(virtualInventoryList) do
                itemInfo.name = zo_strformat(SI_TOOLTIP_ITEM_NAME, GetItemName(itemInfo.bag, itemInfo.index))
                AddEntry(itemInfo)
            end
            self.confirmList:Commit()

            self.confirmList:Activate()
            KEYBIND_STRIP:AddKeybindButtonGroup(self.confirmKeybindStripDescriptor)
        elseif newState == SCENE_HIDING then
            self.confirmList:Deactivate()
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.confirmKeybindStripDescriptor)
            GAMEPAD_TOOLTIPS:Reset(GAMEPAD_LEFT_TOOLTIP)
        end
    end)
end

function ZO_GamepadSmithingResearch:PerformDeferredInitialization()
    if self.keybindStripDescriptor then return end

    self:InitializeResearchLineList(ZO_HorizontalScrollList_Gamepad, "ZO_GamepadSmithingResearchListSlot")
    self:InitializeKeybindStripDescriptors()
    self:InitializeConfirmList()
    self:InitializeFocusItems()
    self:InitializeConfirmDestroyDialog()
    self:AnchorTimerBar()
end

function ZO_GamepadSmithingResearch:AnchorTimerBar()
    local timerBar = self.control:GetNamedChild("TimerBar")
    local researchList = self.control:GetNamedChild("ResearchLineList")

    timerBar:SetParent(researchList)

    timerBar:ClearAnchors()

    local newAnchor = ZO_Anchor:New(TOPLEFT, researchList:GetNamedChild("List"), BOTTOMLEFT)
    newAnchor:AddToControl(timerBar)

    newAnchor = ZO_Anchor:New(TOPRIGHT, researchList:GetNamedChild("List"), BOTTOMRIGHT, 0, 8)
    newAnchor:AddToControl(timerBar)
end

function ZO_GamepadSmithingResearch:GenerateTabBarEntries()
    local tabBarEntries = {}
    local function AddTabEntry(filterType)
        if ZO_CraftingUtils_CanSmithingFilterBeCraftedHere(filterType) then
            local entry = {}
            entry.text = GetString("SI_SMITHINGFILTERTYPE", filterType)
            entry.callback = function()
                self.typeFilter = filterType
                self:HandleDirtyEvent()
            end
            entry.mode = filterType

            table.insert(tabBarEntries, entry)
        end
    end


    AddTabEntry(SMITHING_FILTER_TYPE_WEAPONS)
    AddTabEntry(SMITHING_FILTER_TYPE_ARMOR)
    AddTabEntry(SMITHING_FILTER_TYPE_JEWELRY)

    return tabBarEntries
end

function ZO_GamepadSmithingResearch:SetupTabBar(tabBarEntries, savedFilter)
    if #tabBarEntries == 1 then
        self.typeFilter = tabBarEntries[1].mode
    else
        ZO_GamepadGenericHeader_Activate(self.owner.header)

        local filterFound = false

        for index, entry in pairs(tabBarEntries) do
            if savedFilter == entry.mode then
                self.typeFilter = savedFilter
                ZO_GamepadGenericHeader_SetActiveTabIndex(self.owner.header, index)
                filterFound = true
                break
            end
        end

        if not filterFound then
            self.typeFilter = tabBarEntries[1].mode
            ZO_GamepadGenericHeader_SetActiveTabIndex(self.owner.header, 1)
        end
    end
end

function ZO_GamepadSmithingResearch:RefreshAvailableFilters(dontReselect)
end

function ZO_GamepadSmithingResearch:RefreshCurrentResearchStatusDisplay(currentlyResearching, maxResearchable)
    ZO_GamepadCraftingUtils_SetGenericHeaderData2(self.owner, GetString(SI_GAMEPAD_SMITHING_CURRENT_RESEARCH_HEADER), zo_strformat(SI_GAMEPAD_SMITHING_CURRENT_RESEARCH_AMOUNT, currentlyResearching, maxResearchable))
    ZO_GamepadCraftingUtils_RefreshGenericHeaderData(self.owner)
end

function ZO_GamepadSmithingResearch:InitializeKeybindStripDescriptors()
    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,

        -- Perform research
        {
            keybind = "UI_SHORTCUT_PRIMARY",

            name = function()
                return GetString(SI_ITEM_ACTION_RESEARCH)
            end,

            callback = function()
                self:Research()
            end,

            enabled = function()
                if not ZO_CraftingUtils_IsPerformingCraftProcess() then
                    return self:IsResearchable()
                end
            end
        },

        -- Cancel research
        {
            keybind = "UI_SHORTCUT_SECONDARY",

            name = function()
                return GetString(SI_CRAFTING_CANCEL_RESEARCH)
            end,

            callback = function()
                self:CancelResearch()
            end,

            visible = function()
                if not ZO_CraftingUtils_IsPerformingCraftProcess() then
                    return self:CanCancelResearch()
                end
            end
        },
    }

    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.keybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON)
    ZO_CraftingUtils_ConnectKeybindButtonGroupToCraftingProcess(self.keybindStripDescriptor)

    local function ConfirmResearch()
        local targetData = self.confirmList:GetTargetData()
        if targetData then
            local _, _, _, timeRequiredForNextResearchSecs = GetSmithingResearchLineInfo(self.confirmCraftingType, self.confirmResearchLineIndex)
            local formattedTime = ZO_FormatTime(timeRequiredForNextResearchSecs, TIME_FORMAT_STYLE_COLONS, TIME_FORMAT_PRECISION_TWELVE_HOUR)
            ZO_Dialogs_ShowGamepadDialog("GAMEPAD_CONFIRM_RESEARCH_ITEM", { bagId = targetData.bagId, slotIndex = targetData.slotIndex, owner = self }, { mainTextParams = { formattedTime }})
        end
    end

    -- Confirm research keybind descriptor.
    self.confirmKeybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,

        {
            keybind = "UI_SHORTCUT_PRIMARY",
            name = GetString(SI_SMITHING_RESEARCH_DIALOG_CONFIRM),
            callback = ConfirmResearch,
            sound = SOUNDS.SMITHING_START_RESEARCH,
        },
    }

    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.confirmKeybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON)
end

function ZO_GamepadSmithingResearch:InitializeConfirmDestroyDialog()
    local function ReleaseDialog()
        ZO_Dialogs_ReleaseDialogOnButtonPress(ZO_GAMEPAD_CONFIRM_CANCEL_RESEARCH_DIALOG)
    end

    ZO_Dialogs_RegisterCustomDialog(ZO_GAMEPAD_CONFIRM_CANCEL_RESEARCH_DIALOG,
    {
        blockDialogReleaseOnPress = true,
        canQueue = true,

        gamepadInfo = 
        {
            dialogType = GAMEPAD_DIALOGS.BASIC,
            allowRightStickPassThrough = true,
        },

        setup = function(dialog)
            self.destroyConfirmText = nil
            dialog:setupFunc()
        end,

        title =
        {
            text = SI_CRAFTING_CONFIRM_CANCEL_RESEARCH_TITLE,
        },

        mainText = 
        {
            text = SI_GAMEPAD_CRAFTING_CONFIRM_CANCEL_RESEARCH_DESCRIPTION,
        },
      
        buttons =
        {
            {
                onShowCooldown = 2000,
                keybind = "DIALOG_PRIMARY",
                text = GetString(SI_YES),
                callback = function(dialog)
                    local data = dialog.data
                    CancelSmithingTraitResearch(data.craftingType, data.researchLineIndex, data.traitIndex)
                    ReleaseDialog()
                end,
            },
            {
                keybind = "DIALOG_NEGATIVE",
                text = GetString(SI_NO),
                callback = function()
                    ReleaseDialog()
                end,
            },
        }
    })
end

function ZO_GamepadSmithingResearch:AcceptResearch(bagId, slotIndex)
    ResearchSmithingTrait(bagId, slotIndex)
    --go back to the trait selection screen
    SCENE_MANAGER:HideCurrentScene()
end

function ZO_GamepadSmithingResearch:InitializeConfirmList()
    self.confirmList = ZO_GamepadVerticalItemParametricScrollList:New(self.panelContent:GetNamedChild("Confirm"):GetNamedChild("List"))
    self.confirmList:SetAlignToScreenCenter(true)
    self.confirmList:AddDataTemplate(CONFIRM_TEMPLATE_NAME, ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction, nil, "Entry")

    local function OnEntryChanged(list, selectedData)
        if selectedData then
            GAMEPAD_TOOLTIPS:LayoutBagItem(GAMEPAD_LEFT_TOOLTIP, selectedData.bagId, selectedData.slotIndex)
            if selectedData.isEquippedInCurrentCategory or selectedData.isEquippedInAnotherCategory then
                GAMEPAD_TOOLTIPS:SetStatusLabelText(GAMEPAD_LEFT_TOOLTIP, GetString(SI_GAMEPAD_EQUIPPED_ITEM_HEADER))
                self:UpdateTooltipEquippedIndicatorText(self.selectedEquippedIndicator, selectedData.slotIndex)
            else
                GAMEPAD_TOOLTIPS:ClearStatusLabel(GAMEPAD_LEFT_TOOLTIP)
            end
        else
            GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP)
        end
    end

    self.confirmList:SetOnSelectedDataChangedCallback(OnEntryChanged)

    ZO_Gamepad_AddListTriggerKeybindDescriptors(self.confirmKeybindStripDescriptor, self.confirmList)
end

function ZO_GamepadSmithingResearch:InitializeFocusItems()
    self.focus = ZO_GamepadFocus:New(self.panelContent)
end

function ZO_GamepadSmithingResearch:RefreshFocusItems(focusIndex)
    local function AddEntry(control, highlight, activate, deactivate)
        self.focus:AddEntry(
        {
            control = control,
            highlight = highlight,
            activate = activate,
            deactivate = deactivate,
        })
    end

    local ACTIVE = true

    local function UpdateBorderHighlight(focusedControl, active)
        focusedControl.inactiveBG:SetHidden(active)
        focusedControl.activeBG:SetHidden(not active)
    end

    local function ListActivate(control, data)
        control:Activate()
        UpdateBorderHighlight(control:GetControl():GetParent(), ACTIVE)
    end

    local function ListDeactivate(control, data)
        control:Deactivate()
        UpdateBorderHighlight(control:GetControl():GetParent(), not ACTIVE)
    end

    AddEntry(self.researchLineList, self.control:GetNamedChild("ResearchLineList").focusTexture, ListActivate, ListDeactivate)

    local function Activate(control)
        self:OnResearchRowActivate(control)
    end

    local function Deactivate(control)
        self:OnResearchRowDeactivate(control)
    end

    local entries = self.slotPool:GetActiveObjects()
    for _, v in pairs(entries) do
        AddEntry(v, v:GetNamedChild("Highlight"), Activate, Deactivate)
    end

    if focusIndex then
        self.focus:SetFocusByIndex(focusIndex)
    else
        self.focus:SetFocusByIndex(1)
    end
end

function ZO_GamepadSmithingResearch:OnControlsAcquired()
    ZO_SharedSmithingResearch.OnControlsAcquired(self)
    local savedFocusIndex = self.focus:GetFocus()
    self.focus:RemoveAllEntries()
    self:RefreshFocusItems(savedFocusIndex)
end

function ZO_GamepadSmithingResearch:SetupTooltip(row)
    GAMEPAD_TOOLTIPS:LayoutResearchSmithingItem(GAMEPAD_LEFT_TOOLTIP, GetString("SI_ITEMTRAITTYPE", row.traitType), row.traitDescription, row.traitResearchSourceDescription, row.traitMaterialSourceDescription)
end

function ZO_GamepadSmithingResearch:ClearTooltip(row)
    GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP)
end

function ZO_GamepadSmithingResearch:Research()
    local canResearchCurrentTrait = self:CanResearchCurrentTraitLine()

    if self.atMaxResearchLimit then
        local craftingSkillLineData = SKILLS_DATA_MANAGER:GetCraftingSkillLineData(GetCraftingInteractionType())
        ZO_Alert(UI_ALERT_CATEGORY_ALERT, SOUNDS.NEGATIVE_CLICK, SI_SMITHING_RESEARCH_ALL_SLOTS_IN_USE, craftingSkillLineData:GetName())
    elseif not canResearchCurrentTrait then
        ZO_Alert(UI_ALERT_CATEGORY_ALERT, SOUNDS.NEGATIVE_CLICK, SI_SMITHING_RESEARCH_TRAIT_ALREADY_BEING_RESEARCHED, self.traitLineText)
    else
        self.confirmCraftingType, self.confirmResearchLineIndex, self.confirmTraitIndex = self.activeRow.craftingType, self.activeRow.researchLineIndex, self.activeRow.traitIndex
        SCENE_MANAGER:Push(CONFIRM_SCENE_NAME)
    end
end

function ZO_GamepadSmithingResearch:GetResearchTimeString(count, time)
    local timeWithIcon = zo_iconTextFormatNoSpace("EsoUI/Art/Miscellaneous/Gamepad/gp_icon_timer32.dds", "100%", "100%", time)
    return zo_strformat(SI_GAMEPAD_SMITHING_RESEARCH_TIME_FOR_NEXT, count, timeWithIcon)
end

function ZO_GamepadSmithingResearch:GetExtraInfoColor()
    return ZO_SELECTED_TEXT:UnpackRGBA()
end

function ZO_GamepadSmithingResearch:SetupTraitDisplay(slotControl, researchLine, known, duration, traitIndex)
    local iconControl = GetControl(slotControl, "Icon")

    if known then
        slotControl.nameLabel:SetColor(ZO_NORMAL_TEXT:UnpackRGBA())

        slotControl.statusLabel:SetText("")

        slotControl.timerIcon:SetHidden(true)

        iconControl:SetDesaturation(0)
        iconControl:SetAlpha(1)
    elseif duration then
        slotControl.nameLabel:SetColor(ZO_SECOND_CONTRAST_TEXT:UnpackRGBA())

        slotControl.statusLabel:SetText(GetString(SI_SMITHING_RESEARCH_IN_PROGRESS))
        slotControl.statusLabel:SetColor(ZO_SECOND_CONTRAST_TEXT:UnpackRGBA())

        slotControl.timerIcon:SetHidden(false)
        slotControl.timerIcon:SetColor(ZO_SECOND_CONTRAST_TEXT:UnpackRGBA())

        iconControl:SetDesaturation(0)
        iconControl:SetAlpha(.3)
    elseif researchLine.itemTraitCounts and researchLine.itemTraitCounts[traitIndex] then
        slotControl.nameLabel:SetColor(ZO_SELECTED_TEXT:UnpackRGBA())

        slotControl.statusLabel:SetText(GetString(SI_SMITHING_RESEARCH_RESEARCHABLE))
        slotControl.statusLabel:SetColor(ZO_SELECTED_TEXT:UnpackRGBA())

        slotControl.timerIcon:SetHidden(true)

        iconControl:SetDesaturation(0)
        iconControl:SetAlpha(1)

        slotControl.researchable = true
    else
        slotControl.nameLabel:SetColor(ZO_DISABLED_TEXT:UnpackRGBA())

        slotControl.statusLabel:SetText(GetString(SI_SMITHING_RESEARCH_UNKNOWN))
        slotControl.statusLabel:SetColor(ZO_DISABLED_TEXT:UnpackRGBA())

        slotControl.timerIcon:SetHidden(true)

        iconControl:SetDesaturation(1)
        iconControl:SetAlpha(1)
    end
end