----------------------------
-- Main Menu Helper Panel --
----------------------------

ZO_Main_Menu_Helper_Panel_Gamepad = ZO_CallbackObject:Subclass()

function ZO_Main_Menu_Helper_Panel_Gamepad:New(...)
    local panel = ZO_CallbackObject.New(self)
    panel:Initialize(...)
    return panel
end

function ZO_Main_Menu_Helper_Panel_Gamepad:Initialize(control)
    self.isActive = false
	self.control = control
	
	self:InitializeKeybinds()
	
	self.fragment = ZO_FadeSceneFragment:New(control)
	
	self.fragment:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWING then
            self:OnShowing()
        elseif newState == SCENE_HIDING then
            self:OnHiding()
        elseif newState == SCENE_HIDDEN then
            self:OnHidden()
        end
    end)
end

function ZO_Main_Menu_Helper_Panel_Gamepad:InitializeKeybinds()
	self.keybindStripDescriptor = 
	{
		alignment = KEYBIND_STRIP_ALIGN_LEFT,
	}
	ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.keybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON, function() self:EndSelection() end)
end

function ZO_Main_Menu_Helper_Panel_Gamepad:EndSelection()
	self:FireCallbacks("PanelSelectionEnd", self)
end

function ZO_Main_Menu_Helper_Panel_Gamepad:Activate()
    self.isActive = true
	KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_Main_Menu_Helper_Panel_Gamepad:Deactivate()
    self.isActive = false
	KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_Main_Menu_Helper_Panel_Gamepad:IsActive()
    return self.isActive
end

function ZO_Main_Menu_Helper_Panel_Gamepad:OnShowing()
    -- override in derived classes
end

function ZO_Main_Menu_Helper_Panel_Gamepad:OnHiding()
    -- override in derived classes
end

function ZO_Main_Menu_Helper_Panel_Gamepad:OnHidden()
    -- override in derived classes
end

function ZO_Main_Menu_Helper_Panel_Gamepad:GetFragment()
	return self.fragment
end