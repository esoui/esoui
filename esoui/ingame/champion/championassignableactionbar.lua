
ZO_CHAMPION_FOCUSED_SKILL_STATUS_INDICATOR = "EsoUI/Art/Champion/Gamepad/gp_quickmenu_equipped_selected.dds"
ZO_CHAMPION_EQUIPPED_STATUS_INDICATOR = "EsoUI/Art/Champion/Gamepad/gp_quickmenu_equipped.dds"

ZO_CHAMPION_ACTION_BAR_INITIAL_SLOT_OFFSET_X = 44
ZO_CHAMPION_ACTION_BAR_DISCIPLINE_PADDING_X = 58
ZO_CHAMPION_ACTION_BAR_SLOT_PADDING_X = 13

--[[
    The ChampionAssignableAction bar is an action bar, like the
    KeyboardAssignableActionBar in the skills UI, but specifically for slotting
    passives within the champion system. It uses the same underlying ActionSlot
    and Hotbar mechanisms, but it can only slot champion skills. It does _not_
    use the ActionSlotAssignmentManager; the champion system uses its own
    respec system instead of the skills respec infrastructure.
]]--
ZO_ChampionAssignableActionBar = ZO_InitializingCallbackObject:Subclass()

function ZO_ChampionAssignableActionBar:Initialize(control)
    self.control = control
    self.hotbarCategory = HOTBAR_CATEGORY_CHAMPION -- the champion system only shows one hotbar
    self.gamepadEditor = ZO_ChampionAssignableActionBar_GamepadEditor:New(self)

    self.slots = {}
    self.firstSlotPerDiscipline = {}
    self.disciplineCallouts = 
    {
        [CHAMPION_DISCIPLINE_TYPE_COMBAT] = self.control:GetNamedChild("CombatHighlight"),
        [CHAMPION_DISCIPLINE_TYPE_CONDITIONING] = self.control:GetNamedChild("ConditioningHighlight"),
        [CHAMPION_DISCIPLINE_TYPE_WORLD] = self.control:GetNamedChild("WorldHighlight"),
    }
    self.currentDisciplineCallout = nil
    local lastSlotControl, lastSlot = nil, nil
    local startSlotIndex, endSlotIndex = GetAssignableChampionBarStartAndEndSlots()
    for actionSlotIndex = startSlotIndex, endSlotIndex do
        local slotControl = CreateControlFromVirtual("$(parent)Slot", self.control, "ZO_ChampionAssignableActionSlot", actionSlotIndex)
        local slot = ZO_ChampionAssignableActionBarSlot:New(slotControl, self, actionSlotIndex)
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

    local function OnHotbarSlotUpdated(_, actionSlotIndex, hotbarCategory)
        if hotbarCategory == self.hotbarCategory then
            local actionSlot = self.slots[actionSlotIndex]
            if actionSlot then
                actionSlot:Reset()
            end
        end
    end
    self.control:RegisterForEvent(EVENT_HOTBAR_SLOT_UPDATED, OnHotbarSlotUpdated)

    local function ResetAllHotbars()
        self:ResetAllSlots()
    end
    self.control:RegisterForEvent(EVENT_ACTION_SLOTS_ALL_HOTBARS_UPDATED, ResetAllHotbars)

    local function OnCursorPickup(_, cursorType, actionType, _, actionId)
        if cursorType == MOUSE_CONTENT_ACTION and actionType == ACTION_TYPE_CHAMPION_SKILL then
            local championSkillData = CHAMPION_DATA_MANAGER:GetChampionSkillData(actionId)
            if championSkillData then
                self:ShowDisciplineCallout(championSkillData:GetChampionDisciplineData():GetType())
                self:ShowDragAndDropCalloutsForChampionSkillData(championSkillData)
            end
        end
    end
    self.control:RegisterForEvent(EVENT_CURSOR_PICKUP, OnCursorPickup)

    local function OnCursorDropped(_, cursorType)
        if cursorType == MOUSE_CONTENT_ACTION then
            self:HideCurrentDisciplineCallout()
            self:HideDragAndDropCallouts()
        end
    end
    self.control:RegisterForEvent(EVENT_CURSOR_DROPPED, OnCursorDropped)

    local function OnPlayerActivated()
        self:HideDragAndDropCallouts()
    end
    self.control:RegisterForEvent(EVENT_PLAYER_ACTIVATED, OnPlayerActivated)

    local function UnslotRefundedSkills()
        for _, slot in ipairs(self.slots) do
            local slottedSkillData = slot:GetChampionSkillData()
            if slottedSkillData ~= nil and not slottedSkillData:WouldBePurchased() then
                slot:ClearSlot()
            end
        end
    end
    CHAMPION_DATA_MANAGER:RegisterCallback("AllPointsChanged", UnslotRefundedSkills)
    CHAMPION_DATA_MANAGER:RegisterCallback("ChampionSkillPendingPointsChanged", UnslotRefundedSkills)
