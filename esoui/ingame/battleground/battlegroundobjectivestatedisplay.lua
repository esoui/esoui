--Layout

ZO_BattlegroundObjectiveStateLayout = ZO_InitializingObject:Subclass()

do
    local KEYBOARD_STYLE =
    {
        anchorPoint = TOPLEFT,
    }

    local GAMEPAD_STYLE =
    {
        anchorPoint = TOPRIGHT,
    }

    function ZO_BattlegroundObjectiveStateLayout:Initialize(control)
        self.control = control
        self.objectives = {}
        self.sortFunction = function(a, b)
            return a:GetSortOrder() < b:GetSortOrder()
        end
        ZO_PlatformStyle:New(function(style) self:ApplyStyle(style) end, KEYBOARD_STYLE, GAMEPAD_STYLE)
    end
end

function ZO_BattlegroundObjectiveStateLayout:ApplyStyle(style)
    self.anchorPoint = style.anchorPoint
    self:UpdateAnchors()
end

function ZO_BattlegroundObjectiveStateLayout:Add(objective)
    table.insert(self.objectives, objective)
    local objectiveControl = objective:GetControl()
    objectiveControl:SetParent(self.control)
    objectiveControl:SetHidden(false)
    self:UpdateAnchors()
end

function ZO_BattlegroundObjectiveStateLayout:UpdateAnchors()
    table.sort(self.objectives, self.sortFunction)

    local previousObjectiveControl
    local numTotal = #self.objectives
    for i = 1, numTotal do
        local objective
        if self.anchorPoint == TOPLEFT then
            objective = self.objectives[i]
        elseif self.anchorPoint == TOPRIGHT then
            --anchor them in reverse order from right to left so they stay in the same sorted order, but gather to the right
            objective = self.objectives[numTotal - i + 1]
        end
        local objectiveControl = objective:GetControl()
        objectiveControl:ClearAnchors()
        if previousObjectiveControl then
            if self.anchorPoint == TOPLEFT then
                objectiveControl:SetAnchor(TOPLEFT, previousObjectiveControl, TOPRIGHT, -20, 0)
            elseif self.anchorPoint == TOPRIGHT then
                objectiveControl:SetAnchor(TOPRIGHT, previousObjectiveControl, TOPLEFT, 0, 0)
            end
        else
            objectiveControl:SetAnchor(self.anchorPoint, self.control, self.anchorPoint, 0, 0)
        end
        previousObjectiveControl = objectiveControl
    end
end

function ZO_BattlegroundObjectiveStateLayout:Remove(objective)
    for i, searchObjective in ipairs(self.objectives) do
        if objective == searchObjective then
            table.remove(self.objectives, i, 1)
            self:UpdateAnchors()
            local objectiveControl = objective:GetControl()
            objectiveControl:SetHidden(true)
            break
        end
    end
end

--Indicator

ZO_BattlegroundObjectiveStateIndicator = ZO_InitializingObject:Subclass()

function ZO_BattlegroundObjectiveStateIndicator:Initialize(control, manager)   
    self.control = control
    self.pinTexture = control:GetNamedChild("Pin")
    self.auraPinTexture = self.control:GetNamedChild("Aura")

    self.manager = manager
end

function ZO_BattlegroundObjectiveStateIndicator:GetControl()
    return self.control
end

function ZO_BattlegroundObjectiveStateIndicator:GetSortOrder()
    return 1
end

function ZO_BattlegroundObjectiveStateIndicator:Setup(keepId, objectiveId, battlegroundContext)
    self.keepId = keepId
    self.objectiveId = objectiveId
    self.battlegroundContext = battlegroundContext
end

function ZO_BattlegroundObjectiveStateIndicator:GetObjectiveIds()
    return self.keepId, self.objectiveId, self.battlegroundContext
end

function ZO_BattlegroundObjectiveStateIndicator:IsThisObjective(keepId, objectiveId, battlegroundContext)
    return self.keepId == keepId and self.objectiveId == objectiveId and self.battlegroundContext == battlegroundContext
