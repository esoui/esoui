-----------------------------------
-- GuildHeraldryManager Shared
-----------------------------------

ZO_HERALDRY_CATEGORY_MODE = 1
ZO_HERALDRY_COLOR_MODE = 2
ZO_HERALDRY_BG_STYLE_MODE = 3
ZO_HERALDRY_CREST_STYLE_MODE = 4

ZO_HERALDRY_SKIP_ANIM = true
ZO_HERALDRY_SKIP_SOUND = true

ZO_GuildHeraldryManager_Shared = ZO_Object:Subclass()

function ZO_GuildHeraldryManager_Shared:New(...)
    local manager = ZO_Object.New(self)
    manager:Initialize(...)
    return manager
end

function ZO_GuildHeraldryManager_Shared:Initialize(control, currencyOptions, templateData)
    self.control = control
    self.currencyOptions = currencyOptions

    self.bgStyleCatListControl = self.control:GetNamedChild("BGStyleCategoryList")
    self.crestStyleCatListControl = self.control:GetNamedChild("CrestStyleCategoryList")
    self.pendingTransaction = false

    EndHeraldryCustomization()

    EVENT_MANAGER:RegisterForEvent("guildHeraldry", EVENT_PLAYER_DEACTIVATED, function(eventCode)
        EndHeraldryCustomization()
    end)

    -- This is platform specific data that needs to be overridden by the inheriting classes as it
    -- specifies the platform specific data to use.
    --[[ Expected values in templateData:
        gridListClass - The class object to be use to new the style and color grid lists
        styleEntryTemplate - The template to be used a style element
        styleEntryWidth - The width of a style element
        styleEntryHeight - The height of a style element
        styleGridPadding - The offset of between style elements both horizontally and vertically
        styleEntrySetup - The function used to setup a style element
        styleEntryReset - The function used to reset a style element
        styleHasGridHeader - Bool value of if the style section should have a header internal to the grid list
        colorEntryTemplate - The template to be used a color element
        colorEntryWidth - The width of a color element
        colorEntryHeight - The height of a style element
        colorEntrySetup - The function used to setup a color element
        colorEntryReset - The height of a color element
        headerTemplate - The template used for an in-grid header for both style and color
        headerHeight - The height of the header template
        ]]
    self.templateData = templateData

    self.styleGridListControl = self.control:GetNamedChild("StylePane")
    self.colorGridListControl = self.control:GetNamedChild("ColorPane")
end

local function EqualityFunction(leftData, rightData)
    return leftData.categoryIndex == rightData.categoryIndex and leftData.categoryName == rightData.categoryName
end

function ZO_GuildHeraldryManager_Shared:InitializeStyleCategoryLists(scrollList, scrollListTemplate)
    local function SetupFunction(control, data, selected, selectedDuringRebuild, enabled)
        control:SetHidden(false)

        control:SetTexture(data.icon)
        control.categoryIndex = data.categoryIndex
        control.categoryName = data.categoryName

        if selected then
            self:SetViewedStyleCategory(data.categoryIndex)
            data.categoryList.selectedLabel:SetText(data.categoryName)
        end
    end

    local SHOWN_CATEGORIES = 5
    local MIN_SCALE = .6
    local MAX_SCALE = 1.0

    self.bgStyleCatList = scrollList:New(self.bgStyleCatListControl, scrollListTemplate, SHOWN_CATEGORIES, SetupFunction, EqualityFunction)
    self.bgStyleCatList:SetScaleExtents(MIN_SCALE, MAX_SCALE)
    self.bgStyleCatList.selectedLabel = GetControl(self.bgStyleCatListControl, "SelectedLabel")

    self.crestStyleCatList = scrollList:New(self.crestStyleCatListControl, scrollListTemplate, SHOWN_CATEGORIES, SetupFunction, EqualityFunction)
    self.crestStyleCatList:SetScaleExtents(MIN_SCALE, MAX_SCALE)
    self.crestStyleCatList.selectedLabel = GetControl(self.crestStyleCatListControl, "SelectedLabel")
end

