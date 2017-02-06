---------------------
--Crown Crates Pack--
---------------------

ZO_CROWN_CRATES_PACK_TEXTURE_WIDTH = 1024
ZO_CROWN_CRATES_PACK_TEXTURE_HEIGHT = 1024
ZO_CROWN_CRATES_PACK_TEXTURE_LID_HEIGHT = 44

ZO_CROWN_CRATES_PACK_WIDTH_TO_HEIGHT_RATIO = 1
ZO_CROWN_CRATES_PACK_WIDTH_TO_DEPTH_RATIO = 1
ZO_CROWN_CRATES_PACK_HEIGHT_TO_LID_THICKNESS_RATIO = ZO_CROWN_CRATES_PACK_TEXTURE_LID_HEIGHT / (ZO_CROWN_CRATES_PACK_TEXTURE_HEIGHT * 0.5)
ZO_CROWN_CRATES_PACK_WIDTH_WORLD = 0.1
ZO_CROWN_CRATES_PACK_HEIGHT_WORLD = ZO_CROWN_CRATES_PACK_WIDTH_WORLD * ZO_CROWN_CRATES_PACK_WIDTH_TO_HEIGHT_RATIO
ZO_CROWN_CRATES_PACK_DEPTH_WORLD = ZO_CROWN_CRATES_PACK_WIDTH_WORLD * ZO_CROWN_CRATES_PACK_WIDTH_TO_DEPTH_RATIO
ZO_CROWN_CRATES_PACK_LID_THICKNESS_WORLD = ZO_CROWN_CRATES_PACK_HEIGHT_WORLD * ZO_CROWN_CRATES_PACK_HEIGHT_TO_LID_THICKNESS_RATIO
ZO_CROWN_CRATES_PACK_WIDTH_UI = 350
ZO_CROWN_CRATES_PACK_SPACING_UI = 75
ZO_CROWN_CRATES_PACK_OFFSET_Y_UI = 120
ZO_CROWN_CRATES_PACK_PLACEHOLDER_ALPHA = 0.4
ZO_CROWN_CRATES_PACK_NORMAL_ALPHA = 1
ZO_CROWN_CRATES_PACK_FRONT_MOUSE_PLANE_BUFFER_WORLD = 3

ZO_CROWN_CRATES_PACK_COUNT_LABEL_HEIGHT_UI = 42
ZO_CROWN_CRATES_PACK_COUNT_LABEL_INSET_X_PERCENT = 0.1
ZO_CROWN_CRATES_PACK_COUNT_LABEL_INSET_Y_PERCENT = 0.05

ZO_CROWN_CRATES_PACK_SHOW_MOVE_DURATION_MS = 800
ZO_CROWN_CRATES_PACK_SHOW_SPIN_DURATION_MS = 700
ZO_CROWN_CRATES_PACK_SHOW_SPIN_DELAY_MS = 100
ZO_CROWN_CRATES_PACK_SHOW_SPACING_MS = 100
ZO_CROWN_CRATES_PACK_SHOW_START_PITCH_RADIANS = math.rad(160)
ZO_CROWN_CRATES_PACK_SHOW_START_YAW_RADIANS = math.rad(0)
ZO_CROWN_CRATES_PACK_SHOW_START_ROLL_RADIANS = math.rad(0)
ZO_CROWN_CRATES_PACK_SHOW_END_PITCH_RADIANS = math.rad(-15)
ZO_CROWN_CRATES_PACK_SHOW_END_YAW_RADIANS = math.rad(0)
ZO_CROWN_CRATES_PACK_SHOW_END_ROLL_RADIANS = math.rad(0)

ZO_CROWN_CRATES_PACK_SELECTED_PITCH_RADIANS = math.rad(-8)
ZO_CROWN_CRATES_PACK_SELECTED_YAW_RADIANS = math.rad(0)
ZO_CROWN_CRATES_PACK_SELECTED_ROLL_RADIANS = math.rad(0)
ZO_CROWN_CRATES_PACK_SELECTION_DURATION_MS = 300
ZO_CROWN_CRATES_PACK_SELECTION_OFFSET_Y_UI = 40

ZO_CROWN_CRATES_PACK_HIDE_DURATION_MS = 200
ZO_CROWN_CRATES_PACK_HIDE_END_YAW_RADIANS = math.rad(0)
ZO_CROWN_CRATES_PACK_HIDE_OFFSET_Y_UI = -40

ZO_CROWN_CRATES_PACK_CHOOSE_MOVE_DURATION_MS = 650
ZO_CROWN_CRATES_PACK_CHOOSE_ROTATE_DURATION_MS = 200
ZO_CROWN_CRATES_PACK_CHOOSE_HIDE_DELAY_MS = 450
ZO_CROWN_CRATES_PACK_CHOOSE_HIDE_DURATION_MS = 300
ZO_CROWN_CRATES_PACK_CHOOSE_OFFSET_Y_UI = 150
ZO_CROWN_CRATES_PACK_CHOOSEN_PITCH_RADIANS = math.rad(-8)
ZO_CROWN_CRATES_PACK_CHOOSEN_YAW_RADIANS = math.rad(0)
ZO_CROWN_CRATES_PACK_CHOOSEN_ROLL_RADIANS = math.rad(0)

ZO_CROWN_CRATES_PACK_OPEN_START_YAW_RADIANS = math.rad(0)
ZO_CROWN_CRATES_PACK_OPEN_END_YAW_RADIANS = math.rad(15) 

--Show Info
ZO_CROWN_CRATES_PACK_INFO_AREA_HEIGHT_UI = ZO_CROWN_CRATES_PACK_OFFSET_Y_UI
ZO_CROWN_CRATES_PACK_SHOW_INFO_DURATION_MS = 220

--Hide Info
ZO_CROWN_CRATES_PACK_HIDE_INFO_DURATION_MS = 200

--Animations
ZO_CROWN_CRATES_ANIMATION_PACK_SHOW = "packShow"
ZO_CROWN_CRATES_ANIMATION_PACK_SHOW_INFO = "packShowInfo"
ZO_CROWN_CRATES_ANIMATION_PACK_HIDE_INFO = "packHideInfo"
ZO_CROWN_CRATES_ANIMATION_PACK_SELECT = "packSelect"
ZO_CROWN_CRATES_ANIMATION_PACK_DESELECT = "packDeselect"
ZO_CROWN_CRATES_ANIMATION_PACK_GLOW = "packGlow"
ZO_CROWN_CRATES_ANIMATION_PACK_HIDE = "packHide"
ZO_CROWN_CRATES_ANIMATION_PACK_CHOOSE = "packChoose"
ZO_CROWN_CRATES_ANIMATION_PACK_OPEN = "packOpen"

