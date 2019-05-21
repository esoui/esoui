--Death Recap Toggle
----------------------

local DeathRecapToggle = ZO_Object:Subclass()

function DeathRecapToggle:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function DeathRecapToggle:Initialize(control)
    DEATH_RECAP:RegisterCallback("OnDeathRecapAvailableChanged", function() self:RefreshEnabled() end)
    self:RefreshEnabled()
end

function DeathRecapToggle:RefreshEnabled()
    self.enabled = DEATH_RECAP:IsDeathRecapAvailable()
    DEATH:SetDeathRecapToggleButtonsEnabled(self.enabled)
end

function DeathRecapToggle:Toggle()
    DEATH:ToggleDeathRecap()
end

function DeathRecapToggle:Hide()
    if(self.enabled) then
        if(DEATH_RECAP:IsWindowOpen()) then
            DEATH_RECAP:SetWindowOpen(false)
            return true
        end
    end
    return false
end

--Death Recap
------------------

local DEATH_RECAP_DELAY = 2000

local DeathRecap = ZO_CallbackObject:Subclass()

function DeathRecap:New(...)
    local object = ZO_CallbackObject.New(self)
    object:Initialize(...)
    return object
end

function DeathRecap:Initialize(control)
    self.control = control
    self.scrollContainer = control:GetNamedChild("ScrollContainer")
    self.scrollControl = self.scrollContainer:GetNamedChild("ScrollChild")
    self.waitingToShowPrompt = false
    self.windowOpen = true
    self.deathRecapAvailable = false

    self.killingBlowIcon = GetControl(self.scrollControl, "AttacksKillingBlowIcon")
    self.killingBlowTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_DeathRecapKillingBlowAnimation", self.killingBlowIcon)

    self:InitializeAttackPool()
    self:InitializeTelvarStoneLossLabel()
    self:InitializeHintPool()
    self.hintTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_DeathRecapHintAnimation", self.scrollControl:GetNamedChild("HintsContainerHints"))

    EVENT_MANAGER:RegisterForEvent("DeathRecap", EVENT_PLAYER_DEAD, function() self:OnPlayerDead() end)
    EVENT_MANAGER:RegisterForEvent("DeathRecap", EVENT_PLAYER_ALIVE, function() self:OnPlayerAlive() end)
    EVENT_MANAGER:RegisterForEvent("DeathRecap", EVENT_PLAYER_ACTIVATED, function() self:SetupDeathRecap() end)
    CALLBACK_MANAGER:RegisterCallback("UnitFramesCreated", function() self:OnUnitFramesCreated() end)

    DEATH_RECAP_FRAGMENT = ZO_HUDFadeSceneFragment:New(control)
    DEATH_RECAP_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
        self:RefreshBossBarVisibility()
        self:RefreshUnitFrameVisibility()
        if newState == SCENE_FRAGMENT_SHOWING then
            if self.animateOnShow then
                self.animateOnShow = nil
                self:Animate()
            end
        end
    end)

    local function OnAddOnLoaded(event, name)
        if name == "ZO_Ingame" then
            local defaults = { recapOn = true, }
            self.savedVars = ZO_SavedVars:New("ZO_Ingame_SavedVariables", 1, "DeathRecap", defaults)
            self:SetWindowOpen(self.savedVars.recapOn)
            self.control:UnregisterForEvent(EVENT_ADD_ON_LOADED)
        end
    end
    self.control:RegisterForEvent(EVENT_ADD_ON_LOADED, OnAddOnLoaded)

    self.control:SetHandler("OnEffectivelyShown", function() self:OnEffectivelyShown() end)
    self.control:SetHandler("OnEffectivelyHidden", function() self:OnEffectivelyHidden() end)

    ZO_PlatformStyle:New(function() self:ApplyStyle() end)

    local DEATH_RECAP_RIGHT_SCROLL_INDICATOR_OFFSET_X = 793
    local DEATH_RECAP_RIGHT_SCROLL_INDICATOR_OFFSET_Y = 366
    ZO_Scroll_Gamepad_SetScrollIndicatorSide(self.scrollContainer:GetNamedChild("ScrollIndicator"), self.control, RIGHT, DEATH_RECAP_RIGHT_SCROLL_INDICATOR_OFFSET_X, DEATH_RECAP_RIGHT_SCROLL_INDICATOR_OFFSET_Y, true)
