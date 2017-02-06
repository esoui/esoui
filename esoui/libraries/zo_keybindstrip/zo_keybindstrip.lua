ZO_KeybindStrip = ZO_Object:New()

KEYBIND_STRIP_ALIGN_LEFT = 1
KEYBIND_STRIP_ALIGN_CENTER = 2
KEYBIND_STRIP_ALIGN_RIGHT = 3

KEYBIND_STRIP_DISABLED_ALERT = "alert"
KEYBIND_STRIP_DISABLED_DIALOG = "dialog"

function ZO_KeybindStrip:New(...)
    local keybindStrip = ZO_Object.New(self)
    keybindStrip:Initialize(...)
    return keybindStrip
end

local DOWN = false
local UP = true
function ZO_KeybindStrip:Initialize(control, keybindButtonTemplate, styleInfo)
    self.control = control
    self.centerParent = control:GetNamedChild("CenterParent") or control
    self.keybinds = {}
    self.keybindGroups = {}
    self.cooldownKeybinds = {}
    self.keybindStateStack = {}

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

    self.centerButtons = nil
    self.leftButtons = nil
    self.rightButtons = nil

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
        state.individualButtons[key] = value.keybindButtonDescriptor
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

local function GetDescriptorFromButton(buttonOrEtherealDescriptor)
    if type(buttonOrEtherealDescriptor) == "userdata" then
        return buttonOrEtherealDescriptor.keybindButtonDescriptor
    end
    return buttonOrEtherealDescriptor
end

local function GetValueFromRawOrFunction(keybindButtonDescriptor, key)
    local value
    if keybindButtonDescriptor[key] == nil then
        value = keybindButtonDescriptor.keybindButtonGroupDescriptor and keybindButtonDescriptor.keybindButtonGroupDescriptor[key]
    else
        value = keybindButtonDescriptor[key]
    end

    if type(value) == "function" then
        return value(keybindButtonDescriptor, keybindButtonDescriptor.keybindButtonGroupDescriptor)
    end

    return value
end

local function AddKeybindButtonGroupStack(keybindButtonGroupDescriptor, state)
    if not state.keybindGroups[keybindButtonGroupDescriptor] then
        state.keybindGroups[keybindButtonGroupDescriptor] = keybindButtonGroupDescriptor
        return true
    end

    return false
end

local function AddKeybindButtonStack(keybindButtonDescriptor, state)
    -- Asserting here usually means that a key is already bound (typically because someone forgot to remove a keybinding).
    assert(state.individualButtons[keybindButtonDescriptor.keybind] == nil)
    state.individualButtons[keybindButtonDescriptor.keybind] = keybindButtonDescriptor
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
    customKeybindControl = nil, -- control or a function that returns a control to display instead of the normal keybind label
    callback = function(up) DoSomething() end, -- First and only parameter is whether its a key up or down, ups will only be sent if handlesKeyUp flag is set
    visible = function(descriptor) return IsUsePossible(descriptor.something) end, -- An optional predicate, if present returning true indicates that this descriptor is visible, otherwise it is not
    icon = "IconPath/Icon.dds", -- or a function that returns an icon path, an optional icon to display to the right of the name
    handlesKeyUp = true, -- indicates that the callback would like to be informed of key ups in addition to downs, by default only downs are sent
    disabledDuringSceneHiding = false, -- indicates that the callback is disabled during Scene Hiding, by default it is false
    ethereal = false, -- if true, indicates that the button has no physical presence and will only be considered when a keybind is used, which means that name, alignment, etc properties are ignored. This cannot be a function that returns a value.
}

]]--

