local function IsChatNarrationEnabled()
    return GetSetting_Bool(SETTING_TYPE_ACCESSIBILITY, ACCESSIBILITY_SETTING_TEXT_CHAT_NARRATION)
end

local function IsScreenNarrationEnabled()
    return GetSetting_Bool(SETTING_TYPE_ACCESSIBILITY, ACCESSIBILITY_SETTING_SCREEN_NARRATION)
end

local NARRATION_ENTRY_TYPE_PARAMETRIC_LIST_ENTRY = 1
local NARRATION_ENTRY_TYPE_SORT_FILTER_LIST_ENTRY = 2
local NARRATION_ENTRY_TYPE_SORT_HEADER = 3
local NARRATION_ENTRY_TYPE_COMBO_BOX = 4
local NARRATION_ENTRY_TYPE_GRID_LIST_ENTRY = 5
local NARRATION_ENTRY_TYPE_TEXT_SEARCH_HEADER = 6
local NARRATION_ENTRY_TYPE_DIALOG = 7
local NARRATION_ENTRY_TYPE_FADING_CONTROL_BUFFER = 8
local NARRATION_ENTRY_TYPE_FOCUS_ENTRY = 9
local NARRATION_ENTRY_TYPE_GAMEPAD_GRID_ENTRY = 10
local NARRATION_ENTRY_TYPE_SPINNER = 11
local NARRATION_ENTRY_TYPE_GAMEPAD_BUTTON_TAB_BAR = 12
local NARRATION_ENTRY_TYPE_CUSTOM = 13

local SCREEN_NARRATION_QUEUE_DELAY_MS = 250

internalassert(NARRATION_TYPE_MAX_VALUE == 5, "A new narration type has been added, does it need to be added to the QUEUEABLE_NARRATION_TYPES table?")

--Narration types able to be used when queueing something up for narration. Narration for types not in this table should be sent straight to the C++
local QUEUEABLE_NARRATION_TYPES =
{
    [NARRATION_TYPE_UI_SCREEN] = true,
    [NARRATION_TYPE_HUD] = true,
    [NARRATION_TYPE_ALERT] = true,
}

--The narration queue each entry type will go into by default
local DEFAULT_NARRATION_TYPES =
{
    [NARRATION_ENTRY_TYPE_PARAMETRIC_LIST_ENTRY] = NARRATION_TYPE_UI_SCREEN,
    [NARRATION_ENTRY_TYPE_SORT_FILTER_LIST_ENTRY] = NARRATION_TYPE_UI_SCREEN,
    [NARRATION_ENTRY_TYPE_SORT_HEADER] = NARRATION_TYPE_UI_SCREEN,
    [NARRATION_ENTRY_TYPE_COMBO_BOX] = NARRATION_TYPE_UI_SCREEN,
    [NARRATION_ENTRY_TYPE_GRID_LIST_ENTRY] = NARRATION_TYPE_UI_SCREEN,
    [NARRATION_ENTRY_TYPE_TEXT_SEARCH_HEADER] = NARRATION_TYPE_UI_SCREEN,
    [NARRATION_ENTRY_TYPE_DIALOG] = NARRATION_TYPE_UI_SCREEN,
    [NARRATION_ENTRY_TYPE_FADING_CONTROL_BUFFER] = NARRATION_TYPE_ALERT,
    [NARRATION_ENTRY_TYPE_FOCUS_ENTRY] = NARRATION_TYPE_UI_SCREEN,
    [NARRATION_ENTRY_TYPE_GAMEPAD_GRID_ENTRY] = NARRATION_TYPE_UI_SCREEN,
    [NARRATION_ENTRY_TYPE_SPINNER] = NARRATION_TYPE_UI_SCREEN,
    [NARRATION_ENTRY_TYPE_GAMEPAD_BUTTON_TAB_BAR] = NARRATION_TYPE_UI_SCREEN,
    [NARRATION_ENTRY_TYPE_CUSTOM] = NARRATION_TYPE_UI_SCREEN,
}

local function GetDefaultNarrationType(narrationEntryType)
    return DEFAULT_NARRATION_TYPES[narrationEntryType]
end

---------------------------------------------
-- Narratable Object
---------------------------------------------

ZO_NarratableObject = ZO_PooledObject:Subclass()

function ZO_NarratableObject:Initialize()
    self.narrationStrings = {}
end

function ZO_NarratableObject:Reset()
    ZO_ClearNumericallyIndexedTable(self.narrationStrings)
    self.pauseTime = nil
    self.delimiter = nil
end

--Adds the specified narration text. Narration text can be a string, table of strings, or number
--If addToFront is true, the text will be added to the front of the narration
function ZO_NarratableObject:AddNarrationText(narrationText, addToFront)
    if not narrationText or narrationText == "" then
        return
    end

    if type(narrationText) == "string" then
        if addToFront then
            table.insert(self.narrationStrings, 1, narrationText)
        else
            table.insert(self.narrationStrings, narrationText)
        end
    elseif type(narrationText) == "table" then
        if addToFront then
            ZO_CombineNumericallyIndexedTables(narrationText, self.narrationStrings)
            self.narrationStrings = narrationText
        else
            ZO_CombineNumericallyIndexedTables(self.narrationStrings, narrationText)
        end
    elseif type(narrationText) == "number" then
        if addToFront then
            table.insert(self.narrationStrings, 1, tostring(narrationText))
        else
            table.insert(self.narrationStrings, tostring(narrationText))
        end
    else
        internalassert(false, string.format("%s is not a valid value for narrationText", narrationText))
    end
end

--Sets the pause time to use when forming the final narration string
--Pause time and delimiter are mutually exclusive; setting one will clear the other
function ZO_NarratableObject:SetPauseTimeMS(pauseTime)
    self.pauseTime = pauseTime
    self.delimiter = nil
end

--Sets the delimiter to use when forming the final narration string
--Pause time and delimiter are mutually exclusive; setting one will clear the other
function ZO_NarratableObject:SetDelimiter(delimiter)
    self.delimiter = delimiter
    self.pauseTime = nil
end

function ZO_NarratableObject:AddToPending()
    --If we don't have any strings, don't bother
    if #self.narrationStrings > 0 then
        --If a delimiter is set use that, otherwise fall back to pause time
        if self.delimiter then
            AddPendingNarrationText(ZO_GenerateDelimiterSeparatedList(self.narrationStrings, self.delimiter))
        else
            for _, narrationString in ipairs(self.narrationStrings) do
                AddPartialPendingNarrationText(narrationString)
            end
            FinalizePartialPendingNarrationText(self.pauseTime)
        end
    end
end

---------------------------------------------
-- Screen Narration Params
---------------------------------------------

ZO_ScreenNarrationParams = ZO_PooledObject:Subclass()

function ZO_ScreenNarrationParams:Initialize()
    self:Reset()
end

function ZO_ScreenNarrationParams:Reset()
    --Calling ZO_ClearTable on self will clear out any variables that were set on this object
    ZO_ClearTable(self)
    self.startTimeMs = 0
end

function ZO_ScreenNarrationParams:SetStartTimeMS(startTimeMs)
    self.startTimeMs = startTimeMs
end

function ZO_ScreenNarrationParams:GetStartTimeMS()
    return self.startTimeMs
end

function ZO_ScreenNarrationParams:SetNarrationBlocked(isBlocked)
    self.isBlocked = isBlocked
end

function ZO_ScreenNarrationParams:GetNarrationBlocked()
    return self.isBlocked
end

function ZO_ScreenNarrationParams:SetNarrationType(narrationType)
    self.narrationType = narrationType
end

function ZO_ScreenNarrationParams:GetNarrationType()
    if self.narrationType then
        return self.narrationType
    else
        return GetDefaultNarrationType(self:GetNarrationEntryType())
    end
end

function ZO_ScreenNarrationParams:SetNarrationEntryType(narrationEntryType)
    self.narrationEntryType = narrationEntryType
end

function ZO_ScreenNarrationParams:GetNarrationEntryType()
    return self.narrationEntryType
end

function ZO_ScreenNarrationParams:GetNarrateHeader()
    return self.narrateHeader
end

function ZO_ScreenNarrationParams:GetNarrateSubHeader()
    return self.narrateSubHeader
end

function ZO_ScreenNarrationParams:SetParametricList(list, narrateHeader)
    self.parametricList = list
    self.narrateHeader = narrateHeader
end

function ZO_ScreenNarrationParams:GetParametricList()
    return self.parametricList
end