end

function ZO_ChampionAssignableActionBar:GetHotbarCategory()
    return self.hotbarCategory
end

function ZO_ChampionAssignableActionBar:GetSlot(slotIndex)
    return self.slots[slotIndex]
end

function ZO_ChampionAssignableActionBar:GetNumSlots()
    return #self.slots
end

function ZO_ChampionAssignableActionBar:GetFirstSlotIndexForDiscipline(disciplineId)
    return self.firstSlotPerDiscipline[disciplineId]
end

function ZO_ChampionAssignableActionBar:ResetAllSlots()
    for _, slot in ipairs(self.slots) do
        slot:Reset()
    end
end

function ZO_ChampionAssignableActionBar:RefreshAllSlots()
    for _, slot in ipairs(self.slots) do
        slot:Refresh()
    end
end

function ZO_ChampionAssignableActionBar:HasUnsavedChanges()
    for _, slot in ipairs(self.slots) do
        if slot:HasUnsavedChanges() then
            return true
        end
    end
    return false
end

function ZO_ChampionAssignableActionBar:CollectUnsavedChanges()
    for _, slot in ipairs(self.slots) do
        slot:CollectUnsavedChanges()
    end
end

function ZO_ChampionAssignableActionBar:HideDragAndDropCallouts()
    for _, slot in ipairs(self.slots) do
        slot:HideDragAndDropCallout()
    end
end

function ZO_ChampionAssignableActionBar:ShowDragAndDropCalloutsForChampionSkillData(championSkillData)
    for _, slot in ipairs(self.slots) do
        slot:ShowDragAndDropCalloutForChampionSkillData(championSkillData)
    end
end

function ZO_ChampionAssignableActionBar:ShowSlotCalloutsByDisciplineType(disciplineType)
    for _, slot in ipairs(self.slots) do
        slot:ShowSlotCalloutByDisciplineType(disciplineType)
    end
end

function ZO_ChampionAssignableActionBar:ShowDisciplineCallout(disciplineType)
    if self.currentDisciplineCallout ~= self.disciplineCallouts[disciplineType] then
        self:HideCurrentDisciplineCallout()
        self.disciplineCallouts[disciplineType]:SetHidden(false)
        self.currentDisciplineCallout = self.disciplineCallouts[disciplineType]
    end
end

function ZO_ChampionAssignableActionBar:HideCurrentDisciplineCallout()
    if self.currentDisciplineCallout then
        self.currentDisciplineCallout:SetHidden(true)
        self.currentDisciplineCallout = nil
    end
end

function ZO_ChampionAssignableActionBar:FindSlotMatchingChampionSkill(championSkillData)
    for _, slot in ipairs(self.slots) do
        if slot:GetChampionSkillData() == championSkillData then
            return slot
        end
    end
end

function ZO_ChampionAssignableActionBar:GetGamepadEditor()
    return self.gamepadEditor
end

ZO_ChampionAssignableActionBarSlot = ZO_InitializingObject:Subclass()

function ZO_ChampionAssignableActionBarSlot:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_ChampionAssignableActionBarSlot:Initialize(control, assignableActionBar, actionSlotIndex)
    self.control = control
    self.bar = assignableActionBar
    self.slotIndex = actionSlotIndex
    self.isMousedOver = false

    self.icon = control:GetNamedChild("Icon")

    self.button = control:GetNamedChild("Button")
    self.button.owner = self

    self.starControl = control:GetNamedChild("Star")
    self.starVisuals = ZO_ChampionStarVisuals:New(self.starControl)

    self.dragAndDropCallout = control:GetNamedChild("DragAndDropCallout")
    self.textures = ZO_GetChampionBarDisciplineTextures(GetChampionDisciplineType(self:GetRequiredDisciplineId()))

    self.starControl:SetHandler("OnUpdate", function(_, timeSecs)
        self.starVisuals:Update(timeSecs)
    end)
end

function ZO_ChampionAssignableActionBarSlot:Reset()
    self.championSkillData = self:GetSavedChampionSkillData()
    self:Refresh()
