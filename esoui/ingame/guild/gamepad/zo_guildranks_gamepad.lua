local GUILD_RENAME_RANK_GAMEPAD_DIALOG = "GAMEPAD_RENAME_RANK_DIALOG"
local GUILD_DELETE_RANK_GAMEPAD_DIALOG = "GAMEPAD_DELETE_RANK_DIALOG"
local GUILD_DELETE_RANK_GAMEPAD_WARNING_DIALOG = "GUILD_REMOVE_RANK_WARNING"

local GUILDMASTER_INDEX = 1

local PERMISSION_PADDING = 3
local PERMISSION_ROW_HEIGHT = 40
ZO_GAMEPAD_GUILD_RANKS_PERMISSION_COLUMN_WIDTH = ZO_GAMEPAD_QUADRANT_2_3_CONTAINER_WIDTH / 2

local HEADER_SPACING_OFFSET_Y = 0

local REFRESH_SCREEN = true
local DONT_REFRESH_SCREEN = false

local ADD_RANK_DIALOG_NAME = "GUILD_ADD_RANK_GAMEPAD"

local GAMEPAD_GUILD_RANKS_CHANGE_PERMISSION_TEMPLATE = "ZO_GamepadRankChangePermissionRow"
local GAMEPAD_GUILD_RANKS_MENU_ENTRY_TEMPLATE = "ZO_GamepadMenuEntryTemplate"

local MAX_RANK_ICONS_SUPPORTED = 10

local LIST_DISPLAY_MODES =
{
    RANKS = 1,
    OPTIONS = 2,
    SELECT_ICON = 3,
    CHANGE_PERMISSIONS = 4,
}

-- this will automatically be populated with the number of entries in each column on init
local GAMEPAD_GUILD_RANKS_PERMISSIONS_COLUMN_COUNT = { }
local GAMEPAD_GUILD_RANKS_PERMISSIONS_NUM_COLUMNS = 2
local GAMEPAD_GUILD_RANKS_PERMISSIONS =
{
    {   GetString(IsConsoleUI() and SI_GAMEPAD_GUILD_RANK_PERMISSIONS_VOICE_CHAT or SI_GAMEPAD_GUILD_RANK_PERMISSIONS_CHAT),      GetString(SI_GAMEPAD_GUILD_RANK_PERMISSIONS_ALLIANCE_WAR) },
    {   GUILD_PERMISSION_CHAT,                                  GUILD_PERMISSION_CLAIM_AVA_RESOURCE     },
    {   GUILD_PERMISSION_OFFICER_CHAT_WRITE,                    GUILD_PERMISSION_RELEASE_AVA_RESOURCE   },
    {   GUILD_PERMISSION_OFFICER_CHAT_READ,                     GetString(SI_GAMEPAD_GUILD_RANK_PERMISSIONS_COMMERCE) },
    {   GetString(SI_GAMEPAD_GUILD_RANK_PERMISSIONS_EDIT),      GUILD_PERMISSION_BANK_DEPOSIT           },
    {   GUILD_PERMISSION_SET_MOTD,                              GUILD_PERMISSION_BANK_WITHDRAW   },
    {   GUILD_PERMISSION_DESCRIPTION_EDIT,                      GUILD_PERMISSION_BANK_WITHDRAW_GOLD   },
    {   GetString(SI_GAMEPAD_GUILD_RANK_PERMISSIONS_MEMBERS),   GUILD_PERMISSION_STORE_SELL   },
    {   GUILD_PERMISSION_INVITE,                                GUILD_PERMISSION_GUILD_KIOSK_BID   },
    {   GUILD_PERMISSION_NOTE_READ,                             nil           },
    {   GUILD_PERMISSION_NOTE_EDIT,                             nil           },
    {   GUILD_PERMISSION_PROMOTE,                               nil           },
    {   GUILD_PERMISSION_DEMOTE,                                nil           },
    {   GUILD_PERMISSION_REMOVE,                                nil           },
}

local function SetupRequestEntry(control, data, selected, reselectingDuringRebuild, enabled, active)
    local isValid = enabled
    if data.validInput then
        isValid = data.validInput()
        data.disabled = not isValid
        data:SetEnabled(isValid)
    end

    ZO_SharedGamepadEntry_OnSetup(control, data, selected, reselectingDuringRebuild, isValid, active)
end

local ZO_GuildRanks_Gamepad = ZO_GuildRanks_Shared:Subclass()

function ZO_GuildRanks_Gamepad_Initialize(control)
    GUILD_RANKS_GAMEPAD = ZO_GuildRanks_Gamepad:New(control)
end

function ZO_GuildRanks_Gamepad:New(...)
    local guildRanks = ZO_GuildRanks_Shared.New(self, ...)
    guildRanks:Initialize(...)
    return guildRanks
end

function ZO_GuildRanks_Gamepad:SetMainList(list)
    self.rankList = list
end

function ZO_GuildRanks_Gamepad:SetOptionsList(optionsList)
    self.optionsList = optionsList
end

function ZO_GuildRanks_Gamepad:SetOwningScreen(owningScreen)
    self.owningScreen = owningScreen
end

local function InitializeColumnCount()
    for rowIndex = 1, #GAMEPAD_GUILD_RANKS_PERMISSIONS do
        for columnIndex = 1, GAMEPAD_GUILD_RANKS_PERMISSIONS_NUM_COLUMNS do
            if(GAMEPAD_GUILD_RANKS_PERMISSIONS[rowIndex][columnIndex] ~= nil) then
                GAMEPAD_GUILD_RANKS_PERMISSIONS_COLUMN_COUNT[columnIndex] = rowIndex
            end
        end
    end
end

