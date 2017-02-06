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
ZO_CROWN_CRATES_BONUS_DEAL_TO_SCREEN_DURATION_MS = 310
ZO_CROWN_CRATES_BONUS_DEAL_TO_SCREEN_SCALE_FACTOR = 1.2
ZO_CROWN_CRATES_BONUS_DEAL_TO_SCREEN_ARC_CONTROL_POINT_Y_OFFSET_SCREEN_PERCENT = 0.14
ZO_CROWN_CRATES_BONUS_DEAL_TILT_DURATION_MS = 100
ZO_CROWN_CRATES_BONUS_DEAL_HANG_DURATION_MS = 175
ZO_CROWN_CRATES_BONUS_DEAL_TO_HAND_DURATION_MS = 400
ZO_CROWN_CRATES_BONUS_HANG_START_MS = ZO_CROWN_CRATES_BONUS_DEAL_TO_SCREEN_DURATION_MS + ZO_CROWN_CRATES_BONUS_DEAL_TILT_DURATION_MS
ZO_CROWN_CRATES_BONUS_DEAL_TO_HAND_START_MS = ZO_CROWN_CRATES_BONUS_HANG_START_MS + ZO_CROWN_CRATES_BONUS_DEAL_HANG_DURATION_MS
ZO_CROWN_CRATES_BONUS_DEAL_TO_SCREEN_START_PITCH_RADIANS = math.rad(90)
ZO_CROWN_CRATES_BONUS_DEAL_TO_SCREEN_END_PITCH_RADIANS = math.rad(45)
ZO_CROWN_CRATES_BONUS_DEAL_TO_SCREEN_START_YAW_RADIANS = math.rad(-30)
ZO_CROWN_CRATES_BONUS_DEAL_TO_SCREEN_END_YAW_RADIANS = math.rad(0)
ZO_CROWN_CRATES_BONUS_DEAL_TO_SCREEN_START_ROLL_RADIANS = math.rad(-160)
ZO_CROWN_CRATES_BONUS_DEAL_TO_SCREEN_END_ROLL_RADIANS = math.rad(0)
ZO_CROWN_CRATES_BONUS_DEAL_DRIFT_X_UI = 30

--Mystery Select/Deselect
ZO_CROWN_CRATES_MYSTERY_SELECTION_DURATION_MS = 166
ZO_CROWN_CRATES_MYSTERY_SELECTION_OFFSET_Y_UI = 50

--Mystery Selected
ZO_CROWN_CRATES_MYSTERY_SELECTED_WOBBLE_DURATION_MS = 2800
ZO_CROWN_CRATES_MYSTERY_SELECTED_WOBBLE_SPACING_MS = 1000
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
ZO_CROWN_CRATES_CARD_INFO_INSET_X = 40

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

--Particle Types
ZO_CROWN_CRATES_PARTICLE_TYPE_LIFECYCLE = "lifecycle"
ZO_CROWN_CRATES_PARTICLE_TYPE_REVEALED_SELECTED = "revealedSelected"

--Card Sides
ZO_CROWN_CRATES_CARD_SIDE_BACK = "back"
ZO_CROWN_CRATES_CARD_SIDE_FACE = "face"
ZO_CROWN_CRATES_CARD_SIDE_GEMIFIED_FACE = "gemifiedFace"
ZO_CROWN_CRATES_CARD_SIDE_GEMIFIED_FLIPPED_FACE = "gemifiedFlippedFace"

-- Gem Frame Texture
local ZO_CROWN_CRATES_GEM_FRAME_TEXTURE = "EsoUI/Art/CrownCrates/crownCrate_card_frame_gem.dds"
local ZO_CROWN_CRATES_WHITE_CARD_TEXTURE = "EsoUI/Art/CrownCrates/crownCrate_whiteCard.dds"
local ZO_CROWN_CRATES_REWARD_GEMS_TEXTURE = "EsoUI/Art/CrownCrates/Rewards/crownCrate_reward_gems.dds"

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

ZO_CROWN_CRATES_CARD_TEXTURE_LEVEL_REWARD = 0
ZO_CROWN_CRATES_CARD_TEXTURE_LEVEL_ACTIVATION_OVERLAY = 1
ZO_CROWN_CRATES_CARD_TEXTURE_LEVEL_FRAME = 2
ZO_CROWN_CRATES_CARD_TEXTURE_LEVEL_GLOW = 3
ZO_CROWN_CRATES_CARD_TEXTURE_LEVEL_ACCENT = 4
ZO_CROWN_CRATES_CARD_TEXTURE_LEVEL_COLOR_TINT = 5
ZO_CROWN_CRATES_CARD_TEXTURE_LEVEL_COLOR_FLASH = 6
ZO_CROWN_CRATES_CARD_TEXTURE_LEVEL_GEM_OVERLAY = 7
ZO_CROWN_CRATES_CARD_TEXTURE_LEVEL_MOUSE_AREA = 8

ZO_CrownCratesCard = ZO_CrownCratesAnimatable:Subclass()

function ZO_CrownCratesCard:New(...)
    return ZO_CrownCratesAnimatable.New(self, ...)
end

function ZO_CrownCratesCard:CreateTextureControl(drawLevel)
	local textureControl = CreateControlFromVirtual("", self.control, "ZO_CrownCrateCardTexture")
	textureControl:SetDrawLevel(drawLevel)
	textureControl:Create3DRenderSpace()
	self:AddTexture(textureControl)
	return textureControl
end

