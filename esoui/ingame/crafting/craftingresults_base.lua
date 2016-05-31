local g_forceCenterResultsText = false

function ZO_CraftingResults_Base_PlayPulse(control)
    if not control.pulseAnimation then
        local pulseTexture = CreateControlFromVirtual("$(parent)PulseTexture", control, "ZO_CraftingResultPulseTexture")
        control.pulseAnimation = ANIMATION_MANAGER:CreateTimelineFromVirtual("CraftingResultPulse", pulseTexture)
    end

    if not control.pulseAnimation:IsPlaying() then
        control.pulseAnimation:PlayFromStart()
    end
end

ZO_CraftingResults_Base = ZO_Object:Subclass()

function ZO_CraftingResults_Base:New(...)
    local craftingResults = ZO_Object.New(self)
    craftingResults:Initialize(...)
    return craftingResults
end

function ZO_CraftingResults_Base:Initialize(control, showInGamepadPreferredModeOnly)
    self.control = control

    self:InitializeResultBuffer()

    control:RegisterForEvent(EVENT_CRAFT_STARTED, function(eventCode, ...) self:OnCraftStarted(...) end)
    control:AddFilterForEvent(EVENT_CRAFT_STARTED, REGISTER_FILTER_IS_IN_GAMEPAD_PREFERRED_MODE, showInGamepadPreferredModeOnly)
    control:RegisterForEvent(EVENT_CRAFT_COMPLETED, function(eventCode, ...) self:OnCraftCompleted(...) end)
    control:AddFilterForEvent(EVENT_CRAFT_COMPLETED, REGISTER_FILTER_IS_IN_GAMEPAD_PREFERRED_MODE, showInGamepadPreferredModeOnly)

    self.enchantSoundPlayer = ZO_QueuedSoundPlayer:New()
    self.enchantSoundPlayer:SetFinishedAllSoundsCallback(function() self:OnAllEnchantSoundsFinished() end)
end

function ZO_CraftingResults_Base:SetCraftingTooltip(tooltipControl)
    if self.tooltipControl ~= tooltipControl then
        self.tooltipAnimationSuccessSound = nil
        self.tooltipAnimationFailureSound = nil
        self.tooltipControl = tooltipControl
        self:ForceStop()
        if self.tooltipControl then
            self:AssociateAnimations(self.tooltipControl)
        end
    end

    if not tooltipControl then
        self:FadeAll()
    end
end

function ZO_CraftingResults_Base:SetTooltipAnimationSounds(tooltipAnimationSuccessSound, tooltipAnimationFailureSound)
    self.tooltipAnimationSuccessSound = tooltipAnimationSuccessSound
    self.tooltipAnimationFailureSound = tooltipAnimationFailureSound
end

function ZO_CraftingResults_Base:PlayCraftedSound(itemSoundCategory)
    if not ZO_Enchanting_IsInCreationMode() then
        PlayItemSound(itemSoundCategory, ITEM_SOUND_ACTION_CRAFTED)
    end
end

function ZO_CraftingResults_Base:AssociateAnimations(tooltip)
    if not self.resultTooltipAnimation then
        self.resultTooltipAnimation = ANIMATION_MANAGER:CreateTimelineFromVirtual("CraftingResultTooltipAnimation")
    end

    self.resultTooltipAnimation:GetAnimation(1):SetAnimatedControl(tooltip)
    self.resultTooltipAnimation:GetAnimation(2):SetAnimatedControl(tooltip)

    local tooltipGlow = tooltip:GetNamedChild("Glow")
    self.tooltipGlow = tooltipGlow
    self.resultTooltipAnimation:GetAnimation(3):SetAnimatedControl(tooltipGlow)

    local tooltipBurst1 = tooltip:GetNamedChild("IconBurst1")
    self.tooltipBurst1 = tooltipBurst1
    self.resultTooltipAnimation:GetAnimation(4):SetAnimatedControl(tooltipBurst1)

    local tooltipBurst2 = tooltip:GetNamedChild("IconBurst2")
    self.tooltipBurst2 = tooltipBurst2
    self.resultTooltipAnimation:GetAnimation(5):SetAnimatedControl(tooltipBurst2)

    self.resultTooltipAnimation:GetAnimationTimeline(1):GetAnimation(1):SetAnimatedControl(tooltipBurst1)
    self.resultTooltipAnimation:GetAnimationTimeline(1):GetAnimation(2):SetAnimatedControl(tooltipBurst2)

    local function OnStop(animation)
        tooltipGlow:SetAlpha(0)
        tooltipBurst1:SetAlpha(0)
        tooltipBurst2:SetAlpha(0)

        self:OnTooltipAnimationStopped()
    end

    self.forceStopHandler = function()
        tooltip:SetAlpha(1)
        OnStop()
    end

    self.resultTooltipAnimation:GetAnimation(1):SetHandler("OnStop", OnStop)