function ZO_ScreenNarrationParams:SetGridList(gridList, narrateHeader, narrateSubHeader)
    self.gridList = gridList
    self.narrateHeader = narrateHeader
    self.narrateSubHeader = narrateSubHeader
end

function ZO_ScreenNarrationParams:GetGridList()
    return self.gridList
end

function ZO_ScreenNarrationParams:SetGamepadGrid(gamepadGrid, narrateHeader)
    self.gamepadGrid = gamepadGrid
    self.narrateHeader = narrateHeader
end

function ZO_ScreenNarrationParams:GetGamepadGrid()
    return self.gamepadGrid
end

function ZO_ScreenNarrationParams:SetSelectedSortHeader(sortHeaderGroup, key)
    self.sortHeaderGroup = sortHeaderGroup
    self.selectedSortHeaderKey = key
end

function ZO_ScreenNarrationParams:GetSortHeaderGroup()
    return self.sortHeaderGroup
end

function ZO_ScreenNarrationParams:GetSelectedSortHeaderKey()
    return self.selectedSortHeaderKey
end

function ZO_ScreenNarrationParams:SetComboBox(comboBox)
    self.comboBox = comboBox
end

function ZO_ScreenNarrationParams:GetComboBox()
    return self.comboBox
end

function ZO_ScreenNarrationParams:SetSpinner(spinner, narrateHeader)
    self.spinner = spinner
    self.narrateHeader = narrateHeader
end

function ZO_ScreenNarrationParams:GetSpinner()
    return self.spinner
end

function ZO_ScreenNarrationParams:SetGamepadButtonTabBar(tabBar)
    self.gamepadButtonTabBar = tabBar
end

function ZO_ScreenNarrationParams:GetGamepadButtonTabBar()
    return self.gamepadButtonTabBar
end

function ZO_ScreenNarrationParams:SetTextSearchHeader(textSearchHeader, narrateHeader)
    self.textSearchHeader = textSearchHeader
    self.narrateHeader = narrateHeader
end

function ZO_ScreenNarrationParams:GetTextSearchHeader(textSearchHeader)
    return self.textSearchHeader
end

function ZO_ScreenNarrationParams:SetDialog(dialog, narrateBaseText)
    self.dialog = dialog
    self.narrateDialogBaseText = narrateBaseText
end

function ZO_ScreenNarrationParams:GetDialog()
    return self.dialog
end

function ZO_ScreenNarrationParams:GetNarrateDialogBaseText()
    return self.narrateDialogBaseText
end

function ZO_ScreenNarrationParams:SetFadingControlBuffer(fadingControlBuffer)
    self.fadingControlBuffer = fadingControlBuffer
end

function ZO_ScreenNarrationParams:GetFadingControlBuffer()
    return self.fadingControlBuffer
end

function ZO_ScreenNarrationParams:SetFocus(focus, narrateHeader, narrateSubHeader)
    self.focus = focus
    self.narrateHeader = narrateHeader
    self.narrateSubHeader = narrateSubHeader
end

function ZO_ScreenNarrationParams:GetFocus()
    return self.focus
end

function ZO_ScreenNarrationParams:SetCustomObjectName(objectName, narrateHeader)
    self.customObjectName = objectName
    self.narrateHeader = narrateHeader
end

function ZO_ScreenNarrationParams:GetCustomObjectName()
    return self.customObjectName
end

---------------------------------------------
-- Screen Narration Manager
---------------------------------------------

ZO_ScreenNarrationManager = ZO_InitializingCallbackObject:Subclass()

function ZO_ScreenNarrationManager:Initialize()
    SCREEN_NARRATION_MANAGER = self
    self.parametricListTargetChangedCallback = function(list, targetData, oldTargetData, reachedTarget, targetSelectedIndex, reselectingDuringRebuild)
        local narrationInfo = self.parametricListNarrationInfo[list]
        if narrationInfo:canNarrate() and not reselectingDuringRebuild then
            self:QueueParametricListEntry(list)
        end
    end

    self.parametricListActivatedChangedCallback = function(list, activated)
        if activated then
            local NARRATE_HEADER = true
            self:QueueParametricListEntry(list, NARRATE_HEADER)
        end
    end

    --Re-narrate any active parametric lists upon hiding dialogs
    self.parametricListAllDialogsHiddenCallback = function(list)
        if list:IsActive() then
            local NARRATE_HEADER = true
            self:QueueParametricListEntry(list, NARRATE_HEADER)
        end
    end

    self.parametricListMovementChangedCallback = function(list, isMoving)
        local queuedNarration = self:GetQueuedNarration(GetDefaultNarrationType(NARRATION_ENTRY_TYPE_PARAMETRIC_LIST_ENTRY))
        if queuedNarration and queuedNarration:GetParametricList() == list then
            queuedNarration:SetNarrationBlocked(isMoving)
        end
    end

    self.comboBoxItemSelectedCallback = function(control, data, comboBox)
        self:QueueComboBox(comboBox)
    end

    self.gridListAllDialogsHiddenCallback = function(gridList)
        if gridList:IsActive() then
            local NARRATE_HEADER = true
            local NARRATE_SUB_HEADER = true
            self:QueueGridListEntry(gridList, NARRATE_HEADER, NARRATE_SUB_HEADER)
        end
    end

    self.gamepadGridAllDialogsHiddenCallback = function(gamepadGrid)
        if gamepadGrid:IsActive() then
            local NARRATE_HEADER = true
            self:QueueGamepadGridEntry(gamepadGrid, NARRATE_HEADER)
        end
    end

    self.spinnerAllDialogsHiddenCallback = function(spinner)
        if spinner:IsActive() then
            local NARRATE_HEADER = true
            self:QueueSpinner(spinner, NARRATE_HEADER)
        end
    end

    self.customObjectAllDialogsHiddenCallback = function(objectName)
        local narrationInfo = self.customObjectNarrationInfo[objectName]
        if narrationInfo and narrationInfo:canNarrate() then
            local NARRATE_HEADER = true
            self:QueueCustomEntry(objectName, NARRATE_HEADER)
        end
    end

    self.parametricListNarrationInfo = {}
    self.customObjectNarrationInfo = {}
    self.textSearchHeaderNarrationInfo = {}
    self.queuedNarrations = {}
    self.isLoading = not GetGuiHidden("app")

    self:RegisterForEvents()
    self:InitializeNarrationPools()
end

function ZO_ScreenNarrationManager:RegisterForEvents()
    local function OnUpdate()
        --Do not start any narrations while a load screen is active
        if self.isLoading then
            return
        end

        local currentTimeMs = GetFrameTimeMilliseconds()
        --Loop through each queue and try to narrate anything that is able
        for narrationType = NARRATION_TYPE_ITERATION_BEGIN, NARRATION_TYPE_ITERATION_END do
            local queuedNarration = self:GetQueuedNarration(narrationType)
            if queuedNarration then
                --If a narration has been set to blocked, it will stay in the queue until we set blocked to false or it is replaced by something else
                if not queuedNarration:GetNarrationBlocked() and queuedNarration.startTimeMs <= currentTimeMs then
                    self:TryNarration(queuedNarration)
                    self:ClearQueuedNarration(narrationType)
                end
            end
        end
    end

    local function OnAppGuiHiddenStateChanged(_, hidden)
        self.isLoading = not hidden
        SetTextChatNarrationQueueEnabled(hidden)
        SetCenterScreenAnnounceNarrationQueueEnabled(hidden)
        if self.isLoading then
            --Loop through each queueable narration type and clear out the queue
            for narrationType = NARRATION_TYPE_ITERATION_BEGIN, NARRATION_TYPE_ITERATION_END do
                if QUEUEABLE_NARRATION_TYPES[narrationType] then
                    self:ClearQueuedNarration(narrationType)
                end
            end
        end
    end

    EVENT_MANAGER:RegisterForUpdate("ScreenNarrationUpdate", 0, OnUpdate)
    EVENT_MANAGER:RegisterForEvent("ScreenNarrationManager", EVENT_APP_GUI_HIDDEN_STATE_CHANGED, OnAppGuiHiddenStateChanged)
end