ZO_CrownCratesPack = ZO_CrownCratesAnimatable:Subclass()

function ZO_CrownCratesPack:New(...)
    return ZO_CrownCratesAnimatable.New(self, ...)
end

function ZO_CrownCratesPack:Initialize(control, owner)
	local crownCratesManager = owner:GetOwner()
    ZO_CrownCratesAnimatable.Initialize(self, control, crownCratesManager)
	self.stateMachine = owner:GetStateMachine()

    control:Create3DRenderSpace()
    self.control = control
    self.owner = owner

    local box = CreateControl("", control, CT_CONTROL)
    box:Create3DRenderSpace()
    self.box = box

    --Because these textures use the depth buffer and can be transparent the order in which they render matters. If something closer to the camera is drawn
    --before something farther, then the farther plane will not appear under the closer one even if the closer one is transparent. We use this to simplify
    --the look of the transparent box.

    --Lid (Drawn First)
    local lid = owner:CreateRectagularPrism(self.box, ZO_CROWN_CRATES_PACK_WIDTH_WORLD, ZO_CROWN_CRATES_PACK_LID_THICKNESS_WORLD, ZO_CROWN_CRATES_PACK_DEPTH_WORLD, 0.5, 0, 1)
    lid:SetDrawTier(DT_LOW)
    self.lidRootOffsetY = 0.5 * ZO_CROWN_CRATES_PACK_HEIGHT_WORLD - ZO_CROWN_CRATES_PACK_LID_THICKNESS_WORLD
    lid:Set3DRenderSpaceOrigin(0, self.lidRootOffsetY, ZO_CROWN_CRATES_PACK_DEPTH_WORLD * 0.5)
    box.lid = lid

    --Draw the front and top first since they will remove the left/right/back planes from showing.
    lid.front:SetDrawLevel(0)
    lid.top:SetDrawLevel(1)
    lid.left:SetDrawLevel(2)
    lid.right:SetDrawLevel(3)
    lid.bottom:SetDrawLevel(4)
    lid.back:SetDrawLevel(5)

    lid.left:SetTextureCoords(512/ZO_CROWN_CRATES_PACK_TEXTURE_WIDTH, 1024/ZO_CROWN_CRATES_PACK_TEXTURE_WIDTH, 512/ZO_CROWN_CRATES_PACK_TEXTURE_HEIGHT, (512 + ZO_CROWN_CRATES_PACK_TEXTURE_LID_HEIGHT)/ZO_CROWN_CRATES_PACK_TEXTURE_HEIGHT)
    lid.front:SetTextureCoords(0/ZO_CROWN_CRATES_PACK_TEXTURE_WIDTH, 512/ZO_CROWN_CRATES_PACK_TEXTURE_WIDTH, 512/ZO_CROWN_CRATES_PACK_TEXTURE_HEIGHT, (512 + ZO_CROWN_CRATES_PACK_TEXTURE_LID_HEIGHT)/ZO_CROWN_CRATES_PACK_TEXTURE_HEIGHT)
    lid.right:SetTextureCoords(512/ZO_CROWN_CRATES_PACK_TEXTURE_WIDTH, 1024/ZO_CROWN_CRATES_PACK_TEXTURE_WIDTH, 512/ZO_CROWN_CRATES_PACK_TEXTURE_HEIGHT, (512 + ZO_CROWN_CRATES_PACK_TEXTURE_LID_HEIGHT)/ZO_CROWN_CRATES_PACK_TEXTURE_HEIGHT)
    lid.back:SetTextureCoords(0/ZO_CROWN_CRATES_PACK_TEXTURE_WIDTH, 512/ZO_CROWN_CRATES_PACK_TEXTURE_WIDTH, 512/ZO_CROWN_CRATES_PACK_TEXTURE_HEIGHT, (512 + ZO_CROWN_CRATES_PACK_TEXTURE_LID_HEIGHT)/ZO_CROWN_CRATES_PACK_TEXTURE_HEIGHT)
    lid.top:SetTextureCoords(0/ZO_CROWN_CRATES_PACK_TEXTURE_WIDTH, 512/ZO_CROWN_CRATES_PACK_TEXTURE_WIDTH, 0/ZO_CROWN_CRATES_PACK_TEXTURE_HEIGHT, 512/ZO_CROWN_CRATES_PACK_TEXTURE_HEIGHT)
    lid.bottom:SetTextureCoords(512/ZO_CROWN_CRATES_PACK_TEXTURE_WIDTH, 1024/ZO_CROWN_CRATES_PACK_TEXTURE_WIDTH, 512/ZO_CROWN_CRATES_PACK_TEXTURE_HEIGHT, 1024/ZO_CROWN_CRATES_PACK_TEXTURE_HEIGHT)
	
    --Body (Drawn Second)
    local body = owner:CreateRectagularPrism(self.box, ZO_CROWN_CRATES_PACK_WIDTH_WORLD, ZO_CROWN_CRATES_PACK_HEIGHT_WORLD - ZO_CROWN_CRATES_PACK_LID_THICKNESS_WORLD, ZO_CROWN_CRATES_PACK_DEPTH_WORLD, 0.5, 0.5, 0.5)
    body:SetDrawTier(DT_MEDIUM)

    --Draw the front and top first since they will remove the left/right/back planes from showing.
    body.front:SetDrawLevel(0)
    body.top:SetDrawLevel(1)
    body.left:SetDrawLevel(2)
    body.right:SetDrawLevel(3)
    body.bottom:SetDrawLevel(4)
    body.back:SetDrawLevel(5)

    body:Set3DRenderSpaceOrigin(0, -0.5 * ZO_CROWN_CRATES_PACK_LID_THICKNESS_WORLD, 0)
    box.body = body
    body.left:SetTextureCoords(512/ZO_CROWN_CRATES_PACK_TEXTURE_WIDTH, 1024/ZO_CROWN_CRATES_PACK_TEXTURE_WIDTH, (512 + ZO_CROWN_CRATES_PACK_TEXTURE_LID_HEIGHT)/ZO_CROWN_CRATES_PACK_TEXTURE_HEIGHT, 1024/ZO_CROWN_CRATES_PACK_TEXTURE_HEIGHT)
    body.front:SetTextureCoords(0/ZO_CROWN_CRATES_PACK_TEXTURE_WIDTH, 512/ZO_CROWN_CRATES_PACK_TEXTURE_WIDTH, (512 + ZO_CROWN_CRATES_PACK_TEXTURE_LID_HEIGHT)/ZO_CROWN_CRATES_PACK_TEXTURE_HEIGHT, 1024/ZO_CROWN_CRATES_PACK_TEXTURE_HEIGHT)
    body.right:SetTextureCoords(512/ZO_CROWN_CRATES_PACK_TEXTURE_WIDTH, 1024/ZO_CROWN_CRATES_PACK_TEXTURE_WIDTH, (512 + ZO_CROWN_CRATES_PACK_TEXTURE_LID_HEIGHT)/ZO_CROWN_CRATES_PACK_TEXTURE_HEIGHT, 1024/ZO_CROWN_CRATES_PACK_TEXTURE_HEIGHT)
    body.back:SetTextureCoords(0/ZO_CROWN_CRATES_PACK_TEXTURE_WIDTH, 512/ZO_CROWN_CRATES_PACK_TEXTURE_WIDTH, (512 + ZO_CROWN_CRATES_PACK_TEXTURE_LID_HEIGHT)/ZO_CROWN_CRATES_PACK_TEXTURE_HEIGHT, 1024/ZO_CROWN_CRATES_PACK_TEXTURE_HEIGHT)
    body.top:SetTextureCoords(0/ZO_CROWN_CRATES_PACK_TEXTURE_WIDTH, 512/ZO_CROWN_CRATES_PACK_TEXTURE_WIDTH, 0/ZO_CROWN_CRATES_PACK_TEXTURE_HEIGHT, 512/ZO_CROWN_CRATES_PACK_TEXTURE_HEIGHT)
    body.bottom:SetTextureCoords(512/ZO_CROWN_CRATES_PACK_TEXTURE_WIDTH, 1024/ZO_CROWN_CRATES_PACK_TEXTURE_WIDTH, 512/ZO_CROWN_CRATES_PACK_TEXTURE_HEIGHT, 1024/ZO_CROWN_CRATES_PACK_TEXTURE_HEIGHT)
    --"Shadow" the top surface
    body.top:SetColor(0.35, 0.35, 0.35)

    local glowFront = owner:CreateCenteredFace(body, ZO_CROWN_CRATES_PACK_WIDTH_WORLD, ZO_CROWN_CRATES_PACK_HEIGHT_WORLD - ZO_CROWN_CRATES_PACK_LID_THICKNESS_WORLD)
    local frontOriginX, frontOriginY, frontOriginZ = body.front:Get3DRenderSpaceOrigin()
    glowFront:SetBlendMode(TEX_BLEND_MODE_ADD)
	glowFront:Set3DRenderSpaceOrigin(frontOriginX, frontOriginY, frontOriginZ - 0.0001)
    body.glowFront = glowFront
    body.glowFront:SetTextureCoords(512/ZO_CROWN_CRATES_PACK_TEXTURE_WIDTH, 1024/ZO_CROWN_CRATES_PACK_TEXTURE_WIDTH, ZO_CROWN_CRATES_PACK_TEXTURE_LID_HEIGHT/ZO_CROWN_CRATES_PACK_TEXTURE_HEIGHT, 512/ZO_CROWN_CRATES_PACK_TEXTURE_HEIGHT)
    body.glowFront:SetDrawLevel(0)

    --Front Mouse Plane
    local frontMousePlaneHeightWorld = ZO_CROWN_CRATES_PACK_HEIGHT_WORLD + ZO_CROWN_CRATES_PACK_FRONT_MOUSE_PLANE_BUFFER_WORLD
    local frontMousePlane = owner:CreateCenteredFace(box, ZO_CROWN_CRATES_PACK_WIDTH_WORLD, frontMousePlaneHeightWorld)
    frontMousePlane:Set3DRenderSpaceOrigin(frontOriginX, frontOriginY - 0.5 * frontMousePlaneHeightWorld + 0.5 * ZO_CROWN_CRATES_PACK_HEIGHT_WORLD, frontOriginZ)
    frontMousePlane:SetAlpha(0)
    self.frontMousePlane = frontMousePlane

    self.infoControl = control:GetNamedChild("Info")
    self.infoNameLabel = self.infoControl:GetNamedChild("Name")

    self:InitializeStyles()

    frontMousePlane:SetMouseEnabled(true)
    lid.top:SetMouseEnabled(true)

    local function OnMouseEnter()
        owner:PackOnMouseEnter(self)
    end
    local function OnMouseExit()
        owner:PackOnMouseExit(self)
    end
    ZO_CrownCrates.AddBounceResistantMouseHandlersToControl(box, OnMouseEnter, OnMouseExit)    
    self.boxMouseInputGroup = ZO_MouseInputGroup:New(box)
    self.boxMouseInputGroup:Add(frontMousePlane, ZO_MOUSE_INPUT_GROUP_MOUSE_OVER)
    self.boxMouseInputGroup:Add(lid.top, ZO_MOUSE_INPUT_GROUP_MOUSE_OVER)
        
    --where ... is a list of controls to add the handlers to
    local function AddUpHandler(...)
        local function OnMouseUp() owner:PackOnMouseUp(self) end

        for i = 1, select("#", ...) do
            local control = select(i, ...)
            control:SetHandler("OnMouseUp", OnMouseUp)
        end
    end
    AddUpHandler(frontMousePlane, lid.top)
    
    self:Reset()
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
    }

    function ZO_CrownCratesPack:InitializeStyles()
        ZO_PlatformStyle:New(function(style) self:ApplyStyle(style) end, KEYBOARD_STYLE, GAMEPAD_STYLE)
    end
