---------------------
--Crown Crates Card--
---------------------

--Card Sizing
ZO_CROWN_CRATES_CARD_WIDTH_TO_HEIGHT_RATIO = 1.5
ZO_CROWN_CRATES_CARD_WIDTH_WORLD = 0.1
ZO_CROWN_CRATES_CARD_HEIGHT_BUFFER_WORLD = 0.2
ZO_CROWN_CRATES_CARD_HEIGHT_WORLD = ZO_CROWN_CRATES_CARD_WIDTH_WORLD * ZO_CROWN_CRATES_CARD_WIDTH_TO_HEIGHT_RATIO
ZO_CROWN_CRATES_CARD_WIDTH_IN_HAND_UI = 275
ZO_CROWN_CRATES_CARD_SPACING_IN_HAND_UI = 73
ZO_CROWN_CRATES_CARD_HEIGHT_IN_HAND_UI = ZO_CROWN_CRATES_CARD_WIDTH_IN_HAND_UI * ZO_CROWN_CRATES_CARD_WIDTH_TO_HEIGHT_RATIO
ZO_CROWN_CRATES_CARD_WIDTH_REVEALED_UI = 315
ZO_CROWN_CRATES_CARD_HEIGHT_REVEALED_UI = ZO_CROWN_CRATES_CARD_WIDTH_REVEALED_UI * ZO_CROWN_CRATES_CARD_WIDTH_TO_HEIGHT_RATIO
ZO_CROWN_CRATES_CARD_SPACING_REVEALED_UI = 50
ZO_CROWN_CRATES_CARD_TOP_COORD = 0
ZO_CROWN_CRATES_CARD_BOTTOM_COORD = 1
ZO_CROWN_CRATES_CARD_LEFT_COORD = 82/512
ZO_CROWN_CRATES_CARD_RIGHT_COORD = 430/512

--Primary Deal
ZO_CROWN_CRATES_PRIMARY_DEAL_SPACING_DURATION_MS = 60
ZO_CROWN_CRATES_PRIMARY_DEAL_ARC_CONTROL_POINT_Y_OFFSET_SCREEN_PERCENT = 0.07
ZO_CROWN_CRATES_PRIMARY_DEAL_DURATION_MS = 300
ZO_CROWN_CRATES_PRIMARY_DEAL_START_PITCH_RADIANS = math.rad(90)
ZO_CROWN_CRATES_PRIMARY_DEAL_END_PITCH_RADIANS = math.rad(60)
ZO_CROWN_CRATES_PRIMARY_DEAL_START_YAW_RADIANS = math.rad(180)
ZO_CROWN_CRATES_PRIMARY_DEAL_END_YAW_RADIANS = math.rad(0)
ZO_CROWN_CRATES_PRIMARY_DEAL_START_ROLL_RADIANS = math.rad(0)
ZO_CROWN_CRATES_PRIMARY_DEAL_END_ROLL_RADIANS = math.rad(0)

--Bonus Deal Spread
ZO_CROWN_CRATES_BONUS_SLIDE_TILT_UP_RADIANS = math.rad(30)
ZO_CROWN_CRATES_BONUS_SLIDE_RISE_Y_UI = 50
ZO_CROWN_CRATES_BONUS_SLIDE_DURATION_MS = 333
ZO_CROWN_CRATES_BONUS_SLIDE_RISE_DURATION_MS = 99
ZO_CROWN_CRATES_BONUS_SLIDE_FALL_DURATION_MS = ZO_CROWN_CRATES_BONUS_SLIDE_DURATION_MS - ZO_CROWN_CRATES_BONUS_SLIDE_RISE_DURATION_MS
ZO_CROWN_CRATES_BONUS_SLIDE_TILT_UP_DURATION_MS = 50
ZO_CROWN_CRATES_BONUS_SLIDE_UNTILT_DURATION_MS = 190
ZO_CROWN_CRATES_BONUS_SLIDE_DELAY_MS = 167
ZO_CROWN_CRATES_BONUS_SLIDE_SPACING_DURATION_MS = 33

--Bonus Deal
ZO_CROWN_CRATES_BONUS_DEAL_SPACING_DURATION_MS = 200
ZO_CROWN_CRATES_BONUS_DEAL_TO_SCREEN_DURATION_MS = 333
ZO_CROWN_CRATES_BONUS_DEAL_TO_SCREEN_SCALE_FACTOR = 1.2
ZO_CROWN_CRATES_BONUS_DEAL_TO_SCREEN_ARC_CONTROL_POINT_Y_OFFSET_SCREEN_PERCENT = 0.14
ZO_CROWN_CRATES_BONUS_DEAL_TILT_DURATION_MS = 350
ZO_CROWN_CRATES_BONUS_DEAL_HANG_DURATION_MS = 500
ZO_CROWN_CRATES_BONUS_DEAL_TO_HAND_DURATION_MS = 667
ZO_CROWN_CRATES_BONUS_HANG_START_MS = ZO_CROWN_CRATES_BONUS_DEAL_TO_SCREEN_DURATION_MS + ZO_CROWN_CRATES_BONUS_DEAL_TILT_DURATION_MS
ZO_CROWN_CRATES_BONUS_DEAL_TO_HAND_START_MS = ZO_CROWN_CRATES_BONUS_HANG_START_MS + ZO_CROWN_CRATES_BONUS_DEAL_HANG_DURATION_MS
ZO_CROWN_CRATES_BONUS_DEAL_TO_SCREEN_START_PITCH_RADIANS = math.rad(90)
ZO_CROWN_CRATES_BONUS_DEAL_TO_SCREEN_END_PITCH_RADIANS = math.rad(45)
ZO_CROWN_CRATES_BONUS_DEAL_TO_SCREEN_START_YAW_RADIANS = math.rad(-30)
ZO_CROWN_CRATES_BONUS_DEAL_TO_SCREEN_END_YAW_RADIANS = math.rad(0)
ZO_CROWN_CRATES_BONUS_DEAL_TO_SCREEN_START_ROLL_RADIANS = math.rad(-160)
ZO_CROWN_CRATES_BONUS_DEAL_TO_SCREEN_END_ROLL_RADIANS = math.rad(0)
ZO_CROWN_CRATES_BONUS_DEAL_DRIFT_X_UI = 50

--Mystery Select/Deselect
ZO_CROWN_CRATES_MYSTERY_SELECTION_DURATION_MS = 166
ZO_CROWN_CRATES_MYSTERY_SELECTION_OFFSET_Y_UI = 50

--Mystery Selected
ZO_CROWN_CRATES_MYSTERY_SELECTED_WOBBLE_DURATION_MS = 2800
ZO_CROWN_CRATES_MYSTERY_SELECTED_WOBBLE_SPACING_MS = 1000
ZO_CROWN_CRATES_MYSTERY_SELECTED_WOBBLE_NUM_SETS = 8
ZO_CROWN_CRATES_MYSTERY_SELECTED_WOBBLE_NUM_PER_SET = 3
ZO_CROWN_CRATES_MYSTERY_SELECTED_WOBBLE_MAGNITUDE_RADIANS = math.rad(2)

--Reveal
ZO_CROWN_CRATES_REVEAL_DURATION_MS = 500
ZO_CROWN_CRATES_REVEAL_END_PITCH_RADIANS = math.rad(175)
ZO_CROWN_CRATES_REVEAL_END_YAW_RADIANS = math.rad(0)
ZO_CROWN_CRATES_REVEAL_END_ROLL_RADIANS = math.rad(0)
ZO_CROWN_CRATES_REVEAL_INFO_AREA_HEIGHT_UI = 145

--Leave
ZO_CROWN_CRATES_LEAVE_SPACING_MS = 20
ZO_CROWN_CRATES_LEAVE_MOVE_DURATION_MS = 500
ZO_CROWN_CRATES_LEAVE_SPIN_DURATION_MS = 250
ZO_CROWN_CRATES_LEAVE_END_PITCH_RADIANS = math.rad(175)
ZO_CROWN_CRATES_LEAVE_END_YAW_RADIANS = math.rad(-100)
ZO_CROWN_CRATES_LEAVE_END_ROLL_RADIANS = math.rad(0)

--Revealed Select/Deselect
ZO_CROWN_CRATES_REVEALED_SELECTION_DURATION_MS = 166
ZO_CROWN_CRATES_REVEAL_ALL_OFFSET_DURATION_MS = 120

