local AUTO_CLOSE_MS = 1 * 60 * 1000

ZO_BriefHudTutorial = ZO_TutorialHandlerBase:Subclass()

function ZO_BriefHudTutorial:Initialize(parent)    
    self.tutorial = CreateControlFromVirtual(parent:GetName(), parent, "ZO_BriefHudTutorialTip", "BriefHudTip")
    
    local function UpdateDescription()
        local tutorialIndex = self:GetCurrentlyDisplayedTutorialIndex()
        if tutorialIndex then
            local title, description = GetTutorialInfo(tutorialIndex) --Grab the Gamepad/Keyboard binding
            self.tutorial:SetText(zo_strformat(SI_TUTORIAL_FORMATTER, description))
        end
    end

    local function UpdateTemplate()
        UpdateDescription()
        if IsInGamepadPreferredMode() then
            self.tutorial:SetWidth(850)
            self.tutorial:SetFont("ZoFontGamepad42")
            self.tutorial:ClearAnchors()
            self.tutorial:SetAnchor(BOTTOM, nil, BOTTOM, 0, ZO_COMMON_INFO_DEFAULT_GAMEPAD_BOTTOM_OFFSET_Y)
        else
            self.tutorial:SetWidth(650)
            self.tutorial:SetFont("ZoInteractionPrompt")
            self.tutorial:ClearAnchors()
            self.tutorial:SetAnchor(BOTTOM, nil, BOTTOM, 0, ZO_COMMON_INFO_DEFAULT_KEYBOARD_BOTTOM_OFFSET_Y)
        end
    end

    self.tutorial:RegisterForEvent(EVENT_GAMEPAD_PREFERRED_MODE_CHANGED, UpdateTemplate)
    --in case the player changes the keybind or resets to default while a tutorial is up.
    self.tutorial:RegisterForEvent(EVENT_KEYBINDING_SET, UpdateDescription)
    self.tutorial:RegisterForEvent(EVENT_KEYBINDINGS_LOADED, UpdateDescription)
    
    self.tutorialAnimation = ANIMATION_MANAGER:CreateTimelineFromVirtual("HudBriefTutorialAnimation", self.tutorial)
    self.tutorialAnimation:SetHandler("OnStop", function(timeline) 
        if not timeline:IsPlayingBackward() then 
            FireTutorialHiddenEvent(self.tutorialIndex)
            SHARED_INFORMATION_AREA:SetHidden(self.tutorial, true) 
        end 
    end)

    EVENT_MANAGER:RegisterForUpdate(self.tutorial:GetName() .. "OnUpdate", 0, function() self:OnUpdate() end)
    EVENT_MANAGER:RegisterForEvent("BriefHudTutorial", EVENT_PLAYER_DEAD, function() self:ClearAll() end)

    SHARED_INFORMATION_AREA:AddTutorial(self.tutorial)

    UpdateTemplate()
    self:ClearAll()
end

function ZO_BriefHudTutorial:SetHidden(hide)
    self.tutorial:SetHidden(hide)
end

function ZO_BriefHudTutorial:GetTutorialType()
    return TUTORIAL_TYPE_HUD_BRIEF
end

function ZO_BriefHudTutorial:SuppressTutorials(suppress, reason)
    -- Suppression is disabled since we're potentially disabling 
    -- input so the player ought to know why
end

function ZO_BriefHudTutorial:DisplayTutorial(tutorialIndex)
    self.tutorialIndex = tutorialIndex
    local title, description = GetTutorialInfo(tutorialIndex)
    SetTutorialSeen(tutorialIndex)
    self.tutorial:SetText(zo_strformat(SI_TUTORIAL_FORMATTER, description))
    self.tutorialAnimation:PlayBackward()
    self:SetCurrentlyDisplayedTutorialIndex(tutorialIndex)

    self.displayedTutorialIsActionRequired = IsTutorialActionRequired(tutorialIndex)
    self.currentlyDisplayedTutorialTimeLeft = (not self.displayedTutorialIsActionRequired) and AUTO_CLOSE_MS

    SHARED_INFORMATION_AREA:SetHidden(self.tutorial, false)
end

function ZO_BriefHudTutorial:OnDisplayTutorial(tutorialIndex, priority)
     if tutorialIndex ~= self:GetCurrentlyDisplayedTutorialIndex() then
        if not self:CanShowTutorial() then
            self:ClearAll()
        end
        self:DisplayTutorial(tutorialIndex)
    end
end

function ZO_BriefHudTutorial:RemoveTutorial(tutorialIndex)
    if self:GetCurrentlyDisplayedTutorialIndex() == tutorialIndex then
        if self.displayedTutorialIsActionRequired then
            self.displayedTutorialIsActionRequired = nil
        end

        self:SetCurrentlyDisplayedTutorialIndex(nil)
        self.currentlyDisplayedTutorialTimeLeft = nil
        self.tutorialAnimation:PlayForward()
    end
end

function ZO_BriefHudTutorial:OnUpdate()
    if self.displayedTutorialIsActionRequired then return end

    local now = GetFrameTimeMilliseconds()
    local delta = now - (self.lastUpdate or now)

    if self:GetCurrentlyDisplayedTutorialIndex() and not self.tutorial:IsHidden() then
        self.currentlyDisplayedTutorialTimeLeft = self.currentlyDisplayedTutorialTimeLeft - delta
        if self.currentlyDisplayedTutorialTimeLeft < 0 then
            self:RemoveTutorial(self:GetCurrentlyDisplayedTutorialIndex())
        end
    end

    self.lastUpdate = now
end

function ZO_BriefHudTutorial:ClearAll()
    self:SetCurrentlyDisplayedTutorialIndex(nil)
    self.currentlyDisplayedTutorialTimeLeft = nil
    self.tutorialAnimation:PlayForward()

    if self.displayedTutorialIsActionRequired then
        self.displayedTutorialIsActionRequired = nil
        ClearActiveActionRequiredTutorial()        
    end

    self.queue = {}
end