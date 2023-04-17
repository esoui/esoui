--------------------------
-- Tribute Rewards List --
--------------------------

ZO_TributeRewardsList_Keyboard = ZO_SortFilterList:Subclass()

function ZO_TributeRewardsList_Keyboard:Initialize(control, ...)
    ZO_SortFilterList.Initialize(self, control, ...)

    local function RowSetup(control, data, list)
        control.data = data

        local iconTexture = control:GetNamedChild("Icon")
        local nameLabel = control:GetNamedChild("Name")
        local rewardsNameLabel = control:GetNamedChild("RewardsName")

        iconTexture:SetTexture(data:GetTierIcon())
        nameLabel:SetText(data:GetTierName())
        rewardsNameLabel:SetText(data:GetRewardListName())
        rewardsNameLabel:SetColor(data:GetRewardsTierColor())

        local statusHighlight = control:GetNamedChild("StatusHighlight")
        statusHighlight:SetHidden(not data:IsAttained())
    end

    local function RowHide(control)
        local statusHighlight = control:GetNamedChild("StatusHighlight")
        statusHighlight:SetHidden(true)
    end

    ZO_ScrollList_AddDataType(self.list, 1, "ZO_TributeRewards_Keyboard_Row", ZO_TRIBUTE_REWARD_KEYBOARD_ROW_HEIGHT, RowSetup, RowHide)

    self.automaticallyColorRows = false

    self.currentRewardsType = ZO_TRIBUTE_REWARD_TYPES.SEASON_REWARDS
end

function ZO_TributeRewardsList_Keyboard:SetRewardsType(rewardsTypeId)
    self.currentRewardsType = rewardsTypeId
end

function ZO_TributeRewardsList_Keyboard:GetRewardsType()
    return self.currentRewardsType
end

function ZO_TributeRewardsList_Keyboard:GetNumTiersForTributeRewardsType()
    return TRIBUTE_REWARDS_DATA_MANAGER:GetNumTiersForTributeRewardsType(self.currentRewardsType)
end

function ZO_TributeRewardsList_Keyboard:BuildMasterList()
    -- Update Header
    local rewardsTypeData = TRIBUTE_REWARDS_DATA_MANAGER:GetTributeRewardsTypeData(self.currentRewardsType)
    local tierHeaderLabel = self.control:GetNamedChild("HeadersTierName")
    tierHeaderLabel:SetText(rewardsTypeData:GetTierHeader())

    -- Build list content
    ZO_ScrollList_Clear(self.list)
    local scrollData = ZO_ScrollList_GetDataList(self.list)

    for _, tributeRewardsData in TRIBUTE_REWARDS_DATA_MANAGER:TributeRewardsTypeIterator(self.currentRewardsType) do
        table.insert(scrollData, ZO_ScrollList_CreateDataEntry(1, tributeRewardsData))
    end

    ZO_ScrollList_Commit(self.list)
end

function ZO_TributeRewardsList_Keyboard:FilterScrollList()
    -- Must be overridden
    -- TODO Tribute: Determine if data needs to be filtered
end

function ZO_TributeRewardsList_Keyboard:SortScrollList()
    -- Must be overridden
    -- TODO Tribute: Determine if data needs to be sorted
end

function ZO_TributeRewardsList_Keyboard:EnterRow(row)
    ZO_SortFilterList.EnterRow(self, row)

    ZO_InventorySlot_SetHighlightHidden(row, false)

    local rewardType = row.data:GetRewardsType()
    local rewardListId = row.data:GetRewardListId()
    if rewardListId ~= 0 then
        InitializeTooltip(InformationTooltip, row, RIGHT, 0, 0, LEFT)
        if rewardType:GetRewardsTypeId() == ZO_TRIBUTE_REWARD_TYPES.SEASON_REWARDS then
            InformationTooltip:SetTributeSeasonRewardList(row.data:GetRewardsTierId(), rewardListId)
        else
            InformationTooltip:SetTributeLeaderboardRewardList(rewardListId)
        end
    end
end

