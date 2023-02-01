-- respec shrine interaction info
ZO_SKILL_RESPEC_INTERACT_INFO =
{
    type = "Skill Respec Shrine",
    OnInteractSwitch = function()
        internalassert(false, "OnInteractSwitch is being called.")
        SCENE_MANAGER:ShowBaseScene()
    end,
    interactTypes = { INTERACTION_SKILL_RESPEC },
}

ZO_SceneManager_Leader.AddBypassHideSceneConfirmationReason("SKILLS_PLAYER_DEACTIVATED")

-- Skill XP bars
do
    local function OnXpBarLevelChanged(xpBar, level)
        xpBar:GetControl():GetParent().rank:SetText(level)
    end

    function ZO_Skills_SkillLineInfo_Shared_OnInitialized(control)
        control.name = control:GetNamedChild("Name")
        control.rank = control:GetNamedChild("Rank")
        control.xpBar = ZO_WrappingStatusBar:New(control:GetNamedChild("XPBar"), OnXpBarLevelChanged)
        local statusBarControl = control.xpBar:GetControl()
        ZO_StatusBar_SetGradientColor(statusBarControl, ZO_SKILL_XP_BAR_GRADIENT_COLORS)
        control.glowContainer = statusBarControl:GetNamedChild("GlowContainer")
    end
end

function ZO_SkillInfoXPBar_SetValue(xpBar, level, lastRankXP, nextRankXP, currentXP, noWrap, animateInstantly)
    local maxed = nextRankXP == 0 or nextRankXP == lastRankXP

    if maxed then
        xpBar:SetValue(level, 1, 1, noWrap, animateInstantly)
    else
        xpBar:SetValue(level, currentXP - lastRankXP, nextRankXP - lastRankXP, noWrap, animateInstantly)
    end
end

function ZO_Skills_GetSkillInfoHeaderNarrationText(skillInfoHeaderControl)
    if skillInfoHeaderControl.narrationTextFunction then
        return skillInfoHeaderControl.narrationTextFunction()
    end
end

function ZO_Skills_TieSkillInfoHeaderToCraftingSkill(skillInfoHeaderControl, craftingSkillType)
    local name = skillInfoHeaderControl.name
    local xpBar = skillInfoHeaderControl.xpBar
    local rank = skillInfoHeaderControl.rank
    local glowContainer = skillInfoHeaderControl.glowContainer

    skillInfoHeaderControl.increaseAnimation = skillInfoHeaderControl.increaseAnimation or ANIMATION_MANAGER:CreateTimelineFromVirtual("SkillIncreasedBarAnimation", glowContainer)

    skillInfoHeaderControl.narrationTextFunction = function()
        local narrations = {}
        local skillLineData = xpBar:GetControl().skillLineData
        if skillLineData then
            table.insert(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(skillLineData:GetFormattedName()))
        end
        ZO_CombineNumericallyIndexedTables(narrations, xpBar:GetNarrationText())
        return narrations
    end

    local hadUpdateWhileCrafting = false
    skillInfoHeaderControl.updateSkillInfoHeaderCallback = function(skillLineData)
        local craftingSkillLineData = SKILLS_DATA_MANAGER:GetCraftingSkillLineData(craftingSkillType)

        if not skillLineData or skillLineData == craftingSkillLineData then
            if ZO_CraftingUtils_IsPerformingCraftProcess() then
                hadUpdateWhileCrafting = true
            else
                if craftingSkillLineData == nil then
                    local isSettingTemplate = IsSettingTemplate() and "true" or "false"
                    local numTradeSkillLinesInC = GetNumSkillLines(SKILL_TYPE_TRADESKILL)
                    local message = string.format("CraftingType yielded no skill line data. Is Setting Template - %s; Num Trade Skill Lines in C - %d", isSettingTemplate, numTradeSkillLinesInC)
                    internalassert(false, message)
                end

                local lineRank = craftingSkillLineData:GetCurrentRank()
                local lastXP, nextXP, currentXP = craftingSkillLineData:GetRankXPValues()

                name:SetText(craftingSkillLineData:GetFormattedName())
                local lastRank = rank.lineRank
                rank.lineRank = lineRank

                xpBar:GetControl().skillLineData = craftingSkillLineData

                if skillLineData or hadUpdateWhileCrafting then
                    skillInfoHeaderControl.increaseAnimation:PlayFromStart()
                end

                ZO_SkillInfoXPBar_SetValue(xpBar, lineRank, lastXP, nextXP, currentXP, skillLineData == nil and not hadUpdateWhileCrafting)
            end

            if SkillTooltip:GetOwner() == xpBar:GetControl() then
                ZO_SkillInfoXPBar_OnMouseEnter(xpBar:GetControl())
            end
        end
        SKILLS_DATA_MANAGER:UnregisterCallback("FullSystemUpdated", skillInfoHeaderControl.updateSkillInfoHeaderCallback)
    end

    SKILLS_DATA_MANAGER:RegisterCallback("SkillLineUpdated", skillInfoHeaderControl.updateSkillInfoHeaderCallback)

    skillInfoHeaderControl.craftingAnimationsStoppedCallback = function() 
        if hadUpdateWhileCrafting then
            skillInfoHeaderControl.updateSkillInfoHeaderCallback()
            hadUpdateWhileCrafting = false
        end
    end

    CALLBACK_MANAGER:RegisterCallback("CraftingAnimationsStopped", skillInfoHeaderControl.craftingAnimationsStoppedCallback)

    if SKILLS_DATA_MANAGER:IsDataReady() then
        skillInfoHeaderControl.updateSkillInfoHeaderCallback()
    else
        SKILLS_DATA_MANAGER:RegisterCallback("FullSystemUpdated", skillInfoHeaderControl.updateSkillInfoHeaderCallback)
    end
