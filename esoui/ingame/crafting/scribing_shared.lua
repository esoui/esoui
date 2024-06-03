ZO_SCRIBING_MODE_NONE = 0
ZO_SCRIBING_MODE_SCRIBE = 1
ZO_SCRIBING_MODE_RECENT = 2

ZO_RECENT_SCRIBE_SAVED_VAR_INDEX =
{
    CRAFTED_ABILITY = 1,
    PRIMARY_SCRIPT = 2,
    SECONDARY_SCRIPT = 3,
    TERTIARY_SCRIPT = 4,
}

local INTERACTION =
{
    type = "ScribingStation",
    interactTypes = { INTERACTION_CRAFT },
}

local SHOW_POSITIVE_DROP_CALLOUT = true
local SHOW_NEGATIVE_DROP_CALLOUT = false

ZO_SharedScribingSlotAnimation = ZO_CraftingCreateSlotAnimation:Subclass()

function ZO_SharedScribingSlotAnimation:GetLockInSound(slot)
    return SOUNDS.SCRIBING_SCRIBE_SLOT_ANIMATED
end

ZO_Scribing_Shared = ZO_DeferredInitializingObject:Subclass()

function ZO_Scribing_Shared:Initialize(control, interactSceneName)
    self.control = control

    self.interactScene = self:CreateInteractScene(interactSceneName)

    ZO_DeferredInitializingObject.Initialize(self, self.interactScene)
end

function ZO_Scribing_Shared:CreateInteractScene(name)
    return ZO_InteractScene:New(name, SCENE_MANAGER, INTERACTION)
end

function ZO_Scribing_Shared:OnDeferredInitialize()
    self:InitializeSlots()
    self:InitializeFilters()
    self:InitializeEvents()
    self:InitializeKeybindStripDescriptors()
end

function ZO_Scribing_Shared:InitializeSlots()
    self.slotsContainer = self.control:GetNamedChild("SlotsContainer")
    self.slotsInkCostLabel = nil
    self.scribingSlots = {}
    self.slotAnimation = ZO_SharedScribingSlotAnimation:New(self.interactScene:GetName(), function() return self:IsShowing() end)
end

function ZO_Scribing_Shared:SetCraftedAbilitySlot(slotObject)
    self.craftedAbilitySlot = slotObject
    self.slotAnimation:AddSlot(slotObject)
end

function ZO_Scribing_Shared:AddScriptSlot(slotType, slotObject)
    self.scribingSlots[slotType] = slotObject
    self.slotAnimation:AddSlot(slotObject)
end

function ZO_Scribing_Shared:InitializeFilters()
    self.scriptFilters =
    {
        isUsable = true,
    }
end

function ZO_Scribing_Shared:InitializeEvents()
    CALLBACK_MANAGER:RegisterCallback("CraftingAnimationsStopped", function()
        self:OnScribeComplete()
    end)
end

function ZO_Scribing_Shared:InitializeKeybindStripDescriptors()
    -- To be overridden
end

function ZO_Scribing_Shared:OnShow()
    TriggerTutorial(TUTORIAL_TRIGGER_SCRIBING_OPENED)
end

function ZO_Scribing_Shared:OnHiding()
    -- To be overridden
end

function ZO_Scribing_Shared:OnHidden()
    ResetCraftedAbilityScriptSelectionOverride()
end

function ZO_Scribing_Shared:IsShowing()
    return self.interactScene:IsShowing()
end

function ZO_Scribing_Shared:ShouldCraftButtonBeEnabled()
    if ZO_CraftingUtils_IsPerformingCraftProcess() then
        return false
    end

    local primaryScriptId, secondaryScriptId, tertiaryScriptId = self:GetSlottedScriptIds()
    if primaryScriptId == 0 or secondaryScriptId == 0 or tertiaryScriptId == 0 then
        return false, GetString("SI_TRADESKILLRESULT", CRAFTING_RESULT_EMPTY_SCRIPT_SLOT)
    end

    if not (self:IsScriptIdUnlocked(primaryScriptId) and self:IsScriptIdUnlocked(secondaryScriptId) and self:IsScriptIdUnlocked(tertiaryScriptId)) then
        return false, GetString("SI_TRADESKILLRESULT", CRAFTING_RESULT_UNOWNED_SCRIPT)
    end
    
    local craftedAbilityData = self:GetSlottedCraftedAbilityData()
    if not craftedAbilityData:IsScribableScriptIdCombination(primaryScriptId, secondaryScriptId, tertiaryScriptId) then
        return false, GetString("SI_TRADESKILLRESULT", CRAFTING_RESULT_INVALID_SCRIBING_COMBINATION)
    end

    if craftedAbilityData:AreScriptIdsActive(primaryScriptId, secondaryScriptId, tertiaryScriptId) then
        return false, GetString("SI_TRADESKILLRESULT", CRAFTING_RESULT_SKILL_UNCHANGED)
    end

    return true
