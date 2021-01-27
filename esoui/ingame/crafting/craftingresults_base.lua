ZO_CRAFTING_RESULT_TYPE =
{
    ITEM = 1,
    CURRENCY = 2,
    KNOWLEDGE = 3,
}

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

    control:RegisterForEvent(EVENT_RETRAIT_STARTED, function(eventCode, ...) self:OnRetraitStarted(...) end)
    control:AddFilterForEvent(EVENT_RETRAIT_STARTED, REGISTER_FILTER_IS_IN_GAMEPAD_PREFERRED_MODE, showInGamepadPreferredModeOnly)

    control:RegisterForEvent(EVENT_RETRAIT_RESPONSE, function(eventCode, ...) self:OnRetraitCompleted(...) end)
    control:AddFilterForEvent(EVENT_RETRAIT_RESPONSE, REGISTER_FILTER_IS_IN_GAMEPAD_PREFERRED_MODE, showInGamepadPreferredModeOnly)

    control:RegisterForEvent(EVENT_RECONSTRUCT_STARTED, function(eventCode, ...) self:OnReconstructStarted(...) end)
    control:AddFilterForEvent(EVENT_RECONSTRUCT_STARTED, REGISTER_FILTER_IS_IN_GAMEPAD_PREFERRED_MODE, showInGamepadPreferredModeOnly)

    control:RegisterForEvent(EVENT_RECONSTRUCT_RESPONSE, function(eventCode, ...) self:OnReconstructCompleted(...) end)
    control:AddFilterForEvent(EVENT_RECONSTRUCT_RESPONSE, REGISTER_FILTER_IS_IN_GAMEPAD_PREFERRED_MODE, showInGamepadPreferredModeOnly)

    self.enchantSoundPlayer = ZO_QueuedSoundPlayer:New()
    self.enchantSoundPlayer:SetFinishedAllSoundsCallback(function() self:OnAllEnchantSoundsFinished() end)

    -- Create a pool of CraftingResultTooltipAnimation_Base to be applied to controls that are
    -- not the "primary" crafting tooltip (self.tooltipControl), but are being displayed alongside of it
    -- This allows us to have additional controls animate in-sync with the crafting tooltip
    local function CreateAnimationTimeline()
        return ANIMATION_MANAGER:CreateTimelineFromVirtual("CraftingResultTooltipAnimation_Base")
    end
    local function ResetTimeline(timeline)
        --nothing to do
    end
    self.secondaryTooltipAnimationPool = ZO_ObjectPool:New(CreateAnimationTimeline, ResetTimeline)
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
        self:ClearSecondaryTooltipAnimationControls()
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

        self:OnTooltipAnimationStopped(self.resultTooltipAnimation.craftingType)
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

-- Add a control that we want to have animate alongside the main crafting tooltip (self.tooltipControl)
-- These will not play the full set of animations, but will have the same alpha animations
function ZO_CraftingResults_Base:AddSecondaryTooltipAnimationControl(control)
    if control then
        local animation, key = self.secondaryTooltipAnimationPool:AcquireObject()
        animation:GetAnimation(1):SetAnimatedControl(control)
        animation:GetAnimation(2):SetAnimatedControl(control)
    end
end

function ZO_CraftingResults_Base:ClearSecondaryTooltipAnimationControls()
    self.secondaryTooltipAnimationPool:ReleaseAllObjects()
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

