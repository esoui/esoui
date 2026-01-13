-----------------
-- ZO_PageNavigationIndicator
-----------------

-- TODO: Consider supporting disabled indicators

ZO_PageNavigationIndicator = ZO_InitializingObject:Subclass()

function ZO_PageNavigationIndicator:Initialize(control, parent)
    self.control = control
    control.owner = self
    self.parent = parent

    self.numberLabel = self.control:GetNamedChild("Number")
    self.iconControl = self.control:GetNamedChild("Icon")
end

function ZO_PageNavigationIndicator:GetControl()
    return self.control
end

function ZO_PageNavigationIndicator:GetData()
    return self.data
end

-- indicatorData - a table of various options to modify the indicator
--  icon = texture to show instead of page number
--  color = the color of the indicator text when not selected
--  selectedColor = the color of the indicator text when selected
-- TODO: support options like selectedIcon, mouseOverIcon, iconColor, iconSelectedColor, etc.
function ZO_PageNavigationIndicator:SetData(pageNumber, indicatorData)
    self.pageNumber = pageNumber
    self.data = indicatorData or {}
    self:Refresh()
end

function ZO_PageNavigationIndicator:GetDefaultFont()
    return self.parent:GetDefaultIndicatorFont()
end

function ZO_PageNavigationIndicator:IsHidden()
    return self.control:IsHidden()
end

function ZO_PageNavigationIndicator:SetHidden(isHidden)
    self.control:SetHidden(isHidden)
end

function ZO_PageNavigationIndicator:GetPageNumber()
    return self.pageNumber
end

function ZO_PageNavigationIndicator:GetParent()
    return self.parent
end

function ZO_PageNavigationIndicator:IsSelected()
    return self.pageNumber == self.parent:GetCurrentPage()
end

function ZO_PageNavigationIndicator:Select()
    self.parent:SelectPage(self.pageNumber)
end

function ZO_PageNavigationIndicator:Refresh()
    local data = self.data
    local color
    if self:IsSelected() then
        color = data.selectedColor or ZO_SELECTED_TEXT
    else
        color = data.color or ZO_NORMAL_TEXT
    end

    local hasIcon = data.icon ~= nil
    self.iconControl:SetHidden(not hasIcon)
    self.numberLabel:SetHidden(hasIcon)

    if hasIcon then
        self.iconControl:SetTexture(data.icon)
        -- TODO use optional selected textures or a specific icon color
        self.iconControl:SetColor(color:UnpackRGBA())
    else
        self.numberLabel:SetFont(data.font or self:GetDefaultFont())
        self.numberLabel:SetColor(color:UnpackRGBA())
        self.numberLabel:SetText(self.pageNumber)
    end
end

function ZO_PageNavigationIndicator:Reset()
    self:SetHidden(true)

    self.data = nil
    self.pageNumber = nil
    self.iconControl:SetTexture(nil)
    self.numberLabel:SetText("")
end

function ZO_PageNavigationIndicator:OnClicked()
    self:Select()
end

-----------------
-- ZO_PageNavigation
-----------------

ZO_PAGE_NAVIGATION_NEXT_PAGE = 1
ZO_PAGE_NAVIGATION_PREVIOUS_PAGE = -1

ZO_PageNavigation = ZO_InitializingCallbackObject:Subclass()

function ZO_PageNavigation:Initialize(control)
    self.control = control
    control.owner = self

    self.nextPageControl = self.control:GetNamedChild("NextPage")
    self.nextPageControl.owner = self
    self.previousPageControl = self.control:GetNamedChild("PreviousPage")
    self.previousPageControl.owner = self

    local function CreatePageIndicator(objectPool)
        local pageIndicatorControl = ZO_ObjectPool_CreateNamedControl("$(parent)Indicator", "ZO_PageNavigationIndicator", objectPool, control)
        return ZO_PageNavigationIndicator:New(pageIndicatorControl, self)
    end

    self.pageIndicatorPool = ZO_ObjectPool:New(CreatePageIndicator, ZO_ObjectPool_DefaultResetObject)

    self.pageIndicatorPool:SetCustomAcquireBehavior(function(pageIndicator)
        pageIndicator:SetHidden(false)
    end)

    self.allowWrapping = false
    self.startingPageNumber = 1
    self.currentPage = nil
    self.indicatorInfos = {}
    self.indicatorSpacing = 5
    self.pageChangeSound = SOUNDS.DEFAULT_CLICK -- TODO Tamriel Tomes
    self.pageIndicators = {}
    self.hidePageIndicators = false
    self.showTooltip = true
end

function ZO_PageNavigation:GetAllowWrapping()
    return self.allowWrapping
