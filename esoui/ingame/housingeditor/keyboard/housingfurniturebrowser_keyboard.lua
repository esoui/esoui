ZO_HousingFurnitureBrowser_Keyboard = ZO_HousingFurnitureBrowser_Base:Subclass()

function ZO_HousingFurnitureBrowser_Keyboard:New(...)
    local browser = ZO_Object.New(self)
    browser:Initialize(...)
    return browser
end

local DEBUG_HOUSING_DATA_TYPE = 1

function ZO_HousingFurnitureBrowser_Keyboard:Initialize(control)
    ZO_HousingFurnitureBrowser_Base.Initialize(self, control)
    self.list = control:GetNamedChild("List")

    KEYBOARD_HOUSING_FURNITURE_BROWSER_SCENE = ZO_Scene:New("keyboard_housing_furniture_scene", SCENE_MANAGER)    
    KEYBOARD_HOUSING_FURNITURE_BROWSER_SCENE:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWING then
            self:OnDeferredInitialization() 
            self:OnShowing()        
            KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
        elseif newState == SCENE_FRAGMENT_HIDDEN then
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
            --in case you close this menu by running since you can do that with a keyboard!
            if HousingEditorHasPendingFixture() then
                HousingEditorRequestModeChange(HOUSING_EDITOR_MODE_PLACEMENT)
            else
                HousingEditorRequestModeChange(HOUSING_EDITOR_MODE_SELECTION)
            end
        end
    end)

    SYSTEMS:RegisterKeyboardRootScene("housing_furniture_browser", KEYBOARD_HOUSING_FURNITURE_BROWSER_SCENE)

    local function RefreshMainList()
        if SCENE_MANAGER:IsShowing("keyboard_housing_furniture_scene") then
            self:RefreshMainList()
        else
            self.mainListIsDirty = true
        end
    end

    SHARED_INVENTORY:RegisterCallback("FullInventoryUpdate", RefreshMainList)
    SHARED_INVENTORY:RegisterCallback("SingleSlotInventoryUpdate", RefreshMainList)
end

function ZO_HousingFurnitureBrowser_Keyboard:OnDeferredInitialization()
    if self.isInitialized then
        return
    end

    self:InitializeKeybindStripDescriptors()

    ZO_ScrollList_Initialize(self.list)
    
    local function SetupRow(rowControl, data)
        rowControl:GetNamedChild("Name"):SetText(data.name)
    end

    local ENTRY_HEIGHT = 52
    ZO_ScrollList_AddDataType(self.list, DEBUG_HOUSING_DATA_TYPE, "ZO_PlayerFurnitureSlot", ENTRY_HEIGHT, SetupRow)
    ZO_ScrollList_AddResizeOnScreenResize(self.list)

    self.isInitialized = true
end

function ZO_HousingFurnitureBrowser_Keyboard:InitializeKeybindStripDescriptors()
    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_RIGHT,

        -- Primary
        {
            name =  "[debug] Select",
            keybind = "UI_SHORTCUT_PRIMARY", 
            callback =  function()
                            if HousingEditorHasPendingFixture() then
                                SCENE_MANAGER:HideCurrentScene()
                            end
                        end,
        },
    }
end

function ZO_HousingFurnitureBrowser_Keyboard:OnShowing()
    if self.mainListIsDirty then
        self:RefreshMainList()
    end
end

function ZO_HousingFurnitureBrowser_Keyboard:RefreshMainList()
    local scrollData = ZO_ScrollList_GetDataList(self.list)
    ZO_ScrollList_Clear(self.list)

    local itemFurnitureCache = SHARED_FURNITURE:GetFurnitureCache(ZO_PLACEABLE_TYPE_ITEM)
    for bag, bagEntries in pairs(itemFurnitureCache) do
        for _, slotData in pairs(bagEntries) do --pairs because slotIndex can be zero
            scrollData[#scrollData + 1] = ZO_ScrollList_CreateDataEntry(DEBUG_HOUSING_DATA_TYPE, slotData)
        end
    end

    local testFurnitureCache = SHARED_FURNITURE:GetFurnitureCache(ZO_PLACEABLE_TYPE_TEST)
    for i, furnitureInfo in ipairs(testFurnitureCache) do
        scrollData[#scrollData + 1] = ZO_ScrollList_CreateDataEntry(DEBUG_HOUSING_DATA_TYPE, furnitureInfo)
    end
    
    ZO_ScrollList_Commit(self.list)
    self.mainListIsDirty = false
end

function ZO_HousingFurnitureBrowser_Keyboard_OnMouseClick(self)
    local data = ZO_ScrollList_GetData(self)
    if data.type == ZO_PLACEABLE_TYPE_ITEM then
        HousingEditorPreviewItemFurniture(data.bagId, data.slotIndex)
    elseif data.type == ZO_PLACEABLE_TYPE_TEST then
        DebugHousingEditorPreviewTestFurniture(data.index)
    end  
end

function ZO_HousingFurnitureBrowser_Keyboard_OnMouseDoubleClick(self)
    ZO_HousingFurnitureBrowser_Keyboard_OnMouseClick(self)
    HousingEditorRequestModeChange(HOUSING_EDITOR_MODE_PLACEMENT)
    SCENE_MANAGER:HideCurrentScene()
end

function ZO_HousingFurnitureBrowser_Keyboard_OnInitialize(control)
    local keyboardBrowser = ZO_HousingFurnitureBrowser_Keyboard:New(control)
    SYSTEMS:RegisterKeyboardObject("housing_furniture_browser", keyboardBrowser)
end