-----------------------------------
-- GuildHeraldryManager Keyboard
-----------------------------------
ZO_GUILD_HERALDRY_STYLE_ICON_SIZE = 64
ZO_GUILD_HERALDRY_STYLE_OFFSET = 16
ZO_GUILD_HERALDRY_DYE_SWATCH_DIMENSIONS = 30
ZO_GUILD_HERALDRY_HEADER_TEMPLATE_KEYBOARD_HEIGHT = 35

ZO_GuildHeraldryManager_Keyboard = ZO_GuildHeraldryManager_Shared:Subclass()

function ZO_GuildHeraldryManager_Keyboard:New(...)
    return ZO_GuildHeraldryManager_Shared.New(self, ...)
end

function ZO_GuildHeraldryManager_Keyboard:Initialize(control)
    local function StyleGridEntrySetup(control, data, list)
        local iconContainer = control:GetNamedChild("IconContainer")
        local checkButton = iconContainer:GetNamedChild("Frame")

        local function OnClick()
            self:SelectStyle(data.index)
        end

        iconContainer:GetNamedChild("Icon"):SetTexture(data.icon)
        ZO_CheckButton_SetCheckState(checkButton, self:IsViewingStyleCategoryWithSelection() and data.checked)
        ZO_CheckButton_SetToggleFunction(checkButton, OnClick)
    end

    local function DyeSwatchGridEntrySetup(control, data, list)
        local function OnClicked(swatchControl, button, upInside)
            if upInside then
                if button == MOUSE_BUTTON_INDEX_LEFT then
                    self:SelectColor(data.colorIndex)
                end
            end
        end

        control:SetHandler("OnMouseUp", OnClicked)
        control:SetColor(ZO_DYEING_SWATCH_INDEX, data.r, data.g, data.b)
        control:SetSurfaceHidden(ZO_DYEING_LOCK_INDEX, data.known)
        control:SetSurfaceHidden(ZO_DYEING_NEW_INDEX, not data:IsNew())
        data:SetControl(control)

        data.selected = data.checked
        data:UpdateSelectedState()
    end

    local function GeneralGridEntryReset(control)
        ZO_ObjectPool_DefaultResetControl(control)
    end

    local templateData =
    {
        gridListClass = ZO_GridScrollList_Keyboard,
        styleEntryTemplate = "ZO_GuildHeraldry_Style",
        styleEntryWidth = ZO_GAMEPAD_DEFAULT_SELECTION_ICON_SIZE,
        styleEntryHeight = ZO_GAMEPAD_DEFAULT_SELECTION_ICON_SIZE,
        styleGridPadding = ZO_GUILD_HERALDRY_STYLE_OFFSET,
        styleEntrySetup = StyleGridEntrySetup,
        styleEntryReset = GeneralGridEntryReset,
        styleHasGridHeader = true,
        colorEntryTemplate = "ZO_GuildHeraldry_DyeingSwatch",
        colorEntryWidth = ZO_GUILD_HERALDRY_DYE_SWATCH_DIMENSIONS,
        colorEntryHeight = ZO_GUILD_HERALDRY_DYE_SWATCH_DIMENSIONS,
        colorEntrySetup = DyeSwatchGridEntrySetup,
        colorEntryReset = GeneralGridEntryReset,
        headerTemplate = "ZO_GuildHeraldry_Style_Keyboard_Header_Template",
        headerHeight = ZO_GUILD_HERALDRY_HEADER_TEMPLATE_KEYBOARD_HEIGHT,
    }

    ZO_GuildHeraldryManager_Shared.Initialize(self, control, CURRENCY_OPTIONS, templateData)

    self.costControl = self.control:GetNamedChild("Cost")
    self.costLabel = self.control:GetNamedChild("CostLabel")
    self.categoryList = self.control:GetNamedChild("Categories")
    self.categoryListScrollChild = self.categoryList:GetNamedChild("ScrollChild")
    self.panelNameLabel = self.control:GetNamedChild("PanelName")

    self:InitializeStyleGridList()
    self:InitializeColorGridList()

    self:InitializeKeybindStripDescriptors()
    self:InitializeNavigationTree()
    self:InitializeCategories()
    self:InitializeStyleCategoryLists(ZO_HorizontalScrollList, "ZO_GuildHeraldry_StyleCategory")
    self:PopulateStyleCategoryLists()

    GUILD_HERALDRY_SCENE = ZO_Scene:New("guildHeraldry", SCENE_MANAGER)
    GUILD_HERALDRY_SCENE:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWING then
            StartHeraldryCustomization(self.guildId)
        elseif newState == SCENE_HIDDEN then
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
            EndHeraldryCustomization()
            self:SetPendingExit(false)
        end
    end)
    GUILD_HERALDRY_SCENE:SetHideSceneConfirmationCallback(function(...) self:OnConfirmHideScene(...) end)

    self.control:RegisterForEvent(EVENT_HERALDRY_CUSTOMIZATION_START, function(eventCode)
        if not IsInGamepadPreferredMode() and GUILD_HERALDRY_SCENE:IsShowing() then
            self.initialized = true
            self:SetSelectedHeraldryIndices()
            KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
        end
    end)

    self.control:RegisterForEvent(EVENT_HERALDRY_CUSTOMIZATION_END, function(eventCode)
        if not IsInGamepadPreferredMode() then
            self.initialized = false
        end
    end)

    self.control:RegisterForEvent(EVENT_HERALDRY_SAVED, function(eventCode)
        if not IsInGamepadPreferredMode() then
            self:SetSelectedHeraldryIndices()
            self:UpdateKeybindGroups()
            PlaySound(SOUNDS.GUILD_HERALDRY_APPLIED)
        end
    end)

    self.control:RegisterForEvent(EVENT_HERALDRY_FUNDS_UPDATED, function(eventCode)
        if not IsInGamepadPreferredMode() then
            self:UpdateKeybindGroups()
        end
    end)

    local function OnGuildSelected()
        self:UpdateKeybindGroups()
    end

    CALLBACK_MANAGER:RegisterCallback("OnGuildSelected", OnGuildSelected)