function ZO_GuildHeraldryManager_Shared:PopulateStyleCategoryLists()
    self.bgStyleCatList:Clear()

    for i = 1, GetNumHeraldryBackgroundCategories() do
        local catName, upIcon = GetHeraldryBackgroundCategoryInfo(i)
        local data = { categoryName = catName, icon = upIcon, categoryIndex = i, categoryList = self.bgStyleCatList }
        self.bgStyleCatList:AddEntry(data)
    end

    self.bgStyleCatList:Commit()

    self.crestStyleCatList:Clear()

    for i = 1, GetNumHeraldryCrestCategories() do
        local catName, icon = GetHeraldryCrestCategoryInfo(i)
        local data = { categoryName = catName, icon = icon, categoryIndex = i, categoryList = self.crestStyleCatList }
        self.crestStyleCatList:AddEntry(data)
    end

    self.crestStyleCatList:Commit()
end

function ZO_GuildHeraldryManager_Shared:InitializeStyleGridList()
    local templateData = self.templateData

    self.styleGridList = templateData.gridListClass:New(self.styleGridListControl)

    local NO_HIDE_CALLBACK = nil
    self.styleGridList:AddEntryTemplate(templateData.styleEntryTemplate, templateData.styleEntryWidth, templateData.styleEntryHeight, templateData.styleEntrySetup, NO_HIDE_CALLBACK, templateData.styleEntryReset, templateData.styleGridPadding, templateData.styleGridPadding)
    self.styleGridList:AddHeaderTemplate(templateData.headerTemplate, templateData.headerHeight, ZO_DefaultGridTileHeaderSetup)

    self:BuildStyleGridList()
end

function ZO_GuildHeraldryManager_Shared:InitializeColorGridList()
    local templateData = self.templateData

    self.colorGridList = templateData.gridListClass:New(self.colorGridListControl)

    local NO_HIDE_CALLBACK = nil
    local GRID_PADDING = 0
    local CENTER_ENTRIES = true
    self.colorGridList:AddEntryTemplate(templateData.colorEntryTemplate, templateData.colorEntryWidth, templateData.colorEntryHeight, templateData.colorEntrySetup, NO_HIDE_CALLBACK, templateData.colorEntryReset, GRID_PADDING, GRID_PADDING, CENTER_ENTRIES)
    self.colorGridList:AddHeaderTemplate(templateData.headerTemplate, templateData.headerHeight, ZO_DefaultGridTileHeaderSetup)

    self:InitializeColorCategories()
    self:BuildColorGridList()
end

function ZO_GuildHeraldryManager_Shared:InitializeColorCategories()
    self.colorListsByCategory = {}
    for hueCategory = DYE_HUE_CATEGORY_ITERATION_BEGIN, DYE_HUE_CATEGORY_ITERATION_END do
        self.colorListsByCategory[hueCategory] = {}
    end
    
    for i = 1, GetNumHeraldryColors() do
        local colorName, hueCategory, r, g, b, sortKey = GetHeraldryColorInfo(i)
        local data =
        {
            colorIndex = i,
            dyeName = colorName,
            hueCategory = hueCategory,
            known = true,
            r = r,
            g = g,
            b = b,
            sortKey = sortKey,
        }
        table.insert(self.colorListsByCategory[hueCategory], data)
    end

    for hueCategory = DYE_HUE_CATEGORY_ITERATION_BEGIN, DYE_HUE_CATEGORY_ITERATION_END do
        table.sort(self.colorListsByCategory[hueCategory], ZO_Dyeing_DyeSortComparator)
    end

    self.sortedColorList = {}
    for sortStyleCategory, colors in pairs(self.colorListsByCategory) do
        for _, color in ipairs(colors) do
            color.categoryOrder = sortStyleCategory
            table.insert(self.sortedColorList, color)
        end
    end

    table.sort(self.sortedColorList, ZO_DyeSwatchesGridSort)
end

