ZO_CHAMPION_CONSTELLATION_DEPTH = 1.69
ZO_CHAMPION_CLUSTER_DEPTH = 2.69
ZO_CHAMPION_CONSTELLATION_WIDTH = 600
ZO_CHAMPION_CONSTELLATION_HEIGHT = 338
ZO_CHAMPION_CLUSTER_WIDTH = 400
ZO_CHAMPION_CLUSTER_HEIGHT = 200
ZO_CHAMPION_CONSTELLATION_INNER_RADIUS = 190 -- how far is the start of the constellation from the center of the ring?
ZO_CONSTELLATION_TEXTURE_SIZE_WIDTH = 2048
ZO_CONSTELLATION_TEXTURE_SIZE_HEIGHT = 1024
ZO_CONSTELLATION_TEXTURE_INNER_WIDTH = 1776
ZO_CONSTELLATION_TEXTURE_INNER_HEIGHT = 1000

-- Each ring anchor represents a place on the global ring that each
-- constellation could be in. Each constellation will always be attached to one
-- ring anchor, but there may be inactive ring anchors elsewhere on the ring that
-- should be out of sight of the player.
ZO_ChampionConstellationRingAnchor = ZO_InitializingObject:Subclass()

function ZO_ChampionConstellationRingAnchor:Initialize(sceneGraph, anchorIndex)
    self.anchorIndex = anchorIndex
    local canvasControl = CHAMPION_PERKS:GetChampionCanvas()
    self.constellationZoomedOutTexture = CreateControlFromVirtual("$(parent)Constellation", canvasControl, "ZO_Constellation", anchorIndex)
    self.constellationZoomedInTexture = CreateControlFromVirtual("$(parent)ConstellationZoomedIn", canvasControl, "ZO_ConstellationZoomedIn", anchorIndex)
    self.constellationSelectedTexture = CreateControlFromVirtual("$(parent)ConstellationMouseOver", canvasControl, "ZO_ConstellationMouseOver", anchorIndex)

    self.baseTextureAlphaInterpolator = ZO_LerpInterpolator:New(1)
    self.zoomedInTextureAlphaInterpolator = ZO_LerpInterpolator:New(0)
    self.selectedTextureAlphaInterpolator = ZO_LerpInterpolator:New(0)

    self.ringNode = sceneGraph:CreateNode(string.format("constellationRing%d", self.anchorIndex))
    self.ringNode.ringAnchor = self

    self.rotatedNode = sceneGraph:CreateNode(string.format("constellationRingRotated%d", self.anchorIndex))
    self.rotatedNode:SetParent(self.ringNode)
    self.rotatedNode:SetRotation(-ZO_HALF_PI)
end

