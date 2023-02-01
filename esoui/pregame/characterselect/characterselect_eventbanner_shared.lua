ZO_CharacterSelect_EventBanner_Shared = ZO_Object:Subclass()

function ZO_CharacterSelect_EventBanner_Shared:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_CharacterSelect_EventBanner_Shared:Initialize(control, fragmentConditionFunction)
    self.control = control

    local container = control:GetNamedChild("Container")
    self.carouselControl = container:GetNamedChild("Carousel")
    self.controlContainer = container

    self:InitializeKeybinds()

    local fragment = ZO_FadeSceneFragment:New(control)
    fragment:RegisterCallback("StateChange", function(...) self:OnStateChanged(...) end)
    if fragmentConditionFunction then
        fragment:SetConditional(fragmentConditionFunction)
    end
    self.fragment = fragment

    CHARACTER_SELECT_MANAGER:RegisterCallback("EventAnnouncementExpired", function() self:PopulateCarousel() end)
end

function ZO_CharacterSelect_EventBanner_Shared:GetFragment()
    return self.fragment
end

function ZO_CharacterSelect_EventBanner_Shared:OnStateChanged(oldState, newState)
    if newState == SCENE_SHOWING then
        self:OnShowing()
    elseif newState == SCENE_SHOWN then
        self:OnShown()
    elseif newState == SCENE_HIDING then
        self:OnHiding()
    elseif newState == SCENE_HIDDEN then
        self:OnHidden()
    end
end

function ZO_CharacterSelect_EventBanner_Shared:OnShowing()
    PlaySound(SOUNDS.DEFAULT_WINDOW_OPEN)
    self:PopulateCarousel()
    self.carousel:Activate()
end

function ZO_CharacterSelect_EventBanner_Shared:OnShown()
    -- To be overridden
end

function ZO_CharacterSelect_EventBanner_Shared:OnHiding()
    PlaySound(SOUNDS.DEFAULT_WINDOW_CLOSE)
    self.carousel:Deactivate()
    CHARACTER_SELECT_MANAGER:UpdateLastSeenTimestamp()
    ZO_SavePlayerConsoleProfile()
end

function ZO_CharacterSelect_EventBanner_Shared:OnHidden()
    -- To be overridden
end

function ZO_CharacterSelect_EventBanner_Shared:GetPlatformEventTileTemplate()
    assert(false) -- To be overridden
end

function ZO_CharacterSelect_EventBanner_Shared:InitializeKeybinds()
    -- To be overridden
end

function ZO_CharacterSelect_EventBanner_Shared:PopulateCarousel()
    self.carousel:Clear()

    local numEvents = CHARACTER_SELECT_MANAGER:GetNumEventAnnouncements()
    for i = 1, numEvents do
        local data = CHARACTER_SELECT_MANAGER:GetEventAnnouncementDataByIndex(i)
        local entryData =
        {
            index = data.index,
            name = data.name,
            description = data.description,
            image = data.image,
            startTime = data.startTime,
            remainingTime = data.remainingTime,
            callback = function() self:OnSelectionChanged(i) end
        }

        self.carousel:AddEntry(entryData)
    end
    self.carousel:Commit()

    local ALLOW_IF_DISABLED = true
    local WITHOUT_ANIMATION = true
    self.carousel:SetSelectedIndex(self.autoSelectIndex or 0, ALLOW_IF_DISABLED, WITHOUT_ANIMATION)
end

function ZO_CharacterSelect_EventBanner_Shared:OnEventBannerCloseKeybind()
    PlaySound(SOUNDS.DIALOG_ACCEPT)
    SCENE_MANAGER:RemoveFragment(self:GetFragment())
end

function ZO_CharacterSelect_EventBanner_Shared:OnSelectionChanged(index)
    self.carousel:UpdateSelection(index)
end