end

function ZO_Scribing_Shared:OnScribeComplete()
    local craftedAbilityData = self:GetSlottedCraftedAbilityData()
    if craftedAbilityData then
        local recentCraftedAbilities = self:GetRecentCraftedAbilities()
        local primaryScriptId, secondaryScriptId, tertiaryScriptId = self:GetSlottedScriptIds()
        for i = 1, #recentCraftedAbilities do
            if SCRIBING_MANAGER:IsRecentCraftedAbilityIndexEqual(i, craftedAbilityData:GetId(), primaryScriptId, secondaryScriptId, tertiaryScriptId) then
                table.remove(recentCraftedAbilities, i)
                break
            end
        end
        table.insert(recentCraftedAbilities, { craftedAbilityData:GetId(), primaryScriptId, secondaryScriptId, tertiaryScriptId })
    end

    if self:IsShowing() then
        self:ShowCraftedAbilities()
        local canSeeAbilityScribedTutorial = CanTutorialBeSeen(TUTORIAL_TRIGGER_SCRIBING_ABILITY_SCRIBED)
        if canSeeAbilityScribedTutorial then
            TriggerTutorial(TUTORIAL_TRIGGER_SCRIBING_ABILITY_SCRIBED)
        end

        if self.initialScribe then
            if canSeeAbilityScribedTutorial then
                -- we need to delay the open skill dialog until after the tutorial is shown
                zo_callLater(function() ZO_Dialogs_ShowPlatformDialog("SCRIBING_OPEN_SKILLS_CONFIRM", { skillsData = craftedAbilityData:GetSkillData() }) end, 500)
            else
                ZO_Dialogs_ShowPlatformDialog("SCRIBING_OPEN_SKILLS_CONFIRM", { skillsData = craftedAbilityData:GetSkillData() })
            end
        end
        self.initialScribe = nil
    end
end

function ZO_Scribing_Shared:ShowCraftedAbilities(resetToTop)
    self:ClearCurrentScribingSelection()

    self:RefreshCraftedAbilityList(resetToTop)
    self:UpdateInkDisplay()
end

function ZO_Scribing_Shared:RefreshCraftedAbilityList(resetToTop)
    self:RefreshSlots()
end

function ZO_Scribing_Shared:ShowScripts()
    local RESET_TO_TOP = true
    self:RefreshScriptsList(RESET_TO_TOP)
    self:UpdateInkDisplay()
end

function ZO_Scribing_Shared:RefreshScriptsList(resetToTop)
    self:RefreshSlots()
end

function ZO_Scribing_Shared:GetRecentCraftedAbilities()
    return SCRIBING_MANAGER:GetRecentCraftedAbilities()
end

function ZO_Scribing_Shared:UpdateInkDisplay()
    -- To be overridden
end

function ZO_Scribing_Shared:UpdateResultTooltip()
    -- To be overridden
end

function ZO_Scribing_Shared:SlotCraftedAbilityById(craftedAbilityId)
    local craftedAbilityData = SCRIBING_DATA_MANAGER:GetCraftedAbilityData(craftedAbilityId)
    if craftedAbilityData then
        self.craftedAbilitySlot:SetCraftedAbilityId(craftedAbilityId)
        craftedAbilityData:SetScriptIdSelectionOverride(0, 0, 0)

        self:ShowScripts()
        TriggerTutorial(TUTORIAL_TRIGGER_SCRIBING_GRIMOIRE_SELECTED)
    else
        self.craftedAbilitySlot:SetCraftedAbilityId(0)
        self:ShowCraftedAbilities()
    end
end

