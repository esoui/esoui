ZO_CROWN_CRATES_ANIMATION_MANUAL_GEMIFY_SET = "manualGemifySet"

ZO_MANUAL_GEMIFY_SET_SWING_DURATION = 300
ZO_MANUAL_GEMIFY_SET_SWING_START_MAGNITUDE_DEGREES = 8
ZO_MANUAL_GEMIFY_SET_SWING_END_MAGNITUDE_DEGREES = 1

--Card

ZO_CrownGemificationCard = ZO_CrownCratesCard:Subclass()

function ZO_CrownGemificationCard:New(...)
    return ZO_CrownCratesCard.New(self, ...)
end

function ZO_CrownGemificationCard:Initialize(...)
    ZO_CrownCratesCard.Initialize(self, ...)

    for _, textureControl in ipairs(self.textureControls) do
        textureControl:SetTextureCoords(ZO_CROWN_CRATES_CARD_LEFT_COORD, ZO_CROWN_CRATES_CARD_RIGHT_COORD, ZO_CROWN_CRATES_CARD_TOP_COORD, ZO_CROWN_CRATES_CARD_BOTTOM_COORD)
    end

    self.cardTextureControl:SetAlpha(1)
    self.rewardTypeAreaControl:SetAlpha(1)
end

function ZO_CrownGemificationCard:OnScreenResized()
    self:Refresh3DCardPosition()
end

function ZO_CrownGemificationCard:SetHidden(hidden)
    self.control:SetHidden(hidden)
    if not hidden then
        self:Refresh3DCardPosition()
    end
end

function ZO_ManualGemifySwing_OnUpdate(animation, progress)
    local control = animation:GetAnimatedControl()
    local waveValue = -1 * math.sin(progress * math.pi)
    local magnitudeValue = zo_lerp(ZO_MANUAL_GEMIFY_SET_SWING_START_MAGNITUDE_DEGREES, ZO_MANUAL_GEMIFY_SET_SWING_END_MAGNITUDE_DEGREES, progress)
    control:Set3DRenderSpaceOrientation(math.rad(waveValue * magnitudeValue), 0, 0)
end

function ZO_CrownGemificationCard:SetGemifiable(gemifiable)
    if gemifiable and gemifiable.faceImage then
        self.rewardTextureControl:SetAlpha(1)
        self.rewardTextureControl:SetTexture(gemifiable.faceImage)
        self.frameAccentTextureControl:SetTexture(gemifiable.frameImage)
        self.frameAccentTextureControl:SetColor(gemifiable.rewardQualityColor:UnpackRGBA())
        self.cardTextureControl:SetTexture("EsoUI/Art/CrownCrates/crownCrate_card_bg.dds")
        self.crownCrateTierId = gemifiable.crownCrateTierId
    else
        self.rewardTextureControl:SetAlpha(0)
        self.cardTextureControl:SetTexture("EsoUI/Art/CrownCrates/gemification_cardSlot.dds")
        self.frameAccentTextureControl:SetAlpha(0)
        self.crownCrateTierId = 0
    end

    self:ReleaseParticle(ZO_CROWN_CRATES_PARTICLE_TYPE_LIFECYCLE)
    if self.crownCrateTierId ~= 0 then
        self:StartTierSpecificParticleEffects(ZO_CROWN_CRATES_PARTICLE_TYPE_LIFECYCLE, CROWN_CRATE_TIERED_PARTICLES_REVEAL)
    end

    if not self:GetOnePlayingAnimationOfType(ZO_CROWN_CRATES_ANIMATION_MANUAL_GEMIFY_SET) then
        local swingAnimationTimeline = self:AcquireAndApplyAnimationTimeline(ZO_CROWN_CRATES_ANIMATION_MANUAL_GEMIFY_SET, self.control)
        self:StartAnimation(swingAnimationTimeline)
        PlaySound(SOUNDS.CROWN_CRATES_GEM_WOBBLE)
    end

end

function ZO_CrownGemificationCard:Refresh3DCardPosition()
    local cameraPlaneMetrics = self.owner:GetCameraPlaneMetrics()
    self.control:Set3DRenderSpaceOrigin(0, 0, cameraPlaneMetrics.depthFromCamera)
    self.control:Set3DRenderSpaceOrientation(math.rad(10), 0, 0)
end

function ZO_CrownGemificationCard:Refresh2DCardPosition()
    self.activateCollectibleAreaControl:SetAnchor(CENTER, GuiRoot, CENTER, 0, 0)
