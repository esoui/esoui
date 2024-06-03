--[[ Lore Reader ]]--
local LoreReader = ZO_InitializingObject:Subclass()

function LoreReader:Initialize(control)
    control.owner = self
    self.control = control

    self.bookContainer = control:GetNamedChild("BookContainer")
    self.mediumBg = self.bookContainer:GetNamedChild("MediumBg")

    self.firstPage = self.bookContainer:GetNamedChild("FirstPage")
    self.firstPage.scrollChild = self.firstPage:GetNamedChild("Child")
    self.title = self.firstPage.scrollChild:GetNamedChild("Title")
    self.firstPage.body = self.firstPage.scrollChild:GetNamedChild("Body")

    self.secondPage = self.bookContainer:GetNamedChild("SecondPage")
    self.secondPage.scrollChild = self.secondPage:GetNamedChild("Child")
    self.secondPage.body = self.secondPage.scrollChild:GetNamedChild("Body")

    self.overrideImageTexture = control:GetNamedChild("OverrideImage")
    self.overrideImageTitle = self.overrideImageTexture:GetNamedChild("Title")

    local function OnShowBook(eventCode, title, body, medium, showTitle, bookId)
        local overrideImage, overrideImageTitlePosition = GetLoreBookOverrideImageFromBookId(bookId)
        self:Show(title, body, medium, showTitle, overrideImage, overrideImageTitlePosition)
        PlaySound(self.OpenSound)
    end

    local function OnHideBook()
        SCENE_MANAGER:Hide("loreReaderDefault")
    end

    local function OnAllGuiScreensResized()
        if not self.control:IsHidden() then
            self.pageGrouping = 1
            self:LayoutText()
        end
    end

    control:RegisterForEvent(EVENT_SHOW_BOOK, OnShowBook)
    control:RegisterForEvent(EVENT_HIDE_BOOK, OnHideBook)
    control:RegisterForEvent(EVENT_ALL_GUI_SCREENS_RESIZED, OnAllGuiScreensResized)

    self:InitializeKeybindStripDescriptors()

    LORE_READER_INVENTORY_SCENE = ZO_Scene:New("loreReaderInventory", SCENE_MANAGER)
    LORE_READER_LORE_LIBRARY_SCENE = ZO_Scene:New("loreReaderLoreLibrary", SCENE_MANAGER)
    LORE_READER_DEFAULT_SCENE = ZO_Scene:New("loreReaderDefault", SCENE_MANAGER)
    GAMEPAD_LORE_READER_INVENTORY_SCENE = ZO_Scene:New("gamepad_loreReaderInventory", SCENE_MANAGER)
    GAMEPAD_LORE_READER_LORE_LIBRARY_SCENE = ZO_Scene:New("gamepad_loreReaderLoreLibrary", SCENE_MANAGER)
    GAMEPAD_LORE_READER_DEFAULT_SCENE = ZO_Scene:New("gamepad_loreReaderDefault", SCENE_MANAGER)

    local function OnPCSceneStateChange(oldState, newState)
        if newState == SCENE_SHOWING then
            KEYBIND_STRIP:RemoveDefaultExit()
            KEYBIND_STRIP:AddKeybindButtonGroup(self.PCKeybindStripDescriptor)
            self.keybindStripDescriptor = self.PCKeybindStripDescriptor
        elseif newState == SCENE_HIDDEN then
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.PCKeybindStripDescriptor)
            KEYBIND_STRIP:RestoreDefaultExit()
        end
    end

    local function OnGamepadSceneStateChange(oldState, newState)
        if newState == SCENE_SHOWING then
            KEYBIND_STRIP:AddKeybindButtonGroup(self.gamepadKeybindStripDescriptor)
            self.keybindStripDescriptor = self.gamepadKeybindStripDescriptor
            SCREEN_NARRATION_MANAGER:QueueCustomEntry("loreReader")
        elseif newState == SCENE_HIDDEN then
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.gamepadKeybindStripDescriptor)
        end
    end

    LORE_READER_INVENTORY_SCENE:RegisterCallback("StateChange", OnPCSceneStateChange)
    LORE_READER_LORE_LIBRARY_SCENE:RegisterCallback("StateChange", OnPCSceneStateChange)
    LORE_READER_DEFAULT_SCENE:RegisterCallback("StateChange", OnPCSceneStateChange)
    GAMEPAD_LORE_READER_INVENTORY_SCENE:RegisterCallback("StateChange", OnGamepadSceneStateChange)
    GAMEPAD_LORE_READER_LORE_LIBRARY_SCENE:RegisterCallback("StateChange", OnGamepadSceneStateChange)
    GAMEPAD_LORE_READER_DEFAULT_SCENE:RegisterCallback("StateChange", OnGamepadSceneStateChange)

    local narrationInfo =
    {
        canNarrate = function()
            return GAMEPAD_LORE_READER_INVENTORY_SCENE:IsShowing() or GAMEPAD_LORE_READER_LORE_LIBRARY_SCENE:IsShowing() or GAMEPAD_LORE_READER_DEFAULT_SCENE:IsShowing()
        end,
        selectedNarrationFunction = function()
            return self:GetNarrationText()
        end,
    }
    SCREEN_NARRATION_MANAGER:RegisterCustomObject("loreReader", narrationInfo)
