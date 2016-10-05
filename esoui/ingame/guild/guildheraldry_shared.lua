local COLOR_SWATCH_INDEX = 1
local COLOR_FRAME_INDEX = 2
local COLOR_MUNGE_INDEX = 3
local COLOR_LOCK_INDEX = 4

local STYLE_BACKGROUND_INDEX = 1
local STYLE_SELECTED_INDEX = 2

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

function ZO_GuildHeraldryManager_Shared:Initialize(control, currencyOptions)
    self.control = control
    self.currencyOptions = currencyOptions

    self.styleHeader = self.control:GetNamedChild("StyleHeader")
    self.bgStyleCatListControl = self.control:GetNamedChild("BGStyleCategoryList")
    self.crestStyleCatListControl = self.control:GetNamedChild("CrestStyleCategoryList")
    self.stylePane = self.control:GetNamedChild("StylePane")
    self.stylePaneScrollChild = self.stylePane:GetNamedChild("ScrollChild")
    self.pendingTransaction = false

    self.swatchInterpolator = ZO_SimpleControlScaleInterpolator:New(1.0, 1.3)

    EndHeraldryCustomization()

    EVENT_MANAGER:RegisterForEvent("guildHeraldry", EVENT_PLAYER_DEACTIVATED, function(eventCode)
        EndHeraldryCustomization()
    end)
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
        local catName, upIcon, downIcon, overIcon = GetHeraldryBackgroundCategoryInfo(i)
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

function ZO_GuildHeraldryManager_Shared:InitializeSwatchPool(template, parent)
    self.swatchPool = ZO_ControlPool:New(template, parent)

    local function SetSelected(swatch, selected, skipAnim, skipSound)
        if swatch.selected ~= selected then
            swatch.selected = selected
            if selected and not skipSound then
                PlaySound(SOUNDS.DYEING_SWATCH_SELECTED)
            end
            swatch:UpdateSelectedState(skipAnim)
        end
    end

    local function SetHighlighted(swatch, highlighted, skipAnim, skipSound)
        if swatch.highlighted ~= highlighted then
            swatch.highlighted = highlighted
            if highlighted and not skipSound then
                -- TODO: Need to play a sound here?
            end
            swatch:UpdateHighlightedState(skipAnim)
        end
    end

    local function UpdateState(swatch, skipAnim, highlight, isActive, width)
        if swatch.mousedOver or isActive then
            if skipAnim then
                self.swatchInterpolator:ResetToMax(swatch)
            else
                self.swatchInterpolator:ScaleUp(swatch)
            end
        else
            if skipAnim then
                self.swatchInterpolator:ResetToMin(swatch)
            else
                self.swatchInterpolator:ScaleDown(swatch)
            end
        end

        if highlight and isActive then
            highlight:SetParent(swatch)
            highlight:SetAnchor(TOPLEFT, swatch, TOPLEFT, -width, -width)
            highlight:SetAnchor(BOTTOMRIGHT, swatch, BOTTOMRIGHT, width, width)
            highlight:SetHidden(false)
        end
    end

    local function UpdateSelectedState(swatch, skipAnim)
        UpdateState(swatch, skipAnim, self.sharedColorSelectedHighlight, swatch.selected, 5)
    end

    local function UpdateHighlightedState(swatch, skipAnim)
        UpdateState(swatch, skipAnim, self.sharedColorBrowseHighlight, swatch.selected or swatch.highlighted, 2)
    end

    local function OnClicked(swatch, button, upInside)
        if upInside and button == MOUSE_BUTTON_INDEX_LEFT then
            self:SelectColor(swatch.colorIndex)
        end
    end

    local function OnSwatchCreated(swatch)
        swatch:SetHandler("OnMouseUp", OnClicked)
        swatch.SetSelected = SetSelected
        swatch.SetHighlighted = SetHighlighted
        swatch.UpdateSelectedState = UpdateSelectedState
        swatch.UpdateHighlightedState = UpdateHighlightedState
        swatch.owner = self

        swatch:SetSurfaceHidden(COLOR_LOCK_INDEX, true)
    end

    local function OnSwatchReset(swatch)
        swatch:SetSelected(false, ZO_HERALDRY_SKIP_ANIM)
        swatch:SetHighlighted(false, ZO_HERALDRY_SKIP_ANIM)
    end

    self.swatchPool:SetCustomFactoryBehavior(OnSwatchCreated)
    self.swatchPool:SetCustomResetBehavior(OnSwatchReset)
end