function ZO_CrownCratesCard:Initialize(control, owner)
    self.crownCratesManager = owner:GetOwner()
    ZO_CrownCratesAnimatable.Initialize(self, control, self.crownCratesManager)
    self.stateMachine = owner:GetStateMachine()

    self.control = control
    self.owner = owner
    
    self.rewardTextureControl = self:CreateTextureControl(ZO_CROWN_CRATES_CARD_TEXTURE_LEVEL_REWARD)
    --SetCollectibleActiveAreaOverlay will be on this level, set in XML--
    self.cardTextureControl = self:CreateTextureControl(ZO_CROWN_CRATES_CARD_TEXTURE_LEVEL_FRAME)
    self.cardGlowTextureControl = self:CreateTextureControl(ZO_CROWN_CRATES_CARD_TEXTURE_LEVEL_GLOW)
    self.frameAccentTextureControl = self:CreateTextureControl(ZO_CROWN_CRATES_CARD_TEXTURE_LEVEL_ACCENT)
    self.colorTintOverlayTextureControl = self:CreateTextureControl(ZO_CROWN_CRATES_CARD_TEXTURE_LEVEL_COLOR_TINT)
    self.colorTintOverlayTextureControl:SetTexture(ZO_CROWN_CRATES_WHITE_CARD_TEXTURE)
    self.colorTintOverlayTextureControl:SetBlendMode(TEX_BLEND_MODE_ADD)
    self.colorFlashOverlayTextureControl = self:CreateTextureControl(ZO_CROWN_CRATES_CARD_TEXTURE_LEVEL_COLOR_FLASH)
    self.colorFlashOverlayTextureControl:SetTexture(ZO_CROWN_CRATES_WHITE_CARD_TEXTURE)
    self.gemOverlayTextureControl = self:CreateTextureControl(ZO_CROWN_CRATES_CARD_TEXTURE_LEVEL_GEM_OVERLAY)
    self.gemOverlayTextureControl:SetTexture(ZO_CROWN_CRATES_REWARD_GEMS_TEXTURE)
    self.mouseAreaControl = self:CreateTextureControl(ZO_CROWN_CRATES_CARD_TEXTURE_LEVEL_MOUSE_AREA)

    self.nameAreaControl = control:GetNamedChild("NameArea")
    self.nameLabel = self.nameAreaControl:GetNamedChild("Text")
    self.rewardTypeAreaControl = control:GetNamedChild("RewardTypeArea")
    self.rewardTypeLabel = self.rewardTypeAreaControl:GetNamedChild("Text")
    self.gemGainLabelPool = ZO_ControlPool:New("ZO_CrownCrateCardCrownGemsText", self.rewardTypeAreaControl)
    self.activateCollectibleAreaControl = control:GetNamedChild("SetCollectibleActiveArea")
    self.activateCollectibleKeybindControl = self.activateCollectibleAreaControl:GetNamedChild("Keybind")

    local function ActivateCollectibleCallback()
        if not self.activateCollectibleAreaControl:IsHidden() then
            UseCollectible(self.rewardReferenceDataId)
        end
    end
    self.activateCollectibleKeybindControl:SetCallback(ActivateCollectibleCallback)

    local OnMouseEnter = function()
        self:OnMouseEnter()
    end
    local OnMouseExit = function()
        self:OnMouseExit()
    end
    ZO_CrownCrates.AddBounceResistantMouseHandlersToControl(self.mouseAreaControl, OnMouseEnter, OnMouseExit)
    self.mouseAreaControl:SetMouseEnabled(true)

    self.mouseInputGroup = ZO_MouseInputGroup:New(self.mouseAreaControl)
    self.mouseInputGroup:Add(self.activateCollectibleKeybindControl, ZO_MOUSE_INPUT_GROUP_MOUSE_OVER)

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

        activateCollectibleKeybindStyle = KEYBIND_STRIP_STANDARD_STYLE,
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

        activateCollectibleKeybindStyle = KEYBIND_STRIP_GAMEPAD_STYLE,
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
                        self.nextSingleGemIndex = self.nextSingleGemIndex + 1
                        return singleGem
                    end

    self.singleGemPool = ZO_ObjectPool:New(factory, reset)
end

function ZO_CrownCratesCard:ApplyStyle(style)
    ZO_FontAdjustingWrapLabel_OnInitialized(self.nameLabel, style.nameFonts, TEXT_WRAP_MODE_ELLIPSIS)
    ZO_FontAdjustingWrapLabel_OnInitialized(self.rewardTypeLabel, style.rewardTextFonts, TEXT_WRAP_MODE_ELLIPSIS)
    self.activateCollectibleKeybindControl:SetupStyle(style.activateCollectibleKeybindStyle)
    --Switching between upper and title case requires setting the string again
    self.activateCollectibleKeybindControl:SetText(GetString(SI_COLLECTIBLE_ACTION_SET_ACTIVE))
    self.formattedGemIcon = ZO_Currency_GetPlatformFormattedCurrencyIcon(ZO_Currency_MarketCurrencyToUICurrency(MKCT_CROWN_GEMS), "100%")
    self.gemGainFonts = style.gemGainFonts
end

function ZO_CrownCratesCard:SetRewardIndex(rewardIndex)
    self.rewardIndex = rewardIndex
end

function ZO_CrownCratesCard:SetVisualSlotIndex(visualSlotIndex)
    self.visualSlotIndex = visualSlotIndex
    self:Refresh2DCardPosition()
end

function ZO_CrownCratesCard:Refresh2DCardPosition()
    local cardCenterX, cardCenterY = ZO_CrownCrates.ComputeSlotCenterUIPosition(ZO_CROWN_CRATES_CARD_WIDTH_REVEALED_UI, 
                                                                            ZO_CROWN_CRATES_CARD_HEIGHT_REVEALED_UI, 
                                                                            ZO_CrownCrates.GetBottomOffsetUI() + ZO_CROWN_CRATES_REVEAL_INFO_AREA_HEIGHT_UI,
                                                                            ZO_CROWN_CRATES_CARD_SPACING_REVEALED_UI, 
                                                                            self.visualSlotIndex, 
                                                                            GetNumCurrentCrownCrateTotalRewards())

    self.activateCollectibleAreaControl:SetAnchor(CENTER, GuiRoot, TOPLEFT, cardCenterX, cardCenterY)
    --the remaining 2D card areas are anchored off of the activate collectible area
