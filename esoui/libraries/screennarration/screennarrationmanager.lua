local function IsAccessibilityModeEnabled()
    return GetSetting_Bool(SETTING_TYPE_ACCESSIBILITY, ACCESSIBILITY_SETTING_ACCESSIBILITY_MODE)
end

local function IsChatNarrationEnabled()
    return GetSetting_Bool(SETTING_TYPE_ACCESSIBILITY, ACCESSIBILITY_SETTING_TEXT_CHAT_NARRATION)
end

local function IsScreenNarrationEnabled()
    return GetSetting_Bool(SETTING_TYPE_ACCESSIBILITY, ACCESSIBILITY_SETTING_SCREEN_NARRATION)
end

--Helper function for determining if something is a narratable object
local function IsNarratableObject(narration)
    if narration and narration.IsInstanceOf and narration:IsInstanceOf(ZO_NarratableObject) then
        return true
    end
    return false
end

--TODO XAR: Make an enum for this
local NARRATION_ENTRY_TYPE_PARAMETRIC_LIST_ENTRY = 1
local NARRATION_ENTRY_TYPE_SOCIAL_LIST_ENTRY = 2
local NARRATION_ENTRY_TYPE_SORT_HEADER = 3
local NARRATION_ENTRY_TYPE_COMBO_BOX = 4
local NARRATION_ENTRY_TYPE_GRID_LIST_ENTRY = 5
local NARRATION_ENTRY_TYPE_EDIT_BOX = 6
local NARRATION_ENTRY_TYPE_TEXT_SEARCH_HEADER = 7
local NARRATION_ENTRY_TYPE_DIALOG = 8
local NARRATION_ENTRY_TYPE_FADING_CONTROL_BUFFER = 9
local NARRATION_ENTRY_TYPE_FOCUS_ENTRY = 10

local SCREEN_NARRATION_QUEUE_DELAY_MS = 250

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

--TODO XAR: Look into potentially allowing us to add the narration text to the front
--Adds the specified narration text. Narration text can be a string, table of strings, or number
function ZO_NarratableObject:AddNarrationText(narrationText)
    if not narrationText or narrationText == "" then
        return
    end

    if type(narrationText) == "string" then
        table.insert(self.narrationStrings, narrationText)
    elseif type(narrationText) == "table" then
        ZO_CombineNumericallyIndexedTables(self.narrationStrings, narrationText)
    elseif type(narrationText) == "number" then
        table.insert(self.narrationStrings, tostring(narrationText))
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

function ZO_NarratableObject:GetNarrationText()
    --If a delimiter is set use that, otherwise fall back to pause time
    if self.delimiter then
        return ZO_GenerateDelimiterSeparatedList(self.narrationStrings, self.delimiter)
    else
        return ZO_GeneratePauseSeparatedList(self.narrationStrings, self.pauseTime)
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

function ZO_ScreenNarrationParams:SetNarrationType(narrationType)
    self.narrationType = narrationType
end

function ZO_ScreenNarrationParams:GetNarrationType()
    return self.narrationType
end

--TODO XAR: Is priority a thing we need?
function ZO_ScreenNarrationParams:SetPriority(priority)
    self.priority = priority
end

function ZO_ScreenNarrationParams:GetPriority()
    return self.priority
end

function ZO_ScreenNarrationParams:SetParametricList(list, narrateHeader)
    self.parametricList = list
    self.narrateParametricListHeader = narrateHeader
end

function ZO_ScreenNarrationParams:GetNarrateParametricListHeader()
    return self.narrateParametricListHeader
end

function ZO_ScreenNarrationParams:GetParametricList()
    return self.parametricList
end

function ZO_ScreenNarrationParams:SetGridList(gridList)
    self.gridList = gridList
end

function ZO_ScreenNarrationParams:GetGridList()
    return self.gridList
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

function ZO_ScreenNarrationParams:SetEditBox(editControl, name)
    self.editBoxControl = editControl
    self.editBoxName = name
end

function ZO_ScreenNarrationParams:GetEditBoxControl()
    return self.editBoxControl
end

function ZO_ScreenNarrationParams:GetEditBoxName()
    return self.editBoxName
end

function ZO_ScreenNarrationParams:SetTextSearchHeader(textSearchHeader)
    self.textSearchHeader = textSearchHeader
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

function ZO_ScreenNarrationParams:SetFadingControlBufferData(entryData, templateData)
    self.fadingControlBufferEntryData = entryData
    self.fadingControlBufferTemplateData = templateData
end

function ZO_ScreenNarrationParams:GetFadingControlBufferEntryData()
    return self.fadingControlBufferEntryData
end

function ZO_ScreenNarrationParams:GetFadingControlBufferTemplateData()
    return self.fadingControlBufferTemplateData