end

do
    function DeathRecap:InitializeAttackPool()
        local ICON_ANIMATION_START_INDEX = 1
        local ICON_ANIMATION_END_INDEX = 3
        local TEXT_ANIMATION_INDEX = 4
        local COUNT_ANIMATION_START_INDEX = 5
        local COUNT_ANIMATION_END_INDEX = 7
        self.attackPool = ZO_ControlPool:New("ZO_DeathRecapAttack", self.scrollControl:GetNamedChild("Attacks"), "")
        self.attackTemplate = ZO_GetPlatformTemplate("ZO_DeathRecapAttack")

        self.attackPool:SetCustomFactoryBehavior(function(control)
            control.timeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_DeathRecapAttackAnimation")
            local nestedTimeline = control.timeline:GetAnimationTimeline(1)
            local iconTexture = control:GetNamedChild("Icon")
            local textContainer = control:GetNamedChild("Text")
            
            for i = ICON_ANIMATION_START_INDEX, ICON_ANIMATION_END_INDEX do
                local animation = nestedTimeline:GetAnimation(i)
                animation:SetAnimatedControl(iconTexture)
            end
            nestedTimeline:GetAnimation(TEXT_ANIMATION_INDEX):SetAnimatedControl(textContainer)
            if not nestedTimeline.isKillingBlow then
                for i = COUNT_ANIMATION_START_INDEX, COUNT_ANIMATION_END_INDEX do
                    local numAttackHitsContainer = control:GetNamedChild("NumAttackHits")
                    local animation = nestedTimeline:GetAnimation(i)
                    animation:SetAnimatedControl(numAttackHitsContainer)
                end
            end
        end)

        self.attackPool:SetCustomAcquireBehavior(function(control)
            ApplyTemplateToControl(control, self.attackTemplate)
        end)

        self.attackPool:SetCustomResetBehavior(function(control)
            control.timeline:Stop()
            local iconTexture = control:GetNamedChild("Icon")
            iconTexture:SetScale(1)
            ApplyTemplateToControl(control, self.attackTemplate)
        end)
    end
end

function DeathRecap:InitializeHintPool()
    self.hintPool = ZO_ControlPool:New("ZO_DeathRecapHint", self.scrollControl:GetNamedChild("HintsContainerHints"), "")
    self.hintTemplate = ZO_GetPlatformTemplate("ZO_DeathRecapHint")
    
    self.hintPool:SetCustomAcquireBehavior(function(control)
        ApplyTemplateToControl(control, self.hintTemplate)
    end)
    
    self.hintPool:SetCustomResetBehavior(function(control)
        ApplyTemplateToControl(control, self.hintTemplate)
    end)
end

function DeathRecap:InitializeTelvarStoneLossLabel()
    self.telvarStoneLossControl = self.scrollControl:GetNamedChild("TelvarStoneLoss")
    self.telvarStoneLossValueControl = self.telvarStoneLossControl:GetNamedChild("Value")
    self.telvarStoneLossIconControl = self.telvarStoneLossControl:GetNamedChild("Icon")

    self.telvarLossTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_DeathRecapTelvarLossAnimation", self.telvarStoneLossControl)
end

function DeathRecap:IsWindowOpen()
    return self.windowOpen
end

function DeathRecap:SetWindowOpen(open)
    self.savedVars.recapOn = open
    self.windowOpen = open
    self:RefreshVisibility()

    if IsConsoleUI() then
        AUTO_SAVING:MarkDirty()
    end
end

function DeathRecap:IsDeathRecapAvailable()
    return self.deathRecapAvailable
end

function DeathRecap:SetDeathRecapAvailable(available)
    self.deathRecapAvailable = available
    self:FireCallbacks("OnDeathRecapAvailableChanged", available)
    self:RefreshVisibility()
end

