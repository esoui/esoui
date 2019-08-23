ZO_SmithingCreation = ZO_SharedSmithingCreation:Subclass()

function ZO_SmithingCreation:New(...)
    return ZO_SharedSmithingCreation.New(self, ...)
end

function ZO_SmithingCreation:Initialize(control, owner)
    ZO_SharedSmithingCreation.Initialize(self, control, owner)

    local function OnAddOnLoaded(event, name)
        if name == "ZO_Ingame" then
            self:SetupSavedVars()
            self.control:UnregisterForEvent(EVENT_ADD_ON_LOADED)
        end
    end

    self.control:RegisterForEvent(EVENT_ADD_ON_LOADED, OnAddOnLoaded)

    ZO_InventoryInfoBar_ConnectStandardBar(control:GetNamedChild("InfoBar"))

    self:InitializeFilters()

    local scrollListControl = ZO_HorizontalScrollList
    local traitUnknownFont = "ZoFontWinH4"
    local notEnoughInInventoryFont = "ZoFontHeader4"
    local listSlotTemplate = "ZO_SmithingListSlot"

    self:InitializeTraitList(scrollListControl, traitUnknownFont, notEnoughInInventoryFont, listSlotTemplate)
    self:InitializeStyleList(scrollListControl, traitUnknownFont, notEnoughInInventoryFont, listSlotTemplate)
    self:InitializePatternList(scrollListControl, listSlotTemplate)

    local CHAMPION_POINT_RANGE_DOES_NOT_INHERIT_COLOR = false
    local COLOR_MATERIAL_NAME_WHITE = true
    self:InitializeMaterialList(scrollListControl, ZO_Spinner, listSlotTemplate, CHAMPION_POINT_RANGE_DOES_NOT_INHERIT_COLOR, COLOR_MATERIAL_NAME_WHITE)

    self:InitializeFilterTypeBar()

    self.resultTooltip = control:GetNamedChild("ResultTooltip")
    if IsChatSystemAvailableForCurrentPlatform() then
        local function OnTooltipMouseUp(control, button, upInside)
            if upInside and button == MOUSE_BUTTON_INDEX_RIGHT then
                local link = ZO_LinkHandler_CreateChatLink(GetSmithingPatternResultLink, self:GetSelectedPatternIndex(), self:GetSelectedMaterialIndex(),
                    self:GetSelectedMaterialQuantity(), self:GetSelectedItemStyleId(), self:GetSelectedTraitIndex())
                if link ~= "" then
                    ClearMenu()

                    local function AddLink()
                        ZO_LinkHandler_InsertLink(zo_strformat(SI_TOOLTIP_ITEM_NAME, link))
                    end

                    AddMenuItem(GetString(SI_ITEM_ACTION_LINK_TO_CHAT), AddLink)

                    ShowMenu(self)
                end
            end
        end

        self.resultTooltip:SetHandler("OnMouseUp", OnTooltipMouseUp)
        self.resultTooltip:GetNamedChild("Icon"):SetHandler("OnMouseUp", OnTooltipMouseUp)
    end

    self.multiCraftSpinner = ZO_MultiCraftSpinner:New(control:GetNamedChild("MultiCraftContainerSpinner"))
    ZO_CraftingUtils_ConnectSpinnerToCraftingProcess(self.multiCraftSpinner)
end

function ZO_SmithingCreation:SetHidden(hidden)
    self.control:SetHidden(hidden)
    if not hidden then
        CRAFTING_RESULTS:SetCraftingTooltip(self.resultTooltip)
        CRAFTING_RESULTS:SetTooltipAnimationSounds(self:GetCreateTooltipSound())
        self:TriggerUSITutorial()
    end
    self.refreshGroup:TryClean()
end

function ZO_SmithingCreation:ChangeTypeFilter(filterData)
    ZO_SharedSmithingCreation.ChangeTypeFilter(self, filterData)
    self:ResetMultiCraftNumIterations()
end