function ZO_KeybindStrip:AddKeybindButton(keybindButtonDescriptor, stateIndex)
    local state = self:GetKeybindState(stateIndex)
    if state then
        return AddKeybindButtonStack(keybindButtonDescriptor, state)
    end

    -- Asserting here usually means that a key is already bound (typically because someone forgot to remove a keybinding).
    local currentSceneName = ""
    if SCENE_MANAGER then
        local currentScene = SCENE_MANAGER:GetCurrentScene()
        if currentScene then
            currentSceneName = currentScene:GetName()
        end
    end
    local existingButtonOrEtheralDescriptor = self.keybinds[keybindButtonDescriptor.keybind]
    if existingButtonOrEtheralDescriptor then
        local existingDescriptor = GetDescriptorFromButton(existingButtonOrEtheralDescriptor)
        local existingSceneName = ""
        local existingDescriptorName = ""
        if existingDescriptor then
            --We tried to re-add the same exact button, just return
            if existingDescriptor == keybindButtonDescriptor then
                return
            end

            existingSceneName = existingDescriptor.addedForSceneName
            local descriptorName = GetValueFromRawOrFunction(existingDescriptor, "name")
            if descriptorName then
                existingDescriptorName = descriptorName
            end
        end
        local newDescriptorName = GetValueFromRawOrFunction(keybindButtonDescriptor, "name") or ""
        local context = string.format("Duplicate Keybind: %s. Before: %s (%s). After: %s (%s).", keybindButtonDescriptor.keybind, existingSceneName, existingDescriptorName, currentSceneName, newDescriptorName)
        assert(false, context)
    end

    keybindButtonDescriptor.addedForSceneName = currentSceneName

    if keybindButtonDescriptor.ethereal then
        self.keybinds[keybindButtonDescriptor.keybind] = keybindButtonDescriptor
    else
        local button, key = self.keybindButtonPool:AcquireObject()
        button.keybindButtonDescriptor = keybindButtonDescriptor
        button.key = key

        self.insertionId = (self.insertionId or 0) + 1
        button.insertionOrder = self.insertionId

        self.keybinds[keybindButtonDescriptor.keybind] = button

        if not self.batchUpdating then
            -- clear this out in case it was previously in a group
            keybindButtonDescriptor.keybindButtonGroupDescriptor = nil
        end

        self:AddButtonToAnchors(button)

        if not self.batchUpdating then
            self:SetUpButton(button)
            self:UpdateAnchors()
        end
        return button
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
            self.keybindButtonPool:ReleaseObject(buttonOrEtherealDescriptor.key)

            self:RemoveButtonFromAnchors(buttonOrEtherealDescriptor)

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
    if buttonOrEtherealDescriptor then
        if type(buttonOrEtherealDescriptor) == "userdata" then
            if buttonOrEtherealDescriptor.keybindButtonDescriptor == keybindButtonDescriptor then
                local UPDATE_ONLY = true
                self:SetUpButton(buttonOrEtherealDescriptor, UPDATE_ONLY)
                if not self.batchUpdating then
                    self:UpdateAnchors()
                end
            else
                self:RemoveKeybindButton(buttonOrEtherealDescriptor.keybindButtonDescriptor)
                self:AddKeybindButton(keybindButtonDescriptor)
            end
        else
            if keybindButtonDescriptor ~= buttonOrEtherealDescriptor then
                self:RemoveKeybindButton(buttonOrEtherealDescriptor)
                self:AddKeybindButton(keybindButtonDescriptor)
            end
        end
    end
end

function ZO_KeybindStrip:HasKeybindButton(keybindButtonDescriptor)
    return self.keybinds[keybindButtonDescriptor.keybind] ~= nil
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

function ZO_KeybindStrip:HasKeybindButtonGroup(keybindButtonGroupDescriptor)
    return self.keybindGroups[keybindButtonGroupDescriptor] ~= nil
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