function ZO_ScreenNarrationManager:InitializeNarrationPools()
    local function NarrationParamFactory(pool)
        return ZO_ScreenNarrationParams:New()
    end

    local function NarrationParamReset(params)
        params:Reset()
    end

    local function NarrationParamAcquire(object, objectKey)
        --Narration params need to re-set their pool and key each time we acquire due to us calling ZO_ClearTable(self) in the reset
        object:SetPoolAndKey(self.narrationParamsPool, objectKey)
    end

    self.narrationParamsPool = ZO_ObjectPool:New(NarrationParamFactory, NarrationParamReset)
    self.narrationParamsPool:SetCustomAcquireBehavior(NarrationParamAcquire)

    local function NarratableObjectFactory(pool, key)
        local narratableObject = ZO_NarratableObject:New()
        narratableObject:SetPoolAndKey(pool, key)
        return narratableObject
    end

    local function NarratableObjectReset(narratableObject)
        narratableObject:Reset()
    end

    self.narratableObjectPool = ZO_ObjectPool:New(NarratableObjectFactory, NarratableObjectReset)
end

function ZO_ScreenNarrationManager:RegisterCustomObject(objectName, narrationInfo)
    if self.customObjectNarrationInfo[objectName] then
        local assertMessage = string.format("A custom narration object with the name \"%s\" has already been registered.", objectName)
        internalassert(false, assertMessage)
    end

    CALLBACK_MANAGER:RegisterCallback("AllDialogsHidden", self.customObjectAllDialogsHiddenCallback, objectName)
    self.customObjectNarrationInfo[objectName] = narrationInfo
end

function ZO_ScreenNarrationManager:RegisterParametricList(list, narrationInfo)
    list:RegisterCallback("TargetDataChanged", self.parametricListTargetChangedCallback)
    list:RegisterCallback("ActivatedChanged", self.parametricListActivatedChangedCallback)
    list:RegisterCallback("MovementChanged", self.parametricListMovementChangedCallback)
    CALLBACK_MANAGER:RegisterCallback("AllDialogsHidden", self.parametricListAllDialogsHiddenCallback, list)
    --Store off the associated parametric list narration info for this list, so we can access it later
    self.parametricListNarrationInfo[list] = narrationInfo
end

function ZO_ScreenNarrationManager:RegisterParametricListScreen(list, screen)
    local narrationInfo =
    {
        canNarrate = function()
            return screen:IsShowing()
        end,
        headerNarrationFunction = function()
            return screen:GetHeaderNarration()
        end,
        footerNarrationFunction = function()
            return screen:GetFooterNarration()
        end,
    }
    self:RegisterParametricList(list, narrationInfo)
end

function ZO_ScreenNarrationManager:UnregisterParametricList(list)
    list:UnregisterCallback("TargetDataChanged", self.parametricListTargetChangedCallback)
    list:UnregisterCallback("ActivatedChanged", self.parametricListActivatedChangedCallback)
    list:UnregisterCallback("MovementChanged", self.parametricListMovementChangedCallback)
    CALLBACK_MANAGER:UnregisterCallback("AllDialogsHidden", self.parametricListAllDialogsHiddenCallback, list)
    self.parametricListNarrationInfo[list] = nil
    --Grab the currently queued narration for the matching narration type
    local narrationType = GetDefaultNarrationType(NARRATION_ENTRY_TYPE_PARAMETRIC_LIST_ENTRY)
    local queuedNarration = self:GetQueuedNarration(narrationType)
    --If the list we are unregistering is currently the queued narration, clear it
    if queuedNarration and queuedNarration:GetParametricList() == list then
        self:ClearQueuedNarration(narrationType)
    end
end

function ZO_ScreenNarrationManager:RegisterParametricListDialog(dialog)
    dialog.entryList:RegisterCallback("TargetDataChanged", function(list, targetData, oldTargetData, reachedTarget, targetSelectedIndex, reselectingDuringRebuild)
        if not reselectingDuringRebuild then
            self:QueueDialog(dialog)
        end
    end)

    dialog.entryList:RegisterCallback("ActivatedChanged", function(list, activated)
        if activated then
            self:QueueDialog(dialog)
        end
    end)
end

function ZO_ScreenNarrationManager:RegisterTextSearchHeader(textSearchHeader, narrationInfo)
    textSearchHeader:RegisterCallback("EditBoxFocusLost", function()
        self:QueueTextSearchHeader(textSearchHeader)
    end)

    textSearchHeader:RegisterCallback("FocusActivated", function()
        local NARRATE_HEADER = true
        self:QueueTextSearchHeader(textSearchHeader, NARRATE_HEADER)
    end)

    --Store off the associated text search header narration info for this text search header, so we can access it later
    self.textSearchHeaderNarrationInfo[textSearchHeader] = narrationInfo
end

function ZO_ScreenNarrationManager:RegisterGridList(gridList)
    gridList:SetOnSelectedDataChangedCallback(function(previousData, newData)
        if gridList:IsActive() and newData then
            local narrateSubHeader = false
            if previousData then
                local newGridHeaderData = newData.gridHeaderName or newData.gridHeaderData
                local previousGridHeaderData = previousData.gridHeaderName or previousData.gridHeaderData
                narrateSubHeader = newGridHeaderData ~= previousGridHeaderData
            end
            local DONT_NARRATE_HEADER = false
            self:QueueGridListEntry(gridList, DONT_NARRATE_HEADER, narrateSubHeader)
        end
    end)

    gridList:RegisterCallback("OnActivated", function(selectedData)
        local NARRATE_HEADER = true
        local NARRATE_SUB_HEADER = true
        self:QueueGridListEntry(gridList, NARRATE_HEADER, NARRATE_SUB_HEADER)
    end)

    CALLBACK_MANAGER:RegisterCallback("AllDialogsHidden", self.gridListAllDialogsHiddenCallback, gridList)
end

function ZO_ScreenNarrationManager:RegisterGamepadGrid(gamepadGrid)
    gamepadGrid:RegisterCallback("OnActivated", function()
        local NARRATE_HEADER = true
        self:QueueGamepadGridEntry(gamepadGrid, NARRATE_HEADER)
    end)

    gamepadGrid:RegisterCallback("FocusChanged", function()
        if gamepadGrid:IsActive() then
            self:QueueGamepadGridEntry(gamepadGrid)
        end
    end)

    CALLBACK_MANAGER:RegisterCallback("AllDialogsHidden", self.gamepadGridAllDialogsHiddenCallback, gamepadGrid)
end

function ZO_ScreenNarrationManager:RegisterComboBox(comboBox)
    comboBox:RegisterCallback("OnItemSelected", self.comboBoxItemSelectedCallback)
end

function ZO_ScreenNarrationManager:RegisterDialogDropdown(dialog, dropdown)
    dropdown:RegisterCallback("OnDeactivated", function()
        self:QueueDialog(dialog)
    end)
end

function ZO_ScreenNarrationManager:RegisterSpinner(spinner)
    spinner:RegisterCallback("OnValueChanged", function()
        if spinner:IsActive() then
            self:QueueSpinner(spinner)
        end
    end)

    spinner:RegisterCallback("OnActivated", function()
        local NARRATE_HEADER = true
        self:QueueSpinner(spinner, NARRATE_HEADER)
    end)

    CALLBACK_MANAGER:RegisterCallback("AllDialogsHidden", self.spinnerAllDialogsHiddenCallback, spinner)
end

function ZO_ScreenNarrationManager:RegisterGamepadButtonTabBar(tabBar)
    tabBar:RegisterCallback("OnActivated", function()
        self:QueueGamepadButtonTabBar(tabBar)
    end)

    tabBar:RegisterCallback("OnSelectionChanged", function()
        if tabBar:IsActivated() then
            self:QueueGamepadButtonTabBar(tabBar)
        end
    end)
end

function ZO_ScreenNarrationManager:RegisterFadingControlBuffer(fadingControlBuffer)
    fadingControlBuffer:RegisterCallback("OnEntryUpdated", function()
        self:QueueFadingControlBuffer(fadingControlBuffer)
    end)
end

function ZO_ScreenNarrationManager:CreateNarrationParams(narrationEntryType, delayMS)
    local narrationParams = self.narrationParamsPool:AcquireObject()
    narrationParams:SetNarrationEntryType(narrationEntryType)
    narrationParams:SetStartTimeMS(delayMS + GetFrameTimeMilliseconds())
    return narrationParams
end

function ZO_ScreenNarrationManager:CreateNarratableObject(narrationText, pauseTime)
    local narratableObject = self.narratableObjectPool:AcquireObject()
    narratableObject:AddNarrationText(narrationText)
    narratableObject:SetPauseTimeMS(pauseTime)
    return narratableObject
end