function ZO_ChampionConstellationRingAnchor:SetConstellation(constellation)
    local disciplineData = constellation:GetChampionDisciplineData()
    self.constellation = constellation
    self.ringNode.constellation = constellation

    local constellationComputedWidth, constellationComputedHeight = self.rotatedNode:ComputeSizeForDepth(
        ZO_CHAMPION_CONSTELLATION_WIDTH,
        ZO_CHAMPION_CONSTELLATION_HEIGHT,
        ZO_CHAMPION_CONSTELLATION_DEPTH,
        ZO_CHAMPION_REFERENCE_CAMERA_Z)

    local normalizeFactorX = 1 / ZO_CONSTELLATION_TEXTURE_SIZE_WIDTH
    local normalizeFactorY = 1 / ZO_CONSTELLATION_TEXTURE_SIZE_HEIGHT
    local centerX = ZO_CONSTELLATION_TEXTURE_SIZE_WIDTH * 0.5
    local centerY = ZO_CONSTELLATION_TEXTURE_SIZE_HEIGHT * 0.5
    local halfWidth = ZO_CONSTELLATION_TEXTURE_INNER_WIDTH * 0.5
    local halfHeight = ZO_CONSTELLATION_TEXTURE_INNER_HEIGHT * 0.5
    local left = (centerX - halfWidth) * normalizeFactorX
    local right =  (centerX + halfWidth) * normalizeFactorX
    local top =  (centerY - halfHeight) * normalizeFactorY
    local bottom =  (centerY + halfHeight) * normalizeFactorY

    self.rotatedNode:ClearControls()
    self.constellationZoomedOutTexture:SetTexture(disciplineData:GetBackgroundZoomedOutTexture())
    self.constellationZoomedOutTexture:SetDimensions(constellationComputedWidth, constellationComputedHeight)
    self.constellationZoomedOutTexture:SetTextureCoords(left, right, top, bottom)
    self.rotatedNode:AddTexture(self.constellationZoomedOutTexture, 0, 0, ZO_CHAMPION_CONSTELLATION_DEPTH)
    self.rotatedNode:SetControlAnchorPoint(self.constellationZoomedOutTexture, BOTTOM)

    self.constellationZoomedInTexture:SetTexture(disciplineData:GetBackgroundZoomedInTexture())
    self.constellationZoomedInTexture:SetDimensions(constellationComputedWidth, constellationComputedHeight)
    self.constellationZoomedInTexture:SetTextureCoords(left, right, top, bottom)
    self.rotatedNode:AddTexture(self.constellationZoomedInTexture, 0, 0, ZO_CHAMPION_CONSTELLATION_DEPTH)
    self.rotatedNode:SetControlAnchorPoint(self.constellationZoomedInTexture, BOTTOM)

    self.constellationSelectedTexture:SetTexture(disciplineData:GetBackgroundSelectedZoomedOutTexture())
    self.constellationSelectedTexture:SetDimensions(constellationComputedWidth, constellationComputedHeight)
    self.constellationSelectedTexture:SetTextureCoords(left, right, top, bottom)
    self.rotatedNode:AddTexture(self.constellationSelectedTexture, 0, 0, ZO_CHAMPION_CONSTELLATION_DEPTH)
    self.rotatedNode:SetControlAnchorPoint(self.constellationSelectedTexture, BOTTOM)
end

function ZO_ChampionConstellationRingAnchor:GetNode()
    return self.ringNode
end

function ZO_ChampionConstellationRingAnchor:AttachToConstellation()
    self.constellation:GetNode():SetParent(self.rotatedNode)
end

function ZO_ChampionConstellationRingAnchor:SetVisualInfo(visualInfo)
    self.baseTextureAlphaInterpolator:SetFluxParams(visualInfo.constellationBaseAlpha)
    self.zoomedInTextureAlphaInterpolator:SetFluxParams(visualInfo.constellationZoomedInBackgroundAlpha)
    self.selectedTextureAlphaInterpolator:SetFluxParams(visualInfo.constellationSelectedAlpha)
end

function ZO_ChampionConstellationRingAnchor:UpdateVisuals(timeSecs, frameDeltaSecs)
    local newConstellationAlpha = self.baseTextureAlphaInterpolator:Update(timeSecs, frameDeltaSecs)
    self.constellationZoomedOutTexture:SetAlpha(newConstellationAlpha)

    local newGlowAlpha = self.zoomedInTextureAlphaInterpolator:Update(timeSecs, frameDeltaSecs)
    self.constellationZoomedInTexture:SetAlpha(newGlowAlpha)

    local newSelectedAlpha = self.selectedTextureAlphaInterpolator:Update(timeSecs, frameDeltaSecs)
    self.constellationSelectedTexture:SetAlpha(newSelectedAlpha)
end

ZO_ChampionCluster = ZO_InitializingObject:Subclass()

