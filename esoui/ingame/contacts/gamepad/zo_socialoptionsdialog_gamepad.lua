--------------------------------------------
-- SocialOptionsDialog Gamepad
--------------------------------------------

ZO_SocialOptionsDialogGamepad = ZO_Object:Subclass()

function ZO_SocialOptionsDialogGamepad:Initialize(control)
    if control then
        self.control = control
    end

    self.optionTemplateGroups = {}
    self.conditionResults = {}
    self:BuildOptionsList()

    self.dialogData = {}
    self.control:RegisterForEvent(EVENT_FRIEND_PLAYER_STATUS_CHANGED, function(_, displayName, characterName, oldStatus, newStatus) self:OnPlayerStatusChanged(displayName, characterName, oldStatus, newStatus) end)
    self.control:RegisterForEvent(EVENT_GUILD_MEMBER_PLAYER_STATUS_CHANGED, function(_, _, displayName, characterName, oldStatus, newStatus) self:OnPlayerStatusChanged(displayName, characterName, oldStatus, newStatus) end)
end

function ZO_SocialOptionsDialogGamepad:ShowOptionsDialog()
    local parametricList = {}
    self:PopulateOptionsList(parametricList)
    local data = self:GetDialogData()
    --Saving the displayName and online state of the person the dialog is being opened for.
    self.dialogData.displayName = self.socialData.displayName
    self.dialogData.online = self.socialData.online
    ZO_Dialogs_ShowGamepadDialog("GAMEPAD_SOCIAL_OPTIONS_DIALOG", data)
end

function ZO_SocialOptionsDialogGamepad:GetDialogData()
    local parametricList = {}
    self:PopulateOptionsList(parametricList)
    local data =
    {
        parametricList = parametricList,
    }
    return data
end

function ZO_SocialOptionsDialogGamepad:BuildOptionsList()
    -- This function is meant to be overridden by a subclass
end

function ZO_SocialOptionsDialogGamepad:AddOptionTemplateGroup(headerFunction)
    local id = #self.optionTemplateGroups + 1
    local grouping =
    {
        headerFunction = headerFunction,
        options = {},
    }
    self.optionTemplateGroups[id] = grouping
    return id
end

function ZO_SocialOptionsDialogGamepad:AddOptionTemplate(groupId, buildFunction, conditionFunction)
    local grouping = self.optionTemplateGroups[groupId]
    assert(grouping ~= nil, "You must get a valid id from AddOptionTemplateGroup before adding options")
    table.insert(grouping.options, { buildFunction = buildFunction, conditionFunction = conditionFunction })
end

function ZO_SocialOptionsDialogGamepad:PopulateOptionsList(list)
    ZO_ClearTable(self.conditionResults)
    for groupId, grouping in pairs(self.optionTemplateGroups) do
        self.currentGroupingHeader = grouping.headerFunction and grouping.headerFunction(self)

        for index, option in pairs(grouping.options) do
            if self:CheckCondition(option.conditionFunction) then
                self:AddOption(list, option.buildFunction(self))
                self.currentGroupingHeader = nil
            end
        end
    end
end

function ZO_SocialOptionsDialogGamepad:CheckCondition(conditionFunction)
    local conditionMet = self.socialData ~= nil
    if conditionMet and conditionFunction then
        if self.conditionResults[conditionFunction] == nil then
            conditionMet = conditionFunction(self)
            self.conditionResults[conditionFunction] = conditionMet
        else
            conditionMet = self.conditionResults[conditionFunction]
        end
    end
    return conditionMet
end

function ZO_SocialOptionsDialogGamepad:HasAnyShownOptions()
    for groupId, grouping in pairs(self.optionTemplateGroups) do
        for index, option in pairs(grouping.options) do
            local conditionFunction = option.conditionFunction
            if self:CheckCondition(conditionFunction) then
                return true
            end
        end
    end
    return false
end