end

function ZO_GuildHeraldryManager_Keyboard:GetPurchaseDialogName()
    return "CONFIRM_HERALDRY_PURCHASE"
end

function ZO_GuildHeraldryManager_Keyboard:GetApplyChangesDialogName()
    return "CONFIRM_HERALDRY_APPLY_CHANGES"
end

function ZO_GuildHeraldryManager_Keyboard:ChangeSelectedGuild(changeGuildCallback, changeGuildParams)
    self.changeGuildCallback = changeGuildCallback
    self.changeGuildParams = changeGuildParams

    self:AttemptSaveAndExit()
end

function ZO_GuildHeraldryManager_Keyboard:SetEntryDataSelected(entryData, selected)
    if entryData.control then
        entryData.control.object:SetSelected(selected)
    end
end

function ZO_GuildHeraldryManager_Keyboard:ConfirmExit()
    if self.changeGuildCallback then
        local callback = self.changeGuildCallback
        local params = self.changeGuildParams

        self.changeGuildCallback = nil
        self.changeGuildParams = nil

        callback(params)
    else
        GUILD_HERALDRY_SCENE:AcceptHideScene()
    end
end

function ZO_GuildHeraldryManager_Keyboard:CancelExit()
    GUILD_HERALDRY_SCENE:RejectHideScene()
    self:SetPendingExit(false)
end

function ZO_GuildHeraldryManager_Keyboard:NoChoiceExitCallback()
    GUILD_HERALDRY_SCENE:RejectHideScene()
    self:SetPendingExit(false)
end