end

function ZO_CrownCratesCard:InitializeForDeal(visualSlotIndex)
    self:SetVisualSlotIndex(visualSlotIndex)
    self.rewardName, self.rewardTypeText, self.rewardImage, self.rewardFrameAccentImage, self.gemsExchanged, self.isBonus, self.crownCrateTierId, self.stackCount = GetCrownCrateRewardInfo(self.rewardIndex)
    self.cardTierOrder = GetCrownCrateTierOrdering(self.crownCrateTierId)
    self.rewardQualityColor = ZO_ColorDef:New(GetCrownCrateTierQualityColor(self.crownCrateTierId))
    self.rewardReaction = GetCrownCrateTierReactionNPCAnimation(self.crownCrateTierId)
    self.rewardProductType, self.rewardReferenceDataId = GetCrownCrateRewardProductReferenceData(self.rewardIndex)
    --Make sure the texture is loaded before we need it, so it doesn't pop or fade on flip
    self.rewardTextureControl:SetTexture(self.rewardImage)
    self.mouseAreaControl:SetMouseEnabled(true)
end

function ZO_CrownCratesCard:Reset()
    ZO_CrownCratesAnimatable.Reset(self)
    
    self.nameAreaControl:SetAlpha(0)
    self.rewardTypeAreaControl:SetAlpha(0)

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
    self.cardTierOrder = nil
    self.stackCount = nil
    self.playRevealSounds = true
    self.resizePending = nil
    self:SetState(CARD_STATES.START)

	self:SetCardFaceDesaturation(0)
    self.singleGemPool:ReleaseAllObjects()

    self.control:SetHandler("OnUpdate", nil)

    --Extend the card down below the edge of the screen to fix the bouncing as it moves up on selection and out from under the mouse
    self.mouseAreaControl:Set3DLocalDimensions(ZO_CROWN_CRATES_CARD_WIDTH_WORLD, ZO_CROWN_CRATES_CARD_HEIGHT_WORLD + ZO_CROWN_CRATES_CARD_HEIGHT_BUFFER_WORLD)
    self.mouseAreaControl:Set3DRenderSpaceOrigin(0, -0.5 * (ZO_CROWN_CRATES_CARD_HEIGHT_BUFFER_WORLD + ZO_CROWN_CRATES_CARD_HEIGHT_WORLD) + 0.5 * ZO_CROWN_CRATES_CARD_HEIGHT_WORLD, 0)
    self.activateCollectibleAreaControl:SetHidden(true)

    self.gemGainLabelPool:ReleaseAllObjects()
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
        elseif side == ZO_CROWN_CRATES_CARD_SIDE_FACE then
            self.cardTextureControl:SetTexture(faceImage)
            self.cardGlowTextureControl:SetTexture(faceGlowImage)
            self.rewardTextureControl:SetAlpha(1)
            self.frameAccentTextureControl:SetAlpha(1)
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

function ZO_CrownCratesCard:PrimayDealFromWorldPositionToWorldPosition(startX, startY, startZ)
    local endX, endY, endZ = self.owner:ComputePrimaryDealEndPosition(self.visualSlotIndex)

    self:SetupCardSide(ZO_CROWN_CRATES_CARD_SIDE_BACK)
    self.control:SetHidden(false)
    self.cardTextureControl:SetAlpha(1)
    self.cardGlowTextureControl:SetAlpha(0)

    local function TrackPrimaryDealComplete(timeline, completedPlaying)
        if completedPlaying then
            self.owner:OnPrimaryDealCardComplete()
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

function ZO_CrownCratesCard:BonusDealFromWorldPositionToWorldPosition(startX, startY, startZ)
    local endX, endY, endZ = self.owner:ComputeBonusDealEndPosition(self.visualSlotIndex)

    self:SetupCardSide(ZO_CROWN_CRATES_CARD_SIDE_BACK)
    self.control:SetHidden(false)
    self.cardTextureControl:SetAlpha(1)
    self.cardGlowTextureControl:SetAlpha(0)

    local function TrackBonusDealComplete(timeline, completedPlaying)
        if completedPlaying then
            self.owner:OnBonusDealCardComplete()
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
            self:StartCrateSpecificParticleEffects(ZO_CROWN_CRATES_PARTICLE_TYPE_LIFECYCLE, CROWN_CRATE_PARTICLES_BONUS)
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
        self:ReleaseParticle(ZO_CROWN_CRATES_PARTICLE_TYPE_LIFECYCLE)
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
    local endX, endY, endZ = self.owner:ComputeBonusDealEndPosition(self.visualSlotIndex)
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

function ZO_CrownCratesCard:OnDealComplete()
    self:StartTierSpecificParticleEffects(ZO_CROWN_CRATES_PARTICLE_TYPE_LIFECYCLE, CROWN_CRATE_TIERED_PARTICLES_MYSTERY)
    self:SetState(CARD_STATES.MYSTERY)
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
    if not SCENE_MANAGER:IsCurrentSceneGamepad() then
        self.owner:SetSelectedCard(self)
    end
end

function ZO_CrownCratesCard:OnMouseExit()
    if not SCENE_MANAGER:IsCurrentSceneGamepad() then
        self.owner:SetSelectedCard(nil)
    end
end