end

function ZO_ScreenNarrationParams:SetFocus(focus)
    self.focus = focus
end

function ZO_ScreenNarrationParams:GetFocus()
    return self.focus
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

    self.comboBoxItemSelectedCallback = function(control, data, comboBox)
        self:QueueComboBox(comboBox)
    end

    self.gridListAllDialogsHiddenCallback = function(gridList)
        if gridList:IsActive() then
            self:QueueGridListEntry(gridList)
        end
    end

    self.parametricListNarrationInfo = {}
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
        --TODO XAR: Support multiple queues
        if self.queuedNarration then
            if self.queuedNarration.startTimeMs <= currentTimeMs then
                self:TryNarration(self.queuedNarration)
                self:SetQueuedNarration(nil)
            end
        end
    end

    local function OnAppGuiHiddenStateChanged(_, hidden)
        self.isLoading = not hidden
        SetReadTextChatToClientQueueEnabled(hidden)
        if self.isLoading then
            self:SetQueuedNarration(nil)
            ClearReadTextChatToClientQueue()
            ClearReadUITextToClientQueue()
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

function ZO_ScreenNarrationManager:RegisterParametricList(list, narrationInfo)
    list:RegisterCallback("TargetDataChanged", self.parametricListTargetChangedCallback)
    list:RegisterCallback("ActivatedChanged", self.parametricListActivatedChangedCallback)
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
    }
    self:RegisterParametricList(list, narrationInfo)
end

function ZO_ScreenNarrationManager:UnregisterParametricList(list)
    list:UnregisterCallback("TargetDataChanged", self.parametricListTargetChangedCallback)
    list:UnregisterCallback("ActivatedChanged", self.parametricListActivatedChangedCallback)
    CALLBACK_MANAGER:UnregisterCallback("AllDialogsHidden", self.parametricListAllDialogsHiddenCallback, list)
    self.parametricListNarrationInfo[list] = nil
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

function ZO_ScreenNarrationManager:RegisterTextSearchHeader(textSearchHeader)
    textSearchHeader:RegisterCallback("EditBoxFocusLost", function()
        self:QueueTextSearchHeader(textSearchHeader)
    end)

    textSearchHeader:RegisterCallback("FocusActivated", function()
        self:QueueTextSearchHeader(textSearchHeader)
    end)
end

function ZO_ScreenNarrationManager:RegisterGridList(gridList)
    gridList:SetOnSelectedDataChangedCallback(function(previousData, newData)
        if gridList:IsActive() and newData then
            self:QueueGridListEntry(gridList)
        end
    end)

    gridList:RegisterCallback("OnActivated", function(selectedData)
        if selectedData then
            self:QueueGridListEntry(gridList)
        end
    end)

    CALLBACK_MANAGER:RegisterCallback("AllDialogsHidden", self.gridListAllDialogsHiddenCallback, gridList)
end

function ZO_ScreenNarrationManager:RegisterComboBox(comboBox)
    comboBox:RegisterCallback("OnItemSelected", self.comboBoxItemSelectedCallback)
end

function ZO_ScreenNarrationManager:RegisterDialogDropdown(dialog, dropdown)
    dropdown:RegisterCallback("OnDeactivated", function()
        self:QueueDialog(dialog)
    end)
end

function ZO_ScreenNarrationManager:CreateNarrationParams(narrationType, delayMS)
    local narrationParams = self.narrationParamsPool:AcquireObject()
    narrationParams:SetNarrationType(narrationType)
    narrationParams:SetStartTimeMS(delayMS + GetFrameTimeMilliseconds())
    return narrationParams
end

function ZO_ScreenNarrationManager:CreateNarratableObject(narrationText, pauseTime)
    local narratableObject = self.narratableObjectPool:AcquireObject()
    narratableObject:AddNarrationText(narrationText)
    narratableObject:SetPauseTimeMS(pauseTime)
    return narratableObject
end

function ZO_ScreenNarrationManager:SetQueuedNarration(narrationParams)
    if self.queuedNarration then
        self.queuedNarration:ReleaseObject()
    end
    self.queuedNarration = narrationParams
end

