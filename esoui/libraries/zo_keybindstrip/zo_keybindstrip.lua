ZO_KeybindStrip = ZO_InitializingObject:Subclass()

KEYBIND_STRIP_ALIGN_LEFT = 1
KEYBIND_STRIP_ALIGN_CENTER = 2
KEYBIND_STRIP_ALIGN_RIGHT = 3

KEYBIND_STRIP_DISABLED_ALERT = "alert"
KEYBIND_STRIP_DISABLED_DIALOG = "dialog"

local DOWN = false
local UP = true
function ZO_KeybindStrip:Initialize(control, keybindButtonTemplate, styleInfo)
    self.control = control
    self.centerParent = control:GetNamedChild("CenterParent") or control
    self.keybinds = {}
    self.keybindsByGamepadPreferredKeybind = {}
    self.keybindGroups = {}
    self.cooldownKeybinds = {}
    self.keybindStateStack = {}
    self.keybindButtons = {}

    self:SetStyle(styleInfo)

    local function OnButtonClicked(button)
        local keybindButtonDescriptor = button.keybindButtonDescriptor
        if self:FilterSceneHiding(keybindButtonDescriptor) then
            if keybindButtonDescriptor.callback then
                keybindButtonDescriptor.callback(DOWN)
            end
            if keybindButtonDescriptor.handlesKeyUp or keybindButtonDescriptor.keybindButtonGroupDescriptor and keybindButtonDescriptor.keybindButtonGroupDescriptor.handlesKeyUp then
                if keybindButtonDescriptor.callback then
                    keybindButtonDescriptor.callback(UP)
                end
            end
        end
    end

    local function CreateButton(objectPool)
        -- NOTE: Whatever template is used here is expected to have the interface defined by
        -- ZO_KeybindButtonTemplate_OnInitialized.  This should set up a few control references (for the name and key labels)
        -- as well as defining some state management functions...see that object for more details.
        local button = ZO_ObjectPool_CreateControl(keybindButtonTemplate, objectPool, control)
        button:SetCallback(OnButtonClicked)
        return button
    end

    local function Reset(control)
        control:SetHidden(true)
        control:ClearAnchors()
        if control.customKeybindControl then
            control.customKeybindControl:SetParent(nil)
            control.customKeybindControl:SetHidden(true)
            control.customKeybindControl = nil
        end
    end
    
    self.keybindButtonPool = ZO_ObjectPool:New(CreateButton, Reset)

    local function UpdateBindingLabels()
        for keybind, buttonOrEtherealDescriptor in pairs(self.keybinds) do
            if type(buttonOrEtherealDescriptor) == "userdata" then
                self:SetUpButton(buttonOrEtherealDescriptor)
            end
        end

        self:UpdateAnchors()
    end

    control:RegisterForEvent(EVENT_KEYBINDING_SET, UpdateBindingLabels)
    control:RegisterForEvent(EVENT_KEYBINDING_CLEARED, UpdateBindingLabels)
    control:RegisterForEvent(EVENT_KEYBINDINGS_LOADED, UpdateBindingLabels)
    control:RegisterForEvent(EVENT_GAMEPAD_PREFERRED_MODE_CHANGED, UpdateBindingLabels)
    control:RegisterForEvent(EVENT_INPUT_TYPE_CHANGED, UpdateBindingLabels)

    local function OnUpdate(control, time)
        self:UpdateCooldowns(time)
    end
    control:SetHandler("OnUpdate", OnUpdate)
end

-- Keybind State Stack Management

function ZO_KeybindStrip:PushKeybindGroupState()
    local background
    if not ZO_KeybindStripMungeBackground:IsHidden() then
        background = ZO_KeybindStripMungeBackground
    else
        background = ZO_KeybindStripGamepadBackground
    end
    
    local state = 
    {
        keybindGroups = {},
        individualButtons = {},
        drawTier = self.control:GetDrawTier(),
        drawLayer = self.control:GetDrawLayer(),
        drawLevel = self.control:GetDrawLevel(),
        backgroundTier = background:GetDrawTier(),
        backgroundLayer = background:GetDrawLayer(),
        backgroundLevel = background:GetDrawLevel(),
        allowDefaultExit = self.allowDefaultExit
    }

    --copy all the keybind groups into the state and remove them from the strip
    for key, value in pairs(self.keybindGroups) do
        state.keybindGroups[key] = value
    end
    local topStateIndex = self:GetTopKeybindStateIndex()
    self:RemoveAllKeyButtonGroups(topStateIndex)

    --now copy/overwrite any left over buttons to the state
    for key, value in pairs(self.keybinds) do
        state.individualButtons[key] = value.keybindButtonDescriptor or value
        self:RemoveKeybindButton(value.keybindButtonDescriptor or value, topStateIndex)
    end

    table.insert(self.keybindStateStack, state)

    self:UpdateAnchors()

    return self:GetTopKeybindStateIndex()
end

function ZO_KeybindStrip:PopKeybindGroupState()
    local numStates = #self.keybindStateStack
    if(numStates > 0) then
        local topStateIndex = self:GetTopKeybindStateIndex()
        self:RemoveAllKeyButtonGroups(topStateIndex)
        for key, value in pairs(self.keybinds) do
            self:RemoveKeybindButton(value.keybindButtonDescriptor or value, topStateIndex)
        end

        local state = table.remove(self.keybindStateStack, numStates)
        topStateIndex = self:GetTopKeybindStateIndex()

        self:SetDrawOrder(state.drawTier, state.drawLayer, state.drawLevel)
        self:SetBackgroundDrawOrder(state.backgroundTier, state.backgroundLayer, state.backgroundLevel)
        self.allowDefaultExit = state.allowDefaultExit

        for i, descriptorGroup in pairs(state.keybindGroups) do
            self:AddKeybindButtonGroup(descriptorGroup, topStateIndex)
        end

        for i, keybind in pairs(state.individualButtons) do
            if(self:HasKeybindButton(keybind, topStateIndex)) then
                self:UpdateKeybindButton(keybind, topStateIndex)
            else
                self:AddKeybindButton(keybind, topStateIndex)
            end
        end
        
        self:UpdateAnchors()
    end
end

function ZO_KeybindStrip:RemoveAllKeyButtonGroups(stateIndex)
    local state = self:GetKeybindState(stateIndex)
    if state then
        return ZO_KeybindStrip.RemoveAllKeyButtonGroupsStack(state)
    end

    if next(self.keybindGroups) ~= nil then
        local prevKeybindGroups = ZO_ShallowTableCopy(self.keybindGroups)
        for _, groupDescriptor in pairs(prevKeybindGroups) do
            self:RemoveKeybindButtonGroup(groupDescriptor, stateIndex)
        end
    end
end

