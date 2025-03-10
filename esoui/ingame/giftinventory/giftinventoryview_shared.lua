ZO_GiftInventoryView_Shared = ZO_Object:Subclass()

function ZO_GiftInventoryView_Shared:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_GiftInventoryView_Shared:Initialize(control, sceneName)
    self.control = control
    self.sceneName = sceneName
    self.scene = ZO_Scene:New(sceneName, SCENE_MANAGER)
    self.scene:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWING then
            self:OnShowing()
        elseif newState == SCENE_HIDDEN then
            self:OnHidden()
        end
    end)

    self.fragment = ZO_SimpleSceneFragment:New(control)
    self.scene:AddFragment(self.fragment)

    GIFT_INVENTORY_MANAGER:RegisterCallback("GiftActionResult", function(...) self:OnGiftActionResult(...) end)

    self:InitializeControls()
    self:InitializeParticleSystems()
end

function ZO_GiftInventoryView_Shared:InitializeControls()
    local control = self.control

    self.titleLabel = control:GetNamedChild("Title")
    self.noteLabel = control:GetNamedChild("Note")
    self.giftContainer = control:GetNamedChild("GiftContainer")
    self.giftIconTexture = self.giftContainer:GetNamedChild("Icon")
    self.giftNameLabel = self.giftContainer:GetNamedChild("Name")
    self.giftStackCountLabel = self.giftContainer:GetNamedChild("StackCount")
    self.noteContainer = control:GetNamedChild("NoteContainer")
    local noteScrollChild = self.noteContainer:GetNamedChild("ScrollChild")
    local noteScrollArea = self.noteContainer:GetNamedChild("Scroll")
    self.noteLabel:SetParent(noteScrollChild)
    self.noteLabel:SetAnchor(TOPLEFT, noteScrollChild)
    self.noteLabel:SetWidth(noteScrollArea:GetWidth())
    
    self.overlayGlowControl = self.control:GetNamedChild("OverlayGlow")
    internalassert(self.overlayGlowControl ~= nil)
    self.overlayGlowFadeAnimation = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_GiftInventoryView_OverlayGlowFadeAnimation", self.overlayGlowControl)

    local topLevelwidth, topLevelheight = self.control:GetDimensions()
    local BACKGROUND_PADDING = 8 * 2 -- Padding per edge times num edges
    self.control:SetHandler("OnRectChanged", function(control, newLeft, newTop, newRight, newBottom)
        local newWidth = newRight - newLeft
        local newHeight = newBottom - newTop
        if newWidth ~= topLevelwidth or newHeight ~= topLevelheight then
            self.overlayGlowControl:SetDimensions(newWidth + BACKGROUND_PADDING, newHeight + BACKGROUND_PADDING)
            topLevelwidth = newWidth
            topLevelheight = newHeight
        end
    end)
end

