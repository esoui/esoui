-----------------------------------
-- GuildHeraldryManager Gamepad
-----------------------------------
local CATEGORY_TEMPLATE_NAME = "ZO_GamepadMenuEntryTemplate"

ZO_GUILD_HERALDRY_STYLE_GAMEPAD_HEADER_TEMPLATE_HEIGHT = 60
ZO_GUILD_HERALDRY_STYLE_GAMEPAD_LIST_VERT_PADDING = ZO_GAMEPAD_CONTENT_VERT_OFFSET_PADDING + 40
ZO_GUILD_HERALDRY_STYLE_GAMEPAD_ICON_SIZE = ZO_GAMEPAD_DEFAULT_SELECTION_ICON_SIZE + 11
ZO_GUILD_HERALDRY_STYLE_GAMEPAD_GRID_PADDING = 30

ZO_GUILD_HERALDRY_COLOR_GAMEPAD_ICON_SIZE = 43
ZO_GUILD_HERALDRY_COLOR_GAMEPAD_CHECKMARK_SIZE = 32

ZO_GuildHeraldryManager_Gamepad = ZO_Object.MultiSubclass(ZO_GamepadMultiFocusArea_Manager, ZO_GuildHeraldryManager_Shared)

function ZO_GuildHeraldryManager_Gamepad:New(...)
    return ZO_GuildHeraldryManager_Shared.New(self, ...)
end

function ZO_GuildHeraldryManager_Gamepad:SetMainList(list)
    self.categoryList = list
end

function ZO_GuildHeraldryManager_Gamepad:SetOwningScreen(owningScreen)
    self.owningScreen = owningScreen
end

local function OnBlockingSceneActivated()
    GUILD_HERALDRY_GAMEPAD:AttemptSaveAndExit()
end

function ZO_GuildHeraldryManager_Gamepad:Initialize(control)
    local function StyleGridEntrySetup(control, data, list)
        control:GetNamedChild("Icon"):SetTexture(data.icon)
        control:GetNamedChild("CurrentIconIndicator"):SetHidden(not self:IsViewingStyleCategoryWithSelection() or not data.checked)
    end

    local function DyeSwatchGridEntrySetup(control, data, list)
        control:SetColor(ZO_DYEING_SWATCH_INDEX, data.r, data.g, data.b)
        control:SetSurfaceHidden(ZO_DYEING_LOCK_INDEX, data.known)
        control:SetSurfaceHidden(ZO_DYEING_NEW_INDEX, not data:IsNew())
        control:GetNamedChild("Checkmark"):SetHidden(not data.checked)
        data:SetControl(control)

        local DONT_SKIP_ANIM = false
        data:UpdateSelectedState(DONT_SKIP_ANIM, data.checked)
    end

    local function GeneralGridEntryReset(control)
        ZO_ObjectPool_DefaultResetControl(control)
    end

    local templateData =
    {
        gridListClass = ZO_GridScrollList_Gamepad,
        styleEntryTemplate = "ZO_GuildHeraldry_Style_Gamepad",
        styleEntryWidth = ZO_GUILD_HERALDRY_STYLE_GAMEPAD_ICON_SIZE,
        styleEntryHeight = ZO_GUILD_HERALDRY_STYLE_GAMEPAD_ICON_SIZE,
        styleGridPadding = ZO_GUILD_HERALDRY_STYLE_GAMEPAD_GRID_PADDING,
        styleEntrySetup = StyleGridEntrySetup,
        styleEntryReset = GeneralGridEntryReset,
        colorEntryTemplate = "ZO_GuildHeraldry_Color_Gamepad",
        colorEntryWidth = ZO_GUILD_HERALDRY_COLOR_GAMEPAD_ICON_SIZE,
        colorEntryHeight = ZO_GUILD_HERALDRY_COLOR_GAMEPAD_ICON_SIZE,
        colorEntrySetup = DyeSwatchGridEntrySetup,
        colorEntryReset = GeneralGridEntryReset,
        headerTemplate = "ZO_GuildHeraldry_Style_Gamepad_Header_Template",
        headerHeight = ZO_GUILD_HERALDRY_STYLE_GAMEPAD_HEADER_TEMPLATE_HEIGHT,
    }

    ZO_GamepadMultiFocusArea_Manager.Initialize(self)
    ZO_GuildHeraldryManager_Shared.Initialize(self, control, ZO_GAMEPAD_CURRENCY_OPTIONS, templateData)

    self:InitializeStyleGridList()
    self:InitializeColorGridList()
    self:InitializeMultiFocusAreas()

    self.stylesHeader = self.styleGridListControl:GetNamedChild("StylesHeader")

    self.mode = ZO_HERALDRY_CATEGORY_MODE

    GUILD_HERALDRY_GAMEPAD_FRAGMENT = ZO_FadeSceneFragment:New(self.control, true)
    GUILD_HERALDRY_GAMEPAD_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWING then
            self:PerformDeferredInitialization()

            MAIN_MENU_MANAGER:SetBlockingScene("guildHeraldry_gamepad", OnBlockingSceneActivated)

            self.pendingTransaction = false
            self:PopulateCategories()
            self:PopulateStyleCategoryLists() -- Depends on PopulateCategories being called first.
            self.categoryList:Activate()
            KEYBIND_STRIP:AddKeybindButtonGroup(self.categoryKeybindStripDescriptor)

            self:RegisterEvents()
            StartHeraldryCustomization(self.guildId)

            KEYBIND_STRIP:RemoveDefaultExit()
            KEYBIND_STRIP:AddKeybindButtonGroup(self.globalKeybindStripDescriptor)
        elseif newState == SCENE_HIDING then
            EndHeraldryCustomization()
            self:UnregisterEvents()
            self:SetDirectionalInputEnabled(false)
            self:SetPendingExit(false)

            -- Remove all keybind groups that may have been added
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.globalKeybindStripDescriptor)
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.categoryKeybindStripDescriptor)
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.colorKeybindStripDescriptor)
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.styleCategoryKeybindStripDescriptor)
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.styleKeybindStripDescriptor)
            KEYBIND_STRIP:RestoreDefaultExit()
            self.activeKeybindStripDescriptor = nil
            GAMEPAD_NAV_QUADRANT_1_BACKGROUND_FRAGMENT:TakeFocus()

            -- Deactivate the active element to remove the tigger keybinds associated with the active control manager
            if self.categoryList:IsActive() then
                self.categoryList:Deactivate()
            end
            if self.colorGridList:IsActive() then
                self.colorGridList:Deactivate()
            end
            self:DeactivateCurrentFocus()
        end
    end)