--TODO XAR: Look into making each case a function in a table indexed by narration type
function ZO_ScreenNarrationManager:TryNarration(narrationParams)
    if IsScreenNarrationEnabled() then
        local narrationType = narrationParams:GetNarrationType()
        if narrationType == NARRATION_ENTRY_TYPE_PARAMETRIC_LIST_ENTRY then
            local list = narrationParams:GetParametricList()
            local narrationInfo = self.parametricListNarrationInfo[list]
            if narrationInfo:canNarrate() and list:IsActive() then
                self:NarrateParametricListEntry(narrationInfo, list, list:GetTargetData(), list:GetTargetControl(), narrationParams:GetNarrateParametricListHeader())
            end
        elseif narrationType == NARRATION_ENTRY_TYPE_SOCIAL_LIST_ENTRY then
            local list = narrationParams:GetParametricList()
            if list:IsActive() then
                self:NarrateSocialListEntry(list)
            end
        elseif narrationType == NARRATION_ENTRY_TYPE_SORT_HEADER then
            local sortHeaderGroup = narrationParams:GetSortHeaderGroup()
            local list = narrationParams:GetParametricList()
            local key = narrationParams:GetSelectedSortHeaderKey()
            if list:IsActive() and sortHeaderGroup:IsEnabled() and sortHeaderGroup:IsKeyCurrentSelectedIndex(key) then
                self:NarrateSelectedSortHeader(sortHeaderGroup, key)
            end
        elseif narrationType == NARRATION_ENTRY_TYPE_COMBO_BOX then
            self:NarrateComboBox(narrationParams:GetComboBox())
        elseif narrationType == NARRATION_ENTRY_TYPE_GRID_LIST_ENTRY then
            local gridList = narrationParams:GetGridList()
            if gridList:IsActive() then
                self:NarrateGridListEntry(gridList:GetSelectedData())
            end
        elseif narrationType == NARRATION_ENTRY_TYPE_EDIT_BOX then
            local editControl = narrationParams:GetEditBoxControl()
            local editBoxName = narrationParams:GetEditBoxName()
            self:NarrateEditBox(editControl, editBoxName)
        elseif narrationType == NARRATION_ENTRY_TYPE_TEXT_SEARCH_HEADER then
            local textSearchHeader = narrationParams:GetTextSearchHeader()
            if textSearchHeader:IsActive() then
                self:NarrateEditBox(textSearchHeader:GetEditBox(), GetString(SI_SCREEN_NARRATION_EDIT_BOX_SEARCH_NAME))
            end
        elseif narrationType == NARRATION_ENTRY_TYPE_DIALOG then
            local dialog = narrationParams:GetDialog()
            if ZO_Dialogs_IsShowing(dialog.name) then
                self:NarrateDialog(dialog, narrationParams:GetNarrateDialogBaseText())
            end
        elseif narrationType == NARRATION_ENTRY_TYPE_FADING_CONTROL_BUFFER then
            self:NarrateFadingControlBuffer(narrationParams:GetFadingControlBufferEntryData(), narrationParams:GetFadingControlBufferTemplateData())
        elseif narrationType == NARRATION_ENTRY_TYPE_FOCUS_ENTRY then
            local focus = narrationParams:GetFocus()
            if focus:IsActive() then
                self:NarrateFocusEntry(narrationParams:GetFocus())
            end
        else
            internalassert(false, "Unhandled narration type")
        end
    end
end

function ZO_ScreenNarrationManager:OnSocialListSelectionChanged(list)
    self:QueueSocialListEntry(list)
end

function ZO_ScreenNarrationManager:OnComboBoxFocused(comboBox)
    self:QueueComboBox(comboBox)
end

function ZO_ScreenNarrationManager:OnSortHeaderChanged(list, sortHeaderGroup, key)
    self:QueueSelectedSortHeader(list, sortHeaderGroup, key)
end

function ZO_ScreenNarrationManager:QueueParametricListEntry(list, narrateHeader)
    if IsScreenNarrationEnabled() then
        local queuedNarration = self.queuedNarration
        if queuedNarration and queuedNarration:GetNarrationType() == NARRATION_ENTRY_TYPE_PARAMETRIC_LIST_ENTRY then
            local queuedList = queuedNarration:GetParametricList()
            local queuedNarrateHeader = queuedNarration:GetNarrateParametricListHeader()
            --If the list we are queueing is the same one we are overwriting, then make sure we still read the header if necessary
            if queuedList == list and queuedNarrateHeader then
                narrateHeader = queuedNarrateHeader
            end
        end
        local narrationParams = self:CreateNarrationParams(NARRATION_ENTRY_TYPE_PARAMETRIC_LIST_ENTRY, SCREEN_NARRATION_QUEUE_DELAY_MS)
        narrationParams:SetParametricList(list, narrateHeader)
        self:SetQueuedNarration(narrationParams)
    end
end

function ZO_ScreenNarrationManager:QueueSocialListEntry(list)
    if IsScreenNarrationEnabled() then
        local narrationParams = self:CreateNarrationParams(NARRATION_ENTRY_TYPE_SOCIAL_LIST_ENTRY, SCREEN_NARRATION_QUEUE_DELAY_MS)
        narrationParams:SetParametricList(list)
        self:SetQueuedNarration(narrationParams)
    end