--Queues the given narrationParams into its associated queue
function ZO_ScreenNarrationManager:SetQueuedNarration(narrationParams)
    local narrationType = narrationParams:GetNarrationType()
    if QUEUEABLE_NARRATION_TYPES[narrationType] then
        --Make sure to release any already existing queued narrations before setting the new one
        local queuedNarration = self:GetQueuedNarration(narrationType)
        if queuedNarration then
            queuedNarration:ReleaseObject()
        end
        self.queuedNarrations[narrationType] = narrationParams
    else
        internalassert(false, "Attempting to queue an invalid narration type, please see the QUEUEABLE_NARRATION_TYPES table for the queueable narration types")
    end
end

--Get the narration params currently queued for the specified narration type
function ZO_ScreenNarrationManager:GetQueuedNarration(narrationType)
    return self.queuedNarrations[narrationType]
end

--Clears the queued narration associated with the specified narration type
function ZO_ScreenNarrationManager:ClearQueuedNarration(narrationType)
    if self.queuedNarrations[narrationType] then
        self.queuedNarrations[narrationType]:ReleaseObject()
    end
    self.queuedNarrations[narrationType] = nil
end

function ZO_ScreenNarrationManager:TryNarration(narrationParams)
    if IsScreenNarrationEnabled() then
        local narrationType = narrationParams:GetNarrationType()
        local narrationEntryType = narrationParams:GetNarrationEntryType()
        if narrationEntryType == NARRATION_ENTRY_TYPE_PARAMETRIC_LIST_ENTRY then
            local list = narrationParams:GetParametricList()
            local narrationInfo = self.parametricListNarrationInfo[list]
            if narrationInfo:canNarrate() and list:IsActive() then
                self:NarrateParametricListEntry(narrationInfo, list, list:GetTargetData(), list:GetTargetControl(), narrationParams:GetNarrateHeader(), narrationType)
            end
        elseif narrationEntryType == NARRATION_ENTRY_TYPE_SORT_FILTER_LIST_ENTRY then
            local list = narrationParams:GetParametricList()
            if list:IsActivated() then
                self:NarrateSortFilterListEntry(list, narrationParams:GetNarrateHeader(), narrationType)
            end
        elseif narrationEntryType == NARRATION_ENTRY_TYPE_SORT_HEADER then
            local sortHeaderGroup = narrationParams:GetSortHeaderGroup()
            local list = narrationParams:GetParametricList()
            local key = narrationParams:GetSelectedSortHeaderKey()
            if list:IsActive() and sortHeaderGroup:IsEnabled() and sortHeaderGroup:IsKeyCurrentSelectedIndex(key) then
                self:NarrateSelectedSortHeader(list, sortHeaderGroup, key, narrationParams:GetNarrateHeader(), narrationType)
            end
        elseif narrationEntryType == NARRATION_ENTRY_TYPE_COMBO_BOX then
            self:NarrateComboBox(narrationParams:GetComboBox(), narrationType)
        elseif narrationEntryType == NARRATION_ENTRY_TYPE_GRID_LIST_ENTRY then
            local gridList = narrationParams:GetGridList()
            if gridList:IsActive() then
                self:NarrateGridListEntry(gridList, narrationParams:GetNarrateHeader(), narrationParams:GetNarrateSubHeader(), narrationType)
            end
        elseif narrationEntryType == NARRATION_ENTRY_TYPE_GAMEPAD_GRID_ENTRY then
            local gamepadGrid = narrationParams:GetGamepadGrid()
            if gamepadGrid:IsActive() then
                self:NarrateGamepadGridEntry(gamepadGrid, narrationParams:GetNarrateHeader(), narrationType)
            end
        elseif narrationEntryType == NARRATION_ENTRY_TYPE_TEXT_SEARCH_HEADER then
            local textSearchHeader = narrationParams:GetTextSearchHeader()
            local narrationInfo = self.textSearchHeaderNarrationInfo[textSearchHeader]
            if textSearchHeader:IsActive() then
                self:NarrateTextSearchHeader(textSearchHeader, narrationInfo, narrationParams:GetNarrateHeader(), narrationType)
            end
        elseif narrationEntryType == NARRATION_ENTRY_TYPE_DIALOG then
            local dialog = narrationParams:GetDialog()
            --ZO_Dialogs_IsShowing will continue to return true until the dialog is hidden, so we need to check if it's in the process of hiding separately
            if ZO_Dialogs_IsShowing(dialog.name) and not ZO_Dialogs_IsDialogHiding(dialog.name) then
                self:NarrateDialog(dialog, narrationParams:GetNarrateDialogBaseText(), narrationType)
            end
        elseif narrationEntryType == NARRATION_ENTRY_TYPE_FADING_CONTROL_BUFFER then
            self:NarrateFadingControlBuffer(narrationParams:GetFadingControlBuffer(), narrationType)
        elseif narrationEntryType == NARRATION_ENTRY_TYPE_FOCUS_ENTRY then
            local focus = narrationParams:GetFocus()
            if focus:IsActive() then
                self:NarrateFocusEntry(focus, narrationParams:GetNarrateHeader(), narrationParams:GetNarrateSubHeader(), narrationType)
            end
        elseif narrationEntryType == NARRATION_ENTRY_TYPE_SPINNER then
            local spinner = narrationParams:GetSpinner()
            if spinner:IsActive() then
                self:NarrateSpinner(spinner, narrationParams:GetNarrateHeader(), narrationType)
            end
        elseif narrationEntryType == NARRATION_ENTRY_TYPE_GAMEPAD_BUTTON_TAB_BAR then
            local tabBar = narrationParams:GetGamepadButtonTabBar()
            if tabBar:IsActivated() then
                self:NarrateGamepadButtonTabBar(tabBar, narrationType)
            end
        elseif narrationEntryType == NARRATION_ENTRY_TYPE_CUSTOM then
            local customObjectName = narrationParams:GetCustomObjectName()
            local narrationInfo = self.customObjectNarrationInfo[customObjectName]
            if narrationInfo:canNarrate() then
                self:NarrateCustomEntry(narrationInfo, narrationParams:GetNarrateHeader(), narrationType)
            end
        else
            internalassert(false, "Unhandled narration entry type")
        end
    end
end

function ZO_ScreenNarrationManager:QueueParametricListEntry(list, narrateHeader, overrideQueueDelayMs)
    if IsScreenNarrationEnabled() then
        local narrationInfo = self.parametricListNarrationInfo[list]
        local narrationParams = self:CreateNarrationParams(NARRATION_ENTRY_TYPE_PARAMETRIC_LIST_ENTRY, overrideQueueDelayMs or SCREEN_NARRATION_QUEUE_DELAY_MS)
        narrationParams:SetNarrationType(narrationInfo.narrationType)

        local queuedNarration = self:GetQueuedNarration(narrationParams:GetNarrationType())
        local narrationBlocked = false
        if queuedNarration and queuedNarration:GetNarrationEntryType() == NARRATION_ENTRY_TYPE_PARAMETRIC_LIST_ENTRY then
            local queuedList = queuedNarration:GetParametricList()
            local queuedNarrateHeader = queuedNarration:GetNarrateHeader()
            local queuedNarrationBlocked = queuedNarration:GetNarrationBlocked()
            --If the list we are queueing is the same one we are overwriting, then make sure we still read the header if necessary
            if queuedList == list and queuedNarrateHeader then
                narrateHeader = queuedNarrateHeader
            end

            --If the list we are queueing is the same one we are overwriting, then make sure we remain blocked if necessary
            if queuedList == list and queuedNarrationBlocked then
                narrationBlocked = queuedNarrationBlocked
            end
        end
        narrationParams:SetParametricList(list, narrateHeader)
        narrationParams:SetNarrationBlocked(narrationBlocked)
        self:SetQueuedNarration(narrationParams)
    end
end

function ZO_ScreenNarrationManager:QueueSortFilterListEntry(list, narrateHeader)
    if IsScreenNarrationEnabled() then
        local queuedNarration = self:GetQueuedNarration(GetDefaultNarrationType(NARRATION_ENTRY_TYPE_SORT_FILTER_LIST_ENTRY))
        if queuedNarration and queuedNarration:GetNarrationEntryType() == NARRATION_ENTRY_TYPE_SORT_FILTER_LIST_ENTRY then
            local queuedList = queuedNarration:GetParametricList()
            local queuedNarrateHeader = queuedNarration:GetNarrateHeader()
            --If the list we are queueing is the same one we are overwriting, then make sure we still read the header if necessary
            if queuedList == list and queuedNarrateHeader then
                narrateHeader = queuedNarrateHeader
            end
        end
        local narrationParams = self:CreateNarrationParams(NARRATION_ENTRY_TYPE_SORT_FILTER_LIST_ENTRY, SCREEN_NARRATION_QUEUE_DELAY_MS)
        narrationParams:SetParametricList(list, narrateHeader)
        self:SetQueuedNarration(narrationParams)
    end