end

function LoreReader:InitializeKeybindStripDescriptors()
    local customKeybindControl = self.control:GetNamedChild("KeyStripMouseButtons")
    customKeybindControl:SetHidden(true)
    customKeybindControl.owner = self

    self.PCKeybindStripDescriptor =
    {
        -- Turn pages
        {
            alignment = KEYBIND_STRIP_ALIGN_CENTER,
            name = GetString(SI_LORE_READER_TURN_PAGES),
            keybind = "CUSTOM_LORE_READER",
            callback = function() end,
            customKeybindControl = customKeybindControl,
            visible = function() return self.maxPageGroupings > 1 end,
        },

        -- The keyboard exit should just close this scene (so if it was pushed on the scene stack it will go back, such as going back to the lore library)
        {
            name = GetString(SI_EXIT_BUTTON),
            keybind = "UI_SHORTCUT_EXIT",
            order = -10000,
            callback = function()
                SCENE_MANAGER:HideCurrentScene()
            end,
        },
    }

    self.gamepadKeybindStripDescriptor =
    {
        -- Gamepad turn page backward
        {
            alignment = KEYBIND_STRIP_ALIGN_CENTER,
            name = GetString(SI_LORE_READER_PREVIOUS_PAGE),
            keybind = "UI_SHORTCUT_LEFT_TRIGGER",
            callback = function() 
                self:ChangePageGrouping(-1)
            end,
            enabled = function() return self.pageGrouping ~= 1 end,
            visible = function() return self.maxPageGroupings > 1 end,
        },

        -- Gamepad turn page forward
        {
            alignment = KEYBIND_STRIP_ALIGN_CENTER,
            name = GetString(SI_LORE_READER_NEXT_PAGE),
            keybind = "UI_SHORTCUT_RIGHT_TRIGGER",
            callback = function() 
                self:ChangePageGrouping(1)
            end,
            enabled = function() return self.pageGrouping ~= self.maxPageGroupings end,
            visible = function() return self.maxPageGroupings > 1 end,
        },
    }

    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.gamepadKeybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON)
end

function LoreReader:GetCustomSceneName(currentSceneName)
    if currentSceneName == "loreLibrary" or currentSceneName == "bookSetGamepad" then
        return IsInGamepadPreferredMode() and "gamepad_loreReaderLoreLibrary" or "loreReaderLoreLibrary"
    elseif currentSceneName == "inventory" or currentSceneName == "gamepad_inventory_item_filter" or currentSceneName == "gamepad_inventory_root" then
        return IsInGamepadPreferredMode() and "gamepad_loreReaderInventory" or "loreReaderInventory"
    end
end

function LoreReader:Show(title, body, medium, showTitle, overrideImage, overrideImageTitlePosition)
    local isGamepad = IsInGamepadPreferredMode()
    self:SetupBook(title, body, medium, showTitle, isGamepad, overrideImage, overrideImageTitlePosition)
    local customSceneName = self:GetCustomSceneName(SCENE_MANAGER:GetCurrentScene():GetName())
    if customSceneName then
        SCENE_MANAGER:Push(customSceneName)
    else
        --If we are not pushing a custom scene, just fall back to the default
        local defaultSceneName = isGamepad and "gamepad_loreReaderDefault" or "loreReaderDefault"
        SCENE_MANAGER:Show(defaultSceneName)
    end
