---------------------------
-- Checkbox Tile Gamepad --
---------------------------

ZO_CHECKBOX_TILE_GAMEPAD_WIDTH = 350
ZO_CHECKBOX_TILE_GAMEPAD_HEIGHT = 45

-- Primary logic class must be subclassed after the platform class so that platform specific functions will have priority over the logic class functionality
ZO_CheckboxTile_Gamepad = ZO_Object.MultiSubclass(ZO_Tile_Gamepad, ZO_Tile)

function ZO_CheckboxTile_Gamepad:New(...)
    return ZO_Tile.New(self, ...)
end

function ZO_CheckboxTile_Gamepad:PostInitializePlatform()
    ZO_Tile_Gamepad.PostInitializePlatform(self)

    self.textLabel = self.control:GetNamedChild("Text")
    self.iconControl = self.control:GetNamedChild("Icon")
    self.selectorControl = self.control:GetNamedChild("SelectorBox")
end

function ZO_CheckboxTile_Gamepad:OnSelectionChanged()
    ZO_Tile_Gamepad.OnSelectionChanged(self)

    self:UpdateVisualDisplay()
end

function ZO_CheckboxTile_Gamepad:Layout(data)
    ZO_Tile.Layout(self, data)

    self.data = data

    self.textLabel:SetText(data.text)

    self:UpdateVisualDisplay()
end

function ZO_CheckboxTile_Gamepad:GetIsChecked()
    if type(self.data.isChecked) == "function" then
        return self.data.isChecked()
    end
    return self.data.isChecked
end

function ZO_CheckboxTile_Gamepad:GetIsDisabled()
    if type(self.data.isDisabled) == "function" then
        return self.data.isDisabled()
    end
    return self.data.isDisabled
end

function ZO_CheckboxTile_Gamepad:OnCheckboxToggle()
    local isDisabled = self:GetIsDisabled()
    if not isDisabled then
        PlaySound(self.data.clickSound)

        if self.data.onToggleFunction then
            self.data.onToggleFunction(self.data.value, not self:GetIsChecked())
        end

        self:UpdateVisualDisplay()
    end
end

function ZO_CheckboxTile_Gamepad:UpdateVisualDisplay()
    local color
    local isChecked = self:GetIsChecked()
    local isDisabled = self:GetIsDisabled()
    if self:IsSelected() then
        if isChecked then
            if isDisabled then
                color = ZO_GAMEPAD_COMPONENT_COLORS.SELECTED_ACTIVE_DISABLED
            else
                color = ZO_GAMEPAD_COMPONENT_COLORS.SELECTED_ACTIVE
            end
        else
            color = ZO_GAMEPAD_COMPONENT_COLORS.SELECTED_INACTIVE
        end
    else
        if isChecked then
            if isDisabled then
                color = ZO_GAMEPAD_COMPONENT_COLORS.UNSELECTED_ACTIVE_DISABLED
            else
                color = ZO_GAMEPAD_COMPONENT_COLORS.UNSELECTED_ACTIVE
            end
        else
            color = ZO_GAMEPAD_COMPONENT_COLORS.UNSELECTED_INACTIVE
        end
    end

    self.textLabel:SetColor(color:UnpackRGB())
    self.selectorControl:SetHidden(not self:IsSelected())
    self.iconControl:SetHidden(not isChecked)
end

-- XML functions
----------------

function ZO_CheckboxTile_Gamepad_OnInitialized(control)
    ZO_CheckboxTile_Gamepad:New(control)
end