end

function ZO_BattlegroundObjectiveStateIndicator:MoveToLayout()
    local layout = self.manager:GetObjectiveStateLayout()
    if layout ~= self.containingLayout then
        self:RemoveFromContainingLayout()
        self.containingLayout = layout
        layout:Add(self)
    end
end

function ZO_BattlegroundObjectiveStateIndicator:RemoveFromContainingLayout()
    if self.containingLayout then
        self.containingLayout:Remove(self)
    end
    self.containingLayout = nil
end

function ZO_BattlegroundObjectiveStateIndicator:Reset()
    self:RemoveFromContainingLayout()
end

function ZO_BattlegroundObjectiveStateIndicator:RefreshPinTextures()
    local pinType = GetObjectivePinInfo(self:GetObjectiveIds())
    local auraPinType, r, g, b = GetObjectiveAuraPinInfo(self:GetObjectiveIds())

    local pinTexturePath = ZO_MapPin.GetStaticPinTexture(pinType)
    self.pinTexture:SetTexture(pinTexturePath)

    local auraPinTexturePath = ZO_MapPin.GetStaticPinTexture(auraPinType)
    if auraPinTexturePath then
        self.auraPinTexture:SetHidden(false)
        self.auraPinTexture:SetTexture(auraPinTexturePath)
        self.auraPinTexture:SetColor(r, g, b, 1)
    else
        self.auraPinTexture:SetHidden(true)
    end
end

function ZO_BattlegroundObjectiveStateIndicator:Update()
    self:RemoveFromContainingLayout()
    --It is possible that the objective is updated and removed in the same frame. In that case, when handling a normal update
    --all queries will fail because the object is already gone. So we check here to see that it still exists before adding it.
    --This would not protect against it updating, being removed, and being readded as a new objective all in one frame, so we assume
    --that won't happen.
    if DoesObjectiveExist(self:GetObjectiveIds()) then
        if self:ShouldShow() then
            self:RefreshPinTextures()
            self:MoveToLayout()
        end
    end
end

function ZO_BattlegroundObjectiveStateIndicator:ShouldShow()
    --Must be overridden. Returns true if this indicator should currently be shown.
    assert(false)
end

function ZO_BattlegroundObjectiveStateIndicator.Matches(keepId, objectiveId, battlegroundContext)
    --Must be overridden. Returns true if the passed in objective should have an indicator for this game mode.
    assert(false)
end

--Fake Indicator
--These are used to show objectives that do not yet exist, and are used on a gameType by gameType basis

ZO_FakeBattlegroundObjectiveIndicator = ZO_BattlegroundObjectiveStateIndicator:Subclass()

function ZO_FakeBattlegroundObjectiveIndicator:Initialize(id, manager)
    local parent = manager:GetIndicatorControlContainer()
    local control = CreateControlFromVirtual("$(parent)FakeIndicator", parent, "ZO_BattlegroundObjectiveStatePin", id)
    control:SetHidden(true)
    ZO_BattlegroundObjectiveStateIndicator.Initialize(self, control, manager)
end

function ZO_FakeBattlegroundObjectiveIndicator:Update()
    self:RemoveFromContainingLayout()
    self:RefreshPinTextures()
    self:MoveToLayout()
end

function ZO_FakeBattlegroundObjectiveIndicator:Setup(pinType)
    self.pinType = pinType
    self:Update()
end

do
    local FAKE_INDICATOR_COLOR = 0.5
    local FAKE_INDICATOR_ALPHA = 0.8
    function ZO_FakeBattlegroundObjectiveIndicator:RefreshPinTextures()
        local pinTexturePath = ZO_MapPin.GetStaticPinTexture(self.pinType)
        self.pinTexture:SetTexture(pinTexturePath)
        self.pinTexture:SetColor(FAKE_INDICATOR_COLOR, FAKE_INDICATOR_COLOR, FAKE_INDICATOR_COLOR, FAKE_INDICATOR_ALPHA)
        self.auraPinTexture:SetHidden(true)
    end