function ZO_SocialOptionsDialogGamepad:BuildOptionEntry(header, label, callback, finishedCallback, icon)
    local entry = {
        template = "ZO_GamepadMenuEntryTemplate",
        header = header or self.currentGroupingHeader,
        templateData = {
            text = type(label) == "number" and GetString(label) or label,
            setup = ZO_SharedGamepadEntry_OnSetup,
            callback = callback,
            finishedCallback = finishedCallback,
        },
        icon = icon,
    }
    return entry
end

function ZO_SocialOptionsDialogGamepad:AddOption(list, option)
    if option == nil then 
        return
    end

    if list.header then
        option.header = list.header
        list.header = nil
    end
    table.insert(list, option)
end

function ZO_SocialOptionsDialogGamepad:SetupOptions(socialData)
    self.socialData = socialData
    ZO_ClearTable(self.conditionResults)
end

function ZO_SocialOptionsDialogGamepad:AddSocialOptionsKeybind(descriptor, callback, keybind, name, sound, enabledCallback)
    descriptor[#descriptor + 1] =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        name =      name or GetString(SI_GAMEPAD_SELECT_OPTION),
        keybind =   keybind or "UI_SHORTCUT_PRIMARY",
        enabled =   enabledCallback or function()
                        return self:HasAnyShownOptions()
                    end,
        sound =     sound or SOUNDS.GAMEPAD_MENU_FORWARD,
        callback =  callback or function()
                        return self:ShowOptionsDialog()
                    end,
    }
end

--Hiding the options dialog if the player's online status changes.
function ZO_SocialOptionsDialogGamepad:OnPlayerStatusChanged(displayName, characterName, oldStatus, newStatus)
    if self.dialogData and self.dialogData.displayName == displayName and newStatus ~= nil then
        local isOnline = newStatus ~= PLAYER_STATUS_OFFLINE
        if self.dialogData.online ~= isOnline then
            ZO_Dialogs_ReleaseAllDialogsOfName("GAMEPAD_SOCIAL_OPTIONS_DIALOG")
        end
    end
end

--Shared Options
function ZO_SocialOptionsDialogGamepad:SelectedDataIsPlayer()
    return self.socialData.displayName == GetDisplayName()
end

function ZO_SocialOptionsDialogGamepad:SelectedDataIsNotPlayer()
    return not self:SelectedDataIsPlayer()
end

function ZO_SocialOptionsDialogGamepad:SelectedDataIsLoggedIn()
    return self.socialData.online and self.socialData.hasCharacter and not self:SelectedDataIsPlayer()
end

function ZO_SocialOptionsDialogGamepad:GetDefaultHeader()
    return ZO_FormatUserFacingDisplayName(self.socialData.displayName)
end

function ZO_SocialOptionsDialogGamepad:BuildEditNoteOption()
    local callback = function()
        local data = {
            displayName = self.socialData.displayName,
            note = self.socialData.note,
            noteChangedCallback = self.noteChangedCallback,
        }
        ZO_Dialogs_ShowGamepadDialog("GAMEPAD_SOCIAL_EDIT_NOTE_DIALOG", data)
    end
    local unusedHeader = nil
    return self:BuildOptionEntry(unusedHeader, SI_SOCIAL_MENU_EDIT_NOTE, callback)
end

function ZO_SocialOptionsDialogGamepad:ShouldAddSendMailOption()
    return not self:SelectedDataIsPlayer()
end

function ZO_SocialOptionsDialogGamepad:BuildSendMailOption()
    local function Callback()
        if IsUnitDead("player") then
            ZO_AlertEvent(EVENT_UI_ERROR, SI_CANNOT_DO_THAT_WHILE_DEAD)
        elseif IsUnitInCombat("player") then
            ZO_AlertEvent(EVENT_UI_ERROR, SI_CANNOT_DO_THAT_WHILE_IN_COMBAT)
        else
            MAIL_GAMEPAD:GetSend():ComposeMailTo(ZO_FormatUserFacingCharacterOrDisplayName(self.socialData.displayName))
        end
    end
    local unusedHeader = nil
    return self:BuildOptionEntry(unusedHeader, SI_SOCIAL_MENU_SEND_MAIL, nil, Callback)