function ZO_KeybindStrip:TryHandlingKeybindDown(keybind)
    if not self.control:IsHidden() then
        local buttonOrEtherealDescriptor = self.keybinds[keybind]
        if buttonOrEtherealDescriptor and (not buttonOrEtherealDescriptor.IsControlHidden or not buttonOrEtherealDescriptor:IsControlHidden()) then
            local keybindButtonDescriptor = GetDescriptorFromButton(buttonOrEtherealDescriptor)
            local enabled, disabledAlertText, disabledAlertType = GetValueFromRawOrFunction(keybindButtonDescriptor, "enabled")
            local cooldown = GetValueFromRawOrFunction(keybindButtonDescriptor, "cooldown")
            if cooldown then
                enabled = false
            end
            if enabled ~= false then
                if self:FilterSceneHiding(keybindButtonDescriptor) then
                    if keybindButtonDescriptor.callback then
                        local sound = keybindButtonDescriptor.sound
                        ClearMenu()
                        keybindButtonDescriptor.callback(DOWN)
                        keybindButtonDescriptor.handledDown = true

                        if sound then
                            PlaySound(sound)
                        end
                    end
                end
                return true
            elseif disabledAlertText then
                if disabledAlertType == KEYBIND_STRIP_DISABLED_DIALOG then
                    ZO_Dialogs_ShowPlatformDialog("KEYBIND_STRIP_DISABLED_DIALOG", nil, {mainTextParams = {disabledAlertText}})
                else
                    ZO_Alert(UI_ALERT_CATEGORY_ALERT, nil, disabledAlertText)
                    PlaySound(SOUNDS.GENERAL_ALERT_ERROR)
                end
            end
        end
    end
    return false
end

function ZO_KeybindStrip:TryHandlingKeybindUp(keybind)
    if not self.control:IsHidden() then
        local buttonOrEtherealDescriptor = self.keybinds[keybind]
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
                    if self:FilterSceneHiding(keybindButtonDescriptor) then
                        if keybindButtonDescriptor.callback then
                            ClearMenu()
                            keybindButtonDescriptor.callback(UP)
                        end
                    end
                    return true
                end
            end
        end
    end
    return false
end

function ZO_KeybindStrip:TriggerCooldown(keybindButtonDescriptor, duration, stateIndex, shouldCooldownPersist)
    keybindButtonDescriptor.cooldown = duration / 1000
    keybindButtonDescriptor.cooldownStart = GetFrameTimeMilliseconds() / 1000
    keybindButtonDescriptor.shouldCooldownPersist = shouldCooldownPersist

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
        local cooldownStart = descriptor.cooldownStart
        local difference = time - cooldownStart
        local newCooldown = descriptor.cooldown - difference

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
                if not activeDescriptor.ethereal then
                    activeDescriptor = activeDescriptor.keybindButtonDescriptor
                end
                if descriptor == activeDescriptor then
                    self:UpdateKeybindButton(descriptor, self:GetTopKeybindStateIndex())
                end
            end
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
        resizeToFitPadding = 40,
        leftAnchorOffset = 0,
        centerAnchorOffset = 0,
        rightAnchorOffset = 0,
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
function ZO_KeybindStrip:RemoveButtonFromAnchors(button)
    local keybindButtonDescriptor = button.keybindButtonDescriptor
    local anchorTable = self:GetAnchorTableFromAlignment(keybindButtonDescriptor.alignment or keybindButtonDescriptor.keybindButtonGroupDescriptor and keybindButtonDescriptor.keybindButtonGroupDescriptor.alignment)

    for i=1, #anchorTable do
        if anchorTable[i] == button then
            table.remove(anchorTable, i)
            break
        end
    end
end