end

function ZO_ScreenNarrationManager:QueueSelectedSortHeader(list, sortHeaderGroup, key, narrateHeader)
    if IsScreenNarrationEnabled() then
        local queuedNarration = self:GetQueuedNarration(GetDefaultNarrationType(NARRATION_ENTRY_TYPE_SORT_HEADER))
        if queuedNarration and queuedNarration:GetNarrationEntryType() == NARRATION_ENTRY_TYPE_SORT_HEADER then
            local queuedList = queuedNarration:GetParametricList()
            local queuedNarrateHeader = queuedNarration:GetNarrateHeader()
            --If the list we are queueing is the same one we are overwriting, then make sure we still read the header if necessary
            if queuedList == list and queuedNarrateHeader then
                narrateHeader = queuedNarrateHeader
            end
        end
        local narrationParams = self:CreateNarrationParams(NARRATION_ENTRY_TYPE_SORT_HEADER, SCREEN_NARRATION_QUEUE_DELAY_MS)
        narrationParams:SetParametricList(list, narrateHeader)
        narrationParams:SetSelectedSortHeader(sortHeaderGroup, key)
        self:SetQueuedNarration(narrationParams)
    end
end

function ZO_ScreenNarrationManager:QueueComboBox(comboBox)
    if IsScreenNarrationEnabled() then
        local narrationParams = self:CreateNarrationParams(NARRATION_ENTRY_TYPE_COMBO_BOX, SCREEN_NARRATION_QUEUE_DELAY_MS)
        narrationParams:SetComboBox(comboBox)
        self:SetQueuedNarration(narrationParams)
    end
end

function ZO_ScreenNarrationManager:QueueGridListEntry(gridList, narrateHeader, narrateSubHeader)
    if IsScreenNarrationEnabled() then
        local queuedNarration = self:GetQueuedNarration(GetDefaultNarrationType(NARRATION_ENTRY_TYPE_GRID_LIST_ENTRY))
        if queuedNarration and queuedNarration:GetNarrationEntryType() == NARRATION_ENTRY_TYPE_GRID_LIST_ENTRY then
            local queuedGridList = queuedNarration:GetGridList()
            local queuedNarrateHeader = queuedNarration:GetNarrateHeader()
            local queuedNarrateSubHeader = queuedNarration:GetNarrateSubHeader()
            --If the grid list we are queueing is the same one we are overwriting, then make sure we still read the header if necessary
            if queuedGridList == gridList and queuedNarrateHeader then
                narrateHeader = queuedNarrateHeader
            end

            --If the grid list we are queueing is the same one we are overwriting, then make sure we still read the subheader if necessary
            if queuedGridList == gridList and queuedNarrateSubHeader then
                narrateSubHeader = queuedNarrateSubHeader
            end
        end
        local narrationParams = self:CreateNarrationParams(NARRATION_ENTRY_TYPE_GRID_LIST_ENTRY, SCREEN_NARRATION_QUEUE_DELAY_MS)
        narrationParams:SetGridList(gridList, narrateHeader, narrateSubHeader)
        self:SetQueuedNarration(narrationParams)
    end
end

function ZO_ScreenNarrationManager:QueueGamepadGridEntry(gamepadGrid, narrateHeader)
    if IsScreenNarrationEnabled() then
        local narrationParams = self:CreateNarrationParams(NARRATION_ENTRY_TYPE_GAMEPAD_GRID_ENTRY, SCREEN_NARRATION_QUEUE_DELAY_MS)
        narrationParams:SetGamepadGrid(gamepadGrid, narrateHeader)
        self:SetQueuedNarration(narrationParams)
    end
end

function ZO_ScreenNarrationManager:QueueTextSearchHeader(textSearchHeader, narrateHeader)
    if IsScreenNarrationEnabled() then
        local queuedNarration = self:GetQueuedNarration(GetDefaultNarrationType(NARRATION_ENTRY_TYPE_TEXT_SEARCH_HEADER))
        if queuedNarration and queuedNarration:GetNarrationEntryType() == NARRATION_ENTRY_TYPE_TEXT_SEARCH_HEADER then
            local queuedTextSearchHeader = queuedNarration:GetTextSearchHeader()
            local queuedNarrateHeader = queuedNarration:GetNarrateHeader()
            --If the text search header we are queueing is the same one we are overwriting, then make sure we still read the header if necessary
            if queuedTextSearchHeader == textSearchHeader and queuedNarrateHeader then
                narrateHeader = queuedNarrateHeader
            end
        end
        local narrationParams = self:CreateNarrationParams(NARRATION_ENTRY_TYPE_TEXT_SEARCH_HEADER, SCREEN_NARRATION_QUEUE_DELAY_MS)
        narrationParams:SetTextSearchHeader(textSearchHeader, narrateHeader)
        self:SetQueuedNarration(narrationParams)
    end
end

function ZO_ScreenNarrationManager:QueueDialog(dialog, narrateBaseText)
    if IsScreenNarrationEnabled() then
        local queuedNarration = self:GetQueuedNarration(GetDefaultNarrationType(NARRATION_ENTRY_TYPE_DIALOG))
        if queuedNarration and queuedNarration:GetNarrationEntryType() == NARRATION_ENTRY_TYPE_DIALOG then
            local queuedDialog = queuedNarration:GetDialog()
            local queuedNarrateBaseText = queuedNarration:GetNarrateDialogBaseText()
            --If the dialog we are queuing is the same one we are overwriting, then make sure we still read the base text if necessary
            if queuedDialog == dialog and queuedNarrateBaseText then
                narrateBaseText = queuedNarrateBaseText
            end
        end
        local narrationParams = self:CreateNarrationParams(NARRATION_ENTRY_TYPE_DIALOG, SCREEN_NARRATION_QUEUE_DELAY_MS)
        narrationParams:SetDialog(dialog, narrateBaseText)
        self:SetQueuedNarration(narrationParams)
    end
end

function ZO_ScreenNarrationManager:QueueFadingControlBuffer(fadingControlBuffer)
    if IsScreenNarrationEnabled() then
        local narrationParams = self:CreateNarrationParams(NARRATION_ENTRY_TYPE_FADING_CONTROL_BUFFER, SCREEN_NARRATION_QUEUE_DELAY_MS)
        narrationParams:SetFadingControlBuffer(fadingControlBuffer)
        self:SetQueuedNarration(narrationParams)
    end
end

function ZO_ScreenNarrationManager:QueueFocus(focus, narrateHeader, narrateSubHeader)
    if IsScreenNarrationEnabled() then
        local queuedNarration = self:GetQueuedNarration(GetDefaultNarrationType(NARRATION_ENTRY_TYPE_FOCUS_ENTRY))
        if queuedNarration and queuedNarration:GetNarrationEntryType() == NARRATION_ENTRY_TYPE_FOCUS_ENTRY then
            local queuedFocus = queuedNarration:GetFocus()
            local queuedNarrateHeader = queuedNarration:GetNarrateHeader()
            --If the focus we are queueing is the same one we are overwriting, then make sure we still read the header if necessary
            if queuedFocus == focus and queuedNarrateHeader then
                narrateHeader = queuedNarrateHeader
            end

            local queuedNarrateSubHeader = queuedNarration:GetNarrateSubHeader()
            --If the focus we are queueing is the same one we are overwriting, then make sure we still read the sub header if necessary
            if queuedFocus == focus and queuedNarrateSubHeader then
                narrateSubHeader = queuedNarrateSubHeader
            end
        end

        local narrationParams = self:CreateNarrationParams(NARRATION_ENTRY_TYPE_FOCUS_ENTRY, SCREEN_NARRATION_QUEUE_DELAY_MS)
        narrationParams:SetFocus(focus, narrateHeader, narrateSubHeader)
        self:SetQueuedNarration(narrationParams)
    end
end

function ZO_ScreenNarrationManager:QueueSpinner(spinner, narrateHeader)
    if IsScreenNarrationEnabled() then
        local narrationParams = self:CreateNarrationParams(NARRATION_ENTRY_TYPE_SPINNER, SCREEN_NARRATION_QUEUE_DELAY_MS)
        narrationParams:SetSpinner(spinner, narrateHeader)
        self:SetQueuedNarration(narrationParams)
    end
end

