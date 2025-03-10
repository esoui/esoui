ZO_OutfitStylesBook_Keyboard = ZO_RestyleCommon_Keyboard:Subclass()

function ZO_OutfitStylesBook_Keyboard:Initialize(control)
    ZO_RestyleCommon_Keyboard.Initialize(self, control)

    ZO_OUTFIT_STYLES_BOOK_SCENE = ZO_Scene:New("outfitStylesBook", SCENE_MANAGER)
    ZO_OUTFIT_STYLES_BOOK_FRAGMENT = self:GetFragment()
end

function ZO_OutfitStylesBook_Keyboard:OnDeferredInitialize()
    -- If we haven't run this function yet, and the last restyle sheet we opened was
    -- a costume sheet, we will UI error; InitializeModeData ensures our sheet is set
    -- correctly before we initialize everything else to prevent this.
    self:InitializeModeData()
    ZO_RestyleCommon_Keyboard.OnDeferredInitialize(self)

    self.onModeDropdownChangedCallback = function()
        ZO_OUTFIT_STYLES_PANEL_KEYBOARD:ClearAllCurrentSlotPreviews()
    end

    self.previewAvailable = true
    self.control:SetHandler("OnUpdate", function() self:OnUpdate() end)
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

            enabled = function()
                local collectibleData = ZO_OUTFIT_STYLES_PANEL_KEYBOARD:GetMouseOverEntryData().data
                local isPreviewAvailable = IsCharacterPreviewingAvailable()
                if isPreviewAvailable and (not collectibleData.IsBlocked or not collectibleData:IsBlocked(GAMEPLAY_ACTOR_CATEGORY_PLAYER)) then
                    return true
                elseif not isPreviewAvailable then
                    return false, GetString(SI_PREVIEW_UNAVAILABLE_ERROR)
                end
                return false
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

        -- Change outfit name
        {
            alignment = KEYBIND_STRIP_ALIGN_LEFT,

            keybind = "UI_SHORTCUT_QUATERNARY",

            name = GetString(SI_OUTFIT_CHANGE_NAME),

            visible = function()
                local currentSheet = ZO_RESTYLE_SHEET_WINDOW_KEYBOARD:GetCurrentSheet()
                return currentSheet:GetRestyleMode() == RESTYLE_MODE_OUTFIT
            end,

            callback = function()
                local currentSheet = ZO_RESTYLE_SHEET_WINDOW_KEYBOARD:GetCurrentSheet()
                local outfitManipulator = currentSheet:GetCurrentOutfitManipulator()
                ZO_Dialogs_ShowDialog("RENAME_OUFIT", { actorCategory = outfitManipulator:GetActorCategory(), outfitIndex = outfitManipulator:GetOutfitIndex() }, { initialEditText = outfitManipulator:GetOutfitName() })
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
    ZO_RESTYLE_SHEET_WINDOW_KEYBOARD:UnregisterCallback("ModeSelectorDropdownChanged", self.onModeDropdownChangedCallback)
end

function ZO_OutfitStylesBook_Keyboard:InitializeModeData()
    ZO_RESTYLE_SHEET_WINDOW_KEYBOARD:PopulateEquipmentModeDropdown()
end

function ZO_OutfitStylesBook_Keyboard:OnHidden()
    ZO_RestyleCommon_Keyboard.OnHidden(self)

    ZO_OUTFIT_STYLES_PANEL_KEYBOARD:ClearAllCurrentSlotPreviews()
end

function ZO_OutfitStylesBook_Keyboard:OnUpdate()
    local isPreviewingAvailable = IsCharacterPreviewingAvailable()
    if self.previewAvailable ~= isPreviewingAvailable then
        self.previewAvailable = isPreviewingAvailable
        self.updateKeybindCallback()
    end
end

do
    local DISALLOW_DYEING = false
    local SPECIALIZED_COLLECTIBLE_CATEGORY_ENABLED = true
    local DONT_DERIVE_COLLECTIBLE_CATEGORIES_FROM_SLOTS = false
    local RESTYLE_CATEGORY_DATA = ZO_RestyleCategoryData:New(RESTYLE_MODE_OUTFIT, DISALLOW_DYEING, COLLECTIBLE_CATEGORY_SPECIALIZATION_OUTFIT_STYLES, SPECIALIZED_COLLECTIBLE_CATEGORY_ENABLED, DONT_DERIVE_COLLECTIBLE_CATEGORIES_FROM_SLOTS)
    local RESTYLE_COMPANION_CATEGORY_DATA = ZO_RestyleCategoryData:New(RESTYLE_MODE_COMPANION_OUTFIT, DISALLOW_DYEING, COLLECTIBLE_CATEGORY_SPECIALIZATION_OUTFIT_STYLES, SPECIALIZED_COLLECTIBLE_CATEGORY_ENABLED, DONT_DERIVE_COLLECTIBLE_CATEGORIES_FROM_SLOTS)

    function ZO_OutfitStylesBook_Keyboard:GetRestyleCategoryData()
        local currentSheet = ZO_RESTYLE_SHEET_WINDOW_KEYBOARD:GetCurrentSheet()
        local actorCategory = ZO_OUTFIT_MANAGER.GetActorCategoryByRestyleMode(currentSheet:GetRestyleMode())
        if actorCategory == GAMEPLAY_ACTOR_CATEGORY_PLAYER then
            return RESTYLE_CATEGORY_DATA
        elseif actorCategory == GAMEPLAY_ACTOR_CATEGORY_COMPANION then
            return RESTYLE_COMPANION_CATEGORY_DATA
        end
        return nil
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