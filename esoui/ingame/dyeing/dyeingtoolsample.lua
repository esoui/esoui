ZO_DyeingToolSample = ZO_DyeingToolBase:Subclass()

function ZO_DyeingToolSample:New(...)
    return ZO_DyeingToolBase.New(self, ...)
end

function ZO_DyeingToolSample:Initialize(owner)
   ZO_DyeingToolBase.Initialize(self, owner)
end

function ZO_DyeingToolSample:Activate(fromTool, suppressSounds)
    if fromTool and not suppressSounds then
        PlaySound(SOUNDS.DYEING_TOOL_SAMPLE_SELECTED)
    end
end

function ZO_DyeingToolSample:HasSwatchSelection()
    return false
end

function ZO_DyeingToolSample:OnLeftClicked(restyleSlotData, dyeChannel)
    local dyeId = select(dyeChannel, restyleSlotData:GetPendingDyes())
    self:ProcessDyeId(dyeId)
end

function ZO_DyeingToolSample:OnSavedSetLeftClicked(dyeSetIndex, dyeChannel)
    local dyeId = select(dyeChannel, GetSavedDyeSetDyes(dyeSetIndex))
    self:ProcessDyeId(dyeId)
end

function ZO_DyeingToolSample:ProcessDyeId(dyeId)
    if dyeId > INVALID_DYE_ID then
        local playerDyeInfo = ZO_DYEING_MANAGER:GetPlayerDyeInfoById(dyeId)
        if playerDyeInfo and playerDyeInfo.known then
            local SUPPRESS_SOUNDS = true
            self.owner:SwitchToDyeingWithDyeId(dyeId, SUPPRESS_SOUNDS)
            PlaySound(SOUNDS.DYEING_TOOL_SAMPLE_USED)
        elseif not playerDyeInfo then
            ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.GENERAL_ALERT_ERROR, SI_DYEING_CANNOT_SAMPLE_NON_PLAYER_DYE)
        else
            ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.GENERAL_ALERT_ERROR, SI_DYEING_CANNOT_SAMPLE_LOCKED_DYE)
        end
    else
        ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.GENERAL_ALERT_ERROR, SI_DYEING_CANNOT_SAMPLE)
    end
end

function ZO_DyeingToolSample:GetCursorType()
    return MOUSE_CURSOR_SAMPLE
end

function ZO_DyeingToolSample:GetToolActionString()
    return SI_DYEING_TOOL_SAMPLE_TOOLTIP
end