end

function ZO_ChampionAssignableActionBarSlot:GetChampionSkillData()
    return self.championSkillData
end

function ZO_ChampionAssignableActionBarSlot:GetChampionSkillId()
    if self.championSkillData then
        return self.championSkillData:GetId()
    end
    return nil
end

function ZO_ChampionAssignableActionBarSlot:GetSavedChampionSkillData()
    if GetSlotType(self:GetSlotIndices()) == ACTION_TYPE_CHAMPION_SKILL then
        local championSkillId = GetSlotBoundId(self:GetSlotIndices())
        return CHAMPION_DATA_MANAGER:GetChampionSkillData(championSkillId)
    end
    return nil
end

function ZO_ChampionAssignableActionBarSlot:GetSlotIndices()
    return self.slotIndex, self.bar:GetHotbarCategory()
end

function ZO_ChampionAssignableActionBarSlot:GetRequiredDisciplineId()
    return GetRequiredChampionDisciplineIdForSlot(self:GetSlotIndices())
end

function ZO_ChampionAssignableActionBarSlot:ClearSlot()
    self.championSkillData = nil
    self:Refresh()
    self.bar:FireCallbacks("SlotChanged", self)
    return true
end

function ZO_ChampionAssignableActionBarSlot:GetExpectedSkillSlotResult(championSkillData)
    if not championSkillData:IsTypeSlottable() then 
        return CHAMPION_PURCHASE_CHAMPION_BAR_SKILL_NOT_SLOTTABLE
    end

    if not championSkillData:WouldBePurchased() then
        return CHAMPION_PURCHASE_CHAMPION_BAR_SKILL_NOT_PURCHASED
    end

    local requiredDisciplineId = self:GetRequiredDisciplineId()
    if requiredDisciplineId and requiredDisciplineId ~= championSkillData:GetChampionDisciplineData():GetId() then
        return CHAMPION_PURCHASE_CHAMPION_BAR_WRONG_DISCIPLINE
    end

    return CHAMPION_PURCHASE_SUCCESS
end

function ZO_ChampionAssignableActionBarSlot:CanSlotChampionSkillData(championSkillData)
    return self:GetExpectedSkillSlotResult(championSkillData) == CHAMPION_PURCHASE_SUCCESS
end

function ZO_ChampionAssignableActionBarSlot:AssignChampionSkillToSlot(championSkillData)
    if self.championSkillData ~= championSkillData and self:CanSlotChampionSkillData(championSkillData) then
        -- skills can only be slotted into a single slot at a time
        local oldSlot = self.bar:FindSlotMatchingChampionSkill(championSkillData)
        if oldSlot then
            oldSlot:ClearSlot()
        end

        self.championSkillData = championSkillData

        self:Refresh()
        self.bar:FireCallbacks("SlotChanged", self)
        return true
    end
    return false
end

function ZO_ChampionAssignableActionBarSlot:HasUnsavedChanges()
    return self:GetChampionSkillData() ~= self:GetSavedChampionSkillData()
end

function ZO_ChampionAssignableActionBarSlot:CollectUnsavedChanges()
    if self:HasUnsavedChanges() then
        AddHotbarSlotToChampionPurchaseRequest(self.slotIndex, self:GetChampionSkillId())
    end
end

function ZO_ChampionAssignableActionBarSlot:SelectSlottedStar()
    local data = self:GetChampionSkillData()
    local chosenConstellation = CHAMPION_PERKS:GetChosenConstellation()
    if chosenConstellation then
        local currentCluster = chosenConstellation:GetCurrentCluster()
        if currentCluster then
            local star = currentCluster:GetStarBySkillData(data) 
            chosenConstellation:SelectStar(star)
        end
    end
end

function ZO_ChampionAssignableActionBarSlot:OnMouseEnter()
    self.isMousedOver = true
    if not IsInGamepadPreferredMode() then
        self:SelectSlottedStar()
        self:ShowTooltip()
    end
end

function ZO_ChampionAssignableActionBarSlot:OnMouseExit()
    self.isMousedOver = false
    self:HideTooltip()
    local chosenConstellation = CHAMPION_PERKS:GetChosenConstellation()
    if not IsInGamepadPreferredMode() and chosenConstellation then
        chosenConstellation:SelectStar(nil)
    end
end