function ZO_GuildRanks_Gamepad:Initialize(control)
    InitializeColumnCount()
    local ALWAYS_ANIMATE = true

    --Console has no read permission
    if IsConsoleUI() then
        local removed = false
        for rowIndex, row in ipairs(GAMEPAD_GUILD_RANKS_PERMISSIONS) do
            for columnIndex, entry in ipairs(row) do
                if entry == GUILD_PERMISSION_OFFICER_CHAT_READ then
                    row[columnIndex] = nil
                    removed = true
                    break
                end
            end
            if removed then
                break
            end
        end
    end

    self.permissionsSummary = self.control:GetNamedChild("PermissionsSummary")
    self.permissionsSummaryScrollChild = self.permissionsSummary:GetNamedChild("ScrollChild")
    GUILD_RANKS_PERMISSION_SUMMARY_FRAGMENT = ZO_FadeSceneFragment:New(self.permissionsSummary, ALWAYS_ANIMATE)

    self.iconSelector = self.control:GetNamedChild("IconSelector")
    GUILD_RANKS_ICON_SELECTOR_FRAGMENT = ZO_FadeSceneFragment:New(self.iconSelector, ALWAYS_ANIMATE)

    GUILD_RANKS_GAMEPAD_FRAGMENT = ZO_FadeSceneFragment:New(self.control, ALWAYS_ANIMATE)
    GUILD_RANKS_GAMEPAD_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWING then
            self:ResetRankSelection()
            
            self:PerformDeferredInitialization()
            
            self:ReloadAndRefreshScreen()

            self:OnTargetChanged(self.rankList, self.rankList:GetTargetData())
            
            self.owningScreen:SetListsUseTriggerKeybinds(true)

            KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)

            local OnRefresh = function() 
                self:ReloadAndRefreshScreen()
            end
            
            local OnRefreshMatchGuildId = function(_, guildId) 
                if(self:MatchesGuild(guildId)) then 
                    OnRefresh()
                end
            end

            self.control:RegisterForEvent(EVENT_GUILD_DATA_LOADED, OnRefresh)
            self.control:RegisterForEvent(EVENT_GUILD_RANKS_CHANGED, OnRefreshMatchGuildId)
            self.control:RegisterForEvent(EVENT_GUILD_RANK_CHANGED, OnRefreshMatchGuildId)
            self.control:RegisterForEvent(EVENT_SAVE_GUILD_RANKS_RESPONSE, OnRefreshMatchGuildId)
        elseif newState == SCENE_HIDING then

            self:RemoveUnusedFragments()
            self:SetChangePermissionsEnabled(false)

            self.iconSelector:Deactivate()
            GAMEPAD_NAV_QUADRANT_1_BACKGROUND_FRAGMENT:TakeFocus()

            if(self.currentDropdown) then
                self.currentDropdown:Deactivate(true)
            end
            
            self.owningScreen:SetListsUseTriggerKeybinds(false)

            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)

            self.control:UnregisterForEvent(EVENT_GUILD_DATA_LOADED)
            self.control:UnregisterForEvent(EVENT_GUILD_RANKS_CHANGED)
            self.control:UnregisterForEvent(EVENT_GUILD_RANK_CHANGED)
            self.control:UnregisterForEvent(EVENT_SAVE_GUILD_RANKS_RESPONSE)

            if(self:NeedsSave()) then
                PlaySound(SOUNDS.GUILD_RANK_SAVED)
                self:Save()
            end
        end
    end)
end

function ZO_GuildRanks_Gamepad:ResetRankSelection()
    self.selectedRank = nil
    self:ActivateRankList(DONT_REFRESH_SCREEN)
end

function ZO_GuildRanks_Gamepad:ActivateRankList(refreshScreen)
    self.listDisplayMode = LIST_DISPLAY_MODES.RANKS
    if(refreshScreen) then
        self:RefreshScreen()
    end
    self.owningScreen:SetCurrentList(self.rankList)
end

function ZO_GuildRanks_Gamepad:ActivateOptionsList(refreshScreen)
    if(self.selectedRank == nil) then
        return
    end

    self.listDisplayMode = LIST_DISPLAY_MODES.OPTIONS
    if(refreshScreen) then
        self:RefreshScreen()
    end

    GAMEPAD_NAV_QUADRANT_1_BACKGROUND_FRAGMENT:TakeFocus()
    self.owningScreen:SetCurrentList(self.optionsList)
end

function ZO_GuildRanks_Gamepad:DeactivateOptionsList()
    self.optionsList:Deactivate()
    GAMEPAD_NAV_QUADRANT_1_BACKGROUND_FRAGMENT:ClearFocus()
end

function ZO_GuildRanks_Gamepad:PerformDeferredInitialization()
    if self.deferredInitialized then return end
    self.deferredInitialized = true
    
    self:InitializeKeybindStrip()
    self:InitializePermissionsFragment()
    self:InitializeIconSelector()
    self:InitializeChangePermissions()

    self:InitializeDeleteRankDialog()
    self:InitializeRenameRankDialog()
    self:InitializeAddRankDialog()
end

function ZO_GuildRanks_Gamepad:ReloadAndRefreshScreen()
    self:PopulateRanks()
    self:RefreshScreen()
end

function ZO_GuildRanks_Gamepad:RefreshScreen()
    self:RefreshLists()
    self:RefreshContent()
    self.owningScreen:RefreshHeader()
end

function ZO_GuildRanks_Gamepad:RefreshLists()
    if(self:IsDisplayingRankList()) then
        self:RefreshRankList()
    elseif(self:IsDisplayingOptionsList()) then
        self:RefreshOptionsList()
    end
end

function ZO_GuildRanks_Gamepad:RefreshContent()
    if(self:IsDisplayingRankList()) then
        self:ActivateFragment(GUILD_RANKS_PERMISSION_SUMMARY_FRAGMENT)
    elseif(self:IsDisplayingOptionsList()) then
        self:ActivateFragment(GUILD_RANKS_PERMISSION_SUMMARY_FRAGMENT)
    elseif(self:IsDisplayingIconSelector()) then
        self:ActivateFragment(GUILD_RANKS_ICON_SELECTOR_FRAGMENT)
        self:RefreshIconSelector()
    elseif(self:IsDisplayingChangePermissions()) then
        self:ActivateFragment(GUILD_RANKS_PERMISSION_SUMMARY_FRAGMENT)
        self:RefreshChangePermissions()
    end

    self:SetChangePermissionsEnabled(self:IsDisplayingChangePermissions())

    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

-----------------
-- Dropdowns --
-----------------

function ZO_GuildRanks_Gamepad:SetCurrentDropdown(dropdown)
    self.currentDropdown = dropdown
end