end

function ZO_Skills_UntieSkillInfoHeaderToCraftingSkill(skillInfoHeaderControl)
    SKILLS_DATA_MANAGER:UnregisterCallback("SkillLineUpdated", skillInfoHeaderControl.updateSkillInfoHeaderCallback)
    SKILLS_DATA_MANAGER:UnregisterCallback("FullSystemUpdated", skillInfoHeaderControl.updateSkillInfoHeaderCallback)
    CALLBACK_MANAGER:UnregisterCallback("CraftingAnimationsStopped", skillInfoHeaderControl.craftingAnimationsStoppedCallback)
    skillInfoHeaderControl.craftingAnimationsStoppedCallback = nil
    skillInfoHeaderControl.narrationTextFunction = nil
end

-- Multiple Crafting Skills Xp Bar

ZO_MultipleCraftingSkillsXpBar = ZO_InitializingObject:Subclass()

do
    local function OnXpBarLevelChanged(xpBar, level)
        xpBar:GetControl():GetParent().owner.rankLabel:SetText(level)
    end

    function ZO_MultipleCraftingSkillsXpBar:Initialize(control)
        control.owner = self
        self.control = control
        self.nameLabel = control:GetNamedChild("Name")
        self.rankLabel = control:GetNamedChild("Rank")
        self.xpBar = ZO_WrappingStatusBar:New(control:GetNamedChild("XPBar"), OnXpBarLevelChanged)
        self.statusBarControl = self.xpBar:GetControl()
        self.glowContainer = self.statusBarControl:GetNamedChild("GlowContainer")
        self.increaseAnimation = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_MultipleCraftingSkills_XpGainAnimation", self.control)
        ZO_StatusBar_SetGradientColor(self.statusBarControl, ZO_SKILL_XP_BAR_GRADIENT_COLORS)

        -- Map of registered skillLineIds to their corresponding skillLineData state.
        -- Populated by SetCraftingTypes and updated as queued skill changes are displayed.
        self.skillLineStates = {}

        -- Numerically indexed table used by the FIFO queue that contains the skillLineId of each updated skill line that is awaiting display.
        -- The queue maintains a uniqueness constraint such that updates to queued skill lines evict the existing queue entry and enqueue at the back of the queue.
        self.queuedSkillLineIds = {}

        self.OnSkillLineUpdateHandler = function(...)
            self:OnSkillLineUpdate(...)
        end

        self.OnUpdateHandler = function(...)
            self:OnUpdate(...)
        end
    end
end

function ZO_MultipleCraftingSkillsXpBar:CanShowNextQueuedSkillLine()
    if self.isAnimationPlaying then
        return false
    end

    if ZO_CraftingUtils_IsPerformingCraftProcess() then
        return false
    end

    return true
end

function ZO_MultipleCraftingSkillsXpBar:ClearCraftingTypes()
    SKILLS_DATA_MANAGER:UnregisterCallback("SkillLineUpdated", self.OnSkillLineUpdateHandler)

    if self.OnFullSkillUpdateHandler then
        SKILLS_DATA_MANAGER:UnregisterCallback("FullSystemUpdated", self.OnFullSkillUpdateHandler)
        self.OnFullSkillUpdateHandler = nil
    end

    ZO_ClearTable(self.skillLineStates)
    ZO_ClearNumericallyIndexedTable(self.queuedSkillLineIds)
end

function ZO_MultipleCraftingSkillsXpBar:InternalSetCraftingTypeSkillLineState(skillLineData)
    local data = {}
    data.id = skillLineData:GetId()
    data.lineRank = skillLineData:GetCurrentRank()
    data.lastXP, data.nextXP, data.currentXP = skillLineData:GetRankXPValues()
    self.skillLineStates[data.id] = data
end

function ZO_MultipleCraftingSkillsXpBar:SetCraftingTypes(craftingTypes)
    internalassert(type(craftingTypes) == "table", "craftingTypes must be a numerically indexed table of craftingType values.")

    self:ClearCraftingTypes()

    if SKILLS_DATA_MANAGER:IsDataReady() then
        for _, craftingType in ipairs(craftingTypes) do
            local skillLineData = SKILLS_DATA_MANAGER:GetCraftingSkillLineData(craftingType)
            if skillLineData then
                self:InternalSetCraftingTypeSkillLineState(skillLineData)
            end
        end

        SKILLS_DATA_MANAGER:RegisterCallback("SkillLineUpdated", self.OnSkillLineUpdateHandler)
    else
        if self.OnFullSkillUpdateHandler then
            SKILLS_DATA_MANAGER:UnregisterCallback("FullSystemUpdated", self.OnFullSkillUpdateHandler)
        end

        self.OnFullSkillUpdateHandler = function()
            self:SetCraftingTypes(craftingTypes)
        end

        SKILLS_DATA_MANAGER:RegisterCallback("FullSystemUpdated", self.OnFullSkillUpdateHandler)
    end