end

function ZO_GuildHeraldryManager_Gamepad:InitializeColorGridList()
    ZO_GuildHeraldryManager_Shared.InitializeColorGridList(self)

    self.colorGridList:SetOnSelectedDataChangedCallback(function(previousData, newData) self:OnColorGridSelectedDataChanged(previousData, newData) end)
end

function ZO_GuildHeraldryManager_Gamepad:InitializeMultiFocusAreas()
    local function StyleCategoryActivateCallback()
        local list = self.bgStyleCatList
        if self.activeData.mode == ZO_HERALDRY_CREST_STYLE_MODE then
            list = self.crestStyleCatList
        end

        list:Activate()
        list.control.highlight:SetHidden(false)
        SCREEN_NARRATION_MANAGER:QueueCustomEntry("guildHeraldryStyleSpinner")
    end
    local function StyleCategoryDeactivateCallback()
        local list = self.bgStyleCatList
        if self.activeData.mode == ZO_HERALDRY_CREST_STYLE_MODE then
            list = self.crestStyleCatList
        end

        list:Deactivate()
        list.control.highlight:SetHidden(true)
    end
    self.styleCategoryArea = ZO_GamepadMultiFocusArea_Base:New(self, StyleCategoryActivateCallback, StyleCategoryDeactivateCallback)

    local FOREGO_DIRECTIONAL_INPUT = true
    local function StyleGridActivateCallback()
        self.styleGridList:Activate(FOREGO_DIRECTIONAL_INPUT)
    end

    local function StyleGridDeactivateCallback()
        self.styleGridList:Deactivate(FOREGO_DIRECTIONAL_INPUT)
    end
    self.styleGridArea = ZO_GamepadInteractiveSortFilterFocusArea_Grid:New(self, StyleGridActivateCallback, StyleGridDeactivateCallback)
    self.styleGridArea.gridList = self.styleGridList

    self:AddNextFocusArea(self.styleCategoryArea)
    self:AddNextFocusArea(self.styleGridArea)

    local narrationInfo =
    {
        canNarrate = function()
            if GUILD_HERALDRY_GAMEPAD_FRAGMENT:IsShowing() then
                local list = nil
                if self.mode == ZO_HERALDRY_BG_STYLE_MODE then
                    list = self.bgStyleCatList
                elseif self.mode == ZO_HERALDRY_CREST_STYLE_MODE then
                    list = self.crestStyleCatList
                end
                return list and list:IsActive() or false
            end
            return false
        end,
        selectedNarrationFunction = function()
            local list = self.bgStyleCatList
            if self.activeData.mode == ZO_HERALDRY_CREST_STYLE_MODE then
                list = self.crestStyleCatList
            end
            local data = list:GetSelectedData()
            if data then
                return ZO_FormatSpinnerNarrationText(GetString(SI_GUILD_HERALDRY_TYPE_HEADER), data.categoryName)
            end
        end,
        additionalInputNarrationFunction = function()
            local list = self.bgStyleCatList
            if self.activeData.mode == ZO_HERALDRY_CREST_STYLE_MODE then
                list = self.crestStyleCatList
            end
            local narrationFunction = list:GetAdditionalInputNarrationFunction()
            return narrationFunction()
        end,
    }
    SCREEN_NARRATION_MANAGER:RegisterCustomObject("guildHeraldryStyleSpinner", narrationInfo)
