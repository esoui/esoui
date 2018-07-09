ZO_GiftInventoryView_Keyboard = ZO_GiftInventoryView_Shared:Subclass()

function ZO_GiftInventoryView_Keyboard:New(...)
    return ZO_GiftInventoryView_Shared.New(self, ...)
end

function ZO_GiftInventoryView_Keyboard:Initialize(control)
    ZO_GiftInventoryView_Shared.Initialize(self, control, "giftInventoryViewKeyboard")

    SYSTEMS:RegisterKeyboardObject("giftInventoryView", self)

    local CLAIM_GIFT_KEYBIND = "UI_SHORTCUT_PRIMARY"
    local PREVIEW_GIFT_KEYBIND = "UI_SHORTCUT_TERTIARY"
    local DECLINE_GIFT_KEYBIND = "UI_SHORTCUT_NEGATIVE"
    self:InitializeKeybinds(CLAIM_GIFT_KEYBIND, PREVIEW_GIFT_KEYBIND, DECLINE_GIFT_KEYBIND)
end

-- Begin ZO_GiftInventoryView_Shared Overrides --

function ZO_GiftInventoryView_Keyboard:InitializeControls()
    ZO_GiftInventoryView_Shared.InitializeControls(self)

    ZO_Scroll_Initialize(self.noteContainer)

    local r, g, b = ZO_OFF_WHITE:UnpackRGB()
    self.overlayGlowControl:SetEdgeColor(r, g, b)
    self.overlayGlowControl:SetCenterColor(r, g, b)

    local headerIcon = self.control:GetNamedChild("HeaderIcon")
    headerIcon:SetHandler("OnMouseUp", function(control, button, upInside)
        if button == MOUSE_BUTTON_INDEX_LEFT and upInside then
            self.blastParticleSystem:Stop()
            self.blastParticleSystem:Start()
        end
    end)

    self.giftFrame = self.giftContainer:GetNamedChild("Frame")
end

function ZO_GiftInventoryView_Keyboard:InitializeParticleSystems()
    ZO_GiftInventoryView_Shared.InitializeParticleSystems(self)
    
    local blastParticleSystem = self.blastParticleSystem
    blastParticleSystem:SetParticleParameter("PhysicsInitialVelocityMagnitude", ZO_UniformRangeGenerator:New(700, 1100))
    blastParticleSystem:SetParticleParameter("Size", ZO_UniformRangeGenerator:New(6, 12))
    blastParticleSystem:SetParticleParameter("PhysicsDragMultiplier", 1.5)
    blastParticleSystem:SetParticleParameter("PrimeS", .5)

    local headerSparksParticleSystem = self.headerSparksParticleSystem
    headerSparksParticleSystem:SetParentControl(self.control:GetNamedChild("HeaderFade"))
    headerSparksParticleSystem:SetParticleParameter("PhysicsInitialVelocityMagnitude", ZO_UniformRangeGenerator:New(15, 60))
    headerSparksParticleSystem:SetParticleParameter("Size", ZO_UniformRangeGenerator:New(5, 10))
    headerSparksParticleSystem:SetParticleParameter("DrawLayer", DL_OVERLAY)
    headerSparksParticleSystem:SetParticleParameter("DrawLevel", 2)

    local headerStarbustParticleSystem = self.headerStarbustParticleSystem
    headerStarbustParticleSystem:SetParentControl(self.control:GetNamedChild("HeaderFade"))
    headerStarbustParticleSystem:SetParticleParameter("Size", 256)
    headerStarbustParticleSystem:SetParticleParameter("DrawLayer", DL_OVERLAY)
    headerStarbustParticleSystem:SetParticleParameter("DrawLevel", 1)
end

function ZO_GiftInventoryView_Keyboard:InitializeKeybinds(...)
    ZO_GiftInventoryView_Shared.InitializeKeybinds(self, ...)

    table.insert(self.keybindStripDescriptor,
    -- Custom Exit
    {
        alignment = KEYBIND_STRIP_ALIGN_RIGHT,
        name = GetString(SI_EXIT_BUTTON),
        keybind = "UI_SHORTCUT_EXIT",
        callback = function()
            SCENE_MANAGER:HideCurrentScene()
        end,
    })
end

function ZO_GiftInventoryView_Keyboard:ShowClaimGiftDialog()
    ZO_Dialogs_ShowDialog("CONFIRM_CLAIM_GIFT_KEYBOARD", self.gift)
end

function ZO_GiftInventoryView_Keyboard:ShowClaimGiftNoticeDialog(noticeText, helpCategoryIndex, helpIndex)
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
    ZO_Dialogs_ShowDialog("CLAIM_GIFT_NOTICE_KEYBOARD", dialogData, textParams)
end

function ZO_GiftInventoryView_Keyboard:DeclineGift()
    if self:IsReceivedGift() then
        ZO_Dialogs_ShowDialog("CONFIRM_RETURN_GIFT_KEYBOARD", self.gift)
    else
        ZO_Dialogs_ShowDialog("CONFIRM_DELETE_GIFT_KEYBOARD", self.gift)
    end
end

function ZO_GiftInventoryView_Keyboard:GetItemPreviewListHelper()
    return ITEM_PREVIEW_LIST_HELPER_KEYBOARD
end

function ZO_GiftInventoryView_Keyboard:ShowTooltip(control)
    InitializeTooltip(ItemTooltip, self.giftFrame, RIGHT, -10, 0, LEFT)
    ItemTooltip:SetMarketProduct(self.gift:GetMarketProductId())
end

-- End ZO_GiftInventoryView_Shared Overrides --

-- Begin Global XML Functions --

function ZO_GiftInventoryView_KeyboardGiftFrame_OnMouseEnter(control)
    GIFT_INVENTORY_VIEW_KEYBOARD:ShowTooltip()
end

function ZO_GiftInventoryView_KeyboardGiftFrame_OnMouseExit(control)
    ClearTooltip(ItemTooltip)
end

function ZO_GiftInventoryView_Keyboard_OnInitialized(control)
    GIFT_INVENTORY_VIEW_KEYBOARD = ZO_GiftInventoryView_Keyboard:New(control)
end

-- End Global XML Functions --