function ZO_ChampionAssignableActionBarSlot:Refresh()
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

    local selectedStar = CHAMPION_PERKS:GetSelectedStar()
    if GetCursorContentType() == MOUSE_CONTENT_EMPTY and selectedStar and selectedStar:IsSkillStar() then
        local starSkillData = selectedStar:GetChampionSkillData()
        if self.championSkillData == starSkillData then
            self:ShowDragAndDropCalloutForChampionSkillData(self.championSkillData) 
        else
            self:HideDragAndDropCallout()
        end
    end
    self.icon:SetTexture(backgroundTexture)

    self.button:SetNormalTexture(self.textures.border)
    self.button:SetMouseOverTexture(self.textures.selected)
    self.button:SetDisabledTexture(self.textures.disabled)

    if self.isMousedOver and not IsInGamepadPreferredMode() then
        self:SelectSlottedStar()
        self:ShowTooltip()
    end
end

function ZO_ChampionAssignableActionBarSlot:ShowTooltip()
    self:HideTooltip()

    if self.championSkillData then
        InitializeTooltip(ChampionSkillTooltip, self.button, TOP, 0, 15, BOTTOM)
        local pendingPoints = self.championSkillData:GetNumPendingPoints()
        ChampionSkillTooltip:SetChampionSkill(self.championSkillData:GetId(), pendingPoints, self.championSkillData:GetNextJumpPoint(pendingPoints), CHAMPION_PERKS:IsChampionSkillDataSlotted(self.championSkillData))
    end
end

function ZO_ChampionAssignableActionBarSlot:HideTooltip()
    ClearTooltip(ChampionSkillTooltip)
end

function ZO_ChampionAssignableActionBarSlot:ShowDragAndDropCalloutForChampionSkillData(championSkillData)
    if championSkillData == nil or self:CanSlotChampionSkillData(championSkillData) then
        self.dragAndDropCallout:SetTexture(self.textures.selected)
        self.dragAndDropCallout:SetHidden(false)
    else
        self.button:SetEnabled(false)
    end
end

function ZO_ChampionAssignableActionBarSlot:ShowSlotCalloutByDisciplineType(disciplineType)
    if disciplineType == GetChampionDisciplineType(self:GetRequiredDisciplineId()) then
        self.button:SetEnabled(true)
    else
        self.button:SetEnabled(false)
    end
end

function ZO_ChampionAssignableActionBarSlot:HideDragAndDropCallout()
    self.dragAndDropCallout:SetHidden(true)
    self.button:SetEnabled(true)
end

function ZO_ChampionAssignableActionBarSlot:OnDragStart()
    local result = GetChampionPurchaseAvailability()
    if result ~= CHAMPION_PURCHASE_SUCCESS then
        ZO_AlertEvent(EVENT_CHAMPION_PURCHASE_RESULT, result)
        return
    end

    if GetCursorContentType() == MOUSE_CONTENT_EMPTY then
        if self.championSkillData and self.championSkillData:TryCursorPickup() then
            self:ClearSlot()
            PlaySound(SOUNDS.CHAMPION_STAR_PICKED_UP)
        end
    end
end

function ZO_ChampionAssignableActionBarSlot:OnReceiveDrag()
    local championSkillId = GetCursorChampionSkillId()
    if championSkillId == nil then
        return
    end

    local oldChampionSkillData = self.championSkillData
    local championSkillData = CHAMPION_DATA_MANAGER:GetChampionSkillData(championSkillId)

    local expectedResult = self:GetExpectedSkillSlotResult(championSkillData)
    if expectedResult ~= CHAMPION_PURCHASE_SUCCESS then
        ZO_AlertEvent(EVENT_CHAMPION_PURCHASE_RESULT, expectedResult)
    end

    if self:AssignChampionSkillToSlot(championSkillData) then
        ClearCursor()
        if oldChampionSkillData then
            oldChampionSkillData:TryCursorPickup()
        end
        self:Refresh()
        PlaySound(SOUNDS.CHAMPION_STAR_SLOTTED)
    end
end

function ZO_ChampionAssignableActionBarSlot:ShowActionMenu()
    if self.championSkillData then
        ClearMenu()
        AddMenuItem(GetString(SI_ABILITY_ACTION_CLEAR_SLOT), function()
            if self:ClearSlot() then
                PlaySound(SOUNDS.CHAMPION_STAR_SLOT_CLEARED)
            end
        end)
        ShowMenu(self.button)
    end
end

ZO_ChampionAssignableActionBar_GamepadEditor = ZO_InitializingObject:Subclass()