end

function ZO_FakeBattlegroundObjectiveIndicator:GetSortOrder()
    -- fake indicators are always shown on the right
    return 1000000000
end

function ZO_FakeBattlegroundObjectiveIndicator:ShouldShow()
    -- we are creating these specifically because we want to show them
    return true
end

function ZO_FakeBattlegroundObjectiveIndicator.Matches(keepId, objectiveId, battlegroundContext)
    -- fake indicators are never a real objective
    return false
end

--General Capture Area Indicator

ZO_CaptureAreaObjectiveStateIndicator = ZO_BattlegroundObjectiveStateIndicator:Subclass()

function ZO_CaptureAreaObjectiveStateIndicator:Setup(keepId, objectiveId, battlegroundContext)
    ZO_BattlegroundObjectiveStateIndicator.Setup(self, keepId, objectiveId, battlegroundContext)
    self:GetControl():RegisterForEvent(EVENT_CAPTURE_AREA_STATE_CHANGED, function(_, ...) self:OnCaptureAreaStateChanged(...) end)
    self:Update()
end

function ZO_CaptureAreaObjectiveStateIndicator:OnCaptureAreaStateChanged(keepId, objectiveId, battlegroundContext)
    if self:IsThisObjective(keepId, objectiveId, battlegroundContext) then
        self:Update()
    end
end

function ZO_CaptureAreaObjectiveStateIndicator:Reset()
    ZO_BattlegroundObjectiveStateIndicator.Reset(self)
    self:GetControl():UnregisterForEvent(EVENT_CAPTURE_AREA_STATE_CHANGED)
end

function ZO_CaptureAreaObjectiveStateIndicator:ShouldShow()
    return true
end

function ZO_CaptureAreaObjectiveStateIndicator.Matches(keepId, objectiveId, battlegroundContext)
    return GetObjectiveType(keepId, objectiveId, battlegroundContext) == OBJECTIVE_CAPTURE_AREA
end

--King of the Hill Indicator

ZO_KotHObjectiveStateIndicator = ZO_CaptureAreaObjectiveStateIndicator:Subclass()

function ZO_KotHObjectiveStateIndicator:Initialize(id, manager)
    local parent = manager:GetIndicatorControlContainer()
    local control = CreateControlFromVirtual("$(parent)KotH", parent, "ZO_BattlegroundObjectiveStatePin", id)
    control:SetHidden(true)
    ZO_CaptureAreaObjectiveStateIndicator.Initialize(self, control, manager)
end

--Crazy King Indicator

ZO_CrazyKingObjectiveStateIndicator = ZO_CaptureAreaObjectiveStateIndicator:Subclass()

function ZO_CrazyKingObjectiveStateIndicator:Initialize(id, manager)
    local parent = manager:GetIndicatorControlContainer()
    local control = CreateControlFromVirtual("$(parent)CrazyKing", parent, "ZO_BattlegroundObjectiveStatePin", id)
    control:SetHidden(true)
    ZO_CaptureAreaObjectiveStateIndicator.Initialize(self, control, manager)
end

function ZO_CrazyKingObjectiveStateIndicator:GetSortOrder()
    return GetObjectiveVirtualId(self:GetObjectiveIds())
end

function ZO_CrazyKingObjectiveStateIndicator:ShouldShow()
    return IsObjectiveObjectVisible(self:GetObjectiveIds())
end

--Domination Indicator

ZO_DominationObjectiveStateIndicator = ZO_CaptureAreaObjectiveStateIndicator:Subclass()

function ZO_DominationObjectiveStateIndicator:GetSortOrder()
    return self.designation
end

function ZO_DominationObjectiveStateIndicator:Initialize(id, manager)
    local parent = manager:GetIndicatorControlContainer()
    local control = CreateControlFromVirtual("$(parent)Domination", parent, "ZO_BattlegroundObjectiveStatePin", id)
    control:SetHidden(true)
    ZO_CaptureAreaObjectiveStateIndicator.Initialize(self, control, manager)