function ZO_ChampionCluster:Initialize(constellation, sceneGraph, championClusterData, clusterIndex)
    self.constellation = constellation
    self.championClusterData = championClusterData

    if self:IsRootCluster() then
        self.node = constellation:GetNode()
    else
        --Create a node for this cluster
        local clusterNode = sceneGraph:CreateNode(string.format("constellation%dClusterNode%d", constellation:GetChampionDisciplineData():GetId(), clusterIndex))
        clusterNode:SetParent(constellation:GetNode())
        self.node = clusterNode

        --Acquire the control for the background
        self.backgroundTexture = CHAMPION_PERKS:AcquireClusterTexture()

        --The texture image here is cluster specific
        self.backgroundTexture:SetTexture(championClusterData:GetBackgroundTexture())

        --Calculate the dimensions for the background
        local clusterComputedWidth, clusterComputedHeight = self.node:ComputeSizeForDepth(ZO_CHAMPION_CLUSTER_WIDTH, ZO_CHAMPION_CLUSTER_HEIGHT, ZO_CHAMPION_CLUSTER_DEPTH, ZO_CHAMPION_REFERENCE_CAMERA_Z)
        self.backgroundTexture:SetDimensions(clusterComputedWidth, clusterComputedHeight)

        --Calculate the x and y coordinates of the background so that it is centered on the root star
        local nx, ny = championClusterData:GetRootChampionSkillData():GetPositionNoClusterOffset()
        local x, y = ZO_Champion_ConvertNormalizedCoordinatesToNodeOffset(nx, ny)
        self.node:AddTexture(self.backgroundTexture, x, y, ZO_CHAMPION_CLUSTER_DEPTH)
    end

    self.stars = {}
    self.starsByDataReference = {}
    self.links = {}
    self.linksByDataReference = {}

    self.hidden = true --  when hidden, all star controls are either hidden or released from the star control pool. it's not safe to try to reference a texture or link while hidden.
    self.active = false -- when active, the text and spinners for each star will be visible
end

local CHAMPION_LINE_THICKNESS = 5
function ZO_ChampionCluster:TryAddLinks(star, championSkillData)
    for _, linkedSkillData in championSkillData:LinkedChampionSkillDataIterator() do
        local linkedStar = self.starsByDataReference[linkedSkillData]
        -- there are two valid reasons for linkedStar to not yet exist:
        -- 1. the star still needs to be created. because links are bidirectional, we will create the link when that star is created.
        -- 2. the star is not part of the current cluster. In this case not creating a link is desired and handled automatically.
        if linkedStar and linkedStar:GetTexture() then
            local linkControl = CHAMPION_PERKS:AcquireLinkControl()
            linkControl.championSkillData1 = linkedSkillData
            linkControl.championSkillData2 = championSkillData
            self.node:AddLine(linkControl, linkedStar:GetTexture(), star:GetTexture(), self:IsRootCluster() and ZO_CHAMPION_CONSTELLATION_DEPTH or ZO_CHAMPION_CLUSTER_DEPTH)
            self.node:SetLineThickness(linkControl, CHAMPION_LINE_THICKNESS)
            table.insert(self.links, linkControl)

            if not self.linksByDataReference[linkedSkillData] then
                self.linksByDataReference[linkedSkillData] = {}
            end
            table.insert(self.linksByDataReference[linkedSkillData], linkControl)

            if not self.linksByDataReference[championSkillData] then
                self.linksByDataReference[championSkillData] = {}
            end
            table.insert(self.linksByDataReference[championSkillData], linkControl)
        end
    end
end

function ZO_ChampionCluster:EnsureControlsAreAcquired()
    if not self.controlsAcquired then
        self.controlsAcquired = true
        for _, star in ipairs(self.stars) do
            star:AcquireTexture()
            if star:IsClusterPortalStar() then
                self:TryAddLinks(star, star:GetRootChampionSkillData())
            else
                self:TryAddLinks(star, star:GetChampionSkillData())
            end
        end
    end
end

function ZO_ChampionCluster:ReleaseControls()
    if self.controlsAcquired and not self:IsRootCluster() then
        self.controlsAcquired = false
        for _, star in ipairs(self.stars) do
            star:ReleaseTexture()
        end
        for _, link in ipairs(self.links) do
            CHAMPION_PERKS:ReleaseLinkControl(link)
        end
        ZO_ClearNumericallyIndexedTable(self.links)
    end
end

