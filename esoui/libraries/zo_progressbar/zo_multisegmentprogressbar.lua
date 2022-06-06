----------------------------------
-- ZO Multi Segment Progress Bar
----------------------------------

ZO_PROGRESS_BAR_GROWTH_DIRECTION_LEFT_TO_RIGHT = 1
ZO_PROGRESS_BAR_GROWTH_DIRECTION_RIGHT_TO_LEFT = 2
ZO_PROGRESS_BAR_GROWTH_DIRECTION_TOP_TO_BOTTOM = 3
ZO_PROGRESS_BAR_GROWTH_DIRECTION_BOTTOM_TO_TOP = 4

ZO_MultiSegmentProgressBar = ZO_InitializingObject:Subclass()

function ZO_MultiSegmentProgressBar:Initialize(control, templateName, setupFunction)
    self.control = control

    self.segmentTemplate = templateName
    self.textureControls = {}
    self.currentGrowthDirectionPosition = 0
    self.setupFunction = setupFunction

    self.isUniformSegmentation = false
    self.maxNumSegments = 1
    self.progressBarGrowthDirection = ZO_PROGRESS_BAR_GROWTH_DIRECTION_LEFT_TO_RIGHT
    self.previousSegmentUnderneathOverlap = 0

    -- This ensures proper draw ordering using accumulators
    local function FactorySetup(segment)
        segment:SetAutoRectClipChildren(true)
    end

    self.segmentControlPool = ZO_ControlPool:New(self.segmentTemplate, self.control, "Segment")
    self.segmentControlPool:SetCustomFactoryBehavior(FactorySetup)
end

function ZO_MultiSegmentProgressBar:SetSegmentationUniformity(isUniform)
    self.isUniformSegmentation = isUniform
end

function ZO_MultiSegmentProgressBar:SetMaxSegments(numSegments)
    if numSegments > 0 then
        self.maxNumSegments = numSegments
    end
end

function ZO_MultiSegmentProgressBar:SetSegmentTemplate(templateName)
    self:Clear()
    self.segmentTemplate = templateName
    self.segmentControlPool.templateName = templateName
end

function ZO_MultiSegmentProgressBar:SetProgressBarGrowthDirection(growthDirection)
    self.progressBarGrowthDirection = growthDirection
end

function ZO_MultiSegmentProgressBar:SetPreviousSegmentUnderneathOverlap(overlapValue)
    self.previousSegmentUnderneathOverlap = overlapValue
end

function ZO_MultiSegmentProgressBar:AddSegment(data)
    if #self.textureControls < self.maxNumSegments then
        local segmentIndex = #self.textureControls + 1
        local previousSegmentUnderneathOverlap = segmentIndex > 1 and self.previousSegmentUnderneathOverlap or 0

        if self.progressBarGrowthDirection == ZO_PROGRESS_BAR_GROWTH_DIRECTION_LEFT_TO_RIGHT or self.progressBarGrowthDirection == ZO_PROGRESS_BAR_GROWTH_DIRECTION_RIGHT_TO_LEFT then
            local currentX = self.currentGrowthDirectionPosition + previousSegmentUnderneathOverlap
            local segmentWidth = data and data.width or 0
            if self.isUniformSegmentation then
                segmentWidth = self.control:GetWidth() / self.maxNumSegments
            end
            local segmentControl = self.segmentControlPool:AcquireObject()
            ApplyTemplateToControl(segmentControl, self.segmentTemplate)
            segmentControl:SetWidth(segmentWidth - previousSegmentUnderneathOverlap)
            segmentControl:SetDrawLevel(self.maxNumSegments + 2 - segmentIndex)

            local anchorPoint = self.progressBarGrowthDirection == ZO_PROGRESS_BAR_GROWTH_DIRECTION_LEFT_TO_RIGHT and LEFT or RIGHT
            segmentControl:ClearAnchors()
            segmentControl:SetAnchor(anchorPoint, self.control, anchorPoint, currentX, 0)

            table.insert(self.textureControls, segmentControl)

            if self.setupFunction then
                self.setupFunction(segmentControl, segmentIndex)
            end

            self.currentGrowthDirectionPosition = self.currentGrowthDirectionPosition + segmentWidth
        elseif self.progressBarGrowthDirection == ZO_PROGRESS_BAR_GROWTH_DIRECTION_TOP_TO_BOTTOM or self.progressBarGrowthDirection == ZO_PROGRESS_BAR_GROWTH_DIRECTION_BOTTOM_TO_TOP then
            local currentY = self.currentGrowthDirectionPosition + previousSegmentUnderneathOverlap
            local segmentHeight = data.height
            if self.isUniformSegmentation then
                segmentHeight = self.control:GetHeight() / self.maxNumSegments
            end
            local segmentControl = self.segmentControlPool:AcquireObject()
            ApplyTemplateToControl(segmentControl, self.segmentTemplate)
            segmentControl:SetHeight(segmentHeight - previousSegmentUnderneathOverlap)

            local anchorPoint = self.progressBarGrowthDirection == ZO_PROGRESS_BAR_GROWTH_DIRECTION_TOP_TO_BOTTOM and TOP or BOTTOM
            segmentControl:ClearAnchors()
            segmentControl:SetAnchor(anchorPoint, self.control, anchorPoint, 0, currentY)

            table.insert(self.textureControls, segmentControl)
            self.currentGrowthDirectionPosition = self.currentGrowthDirectionPosition + segmentHeight
        end
    end
end

function ZO_MultiSegmentProgressBar:Clear()
    self.currentGrowthDirectionPosition = 0
    self.segmentControlPool:ReleaseAllObjects()
    self.textureControls = {}
end