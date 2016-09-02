ZO_HousingFurnitureBrowser_Keyboard = ZO_HousingFurnitureBrowser_Base:Subclass()

function ZO_HousingFurnitureBrowser_Keyboard:New(...)
    local browser = ZO_Object.New(self)
    browser:Initialize(...)
    return browser
end

local PLACEABLE_HOUSING_DATA_TYPE = 1
local RECALLABLE_HOUSING_DATA_TYPE = 2

function ZO_HousingFurnitureBrowser_Keyboard:Initialize()
    ZO_HousingFurnitureBrowser_Base.Initialize(self)

    self.placeableList = ZO_HousingFurnitureBrowser_KeyboardPlaceableTopLevel:GetNamedChild("List")
    self.recallableList = ZO_HousingFurnitureBrowser_KeyboardRecallableTopLevel:GetNamedChild("List")

    KEYBOARD_HOUSING_FURNITURE_BROWSER_SCENE = ZO_Scene:New("keyboard_housing_furniture_scene", SCENE_MANAGER)    
    KEYBOARD_HOUSING_FURNITURE_BROWSER_SCENE:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWING then
            self:OnDeferredInitialization()
            self:OnShowing()
            self.menuBarFragment:SelectFragment(SI_FURNITURE_PLACE)     
        elseif newState == SCENE_HIDING then
            self.menuBarFragment:Clear()
            ZO_HousingFurnitureBrowser_Base.Hiding(self)
        end
    end)

    SYSTEMS:RegisterKeyboardRootScene("housing_furniture_browser", KEYBOARD_HOUSING_FURNITURE_BROWSER_SCENE)

    local function RefreshLists()
        if SCENE_MANAGER:IsShowing("keyboard_housing_furniture_scene") then
            self:RefreshLists()
        else
            self.listsAreDirty = true
        end
    end
    ZO_HousingFurnitureBrowser_Base.RegisterEvents(self, RefreshLists)
end

function ZO_HousingFurnitureBrowser_Keyboard:OnDeferredInitialization()
    if self.isInitialized then
        return
    end

    self:InitializeKeybindStripDescriptors()
    self:CreateListFragments()

    ZO_ScrollList_Initialize(self.placeableList)
    
    local function SetupPlaceableRow(rowControl, placeableObject)
        rowControl.name:SetText(placeableObject:GetName())
        rowControl.icon:SetTexture(placeableObject:GetIcon())
    end

    local ENTRY_HEIGHT = 52
    ZO_ScrollList_AddDataType(self.placeableList, PLACEABLE_HOUSING_DATA_TYPE, "ZO_PlayerFurnitureSlot", ENTRY_HEIGHT, SetupPlaceableRow)
    ZO_ScrollList_AddResizeOnScreenResize(self.placeableList)

    ZO_ScrollList_Initialize(self.recallableList)
    
    local function SetupRecallableRow(rowControl, data)
        rowControl.name:SetText(data.name)
        rowControl.icon:SetTexture(data.icon)
    end

    ZO_ScrollList_AddDataType(self.recallableList, RECALLABLE_HOUSING_DATA_TYPE, "ZO_PlayerFurnitureSlot", ENTRY_HEIGHT, SetupRecallableRow)
    ZO_ScrollList_AddResizeOnScreenResize(self.recallableList)

    self.isInitialized = true
end

function ZO_HousingFurnitureBrowser_Keyboard:InitializeKeybindStripDescriptors()
    self.placeKeybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_RIGHT,

        -- Primary
        {
            name =  "[debug] Select",
            keybind = "UI_SHORTCUT_PRIMARY", 
            callback =  function()
                            if HousingEditorIsPreviewing() then
                                SCENE_MANAGER:HideCurrentScene()
                            end
                        end,
        },
    }
end