function ZO_GiftInventoryView_Shared:InitializeParticleSystems()
    local particleR, particleG, particleB = ZO_OFF_WHITE:UnpackRGB()

    local blastParticleSystem = ZO_BlastParticleSystem:New()
    blastParticleSystem:SetParentControl(self.control:GetNamedChild("BlastParticlesOrigin"))
    blastParticleSystem:SetParticlesPerSecond(500)
    blastParticleSystem:SetDuration(.2)
    blastParticleSystem:SetSound(SOUNDS.GIFT_INVENTORY_VIEW_FANFARE_BLAST)
    blastParticleSystem:SetParticleParameter("DurationS", ZO_UniformRangeGenerator:New(1.5, 2.5))
    blastParticleSystem:SetParticleParameter("PhysicsAccelerationMagnitude1", 300)
    self.blastParticleSystem = blastParticleSystem

    local headerSparksParticleSystem = ZO_ControlParticleSystem:New(ZO_AnalyticalPhysicsParticle_Control)
    headerSparksParticleSystem:SetParticlesPerSecond(15)
    headerSparksParticleSystem:SetStartPrimeS(1.5)
    headerSparksParticleSystem:SetSound(SOUNDS.GIFT_INVENTORY_VIEW_FANFARE_SPARKS)
    headerSparksParticleSystem:SetParticleParameter("Texture", "EsoUI/Art/PregameAnimatedBackground/ember.dds")
    headerSparksParticleSystem:SetParticleParameter("BlendMode", TEX_BLEND_MODE_ADD)
    headerSparksParticleSystem:SetParticleParameter("StartAlpha", 1)
    headerSparksParticleSystem:SetParticleParameter("EndAlpha", 0)
    headerSparksParticleSystem:SetParticleParameter("DurationS", ZO_UniformRangeGenerator:New(1, 1.5))
    headerSparksParticleSystem:SetParticleParameter("PhysicsInitialVelocityElevationRadians", ZO_UniformRangeGenerator:New(0, ZO_TWO_PI))
    headerSparksParticleSystem:SetParticleParameter("StartColorR", particleR)
    headerSparksParticleSystem:SetParticleParameter("StartColorG", particleG)
    headerSparksParticleSystem:SetParticleParameter("StartColorB", particleB)
    self.headerSparksParticleSystem = headerSparksParticleSystem

    local headerStarbustParticleSystem = ZO_ControlParticleSystem:New(ZO_StationaryParticle_Control)
    headerStarbustParticleSystem:SetParticlesPerSecond(20)
    headerStarbustParticleSystem:SetStartPrimeS(2)
    headerStarbustParticleSystem:SetSound(SOUNDS.GIFT_INVENTORY_VIEW_FANFARE_STARBURST)
    headerStarbustParticleSystem:SetParticleParameter("Texture", "EsoUI/Art/Miscellaneous/lensflare_star_256.dds")
    headerStarbustParticleSystem:SetParticleParameter("BlendMode", TEX_BLEND_MODE_ADD)
    headerStarbustParticleSystem:SetParticleParameter("StartAlpha", 0)
    headerStarbustParticleSystem:SetParticleParameter("EndAlpha", 1)
    headerStarbustParticleSystem:SetParticleParameter("AlphaEasing", ZO_EaseInOutZeroToOneToZero)
    headerStarbustParticleSystem:SetParticleParameter("StartScale", ZO_UniformRangeGenerator:New(1, 1.3))
    headerStarbustParticleSystem:SetParticleParameter("EndScale", ZO_UniformRangeGenerator:New(.65, 1))
    headerStarbustParticleSystem:SetParticleParameter("DurationS", ZO_UniformRangeGenerator:New(1, 2))
    headerStarbustParticleSystem:SetParticleParameter("StartColorR", particleR)
    headerStarbustParticleSystem:SetParticleParameter("StartColorG", particleG)
    headerStarbustParticleSystem:SetParticleParameter("StartColorB", particleB)
    headerStarbustParticleSystem:SetParticleParameter("StartRotationRadians", ZO_UniformRangeGenerator:New(0, ZO_TWO_PI))
    local MIN_ROTATION_SPEED = math.rad(1.5)
    local MAX_ROTATION_SPEED =  math.rad(3)
    local headerStarbustRotationSpeedGenerator = ZO_WeightedChoiceGenerator:New(
        MIN_ROTATION_SPEED , 0.25,
        MAX_ROTATION_SPEED , 0.25,
        -MIN_ROTATION_SPEED, 0.25,
        -MAX_ROTATION_SPEED, 0.25)

    headerStarbustParticleSystem:SetParticleParameter("RotationSpeedRadians", headerStarbustRotationSpeedGenerator)

    self.headerStarbustParticleSystem = headerStarbustParticleSystem
end

function ZO_GiftInventoryView_Shared:InitializeKeybinds(claimKeybind, previewKeybind, declineKeybind)
    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_CENTER,

        -- Claim Gift
        {
            name = GetString(SI_GIFT_INVENTORY_VIEW_WINDOW_CLAIM_KEYBIND),

            keybind = claimKeybind,

            callback = function()
                self:ClaimGift()
            end,

            visible = function()
                return self:IsReceivedGift()
            end,
        },

        -- Preview Gift
        {
            name = function()
                if IsCurrentlyPreviewing() then
                    return GetString(SI_GIFT_INVENTORY_VIEW_WINDOW_END_PREVIEW_KEYBIND)
                else
                    return GetString(SI_GIFT_INVENTORY_VIEW_WINDOW_PREVIEW_KEYBIND)
                end
            end,

            keybind = previewKeybind,

            callback = function()
                self:TogglePreview()
            end,

            visible = function()
                return self:IsReceivedGift() and self:CanPreviewGift()
            end,
        },

        -- Return/Delete Gift
        {
            name = function()
                if self:IsReceivedGift() then
                    return GetString(SI_GIFT_INVENTORY_VIEW_WINDOW_RETURN_KEYBIND)
                else
                    return GetString(SI_GIFT_INVENTORY_DELETE_KEYBIND)
                end
            end,

            keybind = declineKeybind,

            callback = function()
                self:DeclineGift()
            end,
        },
    }

    self.refreshActionsCallback = function() self:OnRefreshActions() end
