ZO_DyeingToolFill = ZO_DyeingToolBase:Subclass()

function ZO_DyeingToolFill:New(...)
    return ZO_DyeingToolBase.New(self, ...)
end

function ZO_DyeingToolFill:Initialize(owner)
   ZO_DyeingToolBase.Initialize(self, owner)
end

function ZO_DyeingToolFill:Activate(fromTool, suppressSounds)
    if fromTool and not suppressSounds then
        PlaySound(SOUNDS.DYEING_TOOL_FILL_SELECTED)
    end
end

function ZO_DyeingToolFill:GetHighlightRules(dyeableSlot, dyeChannel)
    return nil, dyeChannel
end

function ZO_DyeingToolFill:OnLeftClicked(restyleSlotData, dyeChannel)
    local slots = ZO_Dyeing_GetSlotsForRestyleSet(restyleSlotData:GetRestyleMode(), restyleSlotData:GetRestyleSetIndex())
    for i, dyeableSlotData in ipairs(slots) do
        if not dyeableSlotData:ShouldBeHidden() then
            dyeableSlotData:SetPendingDyes(zo_replaceInVarArgs(dyeChannel, self.owner:GetSelectedDyeId(), dyeableSlotData:GetPendingDyes()))
        end
    end

    self.owner:OnPendingDyesChanged(nil)

    PlaySound(SOUNDS.DYEING_TOOL_FILL_USED)
end

function ZO_DyeingToolFill:OnSavedSetLeftClicked(_, dyeChannel)
    for dyeSetIndex = 1, GetNumSavedDyeSets() do
        SetSavedDyeSetDyes(dyeSetIndex, zo_replaceInVarArgs(dyeChannel, self.owner:GetSelectedDyeId(), GetSavedDyeSetDyes(dyeSetIndex)))
    end

    self.owner:OnSavedSetSlotChanged(nil)

    PlaySound(SOUNDS.DYEING_TOOL_FILL_USED)
end

function ZO_DyeingToolFill:GetCursorType()
    return MOUSE_CURSOR_FILL
end

function ZO_DyeingToolFill:GetToolActionString()
    return SI_DYEING_TOOL_DYE_ALL_TOOLTIP
end
