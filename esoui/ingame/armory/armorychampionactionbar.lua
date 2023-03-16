
local CHAMPION_BAR_DISABLED_ALPHA = 0.5
local CHAMPION_BAR_ENABLED_ALPHA = 1

ZO_ArmoryChampionActionBar = ZO_InitializingCallbackObject:Subclass()

function ZO_ArmoryChampionActionBar:Initialize(control)
    self.control = control
    self.lockIcon = control:GetNamedChild("Lock")
    self.hotbarCategory = HOTBAR_CATEGORY_CHAMPION 
    self.slots = {}
    self.firstSlotPerDiscipline = {}
    self.mouseInputGroup = ZO_MouseInputGroup:New(control)

    local lastSlotControl, lastSlot = nil, nil
    local startSlotIndex, endSlotIndex = GetAssignableChampionBarStartAndEndSlots()
    for actionSlotIndex = startSlotIndex, endSlotIndex do
        local slotControl = CreateControlFromVirtual("$(parent)Slot", self.control, "ZO_ArmoryChampionActionSlot", actionSlotIndex)
        local slot = ZO_ArmoryChampionActionBarSlot:New(slotControl, self, actionSlotIndex)
        self.mouseInputGroup:Add(slot.button, ZO_MOUSE_INPUT_GROUP_MOUSE_OVER)
        table.insert(self.slots, slot)

        if lastSlotControl then
            if lastSlot:GetRequiredDisciplineId() ~= slot:GetRequiredDisciplineId() then
                slotControl:SetAnchor(LEFT, lastSlotControl, RIGHT, ZO_CHAMPION_ACTION_BAR_DISCIPLINE_PADDING_X, 0)
                self.firstSlotPerDiscipline[slot:GetRequiredDisciplineId()] = actionSlotIndex
            else
                slotControl:SetAnchor(LEFT, lastSlotControl, RIGHT, ZO_CHAMPION_ACTION_BAR_SLOT_PADDING_X, 0)
            end
        else
            slotControl:SetAnchor(LEFT, self.control, LEFT, ZO_CHAMPION_ACTION_BAR_INITIAL_SLOT_OFFSET_X, 0)
            self.firstSlotPerDiscipline[slot:GetRequiredDisciplineId()] = actionSlotIndex
        end
        lastSlotControl = slotControl
        lastSlot = slot
    end

    self:ResetAllSlots()
    self:RefreshEnabledState()

    self.control:RegisterForEvent(EVENT_CHAMPION_SYSTEM_UNLOCKED, function() self:RefreshEnabledState() end)
end

function ZO_ArmoryChampionActionBar:GetHotbarCategory()
    return self.hotbarCategory
end

function ZO_ArmoryChampionActionBar:ResetAllSlots()
    for _, slot in ipairs(self.slots) do
        slot:Reset()
    end
end

function ZO_ArmoryChampionActionBar:RefreshEnabledState()
    local isChampionUnlocked = IsChampionSystemUnlocked()
    self.control:SetAlpha(isChampionUnlocked and CHAMPION_BAR_ENABLED_ALPHA or CHAMPION_BAR_DISABLED_ALPHA)
    self.lockIcon:SetHidden(isChampionUnlocked)
    for _, slot in ipairs(self.slots) do
        slot:SetEnabled(isChampionUnlocked)
    end
end

function ZO_ArmoryChampionActionBar:AssignArmoryBuildData(buildData)
    self.buildData = buildData
    self:ResetAllSlots()
end

function ZO_ArmoryChampionActionBar:GetLinkedArmoryBuildData()
    return self.buildData
end

function ZO_ArmoryChampionActionBar:GetFirstSlotIndexForDiscipline(disciplineId)
    return self.firstSlotPerDiscipline[disciplineId]
end

function ZO_ArmoryChampionActionBar:GetNarrationText()
    local narrations = {}
    if IsChampionSystemUnlocked() then
        --Get the narration for each slot
        for _, slot in ipairs(self.slots) do
            ZO_AppendNarration(narrations, slot:GetNarrationText())
        end
    else
        --If the champion system is locked, narrate that, and don't bother to narrate the individual slots
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_SCREEN_NARRATION_LOCKED_ICON_NARRATION)))
    end
    return narrations
end

ZO_ArmoryChampionActionBarSlot = ZO_InitializingObject:Subclass()

function ZO_ArmoryChampionActionBarSlot:Initialize(control, actionBar, actionSlotIndex)
    self.control = control
    self.bar = actionBar
    self.slotIndex = actionSlotIndex
    self.isMousedOver = false

    self.icon = control:GetNamedChild("Icon")

    self.button = control:GetNamedChild("Button")
    self.button.owner = self

    self.starControl = control:GetNamedChild("Star")
    self.starVisuals = ZO_ChampionStarVisuals:New(self.starControl)

    self.textures = ZO_GetChampionBarDisciplineTextures(GetChampionDisciplineType(self:GetRequiredDisciplineId()))

    self.starControl:SetHandler("OnUpdate", function(_, timeSecs)
        self.starVisuals:Update(timeSecs)
    end)
