ZO_IMECandidates = ZO_Object:Subclass()

ZO_IME_CANDIDATES_MIN_WIDTH = 200

function ZO_IMECandidates:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_IMECandidates:Initialize(control)
    self.control = control
    self.pane = control:GetNamedChild("Pane")
    local scroll = self.pane:GetNamedChild("Scroll")
    self.scrollChild = scroll:GetNamedChild("Child")
    self.highlightBackdrop = self.scrollChild:GetNamedChild("Highlight")
    self.moreCandidatesRow = self.scrollChild:GetNamedChild("MoreCandidates")

    self.height = 0
    self.maxPageSize = 0

    local windowManager = GetWindowManager()
    windowManager:SetHandler("OnIMECandidateListUpdated", function(...) self:OnIMECandidateListUpdated(...) end)

    self.candidateRowPool = ZO_ControlPool:New("ZO_IMECandidateRow", self.scrollChild)
end

function ZO_IMECandidates:OnIMECandidateListUpdated(editControl)
    local windowManager = GetWindowManager()
    if windowManager:IsUsingCustomCandidateList() then
        self:RefreshListContents()
        self:RefreshListAnchor(editControl)
    end
end

function ZO_IMECandidates:RefreshListAnchor(editControl)
    local leftControlSpace, topControlSpace, rightControlSpace, bottomControlSpace = editControl:GetIMECompositionExclusionArea()

    local bottomUISpace = editControl:GetTop() + bottomControlSpace
    local remainingBottomUISpace = GuiRoot:GetHeight() - bottomUISpace - ZO_DEFAULT_BACKDROP_ANCHOR_OFFSET
    self.control:ClearAnchors()
    if remainingBottomUISpace > self.height then
        self.control:SetAnchor(TOPLEFT, editControl, TOPLEFT, leftControlSpace, bottomControlSpace + ZO_DEFAULT_BACKDROP_ANCHOR_OFFSET)
    else
        self.control:SetAnchor(BOTTOMLEFT, editControl, TOPLEFT, leftControlSpace, topControlSpace - ZO_DEFAULT_BACKDROP_ANCHOR_OFFSET)
    end
end

