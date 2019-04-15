--Request Friend Dialog
------------------------

local function RequestFriendDialogSetup(dialog, data)
    if(data and data.name) then
        GetControl(dialog, "NameEdit"):SetText(zo_strformat("<<1>>", data.name))
    else
        GetControl(dialog, "NameEdit"):SetText("")
    end
    GetControl(dialog, "MessageEdit"):SetText("")
end

function ZO_RequestFriendDialog_OnInitialized(self)
    ZO_Dialogs_RegisterCustomDialog("REQUEST_FRIEND",   
    {
        customControl = self,
        setup = RequestFriendDialogSetup,
        title =
        {
            text = SI_REQUEST_FRIEND_DIALOG_TITLE,
        },        
        buttons =
        {
            [1] =
            {
                control =   GetControl(self, "Request"),
                text =      SI_REQUEST_FRIEND_DIALOG_REQUEST,
                callback =  function(dialog)
                                local name = GetControl(dialog, "NameEdit"):GetText()
                                local message = GetControl(dialog, "MessageEdit"):GetText()

                                if(name ~= "") then
                                    RequestFriend(name, message)
                                end
                            end,
            },
        
            [2] =
            {
                control =   GetControl(self, "Cancel"),
                text =      SI_DIALOG_CANCEL,
            }
        }
    })

    local friendFields = ZO_RequiredTextFields:New()
    friendFields:AddButton(GetControl(self, "Request"))
    friendFields:AddTextField(GetControl(self, "NameEdit"))
end

--Edit Note Dialog
-------------------

local function EditNoteDialogSetup(dialog, data)
    GetControl(dialog, "DisplayName"):SetText(data.displayName)
    GetControl(dialog, "NoteEdit"):SetText(data.note)
end

function ZO_EditNoteDialog_OnInitialized(self)
    ZO_Dialogs_RegisterCustomDialog("EDIT_NOTE",   
    {
        customControl = self,
        setup = EditNoteDialogSetup,
        title =
        {
            text = SI_EDIT_NOTE_DIALOG_TITLE,
        },
        buttons =
        {
            [1] =
            {
                control =   GetControl(self, "Save"),
                text =      SI_SAVE,
                callback =  function(dialog)
                                local data = dialog.data
                                local note = GetControl(dialog, "NoteEdit"):GetText()

                                if(note ~= data.note) then
                                    data.changedCallback(data.displayName, note)
                                end
                            end,
            },
        
            [2] =
            {
                control =   GetControl(self, "Cancel"),
                text =      SI_DIALOG_CANCEL,
            }
        }
    })
end

function ZO_EditNoteDialog_Hide(owner)
    if(not owner or ZO_EditNoteDialog.owner == owner) then
        ZO_EditNoteDialog:SetHidden(true)
    end
end

--Create Guild Dialog
---------------------

local function CreateGuildDialogSetup(dialog)
    local playerAlliance = GetUnitAlliance("player")
    local playerAllianceEntry = dialog.entries[playerAlliance]
    dialog.OnAllianceSelected(nil, nil, playerAllianceEntry)
    dialog.nameEdit:Clear()
end

function ZO_CreateGuildDialog_OnInitialized(self)
    ZO_Dialogs_RegisterCustomDialog("CREATE_GUILD",   
    {
        title =
        {
            text = SI_PROMPT_TITLE_GUILD_CREATE,
        },
        customControl = self,
        setup = CreateGuildDialogSetup,
        buttons =
        {
            [1] =
            {
                control =   GetControl(self, "Create"),
                text =      SI_DIALOG_CREATE,
                callback =  function(dialog)
                                local guildName = dialog.nameEdit:GetText()
                                if(guildName and guildName ~= "") then
                                    GuildCreate(guildName, dialog.selectedAlliance)
                                end
                            end,
            },
        
            [2] =
            {
                control =   GetControl(self, "Cancel"),
                text =      SI_DIALOG_CANCEL,
            }
        }
    })
    
    local allianceComboBoxControl = GetControl(self, "Alliance")
    self.allianceComboBox = ZO_ComboBox_ObjectFromContainer(allianceComboBoxControl)
    self.allianceComboBox:SetSortsItems(false)
    self.allianceComboBox:SetFont("ZoFontHeader")
    self.allianceComboBox:SetSpacing(4)

    self.nameEdit = GetControl(self, "NameEdit")
    SetupEditControlForNameValidation(self.nameEdit)
    self.createButton = GetControl(self, "Create")

    self.OnAllianceSelected = function(_, entryText, entry)
        self.selectedAlliance = entry.alliance
        self.allianceComboBox:SetSelectedItemText(entry.allianceText)
    end

    self.entries = {}
    local playerAlliance = GetUnitAlliance("player")

    for i = 1, NUM_ALLIANCES do
        local allianceText = zo_iconTextFormat(GetAllianceSymbolIcon(i), 24, 24, GetAllianceName(i))
        local entry = self.allianceComboBox:CreateItemEntry(allianceText, self.OnAllianceSelected)
        entry.alliance = i
        entry.allianceText = allianceText
        table.insert(self.entries, entry)
    end

    self.allianceComboBox:AddItem(self.entries[playerAlliance])
    for i = 1, NUM_ALLIANCES do
        if(i ~= playerAlliance) then
            self.allianceComboBox:AddItem(self.entries[i])
        end
    end

    local allianceRules = GetControl(self, "AllianceRules")
    allianceRules:SetText(zo_strformat(SI_GUILD_CREATE_DIALOG_ALLIANCE_RULES, GetAllianceName(playerAlliance)))

    local createGuildFields = ZO_RequiredTextFields:New()
    createGuildFields:AddButton(self.createButton)
    createGuildFields:SetBoolean("ValidName", false)
    self.createGuildFields = createGuildFields

    self.nameInstructions = ZO_ValidNameInstructions:New(GetControl(self, "NameInstructions"))
end

function ZO_CreateGuildDialogName_UpdateViolations(self)
    local dialog = self:GetParent():GetParent()
    local violations = { IsValidGuildName(self:GetText()) }
    local noViolations = #violations == 0
    if noViolations then
        dialog.nameInstructions:Hide()
    else
        dialog.nameInstructions:Show(dialog.nameEdit, violations)
    end
    dialog.createGuildFields:SetBoolean("ValidName", noViolations)
end

function ZO_CreateGuildDialogName_HideViolations(self)
    local dialog = self:GetParent():GetParent()    
    dialog.nameInstructions:Hide()
end

function ZO_GuildEditBox_FocusGained(editControl)
    if IsInGamepadPreferredMode() then
        ZO_GamepadEditBox_FocusGained(self)
    end
end