end

function ZO_CraftingResults_Base:ForceStop()
    if self.resultTooltipAnimation and self.resultTooltipAnimation:IsPlaying() then
        self.resultTooltipAnimation:Stop()
        self.forceStopHandler()
    end
end

local function DoesCraftingTypeHaveSlotAnimations(craftingType)
    if craftingType == CRAFTING_TYPE_PROVISIONING then
        return false
    elseif craftingType == CRAFTING_TYPE_ENCHANTING then
        return true
    elseif craftingType == CRAFTING_TYPE_ALCHEMY then
        return true
    elseif ZO_Smithing_IsSmithingStation(craftingType) then
        local activeSmithing = ZO_Smithing_GetActiveObject()
        if activeSmithing then
            return activeSmithing:DoesCurrentModeHaveSlotAnimations()
        else
            return true
        end
    end
end

function ZO_CraftingResults_Base:OnCraftStarted(craftingType)
    self.tooltipAnimationCompleted = false
    self.craftingProcessCompleted = false

    --The result of DoesCraftingTypeHaveSlotAnimations for smithing depends on having an active smithing object. There is no such object if the smithing UI
    --is closed. This means that the result of the function can change between OnCraftStarted and OnCraftEnded if the smithing UI is closed during a crafting
    --operation. So store the results off here and don't call it later on.
    self.playStopTooltipAnimation = DoesCraftingTypeHaveSlotAnimations(craftingType)
    self.playStartTooltipAnimation = not self.playStopTooltipAnimation

    if (ZO_Enchanting_IsInCreationMode()) then
        local potencySound, potencyLength, essenceSound, essenceLength, aspectSound, aspectLength = ZO_Enchanting_GetVisibleEnchanting():GetLastRunestoneSoundParams()

        self.enchantSoundPlayer:PlaySound(potencySound, potencyLength)
        self.enchantSoundPlayer:PlaySound(essenceSound, essenceLength)
        self.enchantSoundPlayer:PlaySound(aspectSound, aspectLength)
    end

    CALLBACK_MANAGER:FireCallbacks("CraftingAnimationsStarted")

    if self.playStartTooltipAnimation then
        self:PlayTooltipAnimation()
    end
end

function ZO_CraftingResults_Base:PlayTooltipAnimation(failure)
    if self.tooltipControl and not self.tooltipControl:IsHidden() then
        self:ForceStop()

        self.tooltipGlow:SetEdgeTexture(failure and "EsoUI/Art/Crafting/crafting_toolTip_glow_edge_red64.dds" or "EsoUI/Art/Crafting/crafting_toolTip_glow_edge_blue64.dds", 512, 64)
        if failure then
            self.resultTooltipAnimation:GetAnimation(3):SetDuration(200)
            self.resultTooltipAnimation:GetAnimation(3):SetAlphaValues(.25, 1)
        else
            self.resultTooltipAnimation:GetAnimation(3):SetDuration(500)
            self.resultTooltipAnimation:GetAnimation(3):SetAlphaValues(0, 1)
        end

        self.tooltipBurst1:SetHidden(failure)
        self.tooltipBurst2:SetHidden(failure)

        self.resultTooltipAnimation:PlayFromStart()
        PlaySound(failure and self.tooltipAnimationFailureSound or self.tooltipAnimationSuccessSound)
    else
        self:OnTooltipAnimationStopped()
    end
end

