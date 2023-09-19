local SELL_REASON_COLOR = ZO_ColorDef:New( GetInterfaceColor(INTERFACE_COLOR_TYPE_ITEM_TOOLTIP, ITEM_TOOLTIP_COLOR_SELLS_FOR) )

SHOW_BASE_ABILITY = true

local MOUSE_OVER_TYPE_UNIT = 1
local MOUSE_OVER_TYPE_FIXTURE = 2

local g_MouseOverType = nil

local BORDER_TEXTURE_NORMAL = "EsoUI/Art/Tooltips/UI-Border.dds"
local DIVIDER_TEXTURE_NORMAL = "EsoUI/Art/Miscellaneous/horizontalDivider.dds"
local BORDER_TEXTURE_STOLEN = "EsoUI/Art/Tooltips/UI-Border-Red.dds"
local DIVIDER_TEXTURE_STOLEN = "EsoUI/Art/Miscellaneous/horizontalDividerRed.dds"
local BORDER_TEXTURE_MYTHIC = "EsoUI/Art/Tooltips/UI-Border_Mythic.dds"
local BORDER_TEXTURE_MYTHIC_STOLEN = "EsoUI/Art/Tooltips/UI-Border_Mythic_Red.dds"
local DIVIDER_TEXTURE_MYTHIC = "EsoUI/Art/Miscellaneous/horizontalDivider_Mythic.dds"
local TOOLTIP_EDGE_WIDTH  = 128
local TOOLTIP_EDGE_HEIGHT = 16
local TOOLTIP_EDGE_WIDTH_MYTHIC  = 256
local TOOLTIP_EDGE_HEIGHT_MYTHIC = 32

local function ClearMouseOverTooltip()
    if g_MouseOverType == MOUSE_OVER_TYPE_FIXTURE then
        ClearTooltip(InformationTooltip)
    elseif g_MouseOverType == MOUSE_OVER_TYPE_UNIT then
        ClearTooltip(GameTooltip)
    end
    g_MouseOverType = nil
end

RIDING_TRAIN_DESCRIPTIONS = {
    [RIDING_TRAIN_SPEED] = SI_MOUNT_TRAIN_SPEED,
    [RIDING_TRAIN_STAMINA] = SI_MOUNT_TRAIN_STAMINA,
    [RIDING_TRAIN_CARRYING_CAPACITY] = SI_MOUNT_TRAIN_CARRYING_CAPACITY,
}

function SetTooltipToMountTrain(tooltip, trainType)
    local descriptionStringId = RIDING_TRAIN_DESCRIPTIONS[trainType]
    if descriptionStringId then
        SetTooltipText(tooltip, zo_strformat(descriptionStringId, GetMaxRidingTraining(trainType)))
    end
end

local REASON_CURRENCY_SPACING = 3
local MONEY_LINE_HEIGHT = 18

function ZO_ItemTooltip_SetMoney(tooltipControl, amount, reason, notEnough)
    tooltipControl:ClearLines()
    ZO_ItemTooltip_AddMoney(tooltipControl, amount, reason, notEnough)
end

local ITEM_TOOLTIP_CURRENCY_OPTIONS = 
{
    showTooltips = false
}

function ZO_ItemTooltip_AddMoney(tooltipControl, amount, reason, notEnough)
    local moneyLine = GetControl(tooltipControl, "SellPrice")        
    local reasonLabel = GetControl(moneyLine, "Reason")
    local currencyControl = GetControl(moneyLine, "Currency")
        
    moneyLine:SetHidden(false)    
   
    local width = 0
    reasonLabel:ClearAnchors()
    currencyControl:ClearAnchors()
    
     -- right now reason is always a string index
    if(reason and reason ~= 0) then
        reasonLabel:SetAnchor(TOPLEFT, nil, TOPLEFT, 0, 0)
        currencyControl:SetAnchor(TOPLEFT, reasonLabel, TOPRIGHT, REASON_CURRENCY_SPACING, -2)

        reasonLabel:SetHidden(false)
        reasonLabel:SetColor(SELL_REASON_COLOR:UnpackRGBA())
        reasonLabel:SetText(GetString(reason))
        
        local reasonTextWidth, reasonTextHeight = reasonLabel:GetTextDimensions()
        width = width + reasonTextWidth + REASON_CURRENCY_SPACING
    else
        reasonLabel:SetHidden(true)
        currencyControl:SetAnchor(TOPLEFT, nil, TOPLEFT, 0, 0)
    end

    if(amount > 0) then
        currencyControl:SetHidden(false)
        ZO_CurrencyControl_SetSimpleCurrency(currencyControl, CURT_MONEY, amount, ITEM_TOOLTIP_CURRENCY_OPTIONS, CURRENCY_DONT_SHOW_ALL, notEnough)
        width = width + currencyControl:GetWidth()
    else
        currencyControl:SetHidden(true)
    end

    tooltipControl:AddControl(moneyLine)
    moneyLine:SetAnchor(CENTER)
    moneyLine:SetDimensions(width, MONEY_LINE_HEIGHT)