function ZO_ChampionAssignableActionBar_GamepadEditor:Initialize(championBar)
    self.bar = championBar
    self.horizontalMovementController = ZO_MovementController:New(MOVEMENT_CONTROLLER_DIRECTION_HORIZONTAL)
    self.currentChampionSkillData = nil
    self.currentSlotIndex = nil
    self.isFocused = false

    GAMEPAD_CHAMPION_QUICK_MENU:RegisterChampionBar(self.bar, self)
end

function ZO_ChampionAssignableActionBar_GamepadEditor:IsFocused()
    return self.isFocused
end

function ZO_ChampionAssignableActionBar_GamepadEditor:GetCurrentSlot()
    return self.bar:GetSlot(self.currentSlotIndex)
end

function ZO_ChampionAssignableActionBar_GamepadEditor:UpdateDirectionalInput()
    local lastSlotIndex = self.currentSlotIndex
    local horizontalMove = self.horizontalMovementController:CheckMovement()
    if horizontalMove == MOVEMENT_CONTROLLER_MOVE_NEXT then
        self.currentSlotIndex = self.currentSlotIndex + 1
    elseif horizontalMove == MOVEMENT_CONTROLLER_MOVE_PREVIOUS then
        self.currentSlotIndex = self.currentSlotIndex - 1
    end
    self.currentSlotIndex = zo_clamp(self.currentSlotIndex, 1, self.bar:GetNumSlots())

    --If we are not allowing discipline swapping, make sure we prevent the slot change if it would change the discipline
    local hasDisciplineChanged = self.bar:GetSlot(self.currentSlotIndex):GetRequiredDisciplineId() ~= self.bar:GetSlot(lastSlotIndex):GetRequiredDisciplineId()
    if hasDisciplineChanged and not self.allowDisciplineSwapping then
        self.currentSlotIndex = lastSlotIndex
    end
    if lastSlotIndex ~= self.currentSlotIndex then
        self.bar:GetSlot(lastSlotIndex):HideDragAndDropCallout()
        self.bar:GetSlot(self.currentSlotIndex):ShowDragAndDropCalloutForChampionSkillData(self.currentChampionSkillData)
        --When we change disciplines, we want to cycle to the matching constellation for the new discipline
        if hasDisciplineChanged then
            CHAMPION_PERKS:SelectOrChooseNodeForDisciplineId(self.bar:GetSlot(self.currentSlotIndex):GetRequiredDisciplineId())
        end
        PlaySound(SOUNDS.HOR_LIST_ITEM_SELECTED)
        self:RefreshEditorTooltip()
        self.bar:FireCallbacks("GamepadCurrentSlotChanged")
    end
end

function ZO_ChampionAssignableActionBar_GamepadEditor:StartAssigningChampionSkill(championSkillData)
    self.currentChampionSkillData = championSkillData
    local PREVENT_DISCIPLINE_SWAPPING = false
    self:FocusBar(PREVENT_DISCIPLINE_SWAPPING)
    PlaySound(SOUNDS.CHAMPION_STAR_PICKED_UP)
end

function ZO_ChampionAssignableActionBar_GamepadEditor:FinishAssigningChampionSkill()
    self.bar:GetSlot(self.currentSlotIndex):AssignChampionSkillToSlot(self.currentChampionSkillData)
    PlaySound(SOUNDS.CHAMPION_STAR_SLOTTED)
    self:UnfocusBar()
end

function ZO_ChampionAssignableActionBar_GamepadEditor:IsAssigningChampionSkill()
    return self.currentChampionSkillData ~= nil
end

function ZO_ChampionAssignableActionBar_GamepadEditor:GetExpectedAssignSkillResult()
    return self:GetCurrentSlot():GetExpectedSkillSlotResult(self.currentChampionSkillData)
end

