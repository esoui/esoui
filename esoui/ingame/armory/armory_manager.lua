
ZO_ARMORY_BUILD_ICON_TEXTURE_FORMATTER = "EsoUI/Art/Armory/BuildIcons/buildIcon_%d.dds"
ZO_ARMORY_NUM_BUILD_ICONS = 78

-----------------------------
-- Armory Manager
-----------------------------
ZO_Armory_Manager = ZO_InitializingCallbackObject:Subclass()

function ZO_Armory_Manager:Initialize()
    self.armoryInteraction =
    {
        type = "Armory",
        interactTypes = { INTERACTION_ARMORY },
    }
    self.initialized = false
    self.armoryBuildData = {}
    self.armoryBuildIcons = {}

    self.currentBuildOperation = ARMORY_BUILD_OPERATION_TYPE_NONE

    EVENT_MANAGER:RegisterForEvent("ArmoryManager", EVENT_ARMORY_BUILDS_FULL_UPDATE, function() self:RefreshBuildList() end)
    EVENT_MANAGER:RegisterForEvent("ArmoryManager", EVENT_ARMORY_BUILD_COUNT_UPDATED, function() self:RefreshBuildList() end)
    EVENT_MANAGER:RegisterForEvent("ArmoryManager", EVENT_ARMORY_BUILD_OPERATION_STARTED, function(...) self:OnBuildOperationStarted(...) end)
    EVENT_MANAGER:RegisterForEvent("ArmoryManager", EVENT_ARMORY_BUILD_SAVE_RESPONSE, function(...) self:OnBuildSaveResponseReceived(...) end)
    EVENT_MANAGER:RegisterForEvent("ArmoryManager", EVENT_ARMORY_BUILD_RESTORE_RESPONSE, function(...) self:OnBuildRestoreResponseReceived(...) end)
    EVENT_MANAGER:RegisterForEvent("ArmoryManager", EVENT_ARMORY_BUILD_UPDATED, function(...) self:FireCallbacks("BuildListUpdated") end)

    EVENT_MANAGER:RegisterForEvent("ArmoryManager", EVENT_OPEN_ARMORY_MENU, function()
        self:PerformDeferredInitialization()
        PlaySound(SOUNDS.ARMORY_OPEN)
        if IsInGamepadPreferredMode() then
            SCENE_MANAGER:Show("armoryRootGamepad")
        else
            SCENE_MANAGER:Show("armoryKeyboard")
        end
    end)
end

function ZO_Armory_Manager:PerformDeferredInitialization()
    if not self.initialized then
        self.initialized = true
        self:RefreshBuildList()
        self:RefreshBuildIcons()
    end
end

function ZO_Armory_Manager:TryShowBuildOperationDialog(textParams, operationType)
    if self.currentBuildOperation ~= ARMORY_BUILD_OPERATION_TYPE_NONE then
        if operationType == ARMORY_BUILD_OPERATION_TYPE_SAVE then
            ZO_Dialogs_ShowPlatformDialog("ARMORY_BUILD_SAVE_DIALOG", nil, textParams)
        elseif operationType == ARMORY_BUILD_OPERATION_TYPE_RESTORE then
            ZO_Dialogs_ShowPlatformDialog("ARMORY_BUILD_RESTORE_DIALOG", nil, textParams)
        end
    end

    self.buildOperationInProgressDialogCallId = nil
end

local OPERATION_DIALOG_DELAY_MS = 500
function ZO_Armory_Manager:OnBuildOperationStarted(_, operationType, buildIndex)
    internalassert(self.currentBuildOperation == ARMORY_BUILD_OPERATION_TYPE_NONE, "Attempting to start an armory build operation when one is already in progress")
    local buildData = self:GetBuildDataByIndex(buildIndex)
    if buildData then
        local textParams =
        {
            mainTextParams = { ZO_SELECTED_TEXT:Colorize(buildData:GetName()) },
        }
        self.currentBuildOperation = operationType
        self.buildOperationInProgressDialogCallId = zo_callLater(function() self:TryShowBuildOperationDialog(textParams, operationType) end, OPERATION_DIALOG_DELAY_MS)
        self:FireCallbacks("BuildOperationStarted")
    end
