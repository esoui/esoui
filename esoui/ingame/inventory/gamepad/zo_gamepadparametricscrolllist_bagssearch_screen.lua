ZO_Gamepad_ParametricList_BagsSearch_Screen = ZO_Gamepad_ParametricList_Screen:Subclass()

function ZO_Gamepad_ParametricList_BagsSearch_Screen:Initialize(...)
    ZO_Gamepad_ParametricList_Screen.Initialize(self, ...)

    local function OnTextSearchTextChanged(editBox)
        if self.searchContext then
            TEXT_SEARCH_MANAGER:SetSearchText(self.searchContext, editBox:GetText())
        end
    end

    self:AddSearch(self.textSearchKeybindStripDescriptor, OnTextSearchTextChanged)

    -- Due to addition of text search, navigation of the list is now handled by the screen as opposed to the list itself.
    -- As such, Update handler is needed to update the current list.
    self.control:SetHandler("OnUpdate", function() self:OnUpdate() end)
end

function ZO_Gamepad_ParametricList_BagsSearch_Screen:OnUpdate()
    local list = self:GetCurrentList()
    if list then
        local listObject = list.list
        if listObject then
            listObject:OnUpdate()
        end
    end
end

function ZO_Gamepad_ParametricList_BagsSearch_Screen:OnUpdatedSearchResults()
    local list = self:GetCurrentList()
    if list then
        list:RefreshList()
    end
end

function ZO_Gamepad_ParametricList_BagsSearch_Screen:InitializeKeybindStripDescriptors()
    self.textSearchKeybindStripDescriptor =
    {
        {
            alignment = KEYBIND_STRIP_ALIGN_LEFT,
            keybind = "UI_SHORTCUT_PRIMARY",
            name = function()
                return GetString(SI_GAMEPAD_SELECT_OPTION)
            end,
            callback = function()
                self:SetTextSearchFocused(true)
            end,
        },
    }
    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.textSearchKeybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON, function()
        self:OnBackButtonClicked()
    end)
end

function ZO_Gamepad_ParametricList_BagsSearch_Screen:PerformUpdate()
    if self.dirty then
        self.dirty = false
        self:OnUpdatedSearchResults()
    end
end

function ZO_Gamepad_ParametricList_BagsSearch_Screen:OnBackButtonClicked()
    -- Default back functionality, override this function for different behaviour
    SCENE_MANAGER:HideCurrentScene()
end

function ZO_Gamepad_ParametricList_BagsSearch_Screen:UpdateSearchText()
    if self.textSearchHeaderFocus and self.searchContext then
        self.textSearchHeaderFocus:UpdateTextForContext(self.searchContext)
    end
end

function ZO_Gamepad_ParametricList_BagsSearch_Screen:GetTextSearchText()
    if self.textSearchHeaderFocus then
        return self.textSearchHeaderFocus:GetText()
    end

    return ""
end

function ZO_Gamepad_ParametricList_BagsSearch_Screen:IsSlotInSearchTextResults(bagId, slotIndex)
    if self.searchContext then
        return TEXT_SEARCH_MANAGER:IsItemInSearchTextResults(self.searchContext, BACKGROUND_LIST_FILTER_TARGET_BAG_SLOT, bagId, slotIndex)
    end
    -- Return true for every result if we don't have a context search
    return true
end

function ZO_Gamepad_ParametricList_BagsSearch_Screen:SetTextSearchContext(context)
    self.searchContext = context
end

function ZO_Gamepad_ParametricList_BagsSearch_Screen:ActivateTextSearch()
    if self.searchContext and not TEXT_SEARCH_MANAGER:IsActiveTextSearch(self.searchContext) then
        self:UpdateSearchText()

        local function OnTextSearchResults()
            self.dirty = true
            self:Update()
        end
        self.onTextSearchResults = OnTextSearchResults

        TEXT_SEARCH_MANAGER:ActivateTextSearch(self.searchContext)
        TEXT_SEARCH_MANAGER:RegisterCallback("UpdateSearchResults", OnTextSearchResults)
    end
end

function ZO_Gamepad_ParametricList_BagsSearch_Screen:DeactivateTextSearch()
    if self.searchContext then
        TEXT_SEARCH_MANAGER:DeactivateTextSearch(self.searchContext)
        TEXT_SEARCH_MANAGER:UnregisterCallback("UpdateSearchResults", self.onTextSearchResults)
    end
end

function ZO_Gamepad_ParametricList_BagsSearch_Screen:SetSearchText()
    if self.searchContext then
        TEXT_SEARCH_MANAGER:SetSearchText(self.searchContext, self:GetTextSearchText())
    end
end

function ZO_Gamepad_ParametricList_BagsSearch_Screen:OnShow()
    self:ActivateTextSearch()
end

function ZO_Gamepad_ParametricList_BagsSearch_Screen:OnHiding()
    self:DeactivateTextSearch()
end

function ZO_Gamepad_ParametricList_BagsSearch_Screen:MarkDirtyByBagId(bagId, shouldSuppressSearchUpdate)
    TEXT_SEARCH_MANAGER:MarkDirtyByFilterTargetAndPrimaryKey(BACKGROUND_LIST_FILTER_TARGET_BAG_SLOT, bagId, shouldSuppressSearchUpdate)
end
