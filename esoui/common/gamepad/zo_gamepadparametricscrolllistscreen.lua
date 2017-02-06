local g_updateCooldownManager

--[[    Parametric Scroll List Screen Template

The functions PerformUpdate and InitializeKeybindStripDescriptors must be overridden by a sub-class.
The functions OnSelectionChanged, OnShow, OnShowing, OnHide, and SetupList are additionally
   intended to be overriden by a sub-class, but they are not required to be.

Additionally, after Initialize is called, self.headerData should be setup for the screen's header.
  After updating, a call to ZO_GamepadGenericHeader_Refresh(self.header, self.headerData) should be
  made.

To trigger updates, self:Update() should be called, rather than directly self:PerformUpdate(). This will
  delay the update until the screen is actually shown, if the screen is currently hidden.

Finally, self:OnStateChanged should be called as the primary state-changed callback of the screen.
]]--
ZO_Gamepad_ParametricList_Screen = ZO_Object:Subclass()

function ZO_Gamepad_ParametricList_Screen:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

--[[
Initialize the parametric list screen.

control should be the top-level-control derived from ZO_Gamepad_ParametricList_Screen.

createTabBar should be a boolean for whether the header should create the tab-bar. If true,
    the header data used for udpating the generic header may include tab data. If false, it
    may only provide titleText.

activateOnShow specifies whether the screen should automatically activate its parameteric
    list on show. If nil, defaults to true.

scene - An optional argument for passing in a scene to have that scene's OnStateChanged callback invoke the ZO_Gamepad_ParametricList_Screen's OnStateChanged function.
]]
function ZO_Gamepad_ParametricList_Screen:Initialize(control, createTabBar, activateOnShow, scene)
    control.owner = self
    self.control = control

    local mask = control:GetNamedChild("Mask")

    local container = mask:GetNamedChild("Container")
    control.container = container

    self.activateOnShow = (activateOnShow ~= false) -- nil should be true
    self:SetScene(scene)

    self.headerContainer = container:GetNamedChild("HeaderContainer")
    control.header = self.headerContainer.header
    self.headerFragment = ZO_ConveyorSceneFragment:New(self.headerContainer, ALWAYS_ANIMATE)

    self.header = control.header
    ZO_GamepadGenericHeader_Initialize(self.header, createTabBar)

    self.updateCooldownMS = 0

    self.lists = {}
    self:AddList("Main")
    self._currentList = nil
    self.addListTriggerKeybinds = false
    self.listTriggerKeybinds = nil
    self.listTriggerHeaderComparator = nil

    self:InitializeKeybindStripDescriptors()

    self.dirty = true
end

function ZO_Gamepad_ParametricList_Screen:SetListsUseTriggerKeybinds(addListTriggerKeybinds, optionalHeaderComparator)
    self.addListTriggerKeybinds = addListTriggerKeybinds
    self.listTriggerHeaderComparator = optionalHeaderComparator

    if(not addListTriggerKeybinds) then
        self:TryRemoveListTriggers()
    end
end

---------------------
-- List Management --
---------------------

function ZO_Gamepad_ParametricList_Screen:GetListFragment(list)
    if(type(list) == "string") then
        list = self:GetList(list)
    end

    if(list ~= nil) then
        return list._fragment
    end
end

function ZO_Gamepad_ParametricList_Screen:GetHeaderFragment()
    return self.headerFragment
end

function ZO_Gamepad_ParametricList_Screen:GetHeaderContainer()
    return self.headerContainer
end

function ZO_Gamepad_ParametricList_Screen:ActivateCurrentList()
    if(self._currentList ~= nil) then
        self:TryAddListTriggers()
        self._currentList:Activate()
    end
end

function ZO_Gamepad_ParametricList_Screen:DeactivateCurrentList()
    if(self._currentList ~= nil) then
        self._currentList:Deactivate()
        self:TryRemoveListTriggers()
    end
end

function ZO_Gamepad_ParametricList_Screen:EnableCurrentList()
    if(self._currentList ~= nil) then
        local currentFragment = self:GetListFragment(self._currentList)
        if(currentFragment) then
            SCENE_MANAGER:AddFragment(currentFragment)
        end
        self:TryAddListTriggers()
        self._currentList:Activate()
    end