end

function ZO_SocialOptionsDialogGamepad:ShouldAddWhisperOption()
    return self.socialData.online and IsChatSystemAvailableForCurrentPlatform()
end

function ZO_SocialOptionsDialogGamepad:BuildWhisperOption()
    local finishCallback = function() StartChatInput("", CHAT_CHANNEL_WHISPER, self.socialData.displayName) end
    local unusedHeader = nil
    return self:BuildOptionEntry(unusedHeader, SI_SOCIAL_LIST_PANEL_WHISPER, nil, finishCallback)
end

function ZO_SocialOptionsDialogGamepad:ShouldAddInviteToGroupOption()
    return IsGroupModificationAvailable() and not self:SelectedDataIsPlayer() and IsUnitSoloOrGroupLeader("player")
end

function ZO_SocialOptionsDialogGamepad:ShouldAddInviteToGroupOptionAndCanSelectedDataBeInvited()
    -- PS can send platform invites to offline players which they can then use to launch the game and join
    return self:ShouldAddInviteToGroupOption() and (self:SelectedDataIsLoggedIn() or ZO_IsPlaystationPlatform())
end

function ZO_SocialOptionsDialogGamepad:GetInviteToGroupCallback()
    return function()
        local NOT_SENT_FROM_CHAT = false
        local DISPLAY_INVITED_MESSAGE = true
        TryGroupInviteByName(self.socialData.displayName, NOT_SENT_FROM_CHAT, DISPLAY_INVITED_MESSAGE)
    end
end
function ZO_SocialOptionsDialogGamepad:BuildInviteToGroupOption()
    if self:ShouldAddInviteToGroupOption() then
        local unusedHeader = nil
        return self:BuildOptionEntry(unusedHeader, SI_SOCIAL_MENU_INVITE, self:GetInviteToGroupCallback())
    end
end

function ZO_SocialOptionsDialogGamepad:BuildTravelToPlayerOption(jumpFunc)
    local function JumpToPlayerCallback()
        jumpFunc(DecorateDisplayName(self.socialData.displayName))
        SCENE_MANAGER:ShowBaseScene()
    end
    local unusedHeader = nil
    return self:BuildOptionEntry(unusedHeader, SI_SOCIAL_MENU_JUMP_TO_PLAYER, JumpToPlayerCallback)
end

function ZO_SocialOptionsDialogGamepad:BuildVisitPlayerHouseOption()
    local function JumpToHouseCallback()
        JumpToHouse(DecorateDisplayName(self.socialData.displayName))
        SCENE_MANAGER:ShowBaseScene()
    end
    local unusedHeader = nil
    return self:BuildOptionEntry(unusedHeader, SI_SOCIAL_MENU_VISIT_HOUSE, JumpToHouseCallback)
end

function ZO_SocialOptionsDialogGamepad:BuildInviteToTributeOption()
    if not ZO_IsTributeLocked() then
        local function InviteToTributeCallback()
            InviteToTributeByDisplayName(DecorateDisplayName(self.socialData.displayName))
            SCENE_MANAGER:ShowBaseScene()
        end
        local unusedHeader = nil
        return self:BuildOptionEntry(unusedHeader, SI_SOCIAL_MENU_TRIBUTE_INVITE, InviteToTributeCallback)
    end
end

