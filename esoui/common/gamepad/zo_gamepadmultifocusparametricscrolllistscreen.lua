local GamepadInteractiveSortFilterFocus_ParametricList = ZO_GamepadMultiFocusArea_Base:Subclass()

function GamepadInteractiveSortFilterFocus_ParametricList:HandleMovement(horizontalResult, verticalResult)
    if verticalResult == MOVEMENT_CONTROLLER_MOVE_NEXT then
        self.manager:MoveNext()
        return true
    elseif verticalResult == MOVEMENT_CONTROLLER_MOVE_PREVIOUS then
        self.manager:MovePrevious()
        return true
    end
    return false
end

function GamepadInteractiveSortFilterFocus_ParametricList:HandleMovePrevious()
    local consumed = false
    if self.manager:AtTopOfList() then
        consumed = ZO_GamepadMultiFocusArea_Base.HandleMovePrevious(self)
    end
    return consumed
end

function GamepadInteractiveSortFilterFocus_ParametricList:HandleMoveNext()
    local consumed = false
    if self.manager:AtBottomOfList() then
        consumed = ZO_GamepadMultiFocusArea_Base.HandleMoveNext(self)
    end
    return consumed
end

ZO_Gamepad_MultiFocus_ParametricList_Screen = ZO_Object:MultiSubclass(ZO_GamepadMultiFocusArea_Manager, ZO_Gamepad_ParametricList_Screen)

function ZO_Gamepad_MultiFocus_ParametricList_Screen:New(...)
    return ZO_Gamepad_ParametricList_Screen.New(self, ...)
end

function ZO_Gamepad_MultiFocus_ParametricList_Screen:Initialize(control, createTabBar, activateOnShow, scene)
    ZO_Gamepad_ParametricList_Screen.Initialize(self, control, createTabBar, activateOnShow, scene)
	ZO_GamepadMultiFocusArea_Manager.Initialize(self)
	 
	self:InitializeMultiFocusArea()
end

-- Multi Focus Area functions --

function ZO_Gamepad_MultiFocus_ParametricList_Screen:InitializeMultiFocusArea()
    local function ActivateCallback()
        self._currentList:Activate()
        self:OnListAreaActivate()
    end

    local function DeactivateCallback()
        self._currentList:Deactivate()
        self:OnListAreaDeactivate()
    end

    self.parametricListArea = GamepadInteractiveSortFilterFocus_ParametricList:New(self, ActivateCallback, DeactivateCallback)
    self.parametricListArea:SetKeybindDescriptor(self.keybindStripDescriptor)

    self:AddNextFocusArea(self.parametricListArea)

    self.currentFocalArea = self.parametricListArea
end

function ZO_Gamepad_MultiFocus_ParametricList_Screen:ResetFocusArea()
    self:SelectFocusArea(self.parametricListArea)
end

function ZO_Gamepad_MultiFocus_ParametricList_Screen:OnListAreaActivate()
    -- override in derived functions for desired behaviour
end

function ZO_Gamepad_MultiFocus_ParametricList_Screen:OnListAreaDeactivate()
    -- override in derived functions for desired behaviour
end

function ZO_Gamepad_ParametricList_Screen:MoveNext()
    self._currentList:MoveNext()
end

function ZO_Gamepad_ParametricList_Screen:MovePrevious()
    self._currentList:MovePrevious()
end

function ZO_Gamepad_ParametricList_Screen:AtTopOfList()
    return self._currentList:GetSelectedIndex() == 1 
end

function ZO_Gamepad_ParametricList_Screen:AtBottomOfList()
    return self._currentList:GetSelectedIndex() == self._currentList:GetNumItems()
end

-- Header functions --

function ZO_Gamepad_MultiFocus_ParametricList_Screen:SetupHeaderFocus(headerFocus)
    assert(false) -- Cannot use this function in this class
end

function ZO_Gamepad_MultiFocus_ParametricList_Screen:UpdateDirectionalInput()
    ZO_GamepadMultiFocusArea_Manager.UpdateDirectionalInput(self) -- explicitly state which base class function we want to use
end

-- Scene functions --

-- A function which should be called as the StateChanged callback for the scene.
function ZO_Gamepad_MultiFocus_ParametricList_Screen:OnStateChanged(oldState, newState)
    if newState == SCENE_SHOWING or newState == SCENE_GROUP_SHOWING then
        self:PerformDeferredInitialize()
        if self.activateOnShow then
            self:SetCurrentList(self:GetMainList())
        end
        
        SCENE_MANAGER:AddFragment(self.headerFragment)
        self:OnShowing()
    elseif newState == SCENE_HIDING then
        self:OnHiding()
    elseif newState == SCENE_HIDDEN or newState == SCENE_GROUP_HIDDEN then
        self:OnHide()
        self:Deactivate()
    elseif newState == SCENE_SHOWN or newState == SCENE_GROUP_SHOWN then
        self:OnShow()
    end
end

function ZO_Gamepad_MultiFocus_ParametricList_Screen:RefreshKeybinds()
    self:UpdateActiveFocusKeybinds()
end

-- A function called when the screen is being shown. This should call self:PerformUpdate() if self.dirty.
function ZO_Gamepad_MultiFocus_ParametricList_Screen:OnShowing()
    if self.dirty then
        self:PerformUpdate()
    end

    if not DIRECTIONAL_INPUT:IsListening(self) then
        self._currentList:SetDirectionalInputEnabled(false)
        DIRECTIONAL_INPUT:Activate(self, self.control)
    end
	
	self:ActivateCurrentFocus()
end

-- A function called when the screen is fully hidden. This may be overridden in a sub-class.
function ZO_Gamepad_MultiFocus_ParametricList_Screen:OnHide()
    if DIRECTIONAL_INPUT:IsListening(self) then
        DIRECTIONAL_INPUT:Deactivate(self)
    end
	
	self:DeactivateCurrentFocus()
end