function ZO_CraftingResults_Base:StartCraftProcess(playStopTooltipAnimation)
    self.tooltipAnimationCompleted = false
    self.craftingProcessCompleted = false

    --The result of DoesCraftingTypeHaveSlotAnimations for smithing depends on having an active smithing object. There is no such object if the smithing UI
    --is closed. This means that the result of the function can change between OnCraftStarted and OnCraftEnded if the smithing UI is closed during a crafting
    --operation. So store the results off here and don't call it later on.
    self.playStopTooltipAnimation = playStopTooltipAnimation
    self.playStartTooltipAnimation = not playStopTooltipAnimation

	-- Suppress item count-related messaging for Smithing Tradeskills' Improvement and Research actions.
	if ZO_Smithing_IsSceneShowing() then
		local mode = ZO_Smithing_GetActiveObject():GetMode()
		self.craftingProcessProducesItems = not (mode == SMITHING_MODE_IMPROVEMENT or mode == SMITHING_MODE_RESEARCH)
	elseif SCENE_MANAGER:GetCurrentSceneName() == "gamepad_smithing_research_confirm" then -- Separate case due to ancillary confirmation Scene
		self.craftingProcessProducesItems = false
	else
		self.craftingProcessProducesItems = true
	end

    if ZO_Enchanting_IsInCreationMode() then
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

function ZO_CraftingResults_Base:OnCraftStarted(craftingType)
    local playStopTooltipAnimation = DoesCraftingTypeHaveSlotAnimations(craftingType)
    self:StartCraftProcess(playStopTooltipAnimation)
end

function ZO_CraftingResults_Base:OnRetraitStarted()
    local PLAY_STOP_TOOLTIP_ANIMATION = true
    self:StartCraftProcess(PLAY_STOP_TOOLTIP_ANIMATION)
end

function ZO_CraftingResults_Base:OnReconstructStarted()
    local PLAY_STOP_TOOLTIP_ANIMATION = true
    self:StartCraftProcess(PLAY_STOP_TOOLTIP_ANIMATION)
end

function ZO_CraftingResults_Base:PlayTooltipAnimation(isFailure, isExceptionalResult, craftingType)
    if self.tooltipControl and not self.tooltipControl:IsHidden() then
        self:ForceStop()

        local edgeTexture = "EsoUI/Art/Crafting/crafting_toolTip_glow_edge_blue64.dds"
        local burstTexture = "EsoUI/Art/Crafting/burst_blue.dds"
        if isFailure then
            edgeTexture = "EsoUI/Art/Crafting/crafting_toolTip_glow_edge_red64.dds"
            -- no burst texture for failue since we hide the bursts
        elseif isExceptionalResult then
            edgeTexture = "EsoUI/Art/Crafting/crafting_toolTip_glow_edge_gold64.dds"
            burstTexture = "EsoUI/Art/Crafting/burst_gold.dds"
        end

        self.tooltipGlow:SetEdgeTexture(edgeTexture, 512, 64)
        if isFailure then
            self.resultTooltipAnimation:GetAnimation(3):SetDuration(200)
            self.resultTooltipAnimation:GetAnimation(3):SetAlphaValues(.25, 1)
        else
            self.resultTooltipAnimation:GetAnimation(3):SetDuration(500)
            self.resultTooltipAnimation:GetAnimation(3):SetAlphaValues(0, 1)
            self.tooltipBurst1:SetTexture(burstTexture)
            self.tooltipBurst2:SetTexture(burstTexture)
        end

        self.tooltipBurst1:SetHidden(isFailure)
        self.tooltipBurst2:SetHidden(isFailure)

        self.resultTooltipAnimation.craftingType = craftingType
        self.resultTooltipAnimation:PlayFromStart()

        local secondaryTooltipAnimations = self.secondaryTooltipAnimationPool:GetActiveObjects()
        for _, animation in pairs(secondaryTooltipAnimations) do
            animation:PlayFromStart()
        end
    else
        self:OnTooltipAnimationStopped(craftingType)
    end
    PlaySound(isFailure and self.tooltipAnimationFailureSound or self.tooltipAnimationSuccessSound)
end

function ZO_CraftingResults_Base:CompleteCraftProcess(craftFailed, isExceptionalResult, craftingType)
    if not self.craftingProcessCompleted then
        if self.enchantSoundPlayer:IsPlaying() then
            self.processCompletedArguments = {craftFailed = craftFailed, isExceptionalResult = isExceptionalResult, craftingType = craftingType}
        else
            self.craftingProcessCompleted = true

            if self.playStopTooltipAnimation then
                self:PlayTooltipAnimation(craftFailed, isExceptionalResult, craftingType)
            else
                self:CheckCraftProcessCompleted(craftingType)
            end
        end
    end