function ZO_ScreenNarrationManager:QueueCustomEntry(objectName, narrateHeader)
    if IsScreenNarrationEnabled() then
        local narrationInfo = self.customObjectNarrationInfo[objectName]
        local narrationParams = self:CreateNarrationParams(NARRATION_ENTRY_TYPE_CUSTOM, SCREEN_NARRATION_QUEUE_DELAY_MS)
        narrationParams:SetNarrationType(narrationInfo.narrationType)

        local queuedNarration = self:GetQueuedNarration(narrationParams:GetNarrationType())
        if queuedNarration and queuedNarration:GetNarrationEntryType() == NARRATION_ENTRY_TYPE_CUSTOM then
            local queuedCustomObjectName = queuedNarration:GetCustomObjectName()
            local queuedNarrateHeader = queuedNarration:GetNarrateHeader()
            --If the custom object we are queueing is the same one we are overwriting, then make sure we still read the header if necessary
            if queuedCustomObjectName == objectName and queuedNarrateHeader then
                narrateHeader = queuedNarrateHeader
            end
        end

        narrationParams:SetCustomObjectName(objectName, narrateHeader)
        self:SetQueuedNarration(narrationParams)
    end
end

function ZO_ScreenNarrationManager:QueueGamepadButtonTabBar(tabBar)
    if IsScreenNarrationEnabled() then
        local narrationParams = self:CreateNarrationParams(NARRATION_ENTRY_TYPE_GAMEPAD_BUTTON_TAB_BAR, SCREEN_NARRATION_QUEUE_DELAY_MS)
        narrationParams:SetGamepadButtonTabBar(tabBar)
        self:SetQueuedNarration(narrationParams)
    end
end

function ZO_ScreenNarrationManager:QueueCSA(messageParams)
    if IsScreenNarrationEnabled() then
        --CSAs do not need to wait before sending to the C++, so attempt to narrate them immediately
        self:NarrateText(messageParams:GetNarrationText(), NARRATION_TYPE_CENTER_SCREEN_ANNOUNCEMENT)
    end
end

function ZO_ScreenNarrationManager:QueueCountdownCSA(countdownTime)
    if IsScreenNarrationEnabled() then
        --CSAs do not need to wait before sending to the C++, so attempt to narrate them immediately
        --Countdown CSAs should not queue up behind other CSAs, so put them in the higher priority alert queue instead
        self:NarrateText(self:CreateNarratableObject(countdownTime), NARRATION_TYPE_ALERT)
    end
end

do
    local KEYBIND_PAUSE_TIME_MS = 100
    --Gets a narratable object for the currently active keybinds on the keybind strip
    --If additionalInputNarrationFunction is specified, it will append the return keybind info to the end of the narration of the keybind strip
    --If overrideInputNarrationFunction is specified, only the keybind info it returns will be narrated
    function ZO_ScreenNarrationManager:GetKeybindNarration(additionalInputNarrationFunction, overrideInputNarrationFunction)
        local keybindButtonInfo
        if overrideInputNarrationFunction then
            keybindButtonInfo = overrideInputNarrationFunction()
        else
            keybindButtonInfo = KEYBIND_STRIP:GetOrderedNarratableKeybindButtonInfo()
            if additionalInputNarrationFunction then
                ZO_CombineNumericallyIndexedTables(keybindButtonInfo, additionalInputNarrationFunction())
            end
        end

        local keybindNarration = self:CreateNarratableObject(nil, KEYBIND_PAUSE_TIME_MS)
        for i, buttonInfo in ipairs(keybindButtonInfo) do
            local narrationText
            if buttonInfo.name then
                local formatter
                if i == 1 then
                    formatter = buttonInfo.enabled and SI_SCREEN_NARRATION_FIRST_KEYBIND_FORMATTER or SI_SCREEN_NARRATION_DISABLED_FIRST_KEYBIND_FORMATTER
                else
                    formatter = buttonInfo.enabled and SI_SCREEN_NARRATION_KEYBIND_FORMATTER or SI_SCREEN_NARRATION_DISABLED_KEYBIND_FORMATTER
                end
                narrationText = zo_strformat(formatter, buttonInfo.keybindName, buttonInfo.name)
            else
                local formatter
                if i == 1 then
                    formatter = buttonInfo.enabled and SI_SCREEN_NARRATION_FIRST_KEYBIND_FORMATTER_NO_LABEL or SI_SCREEN_NARRATION_DISABLED_FIRST_KEYBIND_FORMATTER_NO_LABEL
                else
                    formatter = buttonInfo.enabled and SI_SCREEN_NARRATION_KEYBIND_FORMATTER_NO_LABEL or SI_SCREEN_NARRATION_DISABLED_KEYBIND_FORMATTER_NO_LABEL
                end
                narrationText = zo_strformat(formatter, buttonInfo.keybindName)
            end
            keybindNarration:AddNarrationText(narrationText)
        end
        return keybindNarration
    end
end

--Recursively populates a narratable object representing a tooltip read in the order it is laid out visually
function ZO_ScreenNarrationManager:FormatTooltipStrings(narration, tooltipString)
    --If this is just a string, we can just add it to the narration as-is
    if type(tooltipString) == "string" then
        narration:AddNarrationText(tooltipString)
    elseif type(tooltipString) == "table" then
        --If this is a table, loop through each entry and add it to the narration
        for i, tooltipEntry in ipairs(tooltipString) do
            self:FormatTooltipStrings(narration, tooltipEntry)
        end
    elseif type(tooltipString) == "function" then
        --If this is a function, attempt to add the return value to the narration
        self:FormatTooltipStrings(narration, tooltipString())
    end
end

--Gets a table of narratable objects representing the narration text for a tooltip or tooltips
--If optionalTooltipType is not specified, the table returned will contain a narratable object for each visible tooltip
function ZO_ScreenNarrationManager:GetTooltipNarration(optionalTooltipType)
    --Get the table of tooltip strings
    --The table is ordered based on the order the strings should be read visually
    local tooltipStrings = GAMEPAD_TOOLTIPS:GetNarrationText(optionalTooltipType)

    --If an optional tooltip type was not specified, then tooltipStrings will be a table of tables for each visible tooltip
    --If an optional tooltip type was specified, then tooltipStrings will only contain the narration for that tooltip
    --In this situation, we loop and create a narratable object for each individual tooltip
    local narrations = {}
    for i, tooltipNarrationText in ipairs(tooltipStrings) do
        if ZO_IsNarratableObject(tooltipNarrationText) then
            table.insert(narrations, tooltipNarrationText)
        else
            local narration = self:CreateNarratableObject()
            self:FormatTooltipStrings(narration, tooltipNarrationText)
            table.insert(narrations, narration)
        end
    end
    return narrations
end

function ZO_ScreenNarrationManager:NarrateParametricListEntry(narrationInfo, list, entryData, entryControl, narrateHeader, narrationType)
    local narrations = {}
    local additionalInputNarrationFunction

    if narrateHeader and narrationInfo.headerNarrationFunction then
        local headerNarration = narrationInfo:headerNarrationFunction()
        ZO_AppendNarration(narrations, headerNarration)
    end

    if list:IsEmpty() then
        --If the list is empty, then narrate the no item text instead
        ZO_AppendNarration(narrations, self:CreateNarratableObject(list:GetNoItemText()))
    elseif entryData and (entryData.text or entryData.narrationText) then
        additionalInputNarrationFunction = entryData.additionalInputNarrationFunction

        if entryData.headerNarrationFunction then
            ZO_AppendNarration(narrations, entryData.headerNarrationFunction(entryData, entryControl))
        elseif entryData.header then
            ZO_AppendNarration(narrations, self:CreateNarratableObject(entryData.header))
        end

        if entryData.narrationText then
            if type(entryData.narrationText) == "function" then
                --If the narration text is a function it should return either a narratable object or table of narratable objects
                local narration = entryData.narrationText(entryData, entryControl)
                ZO_AppendNarration(narrations, narration)
            else
                ZO_AppendNarration(narrations, self:CreateNarratableObject(entryData.narrationText))
            end
        else
            --Entries using a custom value via entryData.narrationText need to handle entryData.text, sublabels, stack count, status indicators, and progress bars themselves if they want it
            ZO_AppendNarration(narrations, ZO_GetSharedGamepadEntryDefaultNarrationText(entryData, entryControl))
        end

        ZO_AppendNarration(narrations, self:GetTooltipNarration())
    end

    ZO_AppendNarration(narrations, self:GetKeybindNarration(additionalInputNarrationFunction))

    if narrationInfo.footerNarrationFunction then
        local footerNarration = narrationInfo:footerNarrationFunction()
        ZO_AppendNarration(narrations, footerNarration)
    end

    self:NarrateText(narrations, narrationType)