function ZO_CraftingResults_Base:OnCraftCompleted(craftingType)
    if not self.enchantSoundPlayer:IsPlaying() and not self.craftingProcessCompleted then
        self.craftingProcessCompleted = true

        if self.playStopTooltipAnimation then
			local numItemsGained = GetNumLastCraftingResultItemsAndPenalty()
            self:PlayTooltipAnimation(numItemsGained == 0)
        else
            self:CheckCraftProcessCompleted()
        end
    end
end

function ZO_CraftingResults_Base:OnAllEnchantSoundsFinished()
    if not self.craftingProcessCompleted then
        self.craftingProcessCompleted = true
        self:PlayTooltipAnimation()
    end
end

function ZO_CraftingResults_Base:OnTooltipAnimationStopped()
    if self.tooltipAnimationCompleted == false then
        self.tooltipAnimationCompleted = true
        self:CheckCraftProcessCompleted()
    end
end

local function GetBoosterItemTypeForCraftingType()
    local craftingType = GetCraftingInteractionType()
    if craftingType == CRAFTING_TYPE_BLACKSMITHING then
        return ITEMTYPE_BLACKSMITHING_BOOSTER
    elseif craftingType == CRAFTING_TYPE_CLOTHIER then
        return ITEMTYPE_CLOTHIER_BOOSTER
    elseif craftingType == CRAFTING_TYPE_WOODWORKING then
        return ITEMTYPE_WOODWORKING_BOOSTER
    end
end

local function GetBoosterFoundSoundForCraftingType()
    local craftingType = GetCraftingInteractionType()
    if craftingType == CRAFTING_TYPE_BLACKSMITHING then
        return SOUNDS.BLACKSMITH_EXTRACTED_BOOSTER
    elseif craftingType == CRAFTING_TYPE_CLOTHIER then
        return SOUNDS.CLOTHIER_EXTRACTED_BOOSTER
    elseif craftingType == CRAFTING_TYPE_WOODWORKING then
        return SOUNDS.WOODWORKER_EXTRACTED_BOOSTER
    end
end

local function GetFailedSmithingExtractionResultInfo()
    local craftingType = GetCraftingInteractionType()
    if craftingType == CRAFTING_TYPE_BLACKSMITHING then
        return SI_SMITHING_BLACKSMITH_EXTRACTION_FAILED, SOUNDS.BLACKSMITH_FAILED_EXTRACTION
    elseif craftingType == CRAFTING_TYPE_CLOTHIER then
        return SI_SMITHING_CLOTHIER_EXTRACTION_FAILED, SOUNDS.CLOTHIER_FAILED_EXTRACTION
    elseif craftingType == CRAFTING_TYPE_WOODWORKING then
        return SI_SMITHING_WOODWORKING_EXTRACTION_FAILED, SOUNDS.WOODWORKER_FAILED_EXTRACTION
    end
end

local function DidLastCraftGainBooster(numItemsGained)
    local smithingObject = ZO_Smithing_GetActiveObject()
    if smithingObject and smithingObject:IsExtracting() then
        local boosterItemType = GetBoosterItemTypeForCraftingType()
        for i = 1, numItemsGained do
            local name, icon, stack, sellPrice, meetsUsageRequirement, equipType, itemType, itemStyle, quality, itemSoundCategory, itemInstanceId = GetLastCraftingResultItemInfo(i)
            if itemType == boosterItemType then
                return true
            end
        end
    end

    return false
end

function ZO_CraftingResults_Base:SetForceCenterResultsText(forceCenterResultsText)
	g_forceCenterResultsText = forceCenterResultsText
end

function ZO_CraftingResults_Base:ModifyAnchor(control, newAnchor)
	local _, point, relTo, relPoint, offsX, offsY = control:GetAnchor(0)
	self.savedCraftingAnchor = {point, relTo, relPoint, offsX, offsY}
	control:ClearAnchors()
	newAnchor:Set(control)
end

function ZO_CraftingResults_Base:RestoreAnchor(control)
	control:ClearAnchors()
	local restoredAnchor = ZO_Anchor:New(unpack(self.savedCraftingAnchor))
	restoredAnchor:Set(control)
end