function ZO_ChampionCluster:AddPortalToCluster(championClusterData)
    local star = ZO_ChampionClusterPortalStar:New(championClusterData, self.constellation, self)
    table.insert(self.stars, star)
    local rootChampionSkillData = championClusterData:GetRootChampionSkillData()
    self.starsByDataReference[rootChampionSkillData] = star
end

function ZO_ChampionCluster:AddSkillToCluster(championSkillData)
    local star = ZO_ChampionSkillStar:New(championSkillData, self.constellation, self)
    table.insert(self.stars, star)
    self.starsByDataReference[championSkillData] = star
end

function ZO_ChampionCluster:GetStarBySkillData(championSkillData)
    return self.starsByDataReference[championSkillData]
end

function ZO_ChampionCluster:GetChampionClusterData()
    return self.championClusterData
end

function ZO_ChampionCluster:IsRootCluster()
    return self.championClusterData == nil
end

function ZO_ChampionCluster:SetHiddenInternal(hidden)
    for _, star in ipairs(self.stars) do
        star:SetHidden(hidden)
    end
    for _, linkControl in ipairs(self.links) do
        self.node:SetControlHidden(linkControl, hidden)
    end
end

function ZO_ChampionCluster:SetHidden(hidden)
    if self.hidden ~= hidden then
        if not hidden then
            -- show the cluster
            self:EnsureControlsAreAcquired()
            self:SetHiddenInternal(false)
        else
            if self:IsRootCluster() then
                -- this is the root cluster, so it's likely we'll need to show
                -- it again in the near future. hide it instead of releasing
                -- controls
                self:SetHiddenInternal(true)
            else
                -- this is a sub-cluster, which will usually not be visible,
                -- and when it is visible, nothing else will be. Let's release its
                -- controls so they can be used by other sub-clusters
                self:ReleaseControls()
                if self.backgroundTexture then
                    self.backgroundTexture:SetAlpha(0)
                end
            end
        end
        self.hidden = hidden
    end
end

function ZO_ChampionCluster:IsActive()
    return self.active
end

function ZO_ChampionCluster:RefreshState()
        if self.hidden then
            -- will automatically refresh on showing
            return
        end

        for _, star in ipairs(self.stars) do
            star:RefreshState()
        end
end

function ZO_ChampionCluster:SetActive(active, instantly)
        if self.active ~= active then
            self.active = active
            for _, star in ipairs(self.stars) do
                star:SetActive(active, instantly)
            end
        end
end

do
    local LINK_UNLOCKED_ALPHA = 0.9
    local LINK_UNLOCKED_FOCUSED_ALPHA = 1.0
    local LINK_LOCKED_ALPHA = 0.3
    local LINK_LOCKED_FOCUSED_ALPHA = 0.6
    function ZO_ChampionCluster:UpdateLinkVisuals(alphaMultiplier)
        local selectedStar = CHAMPION_PERKS:GetSelectedStar()
        local selectedStarData = nil

        if selectedStar then
            if selectedStar:IsClusterPortalStar() then
                selectedStarData = selectedStar:GetRootChampionSkillData()
            else
                selectedStarData = selectedStar:GetChampionSkillData()
            end
        end

        if self.links then
            for _, linkControl in ipairs(self.links) do
                local isFocused = linkControl.championSkillData1 == selectedStarData or linkControl.championSkillData2 == selectedStarData
                local lockedAlpha = isFocused and LINK_LOCKED_FOCUSED_ALPHA or LINK_LOCKED_ALPHA
                local unlockedAlpha = isFocused and LINK_UNLOCKED_FOCUSED_ALPHA or LINK_UNLOCKED_ALPHA
                if linkControl.championSkillData1:WouldBeUnlockedNode() or linkControl.championSkillData2:WouldBeUnlockedNode() then
                    linkControl:SetAlpha(unlockedAlpha * alphaMultiplier)
                else
                    linkControl:SetAlpha(lockedAlpha * alphaMultiplier)
                end
            end
        end
    end
end