function ZO_SmithingCreation:InitializeFilterTypeBar()
    local MENU_BAR_DATA =
    {
        initialButtonAnchorPoint = RIGHT,
        buttonTemplate = "ZO_CraftingInventoryTab",
        normalSize = 51,
        downSize = 64,
        buttonPadding = -15,
        animationDuration = 180,
    }

    self.tabs = self.control:GetNamedChild("Tabs")
    self.activeTab = self.control:GetNamedChild("TabsActive")

    ZO_MenuBar_SetData(self.tabs, MENU_BAR_DATA)

    local function CreateNewTabFilterData(filterType, name, normal, pressed, highlight, disabled, visible)
        return {
            tooltipText = name,

            descriptor = filterType,
            normal = normal,
            pressed = pressed,
            highlight = highlight,
            disabled = disabled,
            visible = visible,
            callback = function(filterData)
                self.activeTab:SetText(name)
                self:ChangeTypeFilter(filterData)
            end,
        }
    end

    local function CanCraftWeapons()
        return CanSmithingWeaponPatternsBeCraftedHere()
    end

    local function CanCraftArmor()
        return CanSmithingApparelPatternsBeCraftedHere()
    end

    local function CanCraftJewelry()
        return CanSmithingJewelryPatternsBeCraftedHere()
    end

    local function CanCraftSetWeapons()
        return CanCraftWeapons() and CanSmithingSetPatternsBeCraftedHere()
    end

    local function CanCraftSetArmor()
        return CanCraftArmor() and CanSmithingSetPatternsBeCraftedHere()
    end

    local function CanCraftSetJewelry()
        return CanCraftJewelry() and CanSmithingSetPatternsBeCraftedHere()
    end
    ZO_MenuBar_AddButton(self.tabs, CreateNewTabFilterData(SMITHING_FILTER_TYPE_JEWELRY, GetString("SI_SMITHINGFILTERTYPE", SMITHING_FILTER_TYPE_JEWELRY), "EsoUI/Art/Crafting/jewelry_tabIcon_icon_up.dds", "EsoUI/Art/Crafting/jewelry_tabIcon_down.dds", "EsoUI/Art/Crafting/jewelry_tabIcon_icon_over.dds", "EsoUI/Art/Inventory/inventory_tabIcon_jewelry_disabled.dds", CanCraftJewelry))
    ZO_MenuBar_AddButton(self.tabs, CreateNewTabFilterData(SMITHING_FILTER_TYPE_ARMOR, GetString("SI_SMITHINGFILTERTYPE", SMITHING_FILTER_TYPE_ARMOR), "EsoUI/Art/Inventory/inventory_tabIcon_armor_up.dds", "EsoUI/Art/Inventory/inventory_tabIcon_armor_down.dds", "EsoUI/Art/Inventory/inventory_tabIcon_armor_over.dds", "EsoUI/Art/Inventory/inventory_tabIcon_armor_disabled.dds", CanCraftArmor))
    ZO_MenuBar_AddButton(self.tabs, CreateNewTabFilterData(SMITHING_FILTER_TYPE_WEAPONS, GetString("SI_SMITHINGFILTERTYPE", SMITHING_FILTER_TYPE_WEAPONS), "EsoUI/Art/Inventory/inventory_tabIcon_weapons_up.dds", "EsoUI/Art/Inventory/inventory_tabIcon_weapons_down.dds", "EsoUI/Art/Inventory/inventory_tabIcon_weapons_over.dds", "EsoUI/Art/Inventory/inventory_tabIcon_weapons_disabled.dds", CanCraftWeapons))
    ZO_MenuBar_AddButton(self.tabs, CreateNewTabFilterData(SMITHING_FILTER_TYPE_SET_JEWELRY, GetString("SI_SMITHINGFILTERTYPE", SMITHING_FILTER_TYPE_SET_JEWELRY), "EsoUI/Art/Crafting/jewelrySet_tabIcon_icon_up.dds", "EsoUI/Art/Crafting/jewelrySet_tabIcon_down.dds", "EsoUI/Art/Crafting/jewelrySet_tabIcon_icon_over.dds", "EsoUI/Art/Crafting/jewelrySet_tabIcon_icon_disabled.dds", CanCraftSetJewelry))
    ZO_MenuBar_AddButton(self.tabs, CreateNewTabFilterData(SMITHING_FILTER_TYPE_SET_ARMOR, GetString("SI_SMITHINGFILTERTYPE", SMITHING_FILTER_TYPE_SET_ARMOR), "EsoUI/Art/Crafting/smithing_tabIcon_armorSet_up.dds", "EsoUI/Art/Crafting/smithing_tabIcon_armorSet_down.dds", "EsoUI/Art/Crafting/smithing_tabIcon_armorSet_over.dds", "EsoUI/Art/Crafting/smithing_tabIcon_armorSet_disabled.dds", CanCraftSetArmor))
    ZO_MenuBar_AddButton(self.tabs, CreateNewTabFilterData(SMITHING_FILTER_TYPE_SET_WEAPONS, GetString("SI_SMITHINGFILTERTYPE", SMITHING_FILTER_TYPE_SET_WEAPONS), "EsoUI/Art/Crafting/smithing_tabIcon_weaponSet_up.dds", "EsoUI/Art/Crafting/smithing_tabIcon_weaponSet_down.dds", "EsoUI/Art/Crafting/smithing_tabIcon_weaponSet_over.dds", "EsoUI/Art/Crafting/smithing_tabIcon_weaponSet_disabled.dds", CanCraftSetWeapons))

    ZO_CraftingUtils_ConnectMenuBarToCraftingProcess(self.tabs)
end

