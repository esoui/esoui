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

function ZO_DyeingToolFill:GetHighlightRules(dyeSlot, dyeChannel)
    return nil, dyeChannel
end

function ZO_DyeingToolFill:OnEquipSlotLeftClicked(_, dyeChannel)
    local bagSlots = GetBagSize(BAG_WORN)
    for equipSlot = 0, bagSlots - 1 do
        SetPendingEquippedItemDye(equipSlot, zo_replaceInVarArgs(dyeChannel, self.owner:GetSelectedDyeIndex(), GetPendingEquippedItemDye(equipSlot)))
    end

    self.owner:OnPendingDyesChanged(nil)

    PlaySound(SOUNDS.DYEING_TOOL_FILL_USED)
end

function ZO_DyeingToolFill:OnSavedSetLeftClicked(_, dyeChannel)
    for dyeSetIndex = 1, GetNumSavedDyeSets() do
        SetSavedDyeSetDyes(dyeSetIndex, zo_replaceInVarArgs(dyeChannel, self.owner:GetSelectedDyeIndex(), GetSavedDyeSetDyes(dyeSetIndex)))
    end

    self.owner:OnSavedSetSlotChanged(nil)

    PlaySound(SOUNDS.DYEING_TOOL_FILL_USED)
end

function ZO_DyeingToolFill:GetCursorType(equipSlot, dyeChannel)
    return MOUSE_CURSOR_FILL
end