end

function ZO_CrownGemificationCard:ManualGemify(gemsAwarded)
    if not self:GetOnePlayingAnimationOfType(ZO_CROWN_CRATES_ANIMATION_GEMIFY_SINGLE_GEM_GAIN) then
        self:StartSingleGemsAnimation()
        PlaySound(SOUNDS.CROWN_CRATES_GEM_ITEM)
    end
    self:StartGemGainTextAnimation(gemsAwarded, CENTER, self.activateCollectibleAreaControl, CENTER, 0, 0)
end

--Slot

ZO_CrownGemificationSlot = ZO_CallbackObject:Subclass()

function ZO_CrownGemificationSlot:New(...)
    local object = ZO_CallbackObject.New(self)
    object:Initialize(...)
    return object
end

function ZO_CrownGemificationSlot:Initialize(owner)
    self.owner = owner
    self.control = ZO_CrownGemificationSlotTopLevel
    self.control:Create3DRenderSpace()

    self.fragment = ZO_SimpleSceneFragment:New(self.control)
    self.fragment:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_FRAGMENT_SHOWING then
            Set3DRenderSpaceToCurrentCamera(self.control:GetName())
            self:RefreshCameraPlaneMetrics()
            self.card:SetHidden(false)
        elseif newState == SCENE_FRAGMENT_HIDDEN then
            self.card:SetHidden(true)
        end
    end)

    self.cardControl = self.control:GetNamedChild("Card")
    self.card = ZO_CrownGemificationCard:New(self.cardControl, self)
    self.card:Refresh2DCardPosition()

    self.infoControl = self.control:GetNamedChild("Info")
    local contentsControl = self.infoControl:GetNamedChild("Contents")
    self.nameLabel = contentsControl:GetNamedChild("Name")
    self.conversionControl = contentsControl:GetNamedChild("Conversion")
    self.requiredLabel = self.conversionControl:GetNamedChild("Required")
    self.requiredIconTexture = self.conversionControl:GetNamedChild("RequiredIcon")
    self.gemAmountLabel = self.conversionControl:GetNamedChild("GemAmount")
    self.arrowTexture = self.conversionControl:GetNamedChild("Arrow")
    self.backdrop = self.infoControl:GetNamedChild("BG")

    self.control:RegisterForEvent(EVENT_SCREEN_RESIZED, function() self:OnScreenResized() end)

    CROWN_GEMIFICATION_MANAGER:RegisterCallback("GemifiableListChanged", function() self:OnGemifiableListChanged() end)
    CROWN_GEMIFICATION_MANAGER:RegisterCallback("GemifiableChanged", function(gemifiable) self:OnGemifiableChanged(gemifiable) end)

    self:InitializeStyles()
end

do
    local ARROW_TEXTURE_WIDTH = 128

    local KEYBOARD_STYLE =
    {
        nameFont = "ZoFontHeader3",
        conversionFont = "ZoFontCallout2",
        arrowTexture = "EsoUI/Art/CrownCrates/Keyboard/gemification_arrow.dds",
        arrowWidth = 82,
        BGTemplate = "ZO_DefaultBackdrop",
    }

    local GAMEPAD_STYLE =
    {
        nameFont = "ZoFontGamepad27",
        conversionFont = "ZoFontGamepadBold48",
        arrowTexture = "EsoUI/Art/CrownCrates/Gamepad/gp_gemification_arrow.dds",
        arrowWidth = 92,
        BGTemplate = "ZO_DefaultBackdrop_Gamepad"
    }

    function ZO_CrownGemificationSlot:InitializeStyles()
        ZO_PlatformStyle:New(function(style) self:ApplyStyle(style) end, KEYBOARD_STYLE, GAMEPAD_STYLE)
    end

    function ZO_CrownGemificationSlot:ApplyStyle(style)
        self.nameLabel:SetFont(style.nameFont)
        self.requiredLabel:SetFont(style.conversionFont)
        self.gemAmountLabel:SetFont(style.conversionFont)
        self.arrowTexture:SetTexture(style.arrowTexture)
        self.arrowTexture:SetWidth(style.arrowWidth)
        self.arrowTexture:SetTextureCoords(0, style.arrowWidth / ARROW_TEXTURE_WIDTH, 0, 1)
        ApplyTemplateToControl(self.backdrop, style.BGTemplate)
        --Remove the template anchors and anchor fill
        self.backdrop:ClearAnchors()
        self.backdrop:SetAnchorFill()
    end
end