function ZO_Scribing_Shared:SlotScriptById(scriptId)
    local scriptData = self:GetScriptDataById(scriptId)
    if scriptData then
        if self:IsScriptDataSlotted(scriptData) then
            -- Remove slotted script
            local scribingSlot = scriptData:GetScribingSlot()
            self:ClearScriptIdBySlot(scribingSlot)
        else
            -- Add script to slot
            self:SlotScriptIdByScriptData(scriptData)
            TriggerTutorial(TUTORIAL_TRIGGER_SCRIBING_SCRIPT_SELECTED)
        end
    end
    self:RefreshScriptsList()
    self:UpdateCraftingCost()
    self:UpdateResultTooltip()
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_Scribing_Shared:ClearCurrentScribingSelection()
    self.craftedAbilitySlot:ClearCraftedAbilityId()
    self:ClearSelectedScripts()

    ResetCraftedAbilityScriptSelectionOverride()
end

function ZO_Scribing_Shared:ClearSelectedScripts()
    for scribingSlot = SCRIBING_SLOT_ITERATION_BEGIN, SCRIBING_SLOT_ITERATION_END do
        self:ClearScriptIdBySlot(scribingSlot)
    end

    SetCraftedAbilityScriptSelectionOverride(self:GetSlottedCraftedAbilityId(), 0, 0, 0)

    self:RefreshScriptsList()
    self:RefreshSlots()
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_Scribing_Shared:GetSlottedCraftedAbilityId()
    return self.craftedAbilitySlot:GetCraftedAbilityId()
end

function ZO_Scribing_Shared:GetSlottedCraftedAbilityData()
    return SCRIBING_DATA_MANAGER:GetCraftedAbilityData(self:GetSlottedCraftedAbilityId())
end

function ZO_Scribing_Shared:HasCraftedAbilitySlotted()
    return self:GetSlottedCraftedAbilityId() ~= 0
end

function ZO_Scribing_Shared:SlotScriptId(scriptId)
    local scriptData = self:GetScriptDataById(scriptId)
    if scriptData then
        self:SlotScriptIdByScriptData(scriptData)
    end
end

function ZO_Scribing_Shared:GetScriptDataDisabledColor()
    return ZO_DISABLED_TEXT
end

function ZO_Scribing_Shared:SlotScriptIdByScriptData(scriptData)
    local craftedAbilityData = self:GetSlottedCraftedAbilityData()
    if craftedAbilityData then
        local isScriptCompatible = self:IsScriptDataCompatible(craftedAbilityData:GetId(), scriptData)
        self.scribingSlots[scriptData:GetScribingSlot()]:SetScriptId(scriptData:GetId(), isScriptCompatible, self:GetScriptDataDisabledColor())
    end
end

function ZO_Scribing_Shared:GetScriptIdBySlot(slotType)
    return self.scribingSlots[slotType]:GetScriptId()
end

function ZO_Scribing_Shared:GetSlottedScriptIds()
    return self:GetScriptIdBySlot(SCRIBING_SLOT_PRIMARY), self:GetScriptIdBySlot(SCRIBING_SLOT_SECONDARY), self:GetScriptIdBySlot(SCRIBING_SLOT_TERTIARY)
end

function ZO_Scribing_Shared:GetScriptDataById(scriptId)
    return SCRIBING_DATA_MANAGER:GetCraftedAbilityScriptData(scriptId)
end

function ZO_Scribing_Shared:ClearScriptIdBySlot(slotType)
    self.scribingSlots[slotType]:ClearScriptId()
end

function ZO_Scribing_Shared:IsScriptIdSlotted(scriptId)
    local scriptData = SCRIBING_DATA_MANAGER:GetCraftedAbilityScriptData(scriptId)
    return self:IsScriptDataSlotted(scriptData)
end

function ZO_Scribing_Shared:IsScriptDataSlotted(scriptData)
    return self.scribingSlots[scriptData:GetScribingSlot()]:GetScriptId() == scriptData:GetId()
end

function ZO_Scribing_Shared:IsScriptIdCompatibleWithFilters(craftedAbilityId, scriptId)
    if self.scriptFilters then
        local scriptData = self:GetScriptDataById(scriptId)
        local primaryScriptId, secondaryScriptId, tertiaryScriptId = self:GetSlottedScriptIds()
        if not self.scriptFilters.isUsable or (scriptData:IsCompatibleWithSelections(craftedAbilityId, primaryScriptId, secondaryScriptId, tertiaryScriptId) and scriptData:IsUnlocked()) then
            return true
        end
    else
        return true
    end
    return false
end

