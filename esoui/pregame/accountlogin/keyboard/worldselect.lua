local SERVER_DATA = 1

local worldStatusStrings =
{
    [SERVER_STATUS_DOWN]    = SI_SERVER_STATUS_DOWN,
    [SERVER_STATUS_UP]      = SI_SERVER_STATUS_UP,
    [SERVER_STATUS_OUT]     = SI_SERVER_STATUS_OUT,
    [SERVER_STATUS_LOCKED]  = SI_SERVER_STATUS_LOCKED,
}

local defaultColor = ZO_ColorDef:New(1, 1, 1)

local STATUS_COLORS =
{
    [GetString(SI_SERVER_STATUS_DOWN)]    = ZO_ColorDef:New(1, 0, 0),
    [GetString(SI_SERVER_STATUS_UP)]      = ZO_ColorDef:New(0, 1, 0),
    [GetString(SI_SERVER_STATUS_OUT)]     = ZO_ColorDef:New(.75, .75, .75),
    [GetString(SI_SERVER_STATUS_LOCKED)]  = ZO_ColorDef:New(.75, 0, .75),
}

local function SetupWorld(control, data)
    local worldName = control:GetNamedChild("Name")
    local worldStatus = control:GetNamedChild("Status")

    worldName:SetText(data.name)
    worldStatus:SetText(data.status)

    local fieldColor = STATUS_COLORS[data.status] or defaultColor
    worldStatus:SetColor(fieldColor:UnpackRGBA())
end

local worldSortKeys =
{
    ["name"]        = { },
    ["status"]      = { tiebreaker = "name" },
}

local currentSortKey = "name"
local currentSortOrder = ZO_SORT_ORDER_UP

local function SortWorlds(world1, world2)
    return ZO_TableOrderingFunction(world1.data, world2.data, currentSortKey, worldSortKeys, currentSortOrder)
end

function ZO_WorldSelect_SortListAndCommit(sortKey)
    if sortKey then
        if sortKey == currentSortKey then
            currentSortOrder = not currentSortOrder
        else
            currentSortOrder = ZO_SORT_ORDER_UP
        end

        currentSortKey = sortKey
    end

    local dataList = ZO_ScrollList_GetDataList(ZO_WorldSelectScrollList)
    table.sort(dataList, SortWorlds)
    ZO_ScrollList_Commit(ZO_WorldSelectScrollList, dataList)
end

function ZO_WorldSelect_UpdateWorlds()
    local worldDataToSelect = nil
    local realmNameToSelect = nil
    local isInitialUpdate = ZO_ScrollList_GetSelectedData(ZO_WorldSelectScrollList) == nil
    if isInitialUpdate then
        realmNameToSelect = GetCVar("LastRealm")
    end

    local dataList = ZO_ScrollList_GetDataList(ZO_WorldSelectScrollList)
    ZO_ClearNumericallyIndexedTable(dataList)
    local numWorlds = GetNumWorlds()
    for worldIndex = 0, numWorlds - 1 do
        local worldName, worldStatus = GetWorldInfo(worldIndex)

        if worldName ~= "" and worldStatus ~= SERVER_STATUS_OUT then
            worldStatus = GetString(worldStatusStrings[worldStatus])

            if worldStatus == "" then
                worldStatus = GetString(SI_SERVER_STATUS_INVALID)
            end

            local worldData =
            {
                name = worldName,
                status = worldStatus,
                worldIndex = worldIndex,
            }

            if worldName == realmNameToSelect then
                worldDataToSelect = worldData
            end

            table.insert(dataList, ZO_ScrollList_CreateDataEntry(SERVER_DATA, worldData))
        end
    end

    ZO_WorldSelect_SortListAndCommit()
    if worldDataToSelect then
        ZO_ScrollList_SelectDataAndScrollIntoView(ZO_WorldSelectScrollList, worldDataToSelect)
    end
end

local worldSelectionEnabled = true

function ZO_WorldSelect_SetSelectionEnabled(enabled)
    worldSelectionEnabled = enabled
    ZO_WorldSelectLogin:SetEnabled(enabled)
end

function ZO_WorldSelect_SelectWorldForPlay()
    if worldSelectionEnabled == false then
        return
    end

    local worldData = ZO_ScrollList_GetSelectedData(ZO_WorldSelectScrollList)
    if worldData then
        -- if the user picked the same world they are already logged into, just bail out...
        if (GetWorldName() ~= worldData.name) or not IsConnectedToLobby() then
            if worldData.status == GetString(SI_SERVER_STATUS_UP) then
                ZO_WorldSelect:SetHidden(true)
                ZO_WorldSelect_SetSelectionEnabled(false)
                ZO_Dialogs_ShowDialog("CONNECTING_TO_REALM", nil, { mainTextParams = { worldData.name } })
                SelectWorld(worldData.worldIndex)
            else
                ZO_Dialogs_ShowDialog("SERVER_UNAVAILABLE", nil, { mainTextParams = { worldData.name } })
            end
        else
            PregameStateManager_SetState("CharacterSelect_FromIngame")
        end
    end
end

function ZO_WorldSelect_SelectWorldByName(worldName)
    local worldData = ZO_ScrollList_GetDataList(ZO_WorldSelectScrollList)

    if worldData and worldName then
        if (GetWorldName() ~= worldData.name) or not IsConnectedToLobby() then
            for _, v in ipairs(worldData) do
                if string.lower(v.data.name) == string.lower(worldName) then
                    SelectWorld(v.data.worldIndex)
                    break
                end
            end
        end
    end
end

function ZO_WorldSelect_Cancel()
    SetCVar("QuickLaunch", "0")
    PregameStateManager_SetState("AccountLogin")
end

function ZO_WorldSelect_Initialize(control)
    local list = control:GetNamedChild("ScrollList")
    ZO_ScrollList_AddDataType(list, SERVER_DATA, "ZO_WorldSelectRowTemplate", 24, SetupWorld)
    ZO_ScrollList_SetEqualityFunction(list, SERVER_DATA, function(world1, world2) return world1.name == world2.name end)
    ZO_ScrollList_EnableSelection(list, "ZO_ThinListHighlight")
    ZO_ScrollList_EnableHighlight(list, "ZO_ThinListHighlight")
    ZO_ScrollList_SetDeselectOnReselect(list, false)

    EVENT_MANAGER:RegisterForEvent("WorldSelect", EVENT_WORLD_LIST_RECEIVED, ZO_WorldSelect_UpdateWorlds)

    local worldSelectFragment = ZO_FadeSceneFragment:New(control)
    local worldSelectScene = ZO_Scene:New("worldSelect", SCENE_MANAGER)
    worldSelectScene:AddFragment(worldSelectFragment)
    worldSelectScene:AddFragment(PREGAME_BACKGROUND_FRAGMENT)
end