end

function ZO_CrownCratesPack:ApplyStyle(style)
    ZO_FontAdjustingWrapLabel_OnInitialized(self.infoNameLabel, style.nameFonts, TEXT_WRAP_MODE_ELLIPSIS)
end

function ZO_CrownCratesPack:Reset()
    ZO_CrownCratesAnimatable.Reset(self)

    self.crateId = nil
    self.visualCrateId = nil
    self.visualSlotIndex = nil
    self.control:SetAlpha(1)
    self.infoControl:SetAlpha(0)
    local box = self.box
    box.body.front:SetAlpha(1)
    box.body.glowFront:SetAlpha(0)
    box.lid:Set3DRenderSpaceOrientation(ZO_CROWN_CRATES_PACK_OPEN_START_YAW_RADIANS, 0, 0)
    self.visuallySelected = false
    self.rootX = nil
    self.rootY = nil
    self.rootZ = nil
    self.frontMousePlane:SetMouseEnabled(false)
    box.lid.top:SetMouseEnabled(false)
end

function ZO_CrownCratesPack:InitializeForShow(crateId, visualSlotIndex)
    self.crateId = crateId
    local visualCrateId = crateId
    if not visualCrateId then
        visualCrateId = GetOnSaleCrownCrateId()
    end
    self.visualCrateId = visualCrateId
    self.visualSlotIndex = visualSlotIndex
    
    local isPlaceholderCrate = self:IsPlaceholderCrate()
    if visualCrateId then
        local normalTexture = GetCrownCratePackNormalTexture(visualCrateId)
        local box = self.box
        box:SetAlpha(isPlaceholderCrate and ZO_CROWN_CRATES_PACK_PLACEHOLDER_ALPHA or ZO_CROWN_CRATES_PACK_NORMAL_ALPHA)
        
		local body = box.body
		body.front:SetTexture(normalTexture)
		body.glowFront:SetTexture(normalTexture)
		body.back:SetTexture(normalTexture)
		body.left:SetTexture(normalTexture)
		body.right:SetTexture(normalTexture)
		body.top:SetTexture(normalTexture)
		body.bottom:SetTexture(normalTexture)

        local lid = box.lid
        lid.front:SetTexture(normalTexture)
		lid.back:SetTexture(normalTexture)
		lid.left:SetTexture(normalTexture)
		lid.right:SetTexture(normalTexture)
		lid.top:SetTexture(normalTexture)
		lid.bottom:SetTexture(normalTexture)
    end

    if isPlaceholderCrate then
        self.infoNameLabel:SetHidden(true)
    else
        self.infoNameLabel:SetHidden(false)
        local crateName = GetCrownCrateName(crateId)
        local crateCount = GetCrownCrateCount(crateId)
        if crateCount > 1 then
            self.infoNameLabel:SetText(zo_strformat(SI_CROWN_CRATE_PACK_WITH_STACK_NAME, crateName, crateCount))
        else
            self.infoNameLabel:SetText(zo_strformat(SI_CROWN_CRATE_PACK_NAME, crateName))
        end
    end