end

function ZO_ScreenNarrationManager:QueueSelectedSortHeader(list, sortHeaderGroup, key)
    if IsScreenNarrationEnabled() then
        local narrationParams = self:CreateNarrationParams(NARRATION_ENTRY_TYPE_SORT_HEADER, SCREEN_NARRATION_QUEUE_DELAY_MS)
        narrationParams:SetParametricList(list)
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

function ZO_ScreenNarrationManager:QueueEditBox(editControl, name)
    if IsScreenNarrationEnabled() then
        local narrationParams = self:CreateNarrationParams(NARRATION_ENTRY_TYPE_EDIT_BOX, SCREEN_NARRATION_QUEUE_DELAY_MS)
        narrationParams:SetEditBox(editControl, name)
        self:SetQueuedNarration(narrationParams)
    end
end

--TODO XAR: Do we actually need this to be a separate function?
function ZO_ScreenNarrationManager:QueueSearchEditBox(editControl)
    self:QueueEditBox(editControl, GetString(SI_SCREEN_NARRATION_EDIT_BOX_SEARCH_NAME))
end

function ZO_ScreenNarrationManager:QueueGridListEntry(gridList)
    if IsScreenNarrationEnabled() then
        local narrationParams = self:CreateNarrationParams(NARRATION_ENTRY_TYPE_GRID_LIST_ENTRY, SCREEN_NARRATION_QUEUE_DELAY_MS)
        narrationParams:SetGridList(gridList)
        self:SetQueuedNarration(narrationParams)
    end
end

function ZO_ScreenNarrationManager:QueueTextSearchHeader(textSearchHeader)
    if IsScreenNarrationEnabled() then
        local narrationParams = self:CreateNarrationParams(NARRATION_ENTRY_TYPE_TEXT_SEARCH_HEADER, SCREEN_NARRATION_QUEUE_DELAY_MS)
        narrationParams:SetTextSearchHeader(textSearchHeader)
        self:SetQueuedNarration(narrationParams)
    end
end

function ZO_ScreenNarrationManager:QueueDialog(dialog, narrateBaseText)
    if IsScreenNarrationEnabled() then
        local narrationParams = self:CreateNarrationParams(NARRATION_ENTRY_TYPE_DIALOG, SCREEN_NARRATION_QUEUE_DELAY_MS)
        narrationParams:SetDialog(dialog, narrateBaseText)
        self:SetQueuedNarration(narrationParams)
    end
end

function ZO_ScreenNarrationManager:QueueFadingControlBuffer(entryData, templateData)
    if IsScreenNarrationEnabled() then
        local narrationParams = self:CreateNarrationParams(NARRATION_ENTRY_TYPE_FADING_CONTROL_BUFFER, SCREEN_NARRATION_QUEUE_DELAY_MS)
        narrationParams:SetFadingControlBufferData(entryData, templateData)
        self:SetQueuedNarration(narrationParams)
    end
end

function ZO_ScreenNarrationManager:QueueFocus(focus)
    if IsScreenNarrationEnabled() then
        local narrationParams = self:CreateNarrationParams(NARRATION_ENTRY_TYPE_FOCUS_ENTRY, SCREEN_NARRATION_QUEUE_DELAY_MS)
        narrationParams:SetFocus(focus)
        self:SetQueuedNarration(narrationParams)
    end
end

function ZO_ScreenNarrationManager:QueueCSA(messageParams)
    if IsScreenNarrationEnabled() then
        --TODO XAR: Look into having the message params return narratable objects
        local narrationText = self:CreateNarratableObject(messageParams:GetNarrationText())

        --CSAs do not need to wait before sending to the C++, so attempt to narrate them immediately
        --TODO XAR: Have this go into a different queue
        self:NarrateUIText(narrationText)
    end
end

function ZO_ScreenNarrationManager:QueueCountdownCSA(countdownTime)
    if IsScreenNarrationEnabled() then
        --CSAs do not need to wait before sending to the C++, so attempt to narrate them immediately
        --TODO XAR: Have this go into a different queue
        self:NarrateUIText(self:CreateNarratableObject(countdownTime))
    end
end

do
    local KEYBIND_PAUSE_TIME_MS = 100
    --Gets a narratable object for the currently active keybinds on the keybind strip
    function ZO_ScreenNarrationManager:GetKeybindNarration()
        local keybindButtonInfo = KEYBIND_STRIP:GetOrderedNarratableKeybindButtonInfo()
        local keybindNarration = self:CreateNarratableObject(nil, KEYBIND_PAUSE_TIME_MS)
        for i, buttonInfo in ipairs(keybindButtonInfo) do
            local narrationText = ""
            if buttonInfo.name then
                local formatter = i == 1 and SI_SCREEN_NARRATION_FIRST_KEYBIND_FORMATTER or SI_SCREEN_NARRATION_KEYBIND_FORMATTER
                narrationText = zo_strformat(formatter, buttonInfo.keybindName, buttonInfo.name)
            else
                local formatter = i == 1 and SI_SCREEN_NARRATION_FIRST_KEYBIND_FORMATTER_NO_LABEL or SI_SCREEN_NARRATION_KEYBIND_FORMATTER_NO_LABEL
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
    end
