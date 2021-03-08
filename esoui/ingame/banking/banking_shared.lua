ZO_Banking_Shared = ZO_InitializingObject:Subclass()

function ZO_Banking_Shared:Initialize(control)
    local bankFilterTargetDescriptor =
    {
        [BACKGROUND_LIST_FILTER_TARGET_BAG_SLOT] =
        {
            searchFilterList =
            {
                BACKGROUND_LIST_FILTER_TYPE_NAME,
            },
            primaryKeys =
            {
                BAG_BACKPACK,
                BAG_BANK,
                BAG_SUBSCRIBER_BANK,
            }
        },
    }
    TEXT_SEARCH_MANAGER:SetupContextTextSearch("playerBankTextSearch", bankFilterTargetDescriptor)

    local houseBankFilterTargetDescriptor =
    {
        [BACKGROUND_LIST_FILTER_TARGET_BAG_SLOT] =
        {
            searchFilterList =
            {
                BACKGROUND_LIST_FILTER_TYPE_NAME,
            },
            primaryKeys = function()
                local bankingBag = GetBankingBag()
                if IsHouseBankBag(bankingBag) then
                    return { BAG_BACKPACK, bankingBag }
                end
                return {}
            end,
        },
    }
    TEXT_SEARCH_MANAGER:SetupContextTextSearch("houseBankTextSearch", houseBankFilterTargetDescriptor)

    local guildBankFilterTargetDescriptor =
    {
        [BACKGROUND_LIST_FILTER_TARGET_BAG_SLOT] =
        {
            searchFilterList =
            {
                BACKGROUND_LIST_FILTER_TYPE_NAME,
            },
            primaryKeys =
            {
                BAG_BACKPACK,
                BAG_GUILDBANK,
            }
        },
    }
    TEXT_SEARCH_MANAGER:SetupContextTextSearch("guildBankTextSearch", guildBankFilterTargetDescriptor)
end

ZO_BANKING_SHARED = ZO_Banking_Shared:New()