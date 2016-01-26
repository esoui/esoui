ZO_DyeingToolBase = ZO_Object:Subclass()

function ZO_DyeingToolBase:New(...)
    local dyeingToolBase = ZO_Object.New(self)
    dyeingToolBase:Initialize(...)
    return dyeingToolBase
end

function ZO_DyeingToolBase:Initialize(owner)
    self.owner = owner
end

-- Intended to be overriden, called when the tool becomes active
function ZO_DyeingToolBase:Activate(fromTool, suppressSounds)
end

-- Intended to be overriden, called when the tool becomes inactive
function ZO_DyeingToolBase:Deactivate()
end

-- Intended to be overriden for custom behavior, controls whether or not a tool uses dye swatches directly
function ZO_DyeingToolBase:HasSwatchSelection()
    return true
end

-- Intended to be overriden for custom behavior, controls whether or not a tool uses dye saved sets directly
function ZO_DyeingToolBase:HasSavedSetSelection()
    return false
end

-- Intended to be overriden for custom behavior, controls whether this highlights a single slot/channel, or all (return nil for all)
function ZO_DyeingToolBase:GetHighlightRules(dyeSlot, dyeChannel)
    return dyeSlot, dyeChannel
end

function ZO_DyeingToolBase:OnEquipSlotClicked(equipSlot, dyeChannel, button)
    if button == MOUSE_BUTTON_INDEX_LEFT then
        self:OnEquipSlotLeftClicked(equipSlot, dyeChannel)
    elseif button == MOUSE_BUTTON_INDEX_RIGHT then
        self:OnEquipSlotRightClicked(equipSlot, dyeChannel)
    end
end

-- Intended to be overriden, called when a equip slot swatch gets left clicked
function ZO_DyeingToolBase:OnEquipSlotLeftClicked(equipSlot, dyeChannel)
end

-- Called when a equip slot swatch gets right clicked, could be overridden if necessary
function ZO_DyeingToolBase:OnEquipSlotRightClicked(equipSlot, dyeChannel)
    if select(dyeChannel, GetPendingEquippedItemDye(equipSlot)) ~= nil then
        ClearMenu()
        AddMenuItem(GetString(SI_DYEING_CLEAR_MENU),
                    function()
                        SetPendingEquippedItemDye(equipSlot, zo_replaceInVarArgs(dyeChannel, nil, GetPendingEquippedItemDye(equipSlot)))
                        self.owner:OnPendingDyesChanged(equipSlot)
                        PlaySound(SOUNDS.DYEING_TOOL_ERASE_USED)
                    end)
        ShowMenu(self)
    end
end

function ZO_DyeingToolBase:OnSavedSetClicked(dyeSetIndex, dyeChannel, button)
    if button == MOUSE_BUTTON_INDEX_LEFT then
        self:OnSavedSetLeftClicked(dyeSetIndex, dyeChannel)
    elseif button == MOUSE_BUTTON_INDEX_RIGHT then
        self:OnSavedSetRightClicked(dyeSetIndex, dyeChannel)
    end
end

-- Intended to be overriden, called when a saved set swatch gets left clicked
function ZO_DyeingToolBase:OnSavedSetLeftClicked(dyeSetIndex, dyeChannel)
end

-- Called when a saved set swatch gets right clicked, could be overridden if necessary
function ZO_DyeingToolBase:OnSavedSetRightClicked(dyeSetIndex, dyeChannel)
    if select(dyeChannel, GetSavedDyeSetDyes(dyeSetIndex)) ~= nil then
        ClearMenu()
        AddMenuItem(GetString(SI_DYEING_CLEAR_MENU),
                    function()
                        SetSavedDyeSetDyes(dyeSetIndex, zo_replaceInVarArgs(dyeChannel, nil, GetSavedDyeSetDyes(dyeSetIndex)))
                        self.owner:OnSavedSetSlotChanged(dyeSetIndex)
                        PlaySound(SOUNDS.DYEING_TOOL_ERASE_USED)
                    end)
        ShowMenu(self)
    end
end

-- Intended to be overriden for custom cursor over dye swatches
function ZO_DyeingToolBase:GetCursorType(equipSlot, dyeChannel)
    return MOUSE_CURSOR_DO_NOT_CARE
end