function ZO_GuildHeraldryManager_Shared:BuildStyleGridList()
    self.styleGridList:ClearGridList()

    if(self.mode == ZO_HERALDRY_BG_STYLE_MODE or self.mode == ZO_HERALDRY_CREST_STYLE_MODE) and self.activeData then
        local templateData = self.templateData

        -- Iterate through styles and create each style
        local selectedStyle = self.activeData.getSelectedStyle()
        local viewingSelectedCategory = self.activeData.getSelectedCategory() == self.activeData.getViewCategory()

        for i = 1, self.activeData.getNum() do
            local gridHeaderName = ""
            if self.activeData.mode == ZO_HERALDRY_BG_STYLE_MODE then
                gridHeaderName = GetString(SI_GUILD_HERALDRY_PATTERN_HEADER)
            elseif self.activeData.mode == ZO_HERALDRY_CREST_STYLE_MODE then
                gridHeaderName = GetString(SI_GUILD_HERALDRY_DESIGN_HEADER)
            end
            if not templateData.styleHasGridHeader and self.stylesHeader then
                self.stylesHeader:SetText(gridHeaderName)
                gridHeaderName = ""
            end

            local styleName, icon = self.activeData.getInfo(i)
            local data =
            {
                index = i,
                styleName = styleName,
                icon = icon,
                checked = viewingSelectedCategory and i == selectedStyle,
                gridHeaderName = gridHeaderName,
                gridHeaderTemplate = templateData.headerTemplate
            }

            self.styleGridList:AddEntry(data, templateData.styleEntryTemplate)
        end

        self.styleGridList:CommitGridList()
    end
end

function ZO_GuildHeraldryManager_Shared:BuildColorGridList()
    self.colorGridList:ClearGridList()

    if self.mode == ZO_HERALDRY_COLOR_MODE and self.activeData then
        local templateData = self.templateData
        local tempTable = {}
        local selectedData = nil
        for i, color in ipairs(self.sortedColorList) do
            color.checked = false
            local swatchObject = ZO_DyeingSwatch_Shared:New(self)
            swatchObject:SetDataSource(color)
            swatchObject.gridHeaderName = GetString("SI_DYEHUECATEGORY", color.categoryOrder)
            swatchObject.gridHeaderTemplate = templateData.headerTemplate
            swatchObject.color = ZO_ColorDef:New(color.r, color.g, color.b)
            if self.activeData and color.colorIndex == self.activeData.getSelectedColorIndex() then
                color.checked = true
                selectedData = swatchObject
            end
            self.colorGridList:AddEntry(swatchObject, templateData.colorEntryTemplate)
        end

        self.colorGridList:CommitGridList()

        if selectedData then
            local NO_CALLBACK = nil
            local ANIMATE_INSTANTLY = true
            self.colorGridList:ScrollDataToCenter(selectedData, NO_CALLBACK, ANIMATE_INSTANTLY)
        end
    end
end

function ZO_GuildHeraldryManager_Shared:OnCategorySelected(data)
    local oldData = self.activeData
    self.activeData = data
    if self.initialized then
        if oldData and (oldData ~= data) and oldData.changed then
            oldData.changed(oldData, data)
        end

        if self.panelNameLabel then
            self.panelNameLabel:SetText(data.name)
        end

        self:SwitchMode(data.mode)

        if data.resetToSelectedCategory then
            data.resetToSelectedCategory()
        end

        data.layout()
    end
end

function ZO_GuildHeraldryManager_Shared:SelectColor(colorIndex, becauseOfRebuild)
    local selectedColorIndex = self.activeData.getSelectedColorIndex()
    if selectedColorIndex ~= colorIndex or becauseOfRebuild then
        local colorDataList = self.colorGridList:GetData()
        for i, entryData in ipairs(colorDataList) do
            if not entryData.data.header and entryData.data.lineBreakAmount == nil then
                local selected = false
                local data = entryData.data:GetDataSource()
                if data.colorIndex == colorIndex then
                    selected = true
                end
                data.checked = selected
                self:SetEntryDataSelected(entryData, selected)
            end
        end

        self.activeData.setSelectedColorIndex(colorIndex)

        self.colorGridList:RefreshGridList()

        if not becauseOfRebuild then
            self:SetPendingIndices()
        end
    end