function ZO_GuildHeraldryManager_Keyboard:InitializeKeybindStripDescriptors()
    self.keybindStripDescriptor = 
    {
        alignment = KEYBIND_STRIP_ALIGN_CENTER,

        -- Apply Changes
        {
            name = function()
                local pendingCost = GetPendingHeraldryCost()
                local heraldryFunds = GetHeraldryGuildBankedMoney()

                local format
                if heraldryFunds and pendingCost <= heraldryFunds then
                    format = ZO_CURRENCY_FORMAT_WHITE_AMOUNT_ICON
                else
                    format = ZO_CURRENCY_FORMAT_ERROR_AMOUNT_ICON
                end

                if IsCreatingHeraldryForFirstTime() then
                    return zo_strformat(SI_GUILD_HERALDRY_PURCHASE_HERALDRY, ZO_Currency_FormatKeyboard(CURT_MONEY, pendingCost, format))
                else
                    return zo_strformat(SI_GUILD_HERALDRY_APPLY_CHANGES, ZO_Currency_FormatKeyboard(CURT_MONEY, pendingCost, format))
                end
            end,

            keybind = "UI_SHORTCUT_SECONDARY",

            callback = function()
                local pendingCost = GetPendingHeraldryCost()
                local heraldryFunds = GetHeraldryGuildBankedMoney()
                if heraldryFunds and pendingCost <= heraldryFunds then
                    if IsCreatingHeraldryForFirstTime() then
                        self:ConfirmHeraldryPurchase()
                    else
                        self:ConfirmHeraldryApplyChanges()
                    end
                else
                    ZO_AlertNoSuppression(UI_ALERT_CATEGORY_ALERT, nil, SI_GUILD_HERALDRY_ERROR_NOT_ENOUGH_GOLD)
                end
            end,

            visible = function()
                return HasPendingHeraldryChanges()
            end,

            enabled = function()
                local pendingCost = GetPendingHeraldryCost()
                local heraldryFunds = GetHeraldryGuildBankedMoney()
                return heraldryFunds and (pendingCost <= heraldryFunds)
            end,
        },

        -- Undo Changes
        {
            name = GetString(SI_GUILD_HERALDRY_UNDO_CHANGES),

            keybind = "UI_SHORTCUT_NEGATIVE",

            callback = function()
                RevertToSavedHeraldry(false)
                self:SetSelectedHeraldryIndices()
                KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
                PlaySound(SOUNDS.GUILD_HERALDRY_UNDO_CHANGES)
            end,

            visible = function()
                return HasPendingHeraldryChanges() and not IsCreatingHeraldryForFirstTime()
            end,
        },
    }
end

function ZO_GuildHeraldryManager_Keyboard:UpdateKeybindGroups()
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

local CURRENCY_OPTIONS =
{
    showTooltips = true,
    font = "ZoFontGameBold",
    iconSide = RIGHT,
}

function ZO_GuildHeraldryManager_Keyboard:InitializeNavigationTree()
    self.navigationTree = ZO_Tree:New(self.categoryListScrollChild, 60, -10, 374)

    local function BaseTreeHeaderIconSetup(control, data, open)
        control.text:SetDimensionConstraints(0, 0, 300, 0)

        local iconTexture = (open and data.pressedIcon or data.normalIcon) or "EsoUI/Art/Icons/icon_missing.dds"
        local mouseoverTexture = data.mouseoverIcon or "EsoUI/Art/Icons/icon_missing.dds"
        
        control.icon:SetTexture(iconTexture)
        control.iconHighlight:SetTexture(mouseoverTexture)

        ZO_IconHeader_Setup(control, open)
    end
    local function BaseTreeHeaderSetup(node, control, data, open)
        control.text:SetModifyTextType(MODIFY_TEXT_TYPE_UPPERCASE)
        control.text:SetText(data.name)
        BaseTreeHeaderIconSetup(control, data, open)
    end
    local function TreeHeaderSetup(node, control, data, open, userRequested)
        BaseTreeHeaderSetup(node, control, data, open)
        if open and userRequested then
            self.navigationTree:SelectFirstChild(node)
        end
    end

    local function TreeChildSetup(node, control, data, open)
        control:SetText(data.name)
    end
    local function TreeChildOnSelected(control, data, selected, reselectingDuringRebuild)
        control:SetSelected(selected)
        if selected and not reselectingDuringRebuild then
            self:OnCategorySelected(data)
        end
    end
    local function TreeChildlessHeaderOnSelected(control, data, selected, reselectingDuringRebuild)
        TreeChildOnSelected(control, data, selected, reselectingDuringRebuild)
        BaseTreeHeaderIconSetup(control, data, selected)
    end

    local function TreeChildEquality(left, right)
        return left.name == right.name
    end

    self.navigationTree:AddTemplate("ZO_IconHeader", TreeHeaderSetup, nil, nil, nil, 0)
    self.navigationTree:AddTemplate("ZO_GuildHeraldry_ChildlessHeader", BaseTreeHeaderSetup, TreeChildlessHeaderOnSelected)
    self.navigationTree:AddTemplate("ZO_GuildHeraldry_ChildEntry", TreeChildSetup, TreeChildOnSelected, TreeChildEquality)

    self.navigationTree:SetExclusive(true)
    self.navigationTree:SetOpenAnimation("ZO_TreeOpenAnimation")
