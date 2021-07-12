ZO_HELP_NAVIGATION_CONTAINER_WIDTH = 365
-- 55 is the inset from the left side of the header to the left side of the text in ZO_IconHeader, 16 is the offset for the Scroll from ZO_ScrollContainerBase
ZO_HELP_NAVIGATION_CATEGORY_LABEL_WIDTH = ZO_HELP_NAVIGATION_CONTAINER_WIDTH - 55 - 16

ZO_Help_Keyboard = ZO_Object:Subclass()

function ZO_Help_Keyboard:New(...)
    local help = ZO_Object.New(self)
    help:Initialize(...)
    return help
end

function ZO_Help_Keyboard:Initialize(control)
    self.control = control
    control.owner = self

    self.helpControls = {}

    self.noMatchMessage = control:GetNamedChild("NoMatchMessage")
    self.searchBox = control:GetNamedChild("SearchBox")

    self.detailsScrollChild = control:GetNamedChild("DetailsContainerScrollChild")

    self.helpTitle = control:GetNamedChild("DetailsTitle")
    self.helpBody = control:GetNamedChild("DetailsBody1")
    self.helpImage = control:GetNamedChild("DetailsImage")
    self.helpBody2 = control:GetNamedChild("DetailsBody2")

    self.helpTitle:SetParent(self.detailsScrollChild)
    self.helpTitle:SetAnchor(TOPLEFT, nil, TOPLEFT, 10, 0)
    self.helpBody:SetParent(self.detailsScrollChild)
    self.helpImage:SetParent(self.detailsScrollChild)
    self.helpBody2:SetParent(self.detailsScrollChild)

    self.noMatchMessage:SetParent(self.detailsScrollChild)
    self.noMatchMessage:SetAnchor(TOPLEFT, nil, TOPLEFT, 10, 0)

    self:InitializeTree()

    self.systemFilters = nil

    local function UpdateHelp()
        if control:IsHidden() then 
            self.dirty = true
        else
            self:Refresh()
        end
    end

    control:RegisterForEvent(EVENT_HELP_INITIALIZED, UpdateHelp)
    HELP_MANAGER:RegisterCallback("UpdateSearchResults", UpdateHelp)

    LINK_HANDLER:RegisterCallback(LINK_HANDLER.LINK_CLICKED_EVENT, self.OnLinkClicked, self)
    LINK_HANDLER:RegisterCallback(LINK_HANDLER.LINK_MOUSE_UP_EVENT, self.OnLinkClicked, self)

    UpdateHelp()

    HELP_TUTORIALS_FRAGMENT = ZO_FadeSceneFragment:New(control)
    HELP_TUTORIALS_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_FRAGMENT_SHOWING then
            self:OnShowing()
        elseif newState == SCENE_FRAGMENT_HIDDEN then
            self:OnHidden()
        end
    end)


    self:InitializeKeybindStripDescriptors()
end

function ZO_Help_Keyboard:InitializeKeybindStripDescriptors()
    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_CENTER,

        {
            name = GetString(SI_ITEM_ACTION_LINK_TO_CHAT),
            keybind = "UI_SHORTCUT_SECONDARY",

            callback = function()
                local selectedData = self.navigationTree:GetSelectedData()
                local link = ZO_LinkHandler_CreateChatLink(GetHelpLink, selectedData.helpCategoryIndex, selectedData.helpIndex)
                ZO_LinkHandler_InsertLink(link)
            end,

            visible = function()
                local selectedData = self.navigationTree:GetSelectedData()
                if selectedData and selectedData.helpCategoryIndex and selectedData.helpIndex then
                    return IsChatSystemAvailableForCurrentPlatform()
                end

                return false
            end,
        },
    }
end

function ZO_Help_Keyboard:ShowSpecificHelp(helpCategoryIndex, helpIndex)
    if SCENE_MANAGER:IsShowing("helpTutorials") then
        self:SelectHelp(helpCategoryIndex, helpIndex)
    else
        self.showHelpCategoryIndex = helpCategoryIndex
        self.showHelpIndex = helpIndex
        MAIN_MENU_KEYBOARD:ShowScene("helpTutorials")
    end    
end