end

function ZO_DominationObjectiveStateIndicator:Setup(keepId, objectiveId, battlegroundContext)
    self.designation = GetObjectiveDesignation(keepId, objectiveId, battlegroundContext)
    ZO_CaptureAreaObjectiveStateIndicator.Setup(self, keepId, objectiveId, battlegroundContext)
end

--CTF Indicator

ZO_CTFObjectiveStateIndicator = ZO_BattlegroundObjectiveStateIndicator:Subclass()

function ZO_CTFObjectiveStateIndicator:GetSortOrder()
    return self.pinType
end

function ZO_CTFObjectiveStateIndicator:Initialize(id, manager)
    local parent = manager:GetIndicatorControlContainer()
    local control = CreateControlFromVirtual("$(parent)CTF", parent, "ZO_BattlegroundObjectiveStatePin", id)
    control:SetHidden(true)
    ZO_BattlegroundObjectiveStateIndicator.Initialize(self, control, manager)
end

function ZO_CTFObjectiveStateIndicator:Setup(keepId, objectiveId, battlegroundContext)
    ZO_BattlegroundObjectiveStateIndicator.Setup(self, keepId, objectiveId, battlegroundContext)
    self.pinType = GetObjectivePinInfo(keepId, objectiveId, battlegroundContext)
    self:GetControl():RegisterForEvent(EVENT_CAPTURE_FLAG_STATE_CHANGED, function(_, ...) self:OnCaptureFlagStateChanged(...) end)
    self:Update()
end

function ZO_CTFObjectiveStateIndicator:OnCaptureFlagStateChanged(keepId, objectiveId, battlegroundContext)
    if self:IsThisObjective(keepId, objectiveId, battlegroundContext) then
        self:Update()
    end
end

function ZO_CTFObjectiveStateIndicator:Reset()
    ZO_BattlegroundObjectiveStateIndicator.Reset(self)
    self:GetControl():UnregisterForEvent(EVENT_CAPTURE_FLAG_STATE_CHANGED)
end

function ZO_CTFObjectiveStateIndicator:ShouldShow()
    return true
end

function ZO_CTFObjectiveStateIndicator.Matches(keepId, objectiveId, battlegroundContext)
    return GetObjectiveType(keepId, objectiveId, battlegroundContext) == OBJECTIVE_FLAG_CAPTURE
end

--Murderball

ZO_MurderballObjectiveStateIndicator = ZO_BattlegroundObjectiveStateIndicator:Subclass()

function ZO_MurderballObjectiveStateIndicator:Initialize(id, manager)
    local parent = manager:GetIndicatorControlContainer()
    local control = CreateControlFromVirtual("$(parent)Murderball", parent, "ZO_BattlegroundObjectiveStatePin", id)
    control:SetHidden(true)
    ZO_BattlegroundObjectiveStateIndicator.Initialize(self, control, manager)
end

function ZO_MurderballObjectiveStateIndicator:Setup(keepId, objectiveId, battlegroundContext)
    ZO_BattlegroundObjectiveStateIndicator.Setup(self, keepId, objectiveId, battlegroundContext)
    self:GetControl():RegisterForEvent(EVENT_MURDERBALL_STATE_CHANGED, function(_, ...) self:OnMurderballStateChanged(...) end)
    self:Update()
end

function ZO_MurderballObjectiveStateIndicator:OnMurderballStateChanged(keepId, objectiveId, battlegroundContext)
    if self:IsThisObjective(keepId, objectiveId, battlegroundContext) then
        self:Update()
    end
end

function ZO_MurderballObjectiveStateIndicator:Reset()
    ZO_BattlegroundObjectiveStateIndicator.Reset(self)
    self:GetControl():UnregisterForEvent(EVENT_MURDERBALL_STATE_CHANGED)
end

function ZO_MurderballObjectiveStateIndicator:ShouldShow()
    return true
end

function ZO_MurderballObjectiveStateIndicator.Matches(keepId, objectiveId, battlegroundContext)
    return GetObjectiveType(keepId, objectiveId, battlegroundContext) == OBJECTIVE_BALL
