ZO_DyeingToolDye = ZO_DyeingToolBase:Subclass()

function ZO_DyeingToolDye:New(...)
    return ZO_DyeingToolBase.New(self, ...)
end

function ZO_DyeingToolDye:Initialize(owner)
   ZO_DyeingToolBase.Initialize(self, owner)
end

function ZO_DyeingToolDye:Activate(fromTool, suppressSounds)
    if fromTool and not suppressSounds then
        PlaySound(SOUNDS.DYEING_TOOL_DYE_SELECTED)
    end
end

function ZO_DyeingToolDye:OnLeftClicked(dyeableSlot, dyeChannel)
    SetPendingSlotDyes(dyeableSlot, zo_replaceInVarArgs(dyeChannel, self.owner:GetSelectedDyeId(), GetPendingSlotDyes(dyeableSlot)))
    self.owner:OnPendingDyesChanged(dyeableSlot)
    PlaySound(SOUNDS.DYEING_TOOL_DYE_USED)
end

function ZO_DyeingToolDye:OnSavedSetLeftClicked(dyeSetIndex, dyeChannel)
    SetSavedDyeSetDyes(dyeSetIndex, zo_replaceInVarArgs(dyeChannel, self.owner:GetSelectedDyeId(), GetSavedDyeSetDyes(dyeSetIndex)))
    self.owner:OnSavedSetSlotChanged(dyeSetIndex)
    PlaySound(SOUNDS.DYEING_TOOL_DYE_USED)
end

function ZO_DyeingToolDye:GetCursorType(dyeableSlot, dyeChannel)
    return MOUSE_CURSOR_PAINT
end