end

function ZO_GuildHeraldryManager_Gamepad:PerformDeferredInitialization()
    if self.deferredInitialized then return end
    self.deferredInitialized = true

    self:InitializeStyleCategoryLists(ZO_HorizontalScrollList_Gamepad, "ZO_GuildHeraldry_StyleCategory_Gamepad")
    local function OnSelectedBGStyleDataChangedCallback()
        if self.bgStyleCatList:IsActive() then
            SCREEN_NARRATION_MANAGER:QueueCustomEntry("guildHeraldryStyleSpinner")
        end
    end
    self.bgStyleCatList:SetOnSelectedDataChangedCallback(OnSelectedBGStyleDataChangedCallback)

    local function OnSelectedCrestStyleDataChangedCallback()
        if self.crestStyleCatList:IsActive() then
            SCREEN_NARRATION_MANAGER:QueueCustomEntry("guildHeraldryStyleSpinner")
        end
    end
    self.crestStyleCatList:SetOnSelectedDataChangedCallback(OnSelectedCrestStyleDataChangedCallback)
    self:InitializeKeybindStripDescriptors()

    self.styleCategoryArea:SetKeybindDescriptor(self.styleCategoryKeybindStripDescriptor)
    self.styleGridArea:SetKeybindDescriptor(self.styleKeybindStripDescriptor)

    self.categoryList:Activate()
    KEYBIND_STRIP:AddKeybindButtonGroup(self.categoryKeybindStripDescriptor)

    self.costFn = function(control)
        ZO_CurrencyControl_SetSimpleCurrency(control, CURT_MONEY, self.selectedData.cost, self.currencyOptions)
        return true
    end
    self.costFnNarration = function(control)
        return ZO_Currency_FormatGamepad(CURT_MONEY, self.selectedData.cost, ZO_CURRENCY_FORMAT_AMOUNT_NAME)
    end
end

function ZO_GuildHeraldryManager_Gamepad:RegisterEvents()
    self.control:RegisterForEvent(EVENT_HERALDRY_CUSTOMIZATION_START, function(eventCode)
        self.initialized = true
        self:SetSelectedHeraldryIndices()
        self.categoryList:RefreshVisible()
    end)

    self.control:RegisterForEvent(EVENT_HERALDRY_CUSTOMIZATION_END, function(eventCode)
        self.initialized = false
    end)

    self.control:RegisterForEvent(EVENT_HERALDRY_SAVED, function(eventCode)
        self:SetSelectedHeraldryIndices()
        ZO_AlertNoSuppression(UI_ALERT_CATEGORY_ALERT, SOUNDS.GUILD_HERALDRY_APPLIED, SI_GAMEPAD_GUILD_HERALDRY_SAVED)
        self.pendingTransaction = false
        self:UpdateKeybindGroups()
        self.categoryList:RefreshVisible()
    end)

    self.control:RegisterForEvent(EVENT_HERALDRY_FUNDS_UPDATED, function(eventCode)
        self:UpdateKeybindGroups()
    end)
end

function ZO_GuildHeraldryManager_Gamepad:UnregisterEvents()
    self.control:UnregisterForEvent(EVENT_HERALDRY_CUSTOMIZATION_START)
    self.control:UnregisterForEvent(EVENT_HERALDRY_CUSTOMIZATION_END)
    self.control:UnregisterForEvent(EVENT_HERALDRY_SAVED)
    self.control:UnregisterForEvent(EVENT_HERALDRY_FUNDS_UPDATED)
end