end

--Gets a table of narratable objects representing the narration text for a tooltip or tooltips
--If optionalTooltipType is not specified, the table returned will contain a narratable object for each visible tooltip
function ZO_ScreenNarrationManager:GetTooltipNarration(optionalTooltipType)
    --Get the table of tooltip strings
    --The table is ordered based on the order the strings should be read visually
    local tooltipStrings = GAMEPAD_TOOLTIPS:GetNarrationText(optionalTooltipType)

    --If an optional tooltip type was specified tooltipStrings will either be a table of strings representing a single tooltip, or an empty string
    --This means we only need one narratable object
    if optionalTooltipType then
        local narration = self:CreateNarratableObject()
        self:FormatTooltipStrings(narration, tooltipStrings)
        return { narration }
    else
        --If an optional tooltip type was not specified, then tooltipStrings will be a table of tables for each visible tooltip
        --In this situation, we loop and create a narratable object for each individual tooltip
        local narrations = {}
        for i, tooltipNarrationText in ipairs(tooltipStrings) do
            local narration = self:CreateNarratableObject()
            self:FormatTooltipStrings(narration, tooltipNarrationText)
            table.insert(narrations, narration)
        end
        return narrations
    end
end

function ZO_ScreenNarrationManager:NarrateParametricListEntry(narrationInfo, list, entryData, entryControl, narrateHeader)
    local narrations = {}
    if narrateHeader and narrationInfo.headerNarrationFunction then
        local headerNarration = narrationInfo:headerNarrationFunction()
        if headerNarration then
            table.insert(narrations, headerNarration)
        end
    end

    if list:IsEmpty() then
        --If the list is empty, then narrate the no item text instead
        table.insert(narrations, self:CreateNarratableObject(list:GetNoItemText()))
    elseif entryData and (entryData.text or entryData.narrationText) then
        if entryData.header then
            table.insert(narrations, self:CreateNarratableObject(entryData.header))
        end

        if entryData.narrationText then
            if type(entryData.narrationText) == "function" then
                --If the narration text is a function it should return either a narratable object or table of narratable objects
                local narration = entryData.narrationText(entryData, entryControl)
                if IsNarratableObject(narration) then
                    table.insert(narrations, narration)
                else
                    ZO_CombineNumericallyIndexedTables(narrations, narration)
                end
            else
                table.insert(narrations, self:CreateNarratableObject(entryData.narrationText))
            end
        else
            table.insert(narrations, self:CreateNarratableObject(entryData.text))
            --Entries using a custom value via entryData.narrationText need to handle sublabels themselves if they want it
            ZO_CombineNumericallyIndexedTables(narrations, ZO_GetSharedGamepadEntrySubLabelNarrationText(entryData, entryControl))
        end
        ZO_CombineNumericallyIndexedTables(narrations, self:GetTooltipNarration())
    end
    table.insert(narrations, self:GetKeybindNarration())
    self:NarrateUIText(narrations)
end

function ZO_ScreenNarrationManager:NarrateGridListEntry(entryData)
    if entryData then
        local narrations = {}
        if entryData.narrationText then
            if type(entryData.narrationText) == "function" then
                --If the narration text is a function it should return either a narratable object or table of narratable objects
                local narration = entryData.narrationText(entryData)
                if IsNarratableObject(narration) then
                    table.insert(narrations, narration)
                else
                    ZO_CombineNumericallyIndexedTables(narrations, narration)
                end
            else
                table.insert(narrations, self:CreateNarratableObject(entryData.narrationText))
            end
        end
        ZO_CombineNumericallyIndexedTables(narrations, self:GetTooltipNarration())
        table.insert(narrations, self:GetKeybindNarration())

        self:NarrateUIText(narrations)
    end
end

function ZO_ScreenNarrationManager:NarrateSocialListEntry(list)
    local narrations = list:GetSelectedNarrationText()
    table.insert(narrations, self:GetKeybindNarration())
    self:NarrateUIText(narrations)
end

function ZO_ScreenNarrationManager:NarrateSelectedSortHeader(sortHeaderGroup, key)
    local narrations = {}
    table.insert(narrations, sortHeaderGroup:GetSortHeaderNarrationText(key))
    table.insert(narrations, self:GetKeybindNarration())
    self:NarrateUIText(narrations)
