--------------------------
--Tribute Mechanic Card --
--------------------------

ZO_TributeMechanicCard = ZO_InitializingObject:Subclass()

function ZO_TributeMechanicCard:Initialize(control, mechanicIndex)
    control.object = self
    self.control = control
    self.background = control:GetNamedChild("Bg")
    self.glow = self.background:GetNamedChild("Glow")
    self.mechanicText = control:GetNamedChild("Text")
    self.mechanicIndex = mechanicIndex
    local fonts =
    {
        {
            font = "ZoFontTributeAntique40",
            lineLimit = 5,
        },
        {
            font = "ZoFontTributeAntique30",
            lineLimit = 7,
        },
        {
            font = "ZoFontTributeAntique20",
            lineLimit = 10,
        },
    }
    ZO_FontAdjustingWrapLabel_OnInitialized(self.mechanicText, fonts, TEXT_WRAP_MODE_ELLIPSIS)
    self:Reset()
end

do
    local PREPEND_ICON = true
    function ZO_TributeMechanicCard:AttachCardData(cardData)
        self.cardData = cardData
        --Only show cards that have valid mechanics for the index they represent
        if self:HasValidMechanic() then
            self.control:SetHidden(false)
            local mechanicText = self.cardData:GetMechanicText(TRIBUTE_MECHANIC_ACTIVATION_SOURCE_ACTIVATION, self.mechanicIndex, PREPEND_ICON)
            self.mechanicText:SetText(mechanicText)
        end
    end
end

function ZO_TributeMechanicCard:SetHighlighted(isHighlighted)
    if isHighlighted ~= self.isHighlighted then
        self.isHighlighted = isHighlighted
        self.glow:SetHidden(not self.isHighlighted)
    end
end

function ZO_TributeMechanicCard:HasValidMechanic()
    if self.cardData then
        return self.mechanicIndex <= self.cardData:GetNumMechanics(TRIBUTE_MECHANIC_ACTIVATION_SOURCE_ACTIVATION)
    end
    return false
end

function ZO_TributeMechanicCard:Reset()
    self.control:SetHidden(true)
    self:SetHighlighted(false)
    self.cardData = nil
end

function ZO_TributeMechanicCard:GetControl()
    return self.control
end

function ZO_TributeMechanicCard:GetMechanicIndex()
    return self.mechanicIndex
end

function ZO_TributeMechanicCard:OnMouseUp(button, upInside)
    if not IsInGamepadPreferredMode() and button == MOUSE_BUTTON_INDEX_LEFT and upInside then
        TributeChooseMechanic(self.mechanicIndex)
        PlaySound(SOUNDS.TRIBUTE_MECHANIC_CHOSEN)
    end
end

function ZO_TributeMechanicCard:OnMouseEnter()
    if not IsInGamepadPreferredMode() then
        self:SetHighlighted(true)
    end
end

function ZO_TributeMechanicCard:OnMouseExit()
    if not IsInGamepadPreferredMode() then
        self:SetHighlighted(false)
    end
end

------------------------------
--Tribute Mechanic Selector --
------------------------------

ZO_TributeMechanicSelector = ZO_TributeViewer_Manager_Base:Subclass()

function ZO_TributeMechanicSelector:Initialize(control)
    --Order matters. Set self.control before calling the base class initialize
    self.control = control
    ZO_TributeViewer_Manager_Base.Initialize(self)

    TRIBUTE_MECHANIC_SELECTOR_FRAGMENT = ZO_FadeSceneFragment:New(control)
    TRIBUTE_MECHANIC_SELECTOR_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_FRAGMENT_SHOWING then
            self:DeferredInitialize()
            self.focus:SetFocusByIndex(1)
        elseif newState == SCENE_FRAGMENT_SHOWN then
            KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
            if IsInGamepadPreferredMode() then
                self.focus:Activate()
            end
        elseif newState == SCENE_FRAGMENT_HIDING then
            self.focus:Deactivate()
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
        end
    end)
end

function ZO_TributeMechanicSelector:DeferredInitialize()
    if not self.initialized then
        self:InitializeControls()
        self:InitializeKeybindStripDescriptors()
        self:SetupFocus()

        self.initialized = true
    end
end

function ZO_TributeMechanicSelector:InitializeControls()
    self.mechanicContainer = self.control:GetNamedChild("MechanicContainer")
    local mechanicCards = {}
    for i = 1, 4 do
        local mechanicControl = self.mechanicContainer:GetNamedChild("Mechanic" .. i)
        table.insert(mechanicCards, ZO_TributeMechanicCard:New(mechanicControl, i))
    end
    self.mechanicCards = mechanicCards
    -- ZoFontTributeAntique40 is a rarely used font, so defer loading it until it's actually becomes necessary
    self.control:GetNamedChild("Instruction"):SetFont("ZoFontTributeAntique40")
end