end

function ZO_Armory_Manager:OnBuildSaveResponseReceived(_, result, buildIndex)
    --Only do this part if a build save was already in progress
    if self.currentBuildOperation == ARMORY_BUILD_OPERATION_TYPE_SAVE then
        self.currentBuildOperation = ARMORY_BUILD_OPERATION_TYPE_NONE
        if self.buildOperationInProgressDialogCallId then
            zo_removeCallLater(self.buildOperationInProgressDialogCallId)
            self.buildOperationInProgressDialogCallId = nil
        end
        ZO_Dialogs_ReleaseDialog("ARMORY_BUILD_SAVE_DIALOG")
        self:FireCallbacks("BuildOperationCompleted")
    end

    if result == ARMORY_BUILD_SAVE_RESULT_SUCCESS then
        PlaySound(SOUNDS.ARMORY_SAVE_SUCCESS)
        local buildData = self:GetBuildDataByIndex(buildIndex)
        if buildData then
            ZO_Dialogs_ShowPlatformDialog("ARMORY_BUILD_SAVE_SUCCESS_DIALOG", nil, { mainTextParams = { ZO_SELECTED_TEXT:Colorize(buildData:GetName()) } })
        end
    else
        ZO_Dialogs_ShowPlatformDialog("ARMORY_BUILD_SAVE_FAILED_DIALOG", nil, { mainTextParams = { GetString("SI_ARMORYBUILDSAVERESULT", result) } })
    end
end

function ZO_Armory_Manager:OnBuildRestoreResponseReceived(_, result, buildIndex)
    --Only do this part if a build restore was already in progress
    if self.currentBuildOperation == ARMORY_BUILD_OPERATION_TYPE_RESTORE then
        self.currentBuildOperation = ARMORY_BUILD_OPERATION_TYPE_NONE
        if self.buildOperationInProgressDialogCallId then
            zo_removeCallLater(self.buildOperationInProgressDialogCallId)
            self.buildOperationInProgressDialogCallId = nil
        end
        ZO_Dialogs_ReleaseDialog("ARMORY_BUILD_RESTORE_DIALOG")
        self:FireCallbacks("BuildOperationCompleted")
    end

    if result == ARMORY_BUILD_RESTORE_RESULT_SUCCESS then
        PlaySound(SOUNDS.ARMORY_RESTORE_SUCCESS)
        local buildData = self:GetBuildDataByIndex(buildIndex)
        if buildData then
            ZO_Dialogs_ShowPlatformDialog("ARMORY_BUILD_RESTORE_SUCCESS_DIALOG", nil, { mainTextParams = { ZO_SELECTED_TEXT:Colorize(buildData:GetName()) } })
        end
    else
        ZO_Dialogs_ShowPlatformDialog("ARMORY_BUILD_RESTORE_FAILED_DIALOG", nil, { mainTextParams = { GetString("SI_ARMORYBUILDRESTORERESULT", result) } })
    end
end

function ZO_Armory_Manager:IsBuildOperationInProgress()
    return self.currentBuildOperation ~= ARMORY_BUILD_OPERATION_TYPE_NONE
end

function ZO_Armory_Manager:SetHideOnBuildOperationComplete(hideOnComplete)
    self.hideOnBuildOperationComplete = hideOnComplete
end

function ZO_Armory_Manager:OnBuildOperationResultClosed()
    if self.hideOnBuildOperationComplete then
        self.hideOnBuildOperationComplete = false
        SCENE_MANAGER:ShowBaseScene()
    else
        if IsInGamepadPreferredMode() then
            ARMORY_GAMEPAD:UpdateKeybinds()
        end
    end
end