function ZO_SocialOptionsDialogGamepad:BuildGamerCardOption()
    if IsConsoleUI() then
        local callback = function()
            local data = self.socialData
            local displayName = data.displayName
            if data.gamerCardDisplayName then
                displayName = data.gamerCardDisplayName
            end

            if data.consoleId then
                local undecoratedName = UndecorateDisplayName(displayName)
                ShowGamerCard(undecoratedName, data.consoleId)
            elseif data.friendIndex then
                --To make sure we use the correct index if friends list was updated while the dialog is being displayed.
                local updatedData = FRIENDS_LIST_MANAGER:FindDataByDisplayName(displayName)
                if updatedData then
                    ZO_ShowGamerCardFromDisplayNameOrFallback(displayName, ZO_ID_REQUEST_TYPE_DISPLAY_NAME, displayName)
                end
            elseif data.ignoreIndex then
                ZO_ShowGamerCardFromDisplayNameOrFallback(displayName, ZO_ID_REQUEST_TYPE_IGNORE_INFO, data.ignoreIndex)
            elseif data.isGroup then
                ZO_ShowGamerCardFromDisplayNameOrFallback(displayName, ZO_ID_REQUEST_TYPE_GROUP_INFO, data.index)
            elseif displayName then
                ZO_ShowGamerCardFromDisplayName(displayName)
            else
                ZO_Dialogs_ShowGamepadDialog("GAMERCARD_UNAVAILABLE")
            end
        end
        return self:BuildOptionEntry(nil, ZO_GetGamerCardStringId(), callback)
    end
    return nil
end

function ZO_SocialOptionsDialogGamepad:BuildIgnoreOption()
    local stringId
    local callback
    local platform = GetUIPlatform()
    if platform == UI_PLATFORM_PC then
        stringId = SI_FRIEND_MENU_IGNORE
        callback = function()
            ZO_Dialogs_ShowGamepadDialog("CONFIRM_IGNORE_FRIEND", self.socialData, {mainTextParams={ ZO_FormatUserFacingDisplayName(self.socialData.displayName) }}) 
        end
    elseif ZO_DoesConsoleSupportTargetedIgnore() then
        stringId = SI_GAMEPAD_CONTACTS_MENU_IGNORE
        callback = function()
            ZO_ShowConsoleIgnoreDialogFromDisplayNameOrFallback(self.socialData.displayName, ZO_ID_REQUEST_TYPE_FRIEND_INFO, self.socialData.friendIndex)
        end
    end
    if stringId and callback then
        return self:BuildOptionEntry(nil, stringId, callback)
    end
    return nil
end

function ZO_SocialOptionsDialogGamepad:ShouldAddRemoveFriendOption()
    return not IsConsoleUI() and IsFriend(DecorateDisplayName(self.socialData.displayName))
end

function ZO_SocialOptionsDialogGamepad:BuildRemoveFriendOption()
    local callback = function() 
        ZO_Dialogs_ShowGamepadDialog("CONFIRM_REMOVE_FRIEND", self.socialData, {mainTextParams={ZO_FormatUserFacingDisplayName(self.socialData.displayName)}}) 
    end
    return self:BuildOptionEntry(nil, SI_FRIEND_MENU_REMOVE_FRIEND, callback)
end

function ZO_SocialOptionsDialogGamepad:BuildRemoveIgnoreOption()
    local callback = function() 
        RemoveIgnore(self.socialData.displayName)
        PlaySound(SOUNDS.DIALOG_ACCEPT)
    end
    return self:BuildOptionEntry(nil, SI_IGNORE_MENU_REMOVE_IGNORE, callback)
end

function ZO_SocialOptionsDialogGamepad:ShouldAddFriendOption()
    return not IsFriend(DecorateDisplayName(self.socialData.displayName)) and not IsIgnored(DecorateDisplayName(self.socialData.displayName)) and not self:SelectedDataIsPlayer()
end

function ZO_SocialOptionsDialogGamepad:BuildAddFriendOption()
    local callback = function()      
        if IsConsoleUI() then
            local displayName = self.socialData.displayName
            ZO_ShowConsoleAddFriendDialogFromDisplayName(displayName)
        else
            local data = { displayName = self.socialData.displayName, }
            ZO_Dialogs_ShowGamepadDialog("GAMEPAD_SOCIAL_ADD_FRIEND_DIALOG", data)
        end
    end
    return self:BuildOptionEntry(nil, SI_SOCIAL_MENU_ADD_FRIEND, callback)
end