function ZO_GuildHeraldryManager_Gamepad:OnColorGridSelectedDataChanged(previousData, newData)
    local DONT_SKIP_ANIM = false

    if previousData and previousData.control then
        previousData.mousedOver = false
        previousData:UpdateSelectedState(DONT_SKIP_ANIM, previousData.checked)
    end

    if newData then
        if newData.control then
            newData.mousedOver = true
            newData:UpdateSelectedState(DONT_SKIP_ANIM, newData.checked)
        end
    end
end

function ZO_GuildHeraldryManager_Gamepad:GetPurchaseDialogName()
    return "CONFIRM_HERALDRY_PURCHASE_GAMEPAD"
end

function ZO_GuildHeraldryManager_Gamepad:GetApplyChangesDialogName()
    return "CONFIRM_HERALDRY_APPLY_CHANGES_GAMEPAD"
end

function ZO_GuildHeraldryManager_Gamepad:IsCurrentBlockingScene()
    return MAIN_MENU_MANAGER:GetBlockingSceneName() == "guildHeraldry_gamepad"
end

function ZO_GuildHeraldryManager_Gamepad:AttemptSaveAndExit(showBaseScene)
    if self.pendingTransaction then
        return
    end

    ZO_GuildHeraldryManager_Shared.AttemptSaveAndExit(self, showBaseScene)
end

function ZO_GuildHeraldryManager_Gamepad:ConfirmExit(showBaseScene)
    if showBaseScene then
        SCENE_MANAGER:ShowBaseScene()
    else
        SCENE_MANAGER:HideCurrentScene()
    end
    self:SetPendingExit(false)
    MAIN_MENU_MANAGER:ClearBlockingScene(OnBlockingSceneActivated)
end

function ZO_GuildHeraldryManager_Gamepad:CancelExit()
    MAIN_MENU_MANAGER:CancelBlockingSceneNextScene()
    self:SetPendingExit(false)
end

function ZO_GuildHeraldryManager_Gamepad:NoChoiceExitCallback()
    self:ConfirmExit()
end