end

function ZO_GiftInventoryView_Shared:TogglePreview()
    if IsCurrentlyPreviewing() then
        self:EndCurrentPreview()
    else
        self:PreviewGift()
    end
end

internalassert(MARKET_PURCHASE_RESULT_MAX_VALUE == 42, "Update gift claim dialog to handle new purchase result")
function ZO_GiftInventoryView_Shared:ClaimGift()
    local marketProductId = self.gift:GetMarketProductId()
    local expectedClaimResult = CouldAcquireMarketProduct(marketProductId)
    if expectedClaimResult == MARKET_PURCHASE_RESULT_SUCCESS then
        if ShouldMarketProductShowClaimGiftNotice(marketProductId) then
            local noticeText, helpCategoryIndex, helpIndex = GetMarketProductClaimGiftNoticeInfo(marketProductId)
            self:ShowClaimGiftNoticeDialog(noticeText, helpCategoryIndex, helpIndex)
        else
            self:ShowClaimGiftDialog()
        end
    else
        -- We can't claim this gift for some reason
        local errorString
        if expectedClaimResult == MARKET_PURCHASE_RESULT_NOT_ENOUGH_ROOM then
            local slotsRequired = GetSpaceNeededToAcquireMarketProduct(marketProductId)
            errorString = zo_strformat(SI_UNABLE_TO_CLAIM_GIFT_INSUFFICIENT_SPACE_ERROR_TEXT, slotsRequired)
        elseif expectedClaimResult == MARKET_PURCHASE_RESULT_COLLECTIBLE_ALREADY then
            errorString = GetString(SI_UNABLE_TO_CLAIM_GIFT_COLLECTIBLE_OWNED_ERROR_TEXT)
        elseif expectedClaimResult == MARKET_PURCHASE_RESULT_EXCEEDS_CURRENCY_CAP then
            errorString = GetString(SI_UNABLE_TO_CLAIM_GIFT_EXCEEDS_CURRENCY_CAP_ERROR_TEXT)
        elseif expectedClaimResult == MARKET_PURCHASE_RESULT_ALREADY_COMPLETED_INSTANT_UNLOCK then
            local unlockType = GetMarketProductInstantUnlockType(marketProductId)
            if unlockType == INSTANT_UNLOCK_WEREWOLF_BITE or unlockType == INSTANT_UNLOCK_VAMPIRE_BITE then
                errorString = GetString(SI_UNABLE_TO_CLAIM_GIFT_ALREADY_AFFLICTED_ERROR_TEXT)
            else
                errorString = GetString(SI_UNABLE_TO_CLAIM_GIFT_FULLY_UPGRADED_ERROR_TEXT)
            end
        elseif expectedClaimResult == MARKET_PURCHASE_RESULT_FAIL_INSTANT_UNLOCK_REQ_LIST then
            local errorStrings = {}
            local errorStringIds = { GetMarketProductEligibilityErrorStringIds(marketProductId) }
            for i, errorStringId in ipairs(errorStringIds) do
                if errorStringId ~= 0 then
                    table.insert(errorStrings, GetErrorString(errorStringId))
                end
            end

            errorString = table.concat(errorStrings, "\n\n")
        end

        local dialogParams =
        {
            titleParams = { GetMarketProductDisplayName(marketProductId) },
            warningParams = { errorString },
        }

        local NO_DATA = nil
        ZO_Dialogs_ShowPlatformDialog("UNABLE_TO_CLAIM_GIFT", NO_DATA, dialogParams)
    end
end

function ZO_GiftInventoryView_Shared:ShowClaimGiftDialog()
    assert(false) -- Must be overridden
end

function ZO_GiftInventoryView_Shared:ShowClaimGiftNoticeDialog(noticeText, helpCategoryIndex, helpIndex)
    assert(false) -- Must be overridden