------------------
-- Rank Dialogs --
------------------

function ZO_GuildRanks_Gamepad:InitializeAddRankDialog()
    local dialogName = ADD_RANK_DIALOG_NAME
    local parametricDialog = ZO_GenericGamepadDialog_GetControl(GAMEPAD_DIALOGS.PARAMETRIC)

    local function UpdateSelectedName(name)
        if self.selectedName ~= name then
            self.selectedName = name
            self.noViolations = self.selectedName ~= "" and self.selectedName ~= nil
        end
    end

    local function UpdateSelectedRankIndex(rank)
        if(self.selectedRankIndex ~= rank) then
            self.selectedRankIndex = rank
        end
    end

    local function ReleaseDialog()
        ZO_Dialogs_ReleaseDialogOnButtonPress(dialogName)
    end 

    ZO_Dialogs_RegisterCustomDialog(dialogName,
    {
        gamepadInfo = {
            dialogType = GAMEPAD_DIALOGS.PARAMETRIC,
        },

        setup = function(dialog)
            self.noViolations = nil
            self.selectedRankIndex = nil
            self.selectedName = nil
            UpdateSelectedName("")
            dialog:setupFunc()
        end,

        blockDialogReleaseOnPress = true, -- We'll handle Dialog Releases ourselves since we don't want DIALOG_PRIMARY to release the dialog on press.

        title =
        {
            text = SI_GUILD_RANKS_ADD_RANK,
        },
        parametricList =
        {
            -- guild name edit box
            {
                template = "ZO_Gamepad_GenericDialog_Parametric_TextFieldItem",
                templateData = {
                    nameField = true,
                    textChangedCallback = function(control)
                        local newName = control:GetText()
                        if(self.selectedName ~= newName) then
                            UpdateSelectedName(newName)
                            parametricDialog.entryList:RefreshVisible()
                        end
                    end,
                    
                    setup = function(control, data, selected, reselectingDuringRebuild, enabled, active)
                        control.highlight:SetHidden(not selected)

                        control.editBoxControl.textChangedCallback = data.textChangedCallback

                        if(self.selectedName == "") then
                            ZO_EditDefaultText_Initialize(control.editBoxControl, GetString(SI_GAMEPAD_GUILD_RANK_DIALOG_DEFAULT_TEXT))
                        end
                        control.editBoxControl:SetMaxInputChars(MAX_GUILD_RANK_NAME_LENGTH)
                        control.editBoxControl:SetText(self.selectedName)
                        
                        KEYBIND_STRIP:UpdateCurrentKeybindButtonGroups()
                    end,
                },
            },

            -- rank to copy entry
            {
                header = GetString(SI_GUILD_RANKS_COPY_HEADER),
                template = "ZO_GamepadDropdownItem",

                templateData = {
                    rankSelector = true,  
                    setup = function(control, data, selected, reselectingDuringRebuild, enabled, active)
                        control.dropdown:SetSortsItems(false)
                        self:SetCurrentDropdown(control.dropdown)

                        control.dropdown:ClearItems()

                        local function UpdateDropdownSelection()
                            if(self.selectedRankIndex) then
                                control.dropdown:SetSelectedItemText(self.ranks[self.selectedRankIndex].name)
                            else
                                control.dropdown:SetSelectedItemText(GetString(SI_GUILD_RANKS_COPY_NONE))
                            end
                        end

                        local function OnRankSelected(comboBox, entryText, entry)
                            UpdateSelectedRankIndex(entry.rankIndex)
                        end

                        local noneEntry = control.dropdown:CreateItemEntry(GetString(SI_GUILD_RANKS_COPY_NONE), OnRankSelected)
                        control.dropdown:AddItem(noneEntry)
                        --Skip Guild Master
                        for i = 2, #self.ranks do
                            local entry = control.dropdown:CreateItemEntry(self.ranks[i].name, OnRankSelected)
                            entry.rankIndex = i
                            control.dropdown:AddItem(entry)
                        end

                        control.dropdown:UpdateItems()

                        UpdateDropdownSelection()
                    end,
                },
            },

            -- create
            {
                template = "ZO_GamepadTextFieldSubmitItem",
                templateData = {
                    finishedSelector = true,
                    text = GetString(SI_DIALOG_ACCEPT),
                    setup = SetupRequestEntry,
                    validInput = function()
                        return self.noViolations
                    end,
                },
                icon = ZO_GAMEPAD_SUBMIT_ENTRY_ICON,
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

            -- Select Button (used for entering name)
            {
                keybind = "DIALOG_PRIMARY",
                text = GetString(SI_GAMEPAD_SELECT_OPTION),
                callback = function(dialog)
                    local targetData = dialog.entryList:GetTargetData()
                    local targetControl = dialog.entryList:GetTargetControl()
                    if(targetData.nameField and targetControl) then
                        targetControl.editBoxControl:TakeFocus()
                    elseif (targetData.rankSelector) then
                        self.currentDropdown:Activate()
                        local highlightIndex = 1
                        if(self.selectedRankIndex ~= nil) then
                            highlightIndex = self.selectedRankIndex
                        end
                        self.currentDropdown:SetHighlightedItem(highlightIndex)
                    elseif(targetData.finishedSelector) then
                        if(self.noViolations) then
                            self:AddRank(self.selectedName, self.selectedRankIndex)
                            self:RefreshScreen()
                        end

                        ReleaseDialog()
                    end
                end,
                enabled = function()
                    local targetData = parametricDialog.entryList:GetTargetData()
                    local enabled = true

                    if(targetData.finishedSelector) then
                        enabled = self.noViolations
                    end

                    return enabled
                end,
            },
        },

        noChoiceCallback = function(dialog)
            ReleaseDialog()
        end,
    })
end

function ZO_GuildRanks_Gamepad:InitializeRenameRankDialog()
    local dialogName = GUILD_RENAME_RANK_GAMEPAD_DIALOG
    local parametricDialog = ZO_GenericGamepadDialog_GetControl(GAMEPAD_DIALOGS.PARAMETRIC)

    local function UpdateSelectedName(name)
        if self.selectedName ~= name then
            self.selectedName = name
            self.noViolations = self.selectedName ~= "" and self.selectedName ~= nil
        end
    end

    local function ReleaseDialog()
        ZO_Dialogs_ReleaseDialogOnButtonPress(dialogName)
    end 

    ZO_Dialogs_RegisterCustomDialog(dialogName,
    {
        gamepadInfo = {
            dialogType = GAMEPAD_DIALOGS.PARAMETRIC,
        },

        setup = function(dialog)
            self.noViolations = nil
            self.selectedName = nil
            UpdateSelectedName(self.selectedRank:GetName())
            dialog:setupFunc()
        end,

        blockDialogReleaseOnPress = true, -- We'll handle Dialog Releases ourselves since we don't want DIALOG_PRIMARY to release the dialog on press.

        title =
        {
            text = SI_GAMEPAD_GUILD_RANK_RENAME,
        },
        parametricList =
        {
            -- guild name edit box
            {
                template = "ZO_Gamepad_GenericDialog_Parametric_TextFieldItem",
                templateData = {
                    nameField = true,
                    textChangedCallback = function(control) 
                        local newName = control:GetText()
                        if(self.selectedName ~= newName) then
                            UpdateSelectedName(newName)
                            parametricDialog.entryList:RefreshVisible()
                        end
                    end,
                    
                    setup = function(control, data, selected, reselectingDuringRebuild, enabled, active)
                        control.highlight:SetHidden(not selected)

                        control.editBoxControl.textChangedCallback = data.textChangedCallback

                        if(self.selectedName == "") then
                            ZO_EditDefaultText_Initialize(control.editBoxControl, GetString(SI_GAMEPAD_GUILD_RANK_DIALOG_DEFAULT_TEXT))
                        end
                        control.editBoxControl:SetMaxInputChars(MAX_GUILD_RANK_NAME_LENGTH)
                        control.editBoxControl:SetText(self.selectedName)
                        
                        KEYBIND_STRIP:UpdateCurrentKeybindButtonGroups()
                    end,
                },
            },

            -- confirm rename
            {
                template = "ZO_GamepadTextFieldSubmitItem",
                templateData = {
                    finishedSelector = true,
                    text = GetString(SI_DIALOG_ACCEPT),
                    setup = SetupRequestEntry,
                    validInput = function()
                        return self.noViolations
                    end,
                },
                icon = ZO_GAMEPAD_SUBMIT_ENTRY_ICON,
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

            -- Select Button (used for entering name)
            {
                keybind = "DIALOG_PRIMARY",
                text = GetString(SI_GAMEPAD_SELECT_OPTION),
                callback = function(dialog)
                    local targetData = dialog.entryList:GetTargetData()
                    local targetControl = dialog.entryList:GetTargetControl()
                    if(targetData.nameField and targetControl) then
                        targetControl.editBoxControl:TakeFocus()
                    elseif(targetData.finishedSelector) then
                        if(self.noViolations) then
                            self.selectedRank:SetName(self.selectedName)
                            self:RefreshScreen()
                        end

                        ReleaseDialog()
                    end
                end,
                enabled = function()
                    local targetData = parametricDialog.entryList:GetTargetData()
                    local enabled = true

                    if(targetData.finishedSelector) then
                        enabled = self.noViolations
                    end

                    return enabled
                end,
            },
        },

        noChoiceCallback = function(dialog)
            ReleaseDialog()
        end,
    })
end

local g_deleteRankOnFinished = false
function ZO_GuildRanks_Gamepad:InitializeDeleteRankDialog()
    ZO_Dialogs_RegisterCustomDialog(GUILD_DELETE_RANK_GAMEPAD_DIALOG,
    {
        gamepadInfo = {
            dialogType = GAMEPAD_DIALOGS.BASIC,
        },

        title =
        {
            text = function()
                return zo_strformat(SI_GAMEPAD_GUILD_RANK_DELETE_TITLE, self.selectedRank:GetName())
            end, 
        },

        mainText = 
        {
            text = function()
                return zo_strformat(SI_GUILD_RANK_DELETE_WARNING, self.selectedRank:GetName())
            end, 
        },

        setup = function()
            g_deleteRankOnFinished = false
        end,

        finishedCallback = function(dialog)
            if g_deleteRankOnFinished then
                self:DeleteSelectedRank()
            end
        end,
       
        buttons =
        {
            {
                keybind = "DIALOG_PRIMARY",
                text = SI_GAMEPAD_DIALOG_YES_BUTTON,
                callback = function()
                    g_deleteRankOnFinished = true
                end,
            },

            {
                keybind = "DIALOG_NEGATIVE",
                text = SI_GAMEPAD_DIALOG_NO_BUTTON,
                callback = function()
                    self:RefreshScreen()
                end,
            },
        }
    })
end

------------------
-- Screen Stats --
------------------

function ZO_GuildRanks_Gamepad:IsDisplayingRankList()
    return (self.listDisplayMode == LIST_DISPLAY_MODES.RANKS)
end

function ZO_GuildRanks_Gamepad:IsDisplayingOptionsList()
    return (self.listDisplayMode == LIST_DISPLAY_MODES.OPTIONS)
end
function ZO_GuildRanks_Gamepad:IsDisplayingIconSelector()
    return (self.listDisplayMode == LIST_DISPLAY_MODES.SELECT_ICON)
end

function ZO_GuildRanks_Gamepad:IsDisplayingChangePermissions()
    return (self.listDisplayMode == LIST_DISPLAY_MODES.CHANGE_PERMISSIONS)
end

-------------------------
-- Fragment Management --
-------------------------

function ZO_GuildRanks_Gamepad:RemoveUnusedFragments(fragmentBeingAdded)
    local fragments = {
        GUILD_RANKS_PERMISSION_SUMMARY_FRAGMENT,
        GUILD_RANKS_ICON_SELECTOR_FRAGMENT,
    }

    for i, fragment in ipairs(fragments) do
        if(fragmentBeingAdded ~= fragment) then
            GAMEPAD_GUILD_HOME_SCENE:RemoveFragment(fragment)
        end
    end
end

function ZO_GuildRanks_Gamepad:ActivateFragment(fragment)
    self:RemoveUnusedFragments(fragment)

    GAMEPAD_GUILD_HOME_SCENE:AddFragment(fragment)
end

function ZO_GuildRanks_Gamepad:GetMessageText()
    if(self:IsEditingRank()) then
        return self.selectedRank:GetName()
    end

    return nil
end

function ZO_GuildRanks_Gamepad:IsEditingRank()
    return not self:IsDisplayingRankList() and self.selectedRank ~= nil
end

-------------------
-- Icon Selector --
-------------------

function ZO_GuildRanks_Gamepad:InitializeIconSelector()
    local function SelectorInitialize(selector, index)
        selector:GetNamedChild("Icon"):SetTexture(GetGuildRankLargeIcon(index))
    end

    local settings = {
        uniqueName = "ZO_GuildRankLogoSelectorIcons",
        totalIcons = GetNumGuildRankIcons(),
        initFunc = SelectorInitialize,
        iconsPerRow = 4,
        iconOffsetY = 0,
    }

    self.iconSelector = ZO_GamepadIconSelector:New(self.iconSelector, settings)
end

function ZO_GuildRanks_Gamepad:RefreshIconSelector()
    local selectedRank = self.selectedRank
    local selectedIconIndex = selectedRank ~= nil and selectedRank.iconIndex or nil
    self.iconSelector:ForAllIconControls(ZO_GamepadIconSelector_RefreshIconSelectionIndicator, selectedIconIndex)
    self.iconSelector:HighlightIconControl(selectedIconIndex)
end

function ZO_GuildRanks_Gamepad:SelectHighlightedIcon()
    self.selectedRank:SetIconIndex(self.iconSelector:GetHighlightIndex())
end

------------------------
-- Change Permissions --
------------------------

function ZO_GuildRanks_Gamepad:InitializeChangePermissions()
    self.selectorBoxControl = self.control:GetNamedChild("PermissionsSummaryScrollChildSelectorBox")

    self.selectedPermission = {}
    self.selectedPermission.x = 1
    self.selectedPermission.y = 2

    self.vertMovementController = ZO_MovementController:New(MOVEMENT_CONTROLLER_DIRECTION_VERTICAL)
    self.horzMovementController = ZO_MovementController:New(MOVEMENT_CONTROLLER_DIRECTION_HORIZONTAL)
end

function ZO_GuildRanks_Gamepad:UpdateDirectionalInput()
    if(self:IsDisplayingChangePermissions()) then
        local result = self.horzMovementController:CheckMovement()
        if result == MOVEMENT_CONTROLLER_MOVE_NEXT then
            PlaySound(SOUNDS.HOR_LIST_ITEM_SELECTED)
            self:MoveChangePermissionSelection(1, 0)
        elseif result == MOVEMENT_CONTROLLER_MOVE_PREVIOUS then
            PlaySound(SOUNDS.HOR_LIST_ITEM_SELECTED)
            self:MoveChangePermissionSelection(-1, 0)
        end

        local result = self.vertMovementController:CheckMovement()
        if result == MOVEMENT_CONTROLLER_MOVE_NEXT then
            PlaySound(SOUNDS.GAMEPAD_MENU_DOWN)
            self:MoveChangePermissionSelection(0, 1)
        elseif result == MOVEMENT_CONTROLLER_MOVE_PREVIOUS then
            PlaySound(SOUNDS.GAMEPAD_MENU_UP)
            self:MoveChangePermissionSelection(0, -1)
        end
    end
end

function ZO_GuildRanks_Gamepad:IsPositionSelectable(x, y)
    return not (GAMEPAD_GUILD_RANKS_PERMISSIONS[y] == nil or GAMEPAD_GUILD_RANKS_PERMISSIONS[y][x] == nil or type(GAMEPAD_GUILD_RANKS_PERMISSIONS[y][x]) == "string")
end

local X_AXIS = 1
local Y_AXIS = 2

function ZO_GuildRanks_Gamepad:GetNearestSelectablePosition(currentX, currentY, direction, axis)
    local position, max
    local min = 1
    local foundValidPosition = false

    if axis == X_AXIS then
        position = currentX
        max = GAMEPAD_GUILD_RANKS_PERMISSIONS_NUM_COLUMNS
    else
        position = currentY
        max = GAMEPAD_GUILD_RANKS_PERMISSIONS_COLUMN_COUNT[currentX]
    end

    position = position + direction
    while (direction < 0 and position >= min) or (direction > 0 and position <= max) do
        if axis == X_AXIS then
            if self:IsPositionSelectable(position, currentY) then
                foundValidPosition = true
                break
            end
        else
            if self:IsPositionSelectable(currentX, position) then
                foundValidPosition = true
                break
            end
        end 
        position = position + direction
    end

    if axis == X_AXIS and not foundValidPosition then
        local newX = currentX + direction
        if newX >= min and newX <= max then
            local retX, retY
            foundValidPosition, retX, retY = self:GetNearestSelectablePosition(newX, currentY, 1, Y_AXIS)
            if foundValidPosition then
                return foundValidPosition, retX, retY
            else
                return self:GetNearestSelectablePosition(newX, currentY, -1, Y_AXIS)
            end
        end
    end

    if axis == X_AXIS then
        return foundValidPosition, position, currentY
    else
        return foundValidPosition, currentX, position
    end
end

function ZO_GuildRanks_Gamepad:MoveChangePermissionSelection(deltaX, deltaY)
    local newX = self.selectedPermission.x
    local newY = self.selectedPermission.y
    local foundValidPosition = false

    if deltaX ~= 0 then
        foundValidPosition, newX, newY = self:GetNearestSelectablePosition(self.selectedPermission.x, self.selectedPermission.y, deltaX, X_AXIS)
    elseif deltaY ~= 0 then
        foundValidPosition, newX, newY = self:GetNearestSelectablePosition(self.selectedPermission.x, self.selectedPermission.y, deltaY, Y_AXIS)
    end

    if foundValidPosition then
        self.selectedPermission.x = newX
        self.selectedPermission.y = newY
        self:RefreshContent()
    end
end

function ZO_GuildRanks_Gamepad:GetSelectedPermissionControl()
    for i = 1, #self.permissionControls do
        local permissionControl = self.permissionControls[i]

        if(permissionControl.coord.x == self.selectedPermission.x and permissionControl.coord.y == self.selectedPermission.y) then
            return permissionControl
        end
    end

    return nil
end

function ZO_GuildRanks_Gamepad:SetChangePermissionsEnabled(state)
    if(self.changePermissionsEnabled ~= state) then
        if(state) then
            self:DeactivateOptionsList()
            DIRECTIONAL_INPUT:Activate(self, self.control)
        elseif(self.changePermissionsEnabled) then
            DIRECTIONAL_INPUT:Deactivate(self)
            self:ActivateOptionsList()
        end

        self.selectorBoxControl:SetHidden(not state)

        self.changePermissionsEnabled = state
    end
end

function ZO_GuildRanks_Gamepad:RefreshChangePermissions()
    local selectedPermissionControl = self:GetSelectedPermissionControl()
    if(selectedPermissionControl ~= nil) then
        local iconControl = selectedPermissionControl:GetNamedChild("Icon")
        if(iconControl ~= nil) then
            self.selectorBoxControl:SetAnchor(CENTER, iconControl, CENTER, 0, 1)
        end
        
        self.selectorBoxControl.selectedRank = self.selectedRank
        self.selectorBoxControl.selectedPermission = selectedPermissionControl.permission
    end

    self:RefreshPermissionsSummary(self.selectedRank)
end

-----------------
-- Permissions --
-----------------

function ZO_GuildRanks_Gamepad:InitializePermissionsFragment()
    self.permissionControls = {}

    local permissionId = 0
    local currentRow, previousRow
    for rowIndex = 1, #GAMEPAD_GUILD_RANKS_PERMISSIONS do
        previousRow = currentRow
        currentRow = CreateControlFromVirtual("ZO_GuildRanksPermissionRow_Gamepad", self.permissionsSummaryScrollChild, "ZO_GuildPermissionRow_Gamepad", rowIndex)

        if previousRow then
            currentRow:SetAnchor(TOPLEFT, previousRow, BOTTOMLEFT, 0, PERMISSION_PADDING)
        else
            currentRow:SetAnchor(TOPLEFT, nil, TOPLEFT, 0, 0)
        end

        for columnIndex = 1, GAMEPAD_GUILD_RANKS_PERMISSIONS_NUM_COLUMNS do
            local rowInfo = GAMEPAD_GUILD_RANKS_PERMISSIONS[rowIndex]
            if(rowInfo[columnIndex] ~= nil) then
                permissionId = permissionId + 1

                local permission = rowInfo[columnIndex]
                local template

                local isHeader = false
                
                if(type(permission) == "string") then -- this is a header
                    template = "ZO_GuildPermissionHeader_Gamepad"
                    isHeader = true
                else
                    template = "ZO_GuildPermission_Gamepad"
                end
                local permissionControl = CreateControlFromVirtual("ZO_GuildRanksPermission_Gamepad", currentRow, template, permissionId)

                permissionControl.permission = permission

                if columnIndex == 1 then
                    permissionControl:SetAnchor(TOPLEFT, nil, TOPLEFT, 0, 0)
                else
                    permissionControl:SetAnchor(TOPLEFT, nil, TOPLEFT, (columnIndex - 1) * ZO_GAMEPAD_GUILD_RANKS_PERMISSION_COLUMN_WIDTH)
                end

                if(isHeader) then
                    permissionControl.label:SetText(permission)
                else
                    permissionControl.coord = {}
                    permissionControl.coord.x = columnIndex
                    permissionControl.coord.y = rowIndex

                    table.insert(self.permissionControls, permissionControl)

                    local text = GetString("SI_GUILDPERMISSION", permission)

                    --Chat options have special voice chat related labels for console
                    if IsConsoleUI() then
                        if permission == GUILD_PERMISSION_CHAT then
                            text = GetString(SI_GAMEPAD_GUILD_RANK_PERMISSIONS_JOIN_GUILD_CHANNEL)    
                        elseif permission == GUILD_PERMISSION_OFFICER_CHAT_WRITE then
                            text = GetString(SI_GAMEPAD_GUILD_RANK_PERMISSIONS_JOIN_OFFICER_CHANNEL)    
                        end
                    end

                    permissionControl.label:SetText(text)
                end
            end
        end
    end
end

function ZO_GuildRanks_Gamepad:RefreshPermissionsSummary(rank)
    local canPlayerEditPermissions = DoesPlayerHaveGuildPermission(self.guildId, GUILD_PERMISSION_PERMISSION_EDIT)
    for i = 1, #self.permissionControls do
        local permissionControl = self.permissionControls[i]
        local permissionEnabled = ZO_GuildRank_Shared.IsPermissionSet(rank, permissionControl.permission)

        if(permissionControl.icon) then
            permissionControl.icon:SetHidden(not permissionEnabled)
            if(self:IsDisplayingChangePermissions() and self.selectorBoxControl.selectedPermission == permissionControl.permission) then
                permissionControl.label:SetColor(ZO_SELECTED_TEXT:UnpackRGBA())
            elseif(permissionEnabled) then
                permissionControl.label:SetColor(ZO_NORMAL_TEXT:UnpackRGBA())
            else
                permissionControl.label:SetColor(ZO_DISABLED_TEXT:UnpackRGBA())
            end
        end
    end
end

------------------
-- Reorder Rank --
------------------

function ZO_GuildRanks_Gamepad:GetSelectedRankIndex()
    return self:GetRankIndexById(self.selectedRank:GetRankId())
end

function ZO_GuildRanks_Gamepad:IsGuildMasterSelected()
    if(self.selectedRank ~= nil and self.selectedRank.index ~= nil) then
        return IsGuildRankGuildMaster(self.guildId, self.selectedRank.index)
    end

    return false
end

function ZO_GuildRanks_Gamepad:IsLastRankSelected()
    return self:GetSelectedRankIndex() >= #self.ranks
end

function ZO_GuildRanks_Gamepad:InSecondRankSelected()

    return self:GetSelectedRankIndex() <= GUILDMASTER_INDEX + 1
end

function ZO_GuildRanks_Gamepad:ReorderSelectedRank(up)
    if(self.selectedRank ~= nil) then
        local oldIndex = self:GetSelectedRankIndex()
        local newIndex = oldIndex
        if(up) then
            newIndex = newIndex - 1
        else
            newIndex = newIndex + 1
        end

        newIndex = zo_clamp(newIndex, GUILDMASTER_INDEX + 1, #self.ranks)

        if(newIndex ~= oldIndex) then
            local tmp = self.ranks[oldIndex]
            self.ranks[oldIndex] = self.ranks[newIndex]
            self.ranks[newIndex] = tmp

            PlaySound(SOUNDS.GUILD_RANK_REORDERED)

            self:ActivateRankList(REFRESH_SCREEN)
            self.rankList:SetSelectedIndexWithoutAnimation(newIndex)
        end
    end
end

------------------------
-- Delete Rank Dialog --
------------------------

function ZO_GuildRanks_Gamepad:DeleteSelectedRank()
    local index = self:GetSelectedRankIndex()
    table.remove(self.ranks, index)
    self:ResetRankSelection()

    PlaySound(SOUNDS.GUILD_RANK_DELETED)
    self:ActivateRankList(REFRESH_SCREEN)
    self.rankList:SetSelectedIndexWithoutAnimation(1)
end

--------------------
-- Key Bind Strip --
--------------------

function ZO_GuildRanks_Gamepad:InitializeKeybindStrip()
    self.keybindStripDescriptor = {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,

        -- select
        {
            name = function()
                return GetString(SI_GAMEPAD_SELECT_OPTION)
            end,

            keybind = "UI_SHORTCUT_PRIMARY",

            callback = function()
                if(self:IsDisplayingOptionsList()) then
                    local selectedOptionsData = self.optionsList:GetTargetData()
                    if(selectedOptionsData ~= nil and selectedOptionsData.callback ~= nil) then
                        selectedOptionsData.callback()
                    end
                elseif(self:IsDisplayingRankList()) then
                    local selectedRankData = self.rankList:GetTargetData()
                    if(selectedRankData.addRank) then
                        selectedRankData.callback()
                    else
                        PlaySound(SOUNDS.GAMEPAD_MENU_FORWARD)
                        self:ActivateOptionsList(REFRESH_SCREEN)
                    end
                elseif(self:IsDisplayingIconSelector()) then
                    self:SelectHighlightedIcon()
                    
                    PlaySound(SOUNDS.DIALOG_ACCEPT)
                    self:ActivateOptionsList(REFRESH_SCREEN)
                elseif(self:IsDisplayingChangePermissions()) then
                    if(not self.selectorBoxControl:IsHidden()) then
                        PlaySound(SOUNDS.DIALOG_ACCEPT)
                        local isPermissionSet = ZO_GuildRank_Shared.IsPermissionSet(self.selectorBoxControl.selectedRank, self.selectorBoxControl.selectedPermission)
                        ZO_GuildRank_Shared.SetPermission(self.selectorBoxControl.selectedRank, self.selectorBoxControl.selectedPermission, not isPermissionSet)
                        self:RefreshPermissionsSummary(self.selectorBoxControl.selectedRank)
                    end
                end
            end,

            visible = function()
                return DoesPlayerHaveGuildPermission(self.guildId, GUILD_PERMISSION_PERMISSION_EDIT) and #self.ranks > 0
            end,
        },

        -- back
        {
            name = GetString(SI_GAMEPAD_BACK_OPTION),
            keybind = "UI_SHORTCUT_NEGATIVE",

            callback = function()
                if(self:IsDisplayingRankList()) then
                    GAMEPAD_GUILD_HUB:SetEnterInSingleGuildList(true)
                    SCENE_MANAGER:Hide(GAMEPAD_GUILD_HOME_SCENE_NAME)
                elseif(self:IsDisplayingIconSelector() or self:IsDisplayingChangePermissions()) then
                    PlaySound(SOUNDS.GAMEPAD_MENU_BACK)
                    self:ActivateOptionsList(REFRESH_SCREEN)
                    self:RefreshPermissionsSummary(self.selectedRank)
                else
                    PlaySound(SOUNDS.GAMEPAD_MENU_BACK)
                    self:ActivateRankList(REFRESH_SCREEN)
                end
            end,
        },
    }
end

-------------
-- Options --
-------------
do
    local ICON_PERMISSIONS = "EsoUI/Art/Guild/Gamepad/gp_guild_options_permissions.dds"
    local ICON_RENAME = "EsoUI/Art/Guild/Gamepad/gp_guild_options_rename.dds"
    local ICON_DELETE = "EsoUI/Art/Guild/Gamepad/gp_guild_options_delete.dds"
    local ICON_CHANGE_ICON = "EsoUI/Art/Guild/Gamepad/gp_guild_options_changeIcon.dds"
    local ICON_REORDER_UP = "EsoUI/Art/Guild/Gamepad/gp_guild_options_reorder_up.dds"
    local ICON_REORDER_DOWN = "EsoUI/Art/Guild/Gamepad/gp_guild_options_reorder_down.dds"
    
    function ZO_GuildRanks_Gamepad:RefreshOptionsList()
        if(self.selectedRank ~= nil) then
            local isGuildmasterRankSelected = self:IsGuildMasterSelected()
            self.optionsList:Clear()
    
            local data = nil
    
            local firstEntry = true
    
            local function AddEntry(data)
                data:SetIconTintOnSelection(true)
                if(firstEntry) then
                    data:SetHeader(GetString(SI_GAMEPAD_GUILD_RANK_OPTIONS)) 
                    self.optionsList:AddEntryWithHeader(GAMEPAD_GUILD_RANKS_MENU_ENTRY_TEMPLATE, data)
                    firstEntry = false
                else
                    self.optionsList:AddEntry(GAMEPAD_GUILD_RANKS_MENU_ENTRY_TEMPLATE, data)
                end
            end
    
            local canChangePermissions = DoesPlayerHaveGuildPermission(self.guildId, GUILD_PERMISSION_PERMISSION_EDIT) and #self.ranks > 0 and (not self:IsGuildMasterSelected())
            if(canChangePermissions) then
                data = ZO_GamepadEntryData:New(GetString(SI_GAMEPAD_GUILD_RANK_CHANGE_PERMISSIONS), ICON_PERMISSIONS)
                data.callback = function()
                    PlaySound(SOUNDS.GAMEPAD_MENU_FORWARD)
                    self.listDisplayMode = LIST_DISPLAY_MODES.CHANGE_PERMISSIONS
                    self:RefreshScreen()
                end
                AddEntry(data)
            end
    
            data = ZO_GamepadEntryData:New(GetString(SI_GAMEPAD_GUILD_RANK_RENAME_ENTRY), ICON_RENAME)
            data.callback = function()
                ZO_Dialogs_ShowGamepadDialog(GUILD_RENAME_RANK_GAMEPAD_DIALOG)
            end
            AddEntry(data)
    
            if(not isGuildmasterRankSelected) then
                data = ZO_GamepadEntryData:New(GetString(SI_GAMEPAD_GUILD_RANK_DELETE_ENTRY), ICON_DELETE)
                data.callback = function()
                    if(self:IsRankOccupied(self.selectedRank)) then
                        ZO_Dialogs_ShowGamepadDialog(GUILD_DELETE_RANK_GAMEPAD_WARNING_DIALOG, nil, { buttonKeybindOverrides = { "DIALOG_PRIMARY" } })
                    else
                        ZO_Dialogs_ShowGamepadDialog(GUILD_DELETE_RANK_GAMEPAD_DIALOG)
                    end
                end
                AddEntry(data)
            end
    
            data = ZO_GamepadEntryData:New(GetString(SI_GAMEPAD_GUILD_RANK_CHANGE_ICON), ICON_CHANGE_ICON)
            data.callback = function()
                PlaySound(SOUNDS.GAMEPAD_MENU_FORWARD)
                self.listDisplayMode = LIST_DISPLAY_MODES.SELECT_ICON
                self:DeactivateOptionsList()
                self.iconSelector:Activate()
                self:RefreshScreen()
            end
            AddEntry(data)
    
            if(not isGuildmasterRankSelected) then
                if(not self:InSecondRankSelected()) then
                    data = ZO_GamepadEntryData:New(GetString(SI_GAMEPAD_GUILD_RANK_REORDER_UP), ICON_REORDER_UP)
                    data.unfadeRankList = true
                    data.callback = function()
                        self:ReorderSelectedRank(true)
                    end
                    AddEntry(data)
                end
            
                if(not self:IsLastRankSelected()) then
                    data = ZO_GamepadEntryData:New(GetString(SI_GAMEPAD_GUILD_RANK_REORDER_DOWN), ICON_REORDER_DOWN)
                    data.unfadeRankList= true
                    data.callback = function()
                        self:ReorderSelectedRank(false)
                    end
                    AddEntry(data)
                end
            end
    
            self.optionsList:Commit()
        end
    end
end
---------------
-- Add Rank --
---------------

function ZO_GuildRanks_Gamepad:AddRank(rankName, copyPermissionsFromRankIndex)
    local rank = ZO_GuildRank_Shared:New(GUILD_RANKS_GAMEPAD, self.guildId, nil, rankName)
    
    local newRankIndex = self:InsertRank(rank, copyPermissionsFromRankIndex)

    self:RefreshScreen()
    
    self.rankList:SetSelectedIndexWithoutAnimation(newRankIndex)
end

---------------
-- Rank List --
---------------

function ZO_GuildRanks_Gamepad:OnTargetChanged(list, selectedData, oldSelectedData)
    if(selectedData ~= nil) then
        if(selectedData.addRank) then
            self:RemoveUnusedFragments()

            self.selectedRank = nil
        elseif(selectedData.rankObject ~= nil and self.selectedRank ~= selectedData.rankObject) then
            self.selectedRank = selectedData.rankObject
            self:RefreshPermissionsSummary(self.selectedRank)
            self:RefreshContent()
        end
    end

    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_GuildRanks_Gamepad:CancelDialog()
    self:RefreshScreen()
end

function ZO_GuildRanks_Gamepad:PopulateRanks()
    self:ResetRankSelection(false)

    self.ranks = {}

    if(self.guildId) then
        for i = 1, GetNumGuildRanks(self.guildId) do
            local rankObject = ZO_GuildRank_Shared:New(GUILD_RANKS_GAMEPAD, self.guildId, i)
            self.ranks[i] = rankObject
        end
    end
end

function ZO_GuildRanks_Gamepad:RefreshRankList()
    self.rankList:Clear()

    local rankPermission = DoesPlayerHaveGuildPermission(self.guildId, GUILD_PERMISSION_PERMISSION_EDIT)
    
    for i = 1, #self.ranks do
        local rankObject = self.ranks[i]

        local data = ZO_GamepadEntryData:New(rankObject:GetName(), rankObject:GetLargeIcon())
        data:SetIconTintOnSelection(true)
        data.rankObject = rankObject

        if i == 1 then
            local headerText = GetString(SI_WINDOW_TITLE_GUILD_RANKS)
            if(rankPermission) then
                headerText = GetString(SI_GAMEPAD_GUILD_RANK_EDIT)
            end
            data:SetHeader(headerText) 
            self.rankList:AddEntryWithHeader(GAMEPAD_GUILD_RANKS_MENU_ENTRY_TEMPLATE, data)
        else
            self.rankList:AddEntry(GAMEPAD_GUILD_RANKS_MENU_ENTRY_TEMPLATE, data)
        end
    end

    local addRankEnabled = #self.ranks < MAX_GUILD_RANKS and rankPermission
    if(addRankEnabled) then
        local data = ZO_GamepadEntryData:New(GetString(SI_GAMEPAD_GUILD_RANK_ADD), "EsoUI/Art/Buttons/Gamepad/gp_plus_large.dds")
        data:SetIconTintOnSelection(true)
        data.addRank = true
        data.callback = function()
            ZO_Dialogs_ShowGamepadDialog(ADD_RANK_DIALOG_NAME)
        end
        data:SetHeader(GetString(SI_GAMEPAD_GUILD_RANK_NEW_HEADER)) 
        self.rankList:AddEntryWithHeader(GAMEPAD_GUILD_RANKS_MENU_ENTRY_TEMPLATE, data)
    end

    self.rankList:Commit()
end