function ZO_GuildHeraldryManager_Gamepad:InitializeKeybindStripDescriptors()
    self.globalKeybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,

        -- Apply changes.
        {
            keybind = "UI_SHORTCUT_SECONDARY",
            order = 100,

            name = function()
                local pendingCost = GetPendingHeraldryCost()
                local heraldryFunds = GetHeraldryGuildBankedMoney()
                local gamepadGoldIconMarkup =  ZO_Currency_GetGamepadFormattedCurrencyIcon(CURT_MONEY)

                if IsCreatingHeraldryForFirstTime() then
                    if heraldryFunds and pendingCost <= heraldryFunds then
                        return zo_strformat(SI_GAMEPAD_GUILD_HERALDRY_PURCHASE_HERALDRY, ZO_CurrencyControl_FormatCurrency(pendingCost), gamepadGoldIconMarkup)
                    else
                        return zo_strformat(SI_GAMEPAD_GUILD_HERALDRY_PURCHASE_HERALDRY_NOT_ENOUGH, ZO_ERROR_COLOR:Colorize(ZO_CurrencyControl_FormatCurrency(pendingCost)), gamepadGoldIconMarkup)
                    end
                else
                    if heraldryFunds and pendingCost <= heraldryFunds then
                        return zo_strformat(SI_GAMEPAD_GUILD_HERALDRY_APPLY_CHANGES, ZO_CurrencyControl_FormatCurrency(pendingCost), gamepadGoldIconMarkup)
                    else
                        return zo_strformat(SI_GAMEPAD_GUILD_HERALDRY_APPLY_CHANGES_NOT_ENOUGH, ZO_ERROR_COLOR:Colorize(ZO_CurrencyControl_FormatCurrency(pendingCost)), gamepadGoldIconMarkup)
                    end
                end
            end,

            narrationOverrideName  = function()
                local pendingCost = GetPendingHeraldryCost()
                if IsCreatingHeraldryForFirstTime() then
                    return zo_strformat(SI_GAMEPAD_GUILD_HERALDRY_PURCHASE_HERALDRY, ZO_Currency_FormatGamepad(CURT_MONEY, pendingCost, ZO_CURRENCY_FORMAT_AMOUNT_NAME))
                else
                    return zo_strformat(SI_GAMEPAD_GUILD_HERALDRY_APPLY_CHANGES, ZO_Currency_FormatGamepad(CURT_MONEY, pendingCost, ZO_CURRENCY_FORMAT_AMOUNT_NAME))
                end
            end,

            callback = function()
                local pendingCost = GetPendingHeraldryCost()
                local heraldryFunds = GetHeraldryGuildBankedMoney()
                if heraldryFunds and pendingCost <= heraldryFunds then
                    if IsCreatingHeraldryForFirstTime() then
                        self:ConfirmHeraldryPurchase()
                    else
                        self:ConfirmHeraldryApplyChanges()
                    end
                end
            end,

            visible = function()
                return HasPendingHeraldryChanges() and not self.pendingTransaction
            end,
        },

        -- Custom Exit
        {
            --Ethereal binds show no text, the name field is used to help identify the keybind when debugging. This text does not have to be localized.
            name = "Gamepad Guild Heraldry Exit",
            keybind = "UI_SHORTCUT_EXIT",
            ethereal = true,
            callback =  function()
                local SHOW_BASE_SCENE = true
                self:AttemptSaveAndExit(SHOW_BASE_SCENE)
            end,
        },
    }

    self.categoryKeybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,

        -- Select category.
        {
            keybind = "UI_SHORTCUT_PRIMARY",

            name = function()
                return GetString(SI_GAMEPAD_SELECT_OPTION)
            end,

            sound = SOUNDS.GAMEPAD_MENU_FORWARD,

            callback = function()
                self.categoryList:Deactivate()
                KEYBIND_STRIP:RemoveKeybindButtonGroup(self.categoryKeybindStripDescriptor)
                if self.activeData.mode == ZO_HERALDRY_COLOR_MODE then
                    self.colorGridList:Activate()
                    KEYBIND_STRIP:AddKeybindButtonGroup(self.colorKeybindStripDescriptor)
                else
                    self:SetDirectionalInputEnabled(true)
                    self:ActivateFocusArea(self.styleCategoryArea)
                end
            end,
        },
    }

    ZO_Gamepad_AddListTriggerKeybindDescriptors(self.categoryKeybindStripDescriptor, self.categoryList)
    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.categoryKeybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON, function()
        GAMEPAD_GUILD_HUB:SetEnterInSingleGuildList(true)
        self:AttemptSaveAndExit()
    end)

    self.colorKeybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,

        -- Select color.
        {
            keybind = "UI_SHORTCUT_PRIMARY",

            name = function()
                return GetString(SI_GAMEPAD_SELECT_OPTION)
            end,

            callback = function()
                local selectedData = self.colorGridList:GetSelectedData()
                self:SelectColor(selectedData.colorIndex)
            end,
        },
    }

    ZO_Gamepad_AddBackNavigationKeybindDescriptorsWithSound(self.colorKeybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON, function()
        -- We need to call this to store the current selections as we will draw from this source to refresh the grid information
        ZO_GuildHeraldryManager_Shared.SetSelectedHeraldryIndices(self)

        self.colorGridList:Deactivate()
        KEYBIND_STRIP:RemoveKeybindButtonGroup(self.colorKeybindStripDescriptor)

        self.categoryList:Activate()
        KEYBIND_STRIP:AddKeybindButtonGroup(self.categoryKeybindStripDescriptor)
    end)

    self.styleCategoryKeybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
    }

    ZO_Gamepad_AddBackNavigationKeybindDescriptorsWithSound(self.styleCategoryKeybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON, function()
        self:SetDirectionalInputEnabled(false)
        self:SelectFocusArea(nil)

        self.categoryList:Activate()
        KEYBIND_STRIP:AddKeybindButtonGroup(self.categoryKeybindStripDescriptor)
    end)

    self.styleKeybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,

        -- Select style.
        {
            keybind = "UI_SHORTCUT_PRIMARY",

            name = function()
                return GetString(SI_GAMEPAD_SELECT_OPTION)
            end,

            callback = function()
                local selectedData = self.styleGridList:GetSelectedData()
                self:SelectStyle(selectedData.index)
            end
        },
    }

    ZO_Gamepad_AddBackNavigationKeybindDescriptorsWithSound(self.styleKeybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON, function()
        ZO_GuildHeraldryManager_Shared.SetSelectedHeraldryIndices(self) -- This makes sure that the viewCategory is correct for crestData so that icons don't appear as missing or incorrect in the category list
        self:ActivateFocusArea(self.styleCategoryArea)
    end)
end

function ZO_GuildHeraldryManager_Gamepad:UpdateKeybindGroups()
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.globalKeybindStripDescriptor)
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.activeKeybindStripDescriptor)
end

function ZO_GuildHeraldryManager_Gamepad:OnTargetChanged(list, selectedData, oldSelectedData)
    self:OnCategorySelected(selectedData)
    self.selectedData = selectedData
    self.owningScreen:RefreshHeader()
end