end

function ZO_CrownCratesPack:IsPlaceholderCrate()
    return self.crateId == nil
end

function ZO_CrownCratesPack:GetCrownCrateId()
    return self.crateId
end

function ZO_CrownCratesPack:IsSelected()
    return self.owner:GetSelectedPack() == self
end

function ZO_CrownCratesPack:OnSelect()
    if self:CanSelect() then
        self:Select()
    end
end

function ZO_CrownCratesPack:OnDeselect()
    if self:CanSelect() then
        self:Deselect()
    end
end

function ZO_CrownCratesPack:CanSelect()
    return self.stateMachine:IsCurrentStateByName("MANIFEST")
end

function ZO_CrownCratesPack:Show(startX, startY, startZ, endX, endY, endZ)
    self.control:SetHidden(false)
    self.control:Set3DRenderSpaceOrientation(ZO_CROWN_CRATES_PACK_SHOW_START_PITCH_RADIANS, ZO_CROWN_CRATES_PACK_SHOW_START_YAW_RADIANS, ZO_CROWN_CRATES_PACK_SHOW_START_ROLL_RADIANS)

    local animationTimeline = self:AcquireAndApplyAnimationTimeline(ZO_CROWN_CRATES_ANIMATION_PACK_SHOW, self.control, function(timeline, completedPlaying)
        if completedPlaying then
            self.owner:OnManifestPackInComplete()
            --Mouse input on the crate is not enabled until it is finished showing. This will prevent the case where the mouse enters the 
            --crate and then exits it again as it flips and then enters once more but we suppress the enter because of the bounce prevention logic.
            self.frontMousePlane:SetMouseEnabled(true)
            self.box.lid.top:SetMouseEnabled(true)
        end
    end)

    local translateAnimation = animationTimeline:GetAnimation(1)
    translateAnimation:SetTranslateOffsets(startX, startY, startZ, endX, endY, endZ)

    local rotateAnimation = animationTimeline:GetAnimation(2)
    rotateAnimation:SetRotationValues(ZO_CROWN_CRATES_PACK_SHOW_START_PITCH_RADIANS, ZO_CROWN_CRATES_PACK_SHOW_START_YAW_RADIANS, ZO_CROWN_CRATES_PACK_SHOW_START_ROLL_RADIANS,
        ZO_CROWN_CRATES_PACK_SHOW_END_PITCH_RADIANS, ZO_CROWN_CRATES_PACK_SHOW_END_YAW_RADIANS, ZO_CROWN_CRATES_PACK_SHOW_END_ROLL_RADIANS)

    self:StartAnimation(animationTimeline)

    self.rootX = endX
    self.rootY = endY
    self.rootZ = endZ
end

function ZO_CrownCratesPack:StartGlowUp()
    local body = self.box.body
    local glowTimeline = self:AcquireAndApplyAnimationTimeline(ZO_CROWN_CRATES_ANIMATION_PACK_GLOW)

    local glowAlphaAnimation = glowTimeline:GetAnimation(1)
    glowAlphaAnimation:SetAnimatedControl(body.glowFront)
    glowAlphaAnimation:SetAlphaValues(body.glowFront:GetAlpha(), 1)

    self:StartAnimation(glowTimeline)
end

function ZO_CrownCratesPack:StartGlowDown()
    local body = self.box.body
    local glowTimeline = self:AcquireAndApplyAnimationTimeline(ZO_CROWN_CRATES_ANIMATION_PACK_GLOW)

    local glowAlphaAnimation = glowTimeline:GetAnimation(1)
    glowAlphaAnimation:SetAnimatedControl(body.glowFront)
    glowAlphaAnimation:SetAlphaValues(body.glowFront:GetAlpha(), 0)

    self:StartAnimation(glowTimeline)
end

