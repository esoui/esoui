GUILD_KEEP_RELEASE_INTERACTION =
{
    type = "Guild Keep Release",
    interactTypes = { INTERACTION_KEEP_GUILD_RELEASE },
}

GUILD_KEEP_CLAIM_INTERACTION =
{
    type = "Guild Keep Claim",
    interactTypes = { INTERACTION_KEEP_GUILD_CLAIM },
}

local GAMEPAD_KEEP_CLAIM_DIALOG = "GAMEPAD_KEEP_CLAIM_DIALOG"
ZO_GAMEPAD_KEEP_RELEASE_DIALOG = "GAMEPAD_KEEP_RELEASE_DIALOG"
local SELECT_GUILD_KEEP_CLAIM = "SELECT_GUILD_KEEP_CLAIM"
local RELEASE_KEEP_OWNERSHIP = "CONFIRM_RELEASE_KEEP_OWNERSHIP"

local function OnEndKeepGuildClaimInteraction()
    ZO_Dialogs_ReleaseDialog(SELECT_GUILD_KEEP_CLAIM)
    ZO_Dialogs_ReleaseDialog(GAMEPAD_KEEP_CLAIM_DIALOG)
end

local function OnStartKeepGuildReleaseInteraction()
    INTERACT_WINDOW:OnBeginInteraction(GUILD_KEEP_RELEASE_INTERACTION)
    local keepId = GetGuildReleaseInteractionKeepId()

    local dialogName = RELEASE_KEEP_OWNERSHIP
    if(IsInGamepadPreferredMode()) then
        dialogName = ZO_GAMEPAD_KEEP_RELEASE_DIALOG
    end

    ZO_Dialogs_ShowPlatformDialog(dialogName, {release = ReleaseInteractionKeepForGuild, keepId = keepId})
end

local function OnEndKeepGuildReleaseInteraction()
    ZO_Dialogs_ReleaseDialog(RELEASE_KEEP_OWNERSHIP)
    ZO_Dialogs_ReleaseDialog(ZO_GAMEPAD_KEEP_RELEASE_DIALOG)
    
end

local ZO_KeepClaimDialog = ZO_SelectGuildDialog:Subclass()

function ZO_KeepClaimDialog:New(control)
    local function acceptFunction(guildId)
        ClaimInteractionKeepForGuild(guildId)
        INTERACT_WINDOW:OnEndInteraction(GUILD_KEEP_CLAIM_INTERACTION)
    end

    local function declineFunction()
        INTERACT_WINDOW:OnEndInteraction(GUILD_KEEP_CLAIM_INTERACTION)
    end

    local dialog = ZO_SelectGuildDialog.New(self, control, SELECT_GUILD_KEEP_CLAIM, acceptFunction, declineFunction)
    dialog:SetTitle(GetString(SI_PROMPT_TITLE_SELECT_GUILD_KEEP_CLAIM))
    dialog:SetGuildFilter(function(guildId)
        return DoesPlayerHaveGuildPermission(guildId, GUILD_PERMISSION_CLAIM_AVA_RESOURCE)
    end)
    dialog:SetButtonText(1, SI_GUILD_CLAIM_KEEP_ACCEPT)
    dialog.errorTextLabel = GetControl(control, "ErrorText")
    dialog.lastUpdateTime = 0
    
    dialog:InitializeGamepadDialogs()

    -- Event Handlers

    local function OnStartKeepGuildClaimInteraction()
        INTERACT_WINDOW:OnBeginInteraction(GUILD_KEEP_CLAIM_INTERACTION)
        if(not dialog:Show()) then
            INTERACT_WINDOW:OnEndInteraction(GUILD_KEEP_CLAIM_INTERACTION)
        end
    end

    dialog:SetDialogUpdateFn(function(control, time) dialog:OnUpdate(time) end)

    control:RegisterForEvent(EVENT_KEEP_GUILD_CLAIM_UPDATE, function() self:OnGuildInformationChanged() end)
    control:RegisterForEvent(EVENT_START_KEEP_GUILD_CLAIM_INTERACTION, function() OnStartKeepGuildClaimInteraction() end)
    control:RegisterForEvent(EVENT_END_KEEP_GUILD_CLAIM_INTERACTION, function() OnEndKeepGuildClaimInteraction() end)
    control:RegisterForEvent(EVENT_START_KEEP_GUILD_RELEASE_INTERACTION, function() OnStartKeepGuildReleaseInteraction() end)
    control:RegisterForEvent(EVENT_END_KEEP_GUILD_RELEASE_INTERACTION, function() OnEndKeepGuildReleaseInteraction() end)

    return dialog