function ZO_Scribing_Shared:IsAnyScriptSlotted()
    for scribingSlot = SCRIBING_SLOT_ITERATION_BEGIN, SCRIBING_SLOT_ITERATION_END do
        if self:GetScriptIdBySlot(scribingSlot) ~= 0 then
            return true
        end
    end
    return false
end

function ZO_Scribing_Shared:IsScriptIdUnlocked(scriptId)
    local scriptData = SCRIBING_DATA_MANAGER:GetCraftedAbilityScriptData(scriptId)
    return scriptData and scriptData:IsUnlocked()
end

function ZO_Scribing_Shared:ScribeCurrentSelection()
    local primaryScriptId, secondaryScriptId, tertiaryScriptId = self:GetSlottedScriptIds()
    self.initialScribe = self:GetSlottedCraftedAbilityData():GetAbilityId() == 0
    RequestScribe(self:GetSlottedCraftedAbilityId(), primaryScriptId, secondaryScriptId, tertiaryScriptId)
end

function ZO_Scribing_Shared:UpdateCraftingCost()
    if self.slotsInkCostLabel then
        local hasSlottedAnyScripts = self:IsAnyScriptSlotted()
        self.slotsInkCostLabel:SetHidden(not hasSlottedAnyScripts)
        if hasSlottedAnyScripts then
            local inkIcon = ZO_Scribing_Manager.GetScribingInkIcon()
            local primaryScript, secondaryScript, tertiaryScript = self:GetSlottedScriptIds()
            local inkAmount = GetCostToScribeScripts(self:GetSlottedCraftedAbilityId(), primaryScript, secondaryScript, tertiaryScript)
            self.slotsInkCostLabel:SetText(zo_iconTextFormatNoSpaceAlignedRight(inkIcon, "100%", "100%", inkAmount))
        end
    end
end

function ZO_Scribing_Shared:RefreshSlots()
    self:UpdateCraftingCost()
    self:UpdateResultTooltip()
end

function ZO_Scribing_Shared:SelectScriptId(scriptId)
    self:SlotScriptById(scriptId)
end

function ZO_Scribing_Shared:SelectRecentCraftedAbilityData(recentCraftedAbilityData)
    local craftedAbilityId = recentCraftedAbilityData[ZO_RECENT_SCRIBE_SAVED_VAR_INDEX.CRAFTED_ABILITY]
    local primaryScriptId = recentCraftedAbilityData[ZO_RECENT_SCRIBE_SAVED_VAR_INDEX.PRIMARY_SCRIPT]
    local secondaryScriptId = recentCraftedAbilityData[ZO_RECENT_SCRIBE_SAVED_VAR_INDEX.SECONDARY_SCRIPT]
    local tertiaryScriptId = recentCraftedAbilityData[ZO_RECENT_SCRIBE_SAVED_VAR_INDEX.TERTIARY_SCRIPT]
    self:SetupRecentCraftedAbilityToCraft(craftedAbilityId, primaryScriptId, secondaryScriptId, tertiaryScriptId)
end

function ZO_Scribing_Shared:SetupRecentCraftedAbilityToCraft(craftedAbilityId, primaryScriptId, secondaryScriptId, tertiaryScriptId)
    self:SelectCraftedAbilityId(craftedAbilityId)
    self:SelectScriptId(primaryScriptId)
    self:SelectScriptId(secondaryScriptId)
    self:SelectScriptId(tertiaryScriptId)
end

function ZO_Scribing_Shared:ShowSlotDropCalloutsForCraftedAbility(craftedAbilityId)
    for slotType, slot in pairs(self.scribingSlots) do
        slot:ShowDropCallout(SHOW_NEGATIVE_DROP_CALLOUT)
    end 

    self.craftedAbilitySlot:ShowDropCallout(SHOW_POSITIVE_DROP_CALLOUT)
end

function ZO_Scribing_Shared:ShowSlotDropCalloutsForCraftedAbilityScript(scriptId)
    local scriptData = self:GetScriptDataById(scriptId)
    local selectedSlotType = SCRIBING_SLOT_NONE
    if scriptData then
        selectedSlotType = scriptData:GetScribingSlot()
    end
    for slotType, slot in pairs(self.scribingSlots) do
        slot:ShowDropCallout(selectedSlotType == slotType)
    end

    self.craftedAbilitySlot:ShowDropCallout(SHOW_NEGATIVE_DROP_CALLOUT)
end