end

function LoreReader:SetupBook(title, body, medium, showTitle, isGamepad, overrideImage, overrideImageTitlePosition)
    self:ApplyMedium(medium, isGamepad, overrideImage)
    self.pageGrouping = 1
    self:SetText(title, body, showTitle, overrideImageTitlePosition)
end

function LoreReader:OnHide()
    EndInteraction(INTERACTION_BOOK)
    PlaySound(self.CloseSound)
end

local READER_MEDIA =
{
    [BOOK_MEDIUM_NONE] = {}, -- Intentionally left blank to cause UI errors if referenced.
    [BOOK_MEDIUM_YELLOWED_PAPER] =
    {
        NumPages = 2,
        Bg = "EsoUI/Art/LoreLibrary/loreLibrary_paperBook.dds",
        keyboardFonts =
        {
            TitleFont = "ZoFontBookPaperTitle",
            BodyFont = "ZoFontBookPaper",
        },
        gamepadFonts =
        {
            TitleFont = "ZoFontGamepadBookPaperTitle",
            BodyFont = "ZoFontGamepadBookPaper",
        },
        OpenSound = SOUNDS.BOOK_OPEN,
        CloseSound = SOUNDS.BOOK_CLOSE,
        TurnPageSound = SOUNDS.BOOK_PAGE_TURN,
    },
    [BOOK_MEDIUM_ANIMAL_SKIN] =
    {
        NumPages = 2,
        Bg = "EsoUI/Art/LoreLibrary/loreLibrary_skinBook.dds",
        keyboardFonts =
        {
            TitleFont = "ZoFontBookSkinTitle",
            BodyFont = "ZoFontBookSkin",
        },
        gamepadFonts =
        {
            TitleFont = "ZoFontGamepadBookSkinTitle",
            BodyFont = "ZoFontGamepadBookSkin",
        },
        OpenSound = SOUNDS.BOOK_OPEN,
        CloseSound = SOUNDS.BOOK_CLOSE,
        TurnPageSound = SOUNDS.BOOK_PAGE_TURN,
    },
    [BOOK_MEDIUM_RUBBING_PAPER] =
    {
        NumPages = 2,
        Bg = "EsoUI/Art/LoreLibrary/loreLibrary_rubbingBook.dds",
        keyboardFonts =
        {
            TitleFont = "ZoFontBookRubbingTitle",
            BodyFont = "ZoFontBookRubbing",
        },
        gamepadFonts =
        {
            TitleFont = "ZoFontGamepadBookRubbingTitle",
            BodyFont = "ZoFontGamepadBookRubbing",
        },
        OpenSound = SOUNDS.BOOK_OPEN,
        CloseSound = SOUNDS.BOOK_CLOSE,
        TurnPageSound = SOUNDS.BOOK_PAGE_TURN,
    },
    [BOOK_MEDIUM_LETTER] =
    {
        NumPages = 1,
        Bg = "EsoUI/Art/LoreLibrary/loreLibrary_letter.dds",
        keyboardFonts =
        {
            TitleFont = "ZoFontBookLetterTitle",
            BodyFont = "ZoFontBookLetter",
        },
        gamepadFonts =
        {
            TitleFont = "ZoFontGamepadBookLetterTitle",
            BodyFont = "ZoFontGamepadBookLetter",
        },
        PageWidth = 520,
        PageHeight = 725,
        OpenSound = SOUNDS.LORE_NOTE_OPEN,
        CloseSound = SOUNDS.LORE_NOTE_CLOSE,
        TurnPageSound = SOUNDS.LORE_NOTE_PAGE_TURN,
    },
    [BOOK_MEDIUM_NOTE] =
    {
        NumPages = 1,
        Bg = "EsoUI/Art/LoreLibrary/loreLibrary_note.dds",
        keyboardFonts =
        {
            TitleFont = "ZoFontBookNoteTitle",
            BodyFont = "ZoFontBookNote",
        },
        gamepadFonts =
        {
            TitleFont = "ZoFontGamepadBookNoteTitle",
            BodyFont = "ZoFontGamepadBookNote",
        },
        PageWidth = 520,
        PageHeight = 725,
        OpenSound = SOUNDS.LORE_NOTE_OPEN,
        CloseSound = SOUNDS.LORE_NOTE_CLOSE,
        TurnPageSound = SOUNDS.LORE_NOTE_PAGE_TURN,
    },
    [BOOK_MEDIUM_SCROLL] =
    {
        NumPages = 1,
        Bg = "EsoUI/Art/LoreLibrary/loreLibrary_scroll.dds",
        keyboardFonts =
        {
            TitleFont = "ZoFontBookScrollTitle",
            BodyFont = "ZoFontBookScroll",
        },
        gamepadFonts ={
            TitleFont = "ZoFontGamepadBookScrollTitle",
            BodyFont = "ZoFontGamepadBookScroll",
        },
        PageWidth = 480,
        PageHeight = 650,
        FontAlpha = .65,
        OpenSound = SOUNDS.LORE_NOTE_OPEN,
        CloseSound = SOUNDS.LORE_NOTE_CLOSE,
        TurnPageSound = SOUNDS.LORE_NOTE_PAGE_TURN,
    },
    [BOOK_MEDIUM_STONE_TABLET] =
    {
        NumPages = 1,
        Bg = "EsoUI/Art/LoreLibrary/loreLibrary_stoneTablet.dds",
        keyboardFonts =
        {
            TitleFont = "ZoFontBookTabletTitle",
            BodyFont = "ZoFontBookTablet",
        },
        gamepadFonts =
        {
            TitleFont = "ZoFontGamepadBookTabletTitle",
            BodyFont = "ZoFontGamepadBookTablet",
        },
        PageHeight = 765,
        PageWidth = 780,
        FontAlpha = .65,
        FontStyleColor = ZO_ColorDef:New(1, 1, 1, .8),
        OpenSound = SOUNDS.TABLET_OPEN,
        CloseSound = SOUNDS.TABLET_CLOSE,
        TurnPageSound = SOUNDS.TABLET_PAGE_TURN,
    },
    [BOOK_MEDIUM_METAL] =
    {
        NumPages = 2,
        Bg = "EsoUI/Art/LoreLibrary/loreLibrary_dwemerBook.dds",
        keyboardFonts =
        {
            TitleFont = "ZoFontBookMetalTitle",
            BodyFont = "ZoFontBookMetal",
        },
        gamepadFonts =
        {
            TitleFont = "ZoFontGamepadBookMetalTitle",
            BodyFont = "ZoFontGamepadBookMetal",
        },
        LeftPageXOffset = 95,
        RightPageXOffset = -80,
        FontStyleColor = ZO_ColorDef:New(1, 1, 1, .4),
        OpenSound = SOUNDS.BOOK_METAL_OPEN,
        CloseSound = SOUNDS.BOOK_METAL_CLOSE,
        TurnPageSound = SOUNDS.BOOK_METAL_PAGE_TURN,
    },
    [BOOK_MEDIUM_METAL_TABLET] =
    {
        NumPages = 1,
        Bg = "EsoUI/Art/LoreLibrary/loreLibrary_dwemerPage.dds",
        keyboardFonts =
        {
            TitleFont = "ZoFontBookMetalTitle",
            BodyFont = "ZoFontBookMetal",
        },
        gamepadFonts =
        {
            TitleFont = "ZoFontGamepadBookMetalTitle",
            BodyFont = "ZoFontGamepadBookMetal",
        },
        PageWidth = 520,
        PageHeight = 725,
        FontStyleColor = ZO_ColorDef:New(1, 1, 1, .4),
        OpenSound = SOUNDS.BOOK_METAL_OPEN,
        CloseSound = SOUNDS.BOOK_METAL_CLOSE,
        TurnPageSound = SOUNDS.BOOK_METAL_PAGE_TURN,
    },
    [BOOK_MEDIUM_ELVEN_SCROLL] =
    {
        NumPages = 1,
        Bg = "EsoUI/Art/LoreLibrary/loreLibrary_RiteOfPropagation.dds",
        keyboardFonts =
        {
            TitleFont = "ZoFontBookScrollTitle",
            BodyFont ="ZoFontBookScroll",
        },
        gamepadFonts ={
            TitleFont = "ZoFontGamepadBookScrollTitle",
            BodyFont = "ZoFontGamepadBookScroll",
        },
        PageWidth = 480,
        PageHeight = 650,
        PageYOffset = -4,
        OpenSound = SOUNDS.LORE_NOTE_OPEN,
        CloseSound = SOUNDS.LORE_NOTE_CLOSE,
        TurnPageSound = SOUNDS.LORE_NOTE_PAGE_TURN,
    },
}

