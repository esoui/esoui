ZO_BUFF_DEBUFF_LONG_EFFECT_DURATION_SECONDS = 60

local BLINK_THRESHOLD_S = 2

local function GetBuffBorderTexture()
    return IsInGamepadPreferredMode() and "EsoUI/Art/ActionBar/Gamepad/gp_abilityFrame_buff.dds" or "EsoUI/Art/ActionBar/abilityFrame_buff.dds"
end

local function GetDebuffBorderTexture()
    return IsInGamepadPreferredMode() and "EsoUI/Art/ActionBar/Gamepad/gp_abilityFrame_debuff.dds" or "EsoUI/Art/ActionBar/abilityFrame_debuff.dds"
end

---------------
--Base Object--
---------------

ZO_BuffDebuffStyleObject = ZO_Object:Subclass()

function ZO_BuffDebuffStyleObject:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_BuffDebuffStyleObject:Initialize(template)
    self.template = template
    self.sortedBuffs = {}
    self.sortedDebuffs = {}

    local function SortFunction(...)
        return self:SortFunction(...)
    end

    self.SortCallbackFunction = SortFunction
end

function ZO_BuffDebuffStyleObject:GetTemplate()
    return self.template
end

local function IsVisible(containerObject, effectType, timeStarted, timeEnding, permanent, castByPlayer)
    local visible = false
    local effectTypeSetting = (effectType == BUFF_EFFECT_TYPE_BUFF) and BUFFS_SETTING_BUFFS_ENABLED or BUFFS_SETTING_DEBUFFS_ENABLED
    if containerObject:GetVisibilitySetting(effectTypeSetting) then
        visible = true
        if containerObject:GetUnitTag() == "reticleover" then
            if effectType == BUFF_EFFECT_TYPE_BUFF then
                visible = visible and containerObject:GetVisibilitySetting(BUFFS_SETTING_BUFFS_ENABLED_FOR_TARGET)
            elseif effectType == BUFF_EFFECT_TYPE_DEBUFF and not castByPlayer then
                visible = visible and containerObject:GetVisibilitySetting(BUFFS_SETTING_DEBUFFS_ENABLED_FOR_TARGET_FROM_OTHERS)
            end
        end
        if permanent then
            visible = visible and containerObject:GetVisibilitySetting(BUFFS_SETTING_PERMANENT_EFFECTS)
        else
            local duration = timeEnding - timeStarted
            if duration >= ZO_BUFF_DEBUFF_LONG_EFFECT_DURATION_SECONDS then
                visible = visible and containerObject:GetVisibilitySetting(BUFFS_SETTING_LONG_EFFECTS)
            end
        end
    end
    return visible
end

function ZO_BuffDebuffStyleObject:UpdateContainer(containerObject)
    ZO_ClearNumericallyIndexedTable(self.sortedBuffs)
    ZO_ClearNumericallyIndexedTable(self.sortedDebuffs)

    if containerObject:ShouldContextuallyShow() then
        local unitTag = containerObject:GetUnitTag()
        local uid = 1

        if unitTag == "player" then
            --Artificial effects--
            for effectId in ZO_GetNextActiveArtificialEffectIdIter do
                local displayName, iconFile, effectType, sortOrder, timeStarted, timeEnding = GetArtificialEffectInfo(effectId)
                local duration = timeEnding - timeStarted
                local permanent = duration == 0

                if IsVisible(containerObject, effectType, timeStarted, timeEnding, permanent) then
                    local data =
                    {
                        buffName = displayName,
                        timeStarted = timeStarted,
                        timeEnding = timeEnding,
                        iconFilename = iconFile,
                        stackCount = 0,
                        effectType = effectType,
                        uid = uid,
                        duration = duration,
                        permanent = permanent,
                        sortOrder = sortOrder,
                        effectId = effectId,
                        isArtificial = true,
                    }

                    local appropriateTable = (data.effectType == BUFF_EFFECT_TYPE_BUFF) and self.sortedBuffs or self.sortedDebuffs
                    table.insert(appropriateTable, data)
                    uid = uid + 1
                end
            end
        end

        for i = 1, GetNumBuffs(unitTag) do
            local buffName, timeStarted, timeEnding, buffSlot, stackCount, iconFilename, buffType, effectType, abilityType, statusEffectType, abilityId, _, castByPlayer = GetUnitBuffInfo(unitTag, i)
            local permanent = IsAbilityPermanent(abilityId)

            if IsVisible(containerObject, effectType, timeStarted, timeEnding, permanent, castByPlayer) then
                local data =
                {
                    buffName = buffName,
                    timeStarted = timeStarted,
                    timeEnding = timeEnding,
                    buffSlot = buffSlot,
                    stackCount = stackCount,
                    iconFilename = iconFilename,
                    buffType = buffType,
                    effectType = effectType,
                    abilityType = abilityType,
                    statusEffectType = statusEffectType,
                    abilityId = abilityId,
                    uid = uid,
                    duration = timeEnding - timeStarted,
                    castByPlayer = castByPlayer,
                    permanent = permanent,
                    isArtificial = false,
                }
                local appropriateTable = (data.effectType == BUFF_EFFECT_TYPE_BUFF) and self.sortedBuffs or self.sortedDebuffs
                table.insert(appropriateTable, data)
                uid = uid + 1
            end
        end

        if #self.sortedBuffs then
            table.sort(self.sortedBuffs, self.SortCallbackFunction)
        end
        if #self.sortedDebuffs then
            table.sort(self.sortedDebuffs, self.SortCallbackFunction)
        end
    end
