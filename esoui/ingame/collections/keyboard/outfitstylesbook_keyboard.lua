ZO_OutfitStylesBook_Keyboard = ZO_RestyleCommon_Keyboard:Subclass()

function ZO_OutfitStylesBook_Keyboard:New(...)
    return ZO_RestyleCommon_Keyboard.New(self, ...)
end

function ZO_OutfitStylesBook_Keyboard:Initialize(control)
    ZO_RestyleCommon_Keyboard.Initialize(self, control)

    ZO_OUTFIT_STYLES_BOOK_SCENE = ZO_Scene:New("outfitStylesBook", SCENE_MANAGER)
    ZO_OUTFIT_STYLES_BOOK_FRAGMENT = self:GetFragment()

    self.onModeDropdownChangedCallback = function()
        ZO_OUTFIT_STYLES_PANEL_KEYBOARD:ClearAllCurrentSlotPreviews()
    end
end

function ZO_OutfitStylesBook_Keyboard:InitializeKeybindStripDescriptors()
    local INITIAL_CONTEXT_MENU_REF_COUNT = 1

    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_CENTER,
        
        -- Cancel All Previews
        {
            name = GetString(SI_OUTFIT_STYLES_BOOK_END_ALL_PREVIEWS_KEYBIND),
            keybind = "UI_SHORTCUT_NEGATIVE",
            visible = function()
                return ZO_OUTFIT_STYLES_PANEL_KEYBOARD:HasAnyCurrentSlotPreviews()
            end,
            callback = function()
                ZO_OUTFIT_STYLES_PANEL_KEYBOARD:ClearAllCurrentSlotPreviews()
            end,
        },

        -- Preview Target
        {
            alignment = KEYBIND_STRIP_ALIGN_RIGHT,

            name = function()
                local collectibleData = ZO_OUTFIT_STYLES_PANEL_KEYBOARD:GetMouseOverEntryData().data
                if ZO_OUTFIT_STYLES_PANEL_KEYBOARD:IsPreviewingOutfitStyle(collectibleData) then
                    return GetString(SI_OUTFIT_STYLES_BOOK_END_PREVIEW_KEYBIND)
                else
                    return GetString(SI_OUTFIT_STYLES_BOOK_PREVIEW_KEYBIND)
                end
            end,

            keybind = "UI_SHORTCUT_PRIMARY",

            visible = function()
                return ZO_OUTFIT_STYLES_PANEL_KEYBOARD:GetMouseOverEntryData() ~= nil
            end,

            callback = function()
                local collectibleData = ZO_OUTFIT_STYLES_PANEL_KEYBOARD:GetMouseOverEntryData().data
                ZO_OUTFIT_STYLES_PANEL_KEYBOARD:TogglePreviewOutfitStyle(collectibleData)
            end,
        },
    }
end

function ZO_OutfitStylesBook_Keyboard:RegisterForEvents()
    ZO_RestyleCommon_Keyboard.RegisterForEvents(self)

    ZO_OUTFIT_STYLES_PANEL_KEYBOARD:RegisterCallback("PreviewSlotsChanged", self.updateKeybindCallback)
    ZO_RESTYLE_SHEET_WINDOW_KEYBOARD:RegisterCallback("ModeSelectorDropdownChanged", self.onModeDropdownChangedCallback)
end

function ZO_OutfitStylesBook_Keyboard:UnregisterForEvents()
    ZO_RestyleCommon_Keyboard.UnregisterForEvents(self)

    ZO_OUTFIT_STYLES_PANEL_KEYBOARD:UnregisterCallback("PreviewSlotsChanged", self.updateKeybindCallback)
    ZO_RESTYLE_SHEET_WINDOW_KEYBOARD:RegisterCallback("ModeSelectorDropdownChanged", self.onModeDropdownChangedCallback)
end

function ZO_OutfitStylesBook_Keyboard:InitializeModeData()
    ZO_RESTYLE_SHEET_WINDOW_KEYBOARD:PopulateEquipmentModeDropdown()
end

do
    local DISALLOW_DYEING = false
    local SPECIALIZED_COLLECTIBLE_CATEGORY_ENABLED = true
    local DERIVES_COLLECTIBLE_CATEGORIES_FROM_SLOTS = false
    local RESTYLE_CATEGORY_DATA = ZO_RestyleCategoryData:New(DISALLOW_DYEING, COLLECTIBLE_CATEGORY_SPECIALIZATION_OUTFIT_STYLES, SPECIALIZED_COLLECTIBLE_CATEGORY_ENABLED, DERIVES_COLLECTIBLE_CATEGORIES_FROM_SLOTS)

    function ZO_OutfitStylesBook_Keyboard:GetRestyleCategoryData()
        return RESTYLE_CATEGORY_DATA
    end
end

function ZO_OutfitStylesBook_Keyboard:NavigateToCollectibleData(collectibleData)
    if not ZO_OUTFIT_STYLES_BOOK_SCENE:IsShowing() then
        MAIN_MENU_KEYBOARD:ToggleSceneGroup("collectionsSceneGroup", "outfitStylesBook")
    end
    ZO_RestyleCommon_Keyboard.NavigateToCollectibleData(self, collectibleData)
end

function ZO_OutfitStylesBook_Keyboard_OnSearchTextChanged(editBox)
    ZO_OUTFIT_STYLES_BOOK_KEYBOARD:OnSearchTextChanged()
end

function ZO_OutfitStylesBook_Keyboard_OnInitialize(control)
    ZO_OUTFIT_STYLES_BOOK_KEYBOARD = ZO_OutfitStylesBook_Keyboard:New(control)
end