function ZO_Help_Keyboard:OnShowing()
    local systemFilters = HELP_MANAGER:GetShowingOverlaySceneSystemFilters()
    if systemFilters ~= self.systemFilters then
        self.systemFilters = systemFilters
        self.dirty = true
    end

    if self.dirty then
        self:Refresh()
    end
    if self.showHelpCategoryIndex then
        self:SelectHelp(self.showHelpCategoryIndex, self.showHelpIndex)
        self.showHelpCategoryIndex = nil
        self.showHelpIndex = nil
    end

    KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_Help_Keyboard:OnHidden()
    if self.searchBox:GetText() ~= "" then
        self.searchBox:SetText("")
    end

    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_Help_Keyboard:InitializeTree()
    self.navigationTree = ZO_Tree:New(GetControl(self.control, "NavigationContainerScrollChild"), 60, -10, 350)

    local function TreeHeaderSetup(node, control, data, open)
        control.text:SetText(data.name)

        control.icon:SetTexture(open and data.downIcon or data.upIcon)
        control.iconHighlight:SetTexture(data.overIcon)

        ZO_IconHeader_Setup(control, open)
    end
    local function TreeHeaderEquality(left, right)
        return left.helpCategoryIndex == right.helpCategoryIndex
    end
    self.navigationTree:AddTemplate("ZO_Help_Header", TreeHeaderSetup, nil, TreeHeaderEquality, nil, 0)

    local function TreeEntrySetup(node, control, data, open)
        control:SetSelected(false)
        control:SetText(data.name)
    end
    local function TreeEntryOnSelected(control, data, selected, reselectingDuringRebuild)
        control:SetSelected(selected)
        if selected and not reselectingDuringRebuild then
            self:RefreshDetails()
        end
    end
    local function TreeEntryEquality(left, right)
        return left.helpCategoryIndex == right.helpCategoryIndex and left.helpIndex == right.helpIndex
    end
    self.navigationTree:AddTemplate("ZO_Help_NavigationEntry", TreeEntrySetup, TreeEntryOnSelected, TreeEntryEquality)

    self.navigationTree:SetExclusive(true)
    self.navigationTree:SetOpenAnimation("ZO_TreeOpenAnimation")
end

function ZO_Help_Keyboard:SelectHelp(helpCategoryIndex, helpIndex)
    if self.helpControls and self.helpControls[helpCategoryIndex] then
        local helpControl = self.helpControls[helpCategoryIndex][helpIndex]
        if helpControl then
            helpControl.node:GetTree():SelectNode(helpControl.node)
        end
    end
end

function ZO_Help_Keyboard:AddHelpEntry(helpCategoryIndex, helpIndex)
    local systemFilters = self.systemFilters
    if systemFilters and #systemFilters > 0 then
        if not ZO_IsElementInNumericallyIndexedTable(systemFilters, GetUISystemAssociatedWithHelpEntry(helpCategoryIndex, helpIndex)) then
            return
        end
    end

    local parent
    if not self.categoryControls[helpCategoryIndex] then
        self.helpControls[helpCategoryIndex] = {}

        local categoryName, _, upIcon, downIcon, overIcon = GetHelpCategoryInfo(helpCategoryIndex)
        if categoryName ~= "" then
            local categoryData =    {
                                        name = categoryName,
                                        upIcon = upIcon,
                                        downIcon = downIcon,
                                        overIcon = overIcon,
                                        helpCategoryIndex = helpCategoryIndex,
                                    }

            parent = self.navigationTree:AddNode("ZO_Help_Header", categoryData)
            self.categoryControls[helpCategoryIndex] = parent
        end
    else
        parent = self.categoryControls[helpCategoryIndex]
    end

    if parent then
        local helpName, _,_,_,_,_, showOption = GetHelpInfo(helpCategoryIndex, helpIndex)

        if IsKeyboardHelpOption(showOption) then
            local helpData =    {
                                    name = helpName,
                                    helpCategoryIndex = helpCategoryIndex,
                                    helpIndex = helpIndex,
                                }

            local helpNode = self.navigationTree:AddNode("ZO_Help_NavigationEntry", helpData, parent)
            self.helpControls[helpCategoryIndex][helpIndex] = helpNode.control
            self.activeHelpCount = self.activeHelpCount + 1
        end
    end
end

