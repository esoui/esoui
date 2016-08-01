ZO_HousingFurnitureBrowser_Gamepad = ZO_Object.MultiSubclass(ZO_HousingFurnitureBrowser_Base, ZO_Gamepad_ParametricList_Screen)

function ZO_HousingFurnitureBrowser_Gamepad:New(...)
    return ZO_Gamepad_ParametricList_Screen.New(self, ...)
end

function ZO_HousingFurnitureBrowser_Gamepad:Initialize(control)
    GAMEPAD_HOUSING_FURNITURE_BROWSER_SCENE = ZO_Scene:New("gamepad_housing_furniture_scene", SCENE_MANAGER)
    ZO_HousingFurnitureBrowser_Base.Initialize(self, control)
    local ACTIVATE_ON_SHOW = true
    ZO_Gamepad_ParametricList_Screen.Initialize(self, control, ZO_GAMEPAD_HEADER_TABBAR_DONT_CREATE, ACTIVATE_ON_SHOW, GAMEPAD_HOUSING_FURNITURE_BROWSER_SCENE)
    SYSTEMS:RegisterGamepadRootScene("housing_furniture_browser", GAMEPAD_HOUSING_FURNITURE_BROWSER_SCENE)

    local function RefreshMainList()
        if SCENE_MANAGER:IsShowing("gamepad_housing_furniture_scene") then
            self:RefreshMainList()
        else
            self.mainListIsDirty = true
        end
    end
    SHARED_INVENTORY:RegisterCallback("FullInventoryUpdate", RefreshMainList)
    SHARED_INVENTORY:RegisterCallback("SingleSlotInventoryUpdate", RefreshMainList)
end

function ZO_HousingFurnitureBrowser_Gamepad:InitializeKeybindStripDescriptors()
    self.keybindStripDescriptor =
    {
        -- Primary
        {
            name =  "[debug] Select",
            keybind = "UI_SHORTCUT_PRIMARY",        
            callback =  function() 
                            --We've already selected the piece OnTargetChanged, just hide scene
                            SCENE_MANAGER:HideCurrentScene()
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

function ZO_HousingFurnitureBrowser_Gamepad:OnShowing()
    if self.mainListIsDirty then
        self:RefreshMainList()
    else
        --since we didn't rebuild the list fire the changed function on whatever's currently selected
        self:OnTargetChanged(self:GetMainList(), self:GetMainList():GetTargetData())
    end
end

function ZO_HousingFurnitureBrowser_Gamepad:OnHiding()
    if HousingEditorHasPendingFixture() then
        HousingEditorRequestModeChange(HOUSING_EDITOR_MODE_PLACEMENT)
    else
        HousingEditorRequestModeChange(HOUSING_EDITOR_MODE_SELECTION)
    end
end

function ZO_HousingFurnitureBrowser_Gamepad:RefreshMainList()
    local list = self:GetMainList()
    list:Clear()

    local isFirst = true
    local itemFurnitureCache = SHARED_FURNITURE:GetFurnitureCache(ZO_PLACEABLE_TYPE_ITEM)
    for bag, bagEntries in pairs(itemFurnitureCache) do
        for _, slotData in pairs(bagEntries) do --pairs because slotIndex can be zero
            local data = ZO_GamepadEntryData:New(slotData.name)
            data.bagId = slotData.bagId
            data.slotIndex = slotData.slotIndex
            data.type = slotData.type

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
    local testFurnitureCache = SHARED_FURNITURE:GetFurnitureCache(ZO_PLACEABLE_TYPE_TEST)
    for i, testInfo in ipairs(testFurnitureCache) do
        local data = ZO_GamepadEntryData:New(testInfo.name)
        data.index = testInfo.index
        data.type = testInfo.type
        if isFirst then
            data:SetHeader("Test Fixtures, will not persist!")
            list:AddEntryWithHeader("ZO_GamepadMenuEntryTemplate", data)
            isFirst = false
        else
            list:AddEntry("ZO_GamepadMenuEntryTemplate", data)
        end
    end

    list:Commit()
    self.mainListIsDirty = false
end

function ZO_HousingFurnitureBrowser_Gamepad:OnTargetChanged(list, targetData, oldTargetData)
    if targetData.type == ZO_PLACEABLE_TYPE_ITEM then
        HousingEditorPreviewItemFurniture(targetData.bagId, targetData.slotIndex)
    elseif targetData.type == ZO_PLACEABLE_TYPE_TEST then
        DebugHousingEditorPreviewTestFurniture(targetData.index)
    end   
end

function ZO_HousingFurnitureBrowser_Gamepad_OnInitialize(control)
    local gamepadBrowser = ZO_HousingFurnitureBrowser_Gamepad:New(control)
    SYSTEMS:RegisterGamepadObject("housing_furniture_browser", gamepadBrowser)
end