function ZO_CraftingResults_Base:CheckCraftProcessCompleted()
    if self:IsActive() and self.craftingProcessCompleted and self.tooltipAnimationCompleted then
        local numItemsGained, penaltyApplied = GetNumLastCraftingResultItemsAndPenalty()
	    local smithingObject = ZO_Smithing_GetActiveObject()
        local isImproving = smithingObject and smithingObject:IsImproving()

        if GetNumLastCraftingResultLearnedTraits() > 0 then
            self:DisplayDiscoveredTraits()
        end

		if penaltyApplied then
			TriggerTutorial(TUTORIAL_TRIGGER_DECONSTRUCTION_LEVEL_PENALTY)
		end

        if numItemsGained == 0 then
            if SYSTEMS:IsShowing("alchemy") then
                ZO_AlertNoSuppression(UI_ALERT_CATEGORY_ALERT, nil, SI_ALCHEMY_NO_YIELD)
            elseif isImproving then
                ZO_AlertNoSuppression(UI_ALERT_CATEGORY_ALERT, nil, SI_SMITHING_IMPROVEMENT_FAILED)
            elseif smithingObject and smithingObject:IsExtracting() then
				local failedExtractionStringId, failedExtractionSoundName = GetFailedSmithingExtractionResultInfo()
				if penaltyApplied then
					ZO_AlertNoSuppression(UI_ALERT_CATEGORY_ALERT, failedExtractionSoundName, SI_SMITHING_DECONSTRUCTION_LEVEL_PENALTY)
				else
					ZO_AlertNoSuppression(UI_ALERT_CATEGORY_ALERT, failedExtractionSoundName, failedExtractionStringId)
				end
            elseif ZO_Enchanting_IsSceneShowing() then
                if not ZO_Enchanting_IsInCreationMode() then
                    ZO_AlertNoSuppression(UI_ALERT_CATEGORY_ALERT, nil, SI_ENCHANT_NO_YIELD)
                else
                    ZO_AlertNoSuppression(UI_ALERT_CATEGORY_ALERT, nil, SI_ENCHANT_NO_GLYPH_CREATED)
                end
            end
        else
            local gainedBooster = DidLastCraftGainBooster(numItemsGained)
            local shouldDisplayMessages = self:ShouldDisplayMessages()
            for i = 1, numItemsGained do
                local name, icon, stack, sellPrice, meetsUsageRequirement, equipType, itemType, itemStyle, quality, itemSoundCategory, itemInstanceId = GetLastCraftingResultItemInfo(i)
                -- Don't save messages if we can't display them immediately
                if shouldDisplayMessages then
                    local itemInfo = {
                        name = name,
                        icon = icon,
                        stack = stack,
                        sellPrice = sellPrice,
                        meetsUsageRequirement = meetsUsageRequirement,
                        equipType = equipType,
                        itemType = itemType,
                        itemStyle = itemStyle,
                        quality = quality,
                        itemSoundCategory = itemSoundCategory,
                        itemInstanceId = itemInstanceId,
                    }

                    self:DisplayCraftingResult(itemInfo)
                end

                if itemSoundCategory ~= ITEM_SOUND_CATEGORY_BOOSTER then
                    self:PlayCraftedSound(itemSoundCategory)
                end
            end

            if gainedBooster then
                PlaySound(GetBoosterFoundSoundForCraftingType())
            end

            if penaltyApplied then
				ZO_AlertNoSuppression(UI_ALERT_CATEGORY_ALERT, nil, SI_SMITHING_DECONSTRUCTION_LEVEL_PENALTY)
			end
        end

        local totalInspiration = GetLastCraftingResultTotalInspiration()
        if totalInspiration > 0 then
            PlaySound(SOUNDS.CRAFTING_GAINED_INSPIRATION)
        end

        CALLBACK_MANAGER:FireCallbacks("CraftingAnimationsStopped")

        if GetNumLastCraftingResultLearnedTranslations() > 0 then
            self:DisplayTranslatedRunes()
        end
    end
end

function ZO_CraftingResults_Base:IsCraftInProgress()
    return self.craftingProcessCompleted == false or not self.tooltipAnimationCompleted == false
end

function ZO_CraftingResults_Base:HasEntries()
    return false
end