function ZO_HousingFurnitureBrowser_Keyboard:CreateListFragments()

    HOUSING_FURNITURE_BROWSER_PLACEABLE_FRAGMENT = ZO_FadeSceneFragment:New(ZO_HousingFurnitureBrowser_KeyboardPlaceableTopLevel)
    HOUSING_FURNITURE_BROWSER_RECALLABLE_FRAGMENT = ZO_FadeSceneFragment:New(ZO_HousingFurnitureBrowser_KeyboardRecallableTopLevel)
    local function CreateButtonData(normal, pressed, highlight)
        return {
            normal = normal,
            pressed = pressed,
            highlight = highlight,
        }
    end

    local menuBarFragment = ZO_SceneFragmentBar:New(ZO_HousingFurnitureBrowserMenu_KeyboardTopLevelBar)

    --place Button
    local placeButtonData = CreateButtonData("EsoUI/Art/Housing/Keyboard/furniture_tabIcon_place_up.dds",
                                            "EsoUI/Art/Housing/Keyboard/furniture_tabIcon_place_down.dds", 
                                            "EsoUI/Art/Housing/Keyboard/furniture_tabIcon_place_over.dds")
    menuBarFragment:Add(SI_FURNITURE_PLACE, { HOUSING_FURNITURE_BROWSER_PLACEABLE_FRAGMENT }, placeButtonData, self.placeKeybindStripDescriptor)

    --recall Button
    local recallButtonData = CreateButtonData("EsoUI/Art/Housing/Keyboard/furniture_tabIcon_recall_up.dds",
                                               "EsoUI/Art/Housing/Keyboard/furniture_tabIcon_recall_down.dds",
                                               "EsoUI/Art/Housing/Keyboard/furniture_tabIcon_recall_over.dds")
    menuBarFragment:Add(SI_FURNITURE_RECALL, { HOUSING_FURNITURE_BROWSER_RECALLABLE_FRAGMENT }, recallButtonData)
    
    self.menuBarFragment = menuBarFragment
end

function ZO_HousingFurnitureBrowser_Keyboard:OnShowing()
    if self.listsAreDirty then
        self:RefreshLists()
    end
end

function ZO_HousingFurnitureBrowser_Keyboard:RefreshLists()
    --Placeable Tab
    local scrollData = ZO_ScrollList_GetDataList(self.placeableList)
    ZO_ScrollList_Clear(self.placeableList)

    local itemFurnitureCache = SHARED_FURNITURE:GetPlaceableFurnitureCache(ZO_PLACEABLE_TYPE_ITEM)
    for bag, bagEntries in pairs(itemFurnitureCache) do
        for _, placeableItem in pairs(bagEntries) do --pairs because slotIndex can be zero
            scrollData[#scrollData + 1] = ZO_ScrollList_CreateDataEntry(PLACEABLE_HOUSING_DATA_TYPE, placeableItem)
        end
    end

    local collectibleFurnitureCache = SHARED_FURNITURE:GetPlaceableFurnitureCache(ZO_PLACEABLE_TYPE_COLLECTIBLE)
    for id, collData in pairs(collectibleFurnitureCache) do
        scrollData[#scrollData + 1] = ZO_ScrollList_CreateDataEntry(PLACEABLE_HOUSING_DATA_TYPE, collData)
    end
    
    ZO_ScrollList_Commit(self.placeableList)

    --Recallable Tab
    scrollData = ZO_ScrollList_GetDataList(self.recallableList)
    ZO_ScrollList_Clear(self.recallableList)

    local furnitureCache = SHARED_FURNITURE:GetRecallableFurnitureCache()
    for _, placeableFurniture in pairs(furnitureCache) do --pairs because slotIndex can be zero
        scrollData[#scrollData + 1] = ZO_ScrollList_CreateDataEntry(RECALLABLE_HOUSING_DATA_TYPE, placeableFurniture)
    end

    ZO_ScrollList_Commit(self.recallableList)

    self.listsAreDirty = false
end

function ZO_HousingFurnitureBrowser_Keyboard_OnMouseClick(self)
    local data = ZO_ScrollList_GetData(self)
    if data.dataEntry.typeId == PLACEABLE_HOUSING_DATA_TYPE then
        ZO_HousingFurnitureBrowser_Base.PreviewFurniture(self, data)
    end
end

function ZO_HousingFurnitureBrowser_Keyboard_OnMouseDoubleClick(self)
    local data = ZO_ScrollList_GetData(self)
    if data.dataEntry.typeId == PLACEABLE_HOUSING_DATA_TYPE then
        ZO_HousingFurnitureBrowser_Keyboard_OnMouseClick(self)
        SCENE_MANAGER:HideCurrentScene()
    elseif data.dataEntry.typeId == RECALLABLE_HOUSING_DATA_TYPE then
        ZO_HousingFurnitureBrowser_Base.RemoveFurniture(self, data)
    end
end

function ZO_HousingFurnitureBrowser_Keyboard_OnInitialize()
    local keyboardBrowser = ZO_HousingFurnitureBrowser_Keyboard:New()
    SYSTEMS:RegisterKeyboardObject("housing_furniture_browser", keyboardBrowser)
end