function ZO_TributeRewardsList_Keyboard:ExitRow(row)
    ZO_SortFilterList.ExitRow(self, row)

    local iconTexture = row:GetNamedChild("Icon")
    ZO_InventorySlot_SetHighlightHidden(row, true)

    ClearTooltip(InformationTooltip)
end

----------------------------
-- Tribute Rewards Dialog --
----------------------------

function ZO_TributeRewardsDialog_OnInitialized(control)
    local function Factory(objectPool)
        local listControl = ZO_ObjectPool_CreateControl("ZO_TributeRewardListTemplate_Keyboard", objectPool, control)
        local listObject = ZO_TributeRewardsList_Keyboard:New(listControl, control, canSelectLocked)
        listObject.control = listControl
        return listObject
    end

    local function Reset(listObject)
        ZO_ObjectPool_DefaultResetControl(listObject.control)
    end
    control.tributeRewardsDialogListPool = ZO_ObjectPool:New(Factory, Reset)
    control.tributeRewardsDialogDividerPool = ZO_ControlPool:New("ZO_DialogDivider", control, "Divider")

    local function TributeRewardsDialogSetup(dialog)
        control.tributeRewardsDialogListPool:ReleaseAllObjects()
        control.tributeRewardsDialogDividerPool:ReleaseAllObjects()

        local insertDivider = false
        local parentControl = control:GetNamedChild("Container")
        local anchorControl = parentControl
        for i, type in ipairs(ZO_TRIBUTE_REWARD_TYPE_LIST) do
            if insertDivider then
                local dividerControl = control.tributeRewardsDialogDividerPool:AcquireObject()
                dividerControl:ClearAnchors()
                dividerControl:SetAnchor(TOPLEFT, anchorControl, BOTTOMLEFT)
                dividerControl:SetAnchor(TOPRIGHT, anchorControl, BOTTOMRIGHT, 0, 10)
                anchorControl = dividerControl
            end

            local listObject = control.tributeRewardsDialogListPool:AcquireObject()
            listObject.control:SetHidden(false)
            listObject.control:SetParent(parentControl)
            listObject.control:ClearAnchors()
            listObject.control:SetAnchor(TOP, anchorControl, TOP, 0, insertDivider and 20 or 0)
            anchorControl = listObject.control
            insertDivider = true

            listObject:SetRewardsType(type)
            local count = listObject:GetNumTiersForTributeRewardsType()
            local listObjectListControl = listObject.control:GetNamedChild("List")
            listObjectListControl:SetHeight(count * ZO_TRIBUTE_REWARD_KEYBOARD_ROW_HEIGHT)
            listObject:BuildMasterList()
            listObject:RefreshData()
        end
    end

    ZO_Dialogs_RegisterCustomDialog("TRIBUTE_REWARDS_VIEW",
    {
        customControl = control,
        setup = TributeRewardsDialogSetup,
        title =
        {
            text = SI_TRIBUTE_FINDER_REWARDS_TITLE,
        },
        buttons =
        {
            {
                control = control:GetNamedChild("Close"),
                text = SI_DIALOG_CLOSE,
            },
        }
    })
end

function ZO_TributeRewardsDialog_Row_OnMouseEnter(control)
    local listObject = control:GetParent():GetParent():GetParent().object
    listObject:Row_OnMouseEnter(control)
end

function ZO_TributeRewardsDialog_Row_OnMouseExit(control)
    local listObject = control:GetParent():GetParent():GetParent().object
    listObject:Row_OnMouseExit(control)
end

function ZO_TributeRewardsDialog_Info_OnMouseEnter(control)
    local rewardsType = control:GetParent():GetParent().object:GetRewardsType()
    local rewardsTypeData = TRIBUTE_REWARDS_DATA_MANAGER:GetTributeRewardsTypeData(rewardsType)

    InitializeTooltip(InformationTooltip, control, RIGHT, 0, 0, LEFT)
    InformationTooltip:AddLine(rewardsTypeData:GetDescription(), "", ZO_NORMAL_TEXT:UnpackRGB())
end

function ZO_TributeRewardsDialog_Info_OnMouseExit(control)
   ClearTooltip(InformationTooltip)
end