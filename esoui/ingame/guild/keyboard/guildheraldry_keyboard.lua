local STYLE_FRAME_INDEX = 3

ZO_GuildHeraldryManager_Keyboard = ZO_GuildHeraldryManager_Shared:Subclass()

function ZO_GuildHeraldryManager_Keyboard:New(...)
    return ZO_GuildHeraldryManager_Shared.New(self, ...)
end

local function OnBlockingSceneActivated()
    GUILD_HERALDRY:AttemptSaveAndExit()
end

function ZO_GuildHeraldryManager_Keyboard:Initialize(control)
    ZO_GuildHeraldryManager_Shared.Initialize(self, control, CURRENCY_OPTIONS)

    self.costControl = self.control:GetNamedChild("Cost")
    self.sharedColorSelectedHighlight = self.control:GetNamedChild("SharedColorHighlight")
    self.sharedStyleSelectedHighlight = self.control:GetNamedChild("SharedStyleHighlight")
    self.sharedStyleSelectedHighlight.animation = ANIMATION_MANAGER:CreateTimelineFromVirtual("ShowOnMouseOverLabelAnimation", self.sharedStyleSelectedHighlight)
    self.categoryList = self.control:GetNamedChild("Categories")
    self.categoryListScrollChild = self.categoryList:GetNamedChild("ScrollChild")
    self.panelNameLabel = self.control:GetNamedChild("PanelName")
    self.colorPane = self.control:GetNamedChild("ColorPane")
    self.colorPaneScrollChild = self.colorPane:GetNamedChild("ScrollChild")
    self.categoriesHeader = self.control:GetNamedChild("CategoriesHeader")

    self:InitializeSwatchPool("ZO_GuildHeraldry_DyeingSwatch", self.colorPaneScrollChild)
    self:InitializeStylePool("ZO_GuildHeraldry_Style")
    self:InitializeHeaderPool()

    self:InitializeKeybindStripDescriptors()
    self:InitializeNavigationTree()
    self:InitializeCategories()
    self:InitializeStyleCategoryLists(ZO_HorizontalScrollList, "ZO_GuildHeraldry_StyleCategory")
    self:PopulateStyleCategoryLists()

    GUILD_HERALDRY_SCENE = ZO_Scene:New("guildHeraldry", SCENE_MANAGER)
    GUILD_HERALDRY_SCENE:RegisterCallback("StateChange", function(oldState, newState)
        if(newState == SCENE_SHOWING) then
            MAIN_MENU_MANAGER:SetBlockingScene("guildHeraldry", OnBlockingSceneActivated)
            KEYBIND_STRIP:RemoveDefaultExit()
            StartHeraldryCustomization(self.guildId)
        elseif(newState == SCENE_HIDDEN) then
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
            KEYBIND_STRIP:RestoreDefaultExit()
            EndHeraldryCustomization()
        end
    end)

    self.control:RegisterForEvent(EVENT_HERALDRY_CUSTOMIZATION_START, function(eventCode)
        if not IsInGamepadPreferredMode() then
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

function ZO_GuildHeraldryManager_Keyboard:InitializeHeaderPool()
    self.colorHeaderPool = ZO_ControlPool:New("ZO_DyeingHeader", self.colorPaneScrollChild)
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

function ZO_GuildHeraldryManager_Keyboard:IsCurrentBlockingScene()
    return MAIN_MENU_MANAGER:GetBlockingSceneName() == "guildHeraldry"
end

function ZO_GuildHeraldryManager_Keyboard:ConfirmExit()
    if self.changeGuildCallback then
        local callback = self.changeGuildCallback
        local params = self.changeGuildParams

        self.changeGuildCallback = nil
        self.changeGuildParams = nil

        callback(params)
    elseif not MAIN_MENU_MANAGER:HasBlockingSceneNextScene() then
        SCENE_MANAGER:HideCurrentScene()
    end

    self:SetPendingExit(false)
    MAIN_MENU_MANAGER:ClearBlockingScene(OnBlockingSceneActivated)
end

function ZO_GuildHeraldryManager_Keyboard:CancelExit()
    MAIN_MENU_MANAGER:CancelBlockingSceneNextScene()
    self.changeGuildCallback = nil
    self.changeGuildParams = nil
    self:SetPendingExit(false)
end

function ZO_GuildHeraldryManager_Keyboard:NoChoiceExitCallback()
    self:CancelExit()
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

        -- Custom Exit
        {
            alignment = KEYBIND_STRIP_ALIGN_RIGHT,
            name = GetString(SI_EXIT_BUTTON),
            keybind = "UI_SHORTCUT_EXIT",
            callback = function()
                self:AttemptSaveAndExit()
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
        if(open and userRequested) then
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
    local bgMenuData = {
        name = GetString(SI_GUILD_HERALDRY_BACKGROUND),
        normalIcon = "EsoUI/Art/Guild/guildHeraldry_indexIcon_background_up.dds",
        pressedIcon = "EsoUI/Art/Guild/guildHeraldry_indexIcon_background_down.dds",
        mouseoverIcon = "EsoUI/Art/Guild/guildHeraldry_indexIcon_background_over.dds",
    }
    local parent = self.navigationTree:AddNode("ZO_IconHeader", bgMenuData)

    local function LayoutStyles()
        local function AnchorHeraldryStyle(currentAnchor, style, index)
            local STRIDE = 6
            local STYLE_SIZE = 64
            local PADDING = 18
            local INITIAL_OFFSET_X = 40
            local INITIAL_OFFSET_Y = 40

            ZO_Anchor_BoxLayout(currentAnchor, style, index - 1, STRIDE, PADDING, PADDING, STYLE_SIZE, STYLE_SIZE, INITIAL_OFFSET_X, INITIAL_OFFSET_Y)
        end

        self:LayoutStyles(AnchorHeraldryStyle)
    end
    local function LayoutColors()
        self:LayoutColors()
    end

    local bgStyleCost, bgPrimaryColorCost, bgSecondaryColorCost, crestStyleCost, crestColorCost = GetHeraldryCustomizationCosts()

    local bgStyleData = {
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
        styleHeaderName = GetString(SI_GUILD_HERALDRY_PATTERN_HEADER),
    }

    self.navigationTree:AddNode("ZO_GuildHeraldry_ChildEntry", bgStyleData, parent)

    local bgPrimaryColorData = {
        name = GetString(SI_GUILD_HERALDRY_PRIMARY_COLOR),
        mode = ZO_HERALDRY_COLOR_MODE,
        cost = bgPrimaryColorCost,
        layout = LayoutColors,
        setSelectedColor = function(index) self.selectedBackgroundPrimaryColor = index end,
        getSelectedColor = function() return self.selectedBackgroundPrimaryColor end,
    }

    self.navigationTree:AddNode("ZO_GuildHeraldry_ChildEntry", bgPrimaryColorData, parent)

    local bgSecondaryColorData = {
        name = GetString(SI_GUILD_HERALDRY_SECONDARY_COLOR),
        mode = ZO_HERALDRY_COLOR_MODE,
        cost = bgSecondaryColorCost,
        layout = LayoutColors,
        setSelectedColor = function(index) self.selectedBackgroundSecondaryColor = index end,
        getSelectedColor = function() return self.selectedBackgroundSecondaryColor end,
    }

    self.navigationTree:AddNode("ZO_GuildHeraldry_ChildEntry", bgSecondaryColorData, parent)

    local crestMenuData = {
        name = GetString(SI_GUILD_HERALDRY_CREST),
        normalIcon = "EsoUI/Art/Guild/guildHeraldry_indexIcon_crest_up.dds",
        pressedIcon = "EsoUI/Art/Guild/guildHeraldry_indexIcon_crest_down.dds",
        mouseoverIcon = "EsoUI/Art/Guild/guildHeraldry_indexIcon_crest_over.dds",
    }

    parent = self.navigationTree:AddNode("ZO_IconHeader", crestMenuData)

    local crestStyleData = {
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
        styleHeaderName = GetString(SI_GUILD_HERALDRY_DESIGN_HEADER),
    }

    self.navigationTree:AddNode("ZO_GuildHeraldry_ChildEntry", crestStyleData, parent)

     local crestColorData = {
        name = GetString(SI_GUILD_HERALDRY_COLOR),
        mode = ZO_HERALDRY_COLOR_MODE,
        cost = crestColorCost,
        layout = LayoutColors,
        setSelectedColor = function(index) self.selectedCrestColor = index end,
        getSelectedColor = function() return self.selectedCrestColor end,
    }

    self.navigationTree:AddNode("ZO_GuildHeraldry_ChildEntry", crestColorData, parent)

    self.navigationTree:Commit()
end

function ZO_GuildHeraldryManager_Keyboard:SwitchMode(mode)
    if mode == ZO_HERALDRY_COLOR_MODE then
        self.bgStyleCatListControl:SetHidden(true)
        self.crestStyleCatListControl:SetHidden(true)
        self.categoriesHeader:SetHidden(true)
        self.stylePane:SetHidden(true)
        self.colorPane:SetHidden(false)
    elseif mode == ZO_HERALDRY_BG_STYLE_MODE then
        self.bgStyleCatListControl:SetHidden(false)
        self.crestStyleCatListControl:SetHidden(true)
        self.categoriesHeader:SetHidden(false)
        self.stylePane:SetHidden(false)
        self.colorPane:SetHidden(true)
    elseif mode == ZO_HERALDRY_CREST_STYLE_MODE then
        self.bgStyleCatListControl:SetHidden(true)
        self.crestStyleCatListControl:SetHidden(false)
        self.categoriesHeader:SetHidden(false)
        self.stylePane:SetHidden(false)
        self.colorPane:SetHidden(true)
    else
        self.bgStyleCatListControl:SetHidden(true)
        self.crestStyleCatListControl:SetHidden(true)
        self.categoriesHeader:SetHidden(true)
        self.stylePane:SetHidden(true)
        self.colorPane:SetHidden(true)
    end

    self.currentMode = mode
end

function ZO_GuildHeraldryManager_Keyboard:SetSelectedHeraldryIndices()
    ZO_GuildHeraldryManager_Shared.SetSelectedHeraldryIndices(self)

    if self.activeData then
        self:OnCategorySelected(self.activeData)
    end
end

function ZO_GuildHeraldryManager_Keyboard:PopulateColors(activeSwatches, sortedCategories)
    local nextHeaderOffsetY = 0
    local lastHeader
    local selectedColor = self.activeData and self.activeData.getSelectedColor() or nil

    for i, category in ipairs(sortedCategories) do
        local swatches = activeSwatches[category]
        local header = self.colorHeaderPool:AcquireObject()
        header:SetAnchor(TOPLEFT, lastHeader or self.colorPaneScrollChild, TOPLEFT, 0, nextHeaderOffsetY)
        header:SetText(GetString("SI_DYEHUECATEGORY", category))

        local currentAnchor = ZO_Anchor:New(CENTER, header, BOTTOMLEFT)

        table.sort(swatches, ZO_Dyeing_DyeSortComparator)
        local maxHeaderOffsetY = 0
        for j, swatch in ipairs(swatches) do
            local offsetY = AnchorDyeSwatch(currentAnchor, swatch, j)
            maxHeaderOffsetY = zo_max(maxHeaderOffsetY, offsetY)

            if swatch.colorIndex == selectedColor then
                self:SelectColor(swatch.colorIndex, ZO_HERALDRY_SKIP_ANIM)
            end
        end

        nextHeaderOffsetY = GetNextDyeHeaderOffsetY(maxHeaderOffsetY, header)
        lastHeader = header
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

do
    local TEXTURE_WIDTH = 256
    local TEXTURE_HEIGHT = 256

    local FRAME_WIDTH = 64
    local FRAME_HEIGHT = 64

    local FRAME_SLICE_WIDTH = 64
    local FRAME_SLICE_HEIGHT = 64

    local FRAME_PADDING_X = (FRAME_SLICE_WIDTH - FRAME_WIDTH)
    local FRAME_PADDING_Y = (FRAME_SLICE_HEIGHT - FRAME_HEIGHT)

    local FRAME_WIDTH_TEX_COORD = FRAME_WIDTH / TEXTURE_WIDTH
    local FRAME_HEIGHT_TEX_COORD = FRAME_HEIGHT / TEXTURE_HEIGHT

    local FRAME_PADDING_X_TEX_COORD = FRAME_PADDING_X / TEXTURE_WIDTH
    local FRAME_PADDING_Y_TEX_COORD = FRAME_PADDING_Y / TEXTURE_HEIGHT

    local FRAME_START_TEXCOORD_X = 0.0 + FRAME_PADDING_X_TEX_COORD * .5
    local FRAME_START_TEXCOORD_Y = 0.0 + FRAME_PADDING_Y_TEX_COORD * .5

    local FRAME_NUM_COLS = 4
    local FRAME_NUM_ROWS = 2

    local function PickRandomFrame(self)
        local col = zo_random(FRAME_NUM_COLS)
        local row = zo_random(FRAME_NUM_ROWS)

        local left = FRAME_START_TEXCOORD_X + (col - 1) * (FRAME_WIDTH_TEX_COORD + FRAME_PADDING_X_TEX_COORD)
        local right = left + FRAME_WIDTH_TEX_COORD 

        local top = FRAME_START_TEXCOORD_Y + (row - 1) * (FRAME_HEIGHT_TEX_COORD + FRAME_PADDING_Y_TEX_COORD)
        local bottom = top + FRAME_HEIGHT_TEX_COORD
        self:SetTextureCoords(STYLE_FRAME_INDEX, left, right, top, bottom)
    end

    function ZO_GuildHeraldry_StyleFrame_OnInitialized(self)
        PickRandomFrame(self)
    end
end