function ZO_ChampionAssignableActionBar_GamepadEditor:FocusBar(allowDisciplineSwapping)
    if not self.isFocused then
        self.bar:HideDragAndDropCallouts()
        local previousSlotIndex = self.currentSlotIndex
        self.lastSelectedStar = CHAMPION_PERKS:GetGamepadCursor():GetLastSelectedStar()
        self.currentSlotIndex = 1
        self.isFocused = true
        self.allowDisciplineSwapping = allowDisciplineSwapping

        --Set the selected slot to the first slot for the selected/chosen constellation's discipline
        local currentConstellation = CHAMPION_PERKS:GetChosenConstellation() or CHAMPION_PERKS:GetSelectedConstellation()
        if currentConstellation then 
            self.currentSlotIndex = self.bar:GetFirstSlotIndexForDiscipline(currentConstellation:GetChampionDisciplineData():GetId())
            self.bar:ShowDisciplineCallout(currentConstellation:GetChampionDisciplineData():GetType())
            self.bar:ShowSlotCalloutsByDisciplineType(currentConstellation:GetChampionDisciplineData():GetType())
        end

        self:GetCurrentSlot():ShowDragAndDropCalloutForChampionSkillData(self.currentChampionSkillData)

        if self.currentSlotIndex ~= previousSlotIndex then
            self.bar:FireCallbacks("GamepadCurrentSlotChanged")
        end

        self:RefreshEditorTooltip()
        CHAMPION_PERKS:GetGamepadCursor():UpdateVisibility()
        self.bar:FireCallbacks("GamepadFocusChanged")
    end
end

function ZO_ChampionAssignableActionBar_GamepadEditor:UnfocusBar()
    if self.isFocused then
        self.bar:HideDragAndDropCallouts()
        self.bar:HideCurrentDisciplineCallout()

        self.currentChampionSkillData = nil
        self.currentSlotIndex = nil
        self.isFocused = false

        self.bar:RefreshAllSlots()

        CHAMPION_PERKS:GetGamepadCursor():UpdateVisibility()
        self.bar:FireCallbacks("GamepadFocusChanged")
    end
end

function ZO_ChampionAssignableActionBar_GamepadEditor:RefreshEditorTooltip()
    if self:IsAssigningChampionSkill() then
        local starTooltip = CHAMPION_PERKS:GetGamepadStarTooltip()
        local skillData = self:GetCurrentSlot():GetChampionSkillData()

        if skillData then
            CHAMPION_PERKS:GetChosenConstellation():SelectStar(nil)
            starTooltip:ClearAnchors()
            starTooltip:SetAnchor(TOP, self:GetCurrentSlot().control, BOTTOM)
            starTooltip.scrollTooltip:ClearLines()
            starTooltip.tip:LayoutChampionSkill(skillData)
            starTooltip:SetHidden(false)
        else
            CHAMPION_PERKS:GetChosenConstellation():SelectStar(self.lastSelectedStar)
            CHAMPION_PERKS:DirtySelectedStar()
        end
    else
        CHAMPION_PERKS:DirtySelectedStar()
    end
end

ZO_ChampionAssignableActionBar_GamepadQuickMenu = ZO_Gamepad_ParametricList_Screen:Subclass()

local CHAMPION_SKILL_DISCIPLINE_ICONS = 
{
    [CHAMPION_DISCIPLINE_TYPE_COMBAT] = "EsoUI/Art/Champion/Gamepad/gp_quickmenu_combat.dds",
    [CHAMPION_DISCIPLINE_TYPE_CONDITIONING] = "EsoUI/Art/Champion/Gamepad/gp_quickmenu_conditioning.dds",
    [CHAMPION_DISCIPLINE_TYPE_WORLD] = "EsoUI/Art/Champion/Gamepad/gp_quickmenu_world.dds",
}

function ZO_ChampionAssignableActionBar_GamepadQuickMenu:Initialize(topLevelControl)
    local NO_TAB_BAR = false
    local ACTIVATE_ON_SHOW = true
    ZO_Gamepad_ParametricList_Screen.Initialize(self, topLevelControl, NO_TAB_BAR, ACTIVATE_ON_SHOW)

    local ALWAYS_ANIMATE = true
    self.fragment = ZO_FadeSceneFragment:New(topLevelControl, ALWAYS_ANIMATE)
    self:SetParentFragment(self.fragment)

    self.headerData =
    {
        titleText = GetString(SI_GAMEPAD_CHAMPION_QUICK_MENU),
    }
    ZO_GamepadGenericHeader_Refresh(self.header, self.headerData)
end

function ZO_ChampionAssignableActionBar_GamepadQuickMenu:RegisterChampionBar(championBar, championBarGamepadEditor)
    self.bar = championBar
    self.editor = championBarGamepadEditor

    self.bar:RegisterCallback("SlotChanged", function() 
        CHAMPION_PERKS:DirtySelectedStar()
        self:Update() 
    end)

    self.bar:RegisterCallback("GamepadCurrentSlotChanged", function()
        self.autoSelectSkillInCurrentSlot = true
        self:Update()
    end)
end