end

function ZO_GuildHeraldryManager_Shared:SetSelectedHeraldryIndices()
    self.selectedBackgroundCategory, self.selectedBackgroundStyle, self.selectedBackgroundPrimaryColor, self.selectedBackgroundSecondaryColor, self.selectedCrestCategory, self.selectedCrestStyle, self.selectedCrestColor = GetPendingHeraldryIndices()

    self.viewBackgroundCategory = self.selectedBackgroundCategory
    self.viewCrestCategory = self.selectedCrestCategory

    self.bgStyleCatList:SetSelectedDataIndex(self.selectedBackgroundCategory)
    self.crestStyleCatList:SetSelectedDataIndex(self.selectedCrestCategory)
end

function ZO_GuildHeraldryManager_Shared:SetGuildId(guildId)
    if self.guildId ~= guildId then
        self.guildId = guildId

        if SCENE_MANAGER:IsShowing("guildHeraldry") then
            EndHeraldryCustomization()
            StartHeraldryCustomization(guildId)
        end
    end
end

function ZO_GuildHeraldryManager_Shared:IsEnabled()
    return IsPlayerAllowedToEditHeraldry(self.guildId)
end

function ZO_GuildHeraldryManager_Shared:SetViewedStyleCategory(index)
    self.activeData.setViewCategory(index)
    self.activeData.layout()
end

function ZO_GuildHeraldryManager_Shared:SetSelectedStyleCategory(index)
    self.activeData.setSelectedCategory(index)
end

function ZO_GuildHeraldryManager_Shared:SetPendingIndices()
    SetPendingHeraldryIndices(
        self.selectedBackgroundCategory, self.selectedBackgroundStyle, self.selectedBackgroundPrimaryColor, self.selectedBackgroundSecondaryColor,
        self.selectedCrestCategory, self.selectedCrestStyle, self.selectedCrestColor
    )

    self:UpdateKeybindGroups()
end

function ZO_GuildHeraldryManager_Shared:IsViewingStyleCategoryWithSelection()
    if self.activeData and self.activeData.mode ~= ZO_HERALDRY_COLOR_MODE then
        return self.activeData.getViewCategory() == self.activeData.getSelectedCategory()
    end
    return false
end

function ZO_GuildHeraldryManager_Shared:SelectStyle(styleIndex, becauseOfRebuild)
    local previouslySelectedIndex = self.activeData.getSelectedStyle()
    if becauseOfRebuild or not self:IsViewingStyleCategoryWithSelection() or previouslySelectedIndex ~= styleIndex then
        local styleDataList = self.styleGridList:GetData()
        for i, entryData in ipairs(styleDataList) do
            if not entryData.data.header then
                local data = entryData.data
                data.checked = data.index == styleIndex
            end
        end

        self.activeData.setSelectedCategory(self.activeData.getViewCategory())
        self.activeData.setSelectedStyle(styleIndex)

        self.styleGridList:RefreshGridList()

        if not becauseOfRebuild then
            self:SetPendingIndices()
        end
    end
end

function ZO_GuildHeraldryManager_Shared:CanSave()
    return not IsCreatingHeraldryForFirstTime() and HasPendingHeraldryChanges()
end

function ZO_GuildHeraldryManager_Shared:SetPendingExit(isPendingExit)
    self.isPendingExit = isPendingExit
end

function ZO_GuildHeraldryManager_Shared:IsPendingExit()
    return self.isPendingExit
end

function ZO_GuildHeraldryManager_Shared:IsCurrentBlockingScene()
    return false -- May be overridden
end

function ZO_GuildHeraldryManager_Shared:AttemptSaveIfBlocking(showBaseScene)
    local attemptedSave = false

    if self:IsCurrentBlockingScene() then
        self:AttemptSaveAndExit(showBaseScene)
        attemptedSave = true
    end

    return attemptedSave
end