function ZO_KeybindStrip:ClearKeybindGroupStateStack()
    --remove all keybind buttons and loose buttons as well as any states
    local topStateIndex = self:GetTopKeybindStateIndex()
    self:RemoveAllKeyButtonGroups(topStateIndex)
    for key, value in pairs(self.keybinds) do
        self:RemoveKeybindButton(value.keybindButtonDescriptor or value, topStateIndex)
    end
    ZO_ClearTable(self.keybindStateStack)
end

function ZO_KeybindStrip:SetDrawOrder(tier, layer, level)
    if tier then
         self.control:SetDrawTier(tier)
    end
    if layer then
         self.control:SetDrawLayer(layer)
    end
    if level then
         self.control:SetDrawLevel(level)
    end
end

function ZO_KeybindStrip:SetBackgroundDrawOrder(tier, layer, level)
    if ZO_KeybindStripMungeBackground then
        if tier then 
            ZO_KeybindStripMungeBackground:SetDrawTier(tier)
        end
        if layer then 
            ZO_KeybindStripMungeBackground:SetDrawLayer(layer)
        end
        if level then 
            ZO_KeybindStripMungeBackground:SetDrawLevel(level)
        end
    end
    if ZO_KeybindStripGamepadBackground then
        if tier then 
            ZO_KeybindStripGamepadBackground:SetDrawTier(tier)
        end
        if layer then 
            ZO_KeybindStripGamepadBackground:SetDrawLayer(layer)
        end
        if level then 
            ZO_KeybindStripGamepadBackground:SetDrawLevel(level)
        end
    end
end

--Returns nil if there are no keybind group states (push was not called).
--Returns the bottom of the stack when there is no stateIndex if there are keybind group states (push was called at least once).
function ZO_KeybindStrip:GetKeybindState(stateIndex)
    stateIndex = stateIndex or 1
    assert(stateIndex > 0)
    if stateIndex <= #self.keybindStateStack then
        return self.keybindStateStack[stateIndex]
    end
    return nil
end

function ZO_KeybindStrip:GetTopKeybindStateIndex()
    return #self.keybindStateStack + 1
end

--- PRIVATE FUNCTIONS ---

--We store the descriptor for ethereals and the button control for keybinds that actually appear on the strip
local function GetDescriptorFromButton(buttonOrEtherealDescriptor)
    if type(buttonOrEtherealDescriptor) == "userdata" then
        return buttonOrEtherealDescriptor.keybindButtonDescriptor
    end
    return buttonOrEtherealDescriptor
end

local function GetValueFromRawOrFunction(keybindButtonDescriptor, key)
    local value = keybindButtonDescriptor[key]
    if value == nil and keybindButtonDescriptor.keybindButtonGroupDescriptor then
        value = keybindButtonDescriptor.keybindButtonGroupDescriptor[key]
    end

    if type(value) == "function" then
        return value(keybindButtonDescriptor, keybindButtonDescriptor.keybindButtonGroupDescriptor)
    end

    return value
end

function ZO_KeybindStrip.RemoveKeybindButtonGroupStack(keybindButtonGroupDescriptor, state)
    if state.keybindGroups[keybindButtonGroupDescriptor] then
        state.keybindGroups[keybindButtonGroupDescriptor] = nil
        return true
    end

    return false
end

local function RemoveKeybindButtonStack(keybindButtonDescriptor, state)
    state.individualButtons[keybindButtonDescriptor.keybind] = nil
end

local function UpdateKeybindButtonGroupStack(keybindButtonDescriptor, state)
    if state.keybindGroups[keybindButtonDescriptor] then
        return true
    end

    return false
end

local function UpdateKeybindButtonStack(keybindButtonDescriptor, state)
    -- do nothing
end

local function UpdateCurrentKeybindButtonGroupsStack(stateIndex)
    -- do nothing
end

function ZO_KeybindStrip.RemoveAllKeyButtonGroupsStack(state)
    if next(state.keybindGroups) ~= nil then
        local prevKeybindGroups = ZO_ShallowTableCopy(state.keybindGroups)
        for _, groupDescriptor in pairs(prevKeybindGroups) do
            ZO_KeybindStrip.RemoveKeybindButtonGroupStack(groupDescriptor, state)
        end
    end
end


--- END OF PRIVATE FUNCTIONS ---

--[[

An example keybind button descriptor

local descriptor = {
    alignment = KEYBIND_STRIP_ALIGN_CENTER, -- defaults to KEYBIND_STRIP_ALIGN_RIGHT
    order = 100 -- or a function that returns the relative ordering within the alignment, where a lower number is anchored first (right to left for left alignment, left to right for center and right), default is 0 - buttons with the same order are ordered by insertion
    name = "Exit", -- or function that returns a name
    keybind = "UI_SHORTCUT_PRIMARY",
    gamepadPreferredKeybind = "UI_SHORTCUT_NEGATIVE", -- optional, only use in the case that you want to reuse a button between keyboard and gamepad, but want them to have different bindings.
    customKeybindControl = nil, -- control or a function that returns a control to display instead of the normal keybind label
    callback = function(up) DoSomething() end, -- First and only parameter is whether its a key up or down, ups will only be sent if handlesKeyUp flag is set
    visible = function(descriptor) return IsUsePossible(descriptor.something) end, -- An optional predicate, if present returning true indicates that this descriptor is visible, otherwise it is not
    icon = "IconPath/Icon.dds", -- or a function that returns an icon path, an optional icon to display to the right of the name
    handlesKeyUp = true, -- indicates that the callback would like to be informed of key ups in addition to downs, by default only downs are sent
    disabledDuringSceneHiding = false, -- indicates that the callback is disabled during Scene Hiding, by default it is false
    ethereal = false, -- if true, indicates that the button has no physical presence and will only be considered when a keybind is used, which means that name, alignment, etc properties are ignored. This cannot be a function that returns a value.
}

]]--