end

function ZO_KeepClaimDialog:Show()
    local keepId = GetGuildClaimInteractionKeepId()
    local keepName = GetKeepName(keepId)
    self:SetPrompt(zo_strformat(SI_SELECT_GUILD_KEEP_CLAIM_INSTRUCTIONS, keepName))

    local dialogName = SELECT_GUILD_KEEP_CLAIM
    if(IsInGamepadPreferredMode()) then
        dialogName = GAMEPAD_KEEP_CLAIM_DIALOG
    end

    ZO_Dialogs_ShowPlatformDialog(dialogName)

    if(self:HasEntries()) then
        return true
    else
        ZO_Dialogs_ReleaseDialog(dialogName)
        return false
    end
end

function ZO_KeepClaimDialog:UpdateClaimAvailable()
    local result = CheckGuildKeepClaim(self.selectedGuildId, GetGuildClaimInteractionKeepId())
    if(result == CLAIM_KEEP_RESULT_TYPE_SUCCESS) then
        self.acceptButton:SetEnabled(true)
        self.errorTextLabel:SetHidden(true)
    else
        self.acceptButton:SetEnabled(false)
        self.errorTextLabel:SetHidden(false)

        local keepId = GetGuildClaimInteractionKeepId()
        local keepName = GetKeepName(keepId)
        if(result == CLAIM_KEEP_RESULT_TYPE_STILL_ON_COOLDOWN) then
            local time = GetSecondsUntilKeepClaimAvailable(keepId, BGQUERY_LOCAL)
            self.errorTextLabel:SetText(zo_strformat(SI_KEEP_CLAIM_ON_COOLDOWN, keepName, ZO_FormatTime(time, TIME_FORMAT_STYLE_COLONS, TIME_FORMAT_PRECISION_TWELVE_HOUR)))
        else
            self.errorTextLabel:SetText(zo_strformat(GetString("SI_CLAIMKEEPRESULTTYPE", result), keepName))
        end
    end
end

function ZO_KeepClaimDialog:OnUpdate(time)
    if(time > self.lastUpdateTime + 1) then
        self:UpdateClaimAvailable()
        self.lastUpdateTime = time
    end
end

function ZO_KeepClaimDialog:OnGuildSelected(entry)
    ZO_SelectGuildDialog.OnGuildSelected(self, entry)
    self:UpdateClaimAvailable()
end

function ZO_SelectGuildKeepClaimDialog_OnInitialized(self)
    KEEP_CLAIM_DIALOG = ZO_KeepClaimDialog:New(self)
end

function ZO_KeepClaimDialog:SetCurrentDropdown(dropdown)
    self.currentDropdown = dropdown
end

function ZO_KeepClaimDialog:InitializeGamepadDialogs()
    self:InitializeGamepadReleaseKeepDialog()
    self:InitializeGamepadClaimKeepDialog()
end

function ZO_KeepClaimDialog:InitializeGamepadReleaseKeepDialog()
    local dialogName = ZO_GAMEPAD_KEEP_RELEASE_DIALOG
    local dialogSingleton = ZO_GenericGamepadDialog_GetControl(GAMEPAD_DIALOGS.BASIC)

    ZO_Dialogs_RegisterCustomDialog(dialogName,
    {
        gamepadInfo =
        {
            dialogType = GAMEPAD_DIALOGS.BASIC,
        },

        title =
        {
            text = SI_GUILD_RELEASE_KEEP_CONFIRM_TITLE,
        },

        mainText =
        {
            text = SI_GUILD_RELEASE_KEEP_CONFIRM_PROMPT,
        },

        noChoiceCallback = function()
            INTERACT_WINDOW:OnEndInteraction(GUILD_KEEP_RELEASE_INTERACTION)
        end,

        buttons =
        {
            [1] =
            {
                keybind = "DIALOG_PRIMARY",
                text = SI_GUILD_RELEASE_KEEP_ACCEPT,
                callback = function(dialog)
                    dialog.data.release()
                    INTERACT_WINDOW:OnEndInteraction(GUILD_KEEP_RELEASE_INTERACTION)
                end,
                visible = function()
                    local keepId = dialogSingleton.data.keepId
                    local time = GetSecondsUntilKeepClaimAvailable(keepId, BGQUERY_LOCAL)
                    return time == 0
                end,
            },
            [2] =
            {
                keybind = "DIALOG_NEGATIVE",
                text = SI_DIALOG_CANCEL,
                callback = function(dialog)
                    INTERACT_WINDOW:OnEndInteraction(GUILD_KEEP_RELEASE_INTERACTION)
                end,
            },
        },

        updateFn = function(dialog)
            local keepId = dialog.data.keepId
            local keepName = GetKeepName(keepId) 
            local cooldown = GetSecondsUntilKeepClaimAvailable(keepId, BGQUERY_LOCAL)

            if cooldown == 0 then
                dialog.info.mainText.text = SI_GUILD_RELEASE_KEEP_CONFIRM_PROMPT
                ZO_Dialogs_RefreshDialogText(dialogName, dialog, { mainTextParams = { keepName } } )
                ZO_GenericGamepadDialog_RefreshKeybinds(dialog)
            else
                dialog.info.mainText.text = SI_GUILD_RELEASE_KEEP_COOLDOWN
                ZO_Dialogs_RefreshDialogText(dialogName, dialog, { mainTextParams = { keepName, ZO_FormatTime(cooldown, TIME_FORMAT_STYLE_COLONS, TIME_FORMAT_PRECISION_TWELVE_HOUR) } } )
            end

            KEYBIND_STRIP:UpdateCurrentKeybindButtonGroups()
        end,
    })