end

function ZO_CraftingResults_Base:OnCraftCompleted(craftingType)
    local numItemsGained = GetNumLastCraftingResultItemsAndPenalty()
    local craftFailed = numItemsGained == 0
    local NOT_EXCEPTIONAL_RESULT = false
    self:CompleteCraftProcess(craftFailed, NOT_EXCEPTIONAL_RESULT, craftingType)
end

function ZO_CraftingResults_Base:OnRetraitCompleted(result)
    local craftFailed = result ~= RETRAIT_RESPONSE_SUCCESS
    local EXCEPTIONAL_RESULT = true
    self:CompleteCraftProcess(craftFailed, EXCEPTIONAL_RESULT)
end

function ZO_CraftingResults_Base:OnReconstructCompleted(result)
    local craftFailed = result ~= RECONSTRUCT_RESPONSE_SUCCESS
    local EXCEPTIONAL_RESULT = true
    self:CompleteCraftProcess(craftFailed, EXCEPTIONAL_RESULT)
end

function ZO_CraftingResults_Base:OnAllEnchantSoundsFinished()
    if not self.craftingProcessCompleted then
        if self.processCompletedArguments then
            local arguments = self.processCompletedArguments
            self.processCompletedArguments = nil
            self:CompleteCraftProcess(arguments.craftFailed, arguments.isExceptionalResult, arguments.craftingType)
        else
            self.craftingProcessCompleted = true
            self:PlayTooltipAnimation()
        end
    end
end

function ZO_CraftingResults_Base:OnTooltipAnimationStopped(craftingType)
    if self.tooltipAnimationCompleted == false then
        self.tooltipAnimationCompleted = true
        self:CheckCraftProcessCompleted(craftingType)
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
    elseif craftingType == CRAFTING_TYPE_JEWELRYCRAFTING then
        return SOUNDS.JEWELRYCRAFTER_EXTRACTED_BOOSTER
    end
end

local SMITHING_TYPE_TO_FAILED_EXTRACTION_SOUND =
{
    [CRAFTING_TYPE_BLACKSMITHING] = SOUNDS.BLACKSMITH_FAILED_EXTRACTION,
    [CRAFTING_TYPE_CLOTHIER] = SOUNDS.CLOTHIER_FAILED_EXTRACTION,
    [CRAFTING_TYPE_WOODWORKING] = SOUNDS.WOODWORKER_FAILED_EXTRACTION,
    [CRAFTING_TYPE_JEWELRYCRAFTING] = SOUNDS.JEWELRYCRAFTER_FAILED_EXTRACTION,
}
local function GetFailedSmithingExtractionResultInfo(craftingType)
    local failedExtractionSound = internalassert(SMITHING_TYPE_TO_FAILED_EXTRACTION_SOUND[craftingType])
    return SI_SMITHING_EXTRACTION_FAILED, failedExtractionSound
end

local function DidLastCraftGainBooster(numItemsGained)
    local smithingObject = ZO_Smithing_GetActiveObject()
    if smithingObject and smithingObject:IsExtracting() then
        local craftingType = GetCraftingInteractionType()
        local boosterItemType = ZO_CraftingUtils_GetBoosterItemType(craftingType)
        for i = 1, numItemsGained do
            local name, icon, stack, sellPrice, meetsUsageRequirement, equipType, itemType = GetLastCraftingResultItemInfo(i)
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