function ZO_CrownCratesCard:OnMouseUp()
    if not SCENE_MANAGER:IsCurrentSceneGamepad()then
        if self:CanSelect() then
            if self:IsMystery() then
                self:Reveal()
            elseif self:IsRevealed() then
                self:StartTierSpecificParticleEffects(ZO_CROWN_CRATES_PARTICLE_TYPE_REVEALED_SELECTED, CROWN_CRATE_TIERED_PARTICLES_REVEALED_SELECTED)
            end
        end
    end
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
    local endX, endY, endZ = self.owner:ComputeRevealEndPosition(self.visualSlotIndex)

	local function TransitionCardReveal()
		if not self.cardTextureControl:Is3DQuadFacingCamera() and self.side ~= ZO_CROWN_CRATES_CARD_SIDE_FACE then
			self:SetupCardSide(ZO_CROWN_CRATES_CARD_SIDE_FACE)
			self.cardGlowTextureControl:SetAlpha(0)
			self.control:SetHandler("OnUpdate", nil)
			if self:IsSelected() then
				self:RevealedSelect()
			end
			self:ShowInfo()
		end
	end

    local AnimationOnStop = function(timeline, completedPlaying)
        if completedPlaying then
			-- this is some edge case protection incase the player gets a massive frame time spike while revealing all cards
			-- which would cause this animation stop function to be called before the OnUpdate callback gets handled
			-- resulting in the cards 'side' state being incorrect
			TransitionCardReveal()

            if self.playRevealSounds then
                TriggerCrownCrateNPCAnimation(self.rewardReaction)
            end
            if self.gemsExchanged == 0 then
                self:SetState(CARD_STATES.REVEALED)
                self.owner:OnCardFlipComplete()
                self:StartTierSpecificParticleEffects(ZO_CROWN_CRATES_PARTICLE_TYPE_LIFECYCLE, CROWN_CRATE_TIERED_PARTICLES_REVEALED)
                self:RefreshActivateCollectibleKeybind()
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
		TransitionCardReveal()
    end)

    --PFX
	self:StartTierSpecificParticleEffects(ZO_CROWN_CRATES_PARTICLE_TYPE_LIFECYCLE, CROWN_CRATE_TIERED_PARTICLES_REVEAL)

    --Resize the mouse over area back to the card dimensions
    self.mouseAreaControl:Set3DLocalDimensions(ZO_CROWN_CRATES_CARD_WIDTH_WORLD, ZO_CROWN_CRATES_CARD_HEIGHT_WORLD)
    self.mouseAreaControl:Set3DRenderSpaceOrigin(0, 0, 0)
end

function ZO_CrownCratesCard:Gemify()
	local function TransitionCardGemify()
		if self.cardTextureControl:Is3DQuadFacingCamera() and self.side ~= ZO_CROWN_CRATES_CARD_SIDE_GEMIFIED_FACE then
            self:SetupCardSide(ZO_CROWN_CRATES_CARD_SIDE_GEMIFIED_FACE)
            self.colorTintOverlayTextureControl:SetAlpha(ZO_CROWN_CRATES_GEMIFY_TINT_ALPHA)
            self.colorFlashOverlayTextureControl:SetAlpha(0)
            self.nameLabel:SetText(zo_strformat(SI_CROWN_CRATE_REWARD_WITH_GEMS_EXCHANGED, self.gemsExchanged, self.formattedGemIcon, self.rewardName))
            self.control:SetHandler("OnUpdate", nil)
        end 
	end

    local AnimationOnStop = function(timeline, completedPlaying)
        if completedPlaying then
			-- this is some edge case protection incase the player gets a massive frame time spike while revealing all cards
			-- which would cause this animation stop function to be called before the OnUpdate callback gets handled
			-- resulting in the cards 'side' state being incorrect
			TransitionCardGemify()

            local currentPitch, currentYaw, currentRoll = self.control:Get3DRenderSpaceOrientation()
            self.control:Set3DRenderSpaceOrientation(ZO_CROWN_CRATES_GEMIFY_BEGIN_PITCH_RADIANS, currentYaw, currentRoll)
            self:SetupCardSide(ZO_CROWN_CRATES_CARD_SIDE_GEMIFIED_FLIPPED_FACE)
            local function OnAllSingleGemAnimationsComplete()
                self:StartFinalGemAndTextAnimation()
            end
            self:StartSingleGemsAnimation(OnAllSingleGemAnimationsComplete)
        end
    end

    local cardAnimationTimeline = self:AcquireAndApplyAnimationTimeline(ZO_CROWN_CRATES_ANIMATION_GEMIFY_CARD, self.control, AnimationOnStop)
    self:StartAnimation(cardAnimationTimeline)
    --Setup update handler to watch for facing toward the camera again
    self.control:SetHandler("OnUpdate", function(control)
		TransitionCardGemify()
    end)

    self:StartCrateSpecificParticleEffects(ZO_CROWN_CRATES_PARTICLE_TYPE_LIFECYCLE, CROWN_CRATE_PARTICLES_GEMIFY)

    PlaySound(SOUNDS.CROWN_CRATES_GAIN_GEMS)
end

