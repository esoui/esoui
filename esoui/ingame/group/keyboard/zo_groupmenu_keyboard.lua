local GroupMenu_Keyboard = ZO_Object:Subclass()

function GroupMenu_Keyboard:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function GroupMenu_Keyboard:Initialize(control)
    self.control = control

    self.headerControl = self.control:GetNamedChild("Header")
    self.categoriesControl = self.control:GetNamedChild("Categories")

    self:InitializeCategories()

    KEYBOARD_GROUP_MENU_SCENE = ZO_Scene:New("groupMenuKeyboard", SCENE_MANAGER)
    KEYBOARD_GROUP_MENU_SCENE:RegisterCallback("StateChange",  function(oldState, newState)
                                                            if newState == SCENE_SHOWING  then
                                                                KEYBIND_STRIP:AddKeybindButton(self.keybindStripDescriptor)
                                                                if self.currentCategoryFragment then
                                                                    SCENE_MANAGER:AddFragment(self.currentCategoryFragment)
                                                                end
                                                                PREFERRED_ROLES:RefreshRoles()
                                                                if self.categoryFragmentToShow then
                                                                    self:SetCurrentCategory(self.categoryFragmentToShow)
                                                                    self.categoryFragmentToShow = nil
                                                                end
                                                            elseif newState == SCENE_HIDING then
                                                                KEYBIND_STRIP:RemoveKeybindButton(self.keybindStripDescriptor)
                                                            end
                                                        end)
    self:InitializeKeybindDescriptors()
    ZO_ACTIVITY_FINDER_ROOT_MANAGER:RegisterCallback("OnUpdateGroupStatus", function(...) self:OnUpdateGroupStatus(...) end)

    local function RefreshCategories()
        self:RefreshCategories()
    end

    ZO_ACTIVITY_FINDER_ROOT_MANAGER:RegisterCallback("OnLevelUpdate", RefreshCategories)
    self.control:RegisterForEvent(EVENT_PLAYER_ACTIVATED, RefreshCategories)
end

function GroupMenu_Keyboard:InitializeCategories()
    self.navigationTree = ZO_Tree:New(self.categoriesControl:GetNamedChild("ScrollChild"), 60, -10, 260)
    self.categoryFragmentToNodeLookup = {}
    self.nodeList = {}

    local function BaseIconSetup(control, data, open)
        local iconTexture = open and data.pressedIcon or data.normalIcon
        local mouseoverTexture = data.mouseoverIcon

        control.icon:SetTexture(iconTexture)
        control.iconHighlight:SetTexture(mouseoverTexture)
    end

    local function TreeIconEntrySetup(node, control, data, open)
        local selected = node.selected
        BaseIconSetup(control, data, selected)

        control.text:SetModifyTextType(MODIFY_TEXT_TYPE_UPPERCASE)
        control.text:SetText(data.name)
        control:SetSelected(selected)

        local isLocked = data.activityFinderObject and (data.activityFinderObject:GetLevelLockInfo() or data.activityFinderObject:GetNumLocations() == 0)
        isLocked = isLocked or (data.isZoneStories and ZONE_STORIES_MANAGER:GetZoneData(ZONE_STORIES_MANAGER.GetDefaultZoneSelection()) == nil)

        node:SetEnabled(not isLocked)
        ZO_IconHeader_Setup(control, selected, not isLocked)
    end

    local function TreeEntryOnSelected(control, data, selected, reselectingDuringRebuild)
        control:SetSelected(selected)

         if selected then
            if data.activityFinderObject then
                ZO_ACTIVITY_FINDER_ROOT_MANAGER:ClearSelections()
            end

            if KEYBOARD_GROUP_MENU_SCENE:IsShowing() then
                if self.currentCategoryFragment then
                    SCENE_MANAGER:RemoveFragment(self.currentCategoryFragment)
                end

                SCENE_MANAGER:AddFragment(data.categoryFragment)
            end

            self.currentCategoryFragment = data.categoryFragment
        end

        BaseIconSetup(control, data, selected)
        ZO_IconHeader_Setup(control, selected, control.node:IsEnabled())
    end

    self.navigationTree:AddTemplate("ZO_GroupMenuKeyboard_CategoryHeader", TreeIconEntrySetup, TreeEntryOnSelected)

    self.navigationTree:SetExclusive(true)
    self.navigationTree:SetOpenAnimation("ZO_TreeOpenAnimation")
end

function GroupMenu_Keyboard:InitializeKeybindDescriptors()
    self.keybindStripDescriptor =
    {
        -- Invite to Group
        alignment = KEYBIND_STRIP_ALIGN_CENTER,

        name = GetString(SI_GROUP_WINDOW_INVITE_PLAYER),
        keybind = "UI_SHORTCUT_PRIMARY",
        
        callback = function()
            ZO_Dialogs_ShowDialog("GROUP_INVITE")
        end,

        visible = function()
            local playerIsGrouped, playerIsLeader, groupSize = ZO_ACTIVITY_FINDER_ROOT_MANAGER:GetGroupStatus()
            return IsGroupModificationAvailable() and (not playerIsGrouped or (playerIsLeader and groupSize < GROUP_SIZE_MAX))
        end
    }
