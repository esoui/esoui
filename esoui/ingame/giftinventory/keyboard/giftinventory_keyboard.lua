ZO_GiftInventory_Keyboard = ZO_Object:Subclass()

function ZO_GiftInventory_Keyboard:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_GiftInventory_Keyboard:Initialize(control)
    self.control = control
    self.listContainerControl = control:GetNamedChild("ListContainer")

    local scene = ZO_Scene:New("giftInventoryKeyboard", SCENE_MANAGER)
    self.scene = scene
    scene:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWING then
            self:DeferredInitialize()

            if self.queuedCategoryTagToSelect then
                local nodeToSelect = self:GetCategoryNodeByCategoryTag(self.queuedCategoryTagToSelect)
                if nodeToSelect then
                    self.navigationTree:SelectNode(nodeToSelect)
                end
                self.queuedCategoryTagToSelect = nil
            end

            if self.selectedCategoryObject then
                self.selectedCategoryObject:Show()
            end

            if self.isDirty then
                self.navigationTree:RefreshVisible()
                self.isDirty = false
            end

            TriggerTutorial(TUTORIAL_TRIGGER_GIFT_INVENTORY_OPENED)
        elseif newState == SCENE_HIDDEN then
            if self.selectedCategoryObject then
                self.selectedCategoryObject:Hide()
            end
        end
    end)
    SYSTEMS:RegisterKeyboardRootScene("giftInventory", scene)

    local fragment = ZO_FadeSceneFragment:New(control)
    self.fragment = fragment

    local RECEIVED_CATEGORY =
    {
        name = GetString(SI_GIFT_INVENTORY_RECEIVED_GIFTS_HEADER),
        down = "EsoUI/Art/Market/Keyboard/tabIcon_gifting_down.dds",
        up = "EsoUI/Art/Market/Keyboard/tabIcon_gifting_up.dds",
        over = "EsoUI/Art/Market/Keyboard/tabIcon_gifting_over.dds",
        giftStates = { GIFT_STATE_RECEIVED, },
    }

    local THANKED_SUBCATEGORY =
    {
        name = GetString(SI_GIFT_INVENTORY_CLAIMED_GIFTS_HEADER),
        giftStates = { GIFT_STATE_THANKED, },
    }

    local SENT_SUBCATEGORY =
    {
        name = GetString(SI_GIFT_INVENTORY_UNCLAIMED_GIFTS_HEADER),
        giftStates = { GIFT_STATE_SENT, },
    }

    local SENT_AND_THANKED_CATEGORY =
    {
        name = GetString(SI_GIFT_INVENTORY_SENT_GIFTS_HEADER),
        down = "EsoUI/Art/Market/Keyboard/tabIcon_gifting_down.dds",
        up = "EsoUI/Art/Market/Keyboard/tabIcon_gifting_up.dds",
        over = "EsoUI/Art/Market/Keyboard/tabIcon_gifting_over.dds",
        giftStates = { GIFT_STATE_THANKED, GIFT_STATE_SENT },
        subcategories =
        {
            THANKED_SUBCATEGORY,
            SENT_SUBCATEGORY,
        },
    }

    local RETURNED_CATEGORY =
    {
        name = GetString(SI_GIFT_INVENTORY_RETURNED_GIFTS_HEADER),
        down = "EsoUI/Art/Market/Keyboard/tabIcon_gifting_down.dds",
        up = "EsoUI/Art/Market/Keyboard/tabIcon_gifting_up.dds",
        over = "EsoUI/Art/Market/Keyboard/tabIcon_gifting_over.dds",
        giftStates = { GIFT_STATE_RETURNED, },
    }

    self.categories =
    {
        RECEIVED_CATEGORY,
        SENT_AND_THANKED_CATEGORY,
        RETURNED_CATEGORY
    }

    self.categoriesByTag =
    {
        received = RECEIVED_CATEGORY,
        thanked = THANKED_SUBCATEGORY,
        sent = SENT_SUBCATEGORY,
        returned = RETURNED_CATEGORY,
    }

    GIFT_INVENTORY_MANAGER:RegisterCallback("GiftListsChanged", function(...) self:OnGiftListsChanged(...) end)
    MAIN_MENU_KEYBOARD:RefreshCategoryBar()
end

function ZO_GiftInventory_Keyboard:GetCategoryNodeByCategoryTag(categoryTag)
    local categoryData = self.categoriesByTag[categoryTag]
    if categoryData then
        return self.navigationTree:GetTreeNodeByData(categoryData)
    end

    return nil
end

function ZO_GiftInventory_Keyboard:SetSelectedCategoryByGiftState(giftState)
    local categoryTagToSelect
    if giftState == GIFT_STATE_RECEIVED then
        categoryTagToSelect = "received"
    elseif giftState == GIFT_STATE_THANKED then
        categoryTagToSelect = "thanked"
    elseif giftState == GIFT_STATE_SENT then
        categoryTagToSelect = "sent"
    elseif giftState == GIFT_STATE_RETURNED then
        categoryTagToSelect = "returned"
    end

    if categoryTagToSelect ~= nil then
        if self.scene:IsShowing() and self.doneDeferredInit then
            local nodeToSelect = self:GetCategoryNodeByCategoryTag(categoryTagToSelect)
            if nodeToSelect then
                self.navigationTree:SelectNode(nodeToSelect)
            end
        elseif self.scene:GetState() == SCENE_HIDDEN then
            self.queuedCategoryTagToSelect = categoryTagToSelect
        end
    end
end

function ZO_GiftInventory_Keyboard:DeferredInitialize()
    if not self.doneDeferredInit then
        self.doneDeferredInit = true

        self:BuildNavigationTree()
    end