function ZO_CrownCratesCard:StartSingleGemsAnimation(OnAllGemsAnimationComplete)
    for i = 1, ZO_CROWN_CRATES_GEMIFY_TOTAL_SINGLE_GEMS_TO_PLAY do
        local nextSingleGem, objectKey = self.singleGemPool:AcquireObject()
        nextSingleGem.objectKey = objectKey
        nextSingleGem:SetHidden(false)

        local function OnAnimationStopRelease(timeline, completedPlaying)
            if completedPlaying then
                self.singleGemPool:ReleaseObject(timeline:GetFirstAnimation():GetAnimatedControl().objectKey)
            end
        end

        local function OnAnimationStopReleaseAndFlash(timeline, completedPlaying)
            OnAnimationStopRelease(timeline, completedPlaying)
            if completedPlaying then
                local colorTintAnimationTimeline = self:AcquireAndApplyAnimationTimeline(ZO_CROWN_CRATES_ANIMATION_GEMIFY_COLOR_TINT, self.colorFlashOverlayTextureControl)
                self:StartAnimation(colorTintAnimationTimeline)
            end
        end

        local function OnAnimationStopReleaseAndComplete(timeline, completedPlaying)
            OnAnimationStopRelease(timeline, completedPlaying)
            if completedPlaying and OnAllGemsAnimationComplete then
                OnAllGemsAnimationComplete()
            end
        end

        local playOrderIndex = ZO_CROWN_CRATES_GEMIFY_TOTAL_SINGLE_GEMS_TO_PLAY - i
        local animationOnStopHandler
        if playOrderIndex == ZO_CROWN_CRATES_GEMIFY_TOTAL_SINGLE_GEMS_TO_PLAY - 2 then
            animationOnStopHandler = OnAnimationStopReleaseAndFlash
        elseif playOrderIndex == ZO_CROWN_CRATES_GEMIFY_TOTAL_SINGLE_GEMS_TO_PLAY - 1 then
            animationOnStopHandler = OnAnimationStopReleaseAndComplete
        else
            animationOnStopHandler = OnAnimationStopRelease
        end
        local singleGemAnimationTimeline = self:AcquireAndApplyAnimationTimeline(ZO_CROWN_CRATES_ANIMATION_GEMIFY_SINGLE_GEM_GAIN, nextSingleGem, animationOnStopHandler)

        local translateAnimation = singleGemAnimationTimeline:GetAnimation(2)
        local halfCardHeight = ZO_CROWN_CRATES_CARD_HEIGHT_REVEALED_UI / 2
        local nextAngle = ((i - 1) * - ZO_CROWN_CRATES_GEMIFY_SINGLE_GEM_DELTA_ANGLE_DEGREES) - ZO_CROWN_CRATES_GEMIFY_SINGLE_GEM_STARTING_ANGLE_DEGREES
        local offsetX = halfCardHeight * math.cos(math.rad(nextAngle))
        local offsetY = halfCardHeight * math.sin(math.rad(nextAngle))
        translateAnimation:SetTranslateOffsets(offsetX, offsetY, 0, 0)
        nextSingleGem:SetAnchor(CENTER, self.activateCollectibleAreaControl)
        nextSingleGem:SetAlpha(0)

        self:CallLater(function() self:StartAnimation(singleGemAnimationTimeline) end, playOrderIndex * ZO_CROWN_CRATES_GEMIFY_SINGLE_GEM_START_TIME_DELAY_MS)
    end
end

function ZO_CrownCratesCard:StartFinalGemAndTextAnimation()
    local finalGem, finalObjectKey = self.singleGemPool:AcquireObject()
    finalGem:SetHidden(false)

    local AnimationOnStop = function(timeline, completedPlaying)
        if completedPlaying then
            self:SetState(CARD_STATES.REVEALED)
            self.owner:OnCardFlipComplete()
            self:StartTierSpecificParticleEffects(ZO_CROWN_CRATES_PARTICLE_TYPE_LIFECYCLE, CROWN_CRATE_TIERED_PARTICLES_REVEALED)
            self.gemOverlayTextureControl:SetAlpha(1)
            self.singleGemPool:ReleaseObject(finalObjectKey)
            self:RefreshActivateCollectibleKeybind()
        end
    end

    finalGem:SetAnchor(CENTER, self.activateCollectibleAreaControl)
    local finalGemAnimationTimeline = self:AcquireAndApplyAnimationTimeline(ZO_CROWN_CRATES_ANIMATION_GEMIFY_FINAL_GEM, finalGem, AnimationOnStop)
    self:StartAnimation(finalGemAnimationTimeline)

    self.crownCratesManager:AddCrownGems(self.gemsExchanged)
    TriggerCrownCrateNPCAnimation(CROWN_CRATE_NPC_ANIMATION_TYPE_GEMS_AWARDED)

    self:StartGemGainTextAnimation(self.gemsExchanged, BOTTOM, self.rewardTypeLabel, TOP, 0, 5)
end

function ZO_CrownCratesCard:StartGemGainTextAnimation(gemsGained, startPoint, startRelativeTo, startRelativePoint, startOffsetX, startOffsetY)
    local gemGainLabel, gemGainLabelKey = self.gemGainLabelPool:AcquireObject()
    gemGainLabel:ClearAnchors()
    gemGainLabel:SetAnchor(startPoint, startRelativeTo, startRelativePoint, startOffsetX, startOffsetY)
    ZO_FontAdjustingWrapLabel_OnInitialized(gemGainLabel, self.gemGainFonts, TEXT_WRAP_MODE_ELLIPSIS)
    gemGainLabel:SetText(zo_strformat(SI_CROWN_CRATE_GEMS_GAINED_FORMAT, gemsGained, self.formattedGemIcon))
    gemGainLabel:SetAlpha(1)
    local gemTextAnimationTimeline = self:AcquireAndApplyAnimationTimeline(ZO_CROWN_CRATES_ANIMATION_GEMIFY_CROWN_GEM_TEXT, gemGainLabel, function() self.gemGainLabelPool:ReleaseObject(gemGainLabelKey) end)
    self:StartAnimation(gemTextAnimationTimeline)
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
    self:RefreshActivateCollectibleKeybind()
end