end

function ZO_ItemTooltip_ClearMoney(tooltipControl)
    local currencyControl = GetControl(tooltipControl, "SellPrice")
    if currencyControl then
        currencyControl:SetHidden(true)
        currencyControl:ClearAnchors()
    end

    currencyControl = GetControl(tooltipControl, "SellPrice2")
    if currencyControl then
        currencyControl:SetHidden(true)
        currencyControl:ClearAnchors()
    end
end

function ZO_ItemTooltip_ClearCharges(tooltipControl)
    local chargeMeter = GetControl(tooltipControl, "Charges")
    if chargeMeter then
        chargeMeter:SetHidden(true)
    end
end

function ZO_ItemTooltip_ClearCondition(tooltipControl)
    local conditionMeter = GetControl(tooltipControl, "Condition")
    if conditionMeter then
        conditionMeter:SetHidden(true)
    end
end

function ZO_ItemTooltip_ClearEquippedInfo(tooltipControl)
    local equippedInfo = tooltipControl:GetNamedChild("EquippedInfo")
    if equippedInfo then
        equippedInfo:SetHidden(true)
    end
end

function ZO_ItemTooltip_Cleared(tooltipControl)
    ZO_ItemTooltip_ClearCharges(tooltipControl)
    ZO_ItemTooltip_ClearCondition(tooltipControl)
    ZO_ItemTooltip_ClearEquippedInfo(tooltipControl)
    ZO_ItemTooltip_ClearMoney(tooltipControl)
    ZO_Tooltip_OnCleared(tooltipControl)
end

do
    local function CouldSlotHaveMultipleItems(equipSlot)
        return equipSlot == EQUIP_SLOT_RING1
            or equipSlot == EQUIP_SLOT_RING2
            or equipSlot == EQUIP_SLOT_MAIN_HAND
            or equipSlot == EQUIP_SLOT_OFF_HAND
            or equipSlot == EQUIP_SLOT_BACKUP_MAIN
            or equipSlot == EQUIP_SLOT_BACKUP_OFF
    end

    function ZO_ItemTooltip_SetEquippedInfo(tooltipControl, equipSlot, actorCategory)
        local equippedInfo = tooltipControl:GetNamedChild("EquippedInfo")
        if equippedInfo then
            equippedInfo:SetHidden(false)
            local text = equippedInfo:GetNamedChild("Text")
            if CouldSlotHaveMultipleItems(equipSlot) then
                text:SetText(zo_strformat(SI_ITEM_FORMAT_STR_EQUIPPED_SLOT, GetString("SI_EQUIPSLOT", equipSlot)))
            else
                local equippedStringId = SI_ITEM_FORMAT_STR_EQUIPPED
                if actorCategory == GAMEPLAY_ACTOR_CATEGORY_COMPANION then
                    equippedStringId = SI_ITEM_FORMAT_STR_EQUIPPED_COMPANION
                end
                text:SetText(GetString(equippedStringId))
            end
        end
    end
end

function ZO_ItemTooltip_OnAddGameData(tooltipControl, gameDataType, ...)
    if gameDataType == TOOLTIP_GAME_DATA_CHARGES then
        ZO_ItemTooltip_SetCharges(tooltipControl, ...)
    elseif gameDataType == TOOLTIP_GAME_DATA_CONDITION then
        ZO_ItemTooltip_SetCondition(tooltipControl, ...)
    elseif gameDataType == TOOLTIP_GAME_DATA_EQUIPPED_INFO then
        ZO_ItemTooltip_SetEquippedInfo(tooltipControl, ...)
    elseif gameDataType == TOOLTIP_GAME_DATA_MYTHIC_OR_STOLEN then
        ZO_ItemTooltip_UpdateVisualStyle(tooltipControl, ...)
    else
        ZO_Tooltip_OnAddGameData(tooltipControl, gameDataType, ...)
    end
end

