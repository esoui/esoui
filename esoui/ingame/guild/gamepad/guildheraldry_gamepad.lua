local CATEGORY_TEMPLATE_NAME = "ZO_GamepadMenuEntryTemplate"
local CATEGORY_HEADER_TEMPLATE_NAME = "ZO_GamepadMenuEntryHeaderTemplate"
local COLOR_TEMPLATE_NAME = "ZO_GuildHeraldry_SwatchEntryTemplate_Gamepad"
local COLOR_HEADER_TEMPLATE_NAME = "ZO_GuildHeraldry_SwatchHeaderTemplate_Gamepad"

ZO_GAMEPAD_GUILD_HERALDRY_STYLE_LIST_VERT_PADDING = ZO_GAMEPAD_CONTENT_VERT_OFFSET_PADDING + 40

local STYLE_SUBMODE_TOP = 1
local STYLE_SUBMODE_BOTTOM = 2

local DIRECTION_LEFT = 1
local DIRECTION_RIGHT = 2
local DIRECTION_UP = 3
local DIRECTION_DOWN = 4
local DIRECTION_UPLEFT = 5
local DIRECTION_UPRIGHT = 6
local DIRECTION_DOWNLEFT = 7
local DIRECTION_DOWNRIGHT = 8

local STYLE_ROW_TOP = 1

local RESET_TO_SELECTED = true

ZO_GuildHeraldryManager_Gamepad = ZO_GuildHeraldryManager_Shared:Subclass()

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
    ZO_GuildHeraldryManager_Shared.Initialize(self, control, ZO_GAMEPAD_CURRENCY_OPTIONS)

    self:InitializeSwatchPool("ZO_GuildHeraldry_DyeingSwatch_Gamepad")
    self:InitializeStylePool("ZO_GuildHeraldry_Style_Gamepad")

    GUILD_HERALDRY_GAMEPAD_FRAGMENT = ZO_FadeSceneFragment:New(self.control, true)
    GUILD_HERALDRY_GAMEPAD_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWING then
            self:PerformDeferredInitialization()

            MAIN_MENU_MANAGER:SetBlockingScene("guildHeraldry_gamepad", OnBlockingSceneActivated)

            self.pendingTransaction = false
            self:PopulateCategories()
            self:PopulateStyleCategoryLists() -- Depends on PopulateCategories being called first.

            self.categoryList:SetFirstIndexSelected()
            self:SelectMode(ZO_HERALDRY_CATEGORY_MODE)
            self:RegisterEvents()
            StartHeraldryCustomization(self.guildId)

            KEYBIND_STRIP:RemoveDefaultExit()
            KEYBIND_STRIP:AddKeybindButtonGroup(self.globalKeybindStripDescriptor)
        elseif newState == SCENE_HIDING then
            EndHeraldryCustomization()
            self:UnregisterEvents()
            self:SetDirectionalInputEnabled(false)
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.globalKeybindStripDescriptor)
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.activeKeybindStripDescriptor)
            KEYBIND_STRIP:RestoreDefaultExit()
            self.activeKeybindStripDescriptor = nil
            GAMEPAD_NAV_QUADRANT_1_BACKGROUND_FRAGMENT:TakeFocus()
            if self.categoryList:IsActive() then
                self.categoryList:Deactivate()
            else
                self:HideColorHighlight(nil, RESET_TO_SELECTED)
                self:HideStyleHighlight(nil, RESET_TO_SELECTED)
            end
        end
    end)
end

function ZO_GuildHeraldryManager_Gamepad:PerformDeferredInitialization()
    if self.deferredInitialized then return end
    self.deferredInitialized = true

    self.sharedColorSelectedHighlight = self.control:GetNamedChild("SharedColorSelectedHighlight")
    self.sharedColorBrowseHighlight = self.control:GetNamedChild("SharedColorBrowseHighlight")
    self.sharedStyleSelectedHighlight = self.control:GetNamedChild("SharedStyleSelectedHighlight")
    self.sharedStyleSelectedHighlight.blockAlphaChanges = true

    self:InitializeColorList()
    self:InitializeStyleCategoryLists(ZO_HorizontalScrollList_Gamepad, "ZO_GuildHeraldry_StyleCategory_Gamepad")
    self:InitializeKeybindStripDescriptors()

    self.vertMovementController = ZO_MovementController:New(MOVEMENT_CONTROLLER_DIRECTION_VERTICAL)
    self.horzMovementController = ZO_MovementController:New(MOVEMENT_CONTROLLER_DIRECTION_HORIZONTAL)

    self.costFn = function(control)
        ZO_CurrencyControl_SetSimpleCurrency(control, CURT_MONEY, self.selectedData.cost, self.currencyOptions)
        return true
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
        self:EnableHighlight()
        ZO_AlertNoSuppression(UI_ALERT_CATEGORY_ALERT, SOUNDS.GUILD_HERALDRY_APPLIED, SI_GAMEPAD_GUILD_HERALDRY_SAVED)
        self.pendingTransaction = false
        self:UpdateKeybindGroups()
        self.categoryList:RefreshVisible()

        self:HideStyleHighlight()
        self:HideColorHighlight()
        self:SelectMode(ZO_HERALDRY_CATEGORY_MODE)
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