function ZO_CrownCratesPack:StartSelectAnimation()
    local timeline = self:AcquireAndApplyAnimationTimeline(ZO_CROWN_CRATES_ANIMATION_PACK_SELECT, self.control, function(timeline, completedPlaying)
        if completedPlaying then
            self.visuallySelected = true
            if not self:IsSelected() then
                self:StartDeselectAnimation()
            end
        end
    end)
    local rotateAnimation = timeline:GetAnimation(1)
    rotateAnimation:SetRotationValues(ZO_CROWN_CRATES_PACK_SHOW_END_PITCH_RADIANS, ZO_CROWN_CRATES_PACK_SHOW_END_YAW_RADIANS, ZO_CROWN_CRATES_PACK_SHOW_END_ROLL_RADIANS,
        ZO_CROWN_CRATES_PACK_SELECTED_PITCH_RADIANS, ZO_CROWN_CRATES_PACK_SELECTED_YAW_RADIANS, ZO_CROWN_CRATES_PACK_SELECTED_ROLL_RADIANS)
    self:StartAnimation(timeline)

    local translateAnimation = timeline:GetAnimation(2)
    local offsetYWorld = ZO_CrownCrates.ConvertUIUnitsToWorldUnits(self.owner:GetManifestCameraPlaneMetrics(), ZO_CROWN_CRATES_PACK_SELECTION_OFFSET_Y_UI)
    self.control:Set3DRenderSpaceOrigin(self.rootX, self.rootY, self.rootZ)
    translateAnimation:SetTranslateOffsets(self.rootX, self.rootY, self.rootZ, self.rootX, self.rootY + offsetYWorld, self.rootZ)

    self:StartGlowUp()
    self:ShowInfo()
end

function ZO_CrownCratesPack:Select()
    if not self:GetOnePlayingAnimationOfType(ZO_CROWN_CRATES_ANIMATION_PACK_DESELECT) and
        not self:GetOnePlayingAnimationOfType(ZO_CROWN_CRATES_ANIMATION_PACK_SELECT) and
        not self.visuallySelected then
            self:StartSelectAnimation()
    end
    PlaySound(SOUNDS.CROWN_CRATES_MANIFEST_SELECTED)
end

function ZO_CrownCratesPack:StartDeselectAnimation()
    local timeline = self:AcquireAndApplyAnimationTimeline(ZO_CROWN_CRATES_ANIMATION_PACK_DESELECT, self.control, function(timeline, completedPlaying)
        self.visuallySelected = false
        if completedPlaying then
            if self:IsSelected() then
                self:StartSelectAnimation()
            end
        end
    end)
    local rotateAnimation = timeline:GetAnimation(1)
    rotateAnimation:SetRotationValues(ZO_CROWN_CRATES_PACK_SELECTED_PITCH_RADIANS, ZO_CROWN_CRATES_PACK_SELECTED_YAW_RADIANS, ZO_CROWN_CRATES_PACK_SELECTED_ROLL_RADIANS,
        ZO_CROWN_CRATES_PACK_SHOW_END_PITCH_RADIANS, ZO_CROWN_CRATES_PACK_SHOW_END_YAW_RADIANS, ZO_CROWN_CRATES_PACK_SHOW_END_ROLL_RADIANS)
    self:StartAnimation(timeline)

    local translateAnimation = timeline:GetAnimation(2)
    local offsetYWorld = ZO_CrownCrates.ConvertUIUnitsToWorldUnits(self.owner:GetManifestCameraPlaneMetrics(), ZO_CROWN_CRATES_PACK_SELECTION_OFFSET_Y_UI)
    self.control:Set3DRenderSpaceOrigin(self.rootX, self.rootY + offsetYWorld, self.rootZ)
    translateAnimation:SetTranslateOffsets(self.rootX, self.rootY + offsetYWorld, self.rootZ, self.rootX, self.rootY, self.rootZ)
    
    self:StartGlowDown()
    self:HideInfo()
end

function ZO_CrownCratesPack:Deselect()
    if not self:GetOnePlayingAnimationOfType(ZO_CROWN_CRATES_ANIMATION_PACK_SELECT) and
        not self:GetOnePlayingAnimationOfType(ZO_CROWN_CRATES_ANIMATION_PACK_DESELECT) and
        self.visuallySelected then
            self:StartDeselectAnimation()
    end
end

function ZO_CrownCratesPack:ShowInfo()
    local animationTimeline = self:AcquireAndApplyAnimationTimeline(ZO_CROWN_CRATES_ANIMATION_PACK_SHOW_INFO, self.infoControl)
    local infoX, infoY = ZO_CrownCrates.ComputeSlotBottomUIPosition(ZO_CROWN_CRATES_PACK_WIDTH_UI, ZO_CROWN_CRATES_PACK_SPACING_UI, self.visualSlotIndex, self.owner:GetVisualPackCount())
    self.infoControl:ClearAnchors()
    self.infoControl:SetAnchor(BOTTOM, GuiRoot, TOPLEFT, infoX, infoY)
    self:StartAnimation(animationTimeline)
end

function ZO_CrownCratesPack:HideInfo()
    self:StopAllAnimationsOfType(ZO_CROWN_CRATES_ANIMATION_SHOW_INFO)
    local animationTimeline = self:AcquireAndApplyAnimationTimeline(ZO_CROWN_CRATES_ANIMATION_PACK_HIDE_INFO, self.infoControl)
    local alphaAnimation = animationTimeline:GetAnimation(1)
    alphaAnimation:SetAlphaValues(self.infoControl:GetAlpha(), 0)
    self:StartAnimation(animationTimeline)
end

function ZO_CrownCratesPack:Hide()
    self:StopAllAnimationsOfType(ZO_CROWN_CRATES_ANIMATION_PACK_GLOW)
    self:StopAllAnimationsOfType(ZO_CROWN_CRATES_ANIMATION_PACK_SELECT)
    self:StopAllAnimationsOfType(ZO_CROWN_CRATES_ANIMATION_PACK_DESELECT)

    local timeline = self:AcquireAndApplyAnimationTimeline(ZO_CROWN_CRATES_ANIMATION_PACK_HIDE, self.control, function(timeline, completedPlaying)
        if completedPlaying then
            self.owner:OnManifestPackOutComplete()
        end
    end)
    local translateAnimation = timeline:GetAnimation(1)
    local startX, startY, startZ = self.control:Get3DRenderSpaceOrigin()
    local endX = startX
    local manifestPlaneMetrics = self.owner:GetManifestCameraPlaneMetrics()
    local endY = startY + ZO_CrownCrates.ConvertUIUnitsToWorldUnits(manifestPlaneMetrics, ZO_CROWN_CRATES_PACK_HIDE_OFFSET_Y_UI)
    local endZ = startZ
    translateAnimation:SetTranslateOffsets(startX, startY, startZ, endX, endY, endZ)
   
    self:StartAnimation(timeline)

    self:StartGlowDown()
    self:HideInfo()