end

function ZO_GiftInventory_Keyboard:BuildNavigationTree()
    self.navigationTree = ZO_Tree:New(GetControl(self.control, "NavigationContainer"), 60, -10, 275)
    self.navigationTree:SetAutoSelectChildOnNodeOpen(true)

    local function SharedStatusSetup(control, category, selected)
        if not control.statusIcon then
            control.statusIcon = control:GetNamedChild("StatusIcon")
        end
        local isNewHidden = true
        for _, giftState in ipairs(category.giftStates) do
            if GIFT_INVENTORY_MANAGER:HasAnyUnseenGiftsByState(giftState) then
                isNewHidden = false
                break
            end
        end
        control.statusIcon:SetHidden(isNewHidden)
    end

    --Childless Header
    local function ChildlessHeaderSetup(node, control, category, open)
        control.text:SetModifyTextType(MODIFY_TEXT_TYPE_UPPERCASE)
        control.text:SetText(category.name)
        control.iconHighlight:SetTexture(category.over)

        local selected = node:IsSelected()
        control.icon:SetTexture(selected and category.down or category.up)
        SharedStatusSetup(control, category, selected)
        ZO_IconHeader_Setup(control, selected)
    end
    local function TreeEquality(left, right)
        return left == right
    end

    local function ChildlessHeaderOnSelected(control, category, selected, reselectingDuringRebuild)
        control.icon:SetTexture(selected and category.down or category.up)
        ZO_IconHeader_Setup(control, selected)

        if selected and not reselectingDuringRebuild then
            self:SelectCategory(category.categoryObject)
        end
    end
    self.navigationTree:AddTemplate("ZO_StatusIconChildlessHeader", ChildlessHeaderSetup, ChildlessHeaderOnSelected, TreeEquality)
    
    --Normal Header
    local function HeaderSetup(node, control, category, open)
        control.text:SetModifyTextType(MODIFY_TEXT_TYPE_UPPERCASE)
        control.text:SetText(category.name)
        control.iconHighlight:SetTexture(category.over)
        control.icon:SetTexture(open and category.down or category.up)

        SharedStatusSetup(control, category, open)
        ZO_IconHeader_Setup(control, open)
    end
    local CHILD_INDENT = 73
    local CHILD_SPACING = 0
    self.navigationTree:AddTemplate("ZO_StatusIconHeader", HeaderSetup, nil, TreeEquality, CHILD_INDENT, CHILD_SPACING)
    
    --Child

    local function ChildSetup(node, control, category, open)
        control:SetText(category.name)

        local selected = node:IsSelected()
        SharedStatusSetup(control, category, selected)
        ZO_LabelHeader_Setup(control, selected)
    end

    local function ChildOnSelected(control, category, selected, reselectingDuringRebuild)
        ZO_LabelHeader_Setup(control, selected)

        if selected and not reselectingDuringRebuild then
            self:SelectCategory(category.categoryObject)
        end
    end
    self.navigationTree:AddTemplate("ZO_TreeStatusLabelSubCategory", ChildSetup, ChildOnSelected, TreeEquality)

    self.navigationTree:SetExclusive(true)
    self.navigationTree:SetOpenAnimation("ZO_TreeOpenAnimation")

    local function AddNode(template, categoryData, parentNode)
        local node = self.navigationTree:AddNode(template, categoryData, parentNode)
        local statusIcon = node.control:GetNamedChild("StatusIcon")
        statusIcon:SetTexture(ZO_KEYBOARD_NEW_ICON)
        return node
    end

    for _, category in ipairs(self.categories) do
        if category.categoryObject then
            AddNode("ZO_StatusIconChildlessHeader", category)
        else
            local node = AddNode("ZO_StatusIconHeader", category)
            for _, subcategory in ipairs(category.subcategories) do
                AddNode("ZO_TreeStatusLabelSubCategory", subcategory, node)
            end
        end
    end

    local nodeToSelect
    if self.queuedCategoryTagToSelect then
        nodeToSelect = self:GetCategoryNodeByCategoryTag(self.queuedCategoryTagToSelect)
        self.queuedCategoryTagToSelect = nil
    end
    self.navigationTree:Commit(nodeToSelect)
end

function ZO_GiftInventory_Keyboard:GetScene()
    return self.scene
end

function ZO_GiftInventory_Keyboard:GetFragment()
    return self.fragment
end

function ZO_GiftInventory_Keyboard:SetCategoryObject(categoryObject, control, tag)
    control:SetParent(self.listContainerControl)
    control:SetAnchorFill(self.listContainerControl)
    self.categoriesByTag[tag].categoryObject = categoryObject
end

function ZO_GiftInventory_Keyboard:SelectCategory(categoryObject)
    if categoryObject ~= self.selectedCategoryObject then
        if self.selectedCategoryObject then
            self.selectedCategoryObject:Hide()
        end
        self.selectedCategoryObject = categoryObject
        if categoryObject then
            categoryObject:Show()
        end
    end
end

function ZO_GiftInventory_Keyboard:OnGiftListsChanged(changedLists)
    if self.scene:IsShowing() then
        self.navigationTree:RefreshVisible()
    else
        self.isDirty = true
    end
    MAIN_MENU_KEYBOARD:RefreshCategoryBar()
    MAIN_MENU_KEYBOARD:UpdateSceneGroupButtons("marketSceneGroup")
end

function ZO_GiftInventory_Keyboard_OnInitialized(self)
    GIFT_INVENTORY_KEYBOARD = ZO_GiftInventory_Keyboard:New(self)
end