function ZO_SmithingCreation:UpdateUniversalStyleItemCheckBox()
    local checkBox = self.useUniversalStyleItemCheckBox
    local universalStyleItemCount = GetCurrentSmithingStyleItemCount(GetUniversalStyleId())
    ZO_CheckButton_SetLabelText(checkBox, zo_strformat(SI_CRAFTING_USE_UNIVERSAL_STYLE_ITEM, universalStyleItemCount))
end

function ZO_SmithingCreation:InitializeFilters()
    self.haveMaterialsCheckBox = self.control:GetNamedChild("HaveMaterials")
    self.haveKnowledgeCheckBox = self.control:GetNamedChild("HaveKnowledge")
    self.useUniversalStyleItemCheckBox = self.control:GetNamedChild("StyleListUniversalStyleItem")

    local function OnFilterChanged()
        self:OnFilterChanged(ZO_CheckButton_IsChecked(self.haveMaterialsCheckBox), ZO_CheckButton_IsChecked(self.haveKnowledgeCheckBox), ZO_CheckButton_IsChecked(self.useUniversalStyleItemCheckBox))
    end

    local function HandleInventoryChanged()
        self:UpdateUniversalStyleItemCheckBox()
    end

    ZO_CheckButton_SetToggleFunction(self.haveMaterialsCheckBox, OnFilterChanged)
    ZO_CheckButton_SetToggleFunction(self.haveKnowledgeCheckBox, OnFilterChanged)
    ZO_CheckButton_SetToggleFunction(self.useUniversalStyleItemCheckBox, OnFilterChanged)

    ZO_CheckButton_SetLabelText(self.haveMaterialsCheckBox, GetString(SI_SMITHING_HAVE_MATERIALS))
    ZO_CheckButton_SetLabelText(self.haveKnowledgeCheckBox, GetString(SI_SMITHING_HAVE_KNOWLEDGE))

    self:UpdateUniversalStyleItemCheckBox()
    ZO_CheckButtonLabel_SetDefaultColors(self.useUniversalStyleItemCheckBox.label, ZO_COLOR_UNIVERSAL_ITEM, ZO_COLOR_UNIVERSAL_ITEM_SELECTED)
    ZO_CheckButton_Enable(self.useUniversalStyleItemCheckBox, true)

    ZO_CraftingUtils_ConnectCheckBoxToCraftingProcess(self.haveMaterialsCheckBox)
    ZO_CraftingUtils_ConnectCheckBoxToCraftingProcess(self.haveKnowledgeCheckBox)
    ZO_CraftingUtils_ConnectCheckBoxToCraftingProcess(self.useUniversalStyleItemCheckBox)

    -- crappy hack to make sure no one gets in a bad state because we have connected the checkbuttons to the smithing process,
    -- which means we are going to logically set the state of the check buttons without user input, which will interfere with
    -- the player that tries to mouse down on a checkbutton and then start the craft, resulting in a bad state of being stuck in PRESSED
    CALLBACK_MANAGER:RegisterCallback("CraftingAnimationsStarted", function() ZO_CheckButton_SetCheckState(self.haveMaterialsCheckBox, self.savedVars.haveMaterialChecked)
                                                                              ZO_CheckButton_SetCheckState(self.haveKnowledgeCheckBox, self.savedVars.haveKnowledgeChecked)
                                                                              ZO_CheckButton_SetCheckState(self.useUniversalStyleItemCheckBox, self.savedVars.useUniversalStyleItemChecked)
                                                                              end)

    self.useUniversalStyleItemCheckBox:RegisterForEvent(EVENT_INVENTORY_FULL_UPDATE, HandleInventoryChanged)
    self.useUniversalStyleItemCheckBox:RegisterForEvent(EVENT_INVENTORY_SINGLE_SLOT_UPDATE, HandleInventoryChanged)
end

function ZO_SmithingCreation:SetupSavedVars(defaults)
    local defaults = { haveMaterialChecked = false, haveKnowledgeChecked = true, useUniversalStyleItemChecked = false}
    self.savedVars = ZO_SavedVars:New("ZO_Ingame_SavedVariables", 2, "SmithingCreation", defaults)

    ZO_CheckButton_SetCheckState(self.haveMaterialsCheckBox, self.savedVars.haveMaterialChecked)
    ZO_CheckButton_SetCheckState(self.haveKnowledgeCheckBox, self.savedVars.haveKnowledgeChecked)
    ZO_CheckButton_SetCheckState(self.useUniversalStyleItemCheckBox, self:GetIsUsingUniversalStyleItem())
end

function ZO_SmithingCreation:RefreshAvailableFilters()
    ZO_MenuBar_ClearSelection(self.tabs)
    ZO_MenuBar_UpdateButtons(self.tabs)
    ZO_MenuBar_SelectLastVisibleButton(self.tabs, true)
end