function DeathRecap:RefreshVisibility()
    DEATH_RECAP_FRAGMENT:SetHiddenForReason("NotAvailable", not self.deathRecapAvailable)
    DEATH_RECAP_FRAGMENT:SetHiddenForReason("WindowHiddenByUser", not self.windowOpen, DEFAULT_HUD_DURATION, DEFAULT_HUD_DURATION)
end

function DeathRecap:RefreshBossBarVisibility()
    COMPASS_FRAME:SetBossBarHiddenForReason("deathRecap", not DEATH_RECAP_FRAGMENT:IsHidden())
end

function DeathRecap:RefreshUnitFrameVisibility()
    if(UNIT_FRAMES) then
        UNIT_FRAMES:SetFrameHiddenForReason("reticleover", "deathRecap", not DEATH_RECAP_FRAGMENT:IsHidden())
        UNIT_FRAMES:SetGroupAndRaidFramesHiddenForReason("deathRecap", not DEATH_RECAP_FRAGMENT:IsHidden())
    end
end

local function SortAttacks(left, right)
    if(left.wasKillingBlow) then
        return false
    elseif(right.wasKillingBlow) then
        return true
    else
        return left.lastUpdateAgoMS > right.lastUpdateAgoMS
    end    
end

function DeathRecap:SetupAttacks()
    local startAlpha = self.animateOnShow and 0 or 1
    self.attackPool:ReleaseAllObjects()
    self.killingBlowIcon:SetAlpha(startAlpha)

    local attacks = {}
    for i = 1, GetNumKillingAttacks() do
        local attackName, attackDamage, attackIcon, wasKillingBlow, castTimeAgoMS, durationMS, numAttackHits = GetKillingAttackInfo(i)
        local attackInfo = {
            index = i,
            attackName = attackName,
            attackDamage = attackDamage,
            attackIcon = attackIcon,
            wasKillingBlow = wasKillingBlow,
            lastUpdateAgoMS = castTimeAgoMS - durationMS,
            numAttackHits = numAttackHits
        }

        table.insert(attacks, attackInfo)
    end

    table.sort(attacks, SortAttacks)

    --Cert requires that we show the display name if there's no way other way to get it from character name
    --But it's not the desire of design to show so much name so we only show the double name if we absolutely must
    local showBothPlayerNames = IsConsoleUI() and tonumber(GetSetting(SETTING_TYPE_UI, UI_SETTING_PRIMARY_PLAYER_NAME_GAMEPAD)) == PRIMARY_PLAYER_NAME_SETTING_PREFER_CHARACTER

    local prevAttackControl
    for i, attackInfo in ipairs(attacks) do
        local attackControl = self.attackPool:AcquireObject(i)
        local iconControl = attackControl:GetNamedChild("Icon")
        local attackTextControl = attackControl:GetNamedChild("AttackText")
        local attackNameControl = attackTextControl:GetNamedChild("AttackName")
        local damageControl = attackControl:GetNamedChild("Damage")
        local numAttackHitsContainer = attackControl:GetNamedChild("NumAttackHits")
        
        iconControl:SetTexture(attackInfo.attackIcon)
        attackNameControl:SetText(zo_strformat(SI_DEATH_RECAP_ATTACK_NAME, attackInfo.attackName))
        damageControl:SetText(zo_strformat(SI_NUMBER_FORMAT, ZO_CommaDelimitNumber(attackInfo.attackDamage)))
            
        iconControl:SetAlpha(startAlpha)
        attackControl:GetNamedChild("Text"):SetAlpha(startAlpha)

        if attackInfo.numAttackHits > 1 then
            local numAttackHitsCountLabel = numAttackHitsContainer:GetNamedChild("Count")
            local numAttackHitsHitIcon = numAttackHitsContainer:GetNamedChild("HitIcon")
            local numAttackHitsKillIcon = numAttackHitsContainer:GetNamedChild("KillIcon")
            numAttackHitsContainer:SetAlpha(startAlpha)
            numAttackHitsContainer:SetHidden(false)
            numAttackHitsCountLabel:SetText(attackInfo.numAttackHits)
            if attackInfo.wasKillingBlow then
                numAttackHitsHitIcon:SetHidden(true)
                numAttackHitsKillIcon:SetHidden(false)
                self.killingBlowIcon:SetHidden(true)
            else
                numAttackHitsHitIcon:SetHidden(false)
                numAttackHitsKillIcon:SetHidden(true)
            end
        else
            numAttackHitsContainer:SetHidden(true)
            if attackInfo.wasKillingBlow then
                self.killingBlowIcon:SetHidden(false)
                self.killingBlowIcon:SetAnchor(CENTER, attackControl, TOPLEFT, 32, 32)
            end
        end

        local attackerNameControl = attackTextControl:GetNamedChild("AttackerName")
        local frameControl
        if DoesKillingAttackHaveAttacker(attackInfo.index) then
            local attackerRawName, attackerChampionPoints, attackerLevel, attackerAvARank, isPlayer, isBoss, alliance, minionName, attackerDisplayName = GetKillingAttackerInfo(attackInfo.index)
            local battlegroundAlliance = GetKillingAttackerBattlegroundAlliance(attackInfo.index)

            local attackerNameLine
            if isPlayer then
                local nameToShow
                if showBothPlayerNames then
                    nameToShow = ZO_GetPrimaryPlayerNameWithSecondary(attackerDisplayName, attackerRawName)
                else
                    nameToShow = ZO_GetPrimaryPlayerName(attackerDisplayName, attackerRawName)
                end

                if battlegroundAlliance == BATTLEGROUND_ALLIANCE_NONE then
                    local coloredRankIconMarkup = GetColoredAvARankIconMarkup(attackerAvARank, alliance, 32)
                    if minionName == "" then
                        attackerNameLine = zo_strformat(SI_DEATH_RECAP_RANK_ATTACKER_NAME, coloredRankIconMarkup, attackerAvARank, nameToShow)
                    else
                        attackerNameLine = zo_strformat(SI_DEATH_RECAP_RANK_ATTACKER_NAME_MINION, coloredRankIconMarkup, attackerAvARank, nameToShow, minionName)
                    end
                else
                    local battlegroundAllianceIconMarkup = GetBattlegroundIconMarkup(battlegroundAlliance, 32)
                    if minionName == "" then
                        attackerNameLine = zo_strformat(SI_DEATH_RECAP_BATTLEGROUND_ALLIANCE_ATTACKER_NAME, battlegroundAllianceIconMarkup, nameToShow)
                    else
                        attackerNameLine = zo_strformat(SI_DEATH_RECAP_BATTLEGROUND_ALLIANCE_ATTACKER_NAME_MINION, battlegroundAllianceIconMarkup, nameToShow, minionName)
                    end
                end
            else
                if minionName == "" then
                    attackerNameLine = zo_strformat(SI_DEATH_RECAP_ATTACKER_NAME, attackerRawName)
                else
                    attackerNameLine = zo_strformat(SI_DEATH_RECAP_ATTACKER_NAME_MINION, attackerRawName, minionName)
                end
            end

            attackerNameControl:SetText(attackerNameLine)
            attackerNameControl:SetHidden(false) 

            attackNameControl:ClearAnchors()
            attackNameControl:SetAnchor(TOPLEFT, attackerNameControl, BOTTOMLEFT, 0, 2)
            attackNameControl:SetAnchor(TOPRIGHT, attackerNameControl, BOTTOMRIGHT, 0, 2)

            frameControl = isBoss and iconControl:GetNamedChild("BossBorder") or iconControl:GetNamedChild("Border")
            frameControl:SetHidden(false)
        else
            attackerNameControl:SetHidden(true)

            attackNameControl:ClearAnchors()
            attackNameControl:SetAnchor(TOPLEFT)
            attackNameControl:SetAnchor(TOPRIGHT)
            
            frameControl = iconControl:GetNamedChild("Border")
            frameControl:SetHidden(false)
        end

        if(prevAttackControl) then
            attackControl:SetAnchor(TOPLEFT, prevAttackControl, BOTTOMLEFT, 0, 10)
        else
            attackControl:SetAnchor(TOPLEFT, nil, TOPLEFT, 0, 0)
        end

        prevAttackControl = attackControl
    end