end

--Manager

ZO_BattlegroundObjectiveStateIndicatorManager = ZO_InitializingObject:Subclass()

function ZO_BattlegroundObjectiveStateIndicatorManager:Initialize(scoreHud)
    self.gameType = BATTLEGROUND_GAME_TYPE_NONE
    self.indicatorPoolsByGameType = {}
    self.fakeindicatorPoolsByGameType = {}
    self.scoreHud = scoreHud
end

function ZO_BattlegroundObjectiveStateIndicatorManager:GetIndicatorControlContainer()
    return self.scoreHud:GetControl()
end

function ZO_BattlegroundObjectiveStateIndicatorManager:OnBattlegroundGameTypeChanged(newGameType)
    self:ResetIndicators()
    self.gameType = newGameType
    self:BuildIndicators()
end

function ZO_BattlegroundObjectiveStateIndicatorManager:OnObjectivesUpdated()
    self:ResetIndicators()
    self:BuildIndicators()
end

function ZO_BattlegroundObjectiveStateIndicatorManager:GetObjectiveStateLayout()
    return self.scoreHud:GetObjectiveStateLayout()
end

do
    local INDICATOR_CLASS_BY_GAME_TYPE =
    {
        [BATTLEGROUND_GAME_TYPE_CAPTURE_THE_FLAG] = ZO_CTFObjectiveStateIndicator,
        [BATTLEGROUND_GAME_TYPE_KING_OF_THE_HILL] = ZO_KotHObjectiveStateIndicator,
        [BATTLEGROUND_GAME_TYPE_DOMINATION] = ZO_DominationObjectiveStateIndicator,
        [BATTLEGROUND_GAME_TYPE_CRAZY_KING] = ZO_CrazyKingObjectiveStateIndicator,
        [BATTLEGROUND_GAME_TYPE_MURDERBALL] = ZO_MurderballObjectiveStateIndicator,
    }

    function ZO_BattlegroundObjectiveStateIndicatorManager:GetIndicatorClassForGameType(gameType)
        return INDICATOR_CLASS_BY_GAME_TYPE[gameType]
    end

    local FAKE_INDICATOR_CLASS_BY_GAME_TYPE =
    {
        [BATTLEGROUND_GAME_TYPE_CRAZY_KING] = ZO_FakeBattlegroundObjectiveIndicator,
    }

    function ZO_BattlegroundObjectiveStateIndicatorManager:GetFakeIndicatorClassForGameType(gameType)
        return FAKE_INDICATOR_CLASS_BY_GAME_TYPE[gameType]
    end

    local FAKE_INDICATOR_PIN_TYPES_BY_GAME_TYPE =
    {
        [BATTLEGROUND_GAME_TYPE_CRAZY_KING] = MAP_PIN_TYPE_BGPIN_MOBILE_CAPTURE_AREA_NEUTRAL,
    }

    function ZO_BattlegroundObjectiveStateIndicatorManager:GetFakeIndicatorPinTypeForGameType(gameType)
        return FAKE_INDICATOR_PIN_TYPES_BY_GAME_TYPE[gameType]
    end

    local FAKE_INDICATOR_EVENT_BY_GAME_TYPE =
    {
        [BATTLEGROUND_GAME_TYPE_CRAZY_KING] = EVENT_CAPTURE_AREA_STATE_CHANGED,
    }

    function ZO_BattlegroundObjectiveStateIndicatorManager:GetFakeIndicatorEventForGameType(gameType)
        return FAKE_INDICATOR_EVENT_BY_GAME_TYPE[gameType]
    end
end

function ZO_BattlegroundObjectiveStateIndicatorManager:GetIndicatorPoolForGameType(gameType)
    local pool = self.indicatorPoolsByGameType[gameType]
    if not pool then
        local indicatorClass = self:GetIndicatorClassForGameType(gameType)
        local function Factory(objectPool)
            return indicatorClass:New(objectPool:GetNextControlId(), self)
        end
        pool = ZO_ObjectPool:New(Factory, ZO_ObjectPool_DefaultResetObject)
        self.indicatorPoolsByGameType[gameType] = pool
    end
    return pool