end

function ZO_Gamepad_ParametricList_Screen:DisableCurrentList()
    if(self._currentList ~= nil) then
        self._currentList:Deactivate()
        local currentFragment = self:GetListFragment(self._currentList)
        if(currentFragment) then
            SCENE_MANAGER:RemoveFragment(currentFragment)
        end
        self:TryRemoveListTriggers()
        self._currentList = nil
    end
end

function ZO_Gamepad_ParametricList_Screen:SetCurrentList(list)
    if(type(list) == "string") then
        list = self:GetList(list)
    end

    if(self._currentList ~= list) then
        self:DisableCurrentList()
        self._currentList = list
    end
    self:EnableCurrentList()
    self:RefreshKeybinds()
end

function ZO_Gamepad_ParametricList_Screen:GetCurrentList()
    return self._currentList
end

function ZO_Gamepad_ParametricList_Screen:IsCurrentList(list)
    if(type(list) == "string") then
        list = self:GetList(list)
    end

    return list == self._currentList
end

function ZO_Gamepad_ParametricList_Screen:TryAddListTriggers()
    if self.addListTriggerKeybinds and not self.listTriggerKeybinds then
        self.listTriggerKeybinds = {}
        ZO_Gamepad_AddListTriggerKeybindDescriptors(self.listTriggerKeybinds, self._currentList, self.listTriggerHeaderComparator)
        KEYBIND_STRIP:AddKeybindButtonGroup(self.listTriggerKeybinds)
    end
end

function ZO_Gamepad_ParametricList_Screen:TryRemoveListTriggers()
    if self.listTriggerKeybinds then
        KEYBIND_STRIP:RemoveKeybindButtonGroup(self.listTriggerKeybinds)
        self.listTriggerKeybinds = nil
    end
end

-- AddList creates a parametric list which is stored on the class using the given name as a key.
-- If callbackParam is a function, CreateAndSetupList calls callbackParam, or SetupList if callbackParam is nil. If callbackParam is true but not a function, SetupList is not called.
-- The function can create a listClass list instead of creating a ZO_GamepadVerticalItemParametricScrollList. The additional ... arguments are the parameters accepted by listClass.
-- This function also creates a fragment for this list.
-- Note: "Main" is a reserved name and should not be passed in here.
function ZO_Gamepad_ParametricList_Screen:AddList(name, callbackParam, listClass, ...)
    local listContainer = CreateControlFromVirtual("$(parent)"..name, self.control.container, "ZO_Gamepad_ParametricList_Screen_ListContainer")
    local list = self:CreateAndSetupList(listContainer.list, callbackParam, listClass, ...)
    self.lists[name] = list
    local CREATE_HIDDEN = true
    self:CreateListFragment(name, CREATE_HIDDEN)
    return list
end

function ZO_Gamepad_ParametricList_Screen:GetMainList()
    return self.lists["Main"]
end

-- Returns a list that was created using AddList.
function ZO_Gamepad_ParametricList_Screen:GetList(name)
    return self.lists[name]
end

-- Creates a fragment for a list that was created using AddList.
function ZO_Gamepad_ParametricList_Screen:CreateListFragment(name, hideControl)
    local list = self.lists[name]
    local containerControl = list:GetControl():GetParent()
    
    if hideControl ~= nil then
        containerControl:SetHidden(hideControl)
    end

    local ALWAYS_ANIMATE = true
    local fragment = ZO_ConveyorSceneFragment:New(containerControl, ALWAYS_ANIMATE)
    list._fragment = fragment
    return fragment
end

function ZO_Gamepad_ParametricList_Screen:SetScene(scene)
    if self.scene then -- Make sure we don't register multiple callbacks
        self.scene:UnregisterCallback("StateChange", self.onStateChangedCallback)
    end

    if scene then
        self.onStateChangedCallback = function(...)
            self:OnStateChanged(...)
        end
        scene:RegisterCallback("StateChange", self.onStateChangedCallback)
    end

    self.scene = scene
