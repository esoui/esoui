ZO_DyeingToolErase = ZO_DyeingToolBase:Subclass()

function ZO_DyeingToolErase:New(...)
    return ZO_DyeingToolBase.New(self, ...)
end

function ZO_DyeingToolErase:Initialize(owner)
   ZO_DyeingToolBase.Initialize(self, owner)
end

function ZO_DyeingToolErase:Activate(fromTool, suppressSounds)
    if fromTool and not suppressSounds then
        PlaySound(SOUNDS.DYEING_TOOL_ERASE_SELECTED)
    end
end

function ZO_DyeingToolErase:HasSwatchSelection()
    return false
end

function ZO_DyeingToolErase:OnEquipSlotLeftClicked(equipSlot, dyeChannel)
    SetPendingEquippedItemDye(equipSlot, zo_replaceInVarArgs(dyeChannel, nil, GetPendingEquippedItemDye(equipSlot)))
    self.owner:OnPendingDyesChanged(equipSlot)
    PlaySound(SOUNDS.DYEING_TOOL_ERASE_USED)
end

function ZO_DyeingToolErase:OnSavedSetLeftClicked(dyeSetIndex, dyeChannel)
    SetSavedDyeSetDyes(dyeSetIndex, zo_replaceInVarArgs(dyeChannel, nil, GetSavedDyeSetDyes(dyeSetIndex)))
    self.owner:OnSavedSetSlotChanged(dyeSetIndex)
    PlaySound(SOUNDS.DYEING_TOOL_ERASE_USED)
end

function ZO_DyeingToolErase:GetCursorType(equipSlot, dyeChannel)
    return MOUSE_CURSOR_ERASE
end