local function SetTooltipIconTexture(tooltipControl, texture)
    local icon = tooltipControl:GetNamedChild("Icon")
    local fadeLeft = tooltipControl:GetNamedChild("FadeLeft")
    local fadeRight = tooltipControl:GetNamedChild("FadeRight")

    local hidden = texture == nil
    icon:SetHidden(hidden)
    if not hidden then 
        icon:SetTexture(texture)
    end
    fadeLeft:SetHidden(hidden)
    fadeRight:SetHidden(hidden)
end

function ZO_IconTooltip_Cleared(tooltipControl)
    SetTooltipIconTexture(tooltipControl, nil)
end

function ZO_IconTooltip_OnAddGameData(tooltipControl, gameDataType, ...)
    if gameDataType == TOOLTIP_GAME_DATA_ITEM_ICON then
        SetTooltipIconTexture(tooltipControl, ...)
    end
end

function ZO_ItemIconTooltip_Cleared(tooltipControl)
    ZO_ItemTooltip_Cleared(tooltipControl)
    SetTooltipIconTexture(tooltipControl, nil)
end

function ZO_ItemIconTooltip_OnAddGameData(tooltipControl, gameDataType, ...)
    if gameDataType == TOOLTIP_GAME_DATA_ITEM_ICON then
        SetTooltipIconTexture(tooltipControl, ...)
    else
        ZO_ItemTooltip_OnAddGameData(tooltipControl, gameDataType, ...)
    end
end

function ZO_PopupTooltip_SetLink(link)
    if not PopupTooltip:IsHidden() and PopupTooltip.lastLink == link then
        ZO_PopupTooltip_Hide()
        return false
    end

    PopupTooltip:SetHidden(false)
    PopupTooltip:ClearLines()
    PopupTooltip:SetLink(link)
    PopupTooltip.lastLink = link

    return true
end

function ZO_PopupTooltip_Hide()
    PopupTooltip:SetHidden(true)
    PopupTooltip.lastLink = nil
end

function ZO_ItemTooltip_UpdateVisualStyle(tooltipControl, isItemMythic, isItemStolen)
    local borderTexture
    local dividerTexture
    local edgeWidth = TOOLTIP_EDGE_WIDTH
    local edgeHeight = TOOLTIP_EDGE_HEIGHT

    if isItemMythic then
        if isItemStolen then
            borderTexture = BORDER_TEXTURE_MYTHIC_STOLEN
            dividerTexture = DIVIDER_TEXTURE_STOLEN
        else
            borderTexture = BORDER_TEXTURE_MYTHIC
            dividerTexture = DIVIDER_TEXTURE_MYTHIC
        end
        edgeWidth = TOOLTIP_EDGE_WIDTH_MYTHIC
        edgeHeight = TOOLTIP_EDGE_HEIGHT_MYTHIC
    else
       if isItemStolen then
            borderTexture = BORDER_TEXTURE_STOLEN
            dividerTexture = DIVIDER_TEXTURE_STOLEN
        else
            borderTexture = BORDER_TEXTURE_NORMAL
            dividerTexture = DIVIDER_TEXTURE_NORMAL
        end
    end

    tooltipControl:GetNamedChild("BG"):SetEdgeTexture(borderTexture, edgeWidth, edgeHeight)
    tooltipControl:GetNamedChild("BG"):SetInsets(edgeHeight, edgeHeight, -edgeHeight, -edgeHeight)

    -- Color all dividers
    if tooltipControl.dividerPool then
        local dividers = tooltipControl.dividerPool:GetActiveObjects()
        for _, divider in pairs(dividers) do
            divider:SetTexture(dividerTexture)
        end
    end
end

function ZO_ItemTooltip_SetCharges(tooltipControl, charges, maxCharges)
    local chargeMeterContainer = tooltipControl:GetNamedChild("Charges")
    if chargeMeterContainer then
        charges = charges / 2
        maxCharges = maxCharges / 2

        local leftBar = chargeMeterContainer:GetNamedChild("BarLeft")
        local rightBar = chargeMeterContainer:GetNamedChild("BarRight")

        local gradient = ZO_POWER_BAR_GRADIENT_COLORS[COMBAT_MECHANIC_FLAGS_MAGICKA]
        ZO_StatusBar_SetGradientColor(leftBar, gradient)
        ZO_StatusBar_SetGradientColor(rightBar, gradient)

        leftBar:SetMinMax(0, maxCharges)
        rightBar:SetMinMax(0, maxCharges)

        leftBar:SetValue(charges)
        rightBar:SetValue(charges)

        tooltipControl:AddControl(chargeMeterContainer)
        chargeMeterContainer:SetHidden(false)
        chargeMeterContainer:SetAnchor(CENTER)
    end

    ZO_ItemTooltip_UpdateVisualStyle(tooltipControl)
