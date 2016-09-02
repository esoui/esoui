ZO_CrownCratePrototypes = ZO_Object:Subclass()

function ZO_CrownCratePrototypes:New(...)
    local obj = ZO_Object.New(self)
    obj:Initialize(...)
    return obj
end

function ZO_CrownCratePrototypes:Initialize(control)
    self.control = control
end

function ZO_CrownCratePrototypes:PrimaryDeal()
    CROWN_CRATES:LockLocalSpaceToCurrentCamera()
    CROWN_CRATES_PACK_OPENING:ResetCards()
    CROWN_CRATES_PACK_OPENING:StartPrimaryDealAnimation(1, 0, 3)
    self.nextCardToReveal = 1
end

function ZO_CrownCratePrototypes:BonusDeal()
    CROWN_CRATES_PACK_OPENING:StartBonusDealAnimation(1, 0, 3)
end

function ZO_CrownCratePrototypes:MysterySelect()
    local card = CROWN_CRATES_PACK_OPENING:GetCardInVisualOrder(self.nextCardToReveal)
    card:MysterySelect()
end

function ZO_CrownCratePrototypes:MysteryDeselect()
    local card = CROWN_CRATES_PACK_OPENING:GetCardInVisualOrder(self.nextCardToReveal)
    card:MysteryDeselect()
end

function ZO_CrownCratePrototypes:Reveal()
    local card = CROWN_CRATES_PACK_OPENING:GetCardInVisualOrder(self.nextCardToReveal)
    card:Reveal()
    self.nextCardToReveal = self.nextCardToReveal + 1
end

function ZO_CrownCratePrototypes:Leave()
    CROWN_CRATES_PACK_OPENING:StartLeaveAnimation()
end

function ZO_CrownCratePrototypes:ShowManifest()
    CROWN_CRATES:LockLocalSpaceToCurrentCamera()
    CROWN_CRATES_PACK_CHOOSING:ResetPacks()
    CROWN_CRATES_PACK_CHOOSING:Show()
end

function ZO_CrownCratePrototypes:ChooseFirstFromManifest()
    CROWN_CRATES_PACK_CHOOSING:Choose(CROWN_CRATES_PACK_CHOOSING:GetPack(1))
end

--Global XML

function ZO_CrownCratePrototype_OnInitialized(self)
    CROWN_CRATE_PROTOTYPE = ZO_CrownCratePrototypes:New(self)
end