do
    local CRAFTING_RESULT_SORT_ORDER =
    {
        displayQuality = { tiebreaker = "quality", isNumeric = true, tieBreakerSortOrder = ZO_SORT_ORDER_DOWN },
        -- quality is deprecated, included here for addon backwards compatibility
        quality = { tiebreaker = "stack", isNumeric = true, tieBreakerSortOrder = ZO_SORT_ORDER_DOWN },
        stack = { tiebreaker = "resultIndex", isNumeric = true, tieBreakerSortOrder = ZO_SORT_ORDER_UP },
        resultIndex = { isNumeric = true },
    }
    local function CompareCraftingResultItems(left, right)
        return ZO_TableOrderingFunction(left, right, "displayQuality", CRAFTING_RESULT_SORT_ORDER, ZO_SORT_ORDER_DOWN)
    end

    function ZO_CraftingResults_Base:CheckCraftProcessCompleted(craftingType)
        if self:IsActive() and self.craftingProcessCompleted and self.tooltipAnimationCompleted then
            if GetNumLastCraftingResultLearnedTraits() > 0 then
                self:DisplayDiscoveredTraits()
            end

            local numResultCurrencies = GetNumLastCraftingResultCurrencies()
            local numItemsGained, penaltyApplied = GetNumLastCraftingResultItemsAndPenalty()

            if penaltyApplied then
                TriggerTutorial(TUTORIAL_TRIGGER_DECONSTRUCTION_LEVEL_PENALTY)
            end

            if numItemsGained == 0 and numResultCurrencies == 0 then
                if craftingType == CRAFTING_TYPE_ALCHEMY then
                    -- Crafted inert potion
                    ZO_AlertNoSuppression(UI_ALERT_CATEGORY_ALERT, nil, SI_ALCHEMY_NO_YIELD)
                elseif craftingType == CRAFTING_TYPE_ENCHANTING then
                    -- No extraction results
                    ZO_AlertNoSuppression(UI_ALERT_CATEGORY_ALERT, nil, SI_ENCHANT_NO_YIELD)
                elseif IsSmithingCraftingType(craftingType) then
                    -- Only display extraction-related messaging for operations that produce items.
                    if self.craftingProcessProducesItems then
                        -- No results from gear deconstruction
                        local failedExtractionStringId, failedExtractionSoundName = GetFailedSmithingExtractionResultInfo(craftingType)
                        if penaltyApplied then
                            ZO_AlertNoSuppression(UI_ALERT_CATEGORY_ALERT, failedExtractionSoundName, SI_SMITHING_DECONSTRUCTION_LEVEL_PENALTY)
                        else
                            ZO_AlertNoSuppression(UI_ALERT_CATEGORY_ALERT, failedExtractionSoundName, failedExtractionStringId)
                        end
                    end
                end
            else
                local shouldDisplayMessages = self:ShouldDisplayMessages()
                local finalItemSoundCategory = ITEM_SOUND_CATEGORY_NONE
                local resultIndex = 0
                local resultItems = {}
                for i = 1, numItemsGained do
                    local name, icon, stack, sellPrice, meetsUsageRequirement, equipType, itemType, itemStyle, displayQuality, itemSoundCategory, itemInstanceId = GetLastCraftingResultItemInfo(i)

                    -- Don't save messages if we can't display them immediately
                    if shouldDisplayMessages then
                        resultIndex = resultIndex + 1
                        table.insert(resultItems,
                        {
                            resultType = ZO_CRAFTING_RESULT_TYPE.ITEM,
                            resultIndex = resultIndex,
                            name = name,
                            icon = icon,
                            stack = stack,
                            color = GetItemQualityColor(displayQuality),
                            sellPrice = sellPrice,
                            meetsUsageRequirement = meetsUsageRequirement,
                            equipType = equipType,
                            itemType = itemType,
                            itemStyle = itemStyle,
                            displayQuality = displayQuality,
                            -- quality is deprecated, included here for addon backwards compatibility
                            quality = displayQuality,
                            itemSoundCategory = itemSoundCategory,
                            itemInstanceId = itemInstanceId,
                            itemLink = GetLastCraftingResultItemLink(i),
                        })
                    end

                    if finalItemSoundCategory == ITEM_SOUND_CATEGORY_NONE then
                        finalItemSoundCategory = itemSoundCategory
                    end
                end

                table.sort(resultItems, CompareCraftingResultItems)
                for _, resultItem in ipairs(resultItems) do
                    self:DisplayCraftingResult(resultItem)
                end

                if numResultCurrencies ~= 0 and shouldDisplayMessages then
                    -- Append any resulting currencies after any resulting items.
                    for currencyIndex = 1, numResultCurrencies do
                        resultIndex = resultIndex + 1
                        local currencyType, currencyAmount = GetLastCraftingResultCurrencyInfo(currencyIndex)
                        local IS_SINGULAR = true
                        local IS_NOT_UPPERCASE = false
                        local currencyName = GetCurrencyName(currencyType, IS_SINGULAR, IS_NOT_UPPERCASE)
                        local resultData =
                        {
                            resultType = ZO_CRAFTING_RESULT_TYPE.CURRENCY,
                            resultIndex = resultIndex,
                            currencyType = currencyType,
                            name = currencyName,
                            icon = ZO_Currency_GetPlatformCurrencyIcon(currencyType),
                            stack = currencyAmount,
                            color = ZO_Currency_GetPlatformColor(currencyType),
                        }
                        self:DisplayCraftingResult(resultData)
                    end
                end

                local gainedBooster = DidLastCraftGainBooster(numItemsGained)
                if gainedBooster then
                    PlaySound(GetBoosterFoundSoundForCraftingType())
                else
                    self:PlayCraftedSound(finalItemSoundCategory)
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
end