end

function ZO_ItemTooltip_SetCondition(tooltipControl, condition, maxCondition)
    local conditionMeterContainer = tooltipControl:GetNamedChild("Condition")
    if conditionMeterContainer then
        condition = condition / 2
        maxCondition = maxCondition / 2

        local leftBar = conditionMeterContainer:GetNamedChild("BarLeft")
        local rightBar = conditionMeterContainer:GetNamedChild("BarRight")

        local gradient = ZO_POWER_BAR_GRADIENT_COLORS[COMBAT_MECHANIC_FLAGS_STAMINA]
        ZO_StatusBar_SetGradientColor(leftBar, gradient)
        ZO_StatusBar_SetGradientColor(rightBar, gradient)

        leftBar:SetMinMax(0, maxCondition)
        rightBar:SetMinMax(0, maxCondition)

        leftBar:SetValue(condition)
        rightBar:SetValue(condition)

        tooltipControl:AddControl(conditionMeterContainer)
        conditionMeterContainer:SetHidden(false)
        conditionMeterContainer:SetAnchor(CENTER)
    end

    ZO_ItemTooltip_UpdateVisualStyle(tooltipControl)
end

local function SetTooltipActiveSkillProgression(tooltipControl, progressionIndex, lastRankXP, nextRankXP, currentXP, atMorph)
    tooltipControl.xpBar:SetMinMax(lastRankXP, nextRankXP)
    tooltipControl.xpBar:SetValue(currentXP)

    tooltipControl.progressionIndex = progressionIndex

    tooltipControl:AddControl(tooltipControl.xpBar)
    tooltipControl.xpBar:SetAnchor(CENTER)
    tooltipControl.xpBar:SetHidden(false)
end

local function ClearTooltipActiveSkillProgression(tooltipControl)
    tooltipControl.xpBar:SetHidden(true)
    tooltipControl.progressionIndex = nil
end

local function OnTooltipActiveSkillProgressionXPUpdate(tooltipControl, progressionIndex, lastRankXP, nextRankXP, currentXP, atMorph)
    if not tooltipControl:IsHidden() and tooltipControl.progressionIndex == progressionIndex then
        tooltipControl.xpBar:SetMinMax(lastRankXP, nextRankXP)
        tooltipControl.xpBar:SetValue(currentXP)
    end
end

function ZO_SkillTooltip_SetSkillUpgrade(tooltipControl, source, dest)
    if not tooltipControl.upgradePool then
        tooltipControl.upgradePool = ZO_ControlPool:New("SkillTooltipUpgradeLine", tooltipControl, "SkillUpgrade")
    end

    local skillUpgradeControl = tooltipControl.upgradePool:AcquireObject()

    if skillUpgradeControl and source and dest then
        GetControl(skillUpgradeControl, "SourceText"):SetText(source)
        GetControl(skillUpgradeControl, "DestText"):SetText(dest)

        local useCell = 1
        local useLastRowAdded = true
        tooltipControl:AddControl(skillUpgradeControl, useCell, useLastRowAdded)
        skillUpgradeControl:SetAnchor(CENTER)
    end
end

function ZO_SkillTooltip_Initialize(tooltipControl)
    tooltipControl.xpBar = tooltipControl:GetNamedChild("Progression")
    ZO_StatusBar_SetGradientColor(tooltipControl.xpBar, ZO_XP_BAR_GRADIENT_COLORS)

    EVENT_MANAGER:RegisterForEvent("SkillTooltip", EVENT_ABILITY_PROGRESSION_XP_UPDATE, function(_, ...)
        OnTooltipActiveSkillProgressionXPUpdate(tooltipControl, ...)
    end)
end

function ZO_SkillTooltip_Cleared(tooltipControl)
    if tooltipControl.upgradePool then
        tooltipControl.upgradePool:ReleaseAllObjects()
    end
    ClearTooltipActiveSkillProgression(tooltipControl)
    ZO_Tooltip_OnCleared(tooltipControl)
end

function ZO_SkillTooltip_OnAddGameData(tooltipControl, gameDataType, ...)
    if gameDataType == TOOLTIP_GAME_DATA_SKILL_UPGRADE then
        ZO_SkillTooltip_SetSkillUpgrade(tooltipControl, ...)
    elseif gameDataType == TOOLTIP_GAME_DATA_PROGRESSION then
        SetTooltipActiveSkillProgression(tooltipControl, ...)
    else
        ZO_Tooltip_OnAddGameData(tooltipControl, gameDataType, ...)
    end