--Gemify
ZO_CROWN_CRATES_GEMIFY_SHOW_SPIN_DELAY_MS = 333
ZO_CROWN_CRATES_GEMIFY_SHOW_START_MS = 100
ZO_CROWN_CRATES_GEMIFY_SHOW_DURATION_MS = 400
ZO_CROWN_CRATES_GEMIFY_SPIN_DURATION_MS = 500
ZO_CROWN_CRATES_GEMIFY_BEGIN_PITCH_RADIANS = ZO_CROWN_CRATES_REVEAL_END_PITCH_RADIANS
ZO_CROWN_CRATES_GEMIFY_END_PITCH_RADIANS = ZO_CROWN_CRATES_GEMIFY_BEGIN_PITCH_RADIANS + math.rad(180)
ZO_CROWN_CRATES_GEMIFY_TINT_ALPHA = 0.2
ZO_CROWN_CRATES_GEMIFY_TINT_COLOR = ZO_ColorDef:New("0080AA")
ZO_CROWN_CRATES_GEMIFY_COLOR_FLASH = ZO_ColorDef:New("DDFFFF")
ZO_CROWN_CRATES_GEMIFY_COLOR_TINT_IN_DURATION_MS = 166
ZO_CROWN_CRATES_GEMIFY_COLOR_TINT_OUT_DURATION_MS = 133
ZO_CROWN_CRATES_GEMIFY_COLOR_TINT_OUT_DELAY_MS = ZO_CROWN_CRATES_GEMIFY_COLOR_TINT_IN_DURATION_MS
ZO_CROWN_CRATES_GEMIFY_COLOR_TINT_IN_SECOND_DURATION_MS = 50
ZO_CROWN_CRATES_GEMIFY_COLOR_TINT_IN_SECOND_DELAY_MS = ZO_CROWN_CRATES_GEMIFY_COLOR_TINT_OUT_DELAY_MS + ZO_CROWN_CRATES_GEMIFY_COLOR_TINT_OUT_DURATION_MS
ZO_CROWN_CRATES_GEMIFY_COLOR_TINT_OUT_SECOND_DURATION_MS = 50
ZO_CROWN_CRATES_GEMIFY_COLOR_TINT_OUT_SECOND_DELAY_MS = ZO_CROWN_CRATES_GEMIFY_COLOR_TINT_IN_SECOND_DELAY_MS + ZO_CROWN_CRATES_GEMIFY_COLOR_TINT_IN_SECOND_DURATION_MS
ZO_CROWN_CRATES_GEMIFY_FINAL_GEM_UP_DURATION_MS = 100
ZO_CROWN_CRATES_GEMIFY_FINAL_GEM_DOWN_DURATION_MS = 100
ZO_CROWN_CRATES_GEMIFY_FINAL_GEM_DOWN_DELAY_MS = ZO_CROWN_CRATES_GEMIFY_FINAL_GEM_UP_DURATION_MS
ZO_CROWN_CRATES_GEMIFY_TOTAL_SINGLE_GEMS_TO_PLAY = 6
ZO_CROWN_CRATES_GEMIFY_SINGLE_GEM_DURATION_MS = 233
ZO_CROWN_CRATES_GEMIFY_SINGLE_GEM_INDEX_TO_START_FLASH = 1
ZO_CROWN_CRATES_GEMIFY_SINGLE_GEM_STARTING_ANGLE_DEGREES = 90
ZO_CROWN_CRATES_GEMIFY_SINGLE_GEM_DELTA_ANGLE_DEGREES = 60
ZO_CROWN_CRATES_GEMIFY_SINGLE_GEM_START_TIME_DELAY_MS = 100
ZO_CROWN_CRATES_GEMIFY_GEM_GAIN_TEXT_ALPHA_DURATION_MS = 134
ZO_CROWN_CRATES_GEMIFY_GEM_GAIN_TEXT_ALPHA_DELAY_MS = 466
ZO_CROWN_CRATES_GEMIFY_GEM_GAIN_TEXT_TRANSLATE_DURATION_MS = ZO_CROWN_CRATES_GEMIFY_GEM_GAIN_TEXT_ALPHA_DURATION_MS + ZO_CROWN_CRATES_GEMIFY_GEM_GAIN_TEXT_ALPHA_DELAY_MS


--Info
ZO_CROWN_CRATES_CARD_INFO_INSET_X = 20

--Show Info
ZO_CROWN_CRATES_CARD_SHOW_INFO_DURATION_MS = 220
ZO_CROWN_CRATES_CARD_SHOW_INFO_NAME_OFFSET_Y_UI = -15
ZO_CROWN_CRATES_CARD_SHOW_INFO_REWARD_TYPE_OFFSET_Y_UI = 30

--Hide Info
ZO_CROWN_CRATES_CARD_HIDE_INFO_DURATION_MS = 200

--Animations
ZO_CROWN_CRATES_ANIMATION_PRIMARY_DEAL = "primaryDeal"
ZO_CROWN_CRATES_ANIMATION_BONUS_DEAL = "bonusDeal"
ZO_CROWN_CRATES_ANIMATION_BONUS_DEAL_GLOW = "bonusDealGlow"
ZO_CROWN_CRATES_ANIMATION_BONUS_SLIDE = "bonusSlide"
ZO_CROWN_CRATES_ANIMATION_MYSTERY_SELECTED_GLOW = "mysterySelectedGlow"
ZO_CROWN_CRATES_ANIMATION_MYSTERY_SELECT = "mysterySelect"
ZO_CROWN_CRATES_ANIMATION_MYSTERY_DESELECT = "mysteryDeselect"
ZO_CROWN_CRATES_ANIMATION_MYSTERY_SELECTED = "mysterySelected"
ZO_CROWN_CRATES_ANIMATION_REVEAL = "reveal"
ZO_CROWN_CRATES_ANIMATION_CARD_SHOW_INFO = "cardShowInfo"
ZO_CROWN_CRATES_ANIMATION_CARD_HIDE_INFO = "cardHideInfo"
ZO_CROWN_CRATES_ANIMATION_LEAVE = "leave"
ZO_CROWN_CRATES_ANIMATION_REVEALED_SELECTED_GLOW = "revealedSelectedGlow"
ZO_CROWN_CRATES_ANIMATION_GEMIFY_CARD = "gemifyCard"
ZO_CROWN_CRATES_ANIMATION_GEMIFY_OVERLAY = "gemifyOverlay"
ZO_CROWN_CRATES_ANIMATION_GEMIFY_COLOR_TINT = "gemifyColorTint"
ZO_CROWN_CRATES_ANIMATION_GEMIFY_SINGLE_GEM_GAIN = "gemifySingleGemGain"
ZO_CROWN_CRATES_ANIMATION_GEMIFY_FINAL_GEM = "gemifyFinalGem"
ZO_CROWN_CRATES_ANIMATION_GEMIFY_CROWN_GEM_TEXT = "crownGemText"

--Card Sides
ZO_CROWN_CRATES_CARD_SIDE_BACK = "back"
ZO_CROWN_CRATES_CARD_SIDE_FACE = "face"
ZO_CROWN_CRATES_CARD_SIDE_GEMIFIED_FACE = "gemifiedFace"

-- Gem Frame Texture
ZO_CROWN_CRATES_GEM_FRAME_TEXTURE = "EsoUI/Art/CrownCrates/crownCrate_card_frame_gem.dds"

local CARD_STATES = 
{
    START = "START", --1
    MYSTERY = "MYSTERY", --2
    FLIPPING = "FLIPPING", --3
    REVEALED = "REVEALED", --4
    GEMIFY = "GEMIFY", --5
    LEAVING = "LEAVING", --6
}

local FORWARD = true
local BACKWARD = false

ZO_CrownCratesCard = ZO_CrownCratesAnimatable:Subclass()

function ZO_CrownCratesCard:New(...)
    return ZO_CrownCratesAnimatable.New(self, ...)
end

function ZO_CrownCratesCard:Initialize(control, owner)
    ZO_CrownCratesAnimatable.Initialize(self, control)

    self.owner = owner
    self.rewardTextureControl = control:GetNamedChild("Reward")
    self.cardTextureControl = control:GetNamedChild("Card")
    self.frameAccentTextureControl = control:GetNamedChild("FrameAccent")
    self.cardGlowTextureControl = control:GetNamedChild("CardGlow")
	self.colorTintOverlayTextureControl = control:GetNamedChild("ColorTintOverlay")
	self.colorFlashOverlayTextureControl = control:GetNamedChild("ColorFlashOverlay")
    self.gemOverlayTextureControl = control:GetNamedChild("GemOverlay")
    self.mouseAreaControl = control:GetNamedChild("MouseArea")

    self.nameAreaControl = control:GetNamedChild("NameArea")
    self.nameLabel = self.nameAreaControl:GetNamedChild("Text")
    self.rewardTypeAreaControl = control:GetNamedChild("RewardTypeArea")
    self.rewardTypeLabel = self.rewardTypeAreaControl:GetNamedChild("Text")
    self.gemGainLabel = self.rewardTypeAreaControl:GetNamedChild("CrownGemsText")
    
	self.colorTintOverlayTextureControl:SetColor(ZO_CROWN_CRATES_GEMIFY_TINT_COLOR:UnpackRGB())
	self.colorFlashOverlayTextureControl:SetColor(ZO_CROWN_CRATES_GEMIFY_COLOR_FLASH:UnpackRGB())

    self:InitializeSingleGemPool() 
    self:Reset()

    self:InitializeStyles()

    self.nextSingleGemIndex = 1

    self.mouseAreaControl:SetHandler("OnMouseUp", function() self:OnMouseUp() end)
end

do
    local KEYBOARD_STYLE =
    {
        nameFonts =
        {
            {
                font = "ZoFontWinH1",
                lineLimit = 2,
            },
            {
                font = "ZoFontWinH2",
                lineLimit = 2,
            },
            {
                font = "ZoFontWinH3",
                lineLimit = 2,
                dontUseForAdjusting = true,
            },
        },

        rewardTextFonts = 
        {
            {
                font = "ZoFontWinH3",
                lineLimit = 2,
            },
            {
                font = "ZoFontWinH4",
                lineLimit = 2,
                dontUseForAdjusting = true,
            },
        },

        gemGainFonts =
        {
            {
                font = "ZoFontCallout2",
                lineLimit = 2,
            },
            {
                font = "ZoFontCallout",
                lineLimit = 2,
            },
            {
                font = "ZoFontWinH1",
                lineLimit = 2,
                dontUseForAdjusting = true,
            },
        },
    }

    local GAMEPAD_STYLE =
    {
        nameFonts =
        {
            {
                font = "ZoFontGamepad42",
                lineLimit = 2,
            },
            {
                font = "ZoFontGamepad36",
                lineLimit = 2,
            },
            {
                font = "ZoFontGamepad34",
                lineLimit = 2,
            },
            {
                font = "ZoFontGamepad27",
                lineLimit = 2,
                dontUseForAdjusting = true,
            },
        },

        rewardTextFonts =
        {
            {
                font = "ZoFontGamepad34",
                lineLimit = 2,
            },
            {
                font = "ZoFontGamepad27",
                lineLimit = 2,
                dontUseForAdjusting = true,
            },
        },

        gemGainFonts =
        {
            {
                font = "ZoFontGamepad42",
                lineLimit = 2,
            },
            {
                font = "ZoFontGamepad36",
                lineLimit = 2,
            },
            {
                font = "ZoFontGamepad34",
                lineLimit = 2,
                dontUseForAdjusting = true,
            },
        },
    }

    function ZO_CrownCratesCard:InitializeStyles()
        ZO_PlatformStyle:New(function(style) self:ApplyStyle(style) end, KEYBOARD_STYLE, GAMEPAD_STYLE)
    end
end

function ZO_CrownCratesCard:InitializeSingleGemPool()
    local reset = function(singleGem)
        singleGem:ClearAnchors()
        singleGem:SetHidden(true)
    end 
    local factory = function(pool)
                        local singleGem = CreateControlFromVirtual("$(parent)SingleGem",  self.control, "ZO_CrownCrateSingleGem", self.nextSingleGemIndex)
                        singleGem:SetTextureCoords(ZO_CROWN_CRATES_CARD_LEFT_COORD, ZO_CROWN_CRATES_CARD_RIGHT_COORD, ZO_CROWN_CRATES_CARD_TOP_COORD, ZO_CROWN_CRATES_CARD_BOTTOM_COORD)
                        self.nextSingleGemIndex = self.nextSingleGemIndex + 1
                        return singleGem
                    end

    self.singleGemPool = ZO_ObjectPool:New(factory, reset)