end

function ZO_ScreenNarrationManager:NarrateComboBox(comboBox)
    local narrations = {}
    table.insert(narrations, comboBox:GetNarrationText())
    table.insert(narrations, self:GetKeybindNarration())
    self:NarrateUIText(narrations)
end

function ZO_ScreenNarrationManager:NarrateEditBox(editControl, name)
    local narrations = {}
    table.insert(narrations, ZO_FormatEditBoxNarrationText(editControl, name))
    table.insert(narrations, self:GetKeybindNarration())
    self:NarrateUIText(narrations)
end

function ZO_ScreenNarrationManager:NarrateFocusEntry(focus)
    if focus then
        local narrations = {}
        local focusNarration = focus:GetNarrationText()
        if focusNarration then
            table.insert(narrations, focusNarration)
        end

        ZO_CombineNumericallyIndexedTables(narrations, self:GetTooltipNarration())
        table.insert(narrations, self:GetKeybindNarration())

        self:NarrateUIText(narrations)
    end
end

--Forms a table of the narrations that are common amongst all the dialog types
function ZO_ScreenNarrationManager:GetDialogBaseNarration(dialog, dialogInfo, dialogType, textParams, narrateBaseText)
    local narrations = {}
    --narrateBaseText should only be true upon first opening the dialog
    if narrateBaseText then
        if dialog.header and dialog.headerData then
            table.insert(narrations, ZO_GamepadGenericHeader_GetNarrationText(dialog.header, dialog.headerData))
        elseif dialogInfo.title then
            local titleText = ZO_GetFormattedDialogText(dialog, dialogInfo.title, textParams.titleParams)
            table.insert(narrations, self:CreateNarratableObject(titleText))
        end

        if dialogInfo.mainText then
            local mainText = ZO_GetFormattedDialogText(dialog, dialogInfo.mainText, textParams.mainTextParams)
            table.insert(narrations, self:CreateNarratableObject(mainText))
        end

        --Centered dialogs do not support sub text or warning
        if dialogType ~= GAMEPAD_DIALOGS.CENTERED then
            if dialogInfo.subText then
                local subText = ZO_GetFormattedDialogText(dialog, dialogInfo.subText, textParams.subTextParams)
                table.insert(narrations, self:CreateNarratableObject(subText))
            end

            if dialogInfo.warning then
                local warningText = ZO_GetFormattedDialogText(dialog, dialogInfo.warning, textParams.warningParams)
                table.insert(narrations, self:CreateNarratableObject(warningText))
            end
        end

        if dialogInfo.baseNarrationTooltip then
            ZO_CombineNumericallyIndexedTables(narrations, self:GetTooltipNarration(dialogInfo.baseNarrationTooltip))
        end
    end

    return narrations
end

function ZO_ScreenNarrationManager:NarrateDialog(dialog, narrateBaseText)
    local dialogInfo = dialog.info
    if dialogInfo.gamepadInfo then
        local dialogType = dialogInfo.gamepadInfo.dialogType
        local textParams = dialog.textParams or {}
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
                    if entryData.header then
                        table.insert(narrations, self:CreateNarratableObject(entryData.header))
                    end

                    if entryData.narrationText then
                        if type(entryData.narrationText) == "function" then
                            local narration = entryData.narrationText(entryData, entryControl)
                            if IsNarratableObject(narration) then
                                table.insert(narrations, narration)
                            else
                                ZO_CombineNumericallyIndexedTables(narrations, narration)
                            end
                        else
                            table.insert(narrations, self:CreateNarratableObject(entryData.narrationText))
                        end
                    else
                        table.insert(narrations, self:CreateNarratableObject(entryData.text))
                        --Entries using a custom value via entryData.narrationText need to handle sublabels themselves if they want it
                        ZO_CombineNumericallyIndexedTables(narrations, ZO_GetSharedGamepadEntrySubLabelNarrationText(entryData, entryControl))
                    end

                    --Dialogs only narrate tooltips when one is specifically specified
                    if entryData.narrationTooltip then
                        ZO_CombineNumericallyIndexedTables(narrations, self:GetTooltipNarration(entryData.narrationTooltip))
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
                table.insert(narrations, self:CreateNarratableObject(loadingText))
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
                    table.insert(narrations, self:CreateNarratableObject(info.label))
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

                if dialogInfo.narrationText then
                    if type(dialogInfo.narrationText) == "function" then
                        --If the narration text is a function it should return either a narratable object or table of narratable objects
                        local narration = dialogInfo.narrationText(dialog, itemName)
                        if IsNarratableObject(narration) then
                            table.insert(narrations, narration)
                        else
                            ZO_CombineNumericallyIndexedTables(narrations, narration)
                        end
                    else
                        table.insert(narrations, self:CreateNarratableObject(dialogInfo.narrationText))
                    end
                else
                    table.insert(narrations, ZO_FormatSliderNarrationText(dialog.slider, itemName))
                end
            end
        elseif dialogType == GAMEPAD_DIALOGS.CUSTOM then
            if dialogInfo.narrationText then
                if type(dialogInfo.narrationText) == "function" then
                    local narration = dialogInfo.narrationText(dialog)
                    if IsNarratableObject(narration) then
                        table.insert(narrations, narration)
                    else
                        ZO_CombineNumericallyIndexedTables(narrations, narration)
                    end
                else
                    table.insert(narrations, self:CreateNarratableObject(dialogInfo.narrationText))
                end
            end
        else
            internalassert(false, "Unhandled dialog type")
        end

        --Always add keybinds at the end
        table.insert(narrations, self:GetKeybindNarration())
        self:NarrateUIText(narrations)
    end