function ZO_ChampionCluster:UpdateVisuals(timeSecs, newStarAlpha, newLinkAlpha)
    if self.hidden then
        return
    end

    for _, star in ipairs(self.stars) do
        star:UpdateVisuals(timeSecs, newStarAlpha)
    end

    self:UpdateLinkVisuals(newLinkAlpha)

    if self.backgroundTexture then
        self.backgroundTexture:SetAlpha(newStarAlpha)
    end
end

function ZO_ChampionCluster:CollectStarsToAnimateForConfirm(starsToAnimateForConfirm)
    if self.hidden then
        return
    end
    for _, star in ipairs(self.stars) do
        local championSkillData
        if star:IsClusterPortalStar() then
            championSkillData = star:GetRootChampionSkillData()
        else
            championSkillData = star:GetChampionSkillData()
        end
        if championSkillData:HasUnsavedChanges() and championSkillData:WouldBeUnlockedNode() then
            table.insert(starsToAnimateForConfirm, star)
        end
    end
end

--For now, treat the position of the cluster as the position of the first star in the cluster
function ZO_ChampionCluster:GetWorldSpaceCoordinates()
    local firstStar = self.stars[1]
    --If there are no stars in this cluster, just return 0,0 as the position
    if firstStar then
        return firstStar:GetWorldSpaceCoordinates()
    else
        return 0, 0
    end
end

-----------------------
--Constellation
-----------------------

ZO_ChampionConstellation = ZO_InitializingObject:Subclass()

function ZO_ChampionConstellation:Initialize(championDisciplineData, sceneGraph)
    self.championDisciplineData = championDisciplineData

    local disciplineId = championDisciplineData:GetId()

    self.node = sceneGraph:CreateNode(string.format("constellationNode%d", disciplineId))

    --Stars
    self.clustersByClusterData = {}

    self.rootCluster = ZO_ChampionCluster:New(self)
    for clusterIndex, championClusterData in self.championDisciplineData:ChampionClusterDataIterator() do
        local cluster = ZO_ChampionCluster:New(self, sceneGraph, championClusterData, clusterIndex)
        self.clustersByClusterData[championClusterData] = cluster
        self.rootCluster:AddPortalToCluster(championClusterData)
    end

    for _, championSkillData in self.championDisciplineData:ChampionSkillDataIterator() do
        local cluster = self.clustersByClusterData[championSkillData:GetChampionClusterData()] or self.rootCluster
        cluster:AddSkillToCluster(championSkillData)
    end

    self.currentCluster = self.rootCluster
    self.currentCluster:SetHidden(false)
    for _, cluster in pairs(self.clustersByClusterData) do
        cluster:SetHidden(true)
    end

    self:SetActive(false)

    self.rootClusterStarAlphaInterpolator = ZO_LerpInterpolator:New(1)
    self.childClusterStarAlphaInterpolator = ZO_LerpInterpolator:New(1)
    self.linkAlphaInterpolator = ZO_LerpInterpolator:New(1)
    self:RegisterForEvents()
end

function ZO_ChampionConstellation:SetFirstRingAnchor(ringAnchor)
    self.ringAnchor1 = ringAnchor
    self.ringAnchor1:AttachToConstellation()
end

function ZO_ChampionConstellation:SetSecondRingAnchor(ringAnchor)
    self.ringAnchor2 = ringAnchor
end

function ZO_ChampionConstellation:RegisterForEvents()
    CHAMPION_DATA_MANAGER:RegisterCallback("ChampionSkillPendingPointsChanged", function(championSkillData)
        if self.selectedStar and self.selectedStar:IsSkillStar() and championSkillData == self.selectedStar:GetChampionSkillData() then
            self:RefreshSelectedStarTooltip()
        end
    end)
end

function ZO_ChampionConstellation:GetNode()
    return self.node
end

function ZO_ChampionConstellation:GetChampionDisciplineData()
    return self.championDisciplineData
end

function ZO_ChampionConstellation:RefreshState()
    self.currentCluster:RefreshState()