do
    local function GetKeybindDescriptorDebugIdentifier(keybindButtonDescriptor)
        return GetValueFromRawOrFunction(keybindButtonDescriptor, "name") or ""
    end

    function ZO_KeybindStrip:HandleDuplicateAddKeybind(existingButtonOrEtherealDescriptor, keybindButtonDescriptor, state, stateIndex, currentSceneName)
        local existingDescriptor = GetDescriptorFromButton(existingButtonOrEtherealDescriptor)
        if existingDescriptor then
            --We tried to re-add the same exact button, just return
            if existingDescriptor == keybindButtonDescriptor then
                return
            end

            local existingSceneName = existingDescriptor.addedForSceneName or ""
            local existingDescriptorIdentifier = GetKeybindDescriptorDebugIdentifier(existingDescriptor)
            local newDescriptorIdentifier = GetKeybindDescriptorDebugIdentifier(keybindButtonDescriptor)
            local keybindIdentifier
            if keybindButtonDescriptor.gamepadPreferredKeybind then
                keybindIdentifier = string.format("%s or %s", keybindButtonDescriptor.keybind, keybindButtonDescriptor.gamepadPreferredKeybind)
            else
                keybindIdentifier = keybindButtonDescriptor.keybind
            end
            local assertMessage = string.format("Duplicate Keybind: %s. Before: %s (%s). After: %s (%s).", keybindIdentifier, existingSceneName, existingDescriptorIdentifier, currentSceneName, newDescriptorIdentifier)

            -- Asserting here usually means that a key is already bound (typically because someone forgot to remove a keybinding).
            internalassert(false, assertMessage)
            self:RemoveKeybindButton(existingDescriptor, stateIndex)
        end
    end

    function ZO_KeybindStrip:AddKeybindButtonStack(keybindButtonDescriptor, state, stateIndex, currentSceneName)
        local existingButtonOrEtherealDescriptor = state.individualButtons[keybindButtonDescriptor.keybind]
        if existingButtonOrEtherealDescriptor then
            self:HandleDuplicateAddKeybind(existingButtonOrEtherealDescriptor, keybindButtonDescriptor, state, stateIndex, currentSceneName)
        end
        state.individualButtons[keybindButtonDescriptor.keybind] = keybindButtonDescriptor
        keybindButtonDescriptor.addedForSceneName = currentSceneName
    end

    function ZO_KeybindStrip:RegisterKeybindButtonOrEtherealDescriptorInternal(buttonOrEtherealDescriptor)
        local descriptor = GetDescriptorFromButton(buttonOrEtherealDescriptor)
        self.keybinds[descriptor.keybind] = buttonOrEtherealDescriptor
        if descriptor.gamepadPreferredKeybind then
            self.keybindsByGamepadPreferredKeybind[descriptor.gamepadPreferredKeybind] = buttonOrEtherealDescriptor
        end
    end

    function ZO_KeybindStrip:AddKeybindButton(keybindButtonDescriptor, stateIndex)
        local currentSceneName = ""
        if SCENE_MANAGER then
            local currentScene = SCENE_MANAGER:GetCurrentScene()
            if currentScene then
                currentSceneName = currentScene:GetName()
            end
        end

        local state = self:GetKeybindState(stateIndex)
        if state then
            return self:AddKeybindButtonStack(keybindButtonDescriptor, state, stateIndex, currentSceneName)
        end

        local existingButtonOrEtherealDescriptor = self.keybinds[keybindButtonDescriptor.keybind]
        if existingButtonOrEtherealDescriptor then
            self:HandleDuplicateAddKeybind(existingButtonOrEtherealDescriptor, keybindButtonDescriptor, state, stateIndex, currentSceneName)
        end

        if keybindButtonDescriptor.gamepadPreferredKeybind then
            local existingButtonOrEtherealDescriptor = self.keybindsByGamepadPreferredKeybind[keybindButtonDescriptor.gamepadPreferredKeybind]
            if existingButtonOrEtherealDescriptor then
                self:HandleDuplicateAddKeybind(existingButtonOrEtherealDescriptor, keybindButtonDescriptor, state, stateIndex, currentSceneName)
            end
            -- edge case: if a keybind registers only using the normal pathway, but
            -- we shadow it here, there is no way to press that keybind. so let's
            -- prevent that using the normal duplicate keybind handling
            local existingButtonOrEtherealDescriptor = self.keybinds[keybindButtonDescriptor.gamepadPreferredKeybind]
            if existingButtonOrEtherealDescriptor and GetDescriptorFromButton(existingButtonOrEtherealDescriptor).gamepadPreferredKeybind == nil then
                self:HandleDuplicateAddKeybind(existingButtonOrEtherealDescriptor, keybindButtonDescriptor, state, stateIndex, currentSceneName)
            end
        end

        keybindButtonDescriptor.addedForSceneName = currentSceneName

        if GetValueFromRawOrFunction(keybindButtonDescriptor, "ethereal") then
            self:RegisterKeybindButtonOrEtherealDescriptorInternal(keybindButtonDescriptor)
        else
            local button, key = self.keybindButtonPool:AcquireObject()
            button.keybindButtonDescriptor = keybindButtonDescriptor
            button.key = key

            self.insertionId = (self.insertionId or 0) + 1
            button.insertionOrder = self.insertionId

            self:RegisterKeybindButtonOrEtherealDescriptorInternal(button)

            if not self.batchUpdating then
                -- clear this out in case it was previously in a group
                keybindButtonDescriptor.keybindButtonGroupDescriptor = nil
            end

            table.insert(self.keybindButtons, button)

            if not self.batchUpdating then
                self:SetUpButton(button)
                self:UpdateAnchors()
            end
            return button
        end
    end
end

local function CompareKeybindButtonDescriptor(first, second)
    return  (first == nil) or (second == nil) or
            ((first.keybind == second.keybind) and
            (first.name == second.name) and
            (first.callback == second.callback))
end

function ZO_KeybindStrip:RemoveKeybindButton(keybindButtonDescriptor, stateIndex)
    local state = self:GetKeybindState(stateIndex)
    if state then
        return RemoveKeybindButtonStack(keybindButtonDescriptor, state)
    end

    local buttonOrEtherealDescriptor = self.keybinds[keybindButtonDescriptor.keybind]     
    if buttonOrEtherealDescriptor and CompareKeybindButtonDescriptor(buttonOrEtherealDescriptor.keybindButtonDescriptor, keybindButtonDescriptor) then
        self.keybinds[keybindButtonDescriptor.keybind] = nil
        if keybindButtonDescriptor.gamepadPreferredKeybind then
            self.keybindsByGamepadPreferredKeybind[keybindButtonDescriptor.gamepadPreferredKeybind] = nil
        end

        keybindButtonDescriptor.addedForSceneName = nil

        for i, cooldownKeybindDescriptor in ipairs(self.cooldownKeybinds) do
            if cooldownKeybindDescriptor == keybindButtonDescriptor and not cooldownKeybindDescriptor.shouldCooldownPersist then
                table.remove(self.cooldownKeybinds, i)
                cooldownKeybindDescriptor.cooldown = nil
                cooldownKeybindDescriptor.cooldownStart = nil
                break
            end
        end

        if type(buttonOrEtherealDescriptor) == "userdata" then
            local button = buttonOrEtherealDescriptor
            self.keybindButtonPool:ReleaseObject(button.key)
            local buttonIndex = ZO_IndexOfElementInNumericallyIndexedTable(self.keybindButtons, button)
            table.remove(self.keybindButtons, buttonIndex)

            if not self.batchUpdating then
                self:UpdateAnchors()
            end
        end
    end
end

