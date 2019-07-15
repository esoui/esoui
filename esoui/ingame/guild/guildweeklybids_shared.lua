local BID_DATA = 1

ZO_GuildWeeklyBids_Shared = ZO_Object:Subclass()

ZO_GUILD_WEEKLY_BIDS_SORT_KEYS =
{
    order = { isNumeric = true },
    kioskName = {},
    displayName = { tieBreaker = "order" },
    bidAmount = { isNumeric = true , tieBreaker = "order" },
}

function ZO_GuildWeeklyBids_Shared:New(...)
   local object = ZO_Object.New(self)
   object:Initialize(...)
   return object 
end

function ZO_GuildWeeklyBids_Shared:Initialize(bidRowTemplate, bidRowTemplateHeight)
    local listControl = self:GetListControl()
    ZO_ScrollList_AddDataType(listControl, BID_DATA, bidRowTemplate, bidRowTemplateHeight, function(control, data) self:SetupBidRow(control, data) end)
    self.sortHeaderGroup:SelectHeaderByKey("order")

    self.control:RegisterForEvent(EVENT_GUILD_KIOSK_ACTIVE_BIDS_RESPONSE, function(_, ...) self:OnGuildKioskActiveBidsResponse(...) end)

    self.sortFunction = function(listEntry1, listEntry2)
        return ZO_TableOrderingFunction(listEntry1.data, listEntry2.data, self.currentSortKey, ZO_GUILD_WEEKLY_BIDS_SORT_KEYS, self.currentSortOrder)
    end
end

local function CompareBids(a, b)
    if a.bidAmount == b.bidAmount then
        return a.timeSinceBidAtDataSetupS > b.timeSinceBidAtDataSetupS
    else
        return a.bidAmount > b.bidAmount
    end
end

function ZO_GuildWeeklyBids_Shared:BuildMasterList()
    self.masterList = {}
    for i = 1, GetNumGuildKioskActiveBids(self.guildId) do
        local timeSinceBidS, bidAmount, kioskName, bidderDisplayName = GetGuildKioskActiveBidInfo(self.guildId, i)
        table.insert(self.masterList,
        {
            bidAmount = bidAmount,
            kioskName = kioskName,
            displayName = bidderDisplayName,
            timeSinceBidAtDataSetupS = timeSinceBidS,
        })
    end
    table.sort(self.masterList, CompareBids)
    for i, bid in ipairs(self.masterList) do
        bid.order = i
    end

    local listControl = self:GetListControl()
    ZO_ScrollList_Clear(listControl)
    local scrollDataList = ZO_ScrollList_GetDataList(listControl)
    for i, bid in ipairs(self.masterList) do
        table.insert(scrollDataList, ZO_ScrollList_CreateDataEntry(BID_DATA, bid))
    end
end

function ZO_GuildWeeklyBids_Shared:SortScrollList()
    local listControl = self:GetListControl()
    local scrollDataList = ZO_ScrollList_GetDataList(listControl)
    table.sort(scrollDataList, self.sortFunction)
end

function ZO_GuildWeeklyBids_Shared:SetupBidRow(control, data)
    self:SetupRow(control, data)
    control:GetNamedChild("Order"):SetText(data.order)
    control:GetNamedChild("Trader"):SetText(data.kioskName)
    control:GetNamedChild("PlacedBy"):SetText(ZO_FormatUserFacingDisplayName(data.displayName))
    control:GetNamedChild("BidAmount"):SetText(ZO_Currency_FormatPlatform(CURT_MONEY, data.bidAmount, ZO_CURRENCY_FORMAT_WHITE_AMOUNT_ICON))
end

function ZO_GuildWeeklyBids_Shared:TryQueryNewInformation()
    local initialResult = RequestGuildKioskActiveBids(self.guildId)
    if initialResult == SOCIAL_RESULT_NO_ERROR then
        self:SetWeeklyBidLimitText("--")
        self:SetEmptyText(GetString(SI_GUILD_WEEKLY_BIDS_WAITING))
        local listControl = self:GetListControl()
        ZO_ScrollList_Clear(listControl)
        self:CommitScrollList()
    elseif initialResult == SOCIAL_RESULT_REQUEST_ON_COOLDOWN then
        self:OnGuildKioskActiveBidsResponse(self.guildId)
    end
end

function ZO_GuildWeeklyBids_Shared:OnGuildKioskActiveBidsResponse(guildId)
    if self.guildId == guildId then
        self:OnWeeklyBidsDataReady()
    end
end

function ZO_GuildWeeklyBids_Shared:OnWeeklyBidsDataReady()
    self:SetEmptyText(GetString(SI_GUILD_WEEKLY_BIDS_NONE_ACTIVE))

    local maxBids = GetMaxKioskBidsPerGuild()
    local weeklyBidsAmount = ZO_FormatFraction(GetNumGuildKioskActiveBids(self.guildId), GetMaxKioskBidsPerGuild())
    self:SetWeeklyBidLimitText(weeklyBidsAmount)
    self:RefreshData()
end

function ZO_GuildWeeklyBids_Shared:SetWeeklyBidLimitText(text)
    --Needs to be overridden to update the weekly bid limit display 
end