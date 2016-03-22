local BOUNTY_DISPLAY_UPDATE_DELAY_SECONDS = 1

ZO_BountyDisplay = ZO_Object:Subclass()

function ZO_BountyDisplay:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_BountyDisplay:Initialize(control, isGamepad)
    -- Initialize state
    self.nextUpdateTime = 0
    self.currencyOptions = 
    {
        showTooltips = true,
        customTooltip = SI_STATS_BOUNTY_LABEL,
        font = isGamepad and "ZoFontGamepadHeaderDataValue" or "ZoFontGameLargeBold",
        isGamepad = isGamepad,
        iconSide = RIGHT,
    }   

    -- Set up controls
    self.control = control

    local function UpdateBounty()
        self:OnBountyUpdated()
    end

    control:RegisterForEvent(EVENT_JUSTICE_BOUNTY_PAYOFF_AMOUNT_UPDATED, UpdateBounty)

    control:SetHandler("OnUpdate", function(_, time) self:Update(time) end)

    if IsJusticeEnabled() then
        self.control:SetHidden(false)
        self:OnBountyUpdated()
    else
        self.control:SetHidden(true)
    end
end

function ZO_BountyDisplay:Update(time)
    if self.nextUpdateTime <= time then
        self.nextUpdateTime = time + BOUNTY_DISPLAY_UPDATE_DELAY_SECONDS
        self:OnBountyUpdated()
    end
end

function ZO_BountyDisplay:OnBountyUpdated()
    if IsJusticeEnabled() then
        ZO_CurrencyControl_SetSimpleCurrency(self.control, CURT_MONEY, GetFullBountyPayoffAmount(), self.currencyOptions, CURRENCY_SHOW_ALL, true) 
    end
end