function ZO_CrownGemificationSlot:OnScreenResized()
    self:RefreshCameraPlaneMetrics()
    self.card:OnScreenResized()
end

function ZO_CrownGemificationSlot:OnGemifiableChanged(gemifiable)
    if self.gemifiable and self.gemifiable.name == gemifiable.name then
        self:RefreshInfoBox()
    end
end

function ZO_CrownGemificationSlot:OnGemifiableListChanged()
    if self.gemifiable then
        local gemifiableList = CROWN_GEMIFICATION_MANAGER:GetGemifiableList()
        local newGemifiableTable
        for i, gemifiable in ipairs(gemifiableList) do
            if gemifiable.name == self.gemifiable.name then
                newGemifiableTable = gemifiable
                break
            end
        end
        if newGemifiableTable then
            self.gemifiable = newGemifiableTable
            self:RefreshInfoBox()
        else
            self:SetGemifiable(nil)
        end
    end
end

function ZO_CrownGemificationSlot:GetFragment()
    return self.fragment
end

function ZO_CrownGemificationSlot:GetOwner()
    return self.owner
end

function ZO_CrownGemificationSlot:GetStateMachine()
    return nil
end

function ZO_CrownGemificationSlot:RefreshInfoBox()
    if self.gemifiable then
        local gemifiable = self.gemifiable
        self.nameLabel:SetText(zo_strformat(SI_GEMIFICATION_SLOT_NAME_AND_COUNT, gemifiable.name, gemifiable.count))
        self.requiredLabel:SetText(gemifiable.requiredPerConversion)
        self.requiredIconTexture:SetTexture(gemifiable.icon)
        self.gemAmountLabel:SetText(gemifiable.gemsAwardedPerConversion)
        self.conversionControl:SetHidden(false)
        if gemifiable.maxGemifies > 0 then
            self.requiredLabel:SetColor(ZO_WHITE:UnpackRGBA())
            self.gemAmountLabel:SetColor(ZO_WHITE:UnpackRGBA())
        else
            self.requiredLabel:SetColor(ZO_ERROR_COLOR:UnpackRGBA())
            self.gemAmountLabel:SetColor(ZO_ERROR_COLOR:UnpackRGBA())
        end
    else
        self.nameLabel:SetText(GetString(SI_GEMIFICATION_EMPTY_SLOT_MESSAGE))
        self.conversionControl:SetHidden(true)
    end
end

function ZO_CrownGemificationSlot:GetGemifiable()
    return self.gemifiable
end

function ZO_CrownGemificationSlot:SetGemifiable(gemifiable)
    self.gemifiable = gemifiable
    self.card:SetGemifiable(gemifiable)
    self:RefreshInfoBox()
    self:FireCallbacks("GemifiableChanged")
end


function ZO_CrownGemificationSlot:CanGemify()
    if self.gemifiable then
        local gemifiable = self.gemifiable
        if gemifiable.maxGemifies > 0 then
            return true
        else
            return false, zo_strformat(SI_GEMIFICATION_TOO_FEW_TO_EXTRACT, gemifiable.requiredPerConversion, gemifiable.name)
        end
    else
        return false
    end
end

function ZO_CrownGemificationSlot:GetGemifyAllCount()
    local gemifiable = self.gemifiable
    if gemifiable then
        local remainder = gemifiable.count % gemifiable.requiredPerConversion
        return gemifiable.count - remainder
    else
        return 0
    end
end

function ZO_CrownGemificationSlot:GemifyOne()
    if self.gemifiable then
        self.card:ManualGemify(self.gemifiable.gemsAwardedPerConversion)
        self.owner:AddCrownGems(self.gemifiable.gemsAwardedPerConversion)
        self.gemifiable:GemifyOne()
    end
end

function ZO_CrownGemificationSlot:GemifyAll()
    if self.gemifiable then
        self.card:ManualGemify(self.gemifiable.gemTotal)
        self.owner:AddCrownGems(self.gemifiable.gemTotal)
        self.gemifiable:GemifyAll()
    end
end

function ZO_CrownGemificationSlot:GetCameraPlaneMetrics()
    return self.cameraPlaneMetrics
end

function ZO_CrownGemificationSlot:RefreshCameraPlaneMetrics()
    self.cameraPlaneMetrics = self.owner:ComputeCameraPlaneMetrics(ZO_CROWN_CRATES_CARD_WIDTH_WORLD, ZO_CROWN_CRATES_CARD_WIDTH_REVEALED_UI)
end