end

function ZO_CrownCratesPack:Choose()
    self:StopAllAnimationsOfType(ZO_CROWN_CRATES_ANIMATION_PACK_GLOW)
    self:StopAllAnimationsOfType(ZO_CROWN_CRATES_ANIMATION_PACK_SELECT)
    self:StopAllAnimationsOfType(ZO_CROWN_CRATES_ANIMATION_PACK_DESELECT)

    local timeline = self:AcquireAndApplyAnimationTimeline(ZO_CROWN_CRATES_ANIMATION_PACK_CHOOSE, self.control, function(timeline, completedPlaying)
        if completedPlaying then
            self.owner:OnManifestPackOutComplete()
        end
    end)
    local translateAnimation = timeline:GetAnimation(1)
    local startX, startY, startZ = self.control:Get3DRenderSpaceOrigin()
    local endX = startX
    local manifestPlaneMetrics = self.owner:GetManifestCameraPlaneMetrics()
    local endY = startY + ZO_CrownCrates.ConvertUIUnitsToWorldUnits(manifestPlaneMetrics, ZO_CROWN_CRATES_PACK_CHOOSE_OFFSET_Y_UI)
    local endZ = startZ
    translateAnimation:SetTranslateOffsets(startX, startY, startZ, endX, endY, endZ)
   
    local rotateAnimation = timeline:GetAnimation(2)
    local startPitch, startYaw, startRoll = self.control:Get3DRenderSpaceOrientation()
    rotateAnimation:SetRotationValues(startPitch, startYaw, startRoll, ZO_CROWN_CRATES_PACK_CHOOSEN_PITCH_RADIANS, ZO_CROWN_CRATES_PACK_CHOOSEN_YAW_RADIANS, ZO_CROWN_CRATES_PACK_CHOOSEN_ROLL_RADIANS)

    self:StartAnimation(timeline)

    self:StartGlowUp()

    local boxOpenTimeline = self:AcquireAndApplyAnimationTimeline(ZO_CROWN_CRATES_ANIMATION_PACK_OPEN, self.box.lid)
    self:StartAnimation(boxOpenTimeline) 

    self:HideInfo()
end

------------------------------
--Crown Crates Pack Choosing--
------------------------------

ZO_CROWN_CRATES_PACK_CHOOSING_PACKS_PER_PAGE = 5

ZO_CrownCratesPackChoosing = ZO_Object:Subclass()

function ZO_CrownCratesPackChoosing:New(...)
    local obj = ZO_Object.New(self)
    obj:Initialize(...)
    return obj
end

function ZO_CrownCratesPackChoosing:Initialize(owner)
    self.owner = owner
    self.nextPackIndex = 1
    self.packsInVisualOrder = {}
    self:InitializePackPool()
    self:InitializeKeybinds()
    
    self.initialized = true
end

function ZO_CrownCratesPackChoosing:GetStateMachine()
	return self.stateMachine
end

function ZO_CrownCratesPackChoosing:SetStateMachine(stateMachine)
	self.stateMachine = stateMachine
end

function ZO_CrownCratesPackChoosing:GetOwner()
	return self.owner
end

function ZO_CrownCratesPackChoosing:InitializePackPool()
    local reset = function(pack)
        pack:Reset()
    end    
    local factory = function(pool)
                        local pack = ZO_CrownCratesPack:New(CreateControlFromVirtual("$(parent)Pack", self.owner:GetControl(), "ZO_CrownCratePack", self.nextPackIndex), self)
                        self.nextPackIndex = self.nextPackIndex + 1
                        return pack          
                    end
    
    self.packPool = ZO_ObjectPool:New(factory, reset)
end

function ZO_CrownCratesPackChoosing:InitializeKeybinds()
    -- Keyboard --
    self.keyboardManifestKeybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_CENTER,

        {
            keybind = "UI_SHORTCUT_PRIMARY",
            name = GetString(SI_CROWN_CRATE_OPEN_NEXT_CRATE_KEYBIND),
            callback = function()
                local pack = self:GetPackInVisualOrder(1)
                self:Choose(pack)
            end,
            enabled = function()
                local pack = self:GetPackInVisualOrder(1)
                if pack and not pack:IsPlaceholderCrate() then
                    return true
                end
                return false, GetString("SI_LOOTCRATEOPENRESPONSE", LOOT_CRATE_OPEN_RESPONSE_OUT_OF_ALL_LOOT_CRATES)
            end
        },

        ZO_CROWN_CRATES_BUY_CRATES_KEYBIND_KEYBOARD,
    }

    -- Gamepad --
    self.gamepadManifestKeybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_CENTER,

        {
            keybind = "UI_SHORTCUT_PRIMARY",
            name = GetString(SI_CROWN_CRATE_OPEN_SELECTED_CRATE_KEYBIND),
            callback = function()
                local pack = self:GetSelectedPack()
                self:Choose(pack)
            end,
            enabled = function()
                local pack = self:GetSelectedPack()
                if pack and not pack:IsPlaceholderCrate() then
                    return true
                end
                return false, GetString("SI_LOOTCRATEOPENRESPONSE", LOOT_CRATE_OPEN_RESPONSE_OUT_OF_ALL_LOOT_CRATES)
            end
        },

        ZO_CROWN_CRATES_BUY_CRATES_KEYBIND_GAMEPAD,
    }
end

function ZO_CrownCratesPackChoosing:RefreshCameraPlaneMetrics()
    self.manifestCameraPlaneMetrics = self.owner:ComputeCameraPlaneMetrics(ZO_CROWN_CRATES_PACK_WIDTH_WORLD, ZO_CROWN_CRATES_PACK_WIDTH_UI)
end

function ZO_CrownCratesPackChoosing:OnLockLocalSpaceToCurrentCamera()
    self:RefreshCameraPlaneMetrics()
end

function ZO_CrownCratesPackChoosing:GetManifestCameraPlaneMetrics()
    return self.manifestCameraPlaneMetrics
end

function ZO_CrownCratesPackChoosing:ResetPacks()
    self.packPool:ReleaseAllObjects()
    self.currentPage = nil
    self.crateIds = nil
    self.chosenPack = nil
    ZO_ClearNumericallyIndexedTable(self.packsInVisualOrder)
    self.selectedPack = nil