end

function ZO_CrownCratesCard:ApplyStyle(style)
    ZO_FontAdjustingWrapLabel_OnInitialized(self.nameLabel, style.nameFonts, TEXT_WRAP_MODE_ELLIPSIS)
    ZO_FontAdjustingWrapLabel_OnInitialized(self.rewardTypeLabel, style.rewardTextFonts, TEXT_WRAP_MODE_ELLIPSIS)
    ZO_FontAdjustingWrapLabel_OnInitialized(self.gemGainLabel, style.gemGainFonts, TEXT_WRAP_MODE_ELLIPSIS)
end

function ZO_CrownCratesCard:SetRewardIndex(rewardIndex)
    self.rewardIndex = rewardIndex
end

function ZO_CrownCratesCard:SetVisualSlotIndex(visualSlotIndex)
    self.visualSlotIndex = visualSlotIndex
end

function ZO_CrownCratesCard:InitializeForDeal(visualSlotIndex)
    self:SetVisualSlotIndex(visualSlotIndex)
    self.rewardName, self.rewardTypeText, self.rewardImage, self.rewardFrameAccentImage, self.gemsExchanged, self.isBonus, self.crownCrateTierId, self.stackCount = GetCrownCrateRewardInfo(self.rewardIndex)
    self.rewardQualityColor = ZO_ColorDef:New(GetCrownCrateTierQualityColor(self.crownCrateTierId))
    self.rewardReaction = GetCrownCrateTierReactionNPCAnimation(self.crownCrateTierId)
    self.rewardProductType, self.rewardReferenceDataId = GetCrownCrateRewardProductReferenceData(self.rewardIndex)
    self.mouseAreaControl:SetMouseEnabled(true)
end

function ZO_CrownCratesCard:Reset()
    ZO_CrownCratesAnimatable.Reset(self)
    
    self.nameAreaControl:SetAlpha(0)
    self.rewardTypeAreaControl:SetAlpha(0)
    self.gemGainLabel:SetAlpha(0)

    self.rootX = nil
    self.rootY = nil
    self.rootZ = nil
    self.isFloatWobbling = false
    self.side = nil
    self.visualSlotIndex = nil
    self.rewardName = nil
    self.rewardTypeText = nil
    self.rewardImage = nil
    self.rewardFrameAccentImage = nil
    self.rewardProductType = nil
    self.rewardReferenceDataId = nil
    self.gemsExchanged = nil
    self.isBonus = nil
    self.crownCrateTierId = nil
    self.stackCount = nil
    self.playRevealSounds = true
    self:SetState(CARD_STATES.START)

	self:SetCardFaceDesaturation(0)
    self.singleGemPool:ReleaseAllObjects()

    self.control:SetHandler("OnUpdate", nil)

    self:ReleaseParticle()

    self.gemGainLabel:SetAnchor(BOTTOM, self.rewardTypeLabel, TOP, 0, 5)

    --Extend the card down below the edge of the screen to fix the bouncing as it moves up on selection and out from under the mouse
    self.mouseAreaControl:Set3DLocalDimensions(ZO_CROWN_CRATES_CARD_WIDTH_WORLD, ZO_CROWN_CRATES_CARD_HEIGHT_WORLD + ZO_CROWN_CRATES_CARD_HEIGHT_BUFFER_WORLD)
    self.mouseAreaControl:Set3DRenderSpaceOrigin(0, -0.5 * (ZO_CROWN_CRATES_CARD_HEIGHT_BUFFER_WORLD + ZO_CROWN_CRATES_CARD_HEIGHT_WORLD) + 0.5 * ZO_CROWN_CRATES_CARD_HEIGHT_WORLD, 0)
    local OnMouseEnter = function()
        self:OnMouseEnter()
    end
    local OnMouseExit = function()
        self:OnMouseExit()
    end
    ZO_CrownCrates.AddBounceResistantMouseHandlersToControl(self.mouseAreaControl, OnMouseEnter, OnMouseExit)
end

function ZO_CrownCratesCard:SetupCardSide(side)
    if self.side ~= side then
        self.side = side
        local topCoord, bottomCoord
        local backImage, backGlowImage, faceImage, faceGlowImage = GetCrownCrateCardTextures(GetCurrentCrownCrateId())
        if side == ZO_CROWN_CRATES_CARD_SIDE_BACK then
            self.cardTextureControl:SetTexture(backImage)
            self.cardGlowTextureControl:SetTexture(backGlowImage)
        elseif side == ZO_CROWN_CRATES_CARD_SIDE_GEMIFIED_FACE then
            self:SetCardFaceDesaturation(1)
            self.frameAccentTextureControl:SetTexture(ZO_CROWN_CRATES_GEM_FRAME_TEXTURE)
            self.frameAccentTextureControl:SetColor(ZO_BLACK:UnpackRGBA())
        else
            self.cardTextureControl:SetTexture(faceImage)
            self.cardGlowTextureControl:SetTexture(faceGlowImage)
            self.rewardTextureControl:SetAlpha(1)
            self.frameAccentTextureControl:SetAlpha(1)
            self.rewardTextureControl:SetTexture(self.rewardImage)
            self.frameAccentTextureControl:SetTexture(self.rewardFrameAccentImage)
            self.frameAccentTextureControl:SetColor(self.rewardQualityColor:UnpackRGBA())
        end
        self:RefreshTextureCoords()
    end
end

function ZO_CrownCratesCard:RefreshTextureCoords()
    local topCoord, bottomCoord
    if self.side == ZO_CROWN_CRATES_CARD_SIDE_BACK or self.side == ZO_CROWN_CRATES_CARD_SIDE_GEMIFIED_FACE  then
        topCoord = ZO_CROWN_CRATES_CARD_TOP_COORD
        bottomCoord = ZO_CROWN_CRATES_CARD_BOTTOM_COORD
    else
        topCoord = ZO_CROWN_CRATES_CARD_BOTTOM_COORD
        bottomCoord = ZO_CROWN_CRATES_CARD_TOP_COORD
    end

    for _, textureControl in ipairs(self.textureControls) do
        textureControl:SetTextureCoords(ZO_CROWN_CRATES_CARD_LEFT_COORD, ZO_CROWN_CRATES_CARD_RIGHT_COORD, topCoord, bottomCoord)
    end
end

function ZO_CrownCratesCard:AcquireCrateSpecificParticle(crownCrateParticleEffects)
    self:ReleaseParticle()
    self.particlePool = CROWN_CRATES:GetCrateSpecificCardParticlePool(GetCurrentCrownCrateId(), crownCrateParticleEffects)
    self.particle, self.particleKey = self.particlePool:AcquireObject()
    return self.particle
end

function ZO_CrownCratesCard:AcquireTierSpecificParticle(crownCrateTierParticleEffects)
    self:ReleaseParticle()
    self.particlePool = CROWN_CRATES:GetTierSpecificCardParticlePool(self.crownCrateTierId, crownCrateTierParticleEffects)
    self.particle, self.particleKey = self.particlePool:AcquireObject()
    return self.particle
end

function ZO_CrownCratesCard:StartParticle(particle)
    particle:FollowControl(self.control)
    particle:Start()
end

function ZO_CrownCratesCard:ReleaseParticle()
    if self.particleKey then
        self.particlePool:ReleaseObject(self.particleKey)
        self.particlePool = nil
        self.particle = nil
        self.particleKey = nil
    end
end

function ZO_CrownCratesCard:PrimayDealFromWorldPositionToWorldPosition(startX, startY, startZ, endX, endY, endZ)
    self:SetupCardSide(ZO_CROWN_CRATES_CARD_SIDE_BACK)
    self.control:SetHidden(false)
    self.cardTextureControl:SetAlpha(1)
    self.cardGlowTextureControl:SetAlpha(0)

    local function TrackPrimaryDealComplete(timeline, completedPlaying)
        if completedPlaying then
            self:SetState(CARD_STATES.MYSTERY)
            self.owner:OnPrimaryDealCardComplete()

            --PFX
            self:StartParticle(self:AcquireTierSpecificParticle(CROWN_CRATE_TIERED_PARTICLES_MYSTERY))
            PlayCrownCrateTierSpecificParticleEffectSound(self.crownCrateTierId, CROWN_CRATE_TIERED_PARTICLES_MYSTERY)
        end
    end

    local animationTimeline = self:AcquireAndApplyAnimationTimeline(ZO_CROWN_CRATES_ANIMATION_PRIMARY_DEAL, self.control, TrackPrimaryDealComplete)

    --Setup translation
    local translateAnimation = animationTimeline:GetAnimation(1)
    self:SetupBezierArcBetween(translateAnimation, startX, startY, startZ, endX, endY, endZ, ZO_CROWN_CRATES_PRIMARY_DEAL_ARC_CONTROL_POINT_Y_OFFSET_SCREEN_PERCENT)

    --Play
    self:StartAnimation(animationTimeline)

    self.rootX = endX
    self.rootY = endY
    self.rootZ = endZ
end