function ZO_GuildHeraldryManager_Shared:AttemptPromptSaveWarning()
    if HasPendingHeraldryChanges() then
        self:SetPendingExit(true)
        if not IsCreatingHeraldryForFirstTime() then
            local pendingCost = GetPendingHeraldryCost()
            local heraldryFunds = GetHeraldryGuildBankedMoney()
            if heraldryFunds and pendingCost <= heraldryFunds then
                self:ConfirmHeraldryApplyChanges()
                return true
            end
        end
    end

    return false
end

function ZO_GuildHeraldryManager_Shared:AttemptSaveAndExit(showBaseScene)
    if not self:AttemptPromptSaveWarning() then
        self:ConfirmExit(showBaseScene)
    end
end

function ZO_GuildHeraldryManager_Shared:OnConfirmHideScene(scene, nextSceneName, bypassHideSceneConfirmationReason)
    if bypassHideSceneConfirmationReason == nil then
        if self:AttemptPromptSaveWarning() then
            return
        end
    end
    scene:AcceptHideScene()
end

function ZO_GuildHeraldryManager_Shared:ConfirmExit(showBaseScene)
    -- Should be overridden by child classes
end

function ZO_GuildHeraldryManager_Shared:CancelExit()
    -- Should be overridden by child classes
end

function ZO_GuildHeraldryManager_Shared:NoChoiceExitCallback()
    -- Should be overridden by child classes
end

function ZO_GuildHeraldryManager_Shared:SwitchMode(mode)
    if self.mode ~= mode then
        self.mode = mode
        if mode == ZO_HERALDRY_COLOR_MODE then
            self.bgStyleCatListControl:SetHidden(true)
            self.crestStyleCatListControl:SetHidden(true)
            self.styleGridListControl:SetHidden(true)
            self.colorGridListControl:SetHidden(false)
            self:BuildColorGridList()
        elseif mode == ZO_HERALDRY_BG_STYLE_MODE then
            self.bgStyleCatListControl:SetHidden(false)
            self.crestStyleCatListControl:SetHidden(true)
            self.styleGridListControl:SetHidden(false)
            self.colorGridListControl:SetHidden(true)
            self:BuildStyleGridList()
        elseif mode == ZO_HERALDRY_CREST_STYLE_MODE then
            self.bgStyleCatListControl:SetHidden(true)
            self.crestStyleCatListControl:SetHidden(false)
            self.styleGridListControl:SetHidden(false)
            self.colorGridListControl:SetHidden(true)
            self:BuildStyleGridList()
        else
            self.bgStyleCatListControl:SetHidden(true)
            self.crestStyleCatListControl:SetHidden(true)
            self.styleGridListControl:SetHidden(true)
            self.colorGridListControl:SetHidden(true)
            self:BuildColorGridList()
        end
    end
end

function ZO_GuildHeraldryManager_Shared:SetEntryDataSelected(entryData, selected)
    -- To be overridden
end

--[[
    Dialog functions.
--]]

function ZO_GuildHeraldryManager_Shared:GetPurchaseDialogName()
    -- Must be overridden
    assert(false)
end

function ZO_GuildHeraldryManager_Shared:GetApplyChangesDialogName()
    -- Must be overridden
    assert(false)
end

local function SetupHeraldryDialog(control)
    control.data.owner:SetupHeraldryDialog(control)
end

function ZO_GuildHeraldryManager_Shared:PurchaseHeraldryDialogInitialize(control)
    if ZO_Dialogs_IsDialogRegistered(self:GetPurchaseDialogName()) then
        return
    end

    ZO_Dialogs_RegisterCustomDialog(self:GetPurchaseDialogName(),
    {
        customControl = control,
        setup = SetupHeraldryDialog,
        gamepadInfo =
        {
            dialogType = GAMEPAD_DIALOGS.BASIC,
        },
        title =
        {
            text = SI_GUILD_HERALDRY_DIALOG_PURCHASE_TITLE,
        },
        mainText = 
        {
            text = SI_GUILD_HERALDRY_DIALOG_PURCHASE_DESCRIPTION,
        },
        buttons =
        {
            {
                keybind =   "DIALOG_PRIMARY",
                control =   control and GetControl(control, "Accept"),
                text =      SI_DIALOG_ACCEPT,
                callback =  function(dialog)
                    ApplyPendingHeraldryChanges()
                    dialog.data.owner.pendingTransaction = true
                end,
            },
            {
                keybind =   "DIALOG_NEGATIVE",
                control =   control and GetControl(control, "Cancel"),
                text =      SI_DIALOG_CANCEL,
                callback =  function(dialog)
                    -- Do nothing
                end,
            },
        }
    })