function ZO_KeybindStrip:AddButtonToAnchors(button)
    local keybindButtonDescriptor = button.keybindButtonDescriptor
    local anchorTable = self:GetAnchorTableFromAlignment(keybindButtonDescriptor.alignment or keybindButtonDescriptor.keybindButtonGroupDescriptor and keybindButtonDescriptor.keybindButtonGroupDescriptor.alignment)
    anchorTable[#anchorTable + 1] = button
end

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

function ZO_KeybindStrip:GetAnchorTableFromAlignment(alignment)
    if alignment == KEYBIND_STRIP_ALIGN_LEFT then
        self.leftButtons = self.leftButtons or {}
        return self.leftButtons
    end
    if alignment == KEYBIND_STRIP_ALIGN_CENTER then
        self.centerButtons = self.centerButtons or {}
        return self.centerButtons
    end

    self.rightButtons = self.rightButtons or {}
    return self.rightButtons
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
            local keybind = keybindButtonDescriptor.keybind or keybindButtonDescriptor.keybindButtonGroupDescriptor and keybindButtonGroupDescriptor.keybindButtonGroupDescriptor.keybind
            
            local buttonKeybindChanging = button:GetKeybind() ~= keybind
            local suppressUpdate = (updateOnly and isVisible == wasVisible)
            -- updateOnly is used only when we are trying to update keybinds from UpdateKeybindButton so we know that this setup is coming from an update

            local alwaysPreferGamepadMode = self:SetupButtonStyle(button, self.styleInfo)

            if not suppressUpdate or buttonKeybindChanging then
                button:SetKeybind(keybind, nil, nil, alwaysPreferGamepadMode)
            end

            local enabled = GetValueFromRawOrFunction(keybindButtonDescriptor, "enabled")
            if(enabled == nil) then enabled = true end
            local cooldown = GetValueFromRawOrFunction(keybindButtonDescriptor, "cooldown")
            if cooldown then
                enabled = false
            end
            button:SetEnabled(enabled)

            local name = GetValueFromRawOrFunction(keybindButtonDescriptor, "name")
            if cooldown then
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

    local GAMEPAD_BUTTON_ORDER = {
            UI_SHORTCUT_EXIT = 0,
            UI_SHORTCUT_PRIMARY = 1,
            UI_SHORTCUT_NEGATIVE = 2,
            UI_SHORTCUT_SECONDARY = 3,
            UI_SHORTCUT_TERTIARY = 4,
            UI_SHORTCUT_LEFT_STICK = 5,
            UI_SHORTCUT_RIGHT_STICK = 6,
            UI_SHORTCUT_LEFT_TRIGGER = 7,
            UI_SHORTCUT_RIGHT_TRIGGER = 8,

            DIALOG_PRIMARY = 1,
            DIALOG_NEGATIVE = 2,
            DIALOG_SECONDARY = 3,
            DIALOG_TERTIARY = 4,
        }
    local function GamepadSort(buttonLeft, buttonRight)
        local leftKeybindDescriptor = buttonLeft.keybindButtonDescriptor
        local rightKeybindDescriptor = buttonRight.keybindButtonDescriptor

        local leftOrder = GetValueFromRawOrFunction(leftKeybindDescriptor, "gamepadOrder") or GAMEPAD_BUTTON_ORDER[GetValueFromRawOrFunction(leftKeybindDescriptor, "keybind")] or GetValueFromRawOrFunction(leftKeybindDescriptor, "order") or 0
        local rightOrder = GetValueFromRawOrFunction(rightKeybindDescriptor, "gamepadOrder") or GAMEPAD_BUTTON_ORDER[GetValueFromRawOrFunction(rightKeybindDescriptor, "keybind")] or GetValueFromRawOrFunction(rightKeybindDescriptor, "order") or 0

        if leftOrder == rightOrder then
            return buttonLeft.insertionOrder < buttonRight.insertionOrder
        end
        return leftOrder < rightOrder
    end

    function ZO_KeybindStrip:UpdateAnchorsInternal(anchorTable, anchor, relativeAnchor, parent, startOffset, yOffset)
        if anchorTable and #anchorTable > 0 then
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
                        button:SetAnchor(anchor, prevButton, relativeAnchor)
                    else
                        button:SetAnchor(anchor, nil, anchor, startOffset, yOffset)
                    end
                    prevButton = button
                end
            end
                        
            return anchorTable
        end
        return nil
    end

    function ZO_KeybindStrip:UpdateAnchors()
        local yOffset = self.styleInfo and self.styleInfo.yAnchorOffset or 0
        self.leftButtons = self:UpdateAnchorsInternal(self.leftButtons, LEFT, RIGHT, self.control, self.styleInfo and self.styleInfo.leftAnchorOffset or 0, yOffset)
        self.rightButtons = self:UpdateAnchorsInternal(self.rightButtons, RIGHT, LEFT, self.control, self.styleInfo and self.styleInfo.rightAnchorOffset or 0, yOffset)

        self.centerButtons = self:UpdateAnchorsInternal(self.centerButtons, LEFT, RIGHT, self.centerParent, self.styleInfo and self.styleInfo.centerAnchorOffset or 0, yOffset)
    end
end