end

function ZO_ScreenNarrationManager:NarrateGridListEntry(gridList, narrateHeader, narrateSubHeader, narrationType)
    local narrations = {}
    if narrateHeader then
        ZO_AppendNarration(narrations, gridList:GetHeaderNarration())
    end

    local entryData = gridList:GetSelectedData()
    if entryData then
        if narrateSubHeader then
            --The subheader information can be stored in either the gridHeaderName or gridHeaderData fields
            local entryHeaderData = entryData.gridHeaderName or entryData.gridHeaderData
            if entryHeaderData then
                if type(entryHeaderData) == "string" then
                    ZO_AppendNarration(narrations, self:CreateNarratableObject(entryHeaderData))
                elseif entryHeaderData.headerNarrationFunction then
                    ZO_AppendNarration(narrations, entryHeaderData.headerNarrationFunction(entryHeaderData))
                end
            end
        end

        if entryData.narrationText then
            if type(entryData.narrationText) == "function" then
                --If the narration text is a function it should return either a narratable object or table of narratable objects
                local narration = entryData.narrationText(entryData)
                ZO_AppendNarration(narrations, narration)
            else
                ZO_AppendNarration(narrations, self:CreateNarratableObject(entryData.narrationText))
            end
        end
    end

    ZO_AppendNarration(narrations, self:GetTooltipNarration())
    ZO_AppendNarration(narrations, self:GetKeybindNarration())

    self:NarrateText(narrations, narrationType)
end

function ZO_ScreenNarrationManager:NarrateGamepadGridEntry(gamepadGrid, narrateHeader, narrationType)
    local narrations = {}
    if narrateHeader then
        local headerNarration = gamepadGrid:GetHeaderNarration()
        ZO_AppendNarration(narrations, headerNarration)
    end

    local narration = gamepadGrid:GetNarrationText()
    ZO_AppendNarration(narrations, narration)
    ZO_AppendNarration(narrations, self:GetTooltipNarration())
    ZO_AppendNarration(narrations, self:GetKeybindNarration())

    self:NarrateText(narrations, narrationType)
end

function ZO_ScreenNarrationManager:NarrateSortFilterListEntry(list, narrateHeader, narrationType)
    local narrations = {}
    if narrateHeader then
        local headerNarration = list:GetHeaderNarration()
        ZO_AppendNarration(narrations, headerNarration)
    end

    ZO_AppendNarration(narrations, list:GetNarrationText())
    ZO_AppendNarration(narrations, self:GetTooltipNarration())

    local additionalInputNarrationFunction = list:GetAdditionalInputNarrationFunction()
    ZO_AppendNarration(narrations, self:GetKeybindNarration(additionalInputNarrationFunction))
    ZO_AppendNarration(narrations, list:GetFooterNarration())
    self:NarrateText(narrations, narrationType)
end

function ZO_ScreenNarrationManager:NarrateSelectedSortHeader(list, sortHeaderGroup, key, narrateHeader, narrationType)
    local narrations = {}
    if narrateHeader then
        local headerNarration = list:GetHeaderNarration()
        ZO_AppendNarration(narrations, headerNarration)
    end
    ZO_AppendNarration(narrations, sortHeaderGroup:GetSortHeaderNarrationText(key))
    ZO_AppendNarration(narrations, list:GetEmptyRowNarration())
    ZO_AppendNarration(narrations, self:GetKeybindNarration())
    ZO_AppendNarration(narrations, list:GetFooterNarration())
    self:NarrateText(narrations, narrationType)
end

function ZO_ScreenNarrationManager:NarrateComboBox(comboBox, narrationType)
    local narrations = {}
    ZO_AppendNarration(narrations, comboBox:GetNarrationText())

    local tooltipType = comboBox:GetNarrationTooltipType()
    -- Only narrate tooltips if a particular tooltip as been specified for the comboBox
    if tooltipType then
        ZO_AppendNarration(narrations, self:GetTooltipNarration(tooltipType))
    end

    ZO_AppendNarration(narrations, self:GetKeybindNarration())
    self:NarrateText(narrations, narrationType)
end

function ZO_ScreenNarrationManager:NarrateTextSearchHeader(textSearchHeader, narrationInfo, narrateHeader, narrationType)
    local narrations = {}

    --If we have a narration for the header, include if applicable
    if narrateHeader and narrationInfo.headerNarrationFunction then
        local headerNarration = narrationInfo:headerNarrationFunction()
        ZO_AppendNarration(narrations, headerNarration)
    end

    --Get the main narration for the text search header
    ZO_AppendNarration(narrations, textSearchHeader:GetNarrationText())

    --If we have a narration for the results, include that
    if narrationInfo.resultsNarrationFunction then
        local resultsNarration = narrationInfo.resultsNarrationFunction()
        ZO_AppendNarration(narrations, resultsNarration)
    end

    ZO_AppendNarration(narrations, self:GetKeybindNarration())
    self:NarrateText(narrations, narrationType)
end

function ZO_ScreenNarrationManager:NarrateFocusEntry(focus, narrateHeader, narrateSubHeader, narrationType)
    if focus then
        local narrations = {}
        if narrateHeader then
            local headerNarration = focus:GetHeaderNarration()
            ZO_AppendNarration(narrations, headerNarration)
        end

        if narrateSubHeader then
            local subHeaderNarration = focus:GetSubHeaderNarration()
            ZO_AppendNarration(narrations, subHeaderNarration)
        end

        local focusNarration = focus:GetNarrationText()
        ZO_AppendNarration(narrations, focusNarration)

        local additionalInputNarrationFunction = focus:GetAdditionalInputNarrationFunction()
        ZO_AppendNarration(narrations, self:GetTooltipNarration())
        ZO_AppendNarration(narrations, self:GetKeybindNarration(additionalInputNarrationFunction))

        local footerNarration = focus:GetFooterNarration()
        ZO_AppendNarration(narrations, footerNarration)

        self:NarrateText(narrations, narrationType)
    end
end

function ZO_ScreenNarrationManager:NarrateSpinner(spinner, narrateHeader, narrationType)
    if spinner then
        local narrations = {}
        if narrateHeader then
            local headerNarration = spinner:GetHeaderNarration()
            ZO_AppendNarration(narrations, headerNarration)
        end

        local spinnerNarration = spinner:GetNarrationText()
        ZO_AppendNarration(narrations, spinnerNarration)

        if spinner:CanNarrateTooltips() then
            ZO_AppendNarration(narrations, self:GetTooltipNarration())
        end
        local additionalInputNarrationFunction = spinner:GetAdditionalInputNarrationFunction()
        ZO_AppendNarration(narrations, self:GetKeybindNarration(additionalInputNarrationFunction))

        self:NarrateText(narrations, narrationType)
    end
end

function ZO_ScreenNarrationManager:NarrateGamepadButtonTabBar(tabBar, narrationType)
    if tabBar then
        local narrations = {}
        local tabBarNarration = tabBar:GetNarrationText()
        ZO_AppendNarration(narrations, tabBarNarration)
        ZO_AppendNarration(narrations, self:GetTooltipNarration())
        ZO_AppendNarration(narrations, self:GetKeybindNarration())

        self:NarrateText(narrations, narrationType)
    end
end

--Forms a table of the narrations that are common amongst all the dialog types
function ZO_ScreenNarrationManager:GetDialogBaseNarration(dialog, dialogInfo, dialogType, textParams, narrateBaseText)
    local narrations = {}
    --narrateBaseText should only be true upon first opening the dialog
    if narrateBaseText then
        if dialogInfo.headerNarrationFunction then
            ZO_AppendNarration(narrations, dialogInfo.headerNarrationFunction(dialog))
        elseif dialog.header and dialog.headerData then
            ZO_AppendNarration(narrations, ZO_GamepadGenericHeader_GetNarrationText(dialog.header, dialog.headerData))
        elseif dialogInfo.title then
            local titleText = ZO_GetFormattedDialogText(dialog, dialogInfo.title, textParams.titleParams)
            ZO_AppendNarration(narrations, self:CreateNarratableObject(titleText))
        end

        if dialogInfo.mainText then
            local mainTextParams = textParams.mainTextNarrationParams or textParams.mainTextParams
            local mainText = ZO_GetFormattedDialogText(dialog, dialogInfo.mainText, mainTextParams)
            ZO_AppendNarration(narrations, self:CreateNarratableObject(mainText))
        end

        --Centered dialogs do not support sub text or warning
        if dialogType ~= GAMEPAD_DIALOGS.CENTERED then
            if dialogInfo.subText then
                local subText = ZO_GetFormattedDialogText(dialog, dialogInfo.subText, textParams.subTextParams)
                ZO_AppendNarration(narrations, self:CreateNarratableObject(subText))
            end

            if dialogInfo.warning then
                local warningText = ZO_GetFormattedDialogText(dialog, dialogInfo.warning, textParams.warningParams)
                ZO_AppendNarration(narrations, self:CreateNarratableObject(warningText))
            end
        end

        if dialogInfo.baseNarrationTooltip then
            ZO_AppendNarration(narrations, self:GetTooltipNarration(dialogInfo.baseNarrationTooltip))
        end
    end

    return narrations