function ZO_CrownCratesCard:BonusDealFromWorldPositionToWorldPosition(startX, startY, startZ, endX, endY, endZ)
    self:SetupCardSide(ZO_CROWN_CRATES_CARD_SIDE_BACK)
    self.control:SetHidden(false)
    self.cardTextureControl:SetAlpha(1)
    self.cardGlowTextureControl:SetAlpha(0)

    local function TrackBonusDealComplete(timeline, completedPlaying)
        if completedPlaying then
            self:SetState(CARD_STATES.MYSTERY)
            self.owner:OnBonusDealCardComplete()

            --PFX
            self:StartParticle(self:AcquireTierSpecificParticle(CROWN_CRATE_TIERED_PARTICLES_MYSTERY))
            PlayCrownCrateTierSpecificParticleEffectSound(self.crownCrateTierId, CROWN_CRATE_TIERED_PARTICLES_MYSTERY)
        end
    end

    local animationTimeline = self:AcquireAndApplyAnimationTimeline(ZO_CROWN_CRATES_ANIMATION_BONUS_DEAL, self.control, TrackBonusDealComplete)

    --Setup translate to screen
    local translateToScreenAnimation = animationTimeline:GetAnimation(1)
    local scaledUpWidthUI = ZO_CROWN_CRATES_CARD_WIDTH_IN_HAND_UI * ZO_CROWN_CRATES_BONUS_DEAL_TO_SCREEN_SCALE_FACTOR
    local toScreenX = endX
    local toScreenY = 0
    local toScreenZ = ComputeDepthAtWhichWorldWidthRendersAsUIWidth(ZO_CROWN_CRATES_CARD_WIDTH_WORLD, scaledUpWidthUI)
    self:SetupBezierArcBetween(translateToScreenAnimation, startX, startY, startZ, toScreenX, toScreenY, toScreenZ, ZO_CROWN_CRATES_BONUS_DEAL_TO_SCREEN_ARC_CONTROL_POINT_Y_OFFSET_SCREEN_PERCENT)
    translateToScreenAnimation:SetHandler("OnStop", function(animation, animatingControl, completedPlaying)
        --start the bonus particle effect when the card finishes moving to the screen
        if completedPlaying then
            self:StartParticle(self:AcquireCrateSpecificParticle(CROWN_CRATE_PARTICLES_BONUS))
            PlayCrownCrateSpecificParticleEffectSound(GetCurrentCrownCrateId(), CROWN_CRATE_PARTICLES_BONUS)
        end
    end)

    --Setup translate to hand
    local translateToHandAnimation = animationTimeline:GetAnimation(2)
    local fallDriftXWorld = ZO_CrownCrates.ConvertUIUnitsToWorldUnits(self.owner:GetInHandCameraPlaneMetrics(), ZO_CROWN_CRATES_BONUS_DEAL_DRIFT_X_UI)
    translateToHandAnimation:SetTranslateOffsets(toScreenX, toScreenY, toScreenZ, endX, endY, endZ)
    translateToHandAnimation:SetBezierControlPoint(1, zo_lerp(toScreenX, endX, 1/3) + fallDriftXWorld, zo_lerp(toScreenY, endY, 1/3), zo_lerp(toScreenZ, endZ, 1/3))
    translateToHandAnimation:SetBezierControlPoint(2, zo_lerp(toScreenX, endX, 2/3) - fallDriftXWorld, zo_lerp(toScreenY, endY, 2/3), zo_lerp(toScreenZ, endZ, 2/3))
    translateToHandAnimation:SetHandler("OnPlay", function()
        --stop the bonus particle effect as soon as it moves to hand
        self:ReleaseParticle()
    end)

    --Play
    self:StartAnimation(animationTimeline)

    local glowAnimationTimeline = self:AcquireAndApplyAnimationTimeline(ZO_CROWN_CRATES_ANIMATION_BONUS_DEAL_GLOW, self.cardGlowTextureControl)
    self:StartAnimation(glowAnimationTimeline)

    self.rootX = endX
    self.rootY = endY
    self.rootZ = endZ
end

function ZO_CrownCratesCard:BonusSlideToWorldPosition(endX, endY, endZ)
    local startX, startY, startZ = self.control:Get3DRenderSpaceOrigin()
    local startPitch, startYaw, startRoll = self.control:Get3DRenderSpaceOrientation()

    local animationTimeline = self:AcquireAndApplyAnimationTimeline(ZO_CROWN_CRATES_ANIMATION_BONUS_SLIDE, self.control)

    --Setup rise
    local moveAnimation = animationTimeline:GetAnimation(1)
    local riseAnimationDonePercent = ZO_CROWN_CRATES_BONUS_SLIDE_RISE_DURATION_MS / ZO_CROWN_CRATES_BONUS_SLIDE_DURATION_MS
    local riseYOffsetWorld = ZO_CrownCrates.ConvertUIUnitsToWorldUnits(self.owner:GetInHandCameraPlaneMetrics(), ZO_CROWN_CRATES_BONUS_SLIDE_RISE_Y_UI)
    local riseEndX = zo_lerp(startX, endX, riseAnimationDonePercent)
    local riseEndY = startY + riseYOffsetWorld
    local riseEndZ = zo_lerp(startZ, endZ, riseAnimationDonePercent)
    moveAnimation:SetTranslateOffsets(startX, startY, startZ, endX, endY, endZ)
    moveAnimation:SetBezierControlPoint(1, riseEndX, riseEndY, riseEndZ)
    moveAnimation:SetBezierControlPoint(2, riseEndX, riseEndY, riseEndZ)

    --Setup tilt up
    local tiltUpAnimation = animationTimeline:GetAnimation(2)
    local endPitch = startPitch
    local endYaw = startYaw
    local endRoll
    if endX < startX then
        endRoll = ZO_CROWN_CRATES_BONUS_SLIDE_TILT_UP_RADIANS
    else
        endRoll = -ZO_CROWN_CRATES_BONUS_SLIDE_TILT_UP_RADIANS
    end
    tiltUpAnimation:SetRotationValues(startPitch, startYaw, startRoll, endPitch, endYaw, endRoll)

    --Setup un-tilt
    local untiltAnimation = animationTimeline:GetAnimation(3)
    startRoll = endRoll
    endRoll = 0
    untiltAnimation:SetRotationValues(startPitch, startYaw, startRoll, endPitch, endYaw, endRoll)

    --Play
    self:StartAnimation(animationTimeline)

    self.rootX = endX
    self.rootY = endY
    self.rootZ = endZ
end

function ZO_CrownCratesCard:Select()
    if self.side == ZO_CROWN_CRATES_CARD_SIDE_BACK and self:CanAnimateMystery() then
        self:MysterySelect()
    else
        self:RevealedSelect()
    end
    PlaySound(SOUNDS.CROWN_CRATES_CARD_SELECTED)
end

function ZO_CrownCratesCard:Deselect()
    if self.side == ZO_CROWN_CRATES_CARD_SIDE_BACK and self:CanAnimateMystery() then
        self:MysteryDeselect()
    else
        self:RevealedDeselect()
    end
end

function ZO_CrownCratesCard:IsSelected()
    return self.owner:GetSelectedCard() == self
end

function ZO_CrownCratesCard:OnMouseEnter()
    self.owner:SetSelectedCard(self)
end

function ZO_CrownCratesCard:OnMouseExit()
    self.owner:SetSelectedCard(nil)
end

function ZO_CrownCratesCard:OnMouseUp()
    if self:CanSelect() then
        if self:IsMystery() then
            self:Reveal()
        elseif self:IsRevealed() then
            self:ShowMenu()
        end
    end
end

function ZO_CrownCratesCard:ShowMenu()
    ClearMenu()
    if self:CanActivateCollectible() then
        AddMenuItem(GetString(SI_COLLECTIBLE_ACTION_SET_ACTIVE), function() UseCollectible(self.rewardReferenceDataId) end)
    end
    ShowMenu(self.control)
end

function ZO_CrownCratesCard:OnSelect()
    if self:CanSelect() then
        self:Select()
    end
end

function ZO_CrownCratesCard:OnDeselect()
    if self:CanSelect() then
        self:Deselect()
    end
end

function ZO_CrownCratesCard:CanAnimateMystery()
    return self.cardState == CARD_STATES.MYSTERY
end

function ZO_CrownCratesCard:StartMysterySelectedAnimation()
    local animationTimeline = self:AcquireAndApplyAnimationTimeline(ZO_CROWN_CRATES_ANIMATION_MYSTERY_SELECTED, self.control)
    self:StartAnimation(animationTimeline)
end

function ZO_CrownCratesCard:StartMysterySelectAnimation()
    local function AnimationOnStop(timeline, completedPlaying)
        if completedPlaying then
            if self:IsSelected() then
                self:StartMysterySelectedAnimation()
            else
                self:StartMysteryDeselectAnimation()
            end
        end
    end

    local floatOffsetYWorld = ZO_CrownCrates.ConvertUIUnitsToWorldUnits(self.owner:GetInHandCameraPlaneMetrics(), ZO_CROWN_CRATES_MYSTERY_SELECTION_OFFSET_Y_UI)
    local animationTimeline = self:AcquireAndApplyAnimationTimeline(ZO_CROWN_CRATES_ANIMATION_MYSTERY_SELECT, self.control, AnimationOnStop)
    local moveAnimation = animationTimeline:GetAnimation(1)
    moveAnimation:SetTranslateOffsets(self.rootX, self.rootY, self.rootZ, self.rootX, self.rootY + floatOffsetYWorld, self.rootZ)
    self:StartAnimation(animationTimeline)

    local glowAnimationTimeline = self:AcquireAndApplyAnimationTimeline(ZO_CROWN_CRATES_ANIMATION_MYSTERY_SELECTED_GLOW, self.cardGlowTextureControl)
    local glowAlphaAnimation = glowAnimationTimeline:GetAnimation(1)
    glowAlphaAnimation:SetAlphaValues(0, 1)
    self:StartAnimation(glowAnimationTimeline)
end

function ZO_CrownCratesCard:StartMysteryDeselectAnimation()
    local function AnimationOnStop(timeline, completedPlaying)
        if completedPlaying then
            if self:IsSelected() then
                self:StartMysterySelectAnimation()
            end
        end
    end

    local floatOffsetYWorld = ZO_CrownCrates.ConvertUIUnitsToWorldUnits(self.owner:GetInHandCameraPlaneMetrics(), ZO_CROWN_CRATES_MYSTERY_SELECTION_OFFSET_Y_UI)
    local animationTimeline = self:AcquireAndApplyAnimationTimeline(ZO_CROWN_CRATES_ANIMATION_MYSTERY_DESELECT, self.control, AnimationOnStop)
    local moveAnimation = animationTimeline:GetAnimation(1)
    moveAnimation:SetTranslateOffsets(self.rootX, self.rootY + floatOffsetYWorld, self.rootZ, self.rootX, self.rootY, self.rootZ)

    local rotateAnimation = animationTimeline:GetAnimation(2)
    local startPitch, startYaw, startRoll = self.control:Get3DRenderSpaceOrientation()
    rotateAnimation:SetRotationValues(startPitch, startYaw, startRoll, ZO_CROWN_CRATES_PRIMARY_DEAL_END_PITCH_RADIANS, ZO_CROWN_CRATES_PRIMARY_DEAL_END_YAW_RADIANS, ZO_CROWN_CRATES_PRIMARY_DEAL_END_ROLL_RADIANS)

    self:StartAnimation(animationTimeline)

    local glowAnimationTimeline = self:AcquireAndApplyAnimationTimeline(ZO_CROWN_CRATES_ANIMATION_MYSTERY_SELECTED_GLOW, self.cardGlowTextureControl)
    local glowAlphaAnimation = glowAnimationTimeline:GetAnimation(1)
    glowAlphaAnimation:SetAlphaValues(1, 0)
    self:StartAnimation(glowAnimationTimeline)