function ZO_CrownCratesCard:RevealedDeselect()
    if self:GetOnePlayingAnimationOfType(ZO_CROWN_CRATES_ANIMATION_REVEALED_SELECTED_GLOW) then
        self:EnsureAnimationsArePlayingInDirection(ZO_CROWN_CRATES_ANIMATION_REVEALED_SELECTED_GLOW, BACKWARD)
    elseif self.cardGlowTextureControl:GetAlpha() ~= 0 then
        local animationTimeline = self:AcquireAndApplyAnimationTimeline(ZO_CROWN_CRATES_ANIMATION_REVEALED_SELECTED_GLOW, self.cardGlowTextureControl)
        self:StartAnimation(animationTimeline, BACKWARD)
    end
    self:RefreshActivateCollectibleKeybind()
end

function ZO_CrownCratesCard:ShowInfo()
    --Name
    if self.stackCount > 1 then
       	self.nameLabel:SetText(zo_strformat(SI_CROWN_CRATE_REWARD_WITH_STACK_NAME, self.rewardName, self.stackCount))
    else
        self.nameLabel:SetText(zo_strformat(SI_CROWN_CRATE_REWARD_NAME, self.rewardName))
    end
    local animationTimeline = self:AcquireAndApplyAnimationTimeline(ZO_CROWN_CRATES_ANIMATION_CARD_SHOW_INFO, self.nameAreaControl)
    local translateAnimation = animationTimeline:GetAnimation(2)
    translateAnimation:SetTranslateOffsets(0, ZO_CROWN_CRATES_CARD_SHOW_INFO_NAME_OFFSET_Y_UI, 0, 0)
    self:StartAnimation(animationTimeline)

    --Reward Type
    self.rewardTypeLabel:SetText(zo_strformat(SI_ITEM_FORMAT_STR_BROAD_TYPE, self.rewardTypeText))
    animationTimeline = self:AcquireAndApplyAnimationTimeline(ZO_CROWN_CRATES_ANIMATION_CARD_SHOW_INFO, self.rewardTypeAreaControl)
    translateAnimation = animationTimeline:GetAnimation(2)
    translateAnimation:SetTranslateOffsets(0, ZO_CROWN_CRATES_CARD_SHOW_INFO_REWARD_TYPE_OFFSET_Y_UI, 0, 0)
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
    self:DestroyParticle(ZO_CROWN_CRATES_PARTICLE_TYPE_LIFECYCLE)
    self:DestroyParticle(ZO_CROWN_CRATES_PARTICLE_TYPE_REVEALED_SELECTED)

    local startPitch, startYaw, startRoll = self.control:Get3DRenderSpaceOrientation()

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
    rotateAnimation:SetRotationValues(startPitch, startYaw, startRoll, ZO_CROWN_CRATES_LEAVE_END_PITCH_RADIANS, ZO_CROWN_CRATES_LEAVE_END_YAW_RADIANS, ZO_CROWN_CRATES_LEAVE_END_ROLL_RADIANS)
    
    self:StartAnimation(animationTimeline)

    --Setup update handler to watch for facing toward the camera
    self.control:SetHandler("OnUpdate", function(control)
        if (self.side == ZO_CROWN_CRATES_CARD_SIDE_FACE or self.side == ZO_CROWN_CRATES_CARD_SIDE_GEMIFIED_FLIPPED_FACE)
            and self.cardTextureControl:Is3DQuadFacingCamera() then
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

function ZO_CrownCratesCard:RefreshActivateCollectibleKeybind()
    local hideKeybind = not (self:IsSelected() and self:IsRevealed() and self:CanActivateCollectible())
    self.activateCollectibleAreaControl:SetHidden(hideKeybind)
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
           and (self.stateMachine:IsCurrentStateByName("ACTIVE_HAND_MANIPULATION") 
           or self.stateMachine:IsCurrentStateByName("ALL_REVEALED"))
end

function ZO_CrownCratesCard:SetState(newState)
    self.cardState = newState
    if self.resizePending then
        self:ResizeCard()
    end
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
    self.cardGlowTextureControl:SetDesaturation(amount)
end

do
    local DISALLOWED_EQUIPPABLE_COLLECTIBLE_TYPES =
    {
        [COLLECTIBLE_CATEGORY_TYPE_ASSISTANT] = true,
        [COLLECTIBLE_CATEGORY_TYPE_MEMENTO] = true,
        [COLLECTIBLE_CATEGORY_TYPE_DLC] = true,
    }

    function ZO_CrownCratesCard:CanActivateCollectible()
        if self.rewardProductType == MARKET_PRODUCT_TYPE_COLLECTIBLE and not self:IsGemified() then
            local collectibleId = self.rewardReferenceDataId
            if IsCollectibleUsable(collectibleId) and IsCollectibleValidForPlayer(collectibleId) and not IsCollectibleBlocked(collectibleId) then
                local isActive, categoryType = select(7, GetCollectibleInfo(collectibleId))

                return not (isActive or DISALLOWED_EQUIPPABLE_COLLECTIBLE_TYPES[categoryType])
            end
        end
        return false
    end
end

function ZO_CrownCratesCard:OnScreenResized()
    self:ResizeCard()
end

function ZO_CrownCratesCard:ResizeCard()
    self.resizePending = nil
    self:Refresh2DCardPosition()
    if self.cardState == CARD_STATES.MYSTERY then
        local x, y, z
        if GetNumCurrentCrownCrateBonusRewards() > 0 then
            x, y, z = self.owner:ComputeBonusDealEndPosition(self.visualSlotIndex)
        else
            x, y, z = self.owner:ComputePrimaryDealEndPosition(self.visualSlotIndex)
        end
        self.control:Set3DRenderSpaceOrigin(x, y, z)
        self.rootX = x
        self.rootY = y
        self.rootZ = z
    elseif self.cardState == CARD_STATES.REVEALED then
        local x, y, z = self.owner:ComputeRevealEndPosition(self.visualSlotIndex)
        self.control:Set3DRenderSpaceOrigin(x, y, z)
    elseif self.cardState == CARD_STATES.START or self.cardState == CARD_STATES.FLIPPING or self.cardState == CARD_STATES.GEMIFY then
        self.resizePending = true
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

    EVENT_MANAGER:RegisterForEvent("ZO_CrownCratesPackOpening", EVENT_SCREEN_RESIZED, function() self:OnScreenResized() end)
end

function ZO_CrownCratesPackOpening:OnScreenResized()
    self:RefreshCameraPlaneMetrics()
    for key, card in pairs(self.cardPool:GetActiveObjects()) do
        card:OnScreenResized()
    end
end

function ZO_CrownCratesPackOpening:GetStateMachine(stateMachine)
	return self.stateMachine
end

function ZO_CrownCratesPackOpening:SetStateMachine(stateMachine)
	self.stateMachine = stateMachine
end

function ZO_CrownCratesPackOpening:GetOwner()
	return self.owner
end

function ZO_CrownCratesPackOpening:RefreshCameraPlaneMetrics()
    self.inHandCameraPlaneMetrics = self.owner:ComputeCameraPlaneMetrics(ZO_CROWN_CRATES_CARD_WIDTH_WORLD, ZO_CROWN_CRATES_CARD_WIDTH_IN_HAND_UI)
    self.revealedCameraPlaneMetrics = self.owner:ComputeCameraPlaneMetrics(ZO_CROWN_CRATES_CARD_WIDTH_WORLD, ZO_CROWN_CRATES_CARD_WIDTH_REVEALED_UI)
end

function ZO_CrownCratesPackOpening:OnLockLocalSpaceToCurrentCamera()
    self:RefreshCameraPlaneMetrics()
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
    local activateCollectibleKeybind =
    {
        keybind = "UI_SHORTCUT_TERTIARY",
        callback = function()
            local card = self:GetSelectedCard()
            if card and card:IsRevealed() and card:CanActivateCollectible() then
                UseCollectible(card.rewardReferenceDataId)
            end
        end,
        ethereal = true,
    }

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
        },

        activateCollectibleKeybind,
    }

    self.keyboardAllRevealedKeybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_CENTER,
        
        activateCollectibleKeybind,

        ZO_CROWN_CRATES_BUY_CRATES_KEYBIND_KEYBOARD,
    }

    -- Gamepad --
    local function CreateRevealedSelectedKeybindDescriptor(keybind)     
        local descriptor = {
            keybind = keybind,
            ethereal = true,
            callback = function()
                local card = self:GetSelectedCard()
                if card:IsRevealed() then
                    card:StartTierSpecificParticleEffects(ZO_CROWN_CRATES_PARTICLE_TYPE_REVEALED_SELECTED, CROWN_CRATE_TIERED_PARTICLES_REVEALED_SELECTED)
                end
            end,
        }

        return descriptor
    end

    local revealedSelectedKeybindDescriptors = { 
        CreateRevealedSelectedKeybindDescriptor("UI_SHORTCUT_RIGHT_SHOULDER"),
        CreateRevealedSelectedKeybindDescriptor("UI_SHORTCUT_LEFT_SHOULDER"),
        CreateRevealedSelectedKeybindDescriptor("UI_SHORTCUT_LEFT_TRIGGER"),
        CreateRevealedSelectedKeybindDescriptor("UI_SHORTCUT_RIGHT_TRIGGER"),
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

        {
            keybind = "UI_SHORTCUT_SECONDARY",
            name = GetString(SI_CROWN_CRATE_REVEAL_ALL_REWARDS_KEYBIND),
            callback = function()
                self:RevealAllCards()
            end,
        },

        activateCollectibleKeybind,

        unpack(revealedSelectedKeybindDescriptors)
    }

    self.gamepadAllRevealedKeybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_CENTER,

        activateCollectibleKeybind,
        ZO_CROWN_CRATES_BUY_CRATES_KEYBIND_GAMEPAD,
        unpack(revealedSelectedKeybindDescriptors),
    }

    local function RefreshActivateCollectibleBindingKeybindings()
        local card = self:GetSelectedCard()
        if card then
            card:RefreshActivateCollectibleKeybind()
        end
    end

    COLLECTIONS_BOOK_SINGLETON:RegisterCallback("OnCollectibleUpdated", RefreshActivateCollectibleBindingKeybindings)
    COLLECTIONS_BOOK_SINGLETON:RegisterCallback("OnCollectionUpdated", RefreshActivateCollectibleBindingKeybindings)
    COLLECTIONS_BOOK_SINGLETON:RegisterCallback("OnCollectiblesUpdated", RefreshActivateCollectibleBindingKeybindings)
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