end

local NO_LEADING_EDGE = false
local function UpdateDuration(buffDebuffControl, currentTime)
    local data = buffDebuffControl.data
    local durationLabel = buffDebuffControl.duration
    local showDuration = data.duration > 0 and not data.permanent
    durationLabel:SetHidden(not showDuration)
    if showDuration then
        local timeRemainingS = data.timeEnding - currentTime
        if buffDebuffControl.blinkAnimation and timeRemainingS <= BLINK_THRESHOLD_S then
            if not buffDebuffControl.blinkAnimation:IsPlaying() then
                buffDebuffControl.blinkAnimation:PlayFromStart()
            end
        end

        if buffDebuffControl.showCooldown then
            local cooldownControl = buffDebuffControl.cooldown
            if cooldownControl:GetDuration() == 0 then
                cooldownControl:StartCooldown(timeRemainingS * 1000, data.duration * 1000, CD_TYPE_RADIAL, CD_TIME_TYPE_TIME_UNTIL, NO_LEADING_EDGE)
                cooldownControl:SetHidden(false)
            end
        end

        local timeLeftString
        if timeRemainingS >= ZO_ONE_MINUTE_IN_SECONDS then
            timeLeftString = ZO_FormatTime(timeRemainingS, TIME_FORMAT_STYLE_SHOW_LARGEST_UNIT, TIME_FORMAT_PRECISION_SECONDS, TIME_FORMAT_DIRECTION_DESCENDING)
        elseif timeRemainingS <= 0 then
            timeLeftString = 0
        else
            timeLeftString = zo_decimalsplit(timeRemainingS)
        end

        durationLabel:SetText(timeLeftString)
    end
end

function ZO_BuffDebuffStyleObject:UpdateDurations(containerObject)
    local currentTime = GetFrameTimeSeconds()
    local buffPool, debuffPool = containerObject:GetPools()

    for _, buffControl in pairs(buffPool.activeObjects) do
        UpdateDuration(buffControl, currentTime)
    end

    for _, debuffControl in pairs(debuffPool.activeObjects) do
        UpdateDuration(debuffControl, currentTime)
    end
end

function ZO_BuffDebuffStyleObject:SetupIcon(buffDebuffControl)
    local data = buffDebuffControl.data
    buffDebuffControl:GetNamedChild("Icon"):SetTexture(data.iconFilename)
    
    local stackLabel = buffDebuffControl:GetNamedChild("Stacks")
    if data.stackCount > 0 then
        stackLabel:SetText(data.stackCount)
        stackLabel:SetHidden(false)
    else
        stackLabel:SetHidden(true)
    end

    if data.effectType == BUFF_EFFECT_TYPE_DEBUFF then
        buffDebuffControl:GetNamedChild("Frame"):SetTexture(GetDebuffBorderTexture())
    else
        buffDebuffControl:GetNamedChild("Frame"):SetTexture(GetBuffBorderTexture())
    end