function ZO_KeybindStrip:UpdateKeybindButton(keybindButtonDescriptor, stateIndex)
    local state = self:GetKeybindState(stateIndex)
    if state then
        return UpdateKeybindButtonStack(keybindButtonDescriptor, state)
    end

    local buttonOrEtherealDescriptor = self.keybinds[keybindButtonDescriptor.keybind]
    if type(buttonOrEtherealDescriptor) == "userdata" then
        local existingButton = buttonOrEtherealDescriptor
        if existingButton.keybindButtonDescriptor == keybindButtonDescriptor and not GetValueFromRawOrFunction(keybindButtonDescriptor, "ethereal") then
            local UPDATE_ONLY = true
            self:SetUpButton(existingButton, UPDATE_ONLY)
            if not self.batchUpdating then
                self:UpdateAnchors()
            end
        else
            self:RemoveKeybindButton(existingButton.keybindButtonDescriptor)
            self:AddKeybindButton(keybindButtonDescriptor)
        end
    elseif buttonOrEtherealDescriptor then
        local existingButtonDescriptor = buttonOrEtherealDescriptor
        if keybindButtonDescriptor ~= existingButtonDescriptor or not GetValueFromRawOrFunction(keybindButtonDescriptor, "ethereal") then
            self:RemoveKeybindButton(existingButtonDescriptor)
            self:AddKeybindButton(keybindButtonDescriptor)
        end
    end
end

local function HasKeybindButtonStack(keybindButtonDescriptor, state)
    return state.individualButtons[keybindButtonDescriptor.keybind] ~= nil
end

function ZO_KeybindStrip:HasKeybindButton(keybindButtonDescriptor, stateIndex)
    local state = self:GetKeybindState(stateIndex)
    if state then
        return HasKeybindButtonStack(keybindButtonDescriptor, state)
    end
    return self.keybinds[keybindButtonDescriptor.keybind] ~= nil
end

local function HasKeybindButtonGroupStack(keybindButtonGroupDescriptor, state)
    return state.keybindGroups[keybindButtonGroupDescriptor] ~= nil
end

function ZO_KeybindStrip:HasKeybindButtonGroup(keybindButtonGroupDescriptor, stateIndex)
    local state = self:GetKeybindState(stateIndex)
    if state then
        return HasKeybindButtonGroupStack(keybindButtonGroupDescriptor, state)
    end
    return self.keybindGroups[keybindButtonGroupDescriptor] ~= nil
end

--[[

An example keybind button group descriptor

local keybindButtonGroup = {
    -- Anything added here will be inherited by individual descriptors, for example adding an alignment of left here will cause individial descriptors to all be aligned left
    -- unless they specify their own alignment
    alignment = KEYBIND_STRIP_ALIGN_LEFT,
    {
        name = "Exit", -- or function that returns a name
        keybind = "UI_SHORTCUT_PRIMARY",
        callback = function(up) DoSomething() end, -- First and only parameter is whether its a key up or down, ups will only be sent if handlesKeyUp flag is set
        handlesKeyUp = true, -- indicates that the callback would like to be informed of key ups in addition to downs, by default only downs are sent
    },

    {
        alignment = KEYBIND_STRIP_ALIGN_CENTER, -- override the alignment set un the group
        name = "Use", -- or function that returns a name
        keybind = "UI_SHORTCUT_SECONDARY",
        callback = function(up) UseSomething() end, -- First and only parameter is whether its a key up or down, ups will only be sent if handlesKeyUp flag is set
        visible = function(descriptor) return IsUsePossible(descriptor.something) end,
        sound = SOUNDS.POSITIVE_CLICK, -- An audio hook that plays when the button is pressed
    },
}

]]--

local function AddKeybindButtonGroupStack(keybindButtonGroupDescriptor, state)
    if not state.keybindGroups[keybindButtonGroupDescriptor] then
        state.keybindGroups[keybindButtonGroupDescriptor] = keybindButtonGroupDescriptor
        return true
    end

    return false
end

function ZO_KeybindStrip:AddKeybindButtonGroup(keybindButtonGroupDescriptor, stateIndex)
    local state = self:GetKeybindState(stateIndex)
    if state then
        return AddKeybindButtonGroupStack(keybindButtonGroupDescriptor, state)
    end

    if not self.keybindGroups[keybindButtonGroupDescriptor] then
        self.batchUpdating = true

        self.keybindGroups[keybindButtonGroupDescriptor] = keybindButtonGroupDescriptor

        for i, keybindButtonDescriptor in ipairs(keybindButtonGroupDescriptor) do
            keybindButtonDescriptor.keybindButtonGroupDescriptor = keybindButtonGroupDescriptor
            local button = self:AddKeybindButton(keybindButtonDescriptor, stateIndex)
            if button then
                self:SetUpButton(button)
            end
        end

        self:UpdateAnchors()

        self.batchUpdating = false
        return true
    end
    return false
end

function ZO_KeybindStrip:RemoveKeybindButtonGroup(keybindButtonGroupDescriptor, stateIndex)
    local state = self:GetKeybindState(stateIndex)
    if state then
        return ZO_KeybindStrip.RemoveKeybindButtonGroupStack(keybindButtonGroupDescriptor, state)
    end

    if self.keybindGroups[keybindButtonGroupDescriptor] then
        self.batchUpdating = true

        for i, keybindButtonDescriptor in ipairs(keybindButtonGroupDescriptor) do
            self:RemoveKeybindButton(keybindButtonDescriptor, stateIndex)
            keybindButtonDescriptor.keybindButtonGroupDescriptor = nil
        end

        self.keybindGroups[keybindButtonGroupDescriptor] = nil

        self:UpdateAnchors()

        self.batchUpdating = false
        return true
    end
    return false
end

function ZO_KeybindStrip:UpdateCurrentKeybindButtonGroups(stateIndex)
    local state = self:GetKeybindState(stateIndex)
    if state then
        return UpdateCurrentKeybindButtonGroupsStack(state)
    end

    for keybindButtonDescriptor, group in pairs(self.keybindGroups) do
        self:UpdateKeybindButtonGroup(keybindButtonDescriptor, stateIndex)
    end
end

function ZO_KeybindStrip:UpdateKeybindButtonGroup(keybindButtonGroupDescriptor, stateIndex)
    local state = self:GetKeybindState(stateIndex)
    if state then
        return UpdateKeybindButtonGroupStack(keybindButtonGroupDescriptor, state)
    end

    if self.keybindGroups[keybindButtonGroupDescriptor] then
        self.batchUpdating = true

        for i, keybindButtonDescriptor in ipairs(keybindButtonGroupDescriptor) do
            self:UpdateKeybindButton(keybindButtonDescriptor, stateIndex)
        end

        self:UpdateAnchors()

        self.batchUpdating = false
        return true
    end
    return false
end

