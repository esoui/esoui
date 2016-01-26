ZO_SmithingCreation = ZO_SharedSmithingCreation:Subclass()

function ZO_SmithingCreation:New(...)
    return ZO_SharedSmithingCreation.New(self, ...)
end

function ZO_SmithingCreation:Initialize(control, owner)
    local infoBar = control:GetNamedChild("InfoBar")
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

    local HIDE_SPINNER_WHEN_RANK_REQUIREMENT_NOT_MET = false
    self:InitializeMaterialList(scrollListControl, ZO_Spinner, HIDE_SPINNER_WHEN_RANK_REQUIREMENT_NOT_MET, listSlotTemplate)

    self:InitializeFilterTypeBar()

    self.resultTooltip = control:GetNamedChild("ResultTooltip")
    if IsChatSystemAvailableForCurrentPlatform() then
        local function OnTooltipMouseUp(control, button, upInside)
            if upInside and button == MOUSE_BUTTON_INDEX_RIGHT then
                local link = ZO_LinkHandler_CreateChatLink(GetSmithingPatternResultLink, self:GetAllCraftingParameters())
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
end

function ZO_SmithingCreation:SetHidden(hidden)
    self.control:SetHidden(hidden)
    if not hidden then
        CRAFTING_RESULTS:SetCraftingTooltip(self.resultTooltip)
        CRAFTING_RESULTS:SetTooltipAnimationSounds(self:GetCreateTooltipSound())
        if self.dirty then
            self:RefreshAllLists()
        end
    end
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
            activeTabText = name,
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

    local function CanCraftSetWeapons()
        return CanCraftWeapons() and CanSmithingSetPatternsBeCraftedHere()
    end

    local function CanCraftSetArmor()
        return CanCraftArmor() and CanSmithingSetPatternsBeCraftedHere()
    end
    
    ZO_MenuBar_AddButton(self.tabs, CreateNewTabFilterData(ZO_SMITHING_CREATION_FILTER_TYPE_ARMOR, GetString("SI_ITEMFILTERTYPE", ITEMFILTERTYPE_ARMOR), "EsoUI/Art/Inventory/inventory_tabIcon_armor_up.dds", "EsoUI/Art/Inventory/inventory_tabIcon_armor_down.dds", "EsoUI/Art/Inventory/inventory_tabIcon_armor_over.dds", "EsoUI/Art/Inventory/inventory_tabIcon_armor_disabled.dds", CanCraftArmor))
    ZO_MenuBar_AddButton(self.tabs, CreateNewTabFilterData(ZO_SMITHING_CREATION_FILTER_TYPE_WEAPONS, GetString("SI_ITEMFILTERTYPE", ITEMFILTERTYPE_WEAPONS), "EsoUI/Art/Inventory/inventory_tabIcon_weapons_up.dds", "EsoUI/Art/Inventory/inventory_tabIcon_weapons_down.dds", "EsoUI/Art/Inventory/inventory_tabIcon_weapons_over.dds", "EsoUI/Art/Inventory/inventory_tabIcon_weapons_disabled.dds", CanCraftWeapons))
    ZO_MenuBar_AddButton(self.tabs, CreateNewTabFilterData(ZO_SMITHING_CREATION_FILTER_TYPE_SET_ARMOR, GetString(SI_SMITHING_CREATION_FILTER_SET_ARMOR), "EsoUI/Art/Crafting/smithing_tabIcon_armorSet_up.dds", "EsoUI/Art/Crafting/smithing_tabIcon_armorSet_down.dds", "EsoUI/Art/Crafting/smithing_tabIcon_armorSet_over.dds", "EsoUI/Art/Crafting/smithing_tabIcon_armorSet_disabled.dds", CanCraftSetArmor))
    ZO_MenuBar_AddButton(self.tabs, CreateNewTabFilterData(ZO_SMITHING_CREATION_FILTER_TYPE_SET_WEAPONS, GetString(SI_SMITHING_CREATION_FILTER_SET_WEAPONS), "EsoUI/Art/Crafting/smithing_tabIcon_weaponSet_up.dds", "EsoUI/Art/Crafting/smithing_tabIcon_weaponSet_down.dds", "EsoUI/Art/Crafting/smithing_tabIcon_weaponSet_over.dds", "EsoUI/Art/Crafting/smithing_tabIcon_weaponSet_disabled.dds", CanCraftSetWeapons))

    ZO_CraftingUtils_ConnectMenuBarToCraftingProcess(self.tabs)
end

function ZO_SmithingCreation:InitializeFilters()
    self.haveMaterialsCheckBox = self.control:GetNamedChild("HaveMaterials")
    self.haveKnowledgeCheckBox = self.control:GetNamedChild("HaveKnowledge")

    local function OnFilterChanged()
        self:OnFilterChanged(ZO_CheckButton_IsChecked(self.haveMaterialsCheckBox), ZO_CheckButton_IsChecked(self.haveKnowledgeCheckBox))
    end

    ZO_CheckButton_SetToggleFunction(self.haveMaterialsCheckBox, OnFilterChanged)
    ZO_CheckButton_SetToggleFunction(self.haveKnowledgeCheckBox, OnFilterChanged)

    ZO_CheckButton_SetLabelText(self.haveMaterialsCheckBox, GetString(SI_SMITHING_HAVE_MATERIALS))
    ZO_CheckButton_SetLabelText(self.haveKnowledgeCheckBox, GetString(SI_SMITHING_HAVE_KNOWLEDGE))

    ZO_CraftingUtils_ConnectCheckBoxToCraftingProcess(self.haveMaterialsCheckBox)
    ZO_CraftingUtils_ConnectCheckBoxToCraftingProcess(self.haveKnowledgeCheckBox)
end

function ZO_SmithingCreation:SetupSavedVars(defaults)
    local defaults = { haveMaterialChecked = false, haveKnowledgeChecked = true, }
    self.savedVars = ZO_SavedVars:New("ZO_Ingame_SavedVariables", 2, "SmithingCreation", defaults)

    ZO_CheckButton_SetCheckState(self.haveMaterialsCheckBox, self.savedVars.haveMaterialChecked)
    ZO_CheckButton_SetCheckState(self.haveKnowledgeCheckBox, self.savedVars.haveKnowledgeChecked)
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
	-- Need to do this on PC, as the first selection can be garbage otherwise with the style<->pattern cyclic dependencies.
	-- On gamepad, the list auto-scrolls to an item and refreshes twice on its own, so this isn't necessary.
	self:CreatePatternList()
end

function ZO_SmithingCreation:InitializeMaterialList(...)
    local listContainer = self.control:GetNamedChild("MaterialList")
    listContainer.extraInfoLabel:SetAnchor(BOTTOM, listContainer, BOTTOM, 0, 22)

    return ZO_SharedSmithingCreation.InitializeMaterialList(self, ...)
end

function ZO_SmithingCreation:GetPlatformFormattedTextString(stringId, ...)
    return zo_strformat(stringId, ...)
end

function ZO_SmithingCreation:SetLabelHidden(label, hidden)
    label:SetHidden(hidden)
end