function ZO_GuildHeraldryManager_Gamepad:InitializeStyleCategoryLists(scrollList, scrollListTemplate)
    ZO_GuildHeraldryManager_Shared.InitializeStyleCategoryLists(self, scrollList, scrollListTemplate)
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
                local goldIcon = zo_iconFormat(ZO_GAMEPAD_CURRENCY_ICON_GOLD_TEXTURE, 24, 24)

                if IsCreatingHeraldryForFirstTime() then
                    if heraldryFunds and pendingCost <= heraldryFunds then
                        return zo_strformat(SI_GAMEPAD_GUILD_HERALDRY_PURCHASE_HERALDRY, ZO_CurrencyControl_FormatCurrency(pendingCost), goldIcon)
                    else
                        return zo_strformat(SI_GAMEPAD_GUILD_HERALDRY_PURCHASE_HERALDRY_NOT_ENOUGH, ZO_ERROR_COLOR:Colorize(ZO_CurrencyControl_FormatCurrency(pendingCost)), goldIcon)
                    end
                else
                    if heraldryFunds and pendingCost <= heraldryFunds then
                        return zo_strformat(SI_GAMEPAD_GUILD_HERALDRY_APPLY_CHANGES, ZO_CurrencyControl_FormatCurrency(pendingCost), goldIcon)
                    else
                        return zo_strformat(SI_GAMEPAD_GUILD_HERALDRY_APPLY_CHANGES_NOT_ENOUGH, ZO_ERROR_COLOR:Colorize(ZO_CurrencyControl_FormatCurrency(pendingCost)), goldIcon)
                    end
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
            name = GetString(SI_EXIT_BUTTON),
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
                self:SelectMode(self.activeData.mode)
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
                self:SelectColor(self.activeData.getHighlightedColor())
            end,

            visible = function()
                return self.activeData.getSelectedColor() ~= self.activeData.getHighlightedColor()
            end,
        },
    }

    ZO_Gamepad_AddListTriggerKeybindDescriptors(self.colorKeybindStripDescriptor, self.colorList)
    ZO_Gamepad_AddBackNavigationKeybindDescriptorsWithSound(self.colorKeybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON, function()
        self:HideColorHighlight()
        self:SelectMode(ZO_HERALDRY_CATEGORY_MODE)
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

            visible = function()
                local selectedIsHighlighted = (self.activeData.getViewCategory() == self.activeData.getSelectedCategory()) and (self.activeData.getSelectedStyle() == self.activeData.getHighlightedStyle())
                return (self.activeData.getSubMode() == STYLE_SUBMODE_BOTTOM) and not selectedIsHighlighted
            end,

            callback = function()
                self:SelectStyle(self.activeData.getHighlightedStyle())
            end,
        },

        -- Switch to the top style pane.
        {
            keybind = "UI_SHORTCUT_LEFT_TRIGGER",
            ethereal = true,

            sound = SOUNDS.GAMEPAD_MENU_UP,

            callback = function()
                self:SetStyleSubMode(STYLE_SUBMODE_TOP)
            end,
        },

        -- Switch to the bottom style pane.
        {
            keybind = "UI_SHORTCUT_RIGHT_TRIGGER",
            ethereal = true,

            sound = SOUNDS.GAMEPAD_MENU_DOWN,

            callback = function()
                self:SetStyleSubMode(STYLE_SUBMODE_BOTTOM)
            end,
        },
    }

    ZO_Gamepad_AddBackNavigationKeybindDescriptorsWithSound(self.styleKeybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON, function()
        ZO_GuildHeraldryManager_Shared.SetSelectedHeraldryIndices(self) -- This makes sure that the viewCategory is correct for crestData so that icons don't appear as missing or incorrect in the category list
        self:HideStyleHighlight()
        self:SelectMode(ZO_HERALDRY_CATEGORY_MODE)
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
    if(self.selectedData ~= nil) then
        return GetString(SI_GAMEPAD_GUILD_HERALDRY_COST_LABEL), self.costFn
    end

    return nil, nil
end

local function RemoveAllChildren(control)
    -- Queue the children for removal, since we cannot remove them while iterating through them.
    local childrenToRemove = {}
    local childCount = control:GetNumChildren()
    for i = 1, childCount do
        local child = control:GetChild(i)
        table.insert(childrenToRemove, child)
    end

    -- Remove the queued children.
    for _, child in ipairs(childrenToRemove) do
        child:SetParent(nil)
    end
end

local function SetupSwatches(control, data, selected, reselectingDuringRebuild, enabled, active)
    local selectedColor = nil
    local owner = data.owner
    if owner.activeData then
        selectedColor = owner.activeData.getSelectedColor()
    end

    local swatches = data.swatches

    control:SetDimensions(data.width, data.height)

    local swatchesControl = control.swatchesControl
    swatchesControl:SetDimensions(data.width, data.height)

    -- Remove all previously added swatches.
    RemoveAllChildren(swatchesControl)

    local currentAnchor = ZO_Anchor:New(CENTER, control, LEFT)
    for i = 1, #swatches do
        local swatch = swatches[i]
        swatch:SetParent(swatchesControl)
        AnchorDyeSwatch_Gamepad(currentAnchor, swatch, i)

        if swatch.colorIndex == selectedColor then
            owner:SelectColor(swatch.colorIndex, ZO_HERALDRY_SKIP_ANIM)
        end
    end
end

function ZO_GuildHeraldryManager_Gamepad:InitializeColorList()
    self.colorListContainer = self.control:GetNamedChild("ColorList"):GetNamedChild("Container")
    self.colorList = ZO_GamepadVerticalItemParametricScrollList:New(self.colorListContainer:GetNamedChild("List"))
    local IS_ACTIVATED = true
    self.colorList.onActivatedChangedFunction(self.colorList, IS_ACTIVATED)
    self.colorList:SetOnActivatedChangedFunction(nil)
    self.colorList:SetDirectionalInputEnabled(false)
    local DEFAULT_PADDING = 38
    local SWATCH_ROW_HEIGHT = GetDyeSwatchSize_Gamepad() + DEFAULT_PADDING
    self.colorList:SetAlignToScreenCenter(true, SWATCH_ROW_HEIGHT)

    self.colorList:AddDataTemplate(COLOR_TEMPLATE_NAME, SetupSwatches)
    self.colorList:AddDataTemplateWithHeader(COLOR_TEMPLATE_NAME, SetupSwatches, nil, nil, COLOR_HEADER_TEMPLATE_NAME)

    self.colorList:SetOnSelectedDataChangedCallback(function(list, selectedData, oldSelectedData, reachedTarget)
        if reachedTarget then
            if self.targetSwatchToHighlight then
                self:HighlightColor(self.targetSwatchToHighlight)
                self.targetSwatchToHighlight = nil
            elseif selectedData and not self.isPopulatingColors then
                -- We need to maintain the color highlight on the same column (if possible) when the list triggers are used (to jump between headers).
                local oldSwatch = self.colorIndexToSwatch[self.activeData.getHighlightedColor()]
                local newIndex = zo_clamp(oldSwatch.indexInRow, 1, #selectedData.swatches)
                self:HighlightColor(selectedData.swatches[newIndex])
            end

            self:UpdateKeybindGroups()
        end
    end)
end

local function SetupStyleLinks(styles, stride)
    local function GetLink(row, col)
        if  (row == 0) then
            return STYLE_ROW_TOP
        elseif (col > 0) and (col <= stride) then
            local index = ((row - 1) * stride) + col
            if (index > 0) and (index <= #styles) then
                return styles[index]
            end
        end
    end

    -- Setup style links in up to eight directions.
    local styleCount = #styles
    local lastRow = zo_ceil(styleCount / stride)
    local lastCol = ((styleCount - 1) % stride) + 1
    for i = 1, styleCount do
        local style = styles[i]
        local row = zo_ceil(i / stride)
        local col = ((i - 1) % stride) + 1

        if not style.links then
            style.links = {nil, nil, nil, nil, nil, nil, nil, nil} -- For efficiency, pre-allocate the table to accommodate eight directions.
        end

        style.links[DIRECTION_LEFT] = GetLink(row, col - 1)
        style.links[DIRECTION_RIGHT] = GetLink(row, col + 1)
        style.links[DIRECTION_UP] = GetLink(row - 1, col)
        style.links[DIRECTION_DOWN] = GetLink(row + 1, col)
        style.links[DIRECTION_UPLEFT] = GetLink(row - 1, col - 1)
        style.links[DIRECTION_UPRIGHT] = GetLink(row - 1, col + 1)
        style.links[DIRECTION_DOWNLEFT] = GetLink(row + 1, col - 1)
        style.links[DIRECTION_DOWNRIGHT] = GetLink(row + 1, col + 1)
    end
end

function ZO_GuildHeraldryManager_Gamepad:PopulateCategories()
    self.categoryList:Clear()

    local function LayoutStyles()
        local STRIDE = 6
        local STYLE_SIZE = ZO_GAMEPAD_DEFAULT_SELECTION_ICON_SIZE
        local PADDING_X = 30
        local PADDING_Y = 24

        local centerOffset = (STRIDE / 2) * STYLE_SIZE
        centerOffset = centerOffset + (PADDING_X * 1.5)

        local INITIAL_OFFSET_X = (ZO_GAMEPAD_QUADRANT_2_3_CONTAINER_WIDTH / 2) - centerOffset
        local INITIAL_OFFSET_Y = 58

        local function AnchorHeraldryStyle(currentAnchor, style, index)
            ZO_Anchor_BoxLayout(currentAnchor, style, index - 1, STRIDE, PADDING_X, PADDING_Y, STYLE_SIZE, STYLE_SIZE, INITIAL_OFFSET_X, INITIAL_OFFSET_Y)
        end

        self:LayoutStyles(AnchorHeraldryStyle)
        SetupStyleLinks(self.styleIndexToStyle, STRIDE)
    end

    local function LayoutColors()
        self:LayoutColors()
    end

    local function OnLeavingColorMode(oldData, newData)
        -- We must have changed categories, so set the highlighted color to be the same as the selected color.
        self:HideColorHighlight(oldData, RESET_TO_SELECTED)
    end

    local function OnLeavingStyleMode(oldData, newData)
        -- We must have changed categories, so set the highlighted style to be the same as the selected style, and reset
        -- the submode to the top.
        self:HideStyleHighlight(oldData, RESET_TO_SELECTED)
        oldData.setSubMode(STYLE_SUBMODE_TOP)
    end

    local colorIcon = "EsoUI/Art/Dye/Gamepad/dye_square.dds"

    local bgStyleCost, bgPrimaryColorCost, bgSecondaryColorCost, crestStyleCost, crestColorCost = GetHeraldryCustomizationCosts()

    local bgStyleData = ZO_GamepadEntryData:New(GetString(SI_GUILD_HERALDRY_STYLE))
    bgStyleData:SetHeader(GetString(SI_GAMEPAD_GUILD_HERALDRY_BACKGROUND))
    bgStyleData.mode = ZO_HERALDRY_BG_STYLE_MODE
    bgStyleData.cost = bgStyleCost
    bgStyleData.layout = LayoutStyles
    bgStyleData.changed = OnLeavingStyleMode
    bgStyleData.setSubMode = function(mode) self.bgStyleSubMode = mode end
    bgStyleData.getSubMode = function() return self.bgStyleSubMode or STYLE_SUBMODE_TOP end
    bgStyleData.getNum = function() return GetNumHeraldryBackgroundStyles(self.viewBackgroundCategory) end
    bgStyleData.getInfo = function(index) return GetHeraldryBackgroundStyleInfo(self.viewBackgroundCategory, index) end
    bgStyleData.setSelectedCategory = function(index) self.selectedBackgroundCategory = index end
    bgStyleData.getSelectedCategory = function() return self.selectedBackgroundCategory end
    bgStyleData.setViewCategory = function(index) self.viewBackgroundCategory = index end
    bgStyleData.getViewCategory = function() return self.viewBackgroundCategory end
    bgStyleData.resetToSelectedCategory = function() self.bgStyleCatList:SetSelectedDataIndex(self.selectedBackgroundCategory) end
    bgStyleData.setSelectedStyle = function(index) self.selectedBackgroundStyle = index end
    bgStyleData.getSelectedStyle = function() return self.selectedBackgroundStyle end
    bgStyleData.setHighlightedStyle = function(index) self.highlightedBackgroundStyle = index end
    bgStyleData.getHighlightedStyle = function() return self.highlightedBackgroundStyle or self.selectedBackgroundStyle end
    bgStyleData.directionalInputCallback = function(direction) self:UpdateStyleWithDirection(direction) end
    bgStyleData.styleHeaderName = GetString(SI_GUILD_HERALDRY_PATTERN_HEADER)
    bgStyleData.iconUpdateFn = function() 
        local styleIndex = bgStyleData.getSelectedStyle()
        local _, icon = bgStyleData.getInfo(styleIndex)
        bgStyleData:ClearIcons()
        if (bgStyleData.getSelectedCategory() ~= nil) then
            bgStyleData:AddIcon(icon)
        end
    end

    self.categoryList:AddEntryWithHeader(CATEGORY_TEMPLATE_NAME, bgStyleData)

    local bgPrimaryColorData = ZO_GamepadEntryData:New(GetString(SI_GUILD_HERALDRY_PRIMARY_COLOR))
    bgPrimaryColorData.mode = ZO_HERALDRY_COLOR_MODE
    bgPrimaryColorData.cost = bgPrimaryColorCost
    bgPrimaryColorData.layout = LayoutColors
    bgPrimaryColorData.changed = OnLeavingColorMode
    bgPrimaryColorData.setSelectedColor = function(index) self.selectedBackgroundPrimaryColor = index end
    bgPrimaryColorData.getSelectedColor = function() return self.selectedBackgroundPrimaryColor end
    bgPrimaryColorData.setHighlightedColor = function(index) self.highlightedBackgroundPrimaryColor = index end
    bgPrimaryColorData.getHighlightedColor = function() return self.highlightedBackgroundPrimaryColor or self.selectedBackgroundPrimaryColor end
    bgPrimaryColorData.directionalInputCallback = function(direction) self:HighlightColorWithDirection(direction) end
    bgPrimaryColorData.iconUpdateFn = function() 
        bgPrimaryColorData:SetIconTint(nil, nil)
        bgPrimaryColorData:ClearIcons()
        if (bgPrimaryColorData.getSelectedColor() ~= nil) then
            local _, _, r, g, b = GetHeraldryColorInfo(bgPrimaryColorData.getSelectedColor())
            local newColor = ZO_ColorDef:New(r, g, b)
            bgPrimaryColorData:SetIconTint(newColor, newColor)
            bgPrimaryColorData:AddIcon(colorIcon)
        end
    end

    self.categoryList:AddEntry(CATEGORY_TEMPLATE_NAME, bgPrimaryColorData)

    local bgSecondaryColorData = ZO_GamepadEntryData:New(GetString(SI_GUILD_HERALDRY_SECONDARY_COLOR))
    bgSecondaryColorData.mode = ZO_HERALDRY_COLOR_MODE
    bgSecondaryColorData.cost = bgSecondaryColorCost
    bgSecondaryColorData.layout = LayoutColors
    bgSecondaryColorData.changed = OnLeavingColorMode
    bgSecondaryColorData.setSelectedColor = function(index) self.selectedBackgroundSecondaryColor = index end
    bgSecondaryColorData.getSelectedColor = function() return self.selectedBackgroundSecondaryColor end
    bgSecondaryColorData.setHighlightedColor = function(index) self.highlightedBackgroundSecondaryColor = index end
    bgSecondaryColorData.getHighlightedColor = function() return self.highlightedBackgroundSecondaryColor or self.selectedBackgroundSecondaryColor end
    bgSecondaryColorData.directionalInputCallback = function(direction) self:HighlightColorWithDirection(direction) end
    bgSecondaryColorData.iconUpdateFn = function() 
        bgSecondaryColorData:SetIconTint(nil, nil)
        bgSecondaryColorData:ClearIcons()
        if (bgSecondaryColorData.getSelectedColor() ~= nil) then
            local _, _, r, g, b = GetHeraldryColorInfo(bgSecondaryColorData.getSelectedColor())
            local newColor = ZO_ColorDef:New(r, g, b)
            bgSecondaryColorData:SetIconTint(newColor, newColor)
            bgSecondaryColorData:AddIcon(colorIcon)
        end
    end

    self.categoryList:AddEntry(CATEGORY_TEMPLATE_NAME, bgSecondaryColorData, nil, GAMEPAD_HEADER_DEFAULT_PADDING, nil, GAMEPAD_HEADER_SELECTED_PADDING)

    local crestStyleData = ZO_GamepadEntryData:New(GetString(SI_GUILD_HERALDRY_STYLE))
    crestStyleData:SetHeader(GetString(SI_GAMEPAD_GUILD_HERALDRY_CREST))
    crestStyleData.mode = ZO_HERALDRY_CREST_STYLE_MODE
    crestStyleData.cost = crestStyleCost
    crestStyleData.layout = LayoutStyles
    crestStyleData.changed = OnLeavingStyleMode
    crestStyleData.setSubMode = function(mode) self.crestStyleSubMode = mode end
    crestStyleData.getSubMode = function() return self.crestStyleSubMode or STYLE_SUBMODE_TOP end
    crestStyleData.getNum = function() return GetNumHeraldryCrestStyles(self.viewCrestCategory) end
    crestStyleData.getInfo = function(index) return GetHeraldryCrestStyleInfo(self.viewCrestCategory, index) end
    crestStyleData.setSelectedCategory = function(index) self.selectedCrestCategory = index end
    crestStyleData.getSelectedCategory = function() return self.selectedCrestCategory end
    crestStyleData.setViewCategory = function(index) self.viewCrestCategory = index end
    crestStyleData.getViewCategory = function() return self.viewCrestCategory end
    crestStyleData.resetToSelectedCategory = function() self.crestStyleCatList:SetSelectedDataIndex(self.selectedCrestCategory) end
    crestStyleData.setSelectedStyle = function(index) self.selectedCrestStyle = index end
    crestStyleData.getSelectedStyle = function() return self.selectedCrestStyle end
    crestStyleData.setHighlightedStyle = function(index) self.highlightedCrestStyle = index end
    crestStyleData.getHighlightedStyle = function() return self.highlightedCrestStyle or self.selectedCrestStyle end
    crestStyleData.directionalInputCallback = function(direction) self:UpdateStyleWithDirection(direction) end
    crestStyleData.styleHeaderName = GetString(SI_GUILD_HERALDRY_DESIGN_HEADER)
    crestStyleData.iconUpdateFn = function() 
        local styleIndex = crestStyleData.getSelectedStyle()
        local _, icon = crestStyleData.getInfo(styleIndex)
        crestStyleData:ClearIcons()
        if (crestStyleData.getSelectedCategory() ~= nil) then
            crestStyleData:AddIcon(icon)
        end
    end

    self.categoryList:AddEntryWithHeader(CATEGORY_TEMPLATE_NAME, crestStyleData, nil, nil, GAMEPAD_HEADER_SELECTED_PADDING)

    local crestColorData = ZO_GamepadEntryData:New(GetString(SI_GUILD_HERALDRY_COLOR))
    crestColorData.mode = ZO_HERALDRY_COLOR_MODE
    crestColorData.cost = crestColorCost
    crestColorData.layout = LayoutColors
    crestColorData.changed = OnLeavingColorMode
    crestColorData.setSelectedColor = function(index) self.selectedCrestColor = index end
    crestColorData.getSelectedColor = function() return self.selectedCrestColor end
    crestColorData.setHighlightedColor = function(index) self.highlightedCrestColor = index end
    crestColorData.getHighlightedColor = function() return self.highlightedCrestColor or self.selectedCrestColor end
    crestColorData.directionalInputCallback = function(direction) self:HighlightColorWithDirection(direction) end
    crestColorData.iconUpdateFn = function() 
        crestColorData:SetIconTint(nil, nil)
        crestColorData:ClearIcons()
        if (crestColorData.getSelectedColor() ~= nil) then
            local _, _, r, g, b = GetHeraldryColorInfo(crestColorData.getSelectedColor())
            local newColor = ZO_ColorDef:New(r, g, b)
            crestColorData:SetIconTint(newColor, newColor)
            crestColorData:AddIcon(colorIcon)
        end
    end

    self.categoryList:AddEntry(CATEGORY_TEMPLATE_NAME, crestColorData)

    self.categoryList:Commit()
end

function ZO_GuildHeraldryManager_Gamepad:SetViewedStyleCategory(index)
    ZO_GuildHeraldryManager_Shared.SetViewedStyleCategory(self, index)
    self.activeData.setHighlightedStyle(1, ZO_HERALDRY_SKIP_ANIM)
end

local function SetupSwatchLinks(swatchRowGroup, rowIndex)
    local function GetLink(index, row, nextRow)
        if row then
            if (index > 0) and (index <= #row) then
                return row[index]
            end

            if nextRow then
                if (index > 0) and (index <= #nextRow) then
                    return nextRow[index]
                end
            end
        end
    end

    -- Link each swatch in the current row to its nearest neighbors in eight directions.
    local thisRow = swatchRowGroup.current
    for i = 1, #thisRow do
        local swatch = thisRow[i]

        swatch.indexInRow = i
        swatch.row = rowIndex

        if not swatch.links then
            swatch.links = {nil, nil, nil, nil, nil, nil, nil, nil} -- For efficiency, pre-allocate the table to accommodate eight directions.
        end

        swatch.links[DIRECTION_LEFT] = GetLink(i - 1, thisRow) or GetLink(#thisRow, thisRow)
        swatch.links[DIRECTION_RIGHT] = GetLink(i + 1, thisRow) or GetLink(1, thisRow)
        swatch.links[DIRECTION_UP] = GetLink(i, swatchRowGroup.prev, swatchRowGroup.prevPrev)
        swatch.links[DIRECTION_DOWN] = GetLink(i, swatchRowGroup.next, swatchRowGroup.nextNext)
        swatch.links[DIRECTION_UPLEFT] = GetLink(i - 1, swatchRowGroup.prev, swatchRowGroup.prevPrev)
        swatch.links[DIRECTION_UPRIGHT] = GetLink(i + 1, swatchRowGroup.prev, swatchRowGroup.prevPrev)
        swatch.links[DIRECTION_DOWNLEFT] = GetLink(i - 1, swatchRowGroup.next, swatchRowGroup.nextNext)
        swatch.links[DIRECTION_DOWNRIGHT] = GetLink(i + 1, swatchRowGroup.next, swatchRowGroup.nextNext)
    end
end

local function GetSwatchesInRow(swatches, row, entryIndex)
    local swatchesInRow = {}
    local started = false
    for i = 1, #swatches do
        thisRow = GetDyeSwatchRow(i)
        if thisRow == row then
            started = true
            swatchesInRow[#swatchesInRow + 1] = swatches[i]
        elseif started then
            break
        end
    end

    return swatchesInRow
end

do
    local SELECTED_ROW_GAP = 0 -- Increase this to make the selected row stand out a little more.
    local DEFAULT_PADDING = 38
    local SELECTED_PADDING = SELECTED_ROW_GAP - DEFAULT_PADDING
    local CONTROL_WIDTH = GetDyeSwatchMaxRowWidth_Gamepad() + 54
    local CONTROL_HEIGHT = GetDyeSwatchSize_Gamepad() + 36

    function ZO_GuildHeraldryManager_Gamepad:PopulateColors(activeSwatches, sortedCategories)
        self.isPopulatingColors = true
        self.colorList:Clear()

        -- Add each swatch row in each category as a separate list entry.
        local swatchRows = {}
        local entryIndex = 1
        for i, category in ipairs(sortedCategories) do
            local swatches = activeSwatches[category]
            table.sort(swatches, ZO_Dyeing_DyeSortComparator)

            local numRows = GetDyeSwatchNumRows(#swatches)
            for row = 1, numRows do
                local isNextEntryAHeader = sortedCategories[i + 1] and (row == numRows)
                local swatchesInRow = GetSwatchesInRow(swatches, row, entryIndex)
                swatchRows[#swatchRows + 1] = swatchesInRow
                entryIndex = entryIndex + 1

                local data = {swatches = swatchesInRow, owner = self, width = CONTROL_WIDTH, height = CONTROL_HEIGHT}
                local postPadding
                local postSelectedOffsetAdditionalPadding
                if isNextEntryAHeader then
                    postPadding = DEFAULT_PADDING
                    postSelectedOffsetAdditionalPadding = -DEFAULT_PADDING
                else
                    postPadding = -DEFAULT_PADDING
                    postSelectedOffsetAdditionalPadding = SELECTED_PADDING
                end

                if row == 1 then
                    data.header = GetString("SI_DYEHUECATEGORY", category)
                    self.colorList:AddEntryWithHeader(COLOR_TEMPLATE_NAME, data, nil, postPadding, SELECTED_PADDING, postSelectedOffsetAdditionalPadding)
                else
                    self.colorList:AddEntry(COLOR_TEMPLATE_NAME, data, nil, postPadding, SELECTED_PADDING, postSelectedOffsetAdditionalPadding)
                end
            end
        end

        -- Setup links for each swatch (up to eight directions).
        for i = 1, #swatchRows do
            local prev = nil
            local prevPrev = nil
            if i > 2 then
                prev = swatchRows[i - 1]
                prevPrev = swatchRows[i - 2]
            elseif i == 2 then
                prev = swatchRows[1]
            end

            local next = nil
            local nextNext = nil
            if i < (#swatchRows - 1) then
                next = swatchRows[i + 1]
                nextNext = swatchRows[i + 2]
            elseif i == (#swatchRows - 1) then
                next = swatchRows[i + 1]
            end

            local swatchRowGroup = {prevPrev = prevPrev, prev = prev, current = swatchRows[i], next = next, nextNext = nextNext}
            SetupSwatchLinks(swatchRowGroup, i)
        end

        self.colorList:Commit()
        self.isPopulatingColors = false

        -- Set the color list to the currently highlighted entry.
        local swatch = self.colorIndexToSwatch[self.activeData.getHighlightedColor()]
        self.colorList:SetSelectedIndex(swatch.row)
    end
end

function ZO_GuildHeraldryManager_Gamepad:SetActiveKeybindDescriptor(descriptor)
    if self.activeKeybindStripDescriptor then
        KEYBIND_STRIP:RemoveKeybindButtonGroup(self.activeKeybindStripDescriptor)
    end

    self.activeKeybindStripDescriptor = descriptor
    KEYBIND_STRIP:AddKeybindButtonGroup(descriptor)
end

function ZO_GuildHeraldryManager_Gamepad:SetMode_Category()
    self:SetActiveKeybindDescriptor(self.categoryKeybindStripDescriptor)
    self:SetDirectionalInputEnabled(false)
    
    GAMEPAD_NAV_QUADRANT_1_BACKGROUND_FRAGMENT:TakeFocus()
    self.categoryList:Activate()
    self.colorList:Deactivate()
    self.bgStyleCatList:Deactivate()
    self.crestStyleCatList:Deactivate()
end

function ZO_GuildHeraldryManager_Gamepad:SetMode_Color()
    self:SetActiveKeybindDescriptor(self.colorKeybindStripDescriptor)
    self:SetDirectionalInputEnabled(true)
    
    GAMEPAD_NAV_QUADRANT_1_BACKGROUND_FRAGMENT:ClearFocus()
    self.categoryList:Deactivate()
    self.colorList:Activate()
    self.bgStyleCatList:Deactivate()
    self.crestStyleCatList:Deactivate()

    self:EnableHighlight()
end

function ZO_GuildHeraldryManager_Gamepad:SetMode_BGStyle()
    self:SetActiveKeybindDescriptor(self.styleKeybindStripDescriptor)

    GAMEPAD_NAV_QUADRANT_1_BACKGROUND_FRAGMENT:ClearFocus()
    self.categoryList:Deactivate()
    self.colorList:Deactivate()

    local subMode = self.activeData.getSubMode()
    self:SetStyleSubMode(subMode)
end

function ZO_GuildHeraldryManager_Gamepad:SetMode_CrestStyle()
    self:SetActiveKeybindDescriptor(self.styleKeybindStripDescriptor)

    GAMEPAD_NAV_QUADRANT_1_BACKGROUND_FRAGMENT:ClearFocus()
    self.categoryList:Deactivate()
    self.colorList:Deactivate()

    local subMode = self.activeData.getSubMode()
    self:SetStyleSubMode(subMode)
end

function ZO_GuildHeraldryManager_Gamepad:SetStyleSubMode(subMode)
    self.activeData.setSubMode(subMode)

    local list = self.bgStyleCatList
    if self.activeData.mode == ZO_HERALDRY_CREST_STYLE_MODE then
        list = self.crestStyleCatList
    end

    if subMode == STYLE_SUBMODE_TOP then
        list:Activate()
        list.control.highlight:SetHidden(false)
        self:HideStyleHighlight()
    else
        list:Deactivate()
        list.control.highlight:SetHidden(true)
        self:EnableHighlight()
    end

    self:SetDirectionalInputEnabled(true)
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.activeKeybindStripDescriptor)
end

function ZO_GuildHeraldryManager_Gamepad:SwitchMode(mode)
    if mode == ZO_HERALDRY_COLOR_MODE then
        self.bgStyleCatListControl:SetHidden(true)
        self.crestStyleCatListControl:SetHidden(true)
        self.stylePane:SetHidden(true)
        self.colorListContainer:SetHidden(false)
    elseif mode == ZO_HERALDRY_BG_STYLE_MODE then
        self.bgStyleCatListControl:SetHidden(false)
        self.crestStyleCatListControl:SetHidden(true)
        self.stylePane:SetHidden(false)
        self.colorListContainer:SetHidden(true)
    elseif mode == ZO_HERALDRY_CREST_STYLE_MODE then
        self.bgStyleCatListControl:SetHidden(true)
        self.crestStyleCatListControl:SetHidden(false)
        self.stylePane:SetHidden(false)
        self.colorListContainer:SetHidden(true)
    else
        self.bgStyleCatListControl:SetHidden(true)
        self.crestStyleCatListControl:SetHidden(true)
        self.stylePane:SetHidden(true)
        self.colorListContainer:SetHidden(true)
    end
end

function ZO_GuildHeraldryManager_Gamepad:SelectMode(mode)
    self.currentMode = mode

    if mode == ZO_HERALDRY_CATEGORY_MODE then
        self:SetMode_Category()
    elseif mode == ZO_HERALDRY_COLOR_MODE then
        self:SetMode_Color()
    elseif mode == ZO_HERALDRY_BG_STYLE_MODE then
        self:SetMode_BGStyle()
    elseif mode == ZO_HERALDRY_CREST_STYLE_MODE then
        self:SetMode_CrestStyle()
    end

    self:UpdateKeybindGroups()
end

function ZO_GuildHeraldryManager_Gamepad:SetSelectedHeraldryIndices()
    ZO_GuildHeraldryManager_Shared.SetSelectedHeraldryIndices(self)

    if self.activeData then
        self:OnCategorySelected(self.activeData)
    end
end

function ZO_GuildHeraldryManager_Gamepad:HighlightColor(newSwatch, becauseOfRebuild, data)
    data = data or self.activeData
    local oldColor = data.getHighlightedColor()
    local newColor = newSwatch and newSwatch.colorIndex
    if oldColor ~= newColor or becauseOfRebuild then
        local oldSwatch = self.colorIndexToSwatch[oldColor]
        if oldSwatch then
            oldSwatch:SetHighlighted(false, becauseOfRebuild, becauseOfRebuild)
        end

        if newColor then
            data.setHighlightedColor(newColor)
            newSwatch:SetHighlighted(true, becauseOfRebuild, becauseOfRebuild)
        else
            self.sharedColorBrowseHighlight:SetHidden(true)
        end
    end

    return newSwatch
end

function ZO_GuildHeraldryManager_Gamepad:HighlightStyle(newStyle, becauseOfRebuild, data)
    data = data or self.activeData
    local oldStyleIndex = data.getHighlightedStyle()
    local newStyleIndex = newStyle and newStyle.styleIndex
    if becauseOfRebuild or oldStyleIndex ~= newStyleIndex or data.getViewCategory() ~= data.getSelectedCategory() then
        local oldStyle = self.styleIndexToStyle[oldStyleIndex]
        if oldStyle then
            oldStyle:SetHighlighted(false)
        end

        if newStyle then
            data.setHighlightedStyle(newStyleIndex)
            newStyle:SetHighlighted(true, becauseOfRebuild, becauseOfRebuild)
        end
    end

    return newStyle
end

function ZO_GuildHeraldryManager_Gamepad:HideColorHighlight(data, resetToSelected)
    local theData = data or self.activeData
    if theData.mode == ZO_HERALDRY_COLOR_MODE then
        if resetToSelected then
            theData.setHighlightedColor(theData.getSelectedColor())
        end
        self:HighlightColor(nil, ZO_HERALDRY_SKIP_ANIM, theData)
    end
end

function ZO_GuildHeraldryManager_Gamepad:HideStyleHighlight(data, resetToSelected)
    local theData = data or self.activeData
    local mode = theData.mode
    if (mode == ZO_HERALDRY_BG_STYLE_MODE) or (mode == ZO_HERALDRY_CREST_STYLE_MODE) then
        if resetToSelected then
            theData.setHighlightedStyle(theData.getSelectedStyle())
        end
        self:HighlightStyle(nil, ZO_HERALDRY_SKIP_ANIM, theData)
    end
end

function ZO_GuildHeraldryManager_Gamepad:EnableHighlight()
    local mode = self.currentMode
    if mode == ZO_HERALDRY_COLOR_MODE then
        self:HighlightColor(self.colorIndexToSwatch[self.activeData.getHighlightedColor()], ZO_HERALDRY_SKIP_ANIM)
    elseif (mode == ZO_HERALDRY_BG_STYLE_MODE) or (mode == ZO_HERALDRY_CREST_STYLE_MODE) then
        self:HighlightStyle(self.styleIndexToStyle[self.activeData.getHighlightedStyle()], ZO_HERALDRY_SKIP_ANIM)
    end
end

function ZO_GuildHeraldryManager_Gamepad:SetDirectionalInputEnabled(enabled)
    if(self.directionalInputEnabled ~= enabled) then
        if enabled then
            DIRECTIONAL_INPUT:Activate(self, self.control)
        else
            DIRECTIONAL_INPUT:Deactivate(self)
        end

        self.directionalInputEnabled = enabled
    end
end

function ZO_GuildHeraldryManager_Gamepad:HighlightColorWithDirection(direction)
    local highlightedColor = self.activeData.getHighlightedColor()
    local swatch = self.colorIndexToSwatch[highlightedColor]

    self.targetSwatchToHighlight = swatch.links[direction]
    if self.targetSwatchToHighlight then
        if (direction == DIRECTION_LEFT) or (direction == DIRECTION_RIGHT) then
            -- Left and Right are special cases because the row doesn't change.
            -- For all other directions, color highlighting is handled in the OnSelectedDataChanged callback.
            PlaySound(SOUNDS.HOR_LIST_ITEM_SELECTED)
            self:HighlightColor(self.targetSwatchToHighlight)
            self.targetSwatchToHighlight = nil
            self:UpdateKeybindGroups()
        else
            self.colorList:SetSelectedIndex(self.targetSwatchToHighlight.row)
        end
    end
end

function ZO_GuildHeraldryManager_Gamepad:UpdateStyleWithDirection(direction)
    if self.activeData.getSubMode(subMode) == STYLE_SUBMODE_TOP then
        if direction == DIRECTION_DOWN or direction == DIRECTION_DOWNLEFT or direction == DIRECTION_DOWNRIGHT then
            PlaySound(SOUNDS.GAMEPAD_MENU_BACK)
            self:SetStyleSubMode(STYLE_SUBMODE_BOTTOM)
        end
    else
        self:HighlightStyleWithDirection(direction)
    end
end

function ZO_GuildHeraldryManager_Gamepad:HighlightStyleWithDirection(direction)
    local styleIndex = self.activeData.getHighlightedStyle()
    local style = self.styleIndexToStyle[styleIndex]

    local newStyle = style.links[direction]
    if newStyle == STYLE_ROW_TOP then
        PlaySound(SOUNDS.GAMEPAD_MENU_UP)
        self:SetStyleSubMode(STYLE_SUBMODE_TOP)
    elseif (newStyle == LINK_DOWN) then 
        PlaySound(SOUNDS.GAMEPAD_MENU_DOWN)
        self:SetStyleSubMode(STYLE_SUBMODE_BOTTOM) 
    elseif newStyle then
        PlaySound(SOUNDS.HOR_LIST_ITEM_SELECTED)
        self:HighlightStyle(newStyle)
        self:UpdateKeybindGroups()
    end
end

do
    function ZO_GuildHeraldryManager_Gamepad:UpdateDirectionalInput()
        local data = self.activeData

        if self.activeData.mode == ZO_HERALDRY_COLOR_MODE or self.activeData.getSubMode() == STYLE_SUBMODE_BOTTOM then
            local result = self.horzMovementController:CheckMovement()
            if result == MOVEMENT_CONTROLLER_MOVE_NEXT then
                data.directionalInputCallback(DIRECTION_RIGHT)
            elseif result == MOVEMENT_CONTROLLER_MOVE_PREVIOUS then
                data.directionalInputCallback(DIRECTION_LEFT)
            end
        end
        
        local result = self.vertMovementController:CheckMovement()
        if result == MOVEMENT_CONTROLLER_MOVE_NEXT then
            data.directionalInputCallback(DIRECTION_DOWN)
        elseif result == MOVEMENT_CONTROLLER_MOVE_PREVIOUS then
            data.directionalInputCallback(DIRECTION_UP)
        end
    end
end

function ZO_GuildHeraldryManager_Gamepad:SelectColor(...)
    ZO_GuildHeraldryManager_Shared.SelectColor(self, ...)
    local targetData = self.categoryList:GetTargetData()
    if targetData and targetData.mode == ZO_HERALDRY_COLOR_MODE then
        self.categoryList:RefreshVisible()
    end
end

function ZO_GuildHeraldryManager_Gamepad:SelectStyle(...)
    ZO_GuildHeraldryManager_Shared.SelectStyle(self, ...)
    local targetCategoryData = self.categoryList:GetTargetData()
    if self.currentMode == ZO_HERALDRY_CREST_STYLE_MODE and targetCategoryData and targetCategoryData.mode == ZO_HERALDRY_CREST_STYLE_MODE then
        self.categoryList:RefreshVisible()
        local style = self.styleIndexToStyle[self.activeData.getSelectedStyle()]
        if style then
            self:HighlightStyle(style, ZO_HERALDRY_SKIP_ANIM, self.activeData)
        end
    end
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
            header = GetString(SI_GUILD_HERALDRY_DIALOG_BANKED_GOLD_HEADER),
        },

        data2 =
        {
            value = function(control) 
                ZO_CurrencyControl_SetSimpleCurrency(control, CURT_MONEY, pendingCost, ZO_GAMEPAD_CURRENCY_OPTIONS)
                return true
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