function ZO_CraftingResults_Base:ForceCompleteCraftProcess()
    if not (self.craftingProcessCompleted and self.tooltipAnimationCompleted) then
        self.craftingProcessCompleted = true
        self.tooltipAnimationCompleted = true
        CALLBACK_MANAGER:FireCallbacks("CraftingAnimationsStopped")
    end
end

function ZO_CraftingResults_Base:IsCraftInProgress()
    return self.craftingProcessCompleted == false or self.tooltipAnimationCompleted == true
end

function ZO_CraftingResults_Base:HasEntries()
    return false
end

function ZO_CraftingResults_Base:AreCraftingResultsEqual(left, right)
    local resultType = left.resultType
    if resultType ~= right.resultType then
        return false
    end

    if resultType == ZO_CRAFTING_RESULT_TYPE.ITEM then
        return left.itemInstanceId == right.itemInstanceId
    elseif resultType == ZO_CRAFTING_RESULT_TYPE.CURRENCY then
        return left.currencyType == right.currencyType
    elseif resultType == ZO_CRAFTING_RESULT_TYPE.KNOWLEDGE then
        --Knowledge will never be the same, as you can only learn a trait or translation once
        return false
    else
        internalassert(false, "No equality has been defined for crafting result type %d.", resultType)
        return false
    end
end

function ZO_CraftingResults_Base:DisplayCraftingResult()
    assert(false, "You must override the DisplayCraftingResult function when inheriting from ZO_CraftingResults_Base")
end

function ZO_CraftingResults_Base:DisplayDiscoveredTraits()
    assert(false, "You must override the DisplayDiscoveredTraits function when inheriting from ZO_CraftingResults_Base")
end

function ZO_CraftingResults_Base:DisplayTranslatedRunes()
    assert(false, "You must override the DisplayTranslatedRunes function when inheriting from ZO_CraftingResults_Base")
end

function ZO_CraftingResults_Base:FadeAll()
    assert(false, "You must override the FadeAll function when inheriting from ZO_CraftingResults_Base")
end

function ZO_CraftingResults_Base:IsActive()
    assert(false, "You must override the IsActive function when inheriting from ZO_CraftingResults_Base")
end

function ZO_CraftingResults_Base:ShouldDisplayMessages()
    assert(false, "You must override the ShouldDisplayMessages function when inheriting from ZO_CraftingResults_Base")
end