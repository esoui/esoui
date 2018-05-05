local CreateLinkAccount_Console = ZO_Object:Subclass()

function CreateLinkAccount_Console:New(control)
    local object = ZO_Object.New(self)
    object:Initialize(control)
    return object
end

function CreateLinkAccount_Console:Initialize(control)
    self.control = control

    local createLinkAccountScreen_Gamepad_Fragment = ZO_FadeSceneFragment:New(self.control)
    CREATE_LINK_ACCOUNT_SCREEN_GAMEPAD_SCENE = ZO_Scene:New("CreateLinkAccountScreen_Gamepad", SCENE_MANAGER)
    CREATE_LINK_ACCOUNT_SCREEN_GAMEPAD_SCENE:AddFragment(createLinkAccountScreen_Gamepad_Fragment)

    CREATE_LINK_ACCOUNT_SCREEN_GAMEPAD_SCENE:RegisterCallback("StateChange", function(oldState, newState)
                    if newState == SCENE_SHOWING then
                        self:PerformDeferredInitialization()

                        KEYBIND_STRIP:RemoveDefaultExit()
                        self.optionsList:Activate()
                        KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
            
                    elseif newState == SCENE_HIDDEN then
                        KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
                        self.optionsList:Deactivate()
                        KEYBIND_STRIP:RestoreDefaultExit()
                    end
                end)
end

function CreateLinkAccount_Console:PerformDeferredInitialization()
    if self.initialized then return end
    self.initialized = true

    self.activateImagesFragment = nil

    self:SetupOptions()
    self:InitKeybindingDescriptor()
end

function CreateLinkAccount_Console:AddOption(title, imagesFragment, selectedState)
    local option = ZO_GamepadEntryData:New(title)
    option:SetFontScaleOnSelection(true)
    option.selectedCallback = function() PregameStateManager_SetState(selectedState) end
    option.imagesFragment = imagesFragment
    self.optionsList:AddEntry("ZO_GamepadMenuEntryTemplate", option)
end

function CreateLinkAccount_Console:SetupOptions()
    self.optionsList = ZO_GamepadVerticalParametricScrollList:New(self.control:GetNamedChild("Container"):GetNamedChild("Options"):GetNamedChild("List"))
    self.optionsList:SetOnSelectedDataChangedCallback(function(...) self:SelectionChanged(...) end)
    self.optionsList:SetAlignToScreenCenter(true)

    self.optionsList:Clear()

    self.optionsList:AddDataTemplate("ZO_GamepadMenuEntryTemplate", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction)

    self:AddOption(GetString(SI_CREATEACCOUNT_HEADER), CREATE_ACCOUNT_IMAGES_FRAGMENT_CONSOLE, "CreateAccountSetup")
    self:AddOption(GetString(SI_CONSOLE_LINKACCOUNT_HEADER), LINK_ACCOUNT_IMAGES_FRAGMENT_CONSOLE, "LinkAccount")
    
    self.optionsList:Commit()
end

function CreateLinkAccount_Console:SelectionChanged(list, selectedData, oldSelectedData)
    local newImagesFragment = selectedData.imagesFragment

    if self.activateImagesFragment == newImagesFragment then return end

    if self.activateImagesFragment then
        CREATE_LINK_ACCOUNT_SCREEN_GAMEPAD_SCENE:RemoveFragment(self.activateImagesFragment)
    end

    self.activateImagesFragment = newImagesFragment

    if newImagesFragment then
        CREATE_LINK_ACCOUNT_SCREEN_GAMEPAD_SCENE:AddFragment(newImagesFragment)
    end
end

function CreateLinkAccount_Console:InitKeybindingDescriptor()
    self.keybindStripDescriptor = 
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,

        -- Select
        {    
            name = GetString(SI_GAMEPAD_SELECT_OPTION),
            keybind = "UI_SHORTCUT_PRIMARY",
            callback = function()
                local data = self.optionsList:GetTargetData()
                if data ~= nil and data.selectedCallback ~= nil then
                    PlaySound(SOUNDS.POSITIVE_CLICK)
                    data.selectedCallback()
                end
            end,
        },

        -- Back
        KEYBIND_STRIP:GenerateGamepadBackButtonDescriptor(function()
                PlaySound(SOUNDS.NEGATIVE_CLICK)
                PregameStateManager_SetState("AccountLogin")
            end)
    }
end
---------------------------------------

function CreateLinkAccountScreen_Gamepad_Initialize(self)
    CREATE_LINK_ACCOUNT_CONSOLE = CreateLinkAccount_Console:New(self)
end
