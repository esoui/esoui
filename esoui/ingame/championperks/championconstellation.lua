--Constellation
-----------------------

ZO_ChampionConstellation = ZO_Object:Subclass()

function ZO_ChampionConstellation:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_ChampionConstellation:Initialize(sceneGraph, node, disciplineIndex, constellationsDepth)
    self.disciplineIndex = disciplineIndex

    self.name = zo_strformat(SI_CHAMPION_CONSTELLATION_NAME_FORMAT, GetChampionDisciplineName(disciplineIndex))
    self.numSkills = GetNumChampionDisciplineSkills(disciplineIndex)
    self.attributeType = GetChampionDisciplineAttribute(disciplineIndex)

    self.node = node
    self.rotatedNode = sceneGraph:CreateNode(string.format("constellationRotatedNode%d", disciplineIndex))
    self.rotatedNode:SetParent(node)
    self.rotatedNode:SetRotation(-0.5 * math.pi)

    --Constellation
    local canvasControl = sceneGraph:GetCanvasControl()
    local cLeft = ((disciplineIndex - 1) % 3) / 3
    local cRight = (((disciplineIndex - 1) % 3) + 1) / 3
    local cTop = zo_floor((disciplineIndex - 1) / 3) / 3
    local cBottom = (zo_floor((disciplineIndex - 1) / 3) + 1) / 3
    local constellationWidth, constellationHeight = self.rotatedNode:ComputeSizeForDepth(425, 425, constellationsDepth, ZO_CHAMPION_REFERENCE_CAMERA_Z)
    
    self.constellationTexture = CreateControlFromVirtual(canvasControl:GetName().."Constellation", canvasControl, "ZO_Constellation", disciplineIndex)
    self.constellationTexture:SetTextureCoords(cLeft, cRight, cTop, cBottom)
    self.constellationTexture:SetDimensions(constellationWidth, constellationHeight)
    self.rotatedNode:AddControl(self.constellationTexture, 0, 0, constellationsDepth)
    self.rotatedNode:SetControlAnchorPoint(self.constellationTexture, BOTTOM)

    self.constellationGlowTexture = CreateControlFromVirtual(canvasControl:GetName().."ConstellationGlow", canvasControl, "ZO_ConstellationGlow", disciplineIndex)
    self.constellationGlowTexture:SetTextureCoords(cLeft, cRight, cTop, cBottom)
    self.constellationGlowTexture:SetDimensions(constellationWidth, constellationHeight)
    self.rotatedNode:AddControl(self.constellationGlowTexture, 0, 0, constellationsDepth)
    self.rotatedNode:SetControlAnchorPoint(self.constellationGlowTexture, BOTTOM)

    self.constellationMouseoverTexture = CreateControlFromVirtual(canvasControl:GetName().."ConstellationMouseOver", canvasControl, "ZO_ConstellationMouseover", disciplineIndex)
    self.constellationMouseoverTexture:SetTextureCoords(cLeft, cRight, cTop, cBottom)
    self.constellationMouseoverTexture:SetDimensions(constellationWidth, constellationHeight)
    self.rotatedNode:AddControl(self.constellationMouseoverTexture, 0, 0, constellationsDepth - 0.01)
    self.rotatedNode:SetControlAnchorPoint(self.constellationMouseoverTexture, BOTTOM)

    --Refresh spent points first. Stars depend on knowing this total
    self:RefreshSpentPoints()

    --Stars
    self.stars = {}
    for i = 1, self.numSkills do
        local starTexture = CreateControlFromVirtual(canvasControl:GetName().."Constellation"..disciplineIndex.."Star", canvasControl, "ZO_ConstellationStar", i)
        local starDepth = constellationsDepth - 0.01

        self.stars[i] = ZO_ChampionStar:New(self, starTexture, self.rotatedNode, i, constellationWidth, constellationHeight, starDepth)
        starTexture.star = self.stars[i]
    end
    self:ClearChosen()

    --find the most central star and store it
    local minDistFromCenterSq = 1
    for _, star in ipairs(self.stars) do
        local nx, ny = star:GetNormalizedCoordinates()
        local dx, dy = nx - 0.5, ny - 0.5
        local dist = dx * dx + dy * dy
        if dist < minDistFromCenterSq then
            minDistFromCenterSq = dist
            self.closestStarToCenter = star
        end
    end

    self.glowAlphaInterpolator = ZO_LerpInterpolator:New(1)
    self.mouseoverScaleInterpolator = ZO_LerpInterpolator:New(1)
    self.mouseoverAlphaInterpolator = ZO_LerpInterpolator:New(0)
    self.constellationAlphaInterpolator = ZO_LerpInterpolator:New(1)
    self.starAlphaInterpolator = ZO_LerpInterpolator:New(1)
    
    node.constellation = self
