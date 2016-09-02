ZO_HousingFurnitureBrowser_Gamepad = ZO_Object.MultiSubclass(ZO_HousingFurnitureBrowser_Base, ZO_Gamepad_ParametricList_Screen)

function ZO_HousingFurnitureBrowser_Gamepad:New(...)
    return ZO_Gamepad_ParametricList_Screen.New(self, ...)
end

local PLACEABLE_TAB_INDEX = 1
local RECALLABLE_TAB_INDEX = 2

function ZO_HousingFurnitureBrowser_Gamepad:Initialize(control)
    GAMEPAD_HOUSING_FURNITURE_BROWSER_SCENE = ZO_Scene:New("gamepad_housing_furniture_scene", SCENE_MANAGER)
    ZO_HousingFurnitureBrowser_Base.Initialize(self, control)
    local ACTIVATE_ON_SHOW = true
    ZO_Gamepad_ParametricList_Screen.Initialize(self, control, ZO_GAMEPAD_HEADER_TABBAR_CREATE, ACTIVATE_ON_SHOW, GAMEPAD_HOUSING_FURNITURE_BROWSER_SCENE)
    SYSTEMS:RegisterGamepadRootScene("housing_furniture_browser", GAMEPAD_HOUSING_FURNITURE_BROWSER_SCENE)

    self:SetListsUseTriggerKeybinds(true)

    local function RefreshLists()
        self:Update()
    end
    ZO_HousingFurnitureBrowser_Base.RegisterEvents(self, RefreshLists)

    self:InitializeHeader()

    self.placeableList = self:GetMainList()
    self.recallableList = self:AddList("RecallableList")
end

function ZO_HousingFurnitureBrowser_Gamepad:InitializeKeybindStripDescriptors()
    self.keybindStripDescriptor =
    {
        -- Primary
        {
            name =  "[debug] Select",
            keybind = "UI_SHORTCUT_PRIMARY",        
            callback =  function() 
                            if self.activeTabIndex == RECALLABLE_TAB_INDEX then
                                local targetData = self.recallableList:GetTargetData()
                                if targetData then
                                    ZO_HousingFurnitureBrowser_Base.RemoveFurniture(self, targetData)
                                end
                            else
                                --We've already selected the piece OnTargetChanged, just hide scene
                                SCENE_MANAGER:HideCurrentScene()
                            end
                        end,
            alignment = KEYBIND_STRIP_ALIGN_LEFT,
        },
    }

    local function BackFunction()
        HousingEditorRequestModeChange(HOUSING_EDITOR_MODE_SELECTION)
        SCENE_MANAGER:HideCurrentScene()
    end

    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.keybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON, BackFunction)
end

function ZO_HousingFurnitureBrowser_Gamepad:InitializeHeader()
    local tabBarEntries =
    {
        {
            text = GetString(SI_FURNITURE_PLACE),
            callback = function()
                self.activeTabIndex = PLACEABLE_TAB_INDEX
                self:SetCurrentList(self.placeableList)
                self:OnTargetChanged(self.placeableList, self.placeableList:GetTargetData())
            end,
        },
        {
            text = GetString(SI_FURNITURE_RECALL),
            callback = function()
                self.activeTabIndex = RECALLABLE_TAB_INDEX
                HousingEditorEndCurrentPreview()
                self:SetCurrentList(self.recallableList)
            end,
        },
    }

    self.headerData = 
    {
        tabBarEntries = tabBarEntries,
    }

    ZO_GamepadGenericHeader_Initialize(self.header, ZO_GAMEPAD_HEADER_TABBAR_CREATE)
end

function ZO_HousingFurnitureBrowser_Gamepad:OnShowing()
    ZO_Gamepad_ParametricList_Screen.OnShowing(self)
    ZO_GamepadGenericHeader_Refresh(self.header, self.headerData)
    ZO_GamepadGenericHeader_Activate(self.header)

end

function ZO_HousingFurnitureBrowser_Gamepad:OnHiding()
    ZO_HousingFurnitureBrowser_Base.Hiding(self)
    ZO_GamepadGenericHeader_Deactivate(self.header)
end

function ZO_HousingFurnitureBrowser_Gamepad:PerformUpdate()
    --Placeable Tab
    local list = self.placeableList
    list:Clear()

    local isFirst = true
    local itemFurnitureCache = SHARED_FURNITURE:GetPlaceableFurnitureCache(ZO_PLACEABLE_TYPE_ITEM)
    for bag, bagEntries in pairs(itemFurnitureCache) do
        for _, placeableItem in pairs(bagEntries) do --pairs because slotIndex can be zero
            local data = ZO_GamepadEntryData:New(placeableItem:GetName(), placeableItem:GetIcon())
            data.placeableObject = placeableItem

            if isFirst then
                data:SetHeader("[test] Items")
                list:AddEntryWithHeader("ZO_GamepadMenuEntryTemplate", data)
                isFirst = false
            else
                list:AddEntry("ZO_GamepadMenuEntryTemplate", data)
            end
        end
    end

    isFirst = true
    local collectibleFurnitureCache = SHARED_FURNITURE:GetPlaceableFurnitureCache(ZO_PLACEABLE_TYPE_COLLECTIBLE)
    for id, placeableCollectible in pairs(collectibleFurnitureCache) do
        local data = ZO_GamepadEntryData:New(placeableCollectible:GetName(), placeableCollectible:GetIcon())
        data.placeableObject = placeableCollectible

        if isFirst then
            data:SetHeader("[test] Collectibles")
            list:AddEntryWithHeader("ZO_GamepadMenuEntryTemplate", data)
            isFirst = false
        else
            list:AddEntry("ZO_GamepadMenuEntryTemplate", data)
        end
    end
    list:Commit()
    
    --Recallable Tab
    local list = self.recallableList
    list:Clear()

    isFirst = true
    local furnitureCache = SHARED_FURNITURE:GetRecallableFurnitureCache()
    for _, slotData in pairs(furnitureCache) do
        local data = ZO_GamepadEntryData:New(slotData.name, slotData.icon)
        data.furnitureId = slotData.furnitureId

        if isFirst then
            data:SetHeader("[test] Furniture")
            list:AddEntryWithHeader("ZO_GamepadMenuEntryTemplate", data)
            isFirst = false
        else
            list:AddEntry("ZO_GamepadMenuEntryTemplate", data)
        end
    end

    list:Commit()

    self.dirty = false
end

function ZO_HousingFurnitureBrowser_Gamepad:OnTargetChanged(list, targetData, oldTargetData)
    if list == self.placeableList and self.activeTabIndex == PLACEABLE_TAB_INDEX and targetData then
        ZO_HousingFurnitureBrowser_Base.PreviewFurniture(self, targetData.placeableObject)
    end   
end

function ZO_HousingFurnitureBrowser_Gamepad_OnInitialize(control)
    local gamepadBrowser = ZO_HousingFurnitureBrowser_Gamepad:New(control)
    SYSTEMS:RegisterGamepadObject("housing_furniture_browser", gamepadBrowser)
end