function ZO_GuildHeraldryManager_Gamepad:GetPurchaseCost()
    if self.selectedData ~= nil then
        return GetString(SI_GAMEPAD_GUILD_HERALDRY_COST_LABEL), self.costFn, self.costFnNarration
    end

    return nil, nil, nil
end

do
    local DONT_ALLOW_EVEN_IF_DISABLED = true
    local NO_ANIMATION = true

    function ZO_GuildHeraldryManager_Gamepad:PopulateCategories()
        self.categoryList:Clear()

        local function LayoutStyles()
            self:BuildStyleGridList()
        end

        local function LayoutColors()
            self:BuildColorGridList()
        end

        local colorIcon = "EsoUI/Art/Dye/Gamepad/dye_square.dds"

        local bgStyleCost, bgPrimaryColorCost, bgSecondaryColorCost, crestStyleCost, crestColorCost = GetHeraldryCustomizationCosts()

        local function GetEntryNarrationText(entryData, entryControl)
            local narrations = {}

            -- Generate the standard parametric list entry narration
            ZO_AppendNarration(narrations, ZO_GetSharedGamepadEntryDefaultNarrationText(entryData, entryControl))

            -- Treat the content header as a sort of tooltip for the list entry
            ZO_AppendNarration(narrations, GAMEPAD_GUILD_HOME:GetContentHeaderNarrationText())

            return narrations
        end

        local bgStyleData = ZO_GamepadEntryData:New(GetString(SI_GUILD_HERALDRY_STYLE))
        bgStyleData:SetHeader(GetString(SI_GAMEPAD_GUILD_HERALDRY_BACKGROUND))
        bgStyleData.mode = ZO_HERALDRY_BG_STYLE_MODE
        bgStyleData.cost = bgStyleCost
        bgStyleData.layout = LayoutStyles
        bgStyleData.getNum = function() return GetNumHeraldryBackgroundStyles(self.viewBackgroundCategory) end
        bgStyleData.getInfo = function(index) return GetHeraldryBackgroundStyleInfo(self.viewBackgroundCategory, index) end
        bgStyleData.setSelectedCategory = function(index) self.selectedBackgroundCategory = index end
        bgStyleData.getSelectedCategory = function() return self.selectedBackgroundCategory end
        bgStyleData.setViewCategory = function(index) self.viewBackgroundCategory = index end
        bgStyleData.getViewCategory = function() return self.viewBackgroundCategory end
        bgStyleData.resetToSelectedCategory = function() self.bgStyleCatList:SetSelectedDataIndex(self.selectedBackgroundCategory, DONT_ALLOW_EVEN_IF_DISABLED, NO_ANIMATION) end
        bgStyleData.setSelectedStyle = function(index) self.selectedBackgroundStyle = index end
        bgStyleData.getSelectedStyle = function() return self.selectedBackgroundStyle end
        bgStyleData.setHighlightedStyle = function(index) self.highlightedBackgroundStyle = index end
        bgStyleData.getHighlightedStyle = function() return self.highlightedBackgroundStyle or self.selectedBackgroundStyle end
        bgStyleData.directionalInputCallback = function(direction) self:UpdateStyleWithDirection(direction) end
        bgStyleData.iconUpdateFn = function()
            local styleIndex = bgStyleData.getSelectedStyle()
            local _, icon = bgStyleData.getInfo(styleIndex)
            bgStyleData:ClearIcons()
            if bgStyleData.getSelectedCategory() ~= nil then
                bgStyleData:AddIcon(icon)
            end
        end
        bgStyleData.narrationText = GetEntryNarrationText

        self.categoryList:AddEntryWithHeader(CATEGORY_TEMPLATE_NAME, bgStyleData)

        local bgPrimaryColorData = ZO_GamepadEntryData:New(GetString(SI_GUILD_HERALDRY_PRIMARY_COLOR))
        bgPrimaryColorData.mode = ZO_HERALDRY_COLOR_MODE
        bgPrimaryColorData.cost = bgPrimaryColorCost
        bgPrimaryColorData.layout = LayoutColors
        bgPrimaryColorData.setSelectedColorIndex = function(index) self.selectedBackgroundPrimaryColor = index end
        bgPrimaryColorData.getSelectedColorIndex = function() return self.selectedBackgroundPrimaryColor end
        bgPrimaryColorData.iconUpdateFn = function()
            bgPrimaryColorData:SetIconTint(nil, nil)
            bgPrimaryColorData:ClearIcons()
            if bgPrimaryColorData.getSelectedColorIndex() ~= nil then
                local _, _, r, g, b = GetHeraldryColorInfo(bgPrimaryColorData.getSelectedColorIndex())
                local newColor = ZO_ColorDef:New(r, g, b)
                bgPrimaryColorData:SetIconTint(newColor, newColor)
                bgPrimaryColorData:AddIcon(colorIcon)
            end
        end
        bgPrimaryColorData.narrationText = GetEntryNarrationText

        self.categoryList:AddEntry(CATEGORY_TEMPLATE_NAME, bgPrimaryColorData)

        local bgSecondaryColorData = ZO_GamepadEntryData:New(GetString(SI_GUILD_HERALDRY_SECONDARY_COLOR))
        bgSecondaryColorData.mode = ZO_HERALDRY_COLOR_MODE
        bgSecondaryColorData.cost = bgSecondaryColorCost
        bgSecondaryColorData.layout = LayoutColors
        bgSecondaryColorData.setSelectedColorIndex = function(index) self.selectedBackgroundSecondaryColor = index end
        bgSecondaryColorData.getSelectedColorIndex = function() return self.selectedBackgroundSecondaryColor end
        bgSecondaryColorData.iconUpdateFn = function()
            bgSecondaryColorData:SetIconTint(nil, nil)
            bgSecondaryColorData:ClearIcons()
            if bgSecondaryColorData.getSelectedColorIndex() ~= nil then
                local _, _, r, g, b = GetHeraldryColorInfo(bgSecondaryColorData.getSelectedColorIndex())
                local newColor = ZO_ColorDef:New(r, g, b)
                bgSecondaryColorData:SetIconTint(newColor, newColor)
                bgSecondaryColorData:AddIcon(colorIcon)
            end
        end
        bgSecondaryColorData.narrationText = GetEntryNarrationText

        self.categoryList:AddEntry(CATEGORY_TEMPLATE_NAME, bgSecondaryColorData, nil, GAMEPAD_HEADER_DEFAULT_PADDING, nil, GAMEPAD_HEADER_SELECTED_PADDING)

        local crestStyleData = ZO_GamepadEntryData:New(GetString(SI_GUILD_HERALDRY_STYLE))
        crestStyleData:SetHeader(GetString(SI_GAMEPAD_GUILD_HERALDRY_CREST))
        crestStyleData.mode = ZO_HERALDRY_CREST_STYLE_MODE
        crestStyleData.cost = crestStyleCost
        crestStyleData.layout = LayoutStyles
        crestStyleData.getNum = function() return GetNumHeraldryCrestStyles(self.viewCrestCategory) end
        crestStyleData.getInfo = function(index) return GetHeraldryCrestStyleInfo(self.viewCrestCategory, index) end
        crestStyleData.setSelectedCategory = function(index) self.selectedCrestCategory = index end
        crestStyleData.getSelectedCategory = function() return self.selectedCrestCategory end
        crestStyleData.setViewCategory = function(index) self.viewCrestCategory = index end
        crestStyleData.getViewCategory = function() return self.viewCrestCategory end
        crestStyleData.resetToSelectedCategory = function() self.crestStyleCatList:SetSelectedDataIndex(self.selectedCrestCategory, DONT_ALLOW_EVEN_IF_DISABLED, NO_ANIMATION) end
        crestStyleData.setSelectedStyle = function(index) self.selectedCrestStyle = index end
        crestStyleData.getSelectedStyle = function() return self.selectedCrestStyle end
        crestStyleData.setHighlightedStyle = function(index) self.highlightedCrestStyle = index end
        crestStyleData.getHighlightedStyle = function() return self.highlightedCrestStyle or self.selectedCrestStyle end
        crestStyleData.directionalInputCallback = function(direction) self:UpdateStyleWithDirection(direction) end
        crestStyleData.iconUpdateFn = function()
            local styleIndex = crestStyleData.getSelectedStyle()
            local _, icon = crestStyleData.getInfo(styleIndex)
            crestStyleData:ClearIcons()
            if crestStyleData.getSelectedCategory() ~= nil then
                crestStyleData:AddIcon(icon)
            end
        end
        crestStyleData.narrationText = GetEntryNarrationText

        self.categoryList:AddEntryWithHeader(CATEGORY_TEMPLATE_NAME, crestStyleData, nil, nil, GAMEPAD_HEADER_SELECTED_PADDING)

        local crestColorData = ZO_GamepadEntryData:New(GetString(SI_GUILD_HERALDRY_COLOR))
        crestColorData.mode = ZO_HERALDRY_COLOR_MODE
        crestColorData.cost = crestColorCost
        crestColorData.layout = LayoutColors
        crestColorData.setSelectedColorIndex = function(index) self.selectedCrestColor = index end
        crestColorData.getSelectedColorIndex = function() return self.selectedCrestColor end
        crestColorData.iconUpdateFn = function()
            crestColorData:SetIconTint(nil, nil)
            crestColorData:ClearIcons()
            if crestColorData.getSelectedColorIndex() ~= nil then
                local _, _, r, g, b = GetHeraldryColorInfo(crestColorData.getSelectedColorIndex())
                local newColor = ZO_ColorDef:New(r, g, b)
                crestColorData:SetIconTint(newColor, newColor)
                crestColorData:AddIcon(colorIcon)
            end
        end
        crestColorData.narrationText = GetEntryNarrationText

        self.categoryList:AddEntry(CATEGORY_TEMPLATE_NAME, crestColorData)

        self.categoryList:CommitWithoutReselect()
    end