end

-- A function which should be called as the StateChanged callback for the scene.
function ZO_Gamepad_ParametricList_Screen:OnStateChanged(oldState, newState)
    if newState == SCENE_SHOWING or newState == SCENE_GROUP_SHOWING then
        self:PerformDeferredInitialize()
        if self.keybindStripDescriptor then
            KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
        end

        if self.activateOnShow then
            self:SetCurrentList(self:GetMainList())
        end
        
        SCENE_MANAGER:AddFragment(self.headerFragment)
        self:OnShowing()
    elseif newState == SCENE_HIDING then
        if self.keybindStripDescriptor then
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
        end
        self:OnHiding()
    elseif newState == SCENE_HIDDEN or newState == SCENE_GROUP_HIDDEN then
        if newState == SCENE_GROUP_HIDDEN and self.keybindStripDescriptor then
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
        end
        self:Deactivate()
        self:OnHide()
    elseif newState == SCENE_SHOWN or newState == SCENE_GROUP_SHOWN then
        self:OnShow()
    end
end

function ZO_Gamepad_ParametricList_Screen:Activate()
    self:EnableCurrentList()
end

function ZO_Gamepad_ParametricList_Screen:Deactivate()
    self:DisableCurrentList()
end

function ZO_Gamepad_ParametricList_Screen:RefreshKeybinds()
    if self.keybindStripDescriptor then
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
    end
end

-- A function that can be called from (or as) the header's tabBar callback.
function ZO_Gamepad_ParametricList_Screen:OnTabBarCategoryChanged(selectedData)
    if self.scene and SCENE_MANAGER:IsShowing(self.scene.name) then
        if self.currentFragment then
            SCENE_MANAGER:RemoveFragment(self.currentFragment)
        end

        if selectedData.fragment then
            SCENE_MANAGER:AddFragment(selectedData.fragment)
        end

        self:RefreshKeybinds()
    end

    if selectedData.fragment then
        self.currentFragment = selectedData.fragment
    end
end

-- A function, which may be overridden in a sub-class, which should setup the Parametric list (passed in)
--  to the needed specifications. The default implementation will set the list's offset and add some common templates.
function ZO_Gamepad_ParametricList_Screen:SetupList(list)
    list:AddDataTemplate("ZO_GamepadMenuEntryTemplate", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction)
    list:AddDataTemplateWithHeader("ZO_GamepadMenuEntryTemplate", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction, nil, "ZO_GamepadMenuEntryHeaderTemplate")
end

-- A function, which must be overridden in a sub-class, which should add items to the list(s) as well as any other
--  updates which are needed, such as updating the header or keybindstrip. In all cases, this should set self.dirty
--  to false.
function ZO_Gamepad_ParametricList_Screen:PerformUpdate()
    assert(false) -- This function must be overridden in a sub-class.
end

-- A function, which must be overridden in a sub-class, which should setup a keybind descriptor table and assign it to
--  self.keybindStripDescriptor.
function ZO_Gamepad_ParametricList_Screen:InitializeKeybindStripDescriptors()
end

-- A function, which may be overridden in a sub-class, and is called whenever the item list's select is changed.
function ZO_Gamepad_ParametricList_Screen:OnSelectionChanged(list, selectedData, oldSelectedData)
end

-- A function, which may be overridden in a sub-class, and is called whenever the item list's target data is changed.
function ZO_Gamepad_ParametricList_Screen:OnTargetChanged(list, targetData, oldTargetData, reachedTarget, targetSelectedIndex)
end

function ZO_Gamepad_ParametricList_Screen:SetUpdateCooldown(updateCooldownMS)
    self.updateCooldownMS = updateCooldownMS
end

function ZO_Gamepad_ParametricList_Screen:CheckUpdateIfOffCooldown(timeMS)
    if timeMS > self.updateCooldownUntilMS then
        self.updateCooldownUntilMS = nil
        g_updateCooldownManager:Remove(self)
        if self.dirty then
            self:Update()
        end
    end
end

