local syncOptions -- Choice of repository, network share, or perforce fetch for new gamedata

local SERVER_DATA = 1

local serverStatusStrings =
{
    [SERVER_STATUS_DOWN]    = SI_SERVER_STATUS_DOWN,
    [SERVER_STATUS_UP]      = SI_SERVER_STATUS_UP,
    [SERVER_STATUS_OUT]     = SI_SERVER_STATUS_OUT,
    [SERVER_STATUS_LOCKED]  = SI_SERVER_STATUS_LOCKED,
}

local defaultColor = ZO_ColorDef:New (1, 1, 1)

local STATUS_COLORS = 
{
    [GetString(SI_SERVER_STATUS_DOWN)]    = ZO_ColorDef:New(1, 0, 0),
    [GetString(SI_SERVER_STATUS_UP)]      = ZO_ColorDef:New(0, 1, 0),
    [GetString(SI_SERVER_STATUS_OUT)]     = ZO_ColorDef:New(.75, .75, .75),
    [GetString(SI_SERVER_STATUS_LOCKED)]  = ZO_ColorDef:New(.75, 0, .75),
}

local function SetupServer(control, data)
    local serverName = GetControl(control, "Name")
    local serverStatus = GetControl(control, "Status")
        
    serverName:SetText(data.name)
    serverStatus:SetText(data.status)

    local fieldColor = STATUS_COLORS[data.status] or defaultColor
    serverStatus:SetColor(fieldColor:UnpackRGBA())
end

local serverSortKeys =
{
    ["name"]        = { }, 
    ["status"]      = { tiebreaker = "name" },    
}

local currentSortKey = "name"
local currentSortOrder = ZO_SORT_ORDER_UP

local function SortServers(server1, server2)
    return ZO_TableOrderingFunction(server1.data, server2.data, currentSortKey, serverSortKeys, currentSortOrder)
end

function ZO_ServerSelect_SortListAndCommit(sortKey)
    if(sortKey)
    then
        if(sortKey == currentSortKey)
        then
            currentSortOrder = not currentSortOrder
        else
            currentSortOrder = ZO_SORT_ORDER_UP
        end
        
        currentSortKey = sortKey
    end
    
    local dataList = ZO_ScrollList_GetDataList(ZO_ServerSelectScrollList)
    table.sort(dataList, SortServers)
    ZO_ScrollList_Commit(ZO_ServerSelectScrollList, dataList)
end

function ZO_ServerSelect_UpdateWorlds()    
    local dataList = ZO_ScrollList_GetDataList(ZO_ServerSelectScrollList)
    ZO_ClearNumericallyIndexedTable(dataList)

    local numWorlds = GetNumWorlds()
    if(numWorlds > 0) then
        for worldIndex = 0, numWorlds - 1 do
            local serverName, serverStatus = GetWorldInfo(worldIndex)
            
            if(serverName ~= "" and (serverStatus ~= SERVER_STATUS_OUT))
            then
                serverStatus = GetString(serverStatusStrings[serverStatus]) 
                
                if(serverStatus == "")
                then
                    serverStatus = GetString(SI_SERVER_STATUS_INVALID)
                end

                table.insert(dataList, ZO_ScrollList_CreateDataEntry(SERVER_DATA, { name = serverName, status = serverStatus, worldIndex = worldIndex }))
            end
        end
    end
    
	ZO_ServerSelect_SortListAndCommit()        
end

local worldSelectionEnabled = true

function ZO_ServerSelect_SetSelectionEnabled(enabled)
    worldSelectionEnabled = enabled
    ZO_ServerSelectLogin:SetEnabled(enabled)
end

function ZO_ServerSelect_SelectWorldForPlay()
    if(worldSelectionEnabled == false) then return end

    local serverData = ZO_ScrollList_GetSelectedData(ZO_ServerSelectScrollList)
    if(serverData) then                
        -- if the user picked the same world they are already logged into, just bail out...
        if((GetWorldName() ~= serverData.name) or not IsConnectedToLobby()) then
            if(serverData.status == GetString(SI_SERVER_STATUS_UP)) then
                ZO_ServerSelect:SetHidden(true)
                ZO_ServerSelect_SetSelectionEnabled(false)
                ZO_Dialogs_ShowDialog("CONNECTING_TO_REALM", nil, {mainTextParams = {serverData.name}})
                SelectWorld(serverData.worldIndex)
                ZO_CharacterSelect_ClearDefVersionInfo()
            else
                ZO_Dialogs_ShowDialog("SERVER_UNAVAILABLE", nil, {mainTextParams = {serverData.name}})
            end
        else
            PregameStateManager_SetState("CharacterSelect_FromIngame")
        end
    end
end

function ZO_ServerSelect_SelectWorldByName(worldName)
    local serverData = ZO_ScrollList_GetDataList(ZO_ServerSelectScrollList)

    if serverData and worldName then
        if((GetWorldName() ~= serverData.name) or not IsConnectedToLobby()) then
            for _, v in ipairs(serverData) do
                if string.lower(v.data.name) == string.lower(worldName) then
                    SelectWorld(v.data.worldIndex)
                    break
                end
            end
        end
    end
end

function ZO_ServerSelect_Initialize()
    local list = ZO_ServerSelectScrollList
    ZO_ScrollList_AddDataType(list, SERVER_DATA, "ZO_ServerSelectRowTemplate", 24, SetupServer)
    ZO_ScrollList_SetEqualityFunction(list, SERVER_DATA, function(server1, server2) return server1.name == server2.name end)
    ZO_ScrollList_EnableSelection(list, "ZO_ThinListHighlight")
    ZO_ScrollList_EnableHighlight(list, "ZO_ThinListHighlight")
    ZO_ScrollList_SetDeselectOnReselect(list, false)
    ZO_ServerSelectCancel.gameStateString = "AccountLogin"
    
    EVENT_MANAGER:RegisterForEvent("ServerSelect", EVENT_WORLD_LIST_RECEIVED, ZO_ServerSelect_UpdateWorlds)

    local serverSelectFragment = ZO_FadeSceneFragment:New(ZO_ServerSelect)
    local serverSelectScene = ZO_Scene:New("serverSelect", SCENE_MANAGER)
    serverSelectScene:AddFragment(serverSelectFragment)
    serverSelectScene:AddFragment(PREGAME_SLIDE_SHOW_FRAGMENT)
end