end

function ZO_BuffDebuffStyleObject:SortFunction(buffData1, buffData2)
    --Default function sorts buffs before debuffs, then oldest before newest, then alphabetical
    --The uid ensure we don't get hung up on bad buff data (i.e.: duplicates)
    if buffData1.effectType == buffData2.effectType then
        if buffData1.timeStarted == buffData2.timeStarted then
            if buffData1.buffName == buffData2.buffName then
                return buffData1.uid < buffData2.uid
            else
                return buffData1.buffName < buffData2.buffName
            end
        else
            return buffData1.timeStarted < buffData2.timeStarted
        end
    else
        return buffData1.effectType == BUFF_EFFECT_TYPE_BUFF
    end
end

---------------------------
--Center Out Style Object--
---------------------------

--[[This style puts the buffs left-of-center and the debuffs right-of-center,
    each starting in the middle and working their way out 
    Example:
    | B5 B4 B3 B2 B1   D1 D2 __ __ __ |]]--

ZO_BuffDebuffCenterOutStyle = ZO_BuffDebuffStyleObject:Subclass()

function ZO_BuffDebuffCenterOutStyle:New(...)
    return ZO_BuffDebuffStyleObject.New(self, ...)
end

function ZO_BuffDebuffCenterOutStyle:UpdateContainer(containerObject)
    ZO_BuffDebuffStyleObject.UpdateContainer(self, containerObject)

    local buffPool, debuffPool = containerObject:GetPools()

    for i, data in ipairs(self.sortedBuffs) do
        local buffControl = buffPool:AcquireObject()
        buffControl.data = data
        self:SetupIcon(buffControl)
    end

    for i, data in ipairs(self.sortedDebuffs) do
        local debuffControl = debuffPool:AcquireObject()
        debuffControl.data = data
        self:SetupIcon(debuffControl)
    end
end

function ZO_BuffDebuffCenterOutStyle:SortFunction(buffData1, buffData2)
    if buffData1.effectType == buffData2.effectType then
        if buffData1.effectType == BUFF_EFFECT_TYPE_BUFF then
            if buffData1.timeStarted == buffData2.timeStarted then
                return buffData1.buffName > buffData2.buffName
            else
                return buffData1.timeStarted > buffData2.timeStarted
            end
        else
            if buffData1.timeStarted == buffData2.timeStarted then
                return buffData1.buffName <= buffData2.buffName
            else
                return buffData1.timeStarted < buffData2.timeStarted
            end
        end
    else
        return buffData1.effectType == BUFF_EFFECT_TYPE_BUFF
    end
end

ZO_BUFF_DEBUFF_CENTER_OUT_STYLE = ZO_BuffDebuffCenterOutStyle:New("ZO_BuffDebuffCenterOutStyle_Template")

---------------------------
--Spiral Out Style Object--
---------------------------

--[[This style puts the buffs first, followed by the debuffs, with the entire grouping centered together.
    Each section (buff vs debuff) is layed out such that the first one sorted is in the middle of the group
    and the subsequent entries alternate to the right and left 
    Example:
    | B5 B3 B1 B2 B4 B6  D3 D1 D2 |]]--

ZO_BuffDebuffSpiralOutStyle = ZO_BuffDebuffStyleObject:Subclass()

function ZO_BuffDebuffSpiralOutStyle:New(...)
    return ZO_BuffDebuffStyleObject.New(self, ...)
end

function ZO_BuffDebuffSpiralOutStyle:Initialize(...)
    ZO_BuffDebuffStyleObject.Initialize(self, ...)
    self.spiraledTable = {}
end