end

function ZO_GiftInventoryView_Shared:PreviewGift()
    if self.gift then
        local marketProductId = self.gift:GetMarketProductId()
        self:GetItemPreviewListHelper():PreviewMarketProduct(marketProductId)
    end
end

function ZO_GiftInventoryView_Shared:CanPreviewGift()
    if self.gift then
        local marketProductId = self.gift:GetMarketProductId()
        return self:GetItemPreviewListHelper():CanPreviewMarketProduct(marketProductId)
    end
    return false
end

function ZO_GiftInventoryView_Shared:EndCurrentPreview()
    self:GetItemPreviewListHelper():EndCurrentPreview()
end

function ZO_GiftInventoryView_Shared:DeclineGift()
    assert(false) -- Must be overridden
end

function ZO_GiftInventoryView_Shared:OnShowing()
    KEYBIND_STRIP:RemoveDefaultExit()
    KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
    
    self:GetItemPreviewListHelper():RegisterCallback("RefreshActions", self.refreshActionsCallback)
    self.overlayGlowFadeAnimation:PlayFromStart()
    self.blastParticleSystem:Start()
    self.headerSparksParticleSystem:Start()
    self.headerStarbustParticleSystem:Start()

    if self:IsReceivedGift() then
        PlayGiftClaimFanfare()
    else
        PlayGiftThankedFanfare()
    end
end

function ZO_GiftInventoryView_Shared:OnHidden()
    self:GetItemPreviewListHelper():UnregisterCallback("RefreshActions", self.refreshActionsCallback)
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
    KEYBIND_STRIP:RestoreDefaultExit()
    self.blastParticleSystem:Stop()
    self.headerSparksParticleSystem:Stop()
    self.headerStarbustParticleSystem:Stop()
end

function ZO_GiftInventoryView_Shared:OnGiftActionResult(giftAction, result, giftId)
    local isDisplayedGift = self.scene:IsShowing() and self.gift and self.gift:GetGiftId() == giftId
    local isRelevantAction = giftAction == GIFT_ACTION_TAKE or giftAction == GIFT_ACTION_RETURN or giftAction == GIFT_ACTION_DELETE
    local isSuccess = result == GIFT_ACTION_RESULT_SUCCESS
    if isDisplayedGift and isRelevantAction and isSuccess then
        SCENE_MANAGER:Hide(self.sceneName)
    end
end

function ZO_GiftInventoryView_Shared:OnRefreshActions()
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_GiftInventoryView_Shared:GetScene()
    return self.scene
end

function ZO_GiftInventoryView_Shared:GetItemPreviewListHelper()
    assert(false) -- Must be overridden
end

function ZO_GiftInventoryView_Shared:IsReceivedGift()
    return self.gift:IsState(GIFT_STATE_RECEIVED)
end

function ZO_GiftInventoryView_Shared:IsThankedGift()
    return self.gift:IsState(GIFT_STATE_THANKED)
end

function ZO_GiftInventoryView_Shared:SetupAndShowGift(gift)
    self.gift = gift
    local titleStringFormatterId = self:IsReceivedGift() and SI_GIFT_INVENTORY_VIEW_WINDOW_RECEIVED_TITLE or SI_GIFT_INVENTORY_VIEW_WINDOW_THANKED_TITLE
    self.titleLabel:SetText(zo_strformat(titleStringFormatterId, gift:GetUserFacingPlayerName()))
    self.giftNameLabel:SetText(gift:GetFormattedName())
    self.giftIconTexture:SetTexture(gift:GetIcon())
    local unitStackCount = gift:GetStackCount()
    local quantity = gift:GetQuantity()
    local stackCount = unitStackCount * quantity
    if stackCount > 1 then
        self.giftStackCountLabel:SetHidden(false)
        self.giftStackCountLabel:SetText(stackCount)
    else
        self.giftStackCountLabel:SetHidden(true)
    end
    self.noteLabel:SetText(gift:GetNote())

    local noteHeight = self.noteLabel:GetHeight()
    self.noteContainer:SetHeight(noteHeight)
    
    if not gift:HasBeenSeen() then
        gift:View()
    end

    if not self.scene:IsShowing() then
        SCENE_MANAGER:Push(self.sceneName)
    end
end