end

function ZO_ScreenNarrationManager:NarrateFadingControlBuffer(entryData, templateData)
    local narrations = {}
    if entryData.header then
        if templateData.headerNarrationText then
            table.insert(narrations, templateData.headerNarrationText(entryData))
        else
            table.insert(narrations, self:CreateNarratableObject(entryData.header.text))
        end
    end

    local lines = entryData.lines
    if lines then
        local narrationFunction = templateData.narrationText
        for _, line in ipairs(lines) do
            if narrationFunction then
                table.insert(narrations, narrationFunction(line))
            else
                table.insert(narrations, self:CreateNarratableObject(line.text))
            end
        end
    end

    --TODO XAR: Have this use a separate queue from normal UI text
    --We may want to have crafting results and alerts go to different queues differently
    self:NarrateUIText(narrations)
end

--TODO XAR: Do we need category here?
function ZO_ScreenNarrationManager:NarrateChatMessage(chatMessage, category)
    if IsChatNarrationEnabled() then
        if chatMessage ~= "" then
            --TODO XAR: Make a narrate text function that takes a narration type
            RequestReadTextChatToClient(chatMessage)
        end
    end
end

--Adds a single narratable object to the pending narration and then releases the object
function ZO_ScreenNarrationManager:AddPendingNarration(narratableObject)
    local narrationText = narratableObject:GetNarrationText()
    if narrationText ~= "" then
        AddPendingNarrationText(narrationText)
    end
    narratableObject:ReleaseObject()
end

function ZO_ScreenNarrationManager:NarrateUIText(narration)
    if type(narration) == "table" then
        if IsNarratableObject(narration) then
            self:AddPendingNarration(narration)
        else
            for _, narratableObject in ipairs(narration) do
                self:AddPendingNarration(narratableObject)
            end
        end
    end

    RequestReadPendingNarrationTextToClient()
end

--Global functions

--Given a grid list entry, returns the narration text from the entry's object. Intended to be used for entries that inherit from ZO_Tile
function ZO_GetNarrationTextForGridListTile(entryData)
    if entryData and entryData.dataEntry then
        if entryData.dataEntry.control then
            return entryData.dataEntry.control.object:GetNarrationText()
        end
    end
end

--Generates narration text for a toggle control. The header parameter is optional
function ZO_FormatToggleNarrationText(name, isChecked, header)
    local isCheckedText = isChecked and GetString(SI_SCREEN_NARRATION_TOGGLE_ON) or GetString(SI_SCREEN_NARRATION_TOGGLE_OFF)
    if header then
        return SCREEN_NARRATION_MANAGER:CreateNarratableObject(zo_strformat(SI_SCREEN_NARRATION_TOGGLE_WITH_HEADER_FORMATTER, name, isCheckedText, header))
    else
        return SCREEN_NARRATION_MANAGER:CreateNarratableObject(zo_strformat(SI_SCREEN_NARRATION_TOGGLE_FORMATTER, name, isCheckedText))
    end
end

--Generates narration text for a radio button control. The header parameter is optional
function ZO_FormatRadioButtonNarrationText(name, isChecked, header)
    local isCheckedText = isChecked and GetString(SI_SCREEN_NARRATION_TOGGLE_ON) or GetString(SI_SCREEN_NARRATION_TOGGLE_OFF)
    if header then
        return SCREEN_NARRATION_MANAGER:CreateNarratableObject(zo_strformat(SI_SCREEN_NARRATION_RADIO_BUTTON_WITH_HEADER_FORMATTER, name, isCheckedText, header))
    else
        return SCREEN_NARRATION_MANAGER:CreateNarratableObject(zo_strformat(SI_SCREEN_NARRATION_RADIO_BUTTON_FORMATTER, name, isCheckedText))
    end
