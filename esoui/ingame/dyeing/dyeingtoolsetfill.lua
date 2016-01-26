ZO_DyeingToolSetFill = ZO_DyeingToolBase:Subclass()

function ZO_DyeingToolSetFill:New(...)
    return ZO_DyeingToolBase.New(self, ...)
end

function ZO_DyeingToolSetFill:Initialize(owner)
   ZO_DyeingToolBase.Initialize(self, owner)
end

function ZO_DyeingToolSetFill:Activate(fromTool, suppressSounds)
    if fromTool and not suppressSounds then
        PlaySound(SOUNDS.DYEING_TOOL_SET_FILL_SELECTED)
    end
end

function ZO_DyeingToolSetFill:HasSwatchSelection()
    return false
end

function ZO_DyeingToolSetFill:HasSavedSetSelection()
    return true
end

function ZO_DyeingToolSetFill:GetHighlightRules(dyeSlot, dyeChannel)
    return dyeSlot, nil
end

function ZO_DyeingToolSetFill:OnEquipSlotLeftClicked(equipSlot, dyeChannel)
    SetPendingEquippedItemDye(equipSlot, GetSavedDyeSetDyes(self.owner:GetSelectedSavedSetIndex()))

    self.owner:OnPendingDyesChanged(equipSlot)
    PlaySound(SOUNDS.DYEING_TOOL_SET_FILL_USED)
end

function ZO_DyeingToolSetFill:OnSavedSetLeftClicked(dyeSetIndex, dyeChannel)
    self.owner:SetSelectedSavedSetIndex(dyeSetIndex)
end

function ZO_DyeingToolSetFill:GetCursorType(equipSlot, dyeChannel)
    return MOUSE_CURSOR_FILL_MULTIPLE
end