end

function ZO_GuildHeraldryManager_Gamepad:SetSelectedHeraldryIndices()
    ZO_GuildHeraldryManager_Shared.SetSelectedHeraldryIndices(self)

    if self.activeData then
        self:OnCategorySelected(self.activeData)
    end
end

function ZO_GuildHeraldryManager_Gamepad:SetDirectionalInputEnabled(enabled)
    if self.directionalInputEnabled ~= enabled then
        if enabled then
            DIRECTIONAL_INPUT:Activate(self, self.control)
        else
            DIRECTIONAL_INPUT:Deactivate(self)
        end

        self.directionalInputEnabled = enabled
    end
end

function ZO_GuildHeraldryManager_Gamepad:SelectColor(...)
    ZO_GuildHeraldryManager_Shared.SelectColor(self, ...)
    SCREEN_NARRATION_MANAGER:QueueGridListEntry(self.colorGridList)
    local targetData = self.categoryList:GetTargetData()
    if targetData and targetData.mode == ZO_HERALDRY_COLOR_MODE then
        self.categoryList:RefreshVisible()
    end
end

function ZO_GuildHeraldryManager_Gamepad:SelectStyle(...)
    ZO_GuildHeraldryManager_Shared.SelectStyle(self, ...)
    SCREEN_NARRATION_MANAGER:QueueGridListEntry(self.styleGridList)