end

-- Champion Skill Tooltip

local function SetTooltipChampionSkillProgression(tooltipControl, championSkillId, pendingPoints)
    local championSkillData = CHAMPION_DATA_MANAGER:GetChampionSkillData(championSkillId)

    local min = 0
    local max = championSkillData:GetMaxPossiblePoints()
    tooltipControl.progressionStatusBar:SetMinMax(min, max)
    tooltipControl.progressionStatusBar:SetValue(pendingPoints)

    tooltipControl.minResultLabel:SetText(min)
    tooltipControl.maxResultLabel:SetText(max)

    tooltipControl:AddControl(tooltipControl.progressionControl)
    tooltipControl.progressionControl:SetAnchor(TOP)
    tooltipControl.progressionControl:SetHidden(false)

    -- only calculate offsets after the control has been resized
    local maskValue = nil
    if championSkillData:HasJumpPoints() then
        local jumpPoints = championSkillData:GetJumpPoints()
        for _, jumpPoint in ipairs(jumpPoints) do
            if maskValue == nil and jumpPoint >= pendingPoints then
                -- first jump point above or at pending points, store it as the mask point
                maskValue = jumpPoint
            end

            if jumpPoint > min and jumpPoint < max then
                local offsetX = tooltipControl.progressionStatusBar:CalculateSizeWithoutLeadingEdgeForValue(jumpPoint)
                local notchControl = tooltipControl.notchPool:AcquireObject()
                notchControl:SetAnchor(TOP, tooltipControl.progressionStatusBar, TOPLEFT, offsetX)
                notchControl:SetAnchor(BOTTOM, tooltipControl.progressionStatusBar, BOTTOMLEFT, offsetX)
            end
        end
    else
        maskValue = max
    end

    if maskValue ~= max then
        -- set mask to notch position
        local maskOffsetX = tooltipControl.progressionStatusBar:CalculateSizeWithoutLeadingEdgeForValue(maskValue)
        tooltipControl.progressionBarMask:SetAnchor(TOPLEFT, tooltipControl.progressionStatusBar, TOPLEFT)
        tooltipControl.progressionBarMask:SetAnchor(BOTTOMRIGHT, tooltipControl.progressionStatusBar, BOTTOMLEFT, maskOffsetX)
    else
        -- set mask to end of bar
        tooltipControl.progressionBarMask:SetAnchor(TOPLEFT, tooltipControl.progressionStatusBar, TOPLEFT)
        tooltipControl.progressionBarMask:SetAnchor(BOTTOMRIGHT, tooltipControl.progressionStatusBar, BOTTOMRIGHT)
    end
end

local function ClearTooltipChampionSkillProgression(tooltipControl)
    tooltipControl.notchPool:ReleaseAllObjects()
    tooltipControl.progressionControl:SetHidden(true)
end

function ZO_ChampionSkillTooltip_Initialize(tooltipControl)
    tooltipControl.progressionControl = tooltipControl:GetNamedChild("Progression")
    tooltipControl.progressionBarMask = tooltipControl.progressionControl:GetNamedChild("Mask")
    tooltipControl.progressionStatusBar = tooltipControl.progressionBarMask:GetNamedChild("Bar")
    tooltipControl.notchPool = ZO_ControlPool:New("ZO_ChampionSkillStatusBarNotch", tooltipControl.progressionControl:GetNamedChild("Overlay"), "Notch")
    tooltipControl.minResultLabel = tooltipControl.progressionControl:GetNamedChild("MinResult")
    tooltipControl.maxResultLabel = tooltipControl.progressionControl:GetNamedChild("MaxResult")
    ZO_StatusBar_SetGradientColor(tooltipControl.progressionStatusBar, ZO_XP_BAR_GRADIENT_COLORS)
end

function ZO_ChampionSkillTooltip_Cleared(tooltipControl)
    ClearTooltipChampionSkillProgression(tooltipControl)
    ZO_Tooltip_OnCleared(tooltipControl)
end

function ZO_ChampionSkillTooltip_OnAddGameData(tooltipControl, gameDataType, ...)
    if gameDataType == TOOLTIP_GAME_DATA_CHAMPION_PROGRESSION then
        SetTooltipChampionSkillProgression(tooltipControl, ...)
    else
        ZO_Tooltip_OnAddGameData(tooltipControl, gameDataType, ...)
    end
end