function ZO_Scribing_Shared:HideAllSlotDropCallouts()
    for slotType, slot in pairs(self.scribingSlots) do
        slot:HideDropCallout()
    end 

    self.craftedAbilitySlot:HideDropCallout()
end

ZO_SharedCraftedAbilitySlot = ZO_InitializingCallbackObject:Subclass()

function ZO_SharedCraftedAbilitySlot:Initialize(owner, control, emptyTexture, dropCalloutTexturePositive, dropCalloutTextureNegative, placeSound, removeSound, emptySlotIcon)
    ZO_InitializingCallbackObject.Initialize(self)

    self.owner = owner
    self.control = control
    control.slot = self
    self.emptyTexture = emptyTexture

    if emptySlotIcon then
        self.emptyTexture = emptySlotIcon
        self.useEmptySlotIcon = true
        self.emptySlotOverrideIcon = self.control:GetNamedChild("EmptySlotIcon")
        internalassert(self.emptySlotOverrideIcon ~= nil)
    end

    self.nameLabel = control:GetNamedChild("Name")

    self.dropCalloutTexturePositive = dropCalloutTexturePositive
    self.dropCalloutTextureNegative = dropCalloutTextureNegative

    self.placeSound = placeSound
    self.removeSound = removeSound

    -- required
    self.slotIcon = self.control:GetNamedChild("Icon")
    self.dropCallout = self.control:GetNamedChild("DropCallout")
    -- optional
    self.iconBg = self.control:GetNamedChild("IconBg")

    self:ClearCraftedAbilityId()
end

function ZO_SharedCraftedAbilitySlot:SetCraftedAbilityId(craftedAbilityId)
    if self.craftedAbilityId == craftedAbilityId then
        return
    end

    local hadCraftedAbility = self.craftedAbilityId and self.craftedAbilityId > 0

    self.craftedAbilityId = craftedAbilityId
    local craftedAbilityData = SCRIBING_DATA_MANAGER:GetCraftedAbilityData(craftedAbilityId)
    local isEmpty = not craftedAbilityData
    if self.useEmptySlotIcon then
        if isEmpty and self.emptyTexture == "" then
            -- Empty string represents no icon, in this case we should just hide both inventory slot icon and our empty slot override
            self.emptySlotOverrideIcon:SetHidden(true)
            self.slotIcon:SetHidden(true)
        else
            self.emptySlotOverrideIcon:SetTexture(self.emptyTexture)
            self.emptySlotOverrideIcon:SetHidden(not isEmpty)
            if craftedAbilityData then
                self.slotIcon:SetTexture(craftedAbilityData:GetIcon())
            end
            self.slotIcon:SetHidden(isEmpty)
        end
    else
        self.slotIcon:SetHidden(false)
        if isEmpty then
            self.slotIcon:SetTexture(self.emptyTexture)
        else
            self.slotIcon:SetTexture(craftedAbilityData:GetIcon())
        end
    end

    if self.nameLabel then
        if not isEmpty then
            self.nameLabel:SetHidden(false)
            self.nameLabel:SetText(craftedAbilityData:GetFormattedName())
        else
            self.nameLabel:SetHidden(true)
        end
    end

    if self.iconBg then
        self.iconBg:SetHidden(self.craftedAbilityId == nil or self.craftedAbilityId == 0)
    end

    if self.craftedAbilityId ~= 0 then
        PlaySound(self.placeSound)
    elseif hadCraftedAbility then
        PlaySound(self.removeSound)
    end
end

function ZO_SharedCraftedAbilitySlot:ClearCraftedAbilityId()
    self:SetCraftedAbilityId(0)
end

function ZO_SharedCraftedAbilitySlot:GetCraftedAbilityId()
    return self.craftedAbilityId
end

function ZO_SharedCraftedAbilitySlot:GetControl()
    return self.control
end

function ZO_SharedCraftedAbilitySlot:IsSlotControl(slotControl)
    return self.control == slotControl
end

function ZO_SharedCraftedAbilitySlot:ShowDropCallout(isCorrectType)
    self.dropCallout:SetHidden(false)
    self.dropCallout:SetTexture(isCorrectType and self.dropCalloutTexturePositive or self.dropCalloutTextureNegative)
end

function ZO_SharedCraftedAbilitySlot:HideDropCallout()
    self.dropCallout:SetHidden(true)
end

