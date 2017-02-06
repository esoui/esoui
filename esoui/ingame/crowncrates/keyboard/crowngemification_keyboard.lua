ZO_CrownGemification_Keyboard = ZO_Object.MultiSubclass(ZO_CrownGemification_Shared, ZO_SortFilterList)

local GEMIFIABLE_DATA = 1

local g_crownGemificationKeyboard

function ZO_CrownGemification_Keyboard:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    g_crownGemificationKeyboard = object
    return object
end

function ZO_CrownGemification_Keyboard:Initialize(owner, gemificationSlot)
    self.owner = owner
    local control = ZO_CrownGemification_KeyboardTopLevel
    self.control = control
    ZO_SortFilterList.Initialize(self, control)
    -- disable the ZO_SortFilterList functionality of auto-coloring rows
    -- since we will be setting row colors based on different criteria
    self:SetAutomaticallyColorRows(false)

    self.fragment = ZO_SimpleSceneFragment:New(control)
    local exitKeybindStripDescriptor =
    {
        name = GetString(SI_CROWN_CRATE_LEAVE_GEM_EXTRACTION_KEYBIND),
        keybind = "UI_SHORTCUT_EXIT",
        order = -10000,
        callback = function()
            self:RemoveFromScene()
        end,
    }
    ZO_CrownGemification_Shared.Initialize(self, self.fragment, gemificationSlot, exitKeybindStripDescriptor)

    self.sortHeaderGroup:SelectHeaderByKey("gemTotal")

    self:InitializeKeybindStrip()
    self:InitializeList()
    self:InitializeTabs()

    local ENTRY_SORT_KEYS =
    {
        name = { tiebreaker = "gemTotal" },
        gemTotal = { isNumeric = true },
    }
    self.SortData = function(data1, data2)
        return ZO_TableOrderingFunction(data1, data2, self.currentSortKey, ENTRY_SORT_KEYS, self.currentSortOrder)
    end

    self:SetEmptyText(GetString(SI_GEMIFICATION_NOTHING_TO_EXTRACT))
end

function ZO_CrownGemification_Keyboard:OnShowing()
    ZO_CrownGemification_Shared.OnShowing(self)
    --Add List Keybinds
    self:AddKeybinds()
end

function ZO_CrownGemification_Keyboard:OnHidden()
    --Remove List Keybinds
    self:RemoveKeybinds()
    ZO_CrownGemification_Shared.OnHidden(self)
end

function ZO_CrownGemification_Keyboard:InitializeKeybindStrip()
    local listKeybindStripDescriptor =
    {
        {
            name = GetString(SI_GEMIFICATION_SELECT),
            keybind = "UI_SHORTCUT_PRIMARY",
            visible = function()
                return self.mouseOverRow ~= nil
            end,
            callback = function()
                self:SelectMouseOverRow()
            end,
        }
    }
    self:SetKeybindStripDescriptor(listKeybindStripDescriptor)
end

function ZO_CrownGemification_Keyboard:InitializeList()
    ZO_ScrollList_AddDataType(self.list, GEMIFIABLE_DATA, "ZO_CrownGemificationRow", 52, function(control, data) self:SetupGemifiable(control, data) end)
end

do
    local KEYBOARD_GEMIFICATION_FILTER_TEXTURES =
    {
        [GEMIFIABLE_FILTER_TYPE_ALL] =
        {
            up = "EsoUI/Art/Inventory/inventory_tabIcon_all_up.dds", 
            down = "EsoUI/Art/Inventory/inventory_tabIcon_all_down.dds",
            over = "EsoUI/Art/Inventory/inventory_tabIcon_all_over.dds",
        },
    }

    local function GetKeyboardGemificationFilterTexture(filterType)
        local textures = KEYBOARD_GEMIFICATION_FILTER_TEXTURES[filterType]
        return textures.up, textures.down, textures.over
    end

    function ZO_CrownGemification_Keyboard:InitializeTabs()
        self.tabControl = self.control:GetNamedChild("Tabs")

        local function GenerateTab(filterType, normal, pressed, highlight)
            local name = GetString("SI_GEMIFIABLEFILTERTYPE", filterType)
            return {
                tooltipText = name,

                descriptor = filterType,
                normal = normal,
                pressed = pressed,
                highlight = highlight,
                callback = function(tabData)
                    self:OnTabFilterChanged(tabData)
                    self.tabControl:GetNamedChild("Active"):SetText(name)
                end,
            }
        end

        ZO_MenuBar_AddButton(self.tabControl, GenerateTab(GEMIFIABLE_FILTER_TYPE_ALL, GetKeyboardGemificationFilterTexture(GEMIFIABLE_FILTER_TYPE_ALL)))
        ZO_MenuBar_SelectDescriptor(self.tabControl, GEMIFIABLE_FILTER_TYPE_ALL)
    end