end

function ZO_CrownCratesPackChoosing:CreateRectagularPrism(parentControl, width, height, depth, registrationX, registrationY, registrationZ, texture)
    local prism = CreateControl("", parentControl, CT_CONTROL)
    prism:Create3DRenderSpace()

    local centerX = width * (0.5 - registrationX)
    local centerY = height * (0.5 - registrationY)
    local centerZ = depth * (0.5 - registrationZ) 

    --Front
    local frontFace = self:CreateCenteredFace(prism, width, height)
    frontFace:Set3DRenderSpaceOrigin(centerX, centerY, centerZ - depth * 0.5)
    prism.front = frontFace

    --Back
    local backFace = self:CreateCenteredFace(prism, width, height)
    backFace:Set3DRenderSpaceOrigin(centerX, centerY, centerZ + depth * 0.5)
    prism.back = backFace

    --Bottom
    local bottomFace = self:CreateCenteredFace(prism, width, depth)
    bottomFace:Set3DRenderSpaceOrientation(math.rad(90), 0, 0)
    bottomFace:Set3DRenderSpaceOrigin(centerX, centerY - height * 0.5 , centerZ)
    prism.bottom = bottomFace

    --Top
    local topFace = self:CreateCenteredFace(prism, width, depth)
    topFace:Set3DRenderSpaceOrientation(math.rad(90), 0, 0)
    topFace:Set3DRenderSpaceOrigin(centerX, centerY + height * 0.5 , centerZ)
    prism.top = topFace

    --Left
    local leftFace = self:CreateCenteredFace(prism, depth, height)
    leftFace:Set3DRenderSpaceOrientation(0, math.rad(90), 0)
    leftFace:Set3DRenderSpaceOrigin(centerX - width * 0.5, centerY, centerZ)
    prism.left = leftFace

    --Right
    local rightFace = self:CreateCenteredFace(prism, depth, height)
    rightFace:Set3DRenderSpaceOrientation(0, math.rad(90), 0)
    rightFace:Set3DRenderSpaceOrigin(centerX + width * 0.5, centerY, centerZ)
    prism.right = rightFace

    return prism
end

function ZO_CrownCratesPackChoosing:CreateCenteredFace(parentControl, width, height)
    local face = CreateControl("", parentControl, CT_TEXTURE)
    face:Create3DRenderSpace()
    face:Set3DLocalDimensions(width, height)
    face:Set3DRenderSpaceUsesDepthBuffer(true)
    return face
end

function ZO_CrownCratesPackChoosing:GetPack(packIndex)
    return self.packPool:AcquireObject(packIndex)
end

