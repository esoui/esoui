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

function ZO_DyeingToolSetFill:GetHighlightRules(dyeableSlot, dyeChannel)
    return dyeableSlot, nil
end

function ZO_DyeingToolSetFill:OnLeftClicked(restyleSlotData, dyeChannel)
    restyleSlotData:SetPendingDyes(GetSavedDyeSetDyes(self.owner:GetSelectedSavedSetIndex()))

    self.owner:OnPendingDyesChanged(restyleSlotData)
    PlaySound(SOUNDS.DYEING_TOOL_SET_FILL_USED)
end

function ZO_DyeingToolSetFill:OnSavedSetLeftClicked(dyeSetIndex, dyeChannel)
    self.owner:SetSelectedSavedSetIndex(dyeSetIndex)
end

function ZO_DyeingToolSetFill:GetCursorType()
    return MOUSE_CURSOR_FILL_MULTIPLE
end

function ZO_DyeingToolSetFill:GetToolActionString()
    return SI_DYEING_TOOL_SET_FILL
end