function ZO_IMECandidates:RefreshListContents()
    self.candidateRowPool:ReleaseAllObjects()
    self.height = 0
    self.highlightBackdrop:SetHidden(true)

    local windowManager = GetWindowManager()
    local numCandidates = windowManager:GetNumIMECandidates()
   
    if numCandidates > 0 then
        self.control:SetHidden(false)

        --Init this to ZO_IME_CANDIDATES_MIN_WIDTH so we have at least that much space in the final control
        local maxWidth = ZO_IME_CANDIDATES_MIN_WIDTH
    
        local selectedIndex, pageStartIndex, pageSize = windowManager:GetIMECandidatePageInfo()
        local inCandidateWindow = windowManager:IsChoosingIMECandidate()
        
        --We usually get a number of pages with a fixed page size and on the last page the page size becomes smaller if we don't have enough to fill it.
        --Instead of shrinking the view on the last page we lay it out to be as big as the other, just with empty space filling the rest.
        if pageSize > self.maxPageSize then
            self.maxPageSize = pageSize
        end

        local previousRow
        local candidateTextHeight
        local getMoreCandidatesEntryIndex

        for i = 1, numCandidates do
            local candidate = windowManager:GetIMECandidate(i)
            
            --An entry of " " is included in the list where there should be an arrow indicating more results below
            if candidate == " " then
                getMoreCandidatesEntryIndex = i
            end

            local candidateRow = self.candidateRowPool:AcquireObject()
            local textLabel = candidateRow:GetNamedChild("Text")
            textLabel:SetText(candidate)

            candidateRow:ClearAnchors()
            if previousRow then
                candidateRow:SetAnchor(TOPLEFT, previousRow, BOTTOMLEFT, 0, 0)
            else
                candidateRow:SetAnchor(TOPLEFT, nil, TOPLEFT, 0, 0)
            end
            local textWidth, textHeight = textLabel:GetTextDimensions() 
            if not candidateTextHeight then
                candidateTextHeight = textHeight
            end
            candidateRow:SetHeight(textHeight)

            if i == selectedIndex then
                --Only apply the highlight if the candidate list is active
                if inCandidateWindow then
                    self.highlightBackdrop:SetHidden(false)
                    self.highlightBackdrop:ClearAnchors()
                    self.highlightBackdrop:SetAnchorFill(candidateRow)
                end
            end
            
            maxWidth = zo_max(maxWidth, textWidth)            
            previousRow = candidateRow
        end
        
        --Make all the rows the same width so the highlight is uniform across all of them
        for _, candidateRow in pairs(self.candidateRowPool:GetActiveObjects()) do
            candidateRow:SetWidth(maxWidth)
        end
                
        if getMoreCandidatesEntryIndex then
            self.moreCandidatesRow:SetHidden(false)
            self.moreCandidatesRow:SetDimensions(maxWidth, candidateTextHeight)
            self.moreCandidatesRow:ClearAnchors()
            self.moreCandidatesRow:SetAnchor(TOPLEFT, nil, TOPLEFT, 0, candidateTextHeight * (getMoreCandidatesEntryIndex - 1))
        else
            self.moreCandidatesRow:SetHidden(true)
        end

        local pageStartOffset
        --How many entries to show additionally on a scrollable edge. If you can scroll up and down and this value was 1 you'd see one additional entry above the page start and one after the page end
        local NUM_EXTRA_ENTRIES_ON_SCROLLABLE_EDGE = 0.65

        self.scrollChild:SetResizeToFitPadding(0, 0)
        if numCandidates <= self.maxPageSize then
            --if we don't have enough candidates to fill even one page it doesn't scroll so just start at the top
            pageStartOffset = 0
            self.height = self.maxPageSize * candidateTextHeight
        else
            --if we have enough to scroll figure out in which directions we can scroll and add the proper space
            local numExtraEntries
            if pageStartIndex == 1 then
                --Page 1, can only scroll down
                numExtraEntries = NUM_EXTRA_ENTRIES_ON_SCROLLABLE_EDGE
                pageStartOffset = 0 
            elseif (pageStartIndex + pageSize - 1) == numCandidates then
                --Last page, can only scroll up
                numExtraEntries = NUM_EXTRA_ENTRIES_ON_SCROLLABLE_EDGE
                pageStartOffset = -NUM_EXTRA_ENTRIES_ON_SCROLLABLE_EDGE
            else
                --Middle page, can scroll up or down
                numExtraEntries = NUM_EXTRA_ENTRIES_ON_SCROLLABLE_EDGE * 2
                pageStartOffset = -NUM_EXTRA_ENTRIES_ON_SCROLLABLE_EDGE
            end
            self.height = (self.maxPageSize + numExtraEntries) * candidateTextHeight
            local numRowsOnLastPage = numCandidates % self.maxPageSize
            if numRowsOnLastPage > 0 then
                --Pad out the scroll child to fill a full page
                self.scrollChild:SetResizeToFitPadding(0, candidateTextHeight * (self.maxPageSize - numRowsOnLastPage))
            end
        end
                
        local SCROLL_BAR_WIDTH = 16
        self.control:SetDimensions(maxWidth + SCROLL_BAR_WIDTH, self.height)
        
        ZO_Scroll_SetMaxFadeDistance(self.pane, candidateTextHeight * NUM_EXTRA_ENTRIES_ON_SCROLLABLE_EDGE)
        --Scroll to put the page top in view taking into account one line of scroll fade
        ZO_Scroll_ScrollAbsolute(self.pane, (pageStartIndex - 1 + pageStartOffset) * candidateTextHeight)
    else
        self.maxPageSize = 0
        self.height = 0
        self.control:SetHidden(true)
    end
end

function ZO_IMECandidates_TopLevel_OnInitialized(self)
    IME_CANDIDATES = ZO_IMECandidates:New(self)
end