end

function ZO_ScreenNarrationManager:NarrateDialog(dialog, narrateBaseText, narrationType)
    local dialogInfo = dialog.info
    if dialogInfo.gamepadInfo then
        local dialogType = dialogInfo.gamepadInfo.dialogType
        local textParams = dialog.textParams or {}
        local additionalInputNarrationFunction

        --First, get the base narration
        local narrations = self:GetDialogBaseNarration(dialog, dialogInfo, dialogType, textParams, narrateBaseText)
        if dialogType == GAMEPAD_DIALOGS.BASIC then
            --Do nothing, this dialog type is handled fully by the base narration
        elseif dialogType == GAMEPAD_DIALOGS.PARAMETRIC then
            --If the dialog type is parametric, attempt to narrate the currently selected entry in the list
            local list = dialog.entryList
            if list then
                local entryData = list:GetTargetData()
                local entryControl = list:GetTargetControl()
                if entryData and (entryData.text or entryData.narrationText) then
                    additionalInputNarrationFunction = entryData.additionalInputNarrationFunction

                    if entryData.header then
                        ZO_AppendNarration(narrations, self:CreateNarratableObject(entryData.header))
                    end

                    if entryData.narrationText then
                        if type(entryData.narrationText) == "function" then
                            local narration = entryData.narrationText(entryData, entryControl)
                            ZO_AppendNarration(narrations, narration)
                        else
                            ZO_AppendNarration(narrations, self:CreateNarratableObject(entryData.narrationText))
                        end
                    else
                        --Entries using a custom value via entryData.narrationText need to handle entryData.text, sublabels, stack count, status indicators, and progress bars themselves if they want it
                        ZO_AppendNarration(narrations, ZO_GetSharedGamepadEntryDefaultNarrationText(entryData, entryControl))
                    end

                    --Dialogs only narrate tooltips when one is specifically specified
                    if entryData.narrationTooltip then
                        ZO_AppendNarration(narrations, self:GetTooltipNarration(entryData.narrationTooltip))
                    end
                end
            end
        elseif dialogType == GAMEPAD_DIALOGS.COOLDOWN then
            --If this is a cooldown dialog, attempt to narrate the loading text
            if dialogInfo.loading then
                local loadingText = dialogInfo.loading.text
                if type(loadingText) == "function" then
                    loadingText = loadingText(dialog)
                end
                ZO_AppendNarration(narrations, self:CreateNarratableObject(loadingText))
            end
        elseif dialogType == GAMEPAD_DIALOGS.CENTERED then
            --Do nothing, this dialog type is handled fully by the base narration
        elseif dialogType == GAMEPAD_DIALOGS.STATIC_LIST then
            --If the dialog type is static list, attempt to narrate each entry in the list
            if dialogInfo.itemInfo then
                local itemInfo = dialogInfo.itemInfo
                if type(itemInfo) == "function" then
                    itemInfo = itemInfo(dialog)
                end

                for i, info in ipairs(itemInfo) do
                    ZO_AppendNarration(narrations, self:CreateNarratableObject(info.label))
                end
            end
        elseif dialogType == GAMEPAD_DIALOGS.ITEM_SLIDER then
            --If the dialog type is item slider, attempt to narrate the associated slider
            if dialog.slider then
                local itemName = ""
                local bagId = dialog.data.bagId
                local slotIndex = dialog.data.slotIndex
                if bagId and slotIndex then
                    --Use the name of the item as the name of the slider
                    itemName = GetItemName(bagId, slotIndex)
                end

                --Item sliders can assume numeric directional input unless we are told otherwise
                additionalInputNarrationFunction = dialogInfo.additionalInputNarrationFunction or ZO_GetNumericHorizontalDirectionalInputNarrationData

                if dialogInfo.narrationText then
                    if type(dialogInfo.narrationText) == "function" then
                        --If the narration text is a function it should return either a narratable object or table of narratable objects
                        local narration = dialogInfo.narrationText(dialog, itemName)
                        ZO_AppendNarration(narrations, narration)
                    else
                        ZO_AppendNarration(narrations, self:CreateNarratableObject(dialogInfo.narrationText))
                    end
                else
                    ZO_AppendNarration(narrations, ZO_FormatSliderNarrationText(dialog.slider, itemName))
                end
            end
        elseif dialogType == GAMEPAD_DIALOGS.CUSTOM then
            if dialogInfo.narrationText then
                if type(dialogInfo.narrationText) == "function" then
                    local narration = dialogInfo.narrationText(dialog)
                    ZO_AppendNarration(narrations, narration)
                else
                    ZO_AppendNarration(narrations, self:CreateNarratableObject(dialogInfo.narrationText))
                end
            end
            additionalInputNarrationFunction = dialogInfo.additionalInputNarrationFunction
        else
            internalassert(false, "Unhandled dialog type")
        end

        --Always add keybinds at the end
        ZO_AppendNarration(narrations, self:GetKeybindNarration(additionalInputNarrationFunction))
        self:NarrateText(narrations, narrationType)
    end
end

function ZO_ScreenNarrationManager:NarrateFadingControlBuffer(fadingControlBuffer, narrationType)
    local narrations = {}
    ZO_AppendNarration(narrations, fadingControlBuffer:GetNarrationText())
    self:NarrateText(narrations, narrationType)
end

function ZO_ScreenNarrationManager:NarrateCustomEntry(narrationInfo, narrateHeader, narrationType)
    local narrations = {}

    if narrateHeader and narrationInfo.headerNarrationFunction then
        local headerNarration = narrationInfo:headerNarrationFunction()
        ZO_AppendNarration(narrations, headerNarration)
    end

    if narrationInfo.selectedNarrationFunction then
        local selectedNarration = narrationInfo:selectedNarrationFunction()
        ZO_AppendNarration(narrations, selectedNarration)
    end

    --Default to true if nothing was specified for canNarrateTooltips
    local canNarrateTooltips = narrationInfo.canNarrateTooltips == nil and true or narrationInfo.canNarrateTooltips
    if type(canNarrateTooltips) == "function" then
        canNarrateTooltips = canNarrateTooltips()
    end

    if canNarrateTooltips then
        ZO_AppendNarration(narrations, self:GetTooltipNarration())
    end

    local additionalInputNarrationFunction = narrationInfo.additionalInputNarrationFunction
    local overrideInputNarrationFunction = narrationInfo.overrideInputNarrationFunction
    ZO_AppendNarration(narrations, self:GetKeybindNarration(additionalInputNarrationFunction, overrideInputNarrationFunction))

    if narrationInfo.footerNarrationFunction then
        local footerNarration = narrationInfo:footerNarrationFunction()
        ZO_AppendNarration(narrations, footerNarration)
    end
    self:NarrateText(narrations, narrationType)
end

--TODO XAR: Do we need category here?
function ZO_ScreenNarrationManager:NarrateChatMessage(chatMessage, category)
    if IsChatNarrationEnabled() then
        if chatMessage ~= "" then
            RequestReadTextChatToClient(chatMessage)
        end
    end
end

--Adds a single narratable object to the pending narration and then releases the object
function ZO_ScreenNarrationManager:AddPendingNarration(narratableObject)
    narratableObject:AddToPending()
    narratableObject:ReleaseObject()
end

function ZO_ScreenNarrationManager:NarrateText(narration, narrationType)
    if type(narration) == "table" then
        if ZO_IsNarratableObject(narration) then
            self:AddPendingNarration(narration)
        else
            for _, narratableObject in ipairs(narration) do
                self:AddPendingNarration(narratableObject)
            end
        end
    end

    RequestReadPendingNarrationTextToClient(narrationType)
end

-- Global singleton

-- The global singleton moniker is assigned by the Narration Manager's constructor in order to
-- allow data objects to reference the singleton during their construction.
ZO_ScreenNarrationManager:New()