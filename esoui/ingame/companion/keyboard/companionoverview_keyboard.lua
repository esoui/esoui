
ZO_CompanionOverview_Keyboard = ZO_InitializingObject:Subclass()

function ZO_CompanionOverview_Keyboard:Initialize(control)
    self.control = control

    --Initialize the progress bar
    self.progressContainer = control:GetNamedChild("LevelProgress")
    self.levelBar = ZO_CompanionProgressBar_Keyboard:New(self.progressContainer)

    self.passivePerkLabel = control:GetNamedChild("PassivePerkValue")
    self.readOnlyActionBar = ZO_KeyboardAssignableActionBar:New(control:GetNamedChild("ReadOnlyActionBar"))
    self.readOnlyActionBar:SetHotbarEditsEnabled(false)

    local RAPPORT_GRADIENT_START = ZO_ColorDef:New("722323") --Red
    local RAPPORT_GRADIENT_END = ZO_ColorDef:New("009966") --Green
    local RAPPORT_GRADIENT_MIDDLE = ZO_ColorDef:New("9D840D") --Yellow

    --Grab the rapport controls
    local rapportContainer = control:GetNamedChild("RapportContainer")
    self.rapportBarControl = rapportContainer:GetNamedChild("ProgressBar")
    self.rapportStatusLabel = rapportContainer:GetNamedChild("StatusValue")
    self.rapportDescriptionLabel = rapportContainer:GetNamedChild("Description")

    --Initialize the rapport bar
    self.rapportBar = ZO_SlidingStatusBar:New(self.rapportBarControl)
    self.rapportBar:SetGradientColors(RAPPORT_GRADIENT_START, RAPPORT_GRADIENT_END, RAPPORT_GRADIENT_MIDDLE)
    self.rapportBar:SetMinMax(GetMinimumRapport(), GetMaximumRapport())

    --Initialize the dropdown control
    self.outfitContainer = control:GetNamedChild("Outfit")
    self.outfitDropdown = ZO_ComboBox_ObjectFromContainer(self.outfitContainer:GetNamedChild("Dropdown"))

    EVENT_MANAGER:RegisterForEvent("ZO_CompanionOverview_Keyboard", EVENT_COMPANION_RAPPORT_UPDATE, function(eventId, ...) self:RefreshCompanionRapport(...) end)

    -- fragment
    COMPANION_OVERVIEW_KEYBOARD_FRAGMENT = ZO_FadeSceneFragment:New(control)
    COMPANION_OVERVIEW_KEYBOARD_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_FRAGMENT_SHOWING then
            if HasActiveCompanion() then
                if not self.initialized then
                    self.initialized = true
                    self:OnDeferredInitialize()
                end
                self.levelBar:OnShowing()
                self:RefreshCompanionRapport()
                self:RefreshPassivePerk()
                --Order matters
                ACTION_BAR_ASSIGNMENT_MANAGER:SetHotbarCycleOverride(HOTBAR_CATEGORY_COMPANION)
                self.readOnlyActionBar:RefreshAllButtons()
            end
        elseif newState == SCENE_HIDING then
            if self.pendingEquipOutfitIndex ~= ZO_OUTFIT_MANAGER:GetEquippedOutfitIndex(GAMEPLAY_ACTOR_CATEGORY_COMPANION) then
                if self.pendingEquipOutfitIndex then
                    ZO_OUTFIT_MANAGER:EquipOutfit(GAMEPLAY_ACTOR_CATEGORY_COMPANION, self.pendingEquipOutfitIndex)
                else
                    ZO_OUTFIT_MANAGER:UnequipOutfit(GAMEPLAY_ACTOR_CATEGORY_COMPANION)
                end
            end
            ITEM_PREVIEW_KEYBOARD:ClearPreviewCollection()
            ApplyChangesToPreviewCollectionShown()
        elseif newState == SCENE_FRAGMENT_HIDDEN then
            ACTION_BAR_ASSIGNMENT_MANAGER:SetHotbarCycleOverride(nil)
        end
    end)
end

function ZO_CompanionOverview_Keyboard:OnDeferredInitialize()
    self:InitializeOutfitDropdown()
end

function ZO_CompanionOverview_Keyboard:InitializeOutfitDropdown()
    self.pendingEquipOutfitIndex = ZO_OUTFIT_MANAGER:GetEquippedOutfitIndex(GAMEPLAY_ACTOR_CATEGORY_COMPANION)
    self.outfitDropdown:SetSortsItems(false)

    local function OnEquippedOutfit()
        self.pendingEquipOutfitIndex = ZO_OUTFIT_MANAGER:GetEquippedOutfitIndex(GAMEPLAY_ACTOR_CATEGORY_COMPANION)
        self:UpdateOutfitDropdownSelection()
    end

    local function OnRefreshOutfits()
        self:UpdateOutfitDropdownOutfits()
    end

    OnRefreshOutfits()

    ZO_OUTFIT_MANAGER:RegisterCallback("RefreshEquippedOutfitIndex", OnEquippedOutfit)
    ZO_OUTFIT_MANAGER:RegisterCallback("RefreshOutfits", OnRefreshOutfits)
    ZO_OUTFIT_MANAGER:RegisterCallback("RefreshOutfitName", OnRefreshOutfits)
end