end

function ZO_GuildHeraldryManager_Keyboard:InitializeCategories()
    local bgMenuData =
    {
        name = GetString(SI_GUILD_HERALDRY_BACKGROUND),
        normalIcon = "EsoUI/Art/Guild/guildHeraldry_indexIcon_background_up.dds",
        pressedIcon = "EsoUI/Art/Guild/guildHeraldry_indexIcon_background_down.dds",
        mouseoverIcon = "EsoUI/Art/Guild/guildHeraldry_indexIcon_background_over.dds",
    }
    local parent = self.navigationTree:AddNode("ZO_IconHeader", bgMenuData)

    local function LayoutStyles()
        self:BuildStyleGridList()
    end
    local function LayoutColors()
        self:BuildColorGridList()
    end

    local bgStyleCost, bgPrimaryColorCost, bgSecondaryColorCost, crestStyleCost, crestColorCost = GetHeraldryCustomizationCosts()

    local bgStyleData =
    {
        name = GetString(SI_GUILD_HERALDRY_STYLE),
        mode = ZO_HERALDRY_BG_STYLE_MODE,
        cost = bgStyleCost,
        layout = LayoutStyles,
        getNum = function() return GetNumHeraldryBackgroundStyles(self.viewBackgroundCategory) end,
        getInfo = function(index) return GetHeraldryBackgroundStyleInfo(self.viewBackgroundCategory, index) end,
        setSelectedCategory = function(index) self.selectedBackgroundCategory = index end,
        getSelectedCategory = function() return self.selectedBackgroundCategory end,
        setViewCategory = function(index) self.viewBackgroundCategory = index end,
        getViewCategory = function() return self.viewBackgroundCategory end,
        resetToSelectedCategory = function() self.bgStyleCatList:SetSelectedDataIndex(self.selectedBackgroundCategory) end,
        setSelectedStyle = function(index) self.selectedBackgroundStyle = index end,
        getSelectedStyle = function() return self.selectedBackgroundStyle end,
    }

    self.navigationTree:AddNode("ZO_GuildHeraldry_ChildEntry", bgStyleData, parent)

    local bgPrimaryColorData =
    {
        name = GetString(SI_GUILD_HERALDRY_PRIMARY_COLOR),
        mode = ZO_HERALDRY_COLOR_MODE,
        cost = bgPrimaryColorCost,
        layout = LayoutColors,
        setSelectedColorIndex = function(index) self.selectedBackgroundPrimaryColor = index end,
        getSelectedColorIndex = function() return self.selectedBackgroundPrimaryColor end,
    }

    self.navigationTree:AddNode("ZO_GuildHeraldry_ChildEntry", bgPrimaryColorData, parent)

    local bgSecondaryColorData =
    {
        name = GetString(SI_GUILD_HERALDRY_SECONDARY_COLOR),
        mode = ZO_HERALDRY_COLOR_MODE,
        cost = bgSecondaryColorCost,
        layout = LayoutColors,
        setSelectedColorIndex = function(index) self.selectedBackgroundSecondaryColor = index end,
        getSelectedColorIndex = function() return self.selectedBackgroundSecondaryColor end,
    }

    self.navigationTree:AddNode("ZO_GuildHeraldry_ChildEntry", bgSecondaryColorData, parent)

    local crestMenuData =
    {
        name = GetString(SI_GUILD_HERALDRY_CREST),
        normalIcon = "EsoUI/Art/Guild/guildHeraldry_indexIcon_crest_up.dds",
        pressedIcon = "EsoUI/Art/Guild/guildHeraldry_indexIcon_crest_down.dds",
        mouseoverIcon = "EsoUI/Art/Guild/guildHeraldry_indexIcon_crest_over.dds",
    }

    parent = self.navigationTree:AddNode("ZO_IconHeader", crestMenuData)

    local crestStyleData =
    {
        name = GetString(SI_GUILD_HERALDRY_STYLE),
        mode = ZO_HERALDRY_CREST_STYLE_MODE,
        cost = crestStyleCost,
        layout = LayoutStyles,
        getNum = function() return GetNumHeraldryCrestStyles(self.viewCrestCategory) end,
        getInfo = function(index) return GetHeraldryCrestStyleInfo(self.viewCrestCategory, index) end,
        setSelectedCategory = function(index) self.selectedCrestCategory = index end,
        getSelectedCategory = function() return self.selectedCrestCategory end,
        setViewCategory = function(index) self.viewCrestCategory = index end,
        getViewCategory = function() return self.viewCrestCategory end,
        resetToSelectedCategory = function() self.crestStyleCatList:SetSelectedDataIndex(self.selectedCrestCategory) end,
        setSelectedStyle = function(index) self.selectedCrestStyle = index end,
        getSelectedStyle = function() return self.selectedCrestStyle end,
    }

    self.navigationTree:AddNode("ZO_GuildHeraldry_ChildEntry", crestStyleData, parent)

     local crestColorData =
     {
        name = GetString(SI_GUILD_HERALDRY_COLOR),
        mode = ZO_HERALDRY_COLOR_MODE,
        cost = crestColorCost,
        layout = LayoutColors,
        setSelectedColorIndex = function(index) self.selectedCrestColor = index end,
        getSelectedColorIndex = function() return self.selectedCrestColor end,
    }

    self.navigationTree:AddNode("ZO_GuildHeraldry_ChildEntry", crestColorData, parent)

    self.navigationTree:Commit()