end

function ZO_CrownCratesCard:MysterySelect()
    if self:GetOnePlayingAnimationOfType(ZO_CROWN_CRATES_ANIMATION_MYSTERY_SELECTED) then
        --Already floating
    elseif self:GetOnePlayingAnimationOfType(ZO_CROWN_CRATES_ANIMATION_MYSTERY_SELECT) then
        --Already rising
    elseif self:GetOnePlayingAnimationOfType(ZO_CROWN_CRATES_ANIMATION_MYSTERY_DESELECT) then
        --Waiting on fall to complete to rise
    else
        self:StartMysterySelectAnimation()
    end
end

function ZO_CrownCratesCard:MysteryDeselect()
    if self:GetOnePlayingAnimationOfType(ZO_CROWN_CRATES_ANIMATION_MYSTERY_SELECTED) then
        self:StopAllAnimationsOfType(ZO_CROWN_CRATES_ANIMATION_MYSTERY_SELECTED)
        self:StartMysteryDeselectAnimation()
    elseif self:GetOnePlayingAnimationOfType(ZO_CROWN_CRATES_ANIMATION_MYSTERY_SELECT) then
        --Waiting on rise to complete to fall
    elseif self:GetOnePlayingAnimationOfType(ZO_CROWN_CRATES_ANIMATION_MYSTERY_DESELECT) then
        --Already falling
    end
end

function ZO_CrownCratesCard:Reveal()
    if self:GetOnePlayingAnimationOfType(ZO_CROWN_CRATES_ANIMATION_MYSTERY_SELECTED) then
        self:StopAllAnimationsOfType(ZO_CROWN_CRATES_ANIMATION_MYSTERY_SELECTED)
    end
    self:StopAllAnimationsOfType(ZO_CROWN_CRATES_ANIMATION_MYSTERY_SELECTED_GLOW)
    self:StopAllAnimationsOfType(ZO_CROWN_CRATES_ANIMATION_MYSTERY_SELECT)
    self:StopAllAnimationsOfType(ZO_CROWN_CRATES_ANIMATION_MYSTERY_DESELECT)
    
    self:SetState(CARD_STATES.FLIPPING)
    if self.playRevealSounds then
        PlaySound(SOUNDS.CROWN_CRATES_CARD_FLIPPING)
    end

    local startX, startY, startZ = self.control:Get3DRenderSpaceOrigin()
    local startPitch, startYaw, startRoll = self.control:Get3DRenderSpaceOrientation()
    local endX, endY, endZ = self.owner:ComputeSlotCenterWorldPosition(self.owner:GetRevealedCameraPlaneMetrics(), ZO_CROWN_CRATES_CARD_SPACING_REVEALED_UI, self.visualSlotIndex, GetNumCurrentCrownCrateTotalRewards())
    local offsetYWorld = ZO_CrownCrates.ConvertUIUnitsToWorldUnits(self.owner:GetRevealedCameraPlaneMetrics(), ZO_CROWN_CRATES_REVEAL_INFO_AREA_HEIGHT_UI)
    endY = endY + offsetYWorld

    local AnimationOnStop = function(timeline, completedPlaying)
        if completedPlaying then
            TriggerCrownCrateNPCAnimation(self.rewardReaction)
            if self.gemsExchanged == 0 then
                self:SetState(CARD_STATES.REVEALED)
                self.owner:OnCardFlipComplete()
            
                self:StartParticle(self:AcquireTierSpecificParticle(CROWN_CRATE_TIERED_PARTICLES_REVEALED))
                PlayCrownCrateTierSpecificParticleEffectSound(self.crownCrateTierId, CROWN_CRATE_TIERED_PARTICLES_REVEALED)
            else
                self:SetState(CARD_STATES.GEMIFY)
                self:Gemify()
            end
        end
    end
    local animationTimeline = self:AcquireAndApplyAnimationTimeline(ZO_CROWN_CRATES_ANIMATION_REVEAL, self.control, AnimationOnStop)
    
    local translateAnimation = animationTimeline:GetAnimation(1)
    translateAnimation:SetTranslateOffsets(startX, startY, startZ, endX, endY, endZ)

    local rotateAnimation = animationTimeline:GetAnimation(2)
    rotateAnimation:SetRotationValues(startPitch, startYaw, startRoll, ZO_CROWN_CRATES_REVEAL_END_PITCH_RADIANS, ZO_CROWN_CRATES_REVEAL_END_YAW_RADIANS, ZO_CROWN_CRATES_REVEAL_END_ROLL_RADIANS)
    self:StartAnimation(animationTimeline)

    --Setup update handler to watch for facing away from camera
    self.control:SetHandler("OnUpdate", function(control)
        if not self.cardTextureControl:Is3DQuadFacingCamera() then
            self:SetupCardSide(ZO_CROWN_CRATES_CARD_SIDE_FACE)
            self.cardGlowTextureControl:SetAlpha(0)
            control:SetHandler("OnUpdate", nil)
            if self:IsSelected() then
                self:RevealedSelect()
            end
            self:ShowInfo()
        end 
    end)

    --PFX
    self:StartParticle(self:AcquireTierSpecificParticle(CROWN_CRATE_TIERED_PARTICLES_REVEAL))
    PlayCrownCrateTierSpecificParticleEffectSound(self.crownCrateTierId, CROWN_CRATE_TIERED_PARTICLES_REVEAL)

    --Resize the mouse over area back to the card dimensions
    self.mouseAreaControl:Set3DLocalDimensions(ZO_CROWN_CRATES_CARD_WIDTH_WORLD, ZO_CROWN_CRATES_CARD_HEIGHT_WORLD)
    self.mouseAreaControl:Set3DRenderSpaceOrigin(0, 0, 0)

    local OnMouseEnter = function()
        self:OnMouseEnter()
    end
    local OnMouseExit = function()
        self:OnMouseExit()
    end
    self.mouseAreaControl:SetHandler("OnMouseEnter", OnMouseEnter)
    self.mouseAreaControl:SetHandler("OnMouseExit", OnMouseExit)
end

function ZO_CrownCratesCard:Gemify()
    local AnimationOnStop = function(timeline, completedPlaying)
        if completedPlaying then
            self:StartSingleGemsAnimation()
        end
    end

    local cardAnimationTimeline = self:AcquireAndApplyAnimationTimeline(ZO_CROWN_CRATES_ANIMATION_GEMIFY_CARD, self.control, AnimationOnStop)
    self:StartAnimation(cardAnimationTimeline)
    --Setup update handler to watch for facing toward the camera again
    self.control:SetHandler("OnUpdate", function(control)
        if self.cardTextureControl:Is3DQuadFacingCamera() then
            self:SetupCardSide(ZO_CROWN_CRATES_CARD_SIDE_GEMIFIED_FACE)
            self.colorTintOverlayTextureControl:SetAlpha(ZO_CROWN_CRATES_GEMIFY_TINT_ALPHA)
            self.colorFlashOverlayTextureControl:SetAlpha(0)
            local gemsIcon = CROWN_CRATES:GetFormattedGemIcon()
            self.nameLabel:SetText(zo_strformat(SI_CROWN_CRATE_REWARD_WITH_GEMS_EXCHANGED, self.rewardName, self.gemsExchanged, gemsIcon))

            control:SetHandler("OnUpdate", nil)
        end 
    end)

    self:StartParticle(self:AcquireCrateSpecificParticle(CROWN_CRATE_PARTICLES_GEMIFY))
    PlayCrownCrateSpecificParticleEffectSound(GetCurrentCrownCrateId(), CROWN_CRATE_PARTICLES_GEMIFY)

    PlaySound(SOUNDS.CROWN_CRATES_GAIN_GEMS)
end

function ZO_CrownCratesCard:StartSingleGemsAnimation()
    local cardCenterX, cardCenterY = ZO_CrownCrates.ComputeSlotCenterUIPosition(ZO_CROWN_CRATES_CARD_WIDTH_REVEALED_UI, 
                                                                                ZO_CROWN_CRATES_CARD_HEIGHT_REVEALED_UI, 
                                                                                ZO_CrownCrates.GetBottomOffsetUI() + self.nameAreaControl:GetHeight(),
                                                                                ZO_CROWN_CRATES_CARD_SPACING_REVEALED_UI, 
                                                                                self.visualSlotIndex, 
                                                                                GetNumCurrentCrownCrateTotalRewards())
    self.totalSingleGemsPlaying = ZO_CROWN_CRATES_GEMIFY_TOTAL_SINGLE_GEMS_TO_PLAY

    for i = 1, self.totalSingleGemsPlaying do
        local nextSingleGem, objectKey = self.singleGemPool:AcquireObject()
        nextSingleGem:SetHidden(false)

        local AnimationOnStop = function(timeline, completedPlaying)
            if completedPlaying then
                self:EndSingleGemAnimation(objectKey)
            end
        end

        local singleGemAnimationTimeline = self:AcquireAndApplyAnimationTimeline(ZO_CROWN_CRATES_ANIMATION_GEMIFY_SINGLE_GEM_GAIN, nextSingleGem, AnimationOnStop)

        local translateAnimation = singleGemAnimationTimeline:GetAnimation(2)
        local halfCardHeight = ZO_CROWN_CRATES_CARD_HEIGHT_REVEALED_UI / 2
        local nextAngle = ((i - 1) * - ZO_CROWN_CRATES_GEMIFY_SINGLE_GEM_DELTA_ANGLE_DEGREES) - ZO_CROWN_CRATES_GEMIFY_SINGLE_GEM_STARTING_ANGLE_DEGREES
        local offsetX = halfCardHeight * math.cos(math.rad(nextAngle))
        local offsetY = halfCardHeight * math.sin(math.rad(nextAngle))
        translateAnimation:SetTranslateOffsets(cardCenterX + offsetX, cardCenterY + offsetY, cardCenterX, cardCenterY)
        nextSingleGem:SetAnchor(CENTER, GuiRoot, TOPLEFT, cardCenterX + offsetX, cardCenterY + offsetY)
        nextSingleGem:SetAlpha(0)
        zo_callLater( function() self:StartAnimation(singleGemAnimationTimeline) end, (self.totalSingleGemsPlaying - i) * ZO_CROWN_CRATES_GEMIFY_SINGLE_GEM_START_TIME_DELAY_MS)
    end
