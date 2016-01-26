ZO_SceneFragmentBar = ZO_Object:Subclass()

function ZO_SceneFragmentBar:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_SceneFragmentBar:Initialize(menuBar)
    self.menuBar = menuBar
    self.label = menuBar:GetNamedChild("Label")
    self.buttonData = {}
end

function ZO_SceneFragmentBar:SelectFragment(name)
    local SKIP_ANIMATIONS = true 
    ZO_MenuBar_SelectDescriptor(self.menuBar, name, SKIP_ANIMATIONS)
end

function ZO_SceneFragmentBar:SetStartingFragment(name)
    self.lastFragmentName = name
end

function ZO_SceneFragmentBar:ShowLastFragment()
    self:SelectFragment(self.lastFragmentName)
end

function ZO_SceneFragmentBar:GetLastFragment()
    return self.lastFragmentName
end

function ZO_SceneFragmentBar:RemoveActiveKeybind()
    local keybindButton = self.currentKeybindButton
    self.currentKeybindButton = nil
    if(keybindButton) then
        if(keybindButton.keybind) then
            KEYBIND_STRIP:RemoveKeybindButton(keybindButton)
        else
            KEYBIND_STRIP:RemoveKeybindButtonGroup(keybindButton)
        end
    end
end

function ZO_SceneFragmentBar:UpdateActiveKeybind()
    if(self.currentKeybindButton) then
        if(self.currentKeybindButton.keybind) then
            KEYBIND_STRIP:UpdateKeybindButton(self.currentKeybindButton)
        else
            KEYBIND_STRIP:UpdateKeybindButtonGroup(self.currentKeybindButton)
        end
    end
end

function ZO_SceneFragmentBar:Clear()
    ZO_MenuBar_ClearSelection(self.menuBar)
    self:RemoveActiveKeybind()
    if(self.currentFragmentGroup) then
        SCENE_MANAGER:RemoveFragmentGroup(self.currentFragmentGroup)
    end
end

function ZO_SceneFragmentBar:RemoveAll()
    self:Clear()
    ZO_MenuBar_ClearButtons(self.menuBar)
    for _, buttonData in ipairs(self.buttonData) do
        buttonData.callback = buttonData.existingCallback
    end
    self.buttonData = {}
end

function ZO_SceneFragmentBar:Add(name, fragmentGroup, buttonData, keybindButton)
    buttonData.descriptor = name
    buttonData.categoryName = name
    buttonData.existingCallback = buttonData.callback
    local existingCallback = buttonData.callback
    buttonData.callback = function()
        self:RemoveActiveKeybind()
        if(self.currentFragmentGroup) then
            SCENE_MANAGER:RemoveFragmentGroup(self.currentFragmentGroup)
        end

        self.currentFragmentGroup = fragmentGroup
        self.currentKeybindButton = keybindButton

        SCENE_MANAGER:AddFragmentGroup(fragmentGroup)
        if(keybindButton) then
            if(keybindButton.keybind) then
                KEYBIND_STRIP:AddKeybindButton(keybindButton)
            else
                KEYBIND_STRIP:AddKeybindButtonGroup(keybindButton)
            end
        end

        if(self.label) then
            self.label:SetText(zo_strformat(SI_SCENE_FRAGMENT_BAR_TITLE, GetString(name)))
        end

        self.lastFragmentName = name
        if(existingCallback) then
            existingCallback()
        end
    end
    ZO_MenuBar_AddButton(self.menuBar, buttonData)
    table.insert(self.buttonData, buttonData)
end