do
    local GAMPAD_EQUIPMENT_SLOT_TYPES =
    {
        EQUIP_SLOT_MAIN_HAND,
        EQUIP_SLOT_OFF_HAND,
        EQUIP_SLOT_POISON,

        EQUIP_SLOT_BACKUP_MAIN,
        EQUIP_SLOT_BACKUP_OFF,
        EQUIP_SLOT_BACKUP_POISON,

        EQUIP_SLOT_HEAD,
        EQUIP_SLOT_CHEST,
        EQUIP_SLOT_SHOULDERS,

        EQUIP_SLOT_WAIST,
        EQUIP_SLOT_HAND,

        EQUIP_SLOT_LEGS,
        EQUIP_SLOT_FEET,

        EQUIP_SLOT_NECK,
        EQUIP_SLOT_RING1,
        EQUIP_SLOT_RING2,
    }

    -- The set of equip slots shown in a build in their expected order.
    local EQUIPMENT_SLOT_TYPES =
    {
        EQUIP_SLOT_HEAD,
        EQUIP_SLOT_SHOULDERS,
        EQUIP_SLOT_CHEST,
        EQUIP_SLOT_HAND,
        EQUIP_SLOT_WAIST,
        EQUIP_SLOT_LEGS,
        EQUIP_SLOT_FEET,
        EQUIP_SLOT_NECK,
        EQUIP_SLOT_RING1,
        EQUIP_SLOT_RING2,
    }

    function ZO_Armory_Manager:GetEquipmentSlotTypes()
        if IsInGamepadPreferredMode() then
            return GAMPAD_EQUIPMENT_SLOT_TYPES
        else
            return EQUIPMENT_SLOT_TYPES
        end
    end

    local SUPPORTED_SKILLS_HOTBAR_CATEGORIES =
    {
        [HOTBAR_CATEGORY_PRIMARY] = true,
        [HOTBAR_CATEGORY_BACKUP] = true,
    }
    function ZO_Armory_Manager:GetSkillsHotBarCategories()
        return SUPPORTED_SKILLS_HOTBAR_CATEGORIES
    end
end

function ZO_Armory_Manager:GetInteraction()
    return self.armoryInteraction
end

function ZO_Armory_Manager:ShowBuildOperationConfirmationDialog(operationType, buildIndex)
    local buildData = self:GetBuildDataByIndex(buildIndex)
    if buildData then
        if operationType == ARMORY_BUILD_OPERATION_TYPE_RESTORE then
            local data =
            {
                selectedBuildIndex = buildIndex,
                curseType = buildData:GetCurseType(),
                primaryMundus = buildData:GetPrimaryMundusStone(),
            }
            ZO_Dialogs_ShowPlatformDialog("ARMORY_BUILD_RESTORE_CONFIRM_DIALOG", data, { mainTextParams = { ZO_SELECTED_TEXT:Colorize(buildData:GetName()) } })
        elseif operationType == ARMORY_BUILD_OPERATION_TYPE_SAVE then
            ZO_Dialogs_ShowPlatformDialog("ARMORY_BUILD_SAVE_CONFIRM_DIALOG", { selectedBuildIndex = buildIndex }, { mainTextParams = { ZO_SELECTED_TEXT:Colorize(buildData:GetName()) } })
        end
    end
end

function ZO_Armory_Manager:RefreshBuildIcons()
    ZO_ClearNumericallyIndexedTable(self.armoryBuildIcons)
    for i = 1, ZO_ARMORY_NUM_BUILD_ICONS do
        table.insert(self.armoryBuildIcons, string.format(ZO_ARMORY_BUILD_ICON_TEXTURE_FORMATTER, i))
    end
end

function ZO_Armory_Manager:RefreshBuildList()
    ZO_ClearNumericallyIndexedTable(self.armoryBuildData)

    local numBuilds = GetNumUnlockedArmoryBuilds()
    for index = 1, numBuilds do
        table.insert(self.armoryBuildData, ZO_ArmoryBuildData:New(index))
    end

    self:FireCallbacks("BuildListUpdated")
end

function ZO_Armory_Manager:BuildDataIterator(filterFunctions)
    return ZO_FilteredNumericallyIndexedTableIterator(self.armoryBuildData, filterFunctions)
end

function ZO_Armory_Manager:GetBuildDataByIndex(buildIndex)
    return self.armoryBuildData[buildIndex]
end

function ZO_Armory_Manager:GetBuildIcon(iconIndex)
    return self.armoryBuildIcons[iconIndex]
end

ZO_ARMORY_MANAGER = ZO_Armory_Manager:New()