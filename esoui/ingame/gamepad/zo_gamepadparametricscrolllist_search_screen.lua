ZO_Gamepad_ParametricList_Search_Screen = ZO_Object.MultiSubclass(ZO_Gamepad_ParametricList_Screen, ZO_TextSearchObject)

function ZO_Gamepad_ParametricList_Search_Screen:Initialize(searchFilterType, searchContext, ...)
    -- Call signature of :Initialize() is slightly different between ParametricList_Screen and ParametricList_Search_Screen.  Check that upgrade was done correctly.
    internalassert(type(searchFilterType) == "number")
    internalassert(type(searchContext) == "string")

    ZO_Gamepad_ParametricList_Screen.Initialize(self, ...)

    self.searchFilterType = searchFilterType

    local function OnTextSearchTextChanged(editBox)
        self:OnTextSearchTextChanged(editBox)
    end
    self:AddSearch(self.textSearchKeybindStripDescriptor, OnTextSearchTextChanged)
    ZO_TextSearchObject.Initialize(self, searchContext, self:GetSearchEditBox())
end

function ZO_Gamepad_ParametricList_Search_Screen:SetupOnTextChangedHandler()
    -- Due to addition of text search, navigation of the list is now handled by the screen as opposed to the list itself.
    -- As such, Update handler is needed to update the current list.
    self.control:SetHandler("OnUpdate", function() self:OnUpdate() end)
end

function ZO_Gamepad_ParametricList_Search_Screen:OnUpdate()
    local list = self:GetCurrentList()
    if list then
        local listObject = list.list
        if listObject then
            listObject:OnUpdate()
        end
    end
end

-- Overrides ZO_TextSearchObject
function ZO_Gamepad_ParametricList_Search_Screen:OnUpdateSearchResults()
    self:Update()
end

function ZO_Gamepad_ParametricList_Search_Screen:InitializeKeybindStripDescriptors()
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

function ZO_Gamepad_ParametricList_Search_Screen:PerformUpdate()
    if self.dirty then
        self.dirty = false
        local list = self:GetCurrentList()
        if list then
            list:RefreshList()
        end
    end
end

function ZO_Gamepad_ParametricList_Search_Screen:OnBackButtonClicked()
    -- Default back functionality, override this function for different behaviour
    SCENE_MANAGER:HideCurrentScene()
end

-- Overrides ZO_TextSearchObject
function ZO_Gamepad_ParametricList_Search_Screen:GetSearchEditBox()
    return self.textSearchHeaderFocus
end

-- Overrides ZO_TextSearchObject
function ZO_Gamepad_ParametricList_Search_Screen:GetTextSearchText()
    if self.textSearchHeaderFocus then
        return self.textSearchHeaderFocus:GetText()
    end
    return ""
end

-- Overrides ZO_TextSearchObject
function ZO_Gamepad_ParametricList_Search_Screen:UpdateSearchText()
    if self.textSearchHeaderFocus and self.searchContext then
        self.textSearchHeaderFocus:UpdateTextForContext(self.searchContext)
    end
end

function ZO_Gamepad_ParametricList_Search_Screen:OnShowing()
    self:ActivateTextSearch()
end

function ZO_Gamepad_ParametricList_Search_Screen:OnShow()
    local list = self:GetCurrentList()
    local getNumFunction = list.GetNumEntries or list.GetNumItems
    if getNumFunction ~= nil and getNumFunction(list) == 0 then
        -- If the current list is empty, select the search header.
        -- Otherwise the user won't be able to navigate into the search box.
        self:RequestEnterHeader()
    end
end

function ZO_Gamepad_ParametricList_Search_Screen:OnHiding()
    self:DeactivateTextSearch()
end

function ZO_Gamepad_ParametricList_Search_Screen:MarkDirty(shouldSuppressSearchUpdate)
    TEXT_SEARCH_MANAGER:MarkDirtyByFilterTarget(self.searchFilterType, shouldSuppressSearchUpdate)
end