function ZO_TributeMechanicSelector:InitializeKeybindStripDescriptors()
    self.keybindStripDescriptor = 
    {
        {
            --Ethereal binds show no text, the name field is used to help identify the keybind when debugging. This text does not have to be localized.
            name = "Gamepad Select",
            keybind = "UI_SHORTCUT_PRIMARY",
            ethereal = true,
            enabled = function()
                return IsInGamepadPreferredMode()
            end,
            callback = function()
                local selectedData = self.focus:GetFocusItem()
                local mechanicIndex = selectedData.control.object:GetMechanicIndex()
                TributeChooseMechanic(mechanicIndex)
                PlaySound(SOUNDS.TRIBUTE_MECHANIC_CHOSEN)
            end,
        },
        {
            --Ethereal binds show no text, the name field is used to help identify the keybind when debugging. This text does not have to be localized.
            name = "Cancel Move",
            keybind = "UI_SHORTCUT_EXIT",
            ethereal = true,
            enabled = function()
                return TributeCanCancelCurrentMove()
            end,
            callback = function()
                TributeCancelCurrentMove()
            end,
        },
    }
end

function ZO_TributeMechanicSelector:RegisterForEvents(systemName)
    ZO_TributeViewer_Manager_Base.RegisterForEvents(self, systemName)
    local control = self.control

    control:RegisterForEvent(EVENT_TRIBUTE_BEGIN_MECHANIC_SELECTION, function(_, cardInstanceId)
        self:DeferredInitialize()
        local cardDefId, patronDefId = GetTributeCardInstanceDefIds(cardInstanceId)
        self:OnBeginMechanicSelection(patronDefId, cardDefId)
    end)

    control:RegisterForEvent(EVENT_TRIBUTE_END_MECHANIC_SELECTION, function()
        self:Hide()
    end)
end

function ZO_TributeMechanicSelector:SetupFocus()
    self.focus = ZO_GamepadFocus:New(self.mechanicContainer, nil, MOVEMENT_CONTROLLER_DIRECTION_HORIZONTAL)
    for _, mechanic in ipairs(self.mechanicCards) do
        local focusEntry =
        {
            control = mechanic:GetControl(),
            canFocus = function() return mechanic:HasValidMechanic() end,
            activate = function() mechanic:SetHighlighted(true) end,
            deactivate = function() mechanic:SetHighlighted(false) end,
        }
        self.focus:AddEntry(focusEntry)
    end
    self.focus:SetFocusByIndex(1)
end

function ZO_TributeMechanicSelector:OnBeginMechanicSelection(patronDefId, cardDefId)
    self.cardData = ZO_TributeCardData:New(patronDefId, cardDefId)
    self:RefreshAll()
    self:Show()
end

function ZO_TributeMechanicSelector:Show()
    self:FireActivationStateChanged()
    SCENE_MANAGER:AddFragment(TRIBUTE_MECHANIC_SELECTOR_FRAGMENT)
end

function ZO_TributeMechanicSelector:Hide()
    --Order matters. Make sure we clear the card data before firing the activation state changed
    self.cardData = nil
    self:FireActivationStateChanged()
    SCENE_MANAGER:RemoveFragment(TRIBUTE_MECHANIC_SELECTOR_FRAGMENT)
end

function ZO_TributeMechanicSelector:RefreshAll()
    for _, mechanic in ipairs(self.mechanicCards) do
        mechanic:Reset()
        mechanic:AttachCardData(self.cardData)
    end
end

-- Required Overrides

function ZO_TributeMechanicSelector:GetSystemName()
    return "TributeMechanicSelector"
end

function ZO_TributeMechanicSelector:OnGamepadPreferredModeChanged()
    --No need to do anything if the screen isn't up in the first place
    if TRIBUTE_MECHANIC_SELECTOR_FRAGMENT:IsShowing() then
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
        self:RefreshAll()
        if IsInGamepadPreferredMode() then
            self.focus:Activate()
        else
            self.focus:Deactivate()
        end
    end
end

--The mechanic selector does not have functionality for viewing the board while it's open
function ZO_TributeMechanicSelector:IsViewingBoard()
    return false
end

function ZO_TributeMechanicSelector:IsActive()
    return self.cardData ~= nil
end

--The mechanic selector does not have a visible keybind strip
function ZO_TributeMechanicSelector:IsKeybindStripVisible()
    return false
end

function ZO_TributeMechanicSelector:RequestClose()
    if TributeCanCancelCurrentMove() then
        TributeCancelCurrentMove()
    end
end

-------------------------
-- Global XML Functions
-------------------------

function ZO_TributeMechanicSelector_OnInitialized(control)
    TRIBUTE_MECHANIC_SELECTOR = ZO_TributeMechanicSelector:New(control)
end

function ZO_TributeMechanicSelectorUnderlay_OnMouseUp(control, upInside)
    if not IsInGamepadPreferredMode() and upInside then
        if TributeCanCancelCurrentMove() then
            TributeCancelCurrentMove()
        end
    end
end