end

function ZO_CrownCratesCard:EndSingleGemAnimation(objectKey)
    self.singleGemPool:ReleaseObject(objectKey)
    self.totalSingleGemsPlaying = self.totalSingleGemsPlaying - 1
    if self.totalSingleGemsPlaying == 0 then
        local cardCenterX, cardCenterY = ZO_CrownCrates.ComputeSlotCenterUIPosition(ZO_CROWN_CRATES_CARD_WIDTH_REVEALED_UI, 
                                                                                    ZO_CROWN_CRATES_CARD_HEIGHT_REVEALED_UI, 
                                                                                    ZO_CrownCrates.GetBottomOffsetUI() + self.nameAreaControl:GetHeight(), 
                                                                                    ZO_CROWN_CRATES_CARD_SPACING_REVEALED_UI, 
                                                                                    self.visualSlotIndex, 
                                                                                    GetNumCurrentCrownCrateTotalRewards())
        local finalGem, finalObjectKey = self.singleGemPool:AcquireObject()
        finalGem:SetHidden(false)

        local AnimationOnStop = function(timeline, completedPlaying)
            if completedPlaying then
                self:SetState(CARD_STATES.REVEALED)
                self.owner:OnCardFlipComplete()
                self:StartParticle(self:AcquireTierSpecificParticle(CROWN_CRATE_TIERED_PARTICLES_REVEALED))
                PlayCrownCrateTierSpecificParticleEffectSound(self.crownCrateTierId, CROWN_CRATE_TIERED_PARTICLES_REVEALED)
                self.gemOverlayTextureControl:SetAlpha(1)
                self.singleGemPool:ReleaseObject(finalObjectKey)
            end
        end

        finalGem:SetAnchor(CENTER, GuiRoot, TOPLEFT, cardCenterX, cardCenterY)
        local finalGemAnimationTimeline = self:AcquireAndApplyAnimationTimeline(ZO_CROWN_CRATES_ANIMATION_GEMIFY_FINAL_GEM, finalGem, AnimationOnStop)
        self:StartAnimation(finalGemAnimationTimeline)

        CROWN_CRATES:AddCrownGems(self.gemsExchanged)

        local gemsIcon = CROWN_CRATES:GetFormattedGemIcon()
        self.gemGainLabel:SetText(zo_strformat(SI_CROWN_CRATE_GEMS_GAINED_FORMAT, self.gemsExchanged, gemsIcon))
        self.gemGainLabel:SetAlpha(1)
        local gemTextAnimationTimeline = self:AcquireAndApplyAnimationTimeline(ZO_CROWN_CRATES_ANIMATION_GEMIFY_CROWN_GEM_TEXT, self.gemGainLabel)
        self:StartAnimation(gemTextAnimationTimeline)

    elseif self.totalSingleGemsPlaying == ZO_CROWN_CRATES_GEMIFY_SINGLE_GEM_INDEX_TO_START_FLASH then
        local colorTintAnimationTimeline = self:AcquireAndApplyAnimationTimeline(ZO_CROWN_CRATES_ANIMATION_GEMIFY_COLOR_TINT, self.colorFlashOverlayTextureControl)
        self:StartAnimation(colorTintAnimationTimeline)
    end
end

function ZO_CrownCratesCard:SuppressRevealSounds()
    self.playRevealSounds = false
end

function ZO_CrownCratesCard:RevealedSelect()
    if self:GetOnePlayingAnimationOfType(ZO_CROWN_CRATES_ANIMATION_REVEALED_SELECTED_GLOW) then
        self:EnsureAnimationsArePlayingInDirection(ZO_CROWN_CRATES_ANIMATION_REVEALED_SELECTED_GLOW, FORWARD)
    elseif self.cardGlowTextureControl:GetAlpha() ~= 1 then
        local animationTimeline = self:AcquireAndApplyAnimationTimeline(ZO_CROWN_CRATES_ANIMATION_REVEALED_SELECTED_GLOW, self.cardGlowTextureControl)
        self:StartAnimation(animationTimeline, FORWARD)
    end
end

function ZO_CrownCratesCard:RevealedDeselect()
    if self:GetOnePlayingAnimationOfType(ZO_CROWN_CRATES_ANIMATION_REVEALED_SELECTED_GLOW) then
        self:EnsureAnimationsArePlayingInDirection(ZO_CROWN_CRATES_ANIMATION_REVEALED_SELECTED_GLOW, BACKWARD)
    elseif self.cardGlowTextureControl:GetAlpha() ~= 0 then
        local animationTimeline = self:AcquireAndApplyAnimationTimeline(ZO_CROWN_CRATES_ANIMATION_REVEALED_SELECTED_GLOW, self.cardGlowTextureControl)
        self:StartAnimation(animationTimeline, BACKWARD)
    end
end

function ZO_CrownCratesCard:ShowInfo()
    --Name
    local animationTimeline = self:AcquireAndApplyAnimationTimeline(ZO_CROWN_CRATES_ANIMATION_CARD_SHOW_INFO, self.nameAreaControl)
    local translateAnimation = animationTimeline:GetAnimation(2)
    local infoX, infoY = ZO_CrownCrates.ComputeSlotBottomUIPosition(ZO_CROWN_CRATES_CARD_WIDTH_REVEALED_UI, ZO_CROWN_CRATES_CARD_SPACING_REVEALED_UI, self.visualSlotIndex, GetNumCurrentCrownCrateTotalRewards())
    self.nameAreaControl:ClearAnchors()
    self.nameAreaControl:SetAnchor(BOTTOM, GuiRoot, TOPLEFT, infoX, infoY)
    if self.stackCount > 1 then
       	self.nameLabel:SetText(zo_strformat(SI_CROWN_CRATE_REWARD_WITH_STACK_NAME, self.rewardName, self.stackCount))
    else
        self.nameLabel:SetText(zo_strformat(SI_CROWN_CRATE_REWARD_NAME, self.rewardName))
    end
    translateAnimation:SetTranslateOffsets(infoX, infoY + ZO_CROWN_CRATES_CARD_SHOW_INFO_NAME_OFFSET_Y_UI, infoX, infoY)
    self:StartAnimation(animationTimeline)

    --Reward Type
    animationTimeline = self:AcquireAndApplyAnimationTimeline(ZO_CROWN_CRATES_ANIMATION_CARD_SHOW_INFO, self.rewardTypeAreaControl)
    translateAnimation = animationTimeline:GetAnimation(2)
    infoY = infoY - ZO_CROWN_CRATES_REVEAL_INFO_AREA_HEIGHT_UI - ZO_CROWN_CRATES_CARD_HEIGHT_REVEALED_UI
    self.rewardTypeAreaControl:ClearAnchors()
    self.rewardTypeAreaControl:SetAnchor(BOTTOM, GuiRoot, TOPLEFT, infoX, infoY)
    self.rewardTypeLabel:SetText(self.rewardTypeText)
    translateAnimation:SetTranslateOffsets(infoX, infoY + ZO_CROWN_CRATES_CARD_SHOW_INFO_REWARD_TYPE_OFFSET_Y_UI, infoX, infoY)
    self:StartAnimation(animationTimeline)
end

function ZO_CrownCratesCard:HideInfo()
    self:StopAllAnimationsOfType(ZO_CROWN_CRATES_ANIMATION_SHOW_INFO)

    --Name
    local animationTimeline = self:AcquireAndApplyAnimationTimeline(ZO_CROWN_CRATES_ANIMATION_CARD_HIDE_INFO, self.nameAreaControl)
    local alphaAnimation = animationTimeline:GetAnimation(1)
    alphaAnimation:SetAlphaValues(self.nameAreaControl:GetAlpha(), 0)
    self:StartAnimation(animationTimeline)

    --Reward Type
    animationTimeline = self:AcquireAndApplyAnimationTimeline(ZO_CROWN_CRATES_ANIMATION_CARD_HIDE_INFO, self.rewardTypeAreaControl)
    alphaAnimation = animationTimeline:GetAnimation(1)
    alphaAnimation:SetAlphaValues(self.rewardTypeAreaControl:GetAlpha(), 0)
    self:StartAnimation(animationTimeline)
end

function ZO_CrownCratesCard:Leave()
    self:StopAllAnimationsOfType(ZO_CROWN_CRATES_ANIMATION_REVEALED_SELECTED_GLOW)
    self:ReleaseParticle()

    -- if the card is gemified, it will have been flipped 180 degrees, 
    -- meaning we need to change the endPitch to match with the current pitch of the card
    local startPitch, startYaw, startRoll = self.control:Get3DRenderSpaceOrientation()
    local endPitch = ZO_CROWN_CRATES_LEAVE_END_PITCH_RADIANS
    if self.side == ZO_CROWN_CRATES_CARD_SIDE_GEMIFIED_FACE then
         endPitch = ZO_CROWN_CRATES_GEMIFY_END_PITCH_RADIANS
    end

    local AnimationOnStop = function()
        self.owner:OnCardLeaveComplete()
    end

    local offsetXUI = GuiRoot:GetWidth()
    local offsetXWorld = ZO_CrownCrates.ConvertUIUnitsToWorldUnits(self.owner:GetRevealedCameraPlaneMetrics(), offsetXUI)
    local animationTimeline = self:AcquireAndApplyAnimationTimeline(ZO_CROWN_CRATES_ANIMATION_LEAVE, self.control, AnimationOnStop)
    local moveAnimation = animationTimeline:GetAnimation(1)
    local startX, startY, startZ = self.control:Get3DRenderSpaceOrigin()
    moveAnimation:SetTranslateOffsets(startX, startY, startZ, startX + offsetXWorld, startY, startZ)

    local rotateAnimation = animationTimeline:GetAnimation(2)
    rotateAnimation:SetRotationValues(startPitch, startYaw, startRoll, endPitch, ZO_CROWN_CRATES_LEAVE_END_YAW_RADIANS, ZO_CROWN_CRATES_LEAVE_END_ROLL_RADIANS)
    
    self:StartAnimation(animationTimeline)

    --Setup update handler to watch for facing toward the camera
    self.control:SetHandler("OnUpdate", function(control)
        if (self.side == ZO_CROWN_CRATES_CARD_SIDE_FACE and self.cardTextureControl:Is3DQuadFacingCamera())
            or (self.side == ZO_CROWN_CRATES_CARD_SIDE_GEMIFIED_FACE and not self.cardTextureControl:Is3DQuadFacingCamera()) then
            self:SetupCardSide(ZO_CROWN_CRATES_CARD_SIDE_BACK)
            self.cardGlowTextureControl:SetAlpha(0)
            self.rewardTextureControl:SetAlpha(0)
            self.frameAccentTextureControl:SetAlpha(0)
            self.gemOverlayTextureControl:SetAlpha(0)
            self:SetCardFaceDesaturation(0)
            control:SetHandler("OnUpdate", nil)
        end 
    end)

    self:HideInfo()