function ZO_CrownCratesPackOpening:GetHighestMysteryTierCard()
    local highestTierCard = self.cardsInVisualOrder[1]
    for _, card in ipairs(self.cardsInVisualOrder) do
        if card:IsMystery() and card.cardTierOrder > highestTierCard.cardTierOrder then
            highestTierCard = card
        end
    end
    return highestTierCard
end

function ZO_CrownCratesPackOpening:RevealAllCards()
    local mysteryCards = self:GetAllMysteryCards()
    local highestTierCard = self:GetHighestMysteryTierCard()
    for i, card in ipairs(mysteryCards) do
        card:SuppressRevealSounds()
        if card == highestTierCard then
            TriggerCrownCrateNPCAnimation(highestTierCard.rewardReaction)
        end
        card:SetState(CARD_STATES.FLIPPING)
        card:CallLater(function()
            card:Reveal()
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

function ZO_CrownCratesPackOpening:ComputePrimaryDealEndPosition(visualSlotIndex)
    return self:ComputeSlotCenterWorldPosition(self:GetInHandCameraPlaneMetrics(), ZO_CROWN_CRATES_CARD_SPACING_IN_HAND_UI, visualSlotIndex, GetNumCurrentCrownCratePrimaryRewards())
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
        card:CallLater(function()
            card:PrimayDealFromWorldPositionToWorldPosition(sourceX, sourceY, sourceZ)
        end, (visualIndex - 1) * ZO_CROWN_CRATES_PRIMARY_DEAL_SPACING_DURATION_MS)
    end
end

function ZO_CrownCratesPackOpening:ComputeBonusDealEndPosition(visualSlotIndex)
    return self:ComputeSlotCenterWorldPosition(self.inHandCameraPlaneMetrics, ZO_CROWN_CRATES_CARD_SPACING_IN_HAND_UI, visualSlotIndex, GetNumCurrentCrownCratePrimaryRewards() + GetNumCurrentCrownCrateBonusRewards())
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
            card:CallLater(function()
                card:BonusSlideToWorldPosition()
            end, ZO_CROWN_CRATES_BONUS_SLIDE_DELAY_MS + distanceFromEdge * ZO_CROWN_CRATES_BONUS_SLIDE_SPACING_DURATION_MS)
            distanceFromEdge = distanceFromEdge + 1
        end

        distanceFromEdge = 0
        for i = splitCard + 1, numNormalCards do
            local card = self:GetCardInVisualOrder(i)
            local visualSlotIndex = i + numBonusCards
            card:SetVisualSlotIndex(visualSlotIndex)
            card:CallLater(function()
                card:BonusSlideToWorldPosition()
            end, ZO_CROWN_CRATES_BONUS_SLIDE_DELAY_MS + distanceFromEdge * ZO_CROWN_CRATES_BONUS_SLIDE_SPACING_DURATION_MS)
            distanceFromEdge = distanceFromEdge + 1
        end

        --Deal bonus cards
        for i = 1, numBonusCards do
            local card = self:GetCard(numNormalCards + i)
            local visualSlotIndex = splitCard + i
            card:InitializeForDeal(visualSlotIndex)
            card:CallLater(function()
                card:BonusDealFromWorldPositionToWorldPosition(sourceX, sourceY, sourceZ)
            end, (i - 1) * ZO_CROWN_CRATES_BONUS_DEAL_SPACING_DURATION_MS)
            table.insert(self.cardsInVisualOrder, splitCard + 1, card)
        end
    end
end

function ZO_CrownCratesPackOpening:ComputeRevealEndPosition(visualSlotIndex)
    local endX, endY, endZ = self:ComputeSlotCenterWorldPosition(self:GetRevealedCameraPlaneMetrics(), ZO_CROWN_CRATES_CARD_SPACING_REVEALED_UI, visualSlotIndex, GetNumCurrentCrownCrateTotalRewards())
    local offsetYWorld = ZO_CrownCrates.ConvertUIUnitsToWorldUnits(self:GetRevealedCameraPlaneMetrics(), ZO_CROWN_CRATES_REVEAL_INFO_AREA_HEIGHT_UI)
    endY = endY + offsetYWorld
    return endX, endY, endZ
end

function ZO_CrownCratesPackOpening:OnDealComplete()
	for _, card in ipairs(self.cardsInVisualOrder) do
		card:OnDealComplete()
	end
	if SCENE_MANAGER:IsCurrentSceneGamepad() then
		self:SetSelectedCard(self:GetNextMysteryCard())
	end
end

function ZO_CrownCratesPackOpening:StartLeaveAnimation()
    local leavingIndex = 0
    for i = #self.cardsInVisualOrder, 1, -1 do
        local card = self.cardsInVisualOrder[i]
        card:CallLater(function()
            card:Leave()
            card:SetState(CARD_STATES.LEAVING)
            card:RefreshActivateCollectibleKeybind()
        end, leavingIndex * ZO_CROWN_CRATES_LEAVE_SPACING_MS)
        leavingIndex = leavingIndex + 1
    end
    PlaySound(SOUNDS.CROWN_CRATES_CARDS_LEAVE)
end

function ZO_CrownCratesPackOpening:AddHandManipulationKeybinds()
    if self.initialized then
        if SCENE_MANAGER:IsCurrentSceneGamepad() then
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
    if (self.stateMachine:IsCurrentStateByName("ACTIVE_HAND_MANIPULATION")
       or self.stateMachine:IsCurrentStateByName("ALL_REVEALED")) and selectedDirection then
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
        local oldCard = self.selectedCard
        self.selectedCard = card

        if oldCard then
            oldCard:OnDeselect()
        end

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
    self.stateMachine:FireCallbacks(ZO_CROWN_CRATE_TRIGGER_COMMANDS.PRIMARY_DEAL_COMPLETE)
end

function ZO_CrownCratesPackOpening:OnBonusDealCardComplete()
    self.stateMachine:FireCallbacks(ZO_CROWN_CRATE_TRIGGER_COMMANDS.BONUS_DEAL_COMPLETE)
end

function ZO_CrownCratesPackOpening:OnCardFlipComplete()
    self.stateMachine:FireCallbacks(ZO_CROWN_CRATE_TRIGGER_COMMANDS.CARD_REVEALED)
    self:RefreshKeybindings()
end

function ZO_CrownCratesPackOpening:OnCardLeaveComplete()
    self.stateMachine:FireCallbacks(ZO_CROWN_CRATE_TRIGGER_COMMANDS.CARD_OUT_COMPLETE)
end