function LoreReader:ApplyMedium(medium, isGamepad, overrideImage)
    local mediumData = READER_MEDIA[medium] or READER_MEDIA[BOOK_MEDIUM_YELLOWED_PAPER]
    local r, g, b = GetInterfaceColor(INTERFACE_COLOR_TYPE_BOOK_MEDIUM, medium)
    local a = mediumData.FontAlpha or .8
    local styleR, styleG, styleB, styleA
    if mediumData.FontStyleColor then
        styleR, styleG, styleB, styleA = mediumData.FontStyleColor:UnpackRGBA()
    else
        styleR, styleG, styleB, styleA = 0, 0, 0, 1
    end
    local fonts = isGamepad and mediumData.gamepadFonts or mediumData.keyboardFonts
    local titleFont = fonts.TitleFont
    local bodyFont = fonts.BodyFont
    self.CloseSound = mediumData.CloseSound
    self.OpenSound = mediumData.OpenSound

    self.useOverrideImage = overrideImage ~= nil
    if self.useOverrideImage then
        self.bookContainer:SetHidden(true)
        self.overrideImageTexture:SetHidden(false)
        
        self.overrideImageTexture:SetTexture(overrideImage)
        self.overrideImageTitle:SetColor(r, g, b, a)
        self.overrideImageTitle:SetStyleColor(styleR, styleG, styleB, styleA)
        self.overrideImageTitle:SetFont(titleFont)
    else
        self.bookContainer:SetHidden(false)
        self.overrideImageTexture:SetHidden(true)

        self.renderablePageHeight = mediumData.PageHeight or 660

        self.mediumBg:SetTexture(mediumData.Bg)

        self.title:SetColor(r, g, b, a)
        self.title:SetStyleColor(styleR, styleG, styleB, styleA)
        self.firstPage.body:SetColor(r, g, b, a)
        self.firstPage.body:SetStyleColor(styleR, styleG, styleB, styleA)
        self.secondPage.body:SetColor(r, g, b, a)
        self.secondPage.body:SetStyleColor(styleR, styleG, styleB, styleA)

        self.title:SetFont(titleFont)
        self.firstPage:SetHeight(self.renderablePageHeight)
        self.firstPage.body:SetFont(bodyFont)

        self.secondPage:SetHeight(self.renderablePageHeight)
        self.secondPage.body:SetFont(bodyFont)

        self.firstPage:ClearAnchors()
        self.secondPage:ClearAnchors()

        local pageWidth = mediumData.PageWidth or 375
        local pageYOffset = mediumData.PageYOffset or -20
        self.title:SetWidth(pageWidth)
        self.numPagesPerGrouping = mediumData.NumPages
        if self.numPagesPerGrouping > 1 then
            local leftPageXOffset = mediumData.LeftPageXOffset or 100
            local rightPageXOffset = mediumData.RightPageXOffset or -95

            self.firstPage:SetAnchor(LEFT, nil, LEFT, leftPageXOffset, pageYOffset)
            self.secondPage:SetAnchor(RIGHT, nil, RIGHT, rightPageXOffset, pageYOffset)
        else
            local pageXOffset = mediumData.LeftPageXOffset or 0
            self.firstPage:SetAnchor(CENTER, nil, CENTER, pageXOffset, pageYOffset)
        end
    
        self.firstPage:SetWidth(pageWidth)
        self.firstPage.body:SetWidth(pageWidth)
        self.secondPage:SetWidth(pageWidth)
        self.secondPage.body:SetWidth(pageWidth)

        self.TurnPageSound = mediumData.TurnPageSound
    end