ZO_SharedCraftedAbilityScriptSlot = ZO_InitializingCallbackObject:Subclass()

function ZO_SharedCraftedAbilityScriptSlot:Initialize(owner, control, emptyTexture, dropCalloutTexturePositive, dropCalloutTextureNegative, placeSound, removeSound, slotType, emptySlotIcon)
    ZO_InitializingCallbackObject.Initialize(self)

    self.owner = owner
    self.control = control
    control.slot = self
    self.emptyTexture = emptyTexture
    self.slotType = slotType

    if emptySlotIcon then
        self.emptyTexture = emptySlotIcon
        self.useEmptySlotIcon = true
        self.emptySlotOverrideIcon = self.control:GetNamedChild("EmptySlotIcon")
        internalassert(self.emptySlotOverrideIcon ~= nil)
    end

    self.nameLabel = control:GetNamedChild("Name")

    self.dropCalloutTexturePositive = dropCalloutTexturePositive
    self.dropCalloutTextureNegative = dropCalloutTextureNegative

    self.placeSound = placeSound
    self.removeSound = removeSound

    -- required
    self.slotIcon = self.control:GetNamedChild("Icon")
    self.dropCallout = self.control:GetNamedChild("DropCallout")
    -- optional
    self.iconBg = self.control:GetNamedChild("IconBg")

    self:ClearScriptId()
end

function ZO_SharedCraftedAbilityScriptSlot:SetScriptId(scriptId, isScriptCompatible, lockedColor)
    if self.scriptId == scriptId then
        return
    end

    local hadScriptId = self.scriptId and self.scriptId > 0

    self.scriptId = scriptId
    local scriptData = SCRIBING_DATA_MANAGER:GetCraftedAbilityScriptData(scriptId)
    local isEmpty = not scriptData
    if self.useEmptySlotIcon then
        if isEmpty and self.emptyTexture == "" then
            -- Empty string represents no icon, in this case we should just hide both inventory slot icon and our empty slot override
            self.emptySlotOverrideIcon:SetHidden(true)
            self.slotIcon:SetHidden(true)
        else
            self.emptySlotOverrideIcon:SetTexture(self.emptyTexture)
            self.emptySlotOverrideIcon:SetHidden(not isEmpty)
            if scriptData then
                self.slotIcon:SetTexture(scriptData:GetIcon())
            end
            self.slotIcon:SetHidden(isEmpty)
        end
    else
        self.slotIcon:SetHidden(false)
        if isEmpty then
            self.slotIcon:SetTexture(self.emptyTexture)
        else
            self.slotIcon:SetTexture(scriptData:GetIcon())
        end
    end

    if self.nameLabel then
        if not isEmpty then
            self.nameLabel:SetHidden(false)
            self.nameLabel:SetText(scriptData:GetFormattedName())
            local labelColor = ZO_SELECTED_TEXT
            if not isScriptCompatible then
                labelColor = ZO_ERROR_COLOR
            elseif not scriptData:IsUnlocked() then
                labelColor = lockedColor or ZO_DISABLED_TEXT
            end
            self.nameLabel:SetColor(labelColor:UnpackRGBA())
        else
            self.nameLabel:SetHidden(true)
        end
    end

    if self.iconBg then
        self.iconBg:SetHidden(self.scriptId == nil or self.scriptId == 0)
    end

    if self.scriptId ~= 0 then
        PlaySound(self.placeSound)
    elseif hadScriptId then
        PlaySound(self.removeSound)
    end
end

function ZO_SharedCraftedAbilityScriptSlot:ClearScriptId()
    local IS_COMPATIBLE = true
    self:SetScriptId(0, IS_COMPATIBLE)
end

function ZO_SharedCraftedAbilityScriptSlot:GetScriptId()
    return self.scriptId
end

function ZO_SharedCraftedAbilityScriptSlot:GetControl()
    return self.control
end

function ZO_SharedCraftedAbilityScriptSlot:IsSlotControl(slotControl)
    return self.control == slotControl
end

function ZO_SharedCraftedAbilityScriptSlot:ShowDropCallout(isCorrectType)
    self.dropCallout:SetHidden(false)
    self.dropCallout:SetTexture(isCorrectType and self.dropCalloutTexturePositive or self.dropCalloutTextureNegative)
end

function ZO_SharedCraftedAbilityScriptSlot:HideDropCallout()
    self.dropCallout:SetHidden(true)
end