end

function ZO_KeepClaimDialog:InitializeGamepadClaimKeepDialog()
    local dialogName = GAMEPAD_KEEP_CLAIM_DIALOG

    local function UpdateViolations()
        local data = self.currentDropdown and self.currentDropdown:GetSelectedItemData()
        self.noViolations = data and data.noViolations or self.noViolations

        KEYBIND_STRIP:UpdateCurrentKeybindButtonGroups()
    end

    local function UpdateSelectedGuildId(guildId)
        self.selectedGuildId = guildId
        self.selectedGuildName = GetGuildName(guildId)

        UpdateViolations()
    end

    local function UpdateSelectedGuildIndex(index)
        self.selectedGuildIndex = index
    end

    local function DeinitDialog()
        if self.currentDropdown then
            self.currentDropdown:Deactivate()
            self:SetCurrentDropdown(nil)
        end

        INTERACT_WINDOW:OnEndInteraction(GUILD_KEEP_CLAIM_INTERACTION)
    end

    local function ReleaseDialog()
        DeinitDialog()
        ZO_Dialogs_ReleaseDialogOnButtonPress(dialogName)
    end 

    local function UpdateDropdownHighlight()
        local highlightIndex = 1
        if(self.selectedGuildIndex ~= nil) then
            highlightIndex = self.selectedGuildIndex
        end
        self.currentDropdown:SetHighlightedItem(highlightIndex)
    end

    ZO_Dialogs_RegisterCustomDialog(dialogName,
    {
        gamepadInfo = {
            dialogType = GAMEPAD_DIALOGS.PARAMETRIC,
        },

        setup = function(dialog)
            self:RefreshGuildList()

            self.noViolations = nil
            UpdateSelectedGuildId(nil)
            UpdateSelectedGuildIndex(nil)

            dialog:setupFunc()
        end,

        blockDialogReleaseOnPress = true, -- We'll handle Dialog Releases ourselves since we don't want DIALOG_PRIMARY to release the dialog on press.
        noChoiceCallback = DeinitDialog,

        title =
        {
            text = GetString(SI_PROMPT_TITLE_SELECT_GUILD_KEEP_CLAIM),
        },
        mainText = 
        {
            text = function()
                local keepId = GetGuildClaimInteractionKeepId()
                local keepName = GetKeepName(keepId)
                local result = CheckGuildKeepClaim(self.selectedGuildId, keepId)
                
                if result ~= CLAIM_KEEP_RESULT_TYPE_SUCCESS then
                    local cooldown = GetSecondsUntilKeepClaimAvailable(keepId, BGQUERY_LOCAL)

                    if cooldown > 0 then
                        return zo_strformat(SI_KEEP_CLAIM_ON_COOLDOWN, keepName, ZO_FormatTime(cooldown, TIME_FORMAT_STYLE_COLONS, TIME_FORMAT_PRECISION_TWELVE_HOUR))
                    else
                        return zo_strformat(GetString("SI_CLAIMKEEPRESULTTYPE", result), keepName)
                    end
                else
                    return zo_strformat(SI_GAMEPAD_SELECT_GUILD_KEEP_CLAIM_INSTRUCTIONS, keepName)
                end
            end
        },

        updateFn = function(dialog)
            local keepId = GetGuildClaimInteractionKeepId()
            local isClaimAvailable = GetSecondsUntilKeepClaimAvailable(keepId, BGQUERY_LOCAL) == 0
            
            if(isClaimAvailable and not dialog.wasClaimAvailableLastUpdate) then
                dialog:setupFunc()
            end

            UpdateViolations()
            ZO_Dialogs_RefreshDialogText(dialogName, dialog)
            ZO_GenericGamepadDialog_RefreshKeybinds(dialog)
            
            if self.noViolations and self.currentDropdown then
                self.currentDropdown:SetSelectedColor(ZO_SELECTED_TEXT)
            elseif self.currentDropdown then
                self.currentDropdown:SetSelectedColor(ZO_DISABLED_TEXT)
            end

            dialog.wasClaimAvailableLastUpdate = isClaimAvailable
        end,
        
        parametricList =
        {
            -- guild select
            {
                header = SI_GAMEPAD_KEEP_CLAIM_SELECT_GUILD_HEADER,
                template = "ZO_GamepadDropdownItem",


                templateData = {
                    rankSelector = true,  
                    visible = function()
                        return GetSecondsUntilKeepClaimAvailable(GetGuildClaimInteractionKeepId(), BGQUERY_LOCAL) == 0
                    end,
                    setup = function(control, data, selected, reselectingDuringRebuild, enabled, active)
                        control.dropdown:SetSortsItems(false)
                        control.dropdown:SetSelectedColor(ZO_SELECTED_TEXT)
                        self:SetCurrentDropdown(control.dropdown)
                        
                        control.dropdown:ClearItems()

                        local function OnGuildSelected(comboBox, entryText, entry)
                            self.noViolations = entry.noViolations
                            UpdateSelectedGuildId(entry.guildId)
                            UpdateSelectedGuildIndex(entry.index)

                            if self.noViolations then
                                self.currentDropdown:SetSelectedColor(ZO_SELECTED_TEXT)
                            else
                                self.currentDropdown:SetSelectedColor(ZO_ERROR_COLOR)
                            end
                        end

                        local keepId = GetGuildClaimInteractionKeepId()
                        local count = 1
                        for guildId, entry in pairs(self.entries) do
                            local newEntry = control.dropdown:CreateItemEntry(entry.guildText, OnGuildSelected)
                            newEntry.guildId = entry.guildId
                            newEntry.index = count
                            newEntry.guildText = entry.guildText
                            local result = CheckGuildKeepClaim(guildId, keepId)
                            newEntry.noViolations = result == CLAIM_KEEP_RESULT_TYPE_SUCCESS
                            
                            if newEntry.noViolations then
                                newEntry.m_normalColor = ZO_DISABLED_TEXT
                                newEntry.m_highlightColor = ZO_SELECTED_TEXT
                            else
                                newEntry.m_normalColor = ZO_ERROR_COLOR
                                newEntry.m_highlightColor = ZO_ERROR_COLOR
                            end

                            control.dropdown:AddItem(newEntry)

                            count = count + 1
                        end

                        self.currentDropdown:SelectFirstItem()

                        control.dropdown:UpdateItems()

                        local function OnDropdownDeactivated()
                            KEYBIND_STRIP:PopKeybindGroupState()
                        end

                        control.dropdown:SetDeactivatedCallback(OnDropdownDeactivated)
                    end,
                },
            },
        },
       
        buttons =
        {
            -- Cancel Button
            {
                keybind = "DIALOG_NEGATIVE",
                text = GetString(SI_DIALOG_CANCEL),
                callback = function()
                    ReleaseDialog()
                end,
            },

            -- Select Button (used for selecting guild)
            {
                keybind = "DIALOG_PRIMARY",
                text = GetString(SI_GAMEPAD_SELECT_OPTION),
                visible = function()
                    return GetSecondsUntilKeepClaimAvailable(GetGuildClaimInteractionKeepId(), BGQUERY_LOCAL) == 0
                end,
                callback = function()
                    KEYBIND_STRIP:PushKeybindGroupState() -- This is just to hide the keybinds (don't need to store the state)
                    self.currentDropdown:Activate()
                    UpdateDropdownHighlight()
                end,
            },

            -- Claim Button
            {
                keybind = "DIALOG_SECONDARY",
                text = GetString(SI_DIALOG_ACCEPT),
                visible = function()
                    return self.noViolations
                end,
                callback = function()
                    if(self.noViolations) then
                        ClaimInteractionKeepForGuild(self.selectedGuildId)
                    end

                    ReleaseDialog()
                end,
            },
        }
    })
end