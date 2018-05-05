ZO_DyeStamp_Confirmation_Base = ZO_Object:Subclass()

function ZO_DyeStamp_Confirmation_Base:New(...)
    local dyeStampConfirmation = ZO_Object.New(self)
    dyeStampConfirmation:Initialize(...)
    return dyeStampConfirmation
end

function ZO_DyeStamp_Confirmation_Base:Initialize(control, scene)
    self.control = control
    self:InitializeKeybindStripDescriptors()

    scene:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWN then
            self:OnShown()
        elseif newState == SCENE_HIDDEN then
            self:OnHidden()
        end
    end)

    self.control:RegisterForEvent(EVENT_ITEM_PREVIEW_READY, function() self:ShowPreviewedDyeStamp() end)
end

function ZO_DyeStamp_Confirmation_Base:PreviewDyeStamp()
    if not GetPreviewModeEnabled() then
        self.waitingForPreviewBegin = true
        return false
    end

    if self.bagId and self.slotIndex then
        local itemLink = GetItemLink(self.bagId, self.slotIndex)
        SetupDyeStampPreview(self.bagId, self.slotIndex)
        return true
    end

    return false
end

function ZO_DyeStamp_Confirmation_Base:InitializeKeybindStripDescriptors()
    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_CENTER,

        -- Apply dye stamp
        {
            name = GetString(SI_DYEING_COMMIT),
            keybind = "UI_SHORTCUT_SECONDARY",
            callback = function() self:ShowConfirmationDialog() end,
        },

    }

    self:AddExitKey()
end

function ZO_DyeStamp_Confirmation_Base:AddExitKey()
    -- override in derived classes
end

function ZO_DyeStamp_Confirmation_Base:ShowPreviewedDyeStamp()
    if self.waitingForPreviewBegin then
        self.waitingForPreviewBegin = false
        self:PreviewDyeStamp(self.bagId, self.slotIndex)
    end
end

function ZO_DyeStamp_Confirmation_Base:SetTargetItem(bagId, slotIndex)
    self.bagId = bagId
    self.slotIndex = slotIndex
end

function ZO_DyeStamp_Confirmation_Base:OnShown()
    TriggerTutorial(TUTORIAL_TRIGGER_DYE_STAMP_CONFIRMATION_SEEN)

    self:PreviewDyeStamp()

    self.control:SetHidden(false)
    KEYBIND_STRIP:RemoveDefaultExit()
    KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_DyeStamp_Confirmation_Base:OnHidden()
    self.control:SetHidden(true)
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
    KEYBIND_STRIP:RestoreDefaultExit()
end

function ZO_DyeStamp_Confirmation_Base:ShowConfirmationDialog()
    local itemName = GetItemName(self.bagId, self.slotIndex)
    ZO_Dialogs_ShowPlatformDialog("DYE_STAMP_CONFIRM_USE", {onAcceptCallback = function() self:ConfirmUseDyeStamp() end }, {mainTextParams = {itemName}})
end

function ZO_DyeStamp_Confirmation_Base:ConfirmUseDyeStamp()
    if self.bagId and self.slotIndex then
        UseItem(self.bagId, self.slotIndex)
    end
    self:EndConfirmation()
end

function ZO_DyeStamp_Confirmation_Base:EndConfirmation()
    self.bagId = nil
    self.slotIndex = nil
    SCENE_MANAGER:HideCurrentScene()
end