function ZO_KeybindStrip:FilterSceneHiding(keybindButtonDescriptor)
    if keybindButtonDescriptor.disabledDuringSceneHiding then
        local currentScene = SCENE_MANAGER:GetCurrentScene()
        if currentScene and currentScene:GetState() == SCENE_HIDING then
            return false
        end
    end

    return true
end

function ZO_KeybindStrip:GetButtonOrEtherealDescriptorForKeybind(keybind)
    if IsInGamepadPreferredMode() then
        -- in the case of duplicates, prefer the gamepad key
        return self.keybindsByGamepadPreferredKeybind[keybind] or self.keybinds[keybind]
    else
        -- in the case of duplicates, prefer the keyboard key
        return self.keybinds[keybind] or self.keybindsByGamepadPreferredKeybind[keybind]
    end
end

function ZO_KeybindStrip:TryHandlingKeybindDown(keybind)
    if not self.control:IsHidden() then
        local buttonOrEtherealDescriptor = self:GetButtonOrEtherealDescriptorForKeybind(keybind)
        if buttonOrEtherealDescriptor and (not buttonOrEtherealDescriptor.IsControlHidden or not buttonOrEtherealDescriptor:IsControlHidden()) then
            local keybindButtonDescriptor = GetDescriptorFromButton(buttonOrEtherealDescriptor)
            local enabled, disabledAlertText, disabledAlertType = GetValueFromRawOrFunction(keybindButtonDescriptor, "enabled")
            local cooldown = GetValueFromRawOrFunction(keybindButtonDescriptor, "cooldown")
            if cooldown then
                enabled = false
            end
            if enabled ~= false then
                local keybindHandled = nil
                if self:FilterSceneHiding(keybindButtonDescriptor) then
                    if keybindButtonDescriptor.callback then
                        ClearMenu()
                        keybindHandled = keybindButtonDescriptor.callback(DOWN)
                        keybindButtonDescriptor.handledDown = true

                        local sound = GetValueFromRawOrFunction(keybindButtonDescriptor, "sound")
                        if sound then
                            PlaySound(sound)
                        end
                    end
                end
                return keybindHandled or keybindHandled == nil --nil is considered true in this case to ensure backwards compatability
            elseif disabledAlertText then
                local alertText = disabledAlertText
                if type(disabledAlertText) == "function" then
                    alertText = disabledAlertText()
                end

                if disabledAlertType == KEYBIND_STRIP_DISABLED_DIALOG then
                    ZO_Dialogs_ShowPlatformDialog("KEYBIND_STRIP_DISABLED_DIALOG", nil, { mainTextParams = { alertText }})
                else
                    if ZO_REMOTE_SCENE_CHANGE_ORIGIN == SCENE_MANAGER_MESSAGE_ORIGIN_INTERNAL then
                        RequestAlert(UI_ALERT_CATEGORY_ALERT, SOUNDS.GENERAL_ALERT_ERROR, alertText)
                    elseif ZO_REMOTE_SCENE_CHANGE_ORIGIN == SCENE_MANAGER_MESSAGE_ORIGIN_INGAME then
                        ZO_Alert(UI_ALERT_CATEGORY_ALERT, SOUNDS.GENERAL_ALERT_ERROR, alertText)
                    end
                end
            end
        end
    end
    return false
end

function ZO_KeybindStrip:TryHandlingKeybindUp(keybind)
    if not self.control:IsHidden() then
        local buttonOrEtherealDescriptor = self:GetButtonOrEtherealDescriptorForKeybind(keybind)
        if buttonOrEtherealDescriptor and (not buttonOrEtherealDescriptor.IsControlHidden or not buttonOrEtherealDescriptor:IsControlHidden()) then
            local keybindButtonDescriptor = GetDescriptorFromButton(buttonOrEtherealDescriptor)
            local enabled = GetValueFromRawOrFunction(buttonOrEtherealDescriptor, "enabled")
            local cooldown = GetValueFromRawOrFunction(buttonOrEtherealDescriptor, "cooldown")
            if cooldown then
                enabled = false
            end
            local handledPreviousDown = keybindButtonDescriptor.handledDown
            keybindButtonDescriptor.handledDown = nil
            if enabled ~= false or handledPreviousDown then
                if keybindButtonDescriptor.handlesKeyUp or keybindButtonDescriptor.keybindButtonGroupDescriptor and keybindButtonDescriptor.keybindButtonGroupDescriptor.handlesKeyUp then
                    local keybindHandled = nil
                    if self:FilterSceneHiding(keybindButtonDescriptor) then
                        if keybindButtonDescriptor.callback then
                            ClearMenu()
                            keybindHandled = keybindButtonDescriptor.callback(UP)
                        end
                    end
                    return keybindHandled or keybindHandled == nil --nil is considered true in this case to ensure backwards compatability
                end
            end
        end
    end
    return false
end

function ZO_KeybindStrip:TriggerCooldown(keybindButtonDescriptor, duration, stateIndex, shouldCooldownPersist)
    if type(duration) == "function" then
        keybindButtonDescriptor.cooldown = duration() / 1000
        keybindButtonDescriptor.remainingFunction = duration
    else
        keybindButtonDescriptor.cooldown = duration / 1000
        keybindButtonDescriptor.cooldownStart = GetFrameTimeMilliseconds() / 1000
        keybindButtonDescriptor.shouldCooldownPersist = shouldCooldownPersist
    end

    if self.keybinds[keybindButtonDescriptor.keybind] and self.keybinds[keybindButtonDescriptor.keybind].keybindButtonDescriptor == keybindButtonDescriptor then
        self:UpdateKeybindButton(keybindButtonDescriptor, stateIndex)
    end

    --Check for duplicates
    for i = 1, #self.cooldownKeybinds do
        local descriptor = self.cooldownKeybinds[i]
        if descriptor == keybindButtonDescriptor then
            return
        end
    end

    table.insert(self.cooldownKeybinds, keybindButtonDescriptor)
end

function ZO_KeybindStrip:UpdateCooldowns(time)
    for i = #self.cooldownKeybinds, 1, -1 do
        local descriptor = self.cooldownKeybinds[i]
        local newCooldown
        if descriptor.remainingFunction then
            newCooldown = descriptor.remainingFunction()
        else
            local cooldownStart = descriptor.cooldownStart
            local difference = time - cooldownStart
            newCooldown = descriptor.cooldown - difference
        end

        --Only update for changes in the seconds count
        local oldCeiling = zo_ceil(descriptor.cooldown)
        local newCeiling = zo_ceil(newCooldown)

        if oldCeiling ~= newCeiling then
            descriptor.cooldownStart = time
            descriptor.cooldown = newCooldown
            if descriptor.cooldown <= 0 then
                descriptor.cooldown = nil
                descriptor.cooldownStart = nil
                descriptor.shouldCooldownPersist = nil
                table.remove(self.cooldownKeybinds, i)
            end

            local activeDescriptor = self.keybinds[descriptor.keybind]
            if activeDescriptor then
                if not GetValueFromRawOrFunction(activeDescriptor, "ethereal") then
                    activeDescriptor = activeDescriptor.keybindButtonDescriptor
                end
                if descriptor == activeDescriptor then
                    self:UpdateKeybindButton(descriptor, self:GetTopKeybindStateIndex())
                end
            end
        elseif descriptor.cooldown <= 0 then
            descriptor.cooldown = nil
            descriptor.cooldownStart = nil
            descriptor.shouldCooldownPersist = nil
            table.remove(self.cooldownKeybinds, i)
        end
    end
