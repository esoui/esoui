ZO_HousingFurnitureBrowser_Keyboard = ZO_HousingFurnitureBrowser_Base:Subclass()

function ZO_HousingFurnitureBrowser_Keyboard:New(...)
    local browser = ZO_Object.New(self)
    browser:Initialize(...)
    return browser
end

HOUSING_FURNITURE_KEYBOARD_SCENE_NAME = "keyboard_housing_furniture_scene"

function ZO_HousingFurnitureBrowser_Keyboard:Initialize(control)
    ZO_HousingFurnitureBrowser_Base.Initialize(self, control, HOUSING_FURNITURE_KEYBOARD_SCENE_NAME)
    self.modeBar = control:GetNamedChild("Bar")

    local function OnListMostRecentlySelectedDataChanged(data)
        -- selecting the list data will preview the furniture, so we will need to show/hide the house info as appropriate
        if data then
            SCENE_MANAGER:RemoveFragmentGroup(self.houseInfoFragmentGroup)
        else
            SCENE_MANAGER:AddFragmentGroup(self.houseInfoFragmentGroup)
        end
    end

    self.placeablePanel = ZO_HousingFurniturePlacement_Keyboard:New(ZO_HousingFurniturePlacementPanel_KeyboardTopLevel, self)
    self.productsPanel = ZO_HousingFurnitureProducts_Keyboard:New(ZO_HousingFurnitureProductsPanel_KeyboardTopLevel, self)
    self.retrievalPanel = ZO_HousingFurnitureRetrieval_Keyboard:New(ZO_HousingFurnitureRetrievalPanel_KeyboardTopLevel, self)
    self.settingsPanel = ZO_HousingFurnitureSettings_Keyboard:New(ZO_HousingFurnitureSettingsPanel_KeyboardTopLevel, self)

    self.placeablePanel:RegisterCallback("OnMostRecentlySelectedDataChanged", OnListMostRecentlySelectedDataChanged)
    self.productsPanel:RegisterCallback("OnMostRecentlySelectedDataChanged", OnListMostRecentlySelectedDataChanged)
    self.retrievalPanel:RegisterCallback("OnMostRecentlySelectedDataChanged", OnListMostRecentlySelectedDataChanged)

    KEYBOARD_HOUSING_FURNITURE_BROWSER_SCENE = ZO_Scene:New(HOUSING_FURNITURE_KEYBOARD_SCENE_NAME, SCENE_MANAGER)
    KEYBOARD_HOUSING_FURNITURE_BROWSER_SCENE:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWING then
            self:OnDeferredInitialization()
            self:OnShowing()
        elseif newState == SCENE_HIDING then
            self:OnHiding()
        elseif newState == SCENE_HIDDEN then
            self.menuBarFragment:Clear()
        end
    end)

    SYSTEMS:RegisterKeyboardRootScene("housing_furniture_browser", KEYBOARD_HOUSING_FURNITURE_BROWSER_SCENE)
    self.scene = KEYBOARD_HOUSING_FURNITURE_BROWSER_SCENE
end

function ZO_HousingFurnitureBrowser_Keyboard:OnDeferredInitialization()
    if self.isInitialized then
        return
    end

    self:CreateMenuBarTabs()
    self.menuBarFragment:SetStartingFragment(SI_HOUSING_FURNITURE_TAB_PLACE)

    self.houseInfoFragmentGroup = 
    {
        HOUSE_INFORMATION_FRAGMENT,
        MEDIUM_LEFT_PANEL_BG_FRAGMENT,
    }

    self.isInitialized = true
end

function ZO_HousingFurnitureBrowser_Keyboard:OnShowing()
    ZO_HousingFurnitureBrowser_Base.OnShowing(self)

    self.settingsPanel:UpdateLists()
    self.menuBarFragment:ShowLastFragment()

    SCENE_MANAGER:AddFragmentGroup(self.houseInfoFragmentGroup)
end

--Overridden
function ZO_HousingFurnitureBrowser_Keyboard:UpdatePlaceablePanel()
    self.placeablePanel:UpdateLists()
end

--Overridden
function ZO_HousingFurnitureBrowser_Keyboard:UpdateRetrievablePanel()
    self.retrievalPanel:UpdateLists()
end

--Overridden
function ZO_HousingFurnitureBrowser_Keyboard:UpdateRetrievablePanelDistancesAndHeadings()
    self.retrievalPanel:UpdateContentsSort()
end

--Overridden
function ZO_HousingFurnitureBrowser_Keyboard:UpdateRetrievablePanelHeadings()
    self.retrievalPanel:UpdateContentsVisible()
end

--Overridden
function ZO_HousingFurnitureBrowser_Keyboard:UpdateProductsPanel()
    self.productsPanel:UpdateLists()
end

function ZO_HousingFurnitureBrowser_Keyboard.OnHideFurnitureRow(control, data)
    local INSTANT = true
    ZO_HousingFurnitureTemplates_Keyboard_SetListHighlightHidden(control, true, INSTANT)
end

