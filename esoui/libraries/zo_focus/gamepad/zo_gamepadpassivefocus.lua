ZO_GAMEPAD_FOCUS_NO_NEXT = false
ZO_GAMEPAD_FOCUS_NO_PREVIOUS = false

--Layout consts--
ZO_GAMEPAD_PASSIVE_FOCUS_HIGHLIGHT_INSIDE_PADDING = 4
ZO_GAMEPAD_PASSIVE_FOCUS_HIGHLIGHT_WIDE_PADDING = ZO_GAMEPAD_PASSIVE_FOCUS_HIGHLIGHT_INSIDE_PADDING + 5

----------------------
--Passive Focus Base--
----------------------

--When using Passive Focus, the assigned manager will have its own movement controller, and the focus just listens for a move event
--Passive focus never determines when to switch focus on its own

ZO_GamepadPassiveFocus = ZO_Object:Subclass()

function ZO_GamepadPassiveFocus:New(...)
    local focus = ZO_Object.New(self)
    focus:Initialize(...)
    return focus
end

function ZO_GamepadPassiveFocus:Initialize(manager, activateCallback, deactivateCallback)
    self.manager = manager
    self.activateCallback = activateCallback
    self.deactivateCallback = deactivateCallback
end

function ZO_GamepadPassiveFocus:SetupSiblings(previous, next)
    self.previousFocus = previous
    self.nextFocus = next
end

function ZO_GamepadPassiveFocus:SetKeybindDescriptor(keybindDescriptor)
    self.keybindDescriptor = keybindDescriptor
end

function ZO_GamepadPassiveFocus:AppendKeybind(keybind)
    self.keybindDescriptor[#self.keybindDescriptor + 1] = keybind
end

function ZO_GamepadPassiveFocus:UpdateKeybinds()
    if self.keybindDescriptor then
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindDescriptor)
    end
end

function ZO_GamepadPassiveFocus:Activate()
    if not self.active then
        self.active = true

        if self.activateCallback then
            self.activateCallback()
        end

        if self.keybindDescriptor then
            KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindDescriptor)
        end
    end
end

function ZO_GamepadPassiveFocus:Deactivate()
    if self.active then
        self.active = false

        if self.keybindDescriptor then
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindDescriptor)
        end

        if self.deactivateCallback then
            self.deactivateCallback()
        end
    end
end

function ZO_GamepadPassiveFocus:MovePrevious()
    local newFocus = nil
    if self.previousFocus then
        self:Deactivate()
        self.previousFocus:Activate()
        newFocus = self.previousFocus
    end
    return newFocus
end

function ZO_GamepadPassiveFocus:MoveNext()
    local newFocus = nil
    if self.nextFocus then
        self:Deactivate()
        self.nextFocus:Activate()
        newFocus = self.nextFocus
    end
    return newFocus
end

function ZO_GamepadPassiveFocus:Move(nextFocus)
    if nextFocus then
        self:Deactivate()
        nextFocus:Activate()
    end
    return nextFocus
end

function ZO_GamepadPassiveFocus:IsFocused()
    return self.active
end