end

function ZO_BattlegroundObjectiveStateIndicatorManager:GetFakeIndicatorPoolForGameType(gameType)
    local pool = self.fakeindicatorPoolsByGameType[gameType]
    if not pool then
        local fakeIndicatorClass = self:GetFakeIndicatorClassForGameType(gameType)
        if fakeIndicatorClass then
            local function Factory(objectPool)
                return fakeIndicatorClass:New(objectPool:GetNextControlId(), self)
            end
            pool = ZO_ObjectPool:New(Factory, ZO_ObjectPool_DefaultResetObject)
            self.fakeindicatorPoolsByGameType[gameType] = pool
        end
    end
    return pool
end

function ZO_BattlegroundObjectiveStateIndicatorManager:ResetIndicators()
    if self.gameType ~= BATTLEGROUND_GAME_TYPE_NONE then
        local indicatorPool = self:GetIndicatorPoolForGameType(self.gameType)
        indicatorPool:ReleaseAllObjects()
        local fakeIndicatorPool = self:GetFakeIndicatorPoolForGameType(self.gameType)
        if fakeIndicatorPool then
            fakeIndicatorPool:ReleaseAllObjects()
            EVENT_MANAGER:UnregisterForEvent("battlegroundObjectiveStateDisplay", self:GetFakeIndicatorEventForGameType(self.gameType))
        end
    end
end

function ZO_BattlegroundObjectiveStateIndicatorManager:BuildIndicators()
    if self.gameType ~= BATTLEGROUND_GAME_TYPE_NONE then
        local indicatorClass = self:GetIndicatorClassForGameType(self.gameType)
        if indicatorClass then
            local indicatorPool = self:GetIndicatorPoolForGameType(self.gameType)
            for i = 1, GetNumObjectives() do
                local keepId, objectiveId, battlegroundContext = GetObjectiveIdsForIndex(i)
                if IsBattlegroundObjective(keepId, objectiveId, battlegroundContext) then
                    if indicatorClass.Matches(keepId, objectiveId, battlegroundContext) then
                        local indicator = indicatorPool:AcquireObject()
                        indicator:Setup(keepId, objectiveId, battlegroundContext)
                    end
                end
            end
        end

        self:UpdateFakeIndicators()
    end
end

function ZO_BattlegroundObjectiveStateIndicatorManager:UpdateFakeIndicators()
    local fakeIndicatorPool = self:GetFakeIndicatorPoolForGameType(self.gameType)
    if fakeIndicatorPool then
        fakeIndicatorPool:ReleaseAllObjects()

        local battlegroundState = GetCurrentBattlegroundState()
        if battlegroundState == BATTLEGROUND_STATE_RUNNING then
            local indicatorPool = self:GetIndicatorPoolForGameType(self.gameType)
            local activeObjects = indicatorPool:GetActiveObjects()
            local numShown = 0
            for i, indicator in pairs(activeObjects) do
                if indicator:ShouldShow() then
                    numShown = numShown + 1
                end 
            end

            local maxSequencedObjectives = GetCurrentBattlegroundRoundMaxActiveSequencedObjectives()
            if maxSequencedObjectives > 0 and numShown < maxSequencedObjectives then
                EVENT_MANAGER:RegisterForEvent("battlegroundObjectiveStateDisplay", self:GetFakeIndicatorEventForGameType(self.gameType), function(eventId, ...) self:UpdateFakeIndicators(...) end)
                local missingObjectives = maxSequencedObjectives - numShown
                local pinType = self:GetFakeIndicatorPinTypeForGameType(self.gameType)
                for i = 1, missingObjectives do
                    local fakeIndicator = fakeIndicatorPool:AcquireObject()
                    fakeIndicator:Setup(pinType)
                end
            end
        end
    end
end