function ZO_HousingFurnitureBrowser_Keyboard.SetupFurnitureRow(rowControl, furnitureObject, OnMouseClickCallback, OnMouseDoubleClickCallback)
    rowControl.name:SetText(furnitureObject:GetFormattedName())
    local quality = furnitureObject:GetQuality()
    local r, g, b = GetInterfaceColor(INTERFACE_COLOR_TYPE_ITEM_QUALITY_COLORS, quality)
    rowControl.name:SetColor(r, g, b, 1)

    rowControl.icon:SetTexture(furnitureObject:GetIcon())

    local stackCountLabel = rowControl.stackCount
    local stackCount = furnitureObject:GetStackCount()
    local hasStack = stackCount > 1
    if hasStack then
        stackCountLabel:SetText(furnitureObject:GetFormattedStackCount())
    end

    stackCountLabel:SetHidden(not hasStack)

    local statusControl = rowControl.statusIcon

    statusControl:ClearIcons()


    if furnitureObject:IsStolen() then
        statusControl:AddIcon("EsoUI/Art/Inventory/inventory_stolenItem_icon.dds")
    end
    if furnitureObject:IsGemmable() then
        statusControl:AddIcon(ZO_Currency_GetPlatformCurrencyIcon(UI_ONLY_CURRENCY_CROWN_GEMS))
    end
    if furnitureObject:IsFromCrownStore() then
        statusControl:AddIcon(ZO_Currency_GetPlatformCurrencyIcon(UI_ONLY_CURRENCY_CROWNS))
    end

    statusControl:Show()

    rowControl.OnMouseClickCallback = OnMouseClickCallback
    rowControl.OnMouseDoubleClickCallback = OnMouseDoubleClickCallback
    rowControl.furnitureObject = furnitureObject
end

function ZO_HousingFurnitureBrowser_Keyboard:CreateMenuBarTabs()
    local function CreateButtonData(normal, pressed, highlight, mode)
        return {
            normal = normal,
            pressed = pressed,
            highlight = highlight,
            mode = mode,
            callback = function() self:SetMode(mode) end
        }
    end

    local menuBarFragment = ZO_SceneFragmentBar:New(self.modeBar)

    --Placement Button
    local placeButtonData = CreateButtonData("EsoUI/Art/Housing/Keyboard/furniture_tabIcon_place_up.dds",
                                            "EsoUI/Art/Housing/Keyboard/furniture_tabIcon_place_down.dds", 
                                            "EsoUI/Art/Housing/Keyboard/furniture_tabIcon_place_over.dds",
                                            HOUSING_BROWSER_MODE.PLACEMENT)
    menuBarFragment:Add(SI_HOUSING_FURNITURE_TAB_PLACE, { self.placeablePanel:GetFragment() }, placeButtonData)

    --Products Button
    local productsButtonData = CreateButtonData("EsoUI/Art/Housing/Keyboard/furniture_tabIcon_crownFurnishings_up.dds",
                                            "EsoUI/Art/Housing/Keyboard/furniture_tabIcon_crownFurnishings_down.dds", 
                                            "EsoUI/Art/Housing/Keyboard/furniture_tabIcon_crownFurnishings_over.dds",
                                            HOUSING_BROWSER_MODE.PRODUCTS)
    menuBarFragment:Add(SI_HOUSING_FURNITURE_TAB_PURCHASE, { self.productsPanel:GetFragment(), MARKET_CURRENCY_KEYBOARD_FRAGMENT }, productsButtonData)

    --Retrieval Button
    local retrievalButtonData = CreateButtonData("EsoUI/Art/Housing/Keyboard/furniture_tabIcon_recall_up.dds",
                                               "EsoUI/Art/Housing/Keyboard/furniture_tabIcon_recall_down.dds",
                                               "EsoUI/Art/Housing/Keyboard/furniture_tabIcon_recall_over.dds",
                                               HOUSING_BROWSER_MODE.RETRIEVAL)
    menuBarFragment:Add(SI_HOUSING_FURNITURE_TAB_RETRIEVAL, { self.retrievalPanel:GetFragment() }, retrievalButtonData)

    --Settings Button
    local settingsButtonData = CreateButtonData("EsoUI/Art/Housing/Keyboard/furniture_tabIcon_settings_up.dds",
                                               "EsoUI/Art/Housing/Keyboard/furniture_tabIcon_settings_down.dds",
                                               "EsoUI/Art/Housing/Keyboard/furniture_tabIcon_settings_over.dds",
                                               HOUSING_BROWSER_MODE.SETTINGS)
    menuBarFragment:Add(SI_HOUSING_FURNITURE_TAB_SETTINGS, { self.settingsPanel:GetFragment() }, settingsButtonData)
    
    self.menuBarFragment = menuBarFragment
end

--
--[[ XML Functions ]] --
--

function ZO_HousingFurnitureBrowser_Keyboard_OnInitialize(control)
    KEYBOARD_HOUSING_FURNITURE_BROWSER = ZO_HousingFurnitureBrowser_Keyboard:New(control)
    SYSTEMS:RegisterKeyboardObject("housing_furniture_browser", keyboardBrowser)
end