end

function GroupMenu_Keyboard:OnUpdateGroupStatus()
    if KEYBOARD_GROUP_MENU_SCENE:IsShowing() then
        KEYBIND_STRIP:UpdateKeybindButton(self.keybindStripDescriptor)
    end
end

function GroupMenu_Keyboard:SetCategoryOnShow(categoryFragment)
    self.categoryFragmentToShow = categoryFragment
end

function GroupMenu_Keyboard:SetCurrentCategory(categoryFragment)
    if KEYBOARD_GROUP_MENU_SCENE:IsShowing() then
        local node = self.categoryFragmentToNodeLookup[categoryFragment]
        self.navigationTree:SelectNode(node)
    end
end

do
    local LOCK_TEXTURE = zo_iconFormat("EsoUI/Art/Miscellaneous/locked_disabled.dds", "100%", "100%")
    local CHAMPION_ICON = zo_iconFormat(GetChampionPointsIcon(), "100%", "100%")

    function GroupMenu_Keyboard:OnActivityCategoryMouseEnter(control, data)
        ZO_IconHeader_OnMouseEnter(control)
        if not control.enabled then
            local isLevelLocked, lowestLevelLimit, lowestRankLimit = data.activityFinderObject:GetLevelLockInfo()
            local lockedText
            if isLevelLocked then
                if lowestLevelLimit then
                    lockedText = zo_strformat(SI_ACTIVITY_FINDER_TOOLTIP_LEVEL_LOCK, LOCK_TEXTURE, lowestLevelLimit)
                elseif lowestRankLimit then
                    lockedText = zo_strformat(SI_ACTIVITY_FINDER_TOOLTIP_CHAMPION_LOCK, LOCK_TEXTURE, CHAMPION_ICON, lowestRankLimit)
                end
            else
                local numLocations = data.activityFinderObject:GetNumLocations()
                if numLocations == 0 then
                    lockedText = zo_strformat(SI_ACTIVITY_FINDER_TOOLTIP_NO_ACTIVITIES_LOCK, LOCK_TEXTURE)
                end
            end

            if lockedText then
                InitializeTooltip(InformationTooltip, control, RIGHT, -10)
                SetTooltipText(InformationTooltip, lockedText)
            end
        end
    end

    function GroupMenu_Keyboard:OnZoneStoriesCategoryMouseEnter(control, data)
        ZO_IconHeader_OnMouseEnter(control)
        if not control.enabled then
            local isLocked = ZONE_STORIES_MANAGER:GetZoneData(ZONE_STORIES_MANAGER.GetDefaultZoneSelection()) == nil
            if isLocked then
                local lockedText = zo_strformat(SI_ZONE_STORY_TOOLTIP_UNAVAILABLE_IN_ZONE, LOCK_TEXTURE)
                InitializeTooltip(InformationTooltip, control, RIGHT, -10)
                SetTooltipText(InformationTooltip, lockedText)
            end
        end
    end
end

function GroupMenu_Keyboard:AddCategory(data, priority)

    local function PrioritySort(item1, item2)
        if not item1.priority and not item2.priority then
            return item1.data.name < item2.data.name
        end

        if item1.priority and not item2.priority then
            return true
        end

        if not item1.priority and item2.priority then
            return false
        end

        return item1.priority < item2.priority
    end

    self.navigationTree:Reset()

    local nodeData = 
    {
        priority = priority,
        data = data,
    }

    table.insert(self.nodeList, nodeData)
    table.sort(self.nodeList, PrioritySort)

    for i, curNodeData in ipairs(self.nodeList) do
        local node = self.navigationTree:AddNode("ZO_GroupMenuKeyboard_CategoryHeader", curNodeData.data)
        self.categoryFragmentToNodeLookup[curNodeData.data.categoryFragment] = node

        if curNodeData.data.activityFinderObject then
            node.control.OnMouseEnter = function(control) self:OnActivityCategoryMouseEnter(control, curNodeData.data) end
        end

        if curNodeData.data.isZoneStories then
            node.control.OnMouseEnter = function(control) self:OnZoneStoriesCategoryMouseEnter(control, curNodeData.data) end
        end
    end

    self.navigationTree:Commit()
end

function GroupMenu_Keyboard:RefreshCategories()
    self.navigationTree:RefreshVisible()
    self.navigationTree:Commit()
end

function ZO_GroupMenuKeyboard_OnInitialized(control)
    GROUP_MENU_KEYBOARD = GroupMenu_Keyboard:New(control)
end