function ZO_ChampionAssignableActionBar_GamepadQuickMenu:InitializeKeybindStripDescriptors()
    -- this field _cannot_ be named self.keybindStripDescriptor: doing so would
    -- enable the built-in keybind strip handling on the
    -- ParametricScrollListScreen side.
    local list = self:GetMainList()
    self.quickMenuKeybindStripDescriptor = { 
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        
        { 
            name = function()
                local targetData = list:GetTargetData()
                if targetData.championSkillData == self.editor:GetCurrentSlot():GetChampionSkillData() then
                    return GetString(SI_GAMEPAD_CHAMPION_CLEAR_SKILL)
                else
                    return GetString(SI_GAMEPAD_CHAMPION_SLOT_SKILL)
                end
            end,

            keybind = "UI_SHORTCUT_PRIMARY",

            visible = function()
                return list:GetTargetData() ~= nil
            end,

            callback = function()
                local targetData = list:GetTargetData()
                local currentSlot = self.editor:GetCurrentSlot()
                if targetData.championSkillData == currentSlot:GetChampionSkillData() then
                    currentSlot:ClearSlot()
                else
                    currentSlot:AssignChampionSkillToSlot(targetData.championSkillData)
                end
            end,

            sound = function()
                local targetData = list:GetTargetData()
                local currentSlot = self.editor:GetCurrentSlot()
                if targetData.championSkillData == currentSlot:GetChampionSkillData() then
                    return SOUNDS.CHAMPION_STAR_SLOT_CLEARED
                else
                    return SOUNDS.CHAMPION_STAR_SLOTTED
                end
            end,
        },

        {
            name = GetString(SI_GAMEPAD_BACK_OPTION),

            keybind = "UI_SHORTCUT_NEGATIVE",

            callback = function()
                self:Hide()
            end,
        },
    }
    
    ZO_Gamepad_AddListTriggerKeybindDescriptors(self.quickMenuKeybindStripDescriptor, list)
end

function ZO_ChampionAssignableActionBar_GamepadQuickMenu:AddKeybindStrips(keybindStripId)
    KEYBIND_STRIP:AddKeybindButtonGroup(self.quickMenuKeybindStripDescriptor, keybindStripId)
end

function ZO_ChampionAssignableActionBar_GamepadQuickMenu:RemoveKeybindStrips(keybindStripId)
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.quickMenuKeybindStripDescriptor, keybindStripId)
end

function ZO_ChampionAssignableActionBar_GamepadQuickMenu:RefreshKeybinds()
    -- do not use the built in refresh, use the champion perks refresh instead
    CHAMPION_PERKS:RefreshKeybinds()
end

function ZO_ChampionAssignableActionBar_GamepadQuickMenu:SetupList(list)
    local function AreChampionSkillDataEntriesEqual(left, right)
        return left.championSkillData == right.championSkillData
    end
    list:AddDataTemplate("ZO_GamepadChampionSkillEntryTemplate", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction, AreChampionSkillDataEntriesEqual)
    list:AddDataTemplateWithHeader("ZO_GamepadChampionSkillEntryTemplate", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction, AreChampionSkillDataEntriesEqual, "ZO_GamepadMenuEntryHeaderTemplate")
    list:SetNoItemText(GetString(SI_GAMEPAD_CHAMPION_QUICK_MENU_NO_SKILLS))

    local function OnSelectedDataChangedCallback(innerList, selectedData)
        GAMEPAD_TOOLTIPS:ClearLines(GAMEPAD_RIGHT_TOOLTIP)
        if selectedData then
            GAMEPAD_TOOLTIPS:LayoutChampionSkill(GAMEPAD_RIGHT_TOOLTIP, selectedData.championSkillData)
        end
    end
    list:SetOnSelectedDataChangedCallback(OnSelectedDataChangedCallback)
end

