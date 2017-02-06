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
                                                            if(newState == SCENE_SHOWING) then
                                                                KEYBIND_STRIP:AddKeybindButton(self.keybindStripDescriptor)
                                                                if self.currentCategoryFragment then
                                                                    SCENE_MANAGER:AddFragment(self.currentCategoryFragment)
                                                                end
                                                                PREFERRED_ROLES:RefreshRoles()
                                                            elseif(newState == SCENE_HIDDEN) then
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
            return not playerIsGrouped or (playerIsLeader and groupSize < GROUP_SIZE_MAX)
        end
    }
end

function GroupMenu_Keyboard:OnUpdateGroupStatus()
    if KEYBOARD_GROUP_MENU_SCENE:IsShowing() then
        KEYBIND_STRIP:UpdateKeybindButton(self.keybindStripDescriptor)
    end
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
end

function GroupMenu_Keyboard:AddCategory(data)
    local node = self.navigationTree:AddNode("ZO_GroupMenuKeyboard_CategoryHeader", data, nil, SOUNDS.JOURNAL_PROGRESS_CATEGORY_SELECTED)
    self.categoryFragmentToNodeLookup[data.categoryFragment] = node
    if data.activityFinderObject then
        node.control.OnMouseEnter = function(control) self:OnActivityCategoryMouseEnter(control, data) end
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