end

function ZO_CrownCratesCard:IsMystery()
    return self.cardState == CARD_STATES.MYSTERY
end

function ZO_CrownCratesCard:IsRevealed()
    return self.cardState == CARD_STATES.REVEALED
end

function ZO_CrownCratesCard:CanSelect()
    return not (self.cardState == CARD_STATES.START 
           or self.cardState == CARD_STATES.LEAVING)
           and (ZO_CROWN_CRATE_STATE_MACHINE:GetCurrentState() == ZO_CROWN_CRATE_STATES.ACTIVE_HAND_MANIPULATION 
           or ZO_CROWN_CRATE_STATE_MACHINE:GetCurrentState() == ZO_CROWN_CRATE_STATES.ALL_REVEALED)
end

function ZO_CrownCratesCard:SetState(newState)
    self.cardState = newState
end

function ZO_CrownCratesCard:GetState()
    return self.cardState
end

function ZO_CrownCratesCard:IsGemified()
    return self.gemsExchanged > 0
end

function ZO_CrownCratesCard:SetCardFaceDesaturation(amount)
    self.rewardTextureControl:SetDesaturation(amount)
    self.frameAccentTextureControl:SetDesaturation(amount)
    self.cardTextureControl:SetDesaturation(amount)
end

do
    local DISALLOWED_EQUIPPABLE_COLLECTIBLE_TYPES =
    {
        [COLLECTIBLE_CATEGORY_TYPE_ASSISTANT] = true,
        [COLLECTIBLE_CATEGORY_TYPE_TROPHY] = true,
        [COLLECTIBLE_CATEGORY_TYPE_DLC] = true,
    }

    function ZO_CrownCratesCard:CanActivateCollectible()
        if self.rewardProductType == MARKET_PRODUCT_TYPE_COLLECTIBLE and not self:IsGemified() then
            local collectibleId = self.rewardReferenceDataId
            if IsCollectibleUsable(collectibleId) and IsCollectibleValidForPlayer(collectibleId) then
                local isActive, categoryType = select(7, GetCollectibleInfo(collectibleId))

                return not (isActive or DISALLOWED_EQUIPPABLE_COLLECTIBLE_TYPES[categoryType])
            end
        end
        return false
    end
end

-----------------------------
--Crown Crates Card Opening--
-----------------------------

ZO_CrownCratesPackOpening = ZO_Object:Subclass()

function ZO_CrownCratesPackOpening:New(...)
    local obj = ZO_Object.New(self)
    obj:Initialize(...)
    return obj
end

function ZO_CrownCratesPackOpening:Initialize(owner)
    self.owner = owner
    self.nextCardIndex = 1
    self.cardsInVisualOrder = {}
    self:InitializeCardPool()
    self:InitializeKeybinds()
    
    self.initialized = true
end

function ZO_CrownCratesPackOpening:OnLockLocalSpaceToCurrentCamera()
    self.inHandCameraPlaneMetrics = self.owner:ComputeCameraPlaneMetrics(ZO_CROWN_CRATES_CARD_WIDTH_WORLD, ZO_CROWN_CRATES_CARD_WIDTH_IN_HAND_UI)
    self.revealedCameraPlaneMetrics = self.owner:ComputeCameraPlaneMetrics(ZO_CROWN_CRATES_CARD_WIDTH_WORLD, ZO_CROWN_CRATES_CARD_WIDTH_REVEALED_UI)
end

function ZO_CrownCratesPackOpening:GetInHandCameraPlaneMetrics()
    return self.inHandCameraPlaneMetrics
end

function ZO_CrownCratesPackOpening:GetRevealedCameraPlaneMetrics()
    return self.revealedCameraPlaneMetrics
end

function ZO_CrownCratesPackOpening:InitializeCardPool()
    local reset = function(card)
        card:Reset()
    end    
    local factory = function(pool)
                        local card = ZO_CrownCratesCard:New(CreateControlFromVirtual("$(parent)Card", self.owner:GetControl(), "ZO_CrownCrateCard", self.nextCardIndex), self)
                        self.nextCardIndex = self.nextCardIndex + 1
                        return card
                    end
    
    self.cardPool = ZO_ObjectPool:New(factory, reset)
end

function ZO_CrownCratesPackOpening:InitializeKeybinds()
    -- Keyboard --
    self.keyboardHandManipulationKeybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_CENTER,

        {
            keybind = "UI_SHORTCUT_PRIMARY",
            name = GetString(SI_CROWN_CRATE_REVEAL_NEXT_REWARD_KEYBIND),
            callback = function()
                local card = self:GetNextMysteryCard()
                if card then
                    card:Reveal()
                end
            end,
        },

        {
            keybind = "UI_SHORTCUT_SECONDARY",
            name = GetString(SI_CROWN_CRATE_REVEAL_ALL_REWARDS_KEYBIND),
            callback = function()
                self:RevealAllCards()
            end,
        }
    }

    self.keyboardAllRevealedKeybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_CENTER,

        ZO_CROWN_CRATES_BUY_CRATES_KEYBIND_KEYBOARD,
    }

    -- Gamepad --
    local activateCollectibleKeybind =
    {
        keybind = "UI_SHORTCUT_TERTIARY",
        name = GetString(SI_COLLECTIBLE_ACTION_SET_ACTIVE),
        callback = function()
            local card = self:GetSelectedCard()
            UseCollectible(card.rewardReferenceDataId)
        end,
        visible = function()
            local card = self:GetSelectedCard()
            return card and card:IsRevealed() and card:CanActivateCollectible()
        end
    }

    self.gamepadHandManipulationKeybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_CENTER,

        {
            keybind = "UI_SHORTCUT_PRIMARY",
            name = GetString(SI_CROWN_CRATE_REVEAL_SELECTED_REWARD_KEYBIND),
            callback = function()
                local card = self:GetSelectedCard()
                card:Reveal()
                self:RefreshKeybindings()
            end,
            enabled = function()
                local card = self:GetSelectedCard()
                return card and card:IsMystery()
            end
        },

        activateCollectibleKeybind,

        {
            keybind = "UI_SHORTCUT_SECONDARY",
            name = GetString(SI_CROWN_CRATE_REVEAL_ALL_REWARDS_KEYBIND),
            callback = function()
                self:RevealAllCards()
            end,
        },
    }

    self.gamepadAllRevealedKeybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_CENTER,

        activateCollectibleKeybind,
        ZO_CROWN_CRATES_BUY_CRATES_KEYBIND_GAMEPAD,
    }

    local function RefreshKeybindings()
        self:RefreshKeybindings()
    end

    COLLECTIONS_BOOK_SINGLETON:RegisterCallback("OnCollectibleUpdated", RefreshKeybindings)
    COLLECTIONS_BOOK_SINGLETON:RegisterCallback("OnCollectionUpdated", RefreshKeybindings)
    COLLECTIONS_BOOK_SINGLETON:RegisterCallback("OnCollectiblesUpdated", RefreshKeybindings)
end

function ZO_CrownCratesPackOpening:RefreshKeybindings()
    if SCENE_MANAGER:IsCurrentSceneGamepad() then
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.gamepadHandManipulationKeybindStripDescriptor)
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.gamepadAllRevealedKeybindStripDescriptor)
    else
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keyboardHandManipulationKeybindStripDescriptor)
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keyboardAllRevealedKeybindStripDescriptor)
    end
end


function ZO_CrownCratesPackOpening:GetCard(cardIndex)
    local card = self.cardPool:AcquireObject(cardIndex)
    card:SetRewardIndex(cardIndex)
    return card
end

function ZO_CrownCratesPackOpening:GetCardInVisualOrder(visualIndex)
    return self.cardsInVisualOrder[visualIndex]
end

function ZO_CrownCratesPackOpening:GetVisualCardCount()
    return #self.cardsInVisualOrder
end

function ZO_CrownCratesPackOpening:GetNextMysteryCard()
    for _, card in ipairs(self.cardsInVisualOrder) do
        if card:IsMystery() then
            return card
        end
    end
    return nil
end

function ZO_CrownCratesPackOpening:GetFirstSelectedCard()
    for _, card in ipairs(self.cardsInVisualOrder) do
        if card:IsSelected() then
            return card
        end
    end
    return nil
end

function ZO_CrownCratesPackOpening:RevealAllCards()
    TriggerCrownCrateNPCAnimation(CROWN_CRATE_NPC_ANIMATION_TYPE_REVEAL_ALL_CARDS)
    local mysteryCards = self:GetAllMysteryCards()
    for i, card in ipairs(mysteryCards) do
        card:SuppressRevealSounds()
        card:SetState(CARD_STATES.FLIPPING)
        zo_callLater(function()
                        if card.visualSlotIndex then
                            card:Reveal()
                        end
                     end, (i - 1) * ZO_CROWN_CRATES_REVEAL_ALL_OFFSET_DURATION_MS)
    end
    PlaySound(SOUNDS.CROWN_CRATES_CARDS_REVEAL_ALL)
end

function ZO_CrownCratesPackOpening:GetAllMysteryCards()
    local mysteryCards = {}
    for _, card in ipairs(self.cardsInVisualOrder) do
        if card:IsMystery() then
            table.insert(mysteryCards, card)
        end
    end
    return mysteryCards
end

function ZO_CrownCratesPackOpening:ResetCards()
    ZO_ClearNumericallyIndexedTable(self.cardsInVisualOrder)
    self.cardPool:ReleaseAllObjects()
end