function ZO_GuildHeraldryManager_Shared:InitializeStylePool(template)
    self.stylePool = ZO_ControlPool:New(template, self.stylePaneScrollChild)

    local function SetSelected(style, selected, skipAnim, skipSound)
        if style.selected ~= selected then
            style.selected = selected
            if selected and not skipSound then
                PlaySound(SOUNDS.GUILD_HERALDRY_STYLE_SELECTED)
            end
            style:UpdateSelectedState(skipAnim)
        end
    end

    local function SetHighlighted(style, highlighted, skipAnim, skipSound)
        if style.highlighted ~= highlighted then
            style.highlighted = highlighted
            if highlighted and not skipSound then
                -- TODO: Need to play a sound here?
            end
            style:UpdateHighlightedState(skipAnim)
        end
    end

    local function UpdateState(style, skipAnim, highlight, isActive, width)
        if highlight then
            if style.mousedOver or isActive then
                highlight:SetParent(style)
                highlight:SetAnchor(CENTER, style, CENTER, 0, 0)
                if highlight.animation then
                    highlight.animation:PlayForward()
                elseif highlight.blockAlphaChanges then
                    highlight:SetHidden(false)
                else
                    highlight:SetAlpha(1)
                end
            else
                if highlight.animation then
                    highlight.animation:PlayBackward()
                elseif highlight.blockAlphaChanges then
                    highlight:SetHidden(true)
                else
                    highlight:SetAlpha(0)
                end
            end
        end

        if style.frame then
            if style.frame.SetSurfaceHidden then
                style.frame:SetSurfaceHidden(STYLE_SELECTED_INDEX, not isActive)
            elseif width then
                width = isActive and width or 0
                style.frame:SetAnchor(TOPLEFT, style, TOPLEFT, -width, -width)
                style.frame:SetAnchor(BOTTOMRIGHT, style, BOTTOMRIGHT, width, width)
            end
        end
        
        if style.highlight then
            local shouldHaveHighlight = isActive
            
            if not width then
                shouldHaveHighlight = false
            end

            style.highlight:SetHidden(not shouldHaveHighlight)
        end
    end

    local DEFAULT_WIDTH = 10

    local function UpdateSelectedState(style, skipAnim)
        UpdateState(style, skipAnim, self.sharedStyleSelectedHighlight, style.selected, DEFAULT_WIDTH)
    end

    local function UpdateHighlightedState(style, skipAnim)
        UpdateState(style, skipAnim, nil, style.highlighted, DEFAULT_WIDTH)
    end

    local function OnClicked(style, button, upInside)
        if upInside and button == MOUSE_BUTTON_INDEX_LEFT then
            self:SelectStyle(style.styleIndex)
        end
    end

    local function OnStyleCreated(style)
        style:SetHandler("OnMouseUp", OnClicked)
        style.UpdateSelectedState = UpdateSelectedState
        style.UpdateHighlightedState = UpdateHighlightedState
        style.SetSelected = SetSelected
        style.SetHighlighted = SetHighlighted
        style.icon = GetControl(style, "Icon")
        style.frame = GetControl(style, "Frame")
        style.highlight = GetControl(style, "Highlight")
        style.owner = self
        style:SetSelected(false, ZO_HERALDRY_SKIP_ANIM)
    end

    local function OnStyleReset(style)
        style:SetSelected(false, ZO_HERALDRY_SKIP_ANIM)
        style:SetHighlighted(false, ZO_HERALDRY_SKIP_ANIM)
    end

    self.stylePool:SetCustomFactoryBehavior(OnStyleCreated)
    self.stylePool:SetCustomResetBehavior(OnStyleReset)
end

local CURRENCY_OPTIONS =
{
    showTooltips = false,
    font = "ZoFontGameShadow",
    iconSide = RIGHT,
}

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
        if self.costControl then
            if data.cost then
                self.costControl:SetHidden(false)
                ZO_CurrencyControl_SetSimpleCurrency(self.costControl, CURT_MONEY, data.cost, self.currencyOptions)
            else
                self.costControl:SetHidden(true)
            end
        end

        if data.resetToSelectedCategory then
            data.resetToSelectedCategory()
        end

        data.layout()
    end
end

function ZO_GuildHeraldryManager_Shared:SelectColor(colorIndex, becauseOfRebuild)
    local selectedColor = self.activeData.getSelectedColor()
    if selectedColor ~= colorIndex or becauseOfRebuild then
        local oldSwatch = not becauseOfRebuild and self.colorIndexToSwatch[selectedColor]
        if oldSwatch then
            oldSwatch:SetSelected(false)
        end

        self.activeData.setSelectedColor(colorIndex)

        local newSwatch = self.colorIndexToSwatch[colorIndex]
        if newSwatch then
            newSwatch:SetSelected(true, becauseOfRebuild, becauseOfRebuild)
            if self.colorPane then
                ZO_Scroll_ScrollControlIntoCentralView(self.colorPane, self.colorIndexToSwatch[colorIndex])
            end
        else
            self.sharedColorSelectedHighlight:SetHidden(true)
        end

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

        if(SCENE_MANAGER:IsShowing("guildHeraldry")) then
            EndHeraldryCustomization()
            StartHeraldryCustomization(guildId)
        end
    end
end

function ZO_GuildHeraldryManager_Shared:IsEnabled()
    return IsPlayerAllowedToEditHeraldry(self.guildId)
end