end

do
    internalassert(TEXT_TYPE_MAX_VALUE == 5)
    local NUMERIC_ONLY_TEXT_TYPES =
    {
        [TEXT_TYPE_NUMERIC] = true,
        [TEXT_TYPE_NUMERIC_UNSIGNED_INT] = true,
    }

    --Generates narration text for an edit control. The name parameter is optional.
    function ZO_FormatEditBoxNarrationText(editControl, name)
        if editControl then
            local narration = SCREEN_NARRATION_MANAGER:CreateNarratableObject(name)

            local textType = editControl:GetTextType()
            --Use a slightly different string if the edit control is numeric (meaning it only accepts numbers)
            if NUMERIC_ONLY_TEXT_TYPES[textType] then
                narration:AddNarrationText(GetString(SI_SCREEN_NARRATION_NUMERIC_EDIT_BOX))
            else
                narration:AddNarrationText(GetString(SI_SCREEN_NARRATION_EDIT_BOX))
            end

            local valueText = editControl:GetText()
            --Default to using the current value text of the edit box, and then fall back to the default text if necessary
            if valueText ~= "" then
                narration:AddNarrationText(valueText)
            else
                narration:AddNarrationText(editControl:GetDefaultText())
            end
            narration:AddNarrationText(zo_strformat(SI_SCREEN_NARRATION_EDIT_BOX_INPUT_CHARACTER_LIMIT, editControl:GetMaxInputChars()))

            return narration
        end
    end
end

--Generates narration text for a spinner.
function ZO_FormatSpinnerNarrationText(name, value)
    --TODO XAR: Include directional input for the spinner
    return SCREEN_NARRATION_MANAGER:CreateNarratableObject(zo_strformat(SI_SCREEN_NARRATION_SPINNER_FORMATTER, name, value))
end

--Generates narration text for a slider
function ZO_FormatSliderNarrationText(sliderControl, name)
    --TODO XAR: Include directional input for the slider
    local min, max = sliderControl:GetMinMax()
    local value = sliderControl:GetValue()
    return SCREEN_NARRATION_MANAGER:CreateNarratableObject(zo_strformat(SI_SCREEN_NARRATION_SLIDER_FORMATTER, name, value, min, max))
end

--Default function for getting the narration text for a dropdown entry in a parametric list
function ZO_GetDefaultParametricListDropdownNarrationText(entryData, entryControl)
    return entryControl.dropdown:GetNarrationText()
end

--Default function for getting the narration text for an edit box control in a parametric list
function ZO_GetDefaultParametricListEditBoxNarrationText(entryData, entryControl)
    return ZO_FormatEditBoxNarrationText(entryControl.editBoxControl)
end

--Default function for getting the narration text for a toggle in a parametric list
function ZO_GetDefaultParametricListToggleNarrationText(entryData, entryControl)
    local isChecked = ZO_GamepadCheckBoxTemplate_IsChecked(entryControl)
    return ZO_FormatToggleNarrationText(entryData.text, isChecked)
end

--Function for getting a table of narratable objects for sublabels defined in a shared gamepad entry
function ZO_GetSharedGamepadEntrySubLabelNarrationText(entryData, entryControl)
    local narrations = {}
    if entryData.subLabelsNarrationText then
        if type(entryData.subLabelsNarrationText) == "function" then
            local narration = entryData.subLabelsNarrationText(entryData, entryControl)
            if IsNarratableObject(narration) then
                table.insert(narrations, narration)
            else
                ZO_CombineNumericallyIndexedTables(narrations, narration)
            end
        else
            table.insert(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(entryData.subLabelsNarrationText))
        end
    elseif entryData.subLabels then
        for _, subLabelTextProvider in ipairs(entryData.subLabels) do
            local subLabelText
            if type(subLabelTextProvider) == "function" then
                subLabelText = subLabelTextProvider()
            else
                subLabelText = subLabelTextProvider
            end
            table.insert(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(subLabelText))
        end
    end
    return narrations
end

do
    local DEFAULT_PAUSE_TIME_MS = 200
    --Forms a table of strings into a single string separated by pauses for narration.
    function ZO_GeneratePauseSeparatedList(argumentTable, pauseTime)
        pauseTime = pauseTime or DEFAULT_PAUSE_TIME_MS
        local delimiter = string.format(" <break time=\"%dms\" /> ", pauseTime)
        return ZO_GenerateDelimiterSeparatedList(argumentTable, delimiter)
    end
end

-- Global singleton

-- The global singleton moniker is assigned by the Narration Manager's constructor in order to
-- allow data objects to reference the singleton during their construction.
ZO_ScreenNarrationManager:New()