-- A helper function for updating the screen. This should be called when an update is requested, as it will delay
--  the update if the screen is not currently visible.
function ZO_Gamepad_ParametricList_Screen:Update()
    if self.control:IsControlHidden() then
        self.dirty = true
    else
        if self.updateCooldownMS == 0 then
            self:PerformUpdate()
            self.dirty = false
        else
            if self.updateCooldownUntilMS == nil then
                g_updateCooldownManager:Add(self)
                self.updateCooldownUntilMS = GetGameTimeMilliseconds() + self.updateCooldownMS
                self:PerformUpdate()
                self.dirty = false
            else
                self.dirty = true
            end
        end
    end
end

-- A helper function that should be called rather than OnDeferredInitialize when the deferred initialziation of
--  the scene needs to be completed. This is called automatically before OnShowing().
function ZO_Gamepad_ParametricList_Screen:PerformDeferredInitialize()
    if not self.initialized then
        self:OnDeferredInitialize()
        self.initialized = true
    end
end

-- A function, which may be overridden in a sub-class, and is called on the first showing of the screen.
function ZO_Gamepad_ParametricList_Screen:OnDeferredInitialize()
end

-- A function called when the screen is being shown. This should call self:PerformUpdate() if self.dirty.
function ZO_Gamepad_ParametricList_Screen:OnShowing()
    if self.dirty then
        self:PerformUpdate()
    end
end

-- A function called when the screen is fully shown. This may be overridden in a sub-class.
function ZO_Gamepad_ParametricList_Screen:OnShow()
end

-- A function called when the screen is being hidden. This may be overridden in a sub-class.
function ZO_Gamepad_ParametricList_Screen:OnHiding()
end

-- A function called when the screen is fully hidden. This may be overridden in a sub-class.
function ZO_Gamepad_ParametricList_Screen:OnHide()
end

--[[ ----------- ]]
--[[ PRIVATE API ]]
--[[ ----------- ]]

function ZO_Gamepad_ParametricList_Screen:CreateAndSetupList(control, callbackParam, listClass, ...)
    local list
    if listClass then
        list = listClass:New(control, ...)
    else
        list = ZO_GamepadVerticalItemParametricScrollList:New(control)
    end

    list:SetAlignToScreenCenter(true) -- by default, parametric list screens will center to screen space

    if callbackParam then
        if type(callbackParam) == "function" then
            callbackParam(list)
        end
    else
        self:SetupList(list)
    end

    if list.SetOnSelectedDataChangedCallback then
        local function OnSelectionChanged(...)
            self:OnSelectionChanged(...)
            self:RefreshKeybinds()
        end
        list:SetOnSelectedDataChangedCallback(OnSelectionChanged)
    end

    if list.SetOnTargetDataChangedCallback then
        local function OnTargetChanged(...)
            self:OnTargetChanged(...)
            self:RefreshKeybinds()
        end
        list:SetOnTargetDataChangedCallback(OnTargetChanged)
    end

    return list
end

--Update Cooldown Manger

local UpdateCooldownManager = ZO_Object:Subclass()

function UpdateCooldownManager:New(...)
    local obj = ZO_Object.New(self)
    obj:Initialize(...)
    return obj
end

function UpdateCooldownManager:Initialize()
    self.parametricScreensWithCooldowns = {}
    EVENT_MANAGER:RegisterForUpdate("ZO_GamepadParametricList_Screen_UpdateCooldown", 100, function(...) self:Update(...) end)
end

function UpdateCooldownManager:Add(screen)
    table.insert(self.parametricScreensWithCooldowns, screen)
end

function UpdateCooldownManager:Remove(screen)
    for i = 1, #self.parametricScreensWithCooldowns do
        if self.parametricScreensWithCooldowns[i] == screen then
            table.remove(self.parametricScreensWithCooldowns, i)
            break
        end
    end
end

function UpdateCooldownManager:Update(timeMS)
    for i = 1, #self.parametricScreensWithCooldowns do
        local parametricScreen = self.parametricScreensWithCooldowns[i]
        parametricScreen:CheckUpdateIfOffCooldown(timeMS)
    end
end

g_updateCooldownManager = UpdateCooldownManager:New()