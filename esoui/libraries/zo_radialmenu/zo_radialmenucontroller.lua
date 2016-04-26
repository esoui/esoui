--[[
    Radial Menu Controller Base class, requires the control passed in to have a child radial menu named "Menu".
    Does basic initialization and provides callbacks / function overrides to populate the menu and interact with it.
  ]]

ZO_RadialMenuController = ZO_Object:Subclass()

function ZO_RadialMenuController:New(...)
    local radial = ZO_Object.New(self)
    radial:Initialize(...)
    return radial
end

function ZO_RadialMenuController:Initialize(control, entryTemplate, animationTemplate, entryAnimationTemplate)
    self.menuControl = control:GetNamedChild("Menu")
    self.menu = ZO_RadialMenu:New(self.menuControl, entryTemplate, animationTemplate, entryAnimationTemplate, "RadialMenu")

    local function SetupEntryControl(entryControl, data)
        self:SetupEntryControl(entryControl, data)
    end

    local function OnSelectionChangedCallback(selectedEntry)
        self:OnSelectionChangedCallback(selectedEntry)
    end

    self.menu:SetCustomControlSetUpFunction(SetupEntryControl)
    self.menu:SetOnSelectionChangedCallback(OnSelectionChangedCallback)
end

function ZO_RadialMenuController:ShowMenu()
    self.menu:Clear()
    self:PopulateMenu()
    self.menu:Show()
end

--override
function ZO_RadialMenuController:SetupEntryControl(control, data)
    -- Should be Overridden
end

function ZO_RadialMenuController:OnSelectionChangedCallback(selectedEntry)
    -- Should be Overridden
end

function ZO_RadialMenuController:PopulateMenu()
    -- Should be Overridden
end


--[[
    Interactive Radial Menu Controller. This is the base class to use for in-game radial menus tied to keybinds where the user holds down a key/button to
    bring up the radial menu for use.  Releasing the key/button that opened the menu will close the menu and select the currently selected entry.
  ]]

local TIME_TO_HOLD_KEY_MS = 250

ZO_InteractiveRadialMenuController = ZO_RadialMenuController:Subclass()

function ZO_InteractiveRadialMenuController:New(...)
    return ZO_RadialMenuController.New(self, ...)
end

function ZO_InteractiveRadialMenuController:Initialize(control, entryTemplate, animationTemplate, entryAnimationTemplate )
    ZO_RadialMenuController.Initialize(self, control, entryTemplate, animationTemplate, entryAnimationTemplate)

    control:SetHandler("OnUpdate", function() self:OnUpdate() end)
    self.menu:SetOnClearCallback(function() self:StopInteraction() end)
end

function ZO_InteractiveRadialMenuController:StartInteraction()
    if not self.isInteracting and not self.beginHold then
        if self:PrepareForInteraction() then
            self.beginHold = GetFrameTimeMilliseconds()
            return true
        end
    end
end

function ZO_InteractiveRadialMenuController:StopInteraction()
    if self.isInteracting then
        self.isInteracting = false

        LockCameraRotation(false)
        RETICLE:RequestHidden(false)

        self.menu:SelectCurrentEntry()
    elseif self.beginHold then
        self:InteractionCanceled()
    end
    self.beginHold = nil
end

function ZO_InteractiveRadialMenuController:OnUpdate()
    if self.beginHold and GetFrameTimeMilliseconds() >= self.beginHold + TIME_TO_HOLD_KEY_MS then
        self.beginHold = nil
        if not self.isInteracting then
            self:ShowMenu()
        end
    end

    if self.isInteracting and IsInteracting() and GetInteractionType() ~= INTERACTION_HIDEYHOLE then
        self:StopInteraction()
    end
end

function ZO_InteractiveRadialMenuController:ShowMenu()
    ZO_RadialMenuController.ShowMenu(self)

    self.isInteracting = true
    LockCameraRotation(true)
    RETICLE:RequestHidden(true)
end

--override
function ZO_InteractiveRadialMenuController:PrepareForInteraction()
    return true
end

function ZO_InteractiveRadialMenuController:SetupEntryControl(control, data)
    -- Should be Overridden
end

function ZO_InteractiveRadialMenuController:OnSelectionChangedCallback(selectedEntry)
    -- Should be Overridden
end

function ZO_InteractiveRadialMenuController:PopulateMenu()
    -- Should be Overridden
end

function ZO_InteractiveRadialMenuController:InteractionCanceled()
    -- Should be Overridden
end