end

--[[
    Dialog functions.
--]]

function ZO_GuildHeraldryManager_Gamepad:SetupHeraldryDialog(control)
    local pendingCost = GetPendingHeraldryCost()
    local heraldryFunds = GetHeraldryGuildBankedMoney() or 0

    local data =
    {
        data1 =
        {
            value = function(control)
                ZO_CurrencyControl_SetSimpleCurrency(control, CURT_MONEY, heraldryFunds, ZO_GAMEPAD_CURRENCY_OPTIONS)
                return true
            end,
            valueNarration = function(control)
                return ZO_Currency_FormatGamepad(CURT_MONEY, heraldryFunds, ZO_CURRENCY_FORMAT_AMOUNT_NAME)
            end,
            header = GetString(SI_GUILD_HERALDRY_DIALOG_BANKED_GOLD_HEADER),
        },

        data2 =
        {
            value = function(control)
                ZO_CurrencyControl_SetSimpleCurrency(control, CURT_MONEY, pendingCost, ZO_GAMEPAD_CURRENCY_OPTIONS)
                return true
            end,
            valueNarration = function(control)
                return ZO_Currency_FormatGamepad(CURT_MONEY, pendingCost, ZO_CURRENCY_FORMAT_AMOUNT_NAME)
            end,
            header = GetString(SI_GUILD_HERALDRY_DIALOG_COST_HEADER),
        },
    }

    control.setupFunc(control, data)
end

function ZO_GuildHeraldryManager_Gamepad:ConfirmHeraldryPurchase()
    ZO_GuildHeraldryManager_Shared.ConfirmHeraldryPurchase(self, nil, ZO_Dialogs_ShowGamepadDialog)
end

function ZO_GuildHeraldryManager_Gamepad:ConfirmHeraldryApplyChanges()
    ZO_GuildHeraldryManager_Shared.ConfirmHeraldryApplyChanges(self, nil, ZO_Dialogs_ShowGamepadDialog)
end

function ZO_GuildHeraldry_Gamepad_OnInitialized(control)
    GUILD_HERALDRY_GAMEPAD = ZO_GuildHeraldryManager_Gamepad:New(control)
    SYSTEMS:RegisterGamepadObject("guild_heraldry", GUILD_HERALDRY_GAMEPAD)
end