function ZO_CrownCratesPackChoosing:Show()
    local crateIds = {}
    for crateId in ZO_GetNextOwnedCrownCrateIdIter do
        table.insert(crateIds, crateId)
    end
    self.crateIds = crateIds
    self.currentPage = 1
    if #self.crateIds > 0 then
        self.numPages = zo_ceil(#self.crateIds / ZO_CROWN_CRATES_PACK_CHOOSING_PACKS_PER_PAGE)
    else
        self.numPages = 0
    end
    self:StartShowAnimation()
end

function ZO_CrownCratesPackChoosing:AnimateChoice()
    self.chosenPack:Choose()

    for _, pack in ipairs(self.packPool:GetActiveObjects()) do
        if pack ~= self.chosenPack then
            pack:Hide()
        end
    end
end

function ZO_CrownCratesPackChoosing:Hide()
    for _, pack in ipairs(self.packPool:GetActiveObjects()) do
        pack:Hide()
    end
end

function ZO_CrownCratesPackChoosing:ComputeSlotCenterWorldPosition(planeMetrics, spacingUI, bottomOffsetUI, bottomOffsetWorld, slotIndex, totalSlots)
    local spacingWorldWidth = spacingUI * planeMetrics.worldUnitsPerUIUnit
    local totalWorldWidth = totalSlots * ZO_CROWN_CRATES_PACK_WIDTH_WORLD + (totalSlots - 1) * spacingWorldWidth
    local slotCenterX = ZO_CROWN_CRATES_PACK_WIDTH_WORLD * 0.5 + (slotIndex - 1) * (ZO_CROWN_CRATES_PACK_WIDTH_WORLD + spacingWorldWidth)

    local x = slotCenterX - totalWorldWidth * 0.5
    local y = planeMetrics.frustumHeightWorld * -0.5 + bottomOffsetUI * planeMetrics.worldUnitsPerUIUnit + bottomOffsetWorld + ZO_CROWN_CRATES_PACK_HEIGHT_WORLD * 0.5
    --we build the box from the center, but we choose its world width based on the front, so push it half its depth into the screen so its front is registered with manifest plane.
    local z = planeMetrics.depthFromCamera + ZO_CROWN_CRATES_PACK_DEPTH_WORLD * 0.5

    return x, y, z
end

function ZO_CrownCratesPackChoosing:StartPackShowAnimation(packIndex, numPacks, crateId)
    local pack = self:GetPack(packIndex)
    pack:InitializeForShow(crateId, packIndex)
    --20 more units off the bottom to start so the packs are just peeking above the bottom of the screen
    local ADDITIONAL_START_OFFSET_Y = -20
    local startX, startY, startZ = self:ComputeSlotCenterWorldPosition(self.manifestCameraPlaneMetrics, ZO_CROWN_CRATES_PACK_SPACING_UI, ADDITIONAL_START_OFFSET_Y, -ZO_CROWN_CRATES_PACK_HEIGHT_WORLD, packIndex, numPacks)
    local endX, endY, endZ = self:ComputeSlotCenterWorldPosition(self.manifestCameraPlaneMetrics, ZO_CROWN_CRATES_PACK_SPACING_UI, ZO_CROWN_CRATES_PACK_OFFSET_Y_UI + ZO_CrownCrates.GetBottomOffsetUI(), 0, packIndex, numPacks)
    pack:CallLater(function()
        pack:Show(startX, startY, startZ, endX, endY, endZ)
    end, (packIndex - 1) * ZO_CROWN_CRATES_PACK_SHOW_SPACING_MS + 1)
    self.packsInVisualOrder[packIndex] = pack
end

function ZO_CrownCratesPackChoosing:StartShowAnimation()
    if #self.crateIds > 0 then
        local startIndex = 1 + (self.currentPage - 1) * ZO_CROWN_CRATES_PACK_CHOOSING_PACKS_PER_PAGE
        local endIndex = self.currentPage * ZO_CROWN_CRATES_PACK_CHOOSING_PACKS_PER_PAGE
        endIndex = zo_min(endIndex, #self.crateIds)
        ZO_ClearNumericallyIndexedTable(self.packsInVisualOrder)

        local packIndex = 1
        local numPacks = endIndex - startIndex + 1
        for i = startIndex, endIndex do
            local crateId = self.crateIds[i]
            self:StartPackShowAnimation(packIndex, numPacks, crateId)
            packIndex = packIndex + 1
        end
    else
        self:StartPackShowAnimation(1, 1)
    end
end

function ZO_CrownCratesPackChoosing:Choose(chosenPack)
    if chosenPack:IsPlaceholderCrate() then
        ZO_AlertEvent(EVENT_CROWN_CRATE_OPEN_RESPONSE, nil, LOOT_CRATE_OPEN_RESPONSE_OUT_OF_ALL_LOOT_CRATES)
    else
        if chosenPack:CanSelect() then
            local crownCrateId = chosenPack:GetCrownCrateId()
            local numSlotsForCrate = GetInventorySpaceRequiredToOpenCrownCrate(crownCrateId)
            if CheckInventorySpaceSilently(numSlotsForCrate) then
                self.chosenPack = chosenPack
                self.stateMachine:FireCallbacks(ZO_CROWN_CRATE_TRIGGER_COMMANDS.DEAL_REQUESTED)
                SendCrownCrateOpenRequest(crownCrateId)
                PlaySound(SOUNDS.CROWN_CRATES_MANIFEST_CHOSEN)
            else
                ZO_AlertEvent(EVENT_CROWN_CRATE_OPEN_RESPONSE, crownCrateId, LOOT_CRATE_OPEN_RESPONSE_FAIL_NO_INVENTORY_SPACE)
            end
        end
    end    
end

function ZO_CrownCratesPackChoosing:OnManifestPackInComplete()
    self.stateMachine:FireCallbacks(ZO_CROWN_CRATE_TRIGGER_COMMANDS.MANIFEST_IN_COMPLETE)
end

function ZO_CrownCratesPackChoosing:OnManifestPackOutComplete()
    self.stateMachine:FireCallbacks(ZO_CROWN_CRATE_TRIGGER_COMMANDS.MANIFEST_OUT_COMPLETE)
end

function ZO_CrownCratesPackChoosing:GetCurrentPage()
    return self.currentPage
end

function ZO_CrownCratesPackChoosing:GetPreviousPage()
    local page = self.currentPage - 1
    return page == 0 and self.numPages or page
end

function ZO_CrownCratesPackChoosing:GetNextPage()
    local page = self.currentPage + 1
    return page > self.numPages and 1 or page
end

function ZO_CrownCratesPackChoosing:GetNumPacksToDisplayOnPage(page)
    if self.crateIds then
        if page > 0 and page < self.numPages then
            return ZO_CROWN_CRATES_PACK_CHOOSING_PACKS_PER_PAGE
        elseif page == self.numPages then
            return zo_mod(#self.crateIds, ZO_CROWN_CRATES_PACK_CHOOSING_PACKS_PER_PAGE)
        end
    end
    return 0
end

function ZO_CrownCratesPackChoosing:AddManifestKeybinds()
    if self.initialized then
        if SCENE_MANAGER:IsCurrentSceneGamepad() then
            self:SetSelectedPack(self:GetPackInVisualOrder(1))
            KEYBIND_STRIP:AddKeybindButtonGroup(self.gamepadManifestKeybindStripDescriptor)
        else
            KEYBIND_STRIP:AddKeybindButtonGroup(self.keyboardManifestKeybindStripDescriptor)
        end
    end
end

function ZO_CrownCratesPackChoosing:RemoveManifestKeybinds()
    if self.initialized then
        if SCENE_MANAGER:IsCurrentSceneGamepad() then
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.gamepadManifestKeybindStripDescriptor)
        else
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keyboardManifestKeybindStripDescriptor)
        end
    end
end

function ZO_CrownCratesPackChoosing:HandleDirectionalInput(selectedDirection)
    if self.stateMachine:IsCurrentStateByName("MANIFEST") and selectedDirection then
        local selectedPack = self:GetSelectedPack()
        local nextPack
        if selectedPack then
            local nextVisualSlotIndex = selectedPack.visualSlotIndex + selectedDirection
            if nextVisualSlotIndex > self:GetVisualPackCount() then 
                nextVisualSlotIndex = 1
            elseif nextVisualSlotIndex < 1 then
                nextVisualSlotIndex = self:GetVisualPackCount()
            end
            nextPack = self:GetPackInVisualOrder(nextVisualSlotIndex)
        else
            -- this is specifically for players using the gamepad UI but using a mouse and gamepad to navigate this
            nextPack = self:GetPackInVisualOrder(1)
        end
        self:SetSelectedPack(nextPack)
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.gamepadManifestKeybindStripDescriptor)
    end
end

function ZO_CrownCratesPackChoosing:GetPackInVisualOrder(visualIndex)
    return self.packsInVisualOrder[visualIndex]
end

function ZO_CrownCratesPackChoosing:GetVisualPackCount()
    return #self.packsInVisualOrder
end

function ZO_CrownCratesPackChoosing:GetSelectedPack()
    return self.selectedPack
end

function ZO_CrownCratesPackChoosing:SetSelectedPack(pack)
    if self.selectedPack ~= pack then
        if self.selectedPack then
            self.selectedPack:OnDeselect()
        end

        self.selectedPack = pack

        if pack then
            pack:OnSelect()
        end
    end
end

function ZO_CrownCratesPackChoosing:RefreshSelectedPack()
    if self.selectedPack then
        self.selectedPack:OnSelect()
    end
end

--Pack Mouse Behavior
function ZO_CrownCratesPackChoosing:PackOnMouseEnter(pack)
    if not SCENE_MANAGER:IsCurrentSceneGamepad() then
        self:SetSelectedPack(pack)
    end
end

function ZO_CrownCratesPackChoosing:PackOnMouseExit(pack)
    if not SCENE_MANAGER:IsCurrentSceneGamepad() then
        self:SetSelectedPack(nil)
    end
end

function ZO_CrownCratesPackChoosing:PackOnMouseUp(pack)
    if not SCENE_MANAGER:IsCurrentSceneGamepad() then
        self:Choose(pack)
    end
end