end

function ZO_ChampionConstellation:GetDisciplineIndex()
    return self.disciplineIndex
end

function ZO_ChampionConstellation:GetAttributeType()
    return self.attributeType
end

function ZO_ChampionConstellation:GetName()
    return self.name
end

function ZO_ChampionConstellation:GetDescription()
    return GetChampionDisciplineDescription(self.disciplineIndex)
end

function ZO_ChampionConstellation:GetNumSpentPoints()
    if CHAMPION_PERKS:IsInRespecMode() then
        return 0
    else
        return self:GetNumCommittedSpentPoints()
    end
end

function ZO_ChampionConstellation:GetNumCommittedSpentPoints()
    return self.spentPoints
end

function ZO_ChampionConstellation:GetNumPendingPoints()
    local numPendingPoints = 0
    for i, star in ipairs(self.stars) do
        numPendingPoints = numPendingPoints + star:GetNumPendingPoints()
    end
    return numPendingPoints
end

function ZO_ChampionConstellation:GetNumPointsThatWillBeSpent()
    return self:GetNumSpentPoints() + self:GetNumPendingPoints()
end

function ZO_ChampionConstellation:ResetPendingPoints()
    for i, star in ipairs(self.stars) do
        star:ResetPendingPoints()
    end
end

function ZO_ChampionConstellation:RefreshSpentPoints()
    self.spentPoints = 0
    for i = 1, self.numSkills do
        self.spentPoints = self.spentPoints + GetNumPointsSpentOnChampionSkill(self.disciplineIndex, i)
    end
end

function ZO_ChampionConstellation:RefreshAllStarStates()
    for i = 1, #self.stars do
        self.stars[i]:RefreshState()
    end
end

function ZO_ChampionConstellation:RefreshAllStarMinMax()
    for i = 1, #self.stars do
        self.stars[i]:RefreshPointsMinMax()
    end
end

function ZO_ChampionConstellation:RefreshAllStarText()
    for i = 1, #self.stars do
        self.stars[i]:RefreshText()
    end
end

function ZO_ChampionConstellation:HasUnsavedChanges()
    for i, star in ipairs(self.stars) do
        if star:HasUnsavedChanges() then
            return true
        end
    end
    return false
end

function ZO_ChampionConstellation:SetVisualInfo(visualInfo)
    self.glowAlphaInterpolator:SetParams(visualInfo.glowAlpha)
    self.mouseoverScaleInterpolator:SetParams(visualInfo.mouseoverScale)
    self.mouseoverAlphaInterpolator:SetParams(visualInfo.mouseoverAlpha)
    self.constellationAlphaInterpolator:SetParams(visualInfo.constellationAlpha)
    self.starAlphaInterpolator:SetParams(visualInfo.starAlpha)
end

function ZO_ChampionConstellation:UpdateVisuals(timeSecs, frameDeltaSecs)
    local newGlowAlpha = self.glowAlphaInterpolator:Update(timeSecs + self.disciplineIndex, frameDeltaSecs)
    self.constellationGlowTexture:SetAlpha(newGlowAlpha)

    local newMouseoverScale = self.mouseoverScaleInterpolator:Update(timeSecs, frameDeltaSecs)
    self.rotatedNode:SetControlScale(self.constellationMouseoverTexture, newMouseoverScale)

    local newMouseoverAlpha = self.mouseoverAlphaInterpolator:Update(timeSecs, frameDeltaSecs)
    self.constellationMouseoverTexture:SetAlpha(newMouseoverAlpha)

    local newConstellationAlpha = self.constellationAlphaInterpolator:Update(timeSecs, frameDeltaSecs)
    self.constellationTexture:SetAlpha(newConstellationAlpha)

    local newStarAlpha = self.starAlphaInterpolator:Update(timeSecs, frameDeltaSecs)
    local hasAnyUnspentPoints = CHAMPION_PERKS:HasAnySpendableUnspentPoints(self.attributeType)

    for i, star in ipairs(self.stars) do
        star:UpdateVisuals(timeSecs, frameDeltaSecs)

        local starTexture = star:GetTexture()
        local showAtFullAlpha = star:WouldBePurchased()
        if not showAtFullAlpha then
            showAtFullAlpha = not hasAnyUnspentPoints and star:IsPurchased()
        end
        starTexture:SetAlpha(showAtFullAlpha and 1 or newStarAlpha)
    end
end