do
    local FOCUSED_SKILL_STATUS_ICON_OVERRIDE = 
    {
        {
            iconTexture = ZO_CHAMPION_FOCUSED_SKILL_STATUS_INDICATOR,
            iconNarration = GetString(SI_SCREEN_NARRATION_CHAMPION_EQUIPPED),
        }
    }

    local EQUIPPED_STATUS_ICON_OVERRIDE =
    {
        {
            iconTexture = ZO_CHAMPION_EQUIPPED_STATUS_INDICATOR,
            iconNarration = GetString(SI_SCREEN_NARRATION_CHAMPION_EQUIPPED),
        }
    }

    function ZO_ChampionAssignableActionBar_GamepadQuickMenu:PerformUpdate()
        local list = self:GetMainList()
        list:Clear()

        local canBeSlottedFilter = { ZO_ChampionSkillData.CanBeSlotted }
        local currentSlot = self.editor:GetCurrentSlot()
        local currentSlotIndex = currentSlot:GetSlotIndices()

        local isDisciplinePermittedFilter = {}
        local requiredDisciplineId = currentSlot:GetRequiredDisciplineId()
        if requiredDisciplineId then
            table.insert(isDisciplinePermittedFilter, function(disciplineData)
                return disciplineData:GetId() == requiredDisciplineId
            end)
        end

        for _, disciplineData in CHAMPION_DATA_MANAGER:ChampionDisciplineDataIterator(isDisciplinePermittedFilter) do
            local newDiscipline = true
            local disciplineIcon = CHAMPION_SKILL_DISCIPLINE_ICONS[disciplineData:GetType()]
            for _, skillData in disciplineData:ChampionSkillDataIterator(canBeSlottedFilter) do
                local entryName = zo_strformat(SI_CHAMPION_TOOLTIP_CLUSTER_CHILD_FORMAT, skillData:GetRawName(), skillData:GetNumPendingPoints(), skillData:GetMaxPossiblePoints())
                local entryData = ZO_GamepadEntryData:New(entryName)
                entryData:AddIcon(disciplineIcon)
                entryData.championSkillData = skillData

                local matchingSlot = self.bar:FindSlotMatchingChampionSkill(skillData)
                --Mark any entry that is already slotted
                if matchingSlot then
                    local matchingSlotIndex = matchingSlot:GetSlotIndices()
                    if currentSlotIndex == matchingSlotIndex then
                        entryData.isSelected = true
                        entryData.overrideStatusIndicatorIcons = FOCUSED_SKILL_STATUS_ICON_OVERRIDE
                    else
                        entryData.overrideStatusIndicatorIcons = EQUIPPED_STATUS_ICON_OVERRIDE
                    end
                end

                if newDiscipline then
                    self.bar:ShowDisciplineCallout(disciplineData:GetType())
                    self.bar:ShowSlotCalloutsByDisciplineType(disciplineData:GetType())
                    entryData:SetHeader(disciplineData:GetFormattedName())
                    list:AddEntryWithHeader("ZO_GamepadChampionSkillEntryTemplate", entryData)
                else
                    list:AddEntry("ZO_GamepadChampionSkillEntryTemplate", entryData)
                end

                newDiscipline = false
            end
        end

        list:Commit()
    end
end

function ZO_ChampionAssignableActionBar_GamepadQuickMenu:Show()
    SCENE_MANAGER:AddFragment(self.fragment)
end

function ZO_ChampionAssignableActionBar_GamepadQuickMenu:Hide()
    GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_RIGHT_TOOLTIP)
    SCENE_MANAGER:RemoveFragment(self.fragment)
end

function ZO_ChampionAssignableActionBar_GamepadQuickMenu:IsShowing()
    return self.fragment:IsShowing()
end

function ZO_ChampionAssignableActionBar_GamepadQuickMenu:OnHide()
    ZO_Gamepad_ParametricList_Screen.OnHide(self)
    self.editor:UnfocusBar()
    self:RefreshKeybinds()
end

-- Button XML
function ZO_ChampionAssignableActionSlot_OnMouseEnter(control)
    control.owner:OnMouseEnter()
end

function ZO_ChampionAssignableActionSlot_OnMouseExit(control)
    control.owner:OnMouseExit()
end

function ZO_ChampionAssignableActionSlot_OnMouseClicked(control, button)
    if button == MOUSE_BUTTON_INDEX_LEFT then
        if GetCursorContentType() ~= MOUSE_CONTENT_EMPTY then
            control.owner:OnReceiveDrag()
        end
    elseif button == MOUSE_BUTTON_INDEX_RIGHT then
        control.owner:ShowActionMenu()
    end
end

function ZO_ChampionAssignableActionSlot_OnDragStart(control)
    control.owner:OnDragStart()
end

function ZO_ChampionAssignableActionSlot_OnReceiveDrag(control)
    control.owner:OnReceiveDrag()
end

function ZO_ChampionAssignableActionBar_GamepadQuickMenu_OnInitialize(topLevelControl)
    GAMEPAD_CHAMPION_QUICK_MENU = ZO_ChampionAssignableActionBar_GamepadQuickMenu:New(topLevelControl)
end