function ZO_CompanionOverview_Keyboard:UpdateOutfitDropdownSelection()
    local IGNORE_CALLBACK = true
    local equippedOutfitIndex = ZO_OUTFIT_MANAGER:GetEquippedOutfitIndex(GAMEPLAY_ACTOR_CATEGORY_COMPANION)
    local itemEntries = self.outfitDropdown:GetItems()
    for i, entry in ipairs(itemEntries) do
        if equippedOutfitIndex == entry.outfitIndex then
            self.outfitDropdown:SelectItem(entry, IGNORE_CALLBACK)
            break
        end
    end
end

function ZO_CompanionOverview_Keyboard:UpdateOutfitDropdownOutfits()
    self.outfitDropdown:ClearItems()

    local function OnUnequipOutfitSelected()
        self.pendingEquipOutfitIndex = UNEQUIP_OUTFIT
        if HasActiveCompanion() and COMPANION_OVERVIEW_KEYBOARD_FRAGMENT:IsShowing() then
            ITEM_PREVIEW_KEYBOARD:PreviewUnequipOutfit(GAMEPLAY_ACTOR_CATEGORY_COMPANION)
        end
    end
    
    local function OnOutfitEntrySelected(_, _, entry)
        self.pendingEquipOutfitIndex = entry.outfitIndex
        if HasActiveCompanion() and COMPANION_OVERVIEW_KEYBOARD_FRAGMENT:IsShowing() then
            ITEM_PREVIEW_KEYBOARD:PreviewOutfit(GAMEPLAY_ACTOR_CATEGORY_COMPANION, entry.outfitIndex)
        end
    end

    local unequippedOutfitEntry = self.outfitDropdown:CreateItemEntry(GetString(SI_NO_OUTFIT_EQUIP_ENTRY), OnUnequipOutfitSelected)
    self.outfitDropdown:AddItem(unequippedOutfitEntry, ZO_COMBOBOX_SUPPRESS_UPDATE)

    local equippedOutfitIndex = ZO_OUTFIT_MANAGER:GetEquippedOutfitIndex(GAMEPLAY_ACTOR_CATEGORY_COMPANION)
    local defaultEntry = unequippedOutfitEntry

    local numOutfits = ZO_OUTFIT_MANAGER:GetNumOutfits(GAMEPLAY_ACTOR_CATEGORY_COMPANION)
    for outfitIndex = 1, numOutfits do
        local outfitManipulator = ZO_OUTFIT_MANAGER:GetOutfitManipulator(GAMEPLAY_ACTOR_CATEGORY_COMPANION, outfitIndex)
        local entry = self.outfitDropdown:CreateItemEntry(outfitManipulator:GetOutfitName(), OnOutfitEntrySelected)
        entry.outfitIndex = outfitIndex
        self.outfitDropdown:AddItem(entry, ZO_COMBOBOX_SUPPRESS_UPDATE)
        if equippedOutfitIndex == outfitIndex then
            defaultEntry = entry
        end
    end

    self.outfitDropdown:UpdateItems()
    self.outfitDropdown:SelectItem(defaultEntry)
end

function ZO_CompanionOverview_Keyboard:RefreshCompanionRapport()
    if HasActiveCompanion() and COMPANION_OVERVIEW_KEYBOARD_FRAGMENT:IsShowing() then
        --Grab the rapport value, level, and description for the active companion
        local rapportValue = GetActiveCompanionRapport()
        local rapportLevel = GetActiveCompanionRapportLevel()
        local rapportDescription = GetActiveCompanionRapportLevelDescription(rapportLevel)

        self.rapportBar:SetValue(rapportValue)
        self.rapportStatusLabel:SetText(GetString("SI_COMPANIONRAPPORTLEVEL", rapportLevel))
        self.rapportDescriptionLabel:SetText(rapportDescription)
    end
end

function ZO_CompanionOverview_Keyboard:RefreshPassivePerk()
    if HasActiveCompanion() and COMPANION_OVERVIEW_KEYBOARD_FRAGMENT:IsShowing() then
        local passiveAbilityId = ZO_COMPANION_MANAGER:GetActiveCompanionPassivePerkAbilityId()
        if self.passiveAbilityId ~= passiveAbilityId then
            self.passiveAbilityId = passiveAbilityId
            local formattedPassivePerkName = ZO_CachedStrFormat(SI_ABILITY_NAME, GetAbilityName(passiveAbilityId))
            self.passivePerkLabel:SetText(formattedPassivePerkName)
        end
    end
end

function ZO_CompanionOverview_Keyboard:PassivePerk_OnMouseEnter(control)
    if self.passiveAbilityId then
        InitializeTooltip(AbilityTooltip, control, RIGHT, -5, 0, LEFT)
        AbilityTooltip:SetAbilityId(self.passiveAbilityId)
    end
end

function ZO_CompanionOverview_Keyboard:PassivePerk_OnMouseExit(control)
    ClearTooltip(AbilityTooltip)
end

-----------------------------
-- Global XML Functions
-----------------------------

function ZO_CompanionOverview_Keyboard_OnInitialize(control)
    COMPANION_OVERVIEW_KEYBOARD = ZO_CompanionOverview_Keyboard:New(control)
end

function ZO_CompanionOverview_Keyboard_PassivePerk_OnMouseEnter(self)
    COMPANION_OVERVIEW_KEYBOARD:PassivePerk_OnMouseEnter(self)
end

function ZO_CompanionOverview_Keyboard_PassivePerk_OnMouseExit(self)
    COMPANION_OVERVIEW_KEYBOARD:PassivePerk_OnMouseExit(self)
end
