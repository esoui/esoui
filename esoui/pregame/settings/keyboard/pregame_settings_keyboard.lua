--------------------------------
-- ZO_Pregame_Settings_Keyboard
--------------------------------

ZO_Pregame_Settings_Keyboard = ZO_Object:Subclass()

function ZO_Pregame_Settings_Keyboard:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_Pregame_Settings_Keyboard:Initialize(control)
    self.control = control

    local subcategoriesMenuControl = control:GetNamedChild("Subcategory")
    self.subcategoriesMenu = ZO_Horizontal_Menu:New(subcategoriesMenuControl, ZO_HORIZONAL_MENU_ALIGN_CENTER)
    subcategoriesMenuControl:SetAnchor(BOTTOM, ZO_OptionsWindow:GetNamedChild("Divider"), TOP, -75)

    SETTINGS_FRAGMENT = ZO_FadeSceneFragment:New(control)
    SETTINGS_FRAGMENT:RegisterCallback("StateChange",   function(oldState, newState)
                                                            if newState == SCENE_FRAGMENT_SHOWING then
                                                                self:ShowSettings()
                                                            elseif newState == SCENE_FRAGMENT_HIDDEN then
                                                                self:HideSettings()
                                                            end
                                                        end)

    local function OnHorizontalMenuItemSetup(menuControl, data)
        menuControl:SetModifyTextType(MODIFY_TEXT_TYPE_UPPERCASE)

        local name = data.name
        if type(data.name) == "function" then
            name = data.name()
        end

        menuControl:SetText(name)
    end

    local HORIZONTAL_SPACING = 30
    self.subcategoriesMenu:AddTemplate("ZO_Pregame_Settings_Keyboard_Subcategory_Label", OnHorizontalMenuItemSetup, HORIZONTAL_SPACING)
end

function ZO_Pregame_Settings_Keyboard:UpdateSettingsDisplay(isShown)
    local optionsBackground = ZO_OptionsWindow:GetNamedChild("BGLeft")
    local optionsTitle = ZO_OptionsWindow:GetNamedChild("Title")

    optionsBackground:SetHidden(isShown)
    optionsTitle:SetHidden(isShown)
end

function ZO_Pregame_Settings_Keyboard:BuildSubcategoriesMenu()
    if not self.isSubcategoriesMenuBuilt then
        self.settingsCategories = ZO_GameMenuManager_GetVisibleSettingsEntries()
        for i, subcategory in ipairs(self.settingsCategories) do
            local function OnSelectionCallback(control)
                subcategory.callback(control, ZO_ReanchorControlTopHorizontalMenu)
            end
            self.subcategoriesMenu:AddMenuItem(subcategory.name, subcategory.name, OnSelectionCallback, subcategory.unselectedCallback)
        end
        self.isSubcategoriesMenuBuilt = true
    end
end

function ZO_Pregame_Settings_Keyboard:ShowSettings()
    self:BuildSubcategoriesMenu()

    -- Select first sub category by default when showing settings
    if #self.settingsCategories > 0 then
        self.subcategoriesMenu:SetSelectedByIndex(1)
    end

    local SHOW_SETTINGS = true
    self:UpdateSettingsDisplay(SHOW_SETTINGS)
end

function ZO_Pregame_Settings_Keyboard:SetOnExitCallback(onExitCallback)
    self.onExitCallback = onExitCallback
end

function ZO_Pregame_Settings_Keyboard:HideSettings()
    self.subcategoriesMenu:SetSelectedByIndex(nil)

    local HIDE_SETTINGS = false
    self:UpdateSettingsDisplay(HIDE_SETTINGS)

    if self.onExitCallback then
        self.onExitCallback()
    end
end

-- Global XML

function ZO_Pregame_Settings_Keyboard_Initialized(control)
    PREGAME_SETTINGS_KEYBOARD = ZO_Pregame_Settings_Keyboard:New(control)
end

function ZO_Pregame_Settings_Keyboard_Subcategory_Label_MouseUp(self, upInside)
    if upInside then
        PREGAME_SETTINGS_KEYBOARD.subcategoriesMenu:SetSelectedByIndex(self.data.index)
    end
end

function ZO_Pregame_Settings_Keyboard_OnMouseUp(upInside)
    if upInside then
        PREGAME_SETTINGS_KEYBOARD:HideSettings()
    end
end