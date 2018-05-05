
ZO_RetraitStation_Retrait_Base = ZO_Object:Subclass()

function ZO_RetraitStation_Retrait_Base:New(...)
    local obj = ZO_Object.New(self)
    obj:Initialize(...)
    return obj
end

function ZO_RetraitStation_Retrait_Base:Initialize(control)
    self.control = control

    self:InitializeInventory()
    self:InitializeKeybindStripDescriptors()

    CALLBACK_MANAGER:RegisterCallback("CraftingAnimationsStarted", function(...) self:OnRetraitAnimationsStarted(...) end)
    CALLBACK_MANAGER:RegisterCallback("CraftingAnimationsStopped", function(...) self:OnRetraitAnimationsStopped(...) end)
end

function ZO_RetraitStation_Retrait_Base:ShowRetraitDialog(bagId, slotIndex, selectedTrait)
    if IsAwaitingCraftingProcessResponse() then
        return
    end

    local isItemLocked = IsItemPlayerLocked(bagId, slotIndex)

    local dialogName = "CONFIRM_RETRAIT_ITEM"
    if isItemLocked then
        if IsInGamepadPreferredMode() then
            dialogName = "GAMEPAD_CONFIRM_RETRAIT_LOCKED_ITEM"
        else
            dialogName = "CONFIRM_RETRAIT_LOCKED_ITEM"
        end
    end

    local itemQuality = GetItemQuality(bagId, slotIndex)
    local itemQualityColor = GetItemQualityColor(itemQuality)
    local itemName = itemQualityColor:Colorize(GetItemName(bagId, slotIndex))
    local traitName = ZO_SELECTED_TEXT:Colorize(GetString("SI_ITEMTRAITTYPE", selectedTrait))

    local retraitCost, retraitCurrency, retraitCurrencyLocation = GetItemRetraitCost()
    local formattedRetraitCost = ZO_Currency_FormatPlatform(retraitCurrency, retraitCost, ZO_CURRENCY_FORMAT_WHITE_AMOUNT_ICON)

    local function ShowRetraitDialog()
        ZO_Dialogs_ShowPlatformDialog(dialogName, { bagId = bagId, slotIndex = slotIndex, trait = selectedTrait, }, { mainTextParams = { itemName, traitName, formattedRetraitCost, GetString(SI_PERFORM_ACTION_CONFIRMATION) } })
    end

    if IsItemBoPAndTradeable(bagId, slotIndex) then
        ZO_Dialogs_ShowPlatformDialog("CONFIRM_MODIFY_TRADE_BOP", { onAcceptCallback = ShowRetraitDialog }, { mainTextParams = { itemName } })
    else
        ShowRetraitDialog()
    end
end

function ZO_RetraitStation_Retrait_Base:UpdateRequireResearchTooltipString(bagId, slotIndex)
    local tradeskillType, researchLineName = GetRearchLineInfoFromRetraitItem(bagId, slotIndex)
    local tradeskillName = GetCraftingSkillName(tradeskillType)
    self.requiredResearchTooltipString = zo_strformat(SI_RETRAIT_STATION_MUST_RESEARCH_TRAIT, tradeskillName)
end

function ZO_RetraitStation_Retrait_Base:InitializeInventory()
    -- To be overridden
end

function ZO_RetraitStation_Retrait_Base:InitializeKeybindStripDescriptors()
    -- To be overridden
end

function ZO_RetraitStation_Retrait_Base:HandleDirtyEvent()
    if self.control:IsHidden() then
        self.dirty = true
    else
        self:Refresh()
    end
end

function ZO_RetraitStation_Retrait_Base:Refresh()
    self.dirty = false
    -- To be overridden
end

function ZO_RetraitStation_Retrait_Base:OnRetraitResult(result)
    -- To be overridden
end

function ZO_RetraitStation_Retrait_Base:IsShowing()
    return not self.control:IsHidden()
end

function ZO_RetraitStation_Retrait_Base:OnRetraitAnimationsStarted()
    -- Optional override
end

function ZO_RetraitStation_Retrait_Base:OnRetraitAnimationsStopped()
    -- Optional override
end

function ZO_RetraitStation_Retrait_Base:IsItemAlreadySlottedToCraft(bagId, slotIndex)
    -- To be overridden
end

function ZO_RetraitStation_Retrait_Base:CanItemBeAddedToCraft(bagId, slotIndex)
    return CanItemBeRetraited(bagId, slotIndex)
end

function ZO_RetraitStation_Retrait_Base:AddItemToCraft(bagId, slotIndex)
    -- To be overridden
end

function ZO_RetraitStation_Retrait_Base:RemoveItemFromCraft(bagId, slotIndex)
    -- To be overridden
end

-----
-- Global functions
-----

function ZO_RetraitStation_DoesItemPassFilter(bagId, slotIndex, filterType)
    return ZO_CraftingUtils_GetSmithingFilterFromItem(bagId, slotIndex) == filterType
end

function ZO_RetraitStation_CanItemBeRetraited(itemData)
    return CanItemBeRetraited(itemData.bagId, itemData.slotIndex)
end