end

function ZO_MultipleCraftingSkillsXpBar:DequeueSkillLineId(skillLineId, suppressQueueUpdate)
    local dequeuedSkillLineId
    if not skillLineId then
        -- Dequeue the next skillLineId in the queue by default.
        dequeuedSkillLineId = table.remove(self.queuedSkillLineIds, 1)
    else
        -- Dequeue the specified skillLineId in the queue if it exists.
        for queueIndex, queuedSkillLineId in ipairs(self.queuedSkillLineIds) do
            if queuedSkillLineId == skillLineId then
                dequeuedSkillLineId = skillLineId
                table.remove(self.queuedSkillLineIds, queueIndex)
                break
            end
        end
    end

    if dequeuedSkillLineId and not suppressQueueUpdate then
        self:OnQueueChanged()
    end

    return dequeuedSkillLineId
end

function ZO_MultipleCraftingSkillsXpBar:EnqueueSkillLineId(skillLineId)
    local SUPPRESS_QUEUE_UPDATE = true
    self:DequeueSkillLineId(skillLineId, SUPPRESS_QUEUE_UPDATE)
    table.insert(self.queuedSkillLineIds, skillLineId)

    self:OnQueueChanged()
end

function ZO_MultipleCraftingSkillsXpBar:OnSkillLineUpdate(skillLineData)
    if not skillLineData then
        return
    end

    local skillLineId = skillLineData:GetId()
    if not self.skillLineStates[skillLineId] then
        return
    end

    self:EnqueueSkillLineId(skillLineId)
end

function ZO_MultipleCraftingSkillsXpBar:OnPlayAnimation()
    self.isAnimationPlaying = true
end

function ZO_MultipleCraftingSkillsXpBar:OnStopAnimation()
    self.isAnimationPlaying = nil
end

function ZO_MultipleCraftingSkillsXpBar:OnQueueChanged()
    if #self.queuedSkillLineIds == 0 then
        self.control:SetHandler("OnUpdate", nil)
    else
        self.control:SetHandler("OnUpdate", self.OnUpdateHandler)
    end
end

function ZO_MultipleCraftingSkillsXpBar:OnUpdate()
    if not self:CanShowNextQueuedSkillLine() then
        return
    end

    local skillLineId = self:DequeueSkillLineId()
    if not skillLineId then
        return
    end

    local skillLineData = SKILLS_DATA_MANAGER:GetSkillLineDataById(skillLineId)
    -- Order matters:
    local previousSkillLineState = self.skillLineStates[skillLineId]
    self:InternalSetCraftingTypeSkillLineState(skillLineData)

    -- Initialize the experience bar to the previous state of the skill line.
    self.rankLabel.lineRank = previousSkillLineState.lineRank
    local DO_NOT_WRAP = true
    local ANIMATE_INSTANTLY = true
    ZO_SkillInfoXPBar_SetValue(self.xpBar, previousSkillLineState.lineRank, previousSkillLineState.lastXP, previousSkillLineState.nextXP, previousSkillLineState.currentXP, DO_NOT_WRAP, ANIMATE_INSTANTLY)

    -- Prepare the values for the new skill line state.
    self.nameLabel:SetText(skillLineData:GetFormattedName())
    self.statusBarControl.skillLineData = skillLineData
    local lineRank = skillLineData:GetCurrentRank()
    local lastXP, nextXP, currentXP = skillLineData:GetRankXPValues()
    local doNotWrapProgressBar = currentXP < previousSkillLineState.nextXP

    self.ShowQueuedXpBarUpdate = function()
        self.rankLabel.lineRank = lineRank
        ZO_SkillInfoXPBar_SetValue(self.xpBar, lineRank, lastXP, nextXP, currentXP, doNotWrapProgressBar)
    end

    self.increaseAnimation:PlayFromStart()
    if SkillTooltip:GetOwner() == self.statusBarControl then
        ZO_SkillInfoXPBar_OnMouseEnter(self.statusBarControl)
    end
end

function ZO_MultipleCraftingSkillsXpBar_OnInitialized(control)
    ZO_MultipleCraftingSkillsXpBar:New(control)
end

function ZO_MultipleCraftingSkillsXpBar_TieSkillInfoHeaderToCraftingTypes(control, craftingTypes)
    control.owner:SetCraftingTypes(craftingTypes)
end

function ZO_MultipleCraftingSkillsXpBar_UntieSkillInfoHeaderToCraftingTypes(control)
    control.owner:ClearCraftingTypes()
end