end

--Crown Gemification Shared Overrides

function ZO_CrownGemification_Keyboard:InsertIntoScene()
    SCENE_MANAGER:AddFragment(self.fragment)
    SCENE_MANAGER:AddFragment(RIGHT_PANEL_BG_FRAGMENT)
    SCENE_MANAGER:AddFragment(CROWN_CRATES_GEMIFICATION_WINDOW_SOUNDS)
    
end

function ZO_CrownGemification_Keyboard:RemoveFromScene()
    SCENE_MANAGER:RemoveFragment(self.fragment)
    SCENE_MANAGER:RemoveFragment(RIGHT_PANEL_BG_FRAGMENT)
    SCENE_MANAGER:RemoveFragment(CROWN_CRATES_GEMIFICATION_WINDOW_SOUNDS)
end

function ZO_CrownGemification_Keyboard:RefreshList()
    ZO_CrownGemification_Shared.RefreshList(self)
    self:RefreshData()
end

function ZO_CrownGemification_Keyboard:RefreshGemifiable(gemifiable)
    ZO_CrownGemification_Shared.RefreshGemifiable(self, gemifiable)
    self:RefreshVisible()
end

--End Crown Gemification Shared Overrides

--Sort Filter List Overrides

function ZO_CrownGemification_Shared:BuildMasterList()
    self.masterList = CROWN_GEMIFICATION_MANAGER:GetGemifiableList()
end

function ZO_CrownGemification_Shared:FilterScrollList()
    if self.masterList then
        self.personalList = ZO_ShallowTableCopy(self.masterList)
    end
end

function ZO_CrownGemification_Shared:SortScrollList()
    if self.personalList then
        table.sort(self.personalList, self.SortData)

        local scrollData = ZO_ScrollList_GetDataList(self.list)
        ZO_ClearNumericallyIndexedTable(scrollData)
    
        for i, gemifiable in ipairs(self.personalList) do
            table.insert(scrollData, ZO_ScrollList_CreateDataEntry(GEMIFIABLE_DATA, gemifiable))
        end
    end
end

--End Sort Filter List Overrides

function ZO_CrownGemification_Keyboard:SetupGemifiable(control, data)
    local nameControl = GetControl(control, "Name")
    nameControl:SetText(data.name) -- already formatted

    local sellPriceControl = GetControl(control, "SellPrice")
    sellPriceControl:SetHidden(false)
    ZO_CurrencyControl_SetSimpleCurrency(sellPriceControl, UI_ONLY_CURRENCY_CROWN_GEMS, data.gemTotal)

    local hasEnoughForAConversion = data.maxGemifies > 0
    local NOT_LOCKED = false
    ZO_PlayerInventorySlot_SetupSlot(control, data.count, data.icon, hasEnoughForAConversion, NOT_LOCKED)
end

function ZO_CrownGemification_Keyboard:OnTabFilterChanged(filter)
    --Implement if we have more filters
end

function ZO_CrownGemification_Keyboard:SelectMouseOverRow()
    if self.mouseOverRow then
        local data = ZO_ScrollList_GetData(self.mouseOverRow)
        self.gemificationSlot:SetGemifiable(data)
        PlaySound(SOUNDS.DEFAULT_CLICK)
    end
end

function ZO_CrownGemification_Keyboard:Row_OnMouseEnter(control)
    self.mouseOverRow = control
    self:UpdateKeybinds()
    local data = ZO_ScrollList_GetData(self.mouseOverRow)
    InitializeTooltip(InformationTooltip, control, TOPRIGHT, 0, 0, TOPLEFT)
    data:LayoutKeyboardTooltip()
end

function ZO_CrownGemification_Keyboard:Row_OnMouseExit(control)
    self.mouseOverRow = nil
    self:UpdateKeybinds()
    ClearTooltip(InformationTooltip)
end

function ZO_CrownGemification_Keyboard:Row_OnMouseUp(control, button, upInside)
    if upInside and button == MOUSE_BUTTON_INDEX_LEFT then
        self:SelectMouseOverRow()
    end
end

--Global XML

function ZO_CrownGemificationRow_OnMouseEnter(self)
    ZO_InventorySlot_OnMouseEnter(self)
    g_crownGemificationKeyboard:Row_OnMouseEnter(self)
end

function ZO_CrownGemificationRow_OnMouseExit(self)
    ZO_InventorySlot_OnMouseExit(self)
    g_crownGemificationKeyboard:Row_OnMouseExit(self)
end

function ZO_CrownGemificationRow_OnMouseUp(self, button, upInside)
    g_crownGemificationKeyboard:Row_OnMouseUp(self, button, upInside)
end