end

function ZO_ChampionConstellation:CollectStarsToAnimateForConfirm(starsToAnimateForConfirm)
    self.currentCluster:CollectStarsToAnimateForConfirm(starsToAnimateForConfirm)
end

-- visualInfo fields:
-- starAlpha: interpolator params, target is alpha value for visual skill stars
-- glowAlpha: interpolator params, target is alpha value for glow around constellation
-- constellationAlpha: interpolator params, target is constellation alpha as idle animation
-- mouseoverAlpha: interpolator params, target is alpha for entire constellation when a player mouses over it
-- interpolator params defined in ZO_LerpInterpolator:SetFluxParams()
function ZO_ChampionConstellation:SetVisualInfo(visualInfo)
    self.rootClusterStarAlphaInterpolator:SetFluxParams(visualInfo.starAlpha)
    self.childClusterStarAlphaInterpolator:SetFluxParams(visualInfo.childStarAlpha)
    self.linkAlphaInterpolator:SetFluxParams(visualInfo.linkAlpha)
end

function ZO_ChampionConstellation:UpdateVisuals(timeSecs, frameDeltaSecs)
    local newRootStarAlpha = self.rootClusterStarAlphaInterpolator:Update(timeSecs, frameDeltaSecs)
    local newClusterStarAlpha = self.childClusterStarAlphaInterpolator:Update(timeSecs, frameDeltaSecs)
    local linkAlpha = self.linkAlphaInterpolator:Update(timeSecs, frameDeltaSecs)
    self.rootCluster:UpdateVisuals(timeSecs, newRootStarAlpha, linkAlpha * newRootStarAlpha)
    local clusterLinkAlpha = linkAlpha * newClusterStarAlpha
    for _, childCluster in pairs(self.clustersByClusterData) do
        childCluster:UpdateVisuals(timeSecs, newClusterStarAlpha, clusterLinkAlpha)
    end
end

function ZO_ChampionConstellation:SetActive(active, instantly)
    if self.currentCluster:IsActive() ~= active then
        if not active then
            self:SelectStar(nil)
            self:ChangeCurrentClusterToRoot()
        end
        self.currentCluster:SetActive(active, instantly)
    end
end

function ZO_ChampionConstellation:GetCurrentCluster()
    return self.currentCluster
end

function ZO_ChampionConstellation:GetClusterByClusterData(clusterData)
    return self.clustersByClusterData[clusterData] or self.rootCluster
end

function ZO_ChampionConstellation:IsCurrentClusterRoot()
    return self.currentCluster == self.rootCluster
end

function ZO_ChampionConstellation:ChangeCurrentClusterToRoot()
   self:ChangeCurrentCluster(nil) 
end

function ZO_ChampionConstellation:ChangeCurrentCluster(newClusterData)
    local newCluster = self.clustersByClusterData[newClusterData] or self.rootCluster
    local oldCluster = self.currentCluster
    if oldCluster ~= newCluster then
        self:SelectStar(nil)

        newCluster:SetHidden(false)
        newCluster:SetActive(true)

        self.currentCluster = newCluster

        local INSTANT = true
        oldCluster:SetHidden(true)
        oldCluster:SetActive(false, INSTANT)

        CHAMPION_PERKS:RefreshStatusInfo()
    end
end

function ZO_ChampionConstellation:GetCurrentClusterFormattedName()
    if self:IsCurrentClusterRoot() then
        return self.championDisciplineData:GetFormattedName()
    else
        return self.currentCluster:GetChampionClusterData():GetFormattedName()
    end
end

function ZO_ChampionConstellation:RefreshSelectedStarTooltip()
    if self.selectedStar then
        self.selectedStar:ShowPlatformTooltip()
    end
end

