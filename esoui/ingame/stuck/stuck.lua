local Stuck = ZO_Stuck_Base:Subclass()

function Stuck:New(...)
    return ZO_Stuck_Base.New(self, ...)
end

function Stuck:Initialize(...)
    ZO_Stuck_Base.Initialize(self, ...)
end

function Stuck:ShowConfirmDialog()
    local warn = true    

    if(CanUseStuck(warn)) then

        local cost = zo_min(GetRecallCost(), GetCarriedCurrencyAmount(CURT_MONEY))

        if DoesCurrentZoneHaveTelvarStoneBehavior() then
            ZO_Dialogs_ShowDialog("CONFIRM_STUCK_WITH_TELVAR_COST", nil, { mainTextParams = { cost, zo_iconFormat("EsoUI/Art/currency/currency_gold.dds", 16, 16), zo_floor(GetTelvarStonePercentLossOnNonPvpDeath() * 100) } } )
        else
            ZO_Dialogs_ShowDialog("CONFIRM_STUCK", nil, { mainTextParams = { cost, zo_iconFormat("EsoUI/Art/currency/currency_gold.dds", 16, 16) } } )
        end
    end
end

function Stuck:ShowFixingDialog()
    ZO_Dialogs_ShowDialog("FIXING_STUCK")
end

function Stuck:HideFixingDialog()
    ZO_Dialogs_ReleaseDialog("FIXING_STUCK")
end

--Events

function Stuck:OnPlayerActivated()
    if(IsStuckFixPending()) then
        self:ShowFixingDialog()
    end
end

function Stuck:OnStuckBegin()
    self:ShowFixingDialog()
end

function Stuck:OnStuckCanceled()
    self:HideFixingDialog()
end

function Stuck:OnStuckComplete()
    self:HideFixingDialog()
end

-- handling these to technically handle every stuck event if functionality is desired later, but PC informs the user via the chat window / C++ code
function Stuck:OnStuckErrorAlreadyInProgress()
end

function Stuck:OnStuckErrorInvalidLocation()
end

function Stuck:OnStuckErrorInCombat()
end

function Stuck:OnStuckErrorOnCooldown()
end

STUCK = Stuck:New()
SYSTEMS:RegisterKeyboardObject(ZO_STUCK_NAME, STUCK)