function ZO_Help_Keyboard:AddTrialEntry()
    local systemFilters = HELP_MANAGER:GetShowingOverlaySceneSystemFilters()
    if systemFilters and #systemFilters > 0 then
        return
    end

    local accountTypeId, title, description = GetTrialInfo();
    if accountTypeId ~= 0 and title ~= "" and description ~= "" then
        local parent
        self.trialIndex = GetNumHelpCategories() + 1
        self.trialDescription = description
        if not self.categoryControls[self.trialIndex] then
            self.helpControls[self.trialIndex] = {}
            local categoryData =    {
                                        name = GetString(SI_TRIAL_ACCOUNT_HELP_CATEGORY),
                                        upIcon = "EsoUI/Art/Help/help_tabIcon_trial_up.dds",
                                        downIcon = "EsoUI/Art/Help/help_tabIcon_trial_down.dds",
                                        overIcon = "EsoUI/Art/Help/help_tabIcon_trial_over.dds",
                                        helpCategoryIndex = self.trialIndex,
                                    }
            parent = self.navigationTree:AddNode("ZO_Help_Header", categoryData)
            self.categoryControls[self.trialIndex] = parent
        else
            parent = self.categoryControls[self.trialIndex]
        end

        if parent then
            local helpData =    {
                                    name = title,
                                    helpCategoryIndex = self.trialIndex,
                                    helpIndex = 1,
                                }
            local helpNode = self.navigationTree:AddNode("ZO_Help_NavigationEntry", helpData, parent)
            self.helpControls[self.trialIndex][1] = helpNode.control
            self.activeHelpCount = self.activeHelpCount + 1
        end
    end
end

function ZO_Help_Keyboard:RefreshList()
    self.navigationTree:Reset()

    self.helpControls = {}
    self.categoryControls = {}
    self.activeHelpCount = 0
    self.trialIndex = nil
    self.trialDescription = nil
    local searchResults = HELP_MANAGER:GetSearchResults()
    if searchResults then
        for _, result in ipairs(searchResults) do
            self:AddHelpEntry(result.helpCategoryIndex, result.helpIndex)
        end
    else
        self:AddTrialEntry()
        for helpCategoryIndex = 1, GetNumHelpCategories() do
            for helpIndex = 1, GetNumHelpEntriesWithinCategory(helpCategoryIndex) do
                self:AddHelpEntry(helpCategoryIndex, helpIndex)
            end
        end
    end

    self.noMatchMessage:SetHidden(self.activeHelpCount > 0)

    self.navigationTree:Commit()

    self:RefreshDetails()
end

function ZO_Help_Keyboard:Refresh()
    self.dirty = false
    self:RefreshList()
end

function ZO_Help_Keyboard:RefreshDetails()
    local selectedData = self.navigationTree:GetSelectedData()

    if selectedData and selectedData.helpCategoryIndex and selectedData.helpIndex then
        local _, name, description, description2, image, showOption
        if selectedData.helpCategoryIndex == self.trialIndex then
            _, name, description = GetTrialInfo()
        else
            name, description, description2, image, _, _, showOption = GetHelpInfo(selectedData.helpCategoryIndex, selectedData.helpIndex)
        end

        if IsKeyboardHelpOption(showOption) then
            self.helpTitle:SetHidden(false)
            self.helpTitle:SetText(name)

            self.helpBody:SetHidden(false)
            self.helpBody:SetText(description)
            self.helpBody2:SetHidden(false)
            self.helpBody2:SetText(description2)

            if image then
                self.helpImage:SetHidden(false)
                self.helpImage:SetTexture(image)
            else
                self.helpImage:SetHidden(true)
                self.helpImage:SetHeight(0)
            end
        else
            self.helpTitle:SetHidden(true)
            self.helpBody:SetHidden(true)
            self.helpBody2:SetHidden(true)
            self.helpImage:SetHidden(true)
        end
    else
        self.helpTitle:SetHidden(true)
        self.helpBody:SetHidden(true)
        self.helpBody2:SetHidden(true)
        self.helpImage:SetHidden(true)
    end
end

function ZO_Help_Keyboard:OnLinkClicked(link, button, text, color, linkType, ...)
    if linkType == HELP_LINK_TYPE and button == MOUSE_BUTTON_INDEX_LEFT then
        local helpCategoryIndex, helpIndex = GetHelpIndicesFromHelpLink(link)
        if helpCategoryIndex and helpIndex then
            self:ShowSpecificHelp(helpCategoryIndex, helpIndex)
        end
        return true
    end
end

-- Global XML functions

function ZO_Help_OnSearchTextChanged(editBox)
    HELP_MANAGER:SetSearchString(editBox:GetText())
end

function ZO_Help_OnSearchEnterKeyPressed(editBox)
    HELP_MANAGER:SetSearchString(editBox:GetText())
    editBox:LoseFocus()
end

local HELP_MAX_IMAGE_WIDTH = 490
function ZO_Tutorials_Entries_OnTextureLoaded(control)
    -- when hidden we directly manipulate the height, so don't apply constraints in those cases
    if not control:IsHidden() then
        ZO_ResizeTextureWidthAndMaintainAspectRatio(control, HELP_MAX_IMAGE_WIDTH)
    end
end

function ZO_Help_Initialize(control)
    HELP = ZO_Help_Keyboard:New(control)
end
