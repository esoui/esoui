--Layout consts
ZO_MAP_HOUSES_KEYBOARD_ROW_PADDING_X = 20

ZO_MapHouses_Keyboard = ZO_MapHouses_Shared:Subclass()

local HOUSE_HEADER = 1
local HOUSE_DATA = 2

function ZO_MapHouses_Keyboard:New(...)
    return ZO_MapHouses_Shared.New(self,...)
end

function ZO_MapHouses_Keyboard:Initialize(control)
    ZO_MapHouses_Shared.Initialize(self, control)
    self:SetNoHousesLabelControl(control:GetNamedChild("NoHouses"))
end

function ZO_MapHouses_Keyboard:InitializeList(control)
    self.list = control:GetNamedChild("List")

    local function SetupHeader(control, data)
        local headerLabel = control:GetNamedChild("Label")
        headerLabel:SetText(data.text)
    end

    function SetupHouse(control, data)
        local listEnabled = self:IsListEnabled()
        local houseNameLabel = control:GetNamedChild("Name")
        houseNameLabel:SetText(data.houseName)
        houseNameLabel:SetSelected(false)
        houseNameLabel:SetEnabled(listEnabled)
        houseNameLabel:SetMouseEnabled(listEnabled)

        local locationLabel = control:GetNamedChild("Location")
        locationLabel:SetText(data.foundInZoneName)
    end

    ZO_ScrollList_AddDataType(self.list, HOUSE_HEADER, "ZO_WorldMapHouseHeader", 32, SetupHeader)
    ZO_ScrollList_AddDataType(self.list, HOUSE_DATA, "ZO_WorldMapHouseRow", 60, SetupHouse)
end

function ZO_MapHouses_Keyboard:SetListEnabled(enabled)
    ZO_MapHouses_Shared.SetListEnabled(self, enabled)

    ZO_ScrollList_RefreshVisible(self.list)
end

function ZO_MapHouses_Keyboard:RefreshHouseList()
    ZO_MapHouses_Shared.RefreshHouseList(self)

    ZO_ScrollList_Clear(self.list)
    local scrollData = ZO_ScrollList_GetDataList(self.list)

    local houseList = WORLD_MAP_HOUSES_DATA:GetHouseList()

    local firstUnlocked = true
    local firstLocked = true
    for i, mapEntry in ipairs(houseList) do
        local headerText = nil
        if mapEntry.unlocked and firstUnlocked then
            headerText = GetString("SI_COLLECTIBLEUNLOCKSTATE", COLLECTIBLE_UNLOCK_STATE_UNLOCKED_OWNED)
            firstUnlocked = false
        elseif not mapEntry.unlocked and firstLocked then
            headerText = GetString("SI_COLLECTIBLEUNLOCKSTATE", COLLECTIBLE_UNLOCK_STATE_UNLOCKED_LOCKED)
            firstLocked = false
        end

        if headerText then
            local headerEntry = ZO_ScrollList_CreateDataEntry(HOUSE_HEADER, { text = headerText })
            table.insert(scrollData, headerEntry)
        end

        local dataEntry = ZO_ScrollList_CreateDataEntry(HOUSE_DATA, mapEntry)
        table.insert(scrollData, dataEntry)
    end

    ZO_ScrollList_Commit(self.list)
end

function ZO_MapHouses_Keyboard:SetupHouse(control, data)
    local listEnabled = self:IsListEnabled()
    local houseNameLabel = control:GetNamedChild("Name")
    houseNameLabel:SetText(data.houseName)
    houseNameLabel:SetSelected(false)
    houseNameLabel:SetEnabled(listEnabled)
    houseNameLabel:SetMouseEnabled(listEnabled)

    local locationLabel = control:GetNamedChild("Location")
    locationLabel:SetText(data.foundInZoneName)
end

--Global XML

function ZO_WorldMapHouseRow_OnMouseDown(label, button)
    if button == MOUSE_BUTTON_INDEX_LEFT then
        label:SetAnchor(TOPLEFT, nil, TOPLEFT, ZO_MAP_HOUSES_KEYBOARD_ROW_PADDING_X, 1)
    end
end

function ZO_WorldMapHouseRow_OnMouseUp(label, button, upInside)
    if button == MOUSE_BUTTON_INDEX_LEFT then
        label:SetAnchor(TOPLEFT, nil, TOPLEFT, ZO_MAP_HOUSES_KEYBOARD_ROW_PADDING_X, 0)
        if upInside then
            local data = ZO_ScrollList_GetData(label:GetParent())
            ZO_WorldMap_SetMapByIndex(data.mapIndex)
            ZO_WorldMap_PanToWayshrine(data.nodeIndex)
            PlaySound(SOUNDS.MAP_LOCATION_CLICKED)
        end
    end
end

function ZO_WorldMapHouses_OnInitialized(self)
    WORLD_MAP_HOUSES = ZO_MapHouses_Keyboard:New(self)
end