function ZO_ChampionConstellation:SelectStar(newStar)
    local oldStar = self.selectedStar
    if oldStar ~= newStar then
        local championBar = CHAMPION_PERKS:GetChampionBar()
        local gamepadEditor = championBar:GetGamepadEditor()
        if oldStar then
            CHAMPION_PERKS:ReleaseSelectedStarIndicatorTexture()
            oldStar:ClearTooltip()
            if GetCursorContentType() == MOUSE_CONTENT_EMPTY and not gamepadEditor:IsFocused() then
                --Don't bother checking for non skill stars, as they aren't slottable in the first place
                if oldStar:IsSkillStar() then
                    local skillData = oldStar:GetChampionSkillData()
                    local slot = championBar:FindSlotMatchingChampionSkill(skillData)
                    if slot and skillData then
                        slot:HideDragAndDropCallout()
                    end
                end
            end
            oldStar:OnDeselected()
        end

        self.selectedStar = newStar

        if newStar then
            local selectedStarIndicatorTexture = CHAMPION_PERKS:AcquireSelectedStarIndicatorTexture()
            selectedStarIndicatorTexture:SetAnchor(CENTER, newStar:GetTexture(), CENTER, 0, 0)
            if not CHAMPION_PERKS:IsAnimating() then
                PlaySound(SOUNDS.CHAMPION_STAR_MOUSEOVER)
            end
            if GetCursorContentType() == MOUSE_CONTENT_EMPTY and not gamepadEditor:IsFocused() then
                --Don't bother checking for non skill stars, as they aren't slottable in the first place
                if newStar:IsSkillStar() then
                    local skillData = newStar:GetChampionSkillData()
                    local slot = championBar:FindSlotMatchingChampionSkill(skillData)
                    if slot and skillData then
                        slot:ShowDragAndDropCalloutForChampionSkillData(skillData)
                    end
                end
            end
            newStar:OnSelected()
        end

        self:RefreshSelectedStarTooltip()
        CHAMPION_PERKS:OnSelectedStarChanged(oldStar, newStar)
    end
end

function ZO_ChampionConstellation:GetSelectedStar()
    return self.selectedStar
end

function ZO_ChampionConstellation:GetFirstRingNode()
    return self.ringAnchor1:GetNode()
end

function ZO_ChampionConstellation:GetSecondRingNode()
    return self.ringAnchor2:GetNode()
end

function ZO_ChampionConstellation:GetNodeInSameHemisphereAsOtherNode(otherNode)
    local otherNodeAnchorIndex = otherNode.ringAnchor.anchorIndex
    if otherNodeAnchorIndex > CHAMPION_PERKS:GetNumConstellations() then
        return self:GetSecondRingNode()
    else
        return self:GetFirstRingNode()
    end
end

local CHAMPION_CYCLED_TO_SOUNDS =
{
    [CHAMPION_DISCIPLINE_TYPE_WORLD] = SOUNDS.CHAMPION_CYCLED_TO_THIEF,
    [CHAMPION_DISCIPLINE_TYPE_COMBAT] = SOUNDS.CHAMPION_CYCLED_TO_MAGE,
    [CHAMPION_DISCIPLINE_TYPE_CONDITIONING] = SOUNDS.CHAMPION_CYCLED_TO_WARRIOR,
}
function ZO_ChampionConstellation:PlayOnCycledToSound()
    local disciplineData = self:GetChampionDisciplineData()
    PlaySound(CHAMPION_CYCLED_TO_SOUNDS[disciplineData:GetType()])
end

local CHAMPION_SELECTED_SOUNDS =
{
    [CHAMPION_DISCIPLINE_TYPE_WORLD] = SOUNDS.CHAMPION_THIEF_MOUSEOVER,
    [CHAMPION_DISCIPLINE_TYPE_COMBAT] = SOUNDS.CHAMPION_MAGE_MOUSEOVER,
    [CHAMPION_DISCIPLINE_TYPE_CONDITIONING] = SOUNDS.CHAMPION_WARRIOR_MOUSEOVER,
}
function ZO_ChampionConstellation:PlayOnSelectedSound()
    local disciplineData = self:GetChampionDisciplineData()
    PlaySound(CHAMPION_SELECTED_SOUNDS[disciplineData:GetType()])
end
