--[[Basic screen]]--
ZO_LoreLibraryBookSetGamepad = ZO_Gamepad_ParametricList_Screen:Subclass()

function ZO_LoreLibraryBookSetGamepad:New(...)
    return ZO_Gamepad_ParametricList_Screen.New(self, ...)
end

function ZO_LoreLibraryBookSetGamepad:Initialize(control)
    ZO_Gamepad_ParametricList_Screen.Initialize(self, control, false)
    self.itemList = ZO_Gamepad_ParametricList_Screen.GetMainList(self)

    self.headerData = {
            titleText = GetString(SI_WINDOW_TITLE_LORE_LIBRARY),
            data1HeaderText = "",
            data1Text = "",
        }

    ZO_GamepadGenericHeader_Refresh(self.header, self.headerData)

    self:InitializeEvents()
end

function ZO_LoreLibraryBookSetGamepad:InitializeEvents()
    local function OnInitialized()
        if self.control:IsControlHidden() then
            self.dirty = true
        else
            self:Update()
        end
    end

    local function OnBookLearned(eventCode, categoryIndex, collectionIndex, bookIndex)
        if self.control:IsControlHidden() then
            self.dirty = true
        else
            self:Update()
        end
    end

    self.control:RegisterForEvent(EVENT_LORE_LIBRARY_INITIALIZED, OnInitialized)
    self.control:RegisterForEvent(EVENT_LORE_BOOK_LEARNED, OnBookLearned)
end