end

function ZO_KeybindStrip:SetHidden(hidden)
    self.control:SetHidden(hidden)
end

--[[
    A style table provides font and other information to describe the look of the keybind buttons

    An example descriptor:

    {
        nameFont = "ZoFontKeybindStripDescription",
        nameFontColor = ZO_NORMAL_TEXT,
        keyFont = "ZoFontKeybindStripKey",
        modifyTextType = MODIFY_TEXT_TYPE_UPPERCASE,
        alwaysPreferGamepadMode = false,
        resizeToFitPadding = 40,
        yAnchorOffset = 0,
        leftAnchorRelativeToControl = GuiRoot,
        leftAnchorRelativePoint = LEFT,
        leftAnchorOffset = 0,
        centerAnchorOffset = 0,
        rightAnchorOffset = 0,
        rightAnchorRelativeToControl = GuiRoot,
        rightAnchorRelativePoint = RIGHT,
        drawTier = DT_HIGH,
        drawLevel = ZO_HIGH_TIER_GAMEPAD_KEYBIND_STRIP,
        backgroundDrawTier = DT_HIGH,
        backgroundDrawLevel = ZO_HIGH_TIER_GAMEPAD_KEYBIND_STRIP_BG,
    }
]]

function ZO_KeybindStrip:SetStyle(styleInfo)
    if self.styleInfo ~= styleInfo then
        self.styleInfo = styleInfo

        for keybind, buttonOrEtherealDescriptor in pairs(self.keybinds) do
            if type(buttonOrEtherealDescriptor) == "userdata" then
                self:SetUpButton(buttonOrEtherealDescriptor)
            end
        end
        self:UpdateAnchors()

        self:SetDrawOrder(styleInfo.drawTier, styleInfo.drawLayer, styleInfo.drawLevel)
        self:SetBackgroundStyle(styleInfo)

        if self.onStyleChanged then
            self.onStyleChanged(self, styleInfo)
        end
    end
end

function ZO_KeybindStrip:SetBackgroundStyle(styleInfo)
    -- even though we are only refreshing the background style, we are still changing the style overall
    -- store the potential style change so that future calls to SetStyle can refresh everything appropriately
    if self.styleInfo ~= styleInfo then
        self.styleInfo = styleInfo
    end

    self:SetBackgroundDrawOrder(styleInfo.backgroundDrawTier, styleInfo.backgroundDrawLayer, styleInfo.backgroundDrawLevel)
end

function ZO_KeybindStrip:GetStyle()
    return self.styleInfo
end 

function ZO_KeybindStrip:SetOnStyleChangedCallback(onStyleChanged)
    self.onStyleChanged = onStyleChanged
end

-- implementation functions below
function ZO_KeybindStrip:SetupButtonStyle(button, styleInfo)
    if styleInfo then
        if styleInfo.nameFont then
            button:SetNameFont(styleInfo.nameFont)
        end

        if styleInfo.nameFontColor then
            button:SetNormalTextColor(styleInfo.nameFontColor)
        end

        if styleInfo.keyFont then
            button:SetKeyFont(styleInfo.keyFont)
        end

        if styleInfo.resizeToFitPadding then
            button:SetResizeToFitPadding(styleInfo.resizeToFitPadding)
        end

        if styleInfo.modifyTextType then
            button.nameLabel:SetModifyTextType(styleInfo.modifyTextType)
        end

        return styleInfo.alwaysPreferGamepadMode
    end
    return nil
end