end

function ZO_PageNavigation:SetAllowWrapping(allowWrapping)
    self.allowWrapping = allowWrapping
end

function ZO_PageNavigation:GetIndicatorSpacing()
    return self.indicatorSpacing
end

function ZO_PageNavigation:SetIndicatorSpacing(spacing)
    self.indicatorSpacing = spacing
end

function ZO_PageNavigation:GetDefaultIndicatorFont(font)
    return self.defaultFont
end

function ZO_PageNavigation:SetDefaultIndicatorFont(font)
    if font == self.defaultFont then
        return
    end

    self.defaultFont = font
    self:RefreshPageIndicators()
end

function ZO_PageNavigation:SetHidePageIndicators(hide)
    if self.hidePageIndicators == hide then
        return
    end

    self.hidePageIndicators = hide
    self.pageIndicatorPool:ReleaseAllObjects()
    self:Commit()
end

function ZO_PageNavigation:GetShowTooltips()
    return self.showTooltip
end

function ZO_PageNavigation:SetShowTooltips(show)
    self.showTooltip = show
end

function ZO_PageNavigation:SetStartingPageNumber(pageNumber)
    if not internalassert(#self.indicatorInfos == 0, "ZO_PageNavigation must be cleared before a min page number can be set") then
        return
    end

    self.startingPageNumber = pageNumber
end

function ZO_PageNavigation:RefreshPageIndicators()
    if not internalassert(self.defaultFont, "ZO_PageNavigation requires a platform-specific DefaultIndicatorFont.") then
        return
    end

    for _, pageIndicator in pairs(self.pageIndicators) do
        pageIndicator:Refresh()
    end
end

function ZO_PageNavigation:Clear()
    self.currentPage = nil
    self.numPages = nil
    self.pageIndicatorPool:ReleaseAllObjects()
    ZO_ClearTable(self.pageIndicators)
    ZO_ClearNumericallyIndexedTable(self.indicatorInfos)
    self:UpdateNavigationButtons()
end

-- Adds a single page.
function ZO_PageNavigation:AddPage(indicatorInfo)
    if not indicatorInfo then
        indicatorInfo = {}
    end

    table.insert(self.indicatorInfos, indicatorInfo)
end

-- Adds 'numPages' additional pages.
-- Note that the pages that are added will share the same indicatorInfo instance.
function ZO_PageNavigation:AddPages(numPages, indicatorInfo)
    if not indicatorInfo then
        indicatorInfo = {}
    end

    for page = 1, numPages do
        self:AddPage(indicatorInfo)
    end
end

function ZO_PageNavigation:Commit(selectedPage)
    self.numPages = #self.indicatorInfos

    local previousControl = nil
    local pageNumber = self.startingPageNumber
    if not self.hidePageIndicators then
        for indicatorIndex, indicatorInfo in ipairs(self.indicatorInfos) do
            local pageIndicator = self.pageIndicatorPool:AcquireObject()
            pageIndicator:SetData(pageNumber, indicatorInfo)
            self.pageIndicators[pageNumber] = pageIndicator

            local pageIndicatorControl = pageIndicator:GetControl()
            if pageNumber == self.startingPageNumber then
                pageIndicatorControl:SetAnchor(TOPLEFT)
            else
                pageIndicatorControl:SetAnchor(TOPLEFT, previousControl, TOPRIGHT, self.indicatorSpacing, 0)
            end

            previousControl = pageIndicatorControl
            pageNumber = pageNumber + 1
        end
    end

    local pageToSelect = selectedPage or self.startingPageNumber
    local SUPPRESS_SOUND = true
    self:SelectPage(pageToSelect, SUPPRESS_SOUND)
end

function ZO_PageNavigation:UpdateNavigationButtons()
    local numPages = self:GetNumPages()
    local showNavigation = numPages and numPages > 1
    self.nextPageControl:SetHidden(not showNavigation)
    self.previousPageControl:SetHidden(not showNavigation)

    if showNavigation then
        local currentPage = self:GetCurrentPage()
        local canMoveNext = false
        local canMovePrevious = false
        if currentPage then
            canMoveNext = self.allowWrapping or currentPage < numPages
            canMovePrevious = self.allowWrapping or currentPage > self.startingPageNumber
        end

        self.nextPageControl:SetEnabled(canMoveNext)
        self.previousPageControl:SetEnabled(canMovePrevious)
    end
end

function ZO_PageNavigation:IsHidden()
    return self.control:IsHidden()
end

function ZO_PageNavigation:SetHidden(isHidden)
    self.control:SetHidden(isHidden)
end

function ZO_PageNavigation:IsVisible()
    return not self:IsHidden()
end

function ZO_PageNavigation:GetNumPages()
    return self.numPages or 0
end

function ZO_PageNavigation:GetHighestPageNumber()
    return self:GetNumPages() + self.startingPageNumber - 1
end

function ZO_PageNavigation:GetPageChangeSound()
    return self.pageChangeSound
end

function ZO_PageNavigation:SetPageChangeSound(sound)
    self.pageChangeSound = sound
end

function ZO_PageNavigation:GetCurrentPage()
    return self.currentPage
end

function ZO_PageNavigation:ChangePage(direction)
    local currentPage = self:GetCurrentPage()
    local pageToSelect = currentPage + direction
    if self.allowWrapping then
        local highestPageNumber = self:GetHighestPageNumber()
        if pageToSelect < self.startingPageNumber then
            pageToSelect = highestPageNumber
        elseif pageToSelect > highestPageNumber then
            pageToSelect = self.startingPageNumber
        end
    end

    self:SelectPage(pageToSelect)
end

function ZO_PageNavigation:SelectPage(pageNumber, suppressSound)
    if pageNumber < self.startingPageNumber or pageNumber > self:GetHighestPageNumber() then
        return
    end

    if pageNumber == self:GetCurrentPage() then
        return
    end

    self.currentPage = pageNumber
    self:RefreshPageIndicators()
    self:UpdateNavigationButtons()
    if not suppressSound then
        PlaySound(self.pageChangeSound)
    end

    self:FireCallbacks("PageChanged", pageNumber)
end

function ZO_PageNavigation:GetPreviousPageKeybindDescriptor()
    if self.previousPageControl.GetKeybindButtonDescriptorReference then
        return self.previousPageControl:GetKeybindButtonDescriptorReference()
    end

    return nil
end

function ZO_PageNavigation:GetNextPageKeybindDescriptor()
    if self.nextPageControl.GetKeybindButtonDescriptorReference then
        return self.nextPageControl:GetKeybindButtonDescriptorReference()
    end

    return nil
end

--[[ Xml Functions ]]--

function ZO_PageNavigation.PreviousPage_OnMouseClicked(control)
    control.owner:ChangePage(ZO_PAGE_NAVIGATION_PREVIOUS_PAGE)
end

function ZO_PageNavigation.PreviousPage_OnMouseEnter(control)
    if control.owner:GetShowTooltips() then
        InitializeTooltip(InformationTooltip, control, RIGHT, 0, 0, LEFT)
        SetTooltipText(InformationTooltip, GetString(SI_PAGE_NAVIGATION_PREVIOUS_PAGE_LABEL))
    end
end

function ZO_PageNavigation.PreviousPage_OnMouseExit(control)
    ClearTooltip(InformationTooltip)
end

function ZO_PageNavigation.NextPage_OnMouseClicked(control)
    control.owner:ChangePage(ZO_PAGE_NAVIGATION_NEXT_PAGE)
end

function ZO_PageNavigation.NextPage_OnMouseEnter(control)
    if control.owner:GetShowTooltips() then
        InitializeTooltip(InformationTooltip, control, LEFT, 0, 0, RIGHT)
        SetTooltipText(InformationTooltip, GetString(SI_PAGE_NAVIGATION_NEXT_PAGE_LABEL))
    end
end

function ZO_PageNavigation.NextPage_OnMouseExit(control)
    ClearTooltip(InformationTooltip)
end

function ZO_PageNavigationIndicator.OnMouseUp(control, upInside)
    if upInside then
        control.owner:OnClicked()
    end
end

function ZO_PageNavigation.InitializePreviousPageKeybindControl(control)
    local descriptor = {
        name = GetString(SI_PAGE_NAVIGATION_PREVIOUS_PAGE_ACTION),
        keybind = "UI_SHORTCUT_LEFT_SHOULDER",
        ethereal = true,
        callback = function()
            control.owner:ChangePage(ZO_PAGE_NAVIGATION_PREVIOUS_PAGE)
        end
    }
    control:SetKeybindButtonDescriptor(descriptor)
end

function ZO_PageNavigation.InitializeNextPageKeybindControl(control)
    local descriptor = {
        name = GetString(SI_PAGE_NAVIGATION_NEXT_PAGE_ACTION),
        keybind = "UI_SHORTCUT_RIGHT_SHOULDER",
        ethereal = true,
        callback = function()
            control.owner:ChangePage(ZO_PAGE_NAVIGATION_NEXT_PAGE)
        end
    }
    control:SetKeybindButtonDescriptor(descriptor)
end