end

function ZO_GuildHeraldryManager_Keyboard:SetSelectedHeraldryIndices()
    ZO_GuildHeraldryManager_Shared.SetSelectedHeraldryIndices(self)

    if self.activeData then
        self:OnCategorySelected(self.activeData)
    end
end

function ZO_GuildHeraldryManager_Keyboard:OnCategorySelected(data)
    ZO_GuildHeraldryManager_Shared.OnCategorySelected(self, data)

    if self.initialized then
        if data.cost then
            self.costControl:SetHidden(false)
            self.costLabel:SetHidden(false)
            ZO_CurrencyControl_SetSimpleCurrency(self.costControl, CURT_MONEY,  data.cost)
        else
            self.costControl:SetHidden(true)
            self.costLabel:SetHidden(true)
        end
    end
end

--[[
    Dialog functions.
--]]

function ZO_GuildHeraldryManager_Keyboard:SetupHeraldryDialog(control)
    local pendingCost = GetPendingHeraldryCost()
    local heraldryFunds = GetHeraldryGuildBankedMoney() or 0

    local descriptionLabel = control:GetNamedChild("Description")
    local textInfo = type(control.info.mainText.text) == "function" and control.info.mainText.text() or control.info.mainText.text
    descriptionLabel:SetText(GetString(textInfo))

    local guildBalanceControl = control:GetNamedChild("GuildBalance")
    ZO_CurrencyControl_SetSimpleCurrency(guildBalanceControl, CURT_MONEY, heraldryFunds, CURRENCY_OPTIONS)

    local costControl = control:GetNamedChild("Cost")
    ZO_CurrencyControl_SetSimpleCurrency(costControl, CURT_MONEY, pendingCost, CURRENCY_OPTIONS)
end

function ZO_GuildHeraldryManager_Keyboard:ConfirmHeraldryPurchase()
    ZO_GuildHeraldryManager_Shared.ConfirmHeraldryPurchase(self, ZO_GuildHeraldryConfirmationDialog, ZO_Dialogs_ShowDialog)
end

function ZO_GuildHeraldryManager_Keyboard:ConfirmHeraldryApplyChanges()
    ZO_GuildHeraldryManager_Shared.ConfirmHeraldryApplyChanges(self, ZO_GuildHeraldryConfirmationDialog, ZO_Dialogs_ShowDialog)
end

--[[
    Global XML.
--]]

function ZO_GuildHeraldry_OnInitialized(control)
    GUILD_HERALDRY = ZO_GuildHeraldryManager_Keyboard:New(control)
    SYSTEMS:RegisterKeyboardObject("guild_heraldry", GUILD_HERALDRY)
end

function ZO_GuildHeraldry_StyleIcon_Keyboard_OnMouseEnter(self)
    if ZO_CheckButton_IsEnabled(self:GetNamedChild("IconContainerFrame")) then
        self:GetNamedChild("Highlight"):SetHidden(false)
    end
end

function ZO_GuildHeraldry_StyleIcon_Keyboard_OnMouseExit(self)
    self:GetNamedChild("Highlight"):SetHidden(true)
end