function ZO_SmithingCreation:SetupResultTooltip(...)
    self.resultTooltip:SetPendingSmithingItem(...)
end

function ZO_SmithingCreation:OnRefreshAllLists()
    local traitListControl = self.control:GetNamedChild("TraitList")
    local styleListControl = self.control:GetNamedChild("StyleList")
    traitListControl:ClearAnchors()
    if self:ShouldIgnoreStyleItems() then
        local materialListControl = self.control:GetNamedChild("MaterialList")
        traitListControl:SetAnchor(TOP, materialListControl, BOTTOM, 0, 30)
        styleListControl:SetHidden(true)
    else
        traitListControl:SetAnchor(TOP, styleListControl, BOTTOM, 0, 25)
        styleListControl:SetHidden(false)
    end

    -- Need to do this on PC, as the first selection can be garbage otherwise with the style<->pattern cyclic dependencies.
    -- On gamepad, the list auto-scrolls to an item and refreshes twice on its own, so this isn't necessary.
    self:CreatePatternList()
end

function ZO_SmithingCreation:InitializeMaterialList(...)
    local listContainer = self.control:GetNamedChild("MaterialList")
    listContainer.extraInfoLabel:ClearAnchors()
    listContainer.extraInfoLabel:SetAnchor(BOTTOM, listContainer, BOTTOM, 0, 22)

    return ZO_SharedSmithingCreation.InitializeMaterialList(self, ...)
end

function ZO_SmithingCreation:GetPlatformFormattedTextString(stringId, ...)
    return zo_strformat(stringId, ...)
end

function ZO_SmithingCreation:SetLabelHidden(label, hidden)
    label:SetHidden(hidden)
end

function ZO_SmithingCreation:BuyCraftingItems()
    ShowMarketAndSearch(GetString(SI_CROWN_STORE_SEARCH_CRAFT_ITEMS), MARKET_OPEN_OPERATION_UNIVERSAL_STYLE_ITEM)
end

function ZO_SmithingCreation:GetMultiCraftNumIterations()
    return self.multiCraftSpinner:GetValue()
end

function ZO_SmithingCreation:ResetMultiCraftNumIterations()
    self.multiCraftSpinner:SetValue(1)
end

function ZO_SmithingCreation:RefreshMultiCraft()
    self.multiCraftSpinner:SetMinMax(1, self:GetMultiCraftMaxIterations())
    self.multiCraftSpinner:UpdateButtons()
end

function ZO_SmithingCreation:UpdateKeybindStrip()
    self.owner:UpdateSharedKeybindStrip()
end

function ZO_SmithingCreation:ConfirmCreate()
    ZO_KeyboardCraftingUtils_RequestCraftingCreate(self, self:GetMultiCraftNumIterations())
end

function ZO_SmithingCreation_HaveMaterialsOnMouseEnter(control)
    InitializeTooltip(InformationTooltip, control, BOTTOM, 0, -10)
    SetTooltipText(InformationTooltip, GetString(SI_CRAFTING_HAVE_MATERIALS_TOOLTIP))
end

function ZO_SmithingCreation_HaveKnowledgeOnMouseEnter(control)
    InitializeTooltip(InformationTooltip, control, BOTTOM, 0, -10)
    SetTooltipText(InformationTooltip, GetString(SI_CRAFTING_HAVE_KNOWLEDGE_TOOLTIP))
end

function ZO_SmithingCreation_FilterOnMouseExit(control)
    ClearTooltip(InformationTooltip)
end

function ZO_SmithingCreation_UniversalStyleItemOnMouseEnter(control)
    if control.label then
        control.label:SetColor(ZO_COLOR_UNIVERSAL_ITEM_SELECTED:UnpackRGBA())
    end

    InitializeTooltip(InformationTooltip, control, RIGHT, -10, -10)
    local universalStyleItemCount = GetCurrentSmithingStyleItemCount(GetUniversalStyleId())
    InformationTooltip:AddLine(zo_strformat(SI_CRAFTING_USE_UNIVERSAL_STYLE_ITEM, universalStyleItemCount), "", ZO_COLOR_UNIVERSAL_ITEM:UnpackRGBA())
    local r,g,b = ZO_NORMAL_TEXT:UnpackRGB()
    InformationTooltip:AddLine(GetString(SI_CRAFTING_UNIVERSAL_STYLE_ITEM_TOOLTIP), "", r, g, b)
    InformationTooltip:AddLine(GetString(SI_CRAFTING_UNIVERSAL_STYLE_ITEM_CROWN_STORE_TOOLTIP), "", r, g, b)
end

function ZO_SmithingCreation_UniversalStyleItemOnMouseExit(control)
    if control.label then
        control.label:SetColor(ZO_COLOR_UNIVERSAL_ITEM:UnpackRGBA())
    end

    ClearTooltip(InformationTooltip)
end