end

function ZO_GuildHeraldryManager_Shared:ApplyChangesHeraldryDialogInitialize(control)
    if ZO_Dialogs_IsDialogRegistered(self:GetApplyChangesDialogName()) then
        return
    end

    ZO_Dialogs_RegisterCustomDialog(self:GetApplyChangesDialogName(),
    {
        customControl = control,
        setup = SetupHeraldryDialog,
        gamepadInfo =
        {
            dialogType = GAMEPAD_DIALOGS.BASIC,
        },
        title =
        {
            text = SI_GUILD_HERALDRY_DIALOG_APPLY_CHANGES_TITLE,
        },
        mainText = 
        {
            text =  function()
                local textValue
                if self:IsPendingExit() then
                    textValue = SI_GUILD_HERALDRY_DIALOG_APPLY_CHANGES_PENDING_EXIT_DESCRIPTION
                else
                    textValue = SI_GUILD_HERALDRY_DIALOG_APPLY_CHANGES_DESCRIPTION
                end

                return textValue
            end,
        },
        noChoiceCallback =  function()
            if self:IsPendingExit() then
                self:NoChoiceExitCallback()
            end
        end,
        buttons =
        {
            {
                keybind =   "DIALOG_PRIMARY",
                control =   control and GetControl(control, "Accept"),
                text =      SI_GUILD_HERALDRY_DIALOG_ACCEPT,
                callback =  function(dialog)
                    ApplyPendingHeraldryChanges()
                    dialog.data.owner.pendingTransaction = true

                    if self:IsPendingExit() then
                        self:ConfirmExit()
                    end
                end,
            },
            {
                keybind =   "DIALOG_NEGATIVE",
                control =   control and GetControl(control, "Cancel"),
                text =      SI_GUILD_HERALDRY_DIALOG_CANCEL,
                callback =  function(dialog)
                    if self:IsPendingExit() then
                        self:ConfirmExit()
                    end
                end,
            },
            {
                keybind =   "DIALOG_TERTIARY",
                control =   control and GetControl(control, "Return"),
                text =      SI_GAMEPAD_GUILD_HERALDRY_CANCEL_EXIT,
                callback =  function(dialog)
                    self:CancelExit()
                end,
                visible =   function()
                    return IsInGamepadPreferredMode() and self:IsPendingExit()
                end,
            },
        }
    })
end

function ZO_GuildHeraldryManager_Shared:ConfirmHeraldryPurchase(control, showDialogFunc)
    if not self.m_purchaseHeraldryDialog then
        self.m_purchaseHeraldryDialog = true
        self:PurchaseHeraldryDialogInitialize(control)
    end

    local data = { owner = self }
    showDialogFunc(self:GetPurchaseDialogName(), data)
end

function ZO_GuildHeraldryManager_Shared:ConfirmHeraldryApplyChanges(control, showDialogFunc)
    if not self.m_applyChangesHeraldryDialog then
        self.m_applyChangesHeraldryDialog = true
        self:ApplyChangesHeraldryDialogInitialize(control)
    end

    local data = { owner = self }
    showDialogFunc(self:GetApplyChangesDialogName(), data)
end

--[[
    Global XML.
--]]

function ZO_GuildHeraldry_DyeingSwatch_OnMouseEnter(swatchControl)
    local swatchObject = swatchControl.object
    if swatchObject then
        swatchObject.mousedOver = true
        swatchObject:UpdateSelectedState()
    end
end

function ZO_GuildHeraldry_DyeingSwatch_OnMouseExit(swatchControl)
    local swatchObject = swatchControl.object
    if swatchObject then
        swatchObject.mousedOver = false
        swatchObject:UpdateSelectedState()
    end
end