function ZO_CrownCratesPackOpening:ComputeSlotCenterWorldPosition(planeMetrics, spacingUI, slotIndex, totalSlots)
    local spacingWorldWidth = spacingUI * planeMetrics.worldUnitsPerUIUnit
    local totalWorldWidth = totalSlots * ZO_CROWN_CRATES_CARD_WIDTH_WORLD + (totalSlots - 1) * spacingWorldWidth
    local slotCenterX = ZO_CROWN_CRATES_CARD_WIDTH_WORLD * 0.5 + (slotIndex - 1) * (ZO_CROWN_CRATES_CARD_WIDTH_WORLD + spacingWorldWidth)
    local bottomOffsetWorld = ZO_CrownCrates.GetBottomOffsetUI() * planeMetrics.worldUnitsPerUIUnit
    
    local x = slotCenterX - totalWorldWidth * 0.5
    local y = planeMetrics.frustumHeightWorld * -0.5 + ZO_CROWN_CRATES_CARD_HEIGHT_WORLD * 0.5 + bottomOffsetWorld
    local z = planeMetrics.depthFromCamera

    return x, y, z
end

function ZO_CrownCratesPackOpening:StartPrimaryDealAnimation(sourceX, sourceY, sourceZ)
    local numNormalCards = GetNumCurrentCrownCratePrimaryRewards()

    ZO_ClearNumericallyIndexedTable(self.cardsInVisualOrder)
    for i = 1, numNormalCards do
        local card = self:GetCard(i)
        ZO_TableRandomInsert(self.cardsInVisualOrder, card)
    end

    for visualIndex, card in ipairs(self.cardsInVisualOrder) do
        card:InitializeForDeal(visualIndex)
        local endX, endY, endZ = self:ComputeSlotCenterWorldPosition(self.inHandCameraPlaneMetrics, ZO_CROWN_CRATES_CARD_SPACING_IN_HAND_UI, visualIndex, numNormalCards)
        zo_callLater(function()
            if card.visualSlotIndex then
                card:PrimayDealFromWorldPositionToWorldPosition(sourceX, sourceY, sourceZ, endX, endY, endZ)
            end
        end, (visualIndex - 1) * ZO_CROWN_CRATES_PRIMARY_DEAL_SPACING_DURATION_MS)
    end
end

function ZO_CrownCratesPackOpening:StartBonusDealAnimation(sourceX, sourceY, sourceZ)
    local numBonusCards = GetNumCurrentCrownCrateBonusRewards()
    if numBonusCards > 0 then
        --Slide normal cards to make space
        local numNormalCards = GetNumCurrentCrownCratePrimaryRewards()
        local numTotalCards = numNormalCards + numBonusCards
        local splitCard = zo_floor(numNormalCards / 2)

        --Backwards because the inner cards go first
        local distanceFromEdge = 0
        for i = splitCard, 1, -1 do
            local card = self:GetCardInVisualOrder(i)
            local endX, endY, endZ = self:ComputeSlotCenterWorldPosition(self.inHandCameraPlaneMetrics, ZO_CROWN_CRATES_CARD_SPACING_IN_HAND_UI, i, numTotalCards)
            zo_callLater(function()
                if card.visualSlotIndex then
                    card:BonusSlideToWorldPosition(endX, endY, endZ)
                end
            end, ZO_CROWN_CRATES_BONUS_SLIDE_DELAY_MS + distanceFromEdge * ZO_CROWN_CRATES_BONUS_SLIDE_SPACING_DURATION_MS)
            distanceFromEdge = distanceFromEdge + 1
        end

        distanceFromEdge = 0
        for i = splitCard + 1, numNormalCards do
            local card = self:GetCardInVisualOrder(i)
            local visualSlotIndex = i + numBonusCards
            card:SetVisualSlotIndex(visualSlotIndex)
            local endX, endY, endZ = self:ComputeSlotCenterWorldPosition(self.inHandCameraPlaneMetrics, ZO_CROWN_CRATES_CARD_SPACING_IN_HAND_UI, visualSlotIndex, numTotalCards)
            zo_callLater(function()
                if card.visualSlotIndex then
                    card:BonusSlideToWorldPosition(endX, endY, endZ)
                end
            end, ZO_CROWN_CRATES_BONUS_SLIDE_DELAY_MS + distanceFromEdge * ZO_CROWN_CRATES_BONUS_SLIDE_SPACING_DURATION_MS)
            distanceFromEdge = distanceFromEdge + 1
        end

        --Deal bonus cards
        for i = 1, numBonusCards do
            local card = self:GetCard(numNormalCards + i)
            local visualSlotIndex = splitCard + i
            card:InitializeForDeal(visualSlotIndex)
            local endX, endY, endZ = self:ComputeSlotCenterWorldPosition(self.inHandCameraPlaneMetrics, ZO_CROWN_CRATES_CARD_SPACING_IN_HAND_UI, visualSlotIndex, numTotalCards)
            zo_callLater(function()
                if card.visualSlotIndex then
                    card:BonusDealFromWorldPositionToWorldPosition(sourceX, sourceY, sourceZ, endX, endY, endZ)
                end
            end, (i - 1) * ZO_CROWN_CRATES_BONUS_DEAL_SPACING_DURATION_MS)
            table.insert(self.cardsInVisualOrder, splitCard + 1, card)
        end
    end
end

function ZO_CrownCratesPackOpening:StartLeaveAnimation()
    local leavingIndex = 0
    for i = #self.cardsInVisualOrder, 1, -1 do
        local card = self.cardsInVisualOrder[i]
        zo_callLater(function()
            if card.visualSlotIndex then
                card:Leave()
                card:SetState(CARD_STATES.LEAVING)
            end
        end, leavingIndex * ZO_CROWN_CRATES_LEAVE_SPACING_MS)
        leavingIndex = leavingIndex + 1
    end
    PlaySound(SOUNDS.CROWN_CRATES_CARDS_LEAVE)
    ClearMenu()
end

function ZO_CrownCratesPackOpening:AddHandManipulationKeybinds()
    if self.initialized then
        if SCENE_MANAGER:IsCurrentSceneGamepad() then
            self:SetSelectedCard(CROWN_CRATES_PACK_OPENING:GetNextMysteryCard())
            KEYBIND_STRIP:AddKeybindButtonGroup(self.gamepadHandManipulationKeybindStripDescriptor)
        else
            KEYBIND_STRIP:AddKeybindButtonGroup(self.keyboardHandManipulationKeybindStripDescriptor)
        end
    end
end

function ZO_CrownCratesPackOpening:RemoveHandManipulationKeybinds()
    if self.initialized then
        if SCENE_MANAGER:IsCurrentSceneGamepad() then
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.gamepadHandManipulationKeybindStripDescriptor)
        else
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keyboardHandManipulationKeybindStripDescriptor)
        end
    end
end

function ZO_CrownCratesPackOpening:AddAllRevealedKeybinds()
    if self.initialized then
        if SCENE_MANAGER:IsCurrentSceneGamepad() then
            KEYBIND_STRIP:AddKeybindButtonGroup(self.gamepadAllRevealedKeybindStripDescriptor)
        else
            KEYBIND_STRIP:AddKeybindButtonGroup(self.keyboardAllRevealedKeybindStripDescriptor)
        end
    end
end

function ZO_CrownCratesPackOpening:RemoveAllRevealedKeybinds()
    if self.initialized then
        if SCENE_MANAGER:IsCurrentSceneGamepad() then
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.gamepadAllRevealedKeybindStripDescriptor)
        else
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keyboardAllRevealedKeybindStripDescriptor)
        end
    end
end

function ZO_CrownCratesPackOpening:HandleDirectionalInput(selectedDirection)
    if (ZO_CROWN_CRATE_STATE_MACHINE:GetCurrentState() == ZO_CROWN_CRATE_STATES.ACTIVE_HAND_MANIPULATION
       or ZO_CROWN_CRATE_STATE_MACHINE:GetCurrentState() == ZO_CROWN_CRATE_STATES.ALL_REVEALED) and selectedDirection then
        local selectedCard = self:GetSelectedCard()
        local nextCard
        if selectedCard then
            local nextVisualSlotIndex = selectedCard.visualSlotIndex + selectedDirection
            if nextVisualSlotIndex > self:GetVisualCardCount() then
                nextVisualSlotIndex = 1
            elseif nextVisualSlotIndex < 1 then
                nextVisualSlotIndex = self:GetVisualCardCount()
            end
            nextCard = self:GetCardInVisualOrder(nextVisualSlotIndex)
        else
            -- this is specifically for players using the gamepad UI but using a mouse and gamepad to navigate this
            nextCard = self:GetCardInVisualOrder(1)
        end
        self:SetSelectedCard(nextCard)
        self:RefreshKeybindings()
    end
end

function ZO_CrownCratesPackOpening:GetSelectedCard()
    return self.selectedCard
end

function ZO_CrownCratesPackOpening:SetSelectedCard(card)
    if self.selectedCard ~= card then
        if self.selectedCard then
            self.selectedCard:OnDeselect()
        end

        self.selectedCard = card

        if card then
            card:OnSelect()
        end
    end
end

function ZO_CrownCratesPackOpening:RefreshSelectedCard()
    if self.selectedCard then
        self.selectedCard:OnSelect()
    end
end

function ZO_CrownCratesPackOpening:OnPrimaryDealCardComplete()
    ZO_CROWN_CRATE_STATE_MACHINE:FireCallbacks(ZO_CROWN_CRATE_TRIGGER_COMMANDS.PRIMARY_DEAL_COMPLETE)
end

function ZO_CrownCratesPackOpening:OnBonusDealCardComplete()
    ZO_CROWN_CRATE_STATE_MACHINE:FireCallbacks(ZO_CROWN_CRATE_TRIGGER_COMMANDS.BONUS_DEAL_COMPLETE)
end

function ZO_CrownCratesPackOpening:OnCardFlipComplete()
    ZO_CROWN_CRATE_STATE_MACHINE:FireCallbacks(ZO_CROWN_CRATE_TRIGGER_COMMANDS.CARD_REVEALED)
    self:RefreshKeybindings()
end

function ZO_CrownCratesPackOpening:OnCardLeaveComplete()
    ZO_CROWN_CRATE_STATE_MACHINE:FireCallbacks(ZO_CROWN_CRATE_TRIGGER_COMMANDS.CARD_OUT_COMPLETE)
end