function ZO_GuildHeraldryManager_Shared:LayoutColors()
    self.swatchPool:ReleaseAllObjects()
    if self.colorHeaderPool then
        self.colorHeaderPool:ReleaseAllObjects()
    end

    self.colorIndexToSwatch = {}
    local activeSwatches = {}

    for i = 1, GetNumHeraldryColors() do
        local colorName, hueCategory, r, g, b, sortKey = GetHeraldryColorInfo(i)

        if not activeSwatches[hueCategory] then
            activeSwatches[hueCategory] = {}
        end

        local parentCategory = activeSwatches[hueCategory]
        local swatch = self.swatchPool:AcquireObject()

        swatch:SetColor(COLOR_SWATCH_INDEX, r, g, b)
        swatch.sortKey = sortKey
        swatch.colorName = colorName
        swatch.colorIndex = i

        parentCategory[#parentCategory + 1] = swatch
        self.colorIndexToSwatch[i] = swatch
    end

    local sortedCategories = {}
    for category in pairs(activeSwatches) do
        sortedCategories[#sortedCategories + 1] = category
    end
    table.sort(sortedCategories)

    self:PopulateColors(activeSwatches, sortedCategories)
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

function ZO_GuildHeraldryManager_Shared:SelectStyle(styleIndex, becauseOfRebuild)
    if becauseOfRebuild or self.activeData.getSelectedStyle() ~= styleIndex or self.activeData.getViewCategory() ~= self.activeData.getSelectedCategory() then
        local oldStyle = not becauseOfRebuild and self.styleIndexToStyle[self.activeData.getSelectedStyle()]
        if oldStyle then
            oldStyle:SetSelected(false)
        end

        self.activeData.setSelectedCategory(self.activeData.getViewCategory())
        self.activeData.setSelectedStyle(styleIndex)

        local newStyle = self.styleIndexToStyle[styleIndex]
        if newStyle then
            newStyle:SetSelected(true, becauseOfRebuild, becauseOfRebuild)
        end

        if not becauseOfRebuild then
            self:SetPendingIndices()
        end
    end
end

function ZO_GuildHeraldryManager_Shared:LayoutStyles(anchorFunction)
    self.stylePool:ReleaseAllObjects()
    self.styleIndexToStyle = {}

    self.styleHeader:SetText(self.activeData.styleHeaderName)

    local currentAnchor = ZO_Anchor:New(CENTER, self.styleHeader, BOTTOMLEFT)

    local selectedStyle = self.activeData.getSelectedStyle()
    local viewingSelectedCategory = self.activeData.getSelectedCategory() == self.activeData.getViewCategory()

    for i = 1, self.activeData.getNum() do
        local styleControl = self.stylePool:AcquireObject()
        local styleName, icon = self.activeData.getInfo(i)

        styleControl.icon:SetTexture(icon)
        styleControl.styleIndex = i

        self.styleIndexToStyle[i] = styleControl

        anchorFunction(currentAnchor, styleControl, i)

        if viewingSelectedCategory and i == selectedStyle then
           self:SelectStyle(styleControl.styleIndex, ZO_HERALDRY_SKIP_ANIM)
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

function ZO_GuildHeraldryManager_Shared:AttemptSaveIfBlocking(showBaseScene)
    local attemptedSave = false

    if self:IsCurrentBlockingScene() then
        self:AttemptSaveAndExit(showBaseScene)
        attemptedSave = true
    end

    return attemptedSave
end

function ZO_GuildHeraldryManager_Shared:AttemptSaveAndExit(showBaseScene)
    local blocked = false

    if HasPendingHeraldryChanges() then
        self:SetPendingExit(true)
        if not IsCreatingHeraldryForFirstTime() then
            local pendingCost = GetPendingHeraldryCost()
            local heraldryFunds = GetHeraldryGuildBankedMoney()
            if heraldryFunds and pendingCost <= heraldryFunds then
                self:ConfirmHeraldryApplyChanges()
                blocked = true
            end
        end
    end

    if not blocked then
        self:ConfirmExit(showBaseScene)
    end
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
            [1] =
            {
                keybind =   "DIALOG_PRIMARY",
                control =   control and GetControl(control, "Accept"),
                text =      SI_DIALOG_ACCEPT,
                callback =  function(dialog)
                                ApplyPendingHeraldryChanges()
                                dialog.data.owner.pendingTransaction = true
                            end,
            },
            [2] =
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
            [1] =
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

            [2] =
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
            [3] =
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

    local data = {owner = self}
    showDialogFunc(self:GetPurchaseDialogName(), data)
end

function ZO_GuildHeraldryManager_Shared:ConfirmHeraldryApplyChanges(control, showDialogFunc)
    if not self.m_applyChangesHeraldryDialog then
        self.m_applyChangesHeraldryDialog = true
        self:ApplyChangesHeraldryDialogInitialize(control)
    end

    local data = {owner = self}
    showDialogFunc(self:GetApplyChangesDialogName(), data)
end
