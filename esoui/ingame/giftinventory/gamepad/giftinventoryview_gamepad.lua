ZO_GiftInventoryView_Gamepad = ZO_GiftInventoryView_Shared:Subclass()

function ZO_GiftInventoryView_Gamepad:New(...)
    return ZO_GiftInventoryView_Shared.New(self, ...)
end

function ZO_GiftInventoryView_Gamepad:Initialize(control)
    ZO_GiftInventoryView_Shared.Initialize(self, control, "giftInventoryViewGamepad")
    
    ZO_GIFT_INVENTORY_VIEW_SCENE_GAMEPAD = self:GetScene()
    SYSTEMS:RegisterGamepadObject("giftInventoryView", self)

    local CLAIM_GIFT_KEYBIND = "UI_SHORTCUT_PRIMARY"
    local PREVIEW_GIFT_KEYBIND = "UI_SHORTCUT_SECONDARY"
    local DECLINE_GIFT_KEYBIND = "UI_SHORTCUT_RIGHT_STICK"
    self:InitializeKeybinds(CLAIM_GIFT_KEYBIND, PREVIEW_GIFT_KEYBIND, DECLINE_GIFT_KEYBIND)
end

-- Begin ZO_GiftInventoryView_Shared Overrides --

function ZO_GiftInventoryView_Gamepad:InitializeControls()
    ZO_GiftInventoryView_Shared.InitializeControls(self)

    ZO_Scroll_Initialize_Gamepad(self.noteContainer)
    local scrollIndicator = self.noteContainer:GetNamedChild("ScrollIndicator")
    scrollIndicator:ClearAnchors()
    scrollIndicator:SetAnchor(CENTER, self.noteContainer, RIGHT, 0, 0, ANCHOR_CONSTRAINS_Y)
    scrollIndicator:SetAnchor(CENTER, self.control, RIGHT, 0, 0, ANCHOR_CONSTRAINS_X)
    scrollIndicator:SetDrawLayer(DL_OVERLAY)

    self.overlayGlowControl:SetColor(ZO_OFF_WHITE:UnpackRGB())
end

function ZO_GiftInventoryView_Gamepad:InitializeParticleSystems()
    ZO_GiftInventoryView_Shared.InitializeParticleSystems(self)
    
    local blastParticleSystem = self.blastParticleSystem
    blastParticleSystem:SetParticleParameter("PhysicsInitialVelocityMagnitude", ZO_UniformRangeGenerator:New(700, 1100))
    blastParticleSystem:SetParticleParameter("Size", ZO_UniformRangeGenerator:New(6, 12))
    blastParticleSystem:SetParticleParameter("PhysicsDragMultiplier", 1.5)
    blastParticleSystem:SetParticleParameter("PrimeS", .5)

    local headerSparksParticleSystem = self.headerSparksParticleSystem
    headerSparksParticleSystem:SetParentControl(self.control:GetNamedChild("Header"))
    headerSparksParticleSystem:SetParticleParameter("PhysicsInitialVelocityMagnitude", ZO_UniformRangeGenerator:New(15, 60))
    headerSparksParticleSystem:SetParticleParameter("Size", ZO_UniformRangeGenerator:New(5, 10))
    headerSparksParticleSystem:SetParticleParameter("DrawLayer", DL_OVERLAY)
    headerSparksParticleSystem:SetParticleParameter("DrawLevel", 2)

    local headerStarbustParticleSystem = self.headerStarbustParticleSystem
    headerStarbustParticleSystem:SetParentControl(self.control:GetNamedChild("Header"))
    headerStarbustParticleSystem:SetParticleParameter("Size", 256)
    headerStarbustParticleSystem:SetParticleParameter("DrawLayer", DL_OVERLAY)
    headerStarbustParticleSystem:SetParticleParameter("DrawLevel", 1)
end

function ZO_GiftInventoryView_Gamepad:InitializeKeybinds(...)
    ZO_GiftInventoryView_Shared.InitializeKeybinds(self, ...)

    table.insert(self.keybindStripDescriptor,
    {
        name = GetString(SI_GAMEPAD_GIFT_INVENTORY_VIEW_WINDOW_VIEW_TOOLTIP_KEYBIND),

        keybind = "UI_SHORTCUT_LEFT_SHOULDER",

        order = 1000,

        handlesKeyUp = true,

        callback = function(up)
            if up then
                GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_RIGHT_TOOLTIP)
            else
                GAMEPAD_TOOLTIPS:LayoutMarketProduct(GAMEPAD_RIGHT_TOOLTIP, self.gift:GetMarketProductId())
            end
        end,
    })

    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.keybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON)
end

function ZO_GiftInventoryView_Gamepad:ShowClaimGiftDialog()
    ZO_Dialogs_ShowGamepadDialog("CONFIRM_CLAIM_GIFT_GAMEPAD", { gift = self.gift })
end

function ZO_GiftInventoryView_Gamepad:ShowClaimGiftNoticeDialog(noticeText, helpCategoryIndex, helpIndex)
    local dialogData =
    {
        gift = self.gift,
        helpCategoryIndex = helpCategoryIndex,
        helpIndex = helpIndex,
    }
    local textParams =
    {
        titleParams = { self.gift:GetName() },
        mainTextParams = { noticeText },
    }
    ZO_Dialogs_ShowGamepadDialog("CLAIM_GIFT_NOTICE_GAMEPAD", dialogData, textParams)
end

function ZO_GiftInventoryView_Gamepad:DeclineGift()
    if self:IsReceivedGift() then
        ZO_Dialogs_ShowGamepadDialog("CONFIRM_RETURN_GIFT_GAMEPAD", { gift = self.gift })
    else
        ZO_Dialogs_ShowGamepadDialog("CONFIRM_DELETE_GIFT_GAMEPAD", { gift = self.gift })
    end
end

function ZO_GiftInventoryView_Gamepad:GetItemPreviewListHelper()
    return ITEM_PREVIEW_LIST_HELPER_GAMEPAD
end

-- End ZO_GiftInventoryView_Shared Overrides --

-- Begin Global XML Functions --

function ZO_GiftInventoryView_Gamepad_OnInitialized(control)
    GIFT_INVENTORY_VIEW_GAMEPAD = ZO_GiftInventoryView_Gamepad:New(control)
end

-- End Global XML Functions --