function ZO_ChampionConstellation:MakeChosen()
    for _, star in ipairs(self.stars) do
        star:SetEnabled(true)
    end

     if IsInGamepadPreferredMode() then
        self:SelectStar(self.closestStarToCenter)
        DIRECTIONAL_INPUT:Activate(self, self.constellationTexture)
    end
end

function ZO_ChampionConstellation:ClearChosen(instantly)
    self:SelectStar(nil)
    for _, star in ipairs(self.stars) do
        star:SetEnabled(false, instantly)
    end
    DIRECTIONAL_INPUT:Deactivate(self)
end

function ZO_ChampionConstellation:UpdateDirectionalInput()
    if self.selectedStar then
        local x, y = DIRECTIONAL_INPUT:GetXY(ZO_DI_LEFT_STICK)
        if zo_abs(x) > 0.3 or zo_abs(y) > 0.3 then
            if not self.stickEngaged then
                local minScore
                local closestStar
                local selectedNX, selectedNY = self.selectedStar:GetNormalizedCoordinates()
                local stickAngle = math.atan2(y, x)

                for i = 1, #self.stars do
                    local star = self.stars[i]
                    if star ~= self.selectedStar then
                        local nx, ny = star:GetNormalizedCoordinates()
                        local dx = nx - selectedNX
                        local dy = ny - selectedNY
                        local currentAngle = math.atan2(-dy, dx)
                        local angleDist = zo_arcSize(currentAngle, stickAngle)
                        local sqDist = dx * dx + dy * dy
                        local score = angleDist + math.sqrt(sqDist) * 3

                        if angleDist < math.pi * 0.25 then
                            if not closestStar or score < minScore then
                                minScore = score
                                closestStar = star
                            end
                        end                        
                    end
                end

                if closestStar then
                    self.stickEngaged = true
                    self:SelectStar(closestStar)
                end
            end
        else
            self.stickEngaged = false
        end
    end
end

function ZO_ChampionConstellation:OnStarPendingPointsChanged(star)
    if star == self.selectedStar then
        self:RefreshSelectedStarTooltip()
    end
end

function ZO_ChampionConstellation:RefreshSelectedStarTooltip()
    if self.selectedStar then
        local objectUsedForGrowth
        -- The unlock passives growth is based on points spent in the whole constellation,
        -- everything else is based on a single star.
        if self.selectedStar:CanSpendPoints() then
            objectUsedForGrowth = self.selectedStar
        else
            objectUsedForGrowth = self
        end

        local pendingPoints = objectUsedForGrowth:GetNumPendingPoints()
        if CHAMPION_PERKS:IsInRespecMode() then
            pendingPoints = pendingPoints - objectUsedForGrowth:GetNumCommittedSpentPoints()
        end

        if IsInGamepadPreferredMode() then
            CHAMPION_PERKS:LayoutRightTooltipChampionSkillAbility(self.disciplineIndex, self.selectedStar.skillIndex, pendingPoints)
        else
            InitializeTooltip(SkillTooltip, self.selectedStar:GetTexture(), LEFT, 150, 0, CENTER)
            SkillTooltip:SetChampionSkillAbility(self.disciplineIndex, self.selectedStar.skillIndex, pendingPoints)
        end
    end
end

function ZO_ChampionConstellation:SelectStar(star)
    if star ~= self.selectedStar then
        if self.selectedStar then
            ClearTooltip(SkillTooltip)
            --Only clear the gamepad tooltip when we zoom out so it isn't fading in and out when rotating constellations
            self.selectedStar:StopChangingPoints()
            CHAMPION_PERKS:ReleaseSelectedStarIndicatorTexture()
            if IsInGamepadPreferredMode() then
                self.selectedStar:ApplyGamepadButtonTemplatesToTextControl()
            end
        end

        self.selectedStar = star

        if star then
            local selectedStarIndicatorTexture = CHAMPION_PERKS:AcquireSelectedStarIndicatorTexture()
            selectedStarIndicatorTexture:SetAnchor(CENTER, star:GetTexture(), CENTER, 0, 0)
            if IsInGamepadPreferredMode() then
                star:ApplyGamepadTriggerButtonTemplatesToTextControl()
            end
            if not CHAMPION_PERKS:IsAnimating() then
                PlaySound(SOUNDS.CHAMPION_STAR_MOUSEOVER)
            end
        end

        self:RefreshSelectedStarTooltip()
        CHAMPION_PERKS:OnSelectedStarChanged()
    end
end

function ZO_ChampionConstellation:GetSelectedStar()
    return self.selectedStar
end

function ZO_ChampionConstellation:GetStars()
    return self.stars
end