end

local function RandomlyTake(array)
    local index = zo_random(1, #array)
    local value = array[index]
    table.remove(array, index)
    return value
end

function DeathRecap:AddHint(text, prevHintControl)
    local hintIndex = #self.hintPool:GetActiveObjects() + 1
    local hintControl = self.hintPool:AcquireObject(hintIndex)

    hintControl:GetNamedChild("Text"):SetText(text)
            
    if(prevHintControl) then
        hintControl:SetAnchor(TOPLEFT, prevHintControl, BOTTOMLEFT, 0, 10)
    else
        hintControl:SetAnchor(TOPLEFT, nil, TOPLEFT, 0, 0)
    end

    return hintControl
end

function DeathRecap:SetupHints()
    self.hintPool:ReleaseAllObjects()
    self.hintTimeline:Stop()

    local startAlpha = self.animateOnShow and 0 or 1
    self.scrollControl:GetNamedChild("HintsContainerHints"):SetAlpha(startAlpha)

    local numHints = GetNumDeathRecapHints()

    if numHints == 0 then
        self:AddHint(GetString(SI_DEATH_RECAP_NO_HINTS))
    else
        local exclusiveHints = {}
        local alwaysShowHints = {}
        local normalHints = {}

        for i = 1, numHints do
            local hintText, hintImportance = GetDeathRecapHintInfo(i)
            if(hintImportance == DEATH_RECAP_HINT_IMPORTANCE_EXCLUSIVE) then
                table.insert(exclusiveHints, hintText)
            elseif(hintImportance == DEATH_RECAP_HINT_IMPORTANCE_ALWAYS_INCLUDE) then
                table.insert(alwaysShowHints, hintText)
            else
                table.insert(normalHints, hintText)
            end
        end

        local prevHintControl
        if(#exclusiveHints > 0) then
            local text = RandomlyTake(exclusiveHints)
            self:AddHint(text)
            return
        end

        local hintsAdded = 0
        local MAX_HINTS = 3
        while #alwaysShowHints > 0 and hintsAdded < MAX_HINTS do
            local text = RandomlyTake(alwaysShowHints)
            prevHintControl = self:AddHint(text, prevHintControl)
            hintsAdded = hintsAdded + 1
        end

        while #normalHints > 0 and hintsAdded < MAX_HINTS do
            local text = RandomlyTake(normalHints)
            prevHintControl = self:AddHint(text, prevHintControl)
            hintsAdded = hintsAdded + 1
        end        
    end
end

function DeathRecap:SetupTelvarStoneLoss()
    local telvarStonesLost = GetNumTelvarStonesLost()
    
    if telvarStonesLost > 0 then
        self.telvarStoneLossValueControl:SetText(zo_strformat(SI_DEATH_RECAP_TELVAR_STONE_LOSS_VALUE, telvarStonesLost))
        self.telvarStoneLossControl:SetAlpha(self.animateOnShow and 0 or 1)
    else
        self.telvarStoneLossControl:SetAlpha(0)
    end
end

function DeathRecap:SetupDeathRecap()
    self.isPlayerDead = IsUnitDead("player")
    local numAttacks = GetNumKillingAttacks()
    if numAttacks > 0 and IsUnitDead("player") then
        self:SetupAttacks()
        self:SetupHints()
        self:SetupTelvarStoneLoss()
        self:SetDeathRecapAvailable(true)
    else
        self:SetDeathRecapAvailable(false)
    end
end

local ATTACK_ROW_ANIMATION_OVERLAP_PERCENT = 0.5
local HINT_ANIMATION_DELAY_MS = 300

function DeathRecap:Animate()
    local delay = 0
    local lastRowDuration
    for attackRowIndex, attackControl in ipairs(self.attackPool:GetActiveObjects()) do
        local timeline = attackControl.timeline
        local isLastRow = (attackRowIndex == #self.attackPool:GetActiveObjects())
        local nestedTimeline = timeline:GetAnimationTimeline(1)
        local duration = nestedTimeline:GetDuration()
        timeline:SetAnimationTimelineOffset(nestedTimeline, delay)
        nestedTimeline.isKillingBlow = isLastRow
        timeline:PlayFromStart()
        delay = delay + duration * ATTACK_ROW_ANIMATION_OVERLAP_PERCENT

        if(isLastRow) then
            lastRowDuration = duration
        end
    end

    local nestedKBTimeline = self.killingBlowTimeline:GetAnimationTimeline(1)
    self.killingBlowTimeline:SetAnimationTimelineOffset(nestedKBTimeline, zo_max(0, delay - lastRowDuration))
    self.killingBlowTimeline:PlayFromStart()

    if GetNumTelvarStonesLost() > 0 then
        local nestedTelvarLossTimeline = self.telvarLossTimeline:GetAnimationTimeline(1)
        self.telvarLossTimeline:SetAnimationTimelineOffset(nestedTelvarLossTimeline, delay)
        self.telvarLossTimeline:PlayFromStart()
    end
    
    local nestedTimeline = self.hintTimeline:GetAnimationTimeline(1)    
    self.hintTimeline:SetAnimationTimelineOffset(nestedTimeline, delay + HINT_ANIMATION_DELAY_MS)
    self.hintTimeline:PlayFromStart()
end

--Events

function DeathRecap:OnPlayerAlive()
    self.isPlayerDead = false
    self:SetDeathRecapAvailable(false)
end

function DeathRecap:OnPlayerDead()
    self.isPlayerDead = true
    if not self.waitingToShowPrompt then
        self.waitingToShowPrompt = true
        EVENT_MANAGER:RegisterForUpdate("DeathRecapUpdate", DEATH_RECAP_DELAY, function()
            self.waitingToShowPrompt = false
            EVENT_MANAGER:UnregisterForUpdate("DeathRecapUpdate")
            self.animateOnShow = true
            self:SetupDeathRecap()
        end)
    end
end

function DeathRecap:OnUnitFramesCreated()
    self:RefreshUnitFrameVisibility()
end

function DeathRecap:ApplyStyle()
    self.scrollContainer:SetScrollIndicatorEnabled(IsInGamepadPreferredMode())
    ApplyTemplateToControl(self.control, ZO_GetPlatformTemplate("ZO_DeathRecap"))
    self.attackTemplate = ZO_GetPlatformTemplate("ZO_DeathRecapAttack")
    self.hintTemplate = ZO_GetPlatformTemplate("ZO_DeathRecapHint")
    self.telvarStoneLossTemplate = ZO_GetPlatformTemplate("ZO_DeathRecapTelvarStoneLoss")
    ApplyTemplateToControl(self.telvarStoneLossControl, ZO_GetPlatformTemplate("ZO_DeathRecapTelvarStoneLoss"))
    self.telvarStoneLossIconControl:SetTexture(ZO_Currency_GetPlatformCurrencyIcon(CURT_TELVAR_STONES))

    if self.isPlayerDead then
        self:SetupDeathRecap()
        if not self.control:IsHidden() then
            if IsInGamepadPreferredMode() then
                DIRECTIONAL_INPUT:Activate(self, self.control)
            else
                DIRECTIONAL_INPUT:Deactivate(self)
            end
        end
    end
end

function DeathRecap:UpdateDirectionalInput()
    if not self.control:IsHidden() then
        DIRECTIONAL_INPUT:Consume(ZO_DI_RIGHT_STICK) -- Consume input to block camera movement when in gamepad mode with the death recap screen up.
    end
end

function DeathRecap:OnEffectivelyShown()
    if IsInGamepadPreferredMode() then
        DIRECTIONAL_INPUT:Activate(self, self.control)
    end
end

function DeathRecap:OnEffectivelyHidden()
    DIRECTIONAL_INPUT:Deactivate(self)
end

--Global XML

function ZO_DeathRecap_OnInitialized(self)
    DEATH_RECAP = DeathRecap:New(self)
    DEATH_RECAP_TOGGLE = DeathRecapToggle:New()
end