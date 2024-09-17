--------------------------
-- Skill Style Selector --
--------------------------

ZO_SKILL_STYLE_ICON_SELECTOR_PICK_KEYBOARD_SIZE = 96
ZO_SKILL_STYLE_ICON_SELECTOR_PICK_KEYBOARD_PADDING = -16
ZO_SKILL_STYLE_ICON_SELECTOR_ICON_KEYBOARD_SIZE = 64
ZO_SKILL_STYLE_ICON_SELECTOR_ICON_KEYBOARD_OFFSET_X = 16
ZO_SKILL_STYLE_ICON_SELECTOR_ICON_KEYBOARD_OFFSET_Y = 0

ZO_SkillStyleIconSelector_Keyboard = ZO_InitializingObject:Subclass()

function ZO_SkillStyleIconSelector_Keyboard:Initialize(control)
    self.control = control

    --[[ Expected Attributes for Skill Style Selector Icon
        gridListClass - The class object from which self.skillStyleSelectorGridList will be created,
        entryTemplate - The name of the template control to be used for an icon in the view that allows a skill style to select its icon,
        entryWidth - The width to be used for the the entryTemplate,
        entryHeight - The height to be used for the entryTemplate,
        entryPaddingX - The padding in pixels between icons horizontally,
        entryPaddingY - The padding in pixels between icons vertically,
        narrationText - Optional: The text used to narrate the entry when using screen narration. Can be a function or a string,
    ]]
    self.templateData =
    {
        gridListClass = ZO_GridScrollList_Keyboard,
        entryTemplate = "ZO_SkillStyle_SelectorIcon_Keyboard_Control",
        entryWidth = ZO_SKILL_STYLE_ICON_SELECTOR_PICK_KEYBOARD_SIZE,
        entryHeight = ZO_SKILL_STYLE_ICON_SELECTOR_PICK_KEYBOARD_SIZE,
        entryPaddingX = ZO_SKILL_STYLE_ICON_SELECTOR_PICK_KEYBOARD_PADDING,
        entryPaddingY = ZO_SKILL_STYLE_ICON_SELECTOR_PICK_KEYBOARD_PADDING,
    }

    self:InitializeSkillStyleSelectorGridList()

    local function OnCollectibleUpdated()
        self:RefreshGridList()
        if self.skillStyleIconSelectedCallback then
            local index = self.activeData and self.activeData.iconIndex or nil
            self.skillStyleIconSelectedCallback(index)
        end
    end

    ZO_COLLECTIBLE_DATA_MANAGER:RegisterCallback("OnCollectibleUpdated", OnCollectibleUpdated)
end

function ZO_SkillStyleIconSelector_Keyboard:SetSkillData(skillData)
    self.skillData = skillData
end

function ZO_SkillStyleIconSelector_Keyboard:InitializeSkillStyleSelectorGridList()
    local templateData = self.templateData

    local NO_AUTO_FILL_ROWS = nil
    local RESIZE_TO_FIT_COLUMN_MAX = 5
    local RESIZE_TO_FIT_ROW_MAX = 4
    self.skillStyleSelectorGridList = templateData.gridListClass:New(self.control, NO_AUTO_FILL_ROWS, RESIZE_TO_FIT_COLUMN_MAX, RESIZE_TO_FIT_ROW_MAX)

    local function skillStyleSelectorEntrySetup(control, data)
        self:OnSkillStyleSelectorEntrySetup(control, data)
    end

    local HIDE_CALLBACK = nil
    self.skillStyleSelectorGridList:AddEntryTemplate(templateData.entryTemplate, templateData.entryWidth, templateData.entryHeight, skillStyleSelectorEntrySetup, HIDE_CALLBACK, nil, templateData.entryPaddingX, templateData.entryPaddingY)

    self:BuildSkillStyleSelectorIconGridList()
end

function ZO_SkillStyleIconSelector_Keyboard:OnSkillStyleSelectorEntrySetup(control, data)
    local iconContainer = control:GetNamedChild("IconContainer")
    local checkButton = iconContainer:GetNamedChild("Frame")
    local lockIcon = iconContainer:GetNamedChild("Lock")
    local selectedBorder = iconContainer:GetNamedChild("SelectedBorder")

    local isLocked = data.collectibleData:IsLocked() or data.collectibleData:IsBlocked()
    lockIcon:SetHidden(not isLocked)

    local isCurrent = data.collectibleData:IsUnlocked() and data.collectibleData:IsActive()
    selectedBorder:SetHidden(not isCurrent)
    if isCurrent then
        self.activeData = data
    end

    local function OnClick()
        self:OnSkillStyleSelectorGridListEntryClicked(data.iconIndex)
    end

    if not self.skillData.isPurchased then
        iconContainer:SetAlpha(0.3)
    else
        iconContainer:SetAlpha(1)
    end

    control.data = data
    iconContainer:GetNamedChild("Icon"):SetTexture(data.collectibleData:GetIcon())
    ZO_CheckButton_SetCheckState(checkButton, isCurrent)
    ZO_CheckButton_SetToggleFunction(checkButton, OnClick)
    ZO_CheckButton_SetEnableState(checkButton, not isLocked)
end

function ZO_SkillStyleIconSelector_Keyboard:SetSkillStyleIconSelectedCallback(callback)
    self.skillStyleIconSelectedCallback = callback
end

function ZO_SkillStyleIconSelector_Keyboard:CreateSkillStyleSelectorIconDataObject(index)
    local collectibleId = GetProgressionSkillAbilityFxOverrideCollectibleIdByIndex(self.skillData.progressionId, index)
    local collectibleData = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(collectibleId)
    if collectibleData and not collectibleData:IsHiddenFromCollection() then
        local data =
        {
            iconIndex = index,
            collectibleId = collectibleId,
            collectibleData = collectibleData,
            narrationText = self.templateData.narrationText,
        }
        return data
    end
    return nil
end

function ZO_SkillStyleIconSelector_Keyboard:BuildSkillStyleSelectorIconGridList()
    self.skillStyleSelectorGridList:ClearGridList()
    self.activeData = nil

    local templateData = self.templateData
    if self.skillData then
        for i = 1, GetNumProgressionSkillAbilityFxOverrides(self.skillData.progressionId) do
            local data = self:CreateSkillStyleSelectorIconDataObject(i)
            if data then
                self.skillStyleSelectorGridList:AddEntry(data, templateData.entryTemplate)
            end
        end

        self.skillStyleSelectorGridList:CommitGridList()
    end
end

function ZO_SkillStyleIconSelector_Keyboard:RefreshGridList()
    self.activeData = nil
    self.skillStyleSelectorGridList:RefreshGridList()
end

function ZO_SkillStyleIconSelector_Keyboard:GetActiveData()
    return self.activeData
end

function ZO_SkillStyleIconSelector_Keyboard:TryClearSelection()
    if self.activeData then
        local collectibleData = self.activeData.collectibleData
        if collectibleData:IsActive() and not collectibleData:IsBlocked() then
            collectibleData:Use()
            return true
        end
    end
    return false
end

function ZO_SkillStyleIconSelector_Keyboard:OnSkillStyleSelectorGridListEntryClicked(newIconIndex)
    if self.skillData.isPurchased then
        local gridData = self.skillStyleSelectorGridList:GetData()
        local selectedData = gridData[newIconIndex]
        if selectedData then
            local collectibleData = selectedData.data.collectibleData
            if collectibleData and not collectibleData:IsBlocked() and collectibleData:IsUnlocked() and not collectibleData:IsActive() then
                collectibleData:Use()
            end
        end
    end
end