end

function ZO_ArmoryChampionActionBarSlot:Reset()
    self.buildData = self.bar:GetLinkedArmoryBuildData()
    self.championSkillData = self:GetSavedChampionSkillData()
    self:Refresh()
end

function ZO_ArmoryChampionActionBarSlot:GetChampionSkillData()
    return self.championSkillData
end

function ZO_ArmoryChampionActionBarSlot:GetChampionSkillId()
    if self.championSkillData then
        return self.championSkillData:GetId()
    end
    return nil
end

function ZO_ArmoryChampionActionBarSlot:GetSavedChampionSkillData()
    if self.buildData then
        local championSkillId = self.buildData:GetSlottedChampionSkillId(self.slotIndex)
        return CHAMPION_DATA_MANAGER:GetChampionSkillData(championSkillId)
    end
    return nil
end

function ZO_ArmoryChampionActionBarSlot:SetEnabled(enabled)
    self.button:SetEnabled(enabled)
end

function ZO_ArmoryChampionActionBarSlot:GetSlotIndices()
    return self.slotIndex, self.bar:GetHotbarCategory()
end

function ZO_ArmoryChampionActionBarSlot:GetRequiredDisciplineId()
    return GetRequiredChampionDisciplineIdForSlot(self:GetSlotIndices())
end

function ZO_ArmoryChampionActionBarSlot:OnMouseEnter()
    self.isMousedOver = true
    if not IsInGamepadPreferredMode() then
        self:ShowTooltip()
    end
end

function ZO_ArmoryChampionActionBarSlot:OnMouseExit()
    self.isMousedOver = false
    self:HideTooltip()
end

function ZO_ArmoryChampionActionBarSlot:Refresh()
    local backgroundTexture
    if self.championSkillData then
        local disciplineType = self.championSkillData:GetChampionDisciplineData():GetType()
        local NOT_SLOTTED = false -- should only be visually slotted in world
        self.starVisuals:Setup(ZO_CHAMPION_STAR_VISUAL_TYPE.SLOTTABLE, ZO_CHAMPION_STAR_STATE.PURCHASED, disciplineType, NOT_SLOTTED)
        self.starControl:SetHidden(false)
        backgroundTexture = self.textures.slotted
    else
        self.starControl:SetHidden(true)
        backgroundTexture = self.textures.empty
    end

    self.icon:SetTexture(backgroundTexture)

    self.button:SetNormalTexture(self.textures.border)
    self.button:SetMouseOverTexture(self.textures.selected)
    self.button:SetDisabledTexture(self.textures.disabled)

    if self.isMousedOver and not IsInGamepadPreferredMode() then
        self:ShowTooltip()
    end
end

function ZO_ArmoryChampionActionBarSlot:ShowTooltip()
    self:HideTooltip()

    if self.championSkillData then
        local championSkillId = self.championSkillData:GetId()
        InitializeTooltip(ChampionSkillTooltip, self.button, TOP, 0, 15, BOTTOM)
        ChampionSkillTooltip:SetAbilityId(GetChampionAbilityId(championSkillId))
    end
end

function ZO_ArmoryChampionActionBarSlot:GetNarrationText()
    local narrations = {}
    local disciplineId = self:GetRequiredDisciplineId()
    --If this is the first slot for its discipline, include the discipline name in the narration
    if self.bar:GetFirstSlotIndexForDiscipline(disciplineId) == self.slotIndex then
        local disciplineName = ZO_CachedStrFormat(SI_CHAMPION_CONSTELLATION_NAME_FORMAT, GetChampionDisciplineName(disciplineId))
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(disciplineName))
    end

    if self.championSkillData then
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(self.championSkillData:GetFormattedName()))
    else
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_GAMEPAD_ARMORY_EMPTY_ENTRY_NARRATION)))
    end
    return narrations
end

function ZO_ArmoryChampionActionBarSlot:HideTooltip()
    ClearTooltip(ChampionSkillTooltip)
end


-- Button XML
function ZO_ArmoryChampionActionSlot_OnMouseEnter(control)
    control.owner:OnMouseEnter()
end

function ZO_ArmoryChampionActionSlot_OnMouseExit(control)
    control.owner:OnMouseExit()
end

function ZO_ArmoryChampionActionBar_OnMouseEnter(control)
    if not IsChampionSystemUnlocked() then
        InitializeTooltip(InformationTooltip, control, RIGHT, -10)
        InformationTooltip:AddLine(GetString(SI_ARMORY_CHAMPION_LOCKED_TOOLTIP), "", ZO_NORMAL_TEXT:UnpackRGBA())
    end
end

function ZO_ArmoryChampionActionBar_OnMouseExit(control)
    ClearTooltip(InformationTooltip)
end