do
    local function IsVisible(keybindButtonDescriptor)
        local visibilityFunction = keybindButtonDescriptor.visible or keybindButtonDescriptor.keybindButtonGroupDescriptor and keybindButtonDescriptor.keybindButtonGroupDescriptor.visible
        return not visibilityFunction or visibilityFunction(keybindButtonDescriptor, keybindButtonDescriptor.keybindButtonGroupDescriptor)
    end

    function ZO_KeybindStrip:SetUpButton(button, updateOnly)
        local keybindButtonDescriptor = button.keybindButtonDescriptor

        local isVisible = IsVisible(button.keybindButtonDescriptor)
        local wasVisible = not button:IsHidden()
        local customKeybindControl = GetValueFromRawOrFunction(keybindButtonDescriptor, "customKeybindControl")
        if isVisible then
            if customKeybindControl then
                customKeybindControl:SetHidden(false)
                customKeybindControl:SetParent(button)
                customKeybindControl:ClearAnchors()
                customKeybindControl:SetAnchor(RIGHT, button.keyLabel, RIGHT)
                button.keyLabel:SetHidden(true)
                button.customKeybindControl = customKeybindControl
                button:SetResizeToFitPadding(0) -- This should be handled on the custom control
            else
                button.keyLabel:SetHidden(false)
            end

            local keybind = keybindButtonDescriptor.keybind
            local gamepadPreferredKeybind = keybindButtonDescriptor.gamepadPreferredKeybind
            local keybindButtonGroupDescriptor = keybindButtonDescriptor.keybindButtonGroupDescriptor
            
            if keybindButtonGroupDescriptor then
                if not keybind then
                    keybind = keybindButtonGroupDescriptor.keybind
                end

                if not gamepadPreferredKeybind then
                    gamepadPreferredKeybind = keybindButtonGroupDescriptor.gamepadPreferredKeybind
                end
            end

            local buttonKeybindChanging = button:GetKeybind() ~= keybind
            local suppressUpdate = (updateOnly and isVisible == wasVisible)
            -- updateOnly is used only when we are trying to update keybinds from UpdateKeybindButton so we know that this setup is coming from an update

            local alwaysPreferGamepadMode = self:SetupButtonStyle(button, self.styleInfo)

            if not suppressUpdate or buttonKeybindChanging then
                local DEFAULT_SHOW_UNBOUND = nil
                button:SetKeybind(keybind, DEFAULT_SHOW_UNBOUND, gamepadPreferredKeybind, alwaysPreferGamepadMode)
            end

            local enabled = GetValueFromRawOrFunction(keybindButtonDescriptor, "enabled")
            if enabled == nil then
                enabled = true
            end
            local cooldown = GetValueFromRawOrFunction(keybindButtonDescriptor, "cooldown")
            if cooldown and cooldown > 0 then
                enabled = false
            end
            button:SetEnabled(enabled)
            -- if we have a custom keybind control then attempt to disable it as well to match
            if customKeybindControl and customKeybindControl.SetEnabled then
                customKeybindControl:SetEnabled(enabled)
            end

            local name = GetValueFromRawOrFunction(keybindButtonDescriptor, "name")
            if cooldown and cooldown > 0 then
                local seconds = zo_ceil(cooldown)
                name = zo_strformat(SI_BINDING_NAME_COOLDOWN_FORMAT, name, seconds)
            end
            button.nameLabel:SetText(name)
            local iconPath = GetValueFromRawOrFunction(keybindButtonDescriptor, "icon")
            if iconPath and iconPath ~= "" then
                if not button.icon then
                    button.icon = CreateControl("$(parent)Icon", button, CT_TEXTURE)
                    button.icon:SetDimensions(20, 20)
                    button.icon:SetAnchor(LEFT, button.nameLabel, RIGHT, 0, -5)
                end
                button.icon:SetTexture(iconPath)
                button.icon:SetHidden(false)
            else
                if button.icon then
                    button.icon:SetHidden(true)
                end
            end
        else
            if customKeybindControl then
                customKeybindControl:SetHidden(true)
            end
        end

        button:SetHidden(not isVisible)
    end

    local function KeyboardSort(buttonLeft, buttonRight)
        local leftOrder = GetValueFromRawOrFunction(buttonLeft.keybindButtonDescriptor, "order") or 0
        local rightOrder = GetValueFromRawOrFunction(buttonRight.keybindButtonDescriptor, "order") or 0

        if leftOrder == rightOrder then
            return buttonLeft.insertionOrder < buttonRight.insertionOrder
        end
        return leftOrder < rightOrder
    end

    local GAMEPAD_BUTTON_ORDER =
    {
        UI_SHORTCUT_EXIT = 0,
        UI_SHORTCUT_PRIMARY = 1,
        UI_SHORTCUT_NEGATIVE = 2,
        UI_SHORTCUT_SECONDARY = 3,
        UI_SHORTCUT_TERTIARY = 4,
        UI_SHORTCUT_QUATERNARY = 5,
        UI_SHORTCUT_QUINARY = 6,
        UI_SHORTCUT_LEFT_STICK = 7,
        UI_SHORTCUT_RIGHT_STICK = 8,
        UI_SHORTCUT_LEFT_TRIGGER = 9,
        UI_SHORTCUT_RIGHT_TRIGGER = 10,

        DIALOG_PRIMARY = 1,
        DIALOG_NEGATIVE = 2,
        DIALOG_SECONDARY = 3,
        DIALOG_TERTIARY = 4,
        DIALOG_RESET = 5,
    }

    local function GetGamepadOrderFromKeybindDescriptor(keybindDescriptor)
        local order = GetValueFromRawOrFunction(keybindDescriptor, "gamepadOrder")
        if order then
            return order
        end
        order = GAMEPAD_BUTTON_ORDER[keybindDescriptor.gamepadPreferredKeybind or keybindDescriptor.keybind]
        if order then
            return order
        end
        order = GetValueFromRawOrFunction(keybindDescriptor, "order")
        if order then
            return order
        end
        return 0
    end

    local function GamepadSort(buttonLeft, buttonRight)
        local leftKeybindDescriptor = buttonLeft.keybindButtonDescriptor
        local rightKeybindDescriptor = buttonRight.keybindButtonDescriptor

        local leftOrder = GetGamepadOrderFromKeybindDescriptor(leftKeybindDescriptor)
        local rightOrder = GetGamepadOrderFromKeybindDescriptor(rightKeybindDescriptor)

        if leftOrder == rightOrder then
            return buttonLeft.insertionOrder < buttonRight.insertionOrder
        end
        return leftOrder < rightOrder
    end

    local function EtherealSort(leftKeybindDescriptor, rightKeybindDescriptor)
        local leftOrder = leftKeybindDescriptor.etherealNarrationOrder or 0
        local rightOrder = rightKeybindDescriptor.etherealNarrationOrder or 0
        if leftOrder == rightOrder then
            return leftKeybindDescriptor.keybind < rightKeybindDescriptor.keybind
        else
            return leftOrder < rightOrder
        end
    end

    local function GetKeybindButtonDescriptorNarrationInfo(keybindButtonDescriptor)
        local enabled = GetValueFromRawOrFunction(keybindButtonDescriptor, "enabled")
        if enabled == nil then
            enabled = true
        end

        --Any additional info we end up needing for narration should go here
        local data = 
        {
            name = GetValueFromRawOrFunction(keybindButtonDescriptor, "narrationOverrideName") or GetValueFromRawOrFunction(keybindButtonDescriptor, "name"),
            keybindName = ZO_Keybindings_GetHighestPriorityNarrationStringFromAction(keybindButtonDescriptor.keybind) or GetString(SI_ACTION_IS_NOT_BOUND),
            enabled = enabled,
        }

        return data
    end

    function ZO_KeybindStrip:GetOrderedNarratableKeybindButtonInfo()
        local keybinds = {}
        --Do not include anything if the keybind strip is currently hidden
        if not self.control:IsHidden() then
            local buttonsByAlignment =
            {
                [KEYBIND_STRIP_ALIGN_LEFT] = {},
                [KEYBIND_STRIP_ALIGN_CENTER] = {},
                [KEYBIND_STRIP_ALIGN_RIGHT] = {},
            }

            for _, button in ipairs(self.keybindButtons) do
                local isVisible = IsVisible(button.keybindButtonDescriptor)
                if isVisible then
                    local alignment = GetValueFromRawOrFunction(button.keybindButtonDescriptor, "alignment") or KEYBIND_STRIP_ALIGN_RIGHT
                    table.insert(buttonsByAlignment[alignment], button)
                end
            end

            for alignment, buttons in pairs(buttonsByAlignment) do
                if IsInGamepadPreferredMode() then
                    table.sort(buttons, GamepadSort)
                else
                    table.sort(buttons, KeyboardSort)
                end
            end

            for _, button in ipairs(buttonsByAlignment[KEYBIND_STRIP_ALIGN_LEFT]) do
                table.insert(keybinds, GetKeybindButtonDescriptorNarrationInfo(button.keybindButtonDescriptor))
            end

            for _, button in ipairs(buttonsByAlignment[KEYBIND_STRIP_ALIGN_CENTER]) do
                table.insert(keybinds, GetKeybindButtonDescriptorNarrationInfo(button.keybindButtonDescriptor))
            end

            --Iterate backwards through the right aligned keybinds so they are ordered left to right visually
            for _, button in ZO_NumericallyIndexedTableReverseIterator(buttonsByAlignment[KEYBIND_STRIP_ALIGN_RIGHT]) do
                table.insert(keybinds, GetKeybindButtonDescriptorNarrationInfo(button.keybindButtonDescriptor))
            end

            local etherealDescriptors = {}
            --Iterate through ethereal keybinds to see if we need to narrate any
            for keybind, buttonOrEtherealDescriptor in pairs(self.keybinds) do
                if type(buttonOrEtherealDescriptor) ~= "userdata" then
                    --If any ethereal descriptor are marked as something we want to narrate, include them here
                    if GetValueFromRawOrFunction(buttonOrEtherealDescriptor, "ethereal") then
                        local narrateEthereal = buttonOrEtherealDescriptor.narrateEthereal
                        if type(narrateEthereal) == "function" then
                            narrateEthereal = narrateEthereal()
                        end

                        if narrateEthereal then
                            table.insert(etherealDescriptors, buttonOrEtherealDescriptor)
                        end
                    end
                end
            end

            table.sort(etherealDescriptors, EtherealSort)

            for _, descriptor in ipairs(etherealDescriptors) do
                table.insert(keybinds, GetKeybindButtonDescriptorNarrationInfo(descriptor))
            end
        end

        return keybinds
    end

    function ZO_KeybindStrip:UpdateAnchorsInternal(anchorTable, parent, initialConstrainXAnchor, initialConstrainYAnchor, subsequentAnchor)
        if IsInGamepadPreferredMode() then
            table.sort(anchorTable, GamepadSort)
        else
            table.sort(anchorTable, KeyboardSort)
        end
        for i, button in ipairs(anchorTable) do
            button:ClearAnchors()
        end

        local prevButton
        for i, button in ipairs(anchorTable) do
            local isVisible = IsVisible(button.keybindButtonDescriptor)
            local wasVisible = not button:IsHidden()
            if isVisible and not wasVisible then
                local UPDATE_ONLY = true
                self:SetUpButton(button, UPDATE_ONLY)
            end

            if isVisible then
                button:SetParent(parent)
                if prevButton then
                    subsequentAnchor:SetTarget(prevButton)
                    subsequentAnchor:AddToControl(button)
                else
                    initialConstrainXAnchor:AddToControl(button)
                    initialConstrainYAnchor:AddToControl(button)
                end
                prevButton = button
            end
        end
    end

    function ZO_KeybindStrip:UpdateAnchors()
        local hasCustomStyle = self.styleInfo ~= nil
        local yOffset = hasCustomStyle and self.styleInfo.yAnchorOffset or 0

        local firstAnchor = ZO_Anchor:New()
        firstAnchor:SetFromControlAnchor(self.control, 0)

        local secondAnchor = ZO_Anchor:New()
        secondAnchor:SetFromControlAnchor(self.control, 1)

        self.control:ClearAnchors()

        firstAnchor:SetOffsets(nil, yOffset)
        secondAnchor:SetOffsets(nil, yOffset)

        firstAnchor:AddToControl(self.control)
        secondAnchor:AddToControl(self.control)

        -- collect button alignments
        local buttonsByAlignment =
        {
            [KEYBIND_STRIP_ALIGN_LEFT] = {},
            [KEYBIND_STRIP_ALIGN_CENTER] = {},
            [KEYBIND_STRIP_ALIGN_RIGHT] = {},
        }
        for _, button in ipairs(self.keybindButtons) do
            local alignment = GetValueFromRawOrFunction(button.keybindButtonDescriptor, "alignment") or KEYBIND_STRIP_ALIGN_RIGHT
            table.insert(buttonsByAlignment[alignment], button)
        end

        -- layout the KEYBIND_STRIP_ALIGN_LEFT buttons
        local leftAnchorRelativeToControl = hasCustomStyle and self.styleInfo.leftAnchorRelativeToControl or nil
        local leftAnchorRelativePoint = hasCustomStyle and self.styleInfo.leftAnchorRelativePoint or LEFT
        local leftAnchorOffsetX = hasCustomStyle and self.styleInfo.leftAnchorOffset or 0
        local leftInitialConstrainXAnchor = ZO_Anchor:New(LEFT, leftAnchorRelativeToControl, leftAnchorRelativePoint, leftAnchorOffsetX, 0, ANCHOR_CONSTRAINS_X)
        local leftInitialConstrainYAnchor = ZO_Anchor:New(LEFT, nil, LEFT, 0, 0, ANCHOR_CONSTRAINS_Y)
        local leftSubsequentAnchor = ZO_Anchor:New(LEFT, nil, RIGHT)

        self:UpdateAnchorsInternal(buttonsByAlignment[KEYBIND_STRIP_ALIGN_LEFT], self.control, leftInitialConstrainXAnchor, leftInitialConstrainYAnchor, leftSubsequentAnchor)

        -- layout the KEYBIND_STRIP_ALIGN_RIGHT buttons
        local rightAnchorRelativeToControl = hasCustomStyle and self.styleInfo.rightAnchorRelativeToControl or nil
        local rightAnchorRelativePoint = hasCustomStyle and self.styleInfo.rightAnchorRelativePoint or RIGHT
        local rightAnchorOffsetX = hasCustomStyle and self.styleInfo.rightAnchorOffset or 0
        local rightInitialConstrainXAnchor = ZO_Anchor:New(RIGHT, rightAnchorRelativeToControl, rightAnchorRelativePoint, rightAnchorOffsetX, 0, ANCHOR_CONSTRAINS_X)
        local rightInitialConstrainYAnchor = ZO_Anchor:New(RIGHT, nil, RIGHT, 0, 0, ANCHOR_CONSTRAINS_Y)
        local rightSubsequentAnchor = ZO_Anchor:New(RIGHT, nil, LEFT)

        self:UpdateAnchorsInternal(buttonsByAlignment[KEYBIND_STRIP_ALIGN_RIGHT], self.control, rightInitialConstrainXAnchor, rightInitialConstrainYAnchor, rightSubsequentAnchor)

        -- layout the KEYBIND_STRIP_ALIGN_CENTER buttons
        local centerAnchorOffsetX = hasCustomStyle and self.styleInfo.centerAnchorOffset or 0
        local centerInitialConstrainXAnchor = ZO_Anchor:New(LEFT, nil, LEFT, centerAnchorOffsetX, 0, ANCHOR_CONSTRAINS_X)
        local centerInitialConstrainYAnchor = ZO_Anchor:New(LEFT, nil, LEFT, 0, 0, ANCHOR_CONSTRAINS_Y)
        local centerSubsequentAnchor = ZO_Anchor:New(LEFT, nil, RIGHT)

        self:UpdateAnchorsInternal(buttonsByAlignment[KEYBIND_STRIP_ALIGN_CENTER], self.centerParent, centerInitialConstrainXAnchor, centerInitialConstrainYAnchor, centerSubsequentAnchor)
    end
end