do
    local function ZO_BuffDebuffSpiralOutStyle_UpdateSpiraledTable(spiraledTable, sortedTable)
        ZO_ClearNumericallyIndexedTable(spiraledTable)
        if #sortedTable then
            local indexOneSpiralPosition = zo_ceil(#sortedTable / 2)
            spiraledTable[indexOneSpiralPosition] = sortedTable[1]

            for i = 2, #sortedTable do
                local spiralIndex
                if i % 2 == 0 then
                    spiralIndex = i / 2 + indexOneSpiralPosition
                else
                    spiralIndex = indexOneSpiralPosition - zo_floor(i / 2)
                end
                spiraledTable[spiralIndex] = sortedTable[i]
            end
        end
    end

    function ZO_BuffDebuffSpiralOutStyle:UpdateContainer(containerObject)
        ZO_BuffDebuffStyleObject.UpdateContainer(self, containerObject)

        local buffPool, debuffPool = containerObject:GetPools()

        ZO_BuffDebuffSpiralOutStyle_UpdateSpiraledTable(self.spiraledTable, self.sortedBuffs)
        for i, data in ipairs(self.spiraledTable) do
            local buffControl = buffPool:AcquireObject()
            buffControl.data = data
            self:SetupIcon(buffControl)
        end

        ZO_BuffDebuffSpiralOutStyle_UpdateSpiraledTable(self.spiraledTable, self.sortedDebuffs)
        for i, data in ipairs(self.spiraledTable) do
            local buffControl = debuffPool:AcquireObject()
            buffControl.data = data
            self:SetupIcon(buffControl)
        end
    end
end

ZO_BUFF_DEBUFF_SPIRAL_OUT_STYLE = ZO_BuffDebuffSpiralOutStyle:New("ZO_BuffDebuffAllCenteredStyle_Template")

---------------------------
--Expires In Style Object--
---------------------------

--[[This style puts both bufffs and debuffsin a single container centered on the units health bar,
    each starting in the middle and working their way out, with buffs/debuffs expiring sooner towards the middle 
    Example:
    | B5 B4 B3 B2 B1 D1 D2 |]]--

ZO_BuffDebuffExpiresInStyle = ZO_BuffDebuffStyleObject:Subclass()

function ZO_BuffDebuffExpiresInStyle:New(...)
    return ZO_BuffDebuffStyleObject.New(self, ...)
end

function ZO_BuffDebuffExpiresInStyle:UpdateContainer(containerObject)
    ZO_BuffDebuffStyleObject.UpdateContainer(self, containerObject)

    local currentTime = GetFrameTimeSeconds()
    local buffPool, debuffPool = containerObject:GetPools()

    for i, data in ipairs(self.sortedBuffs) do
        local buffControl = buffPool:AcquireObject()
        buffControl.data = data
        self:SetupIcon(buffControl)
    end

    for i, data in ipairs(self.sortedDebuffs) do
        local debuffControl = debuffPool:AcquireObject()
        debuffControl.data = data
        self:SetupIcon(debuffControl)
    end
end

function ZO_BuffDebuffExpiresInStyle:SortFunction(buffData1, buffData2)
    if buffData1.effectType == buffData2.effectType then
        local buff1Permenant = buffData1.duration == 0
        local buff2Permenant = buffData2.duration == 0

        if buffData1.effectType == BUFF_EFFECT_TYPE_BUFF then
            if buff1Permenant and buff2Permenant then
                return buffData1.buffName > buffData2.buffName
            else
                if buff1Permenant then
                    return true
                elseif buff2Permenant then
                    return false
                end

                if buffData1.timeEnding == buffData2.timeEnding then
                    return buffData1.buffName > buffData2.buffName
                else
                    return buffData1.timeEnding > buffData2.timeEnding
                end
            end
        else
            if buff1Permenant and buff2Permenant then
                return buffData1.buffName < buffData2.buffName
            else
                if buff1Permenant then
                    return false
                elseif buff2Permenant then
                    return true
                end

                if buffData1.timeEnding == buffData2.timeEnding then
                    return buffData1.buffName < buffData2.buffName
                else
                    return buffData1.timeEnding < buffData2.timeEnding
                end
            end
        end
    else
        return buffData1.effectType == BUFF_EFFECT_TYPE_BUFF
    end
end

ZO_BUFF_DEBUFF_EXPIRES_IN_STYLE = ZO_BuffDebuffExpiresInStyle:New("ZO_BuffDebuffAllCenteredStyle_Template")