end

do
    local OVERRIDE_IMAGE_TITLE_PADDING = 20

    local function CalculatePageHeight(fontHeight, maxHeight)
        return zo_floor(maxHeight / fontHeight) * fontHeight
    end

    function LoreReader:LayoutText()
        if self.useOverrideImage then
            self.maxPageGroupings = 1

            if self.showTitle then
                self.overrideImageTitle:SetHidden(false)
                local anchorPosition = self.overrideImageTitlePosition
                local offsetX = 0
                local offsetY = 0
                local horizontalAlignment = TEXT_ALIGN_CENTER
                if ZO_FlagHelpers.MaskHasFlag(anchorPosition, LEFT) then
                    offsetX = OVERRIDE_IMAGE_TITLE_PADDING
                    horizontalAlignment = TEXT_ALIGN_LEFT
                elseif ZO_FlagHelpers.MaskHasFlag(anchorPosition, RIGHT) then
                    offsetX = -OVERRIDE_IMAGE_TITLE_PADDING
                    horizontalAlignment = TEXT_ALIGN_RIGHT
                end
                if ZO_FlagHelpers.MaskHasFlag(anchorPosition, TOP) then
                    offsetY = OVERRIDE_IMAGE_TITLE_PADDING
                elseif ZO_FlagHelpers.MaskHasFlag(anchorPosition, BOTTOM) then
                    offsetY = -OVERRIDE_IMAGE_TITLE_PADDING
                end
                self.overrideImageTitle:ClearAnchors()
                self.overrideImageTitle:SetAnchor(anchorPosition, nil, anchorPosition, offsetX, offsetY)
                self.overrideImageTitle:SetText(self.titleText)
                self.overrideImageTitle:SetWidth(self.overrideImageTexture:GetWidth() - (OVERRIDE_IMAGE_TITLE_PADDING * 2))
                self.overrideImageTitle:SetHorizontalAlignment(horizontalAlignment)
            else
                self.overrideImageTitle:SetHidden(true)
            end
        else
            local bodyFontHeight = self.firstPage.body:GetFontHeight()
            --Calculate the number of full lines that can fit in the page then save the height of that many lines as pageHeight.
            self.pageHeight = CalculatePageHeight(bodyFontHeight, self.renderablePageHeight)

            self.firstPage:SetHeight(self.pageHeight)
            self.firstPage.body:ClearAnchors()

            local titleHeight = 0
            local yOffsetNeededToAlignLines = 0

            if self.showTitle then
                self.title:SetHidden(false)
                self.title:SetText(self.titleText)

                titleHeight = self.title:GetTextHeight()
                yOffsetNeededToAlignLines = bodyFontHeight - (titleHeight % bodyFontHeight)

                self.firstPage.body:SetAnchor(TOP, self.title, BOTTOM, 0, yOffsetNeededToAlignLines)
            else
                self.title:SetHidden(true)
                self.firstPage.body:SetAnchor(TOP, self.title, TOP, 0, 0)
            end
    
            self.firstPage.body:SetText(self.bodyText)

            if self.numPagesPerGrouping > 1 then
                self.secondPage:SetHidden(false)
                self.secondPage:SetHeight(self.pageHeight)
                self.secondPage.body:SetText(self.bodyText)
                self.secondPageAdditionalOffset = self.pageHeight - (titleHeight + yOffsetNeededToAlignLines)
                self.secondPage:SetVerticalScroll(self.secondPageAdditionalOffset)
            else
                self.secondPage:SetHidden(true)
            end

            self.firstPage:SetVerticalScroll(0)
    
            --The title height + the spacing between the title and body + the body height
            local entireHeight = titleHeight + yOffsetNeededToAlignLines + self.firstPage.body:GetTextHeight()

            --There are cases where the entire height is just barely larger than what can fit in one page (or two pages, or any integer number of pages). This leads to us
            --allocating a whole new page to show the bottom of the last line which often doesn't even have anything visible going on. The slop value is used to modify the
            --calculation so that if the amount that overflows the page is less than 10% of one line in height we don't bother making a new page. This pretty much only happens
            --due to minor floating point differences, but we might as well handle as much as we can.
            local slop = (bodyFontHeight * 0.1) / self.pageHeight
            local numPages = zo_ceil((entireHeight / self.pageHeight) - slop)
            self.maxPageGroupings = zo_ceil(numPages / self.numPagesPerGrouping)
        end
        self:UpdatePagingButtons()
    end
end

function LoreReader:SetText(title, body, showTitle, overrideImageTitlePosition)
    self.titleText = title
    self.bodyText = body
    self.showTitle = showTitle
    self.overrideImageTitlePosition = overrideImageTitlePosition

    self:LayoutText()
end

function LoreReader:ChangePageGrouping(offset)
    local newPage = zo_clamp(self.pageGrouping + offset, 1, self.maxPageGroupings)
    if self.pageGrouping ~= newPage then
        self.pageGrouping = newPage
        local scrollOffset = (self.pageGrouping - 1) * self.pageHeight * self.numPagesPerGrouping
        self.firstPage:SetVerticalScroll(scrollOffset)
        if self.numPagesPerGrouping > 1 then
            self.secondPage:SetVerticalScroll(scrollOffset + self.secondPageAdditionalOffset)
        end

        self:UpdatePagingButtons()
        PlaySound(self.TurnPageSound)
        --Re-narrate when changing the page grouping
        SCREEN_NARRATION_MANAGER:QueueCustomEntry("loreReader")
    end
end

function LoreReader:UpdatePagingButtons()
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

function LoreReader:GetNarrationText()
    
    if self.useOverrideImage then
        if self.showTitle then
            return SCREEN_NARRATION_MANAGER:CreateNarratableObject(self.titleText)
        end
    else
        local narrations = {}
        local bodyFontHeight = self.firstPage.body:GetFontHeight()
        local titleHeight = 0
        local yOffsetNeededToAlignLines = 0

        if self.showTitle then
            --If this is the first page and we are showing the title, include that in the narration
            if self.pageGrouping == 1 then
                table.insert(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(self.titleText))
            end
            titleHeight = self.title:GetTextHeight()
            yOffsetNeededToAlignLines = bodyFontHeight - (titleHeight % bodyFontHeight)
        end
    
        --Calculate the number of lines for the first page, taking title into account
        local numLinesFirstPage = zo_floor((self.renderablePageHeight - (yOffsetNeededToAlignLines + titleHeight)) / bodyFontHeight)
        --Calculate the number of lines for the rest of the pages
        local numLinesNormal = zo_floor(self.renderablePageHeight / bodyFontHeight)

        --Determine the number of lines for the second page (if there is one)
        local additionalLinesPerGrouping = 0
        if self.numPagesPerGrouping > 1 then
            additionalLinesPerGrouping = numLinesNormal
        end

        --Determine the number of lines for the first and second page combined
        local numLinesPerGrouping = numLinesNormal + additionalLinesPerGrouping

        local startLine
        local endLine

        if self.pageGrouping > 1 then
            --The first page grouping could potentially have a different number of lines than the rest, so manually account for that in the calculation
            local endLinePrevious = (self.pageGrouping - 2) * numLinesPerGrouping + numLinesFirstPage + additionalLinesPerGrouping
            startLine = endLinePrevious + 1
            endLine = endLinePrevious + numLinesPerGrouping
        else
            --If this is the first page grouping, then we can assume we are starting at line 1
            startLine = 1
            endLine = numLinesFirstPage + additionalLinesPerGrouping
        end

        --Get the text for the lines we determined and add it to the narration
        local narrationText = self.firstPage.body:GetTextForLines(startLine, endLine)
        table.insert(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(narrationText))
        return narrations
    end
end

--[[ XML Handlers ]]--
function ZO_LoreReader_OnInitialize(control)
    LORE_READER = LoreReader:New(control)
end

function ZO_LoreReader_OnHide(control)
    control.owner:OnHide()
end

function ZO_LoreReader_OnClicked(control, button)
    if button == MOUSE_BUTTON_INDEX_LEFT then
        control.owner:ChangePageGrouping(-1)
    elseif button == MOUSE_BUTTON_INDEX_RIGHT then
        control.owner:ChangePageGrouping(1)
    end
end

function ZO_LoreReader_OnPagePreviousClicked(control)
    control.owner:ChangePageGrouping(-1)
end

function ZO_LoreReader_OnPageNextClicked(control)
    control.owner:ChangePageGrouping(1)
end