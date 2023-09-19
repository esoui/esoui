ZO_HELP_TICKET_FIELD_TYPE =
{
    IMPACT =  1,
    CATEGORY = 2,
    SUBCATEGORY = 3,
    DETAILS = 4,
    EXTERNAL_INFO = 5,
    DESCRIPTION = 6,
    ATTACH_SCREENSHOT = 7,
    SUBMIT = 8,
}

ZO_HELP_SUBMIT_FEEDBACK_FIELD_DATA =
{
    [ZO_HELP_TICKET_FIELD_TYPE.IMPACT] =
    {
        enumStringPrefix = "SI_CUSTOMERSERVICESUBMITFEEDBACKIMPACTS",
        iterationBegin = CUSTOMER_SERVICE_SUBMIT_FEEDBACK_IMPACT_ITERATION_BEGIN,
        iterationEnd = CUSTOMER_SERVICE_SUBMIT_FEEDBACK_IMPACT_ITERATION_END,
        invalidEntry = CUSTOMER_SERVICE_SUBMIT_FEEDBACK_IMPACT_NONE,
    },
    [ZO_HELP_TICKET_FIELD_TYPE.CATEGORY] =
    {
        enumStringPrefix = "SI_CUSTOMERSERVICESUBMITFEEDBACKCATEGORIES",
        universallyAddEnum = CUSTOMER_SERVICE_SUBMIT_FEEDBACK_SUBCATEGORY_NONE,
        iterationBegin = CUSTOMER_SERVICE_SUBMIT_FEEDBACK_CATEGORY_ITERATION_BEGIN + 1,
        iterationEnd = CUSTOMER_SERVICE_SUBMIT_FEEDBACK_CATEGORY_ITERATION_END,
        sortFunction = function(left, right)
            return left.name < right.name
        end,
        invalidEntry = CUSTOMER_SERVICE_SUBMIT_FEEDBACK_CATEGORY_NONE,
    },
    [ZO_HELP_TICKET_FIELD_TYPE.SUBCATEGORY] =
    {
        enumStringPrefix = "SI_CUSTOMERSERVICESUBMITFEEDBACKSUBCATEGORIES",
        universallyAddEnum = CUSTOMER_SERVICE_SUBMIT_FEEDBACK_SUBCATEGORY_NONE,
        otherEnum = CUSTOMER_SERVICE_SUBMIT_FEEDBACK_SUBCATEGORY_OTHER,
        categoryContextualData = 
        {
            [CUSTOMER_SERVICE_SUBMIT_FEEDBACK_CATEGORY_ALLIANCE_WAR] =
            {
                iterationBegin = CUSTOMER_SERVICE_SUBMIT_FEEDBACK_SUBCATEGORY_ALLIANCE_WAR_1,
                iterationEnd = CUSTOMER_SERVICE_SUBMIT_FEEDBACK_SUBCATEGORY_ALLIANCE_WAR_END - 1,
            },
            [CUSTOMER_SERVICE_SUBMIT_FEEDBACK_CATEGORY_AUDIO] =
            {
                iterationBegin = CUSTOMER_SERVICE_SUBMIT_FEEDBACK_SUBCATEGORY_AUDIO_1,
                iterationEnd = CUSTOMER_SERVICE_SUBMIT_FEEDBACK_SUBCATEGORY_AUDIO_END - 1,
            },
            [CUSTOMER_SERVICE_SUBMIT_FEEDBACK_CATEGORY_CRAFTING] =
            {
                iterationBegin = CUSTOMER_SERVICE_SUBMIT_FEEDBACK_SUBCATEGORY_CRAFTING_1,
                iterationEnd = CUSTOMER_SERVICE_SUBMIT_FEEDBACK_SUBCATEGORY_CRAFTING_END - 1,
            },
            [CUSTOMER_SERVICE_SUBMIT_FEEDBACK_CATEGORY_COMBAT] =
            {
                iterationBegin = CUSTOMER_SERVICE_SUBMIT_FEEDBACK_SUBCATEGORY_COMBAT_1,
                iterationEnd = CUSTOMER_SERVICE_SUBMIT_FEEDBACK_SUBCATEGORY_COMBAT_END - 1,
            },
            [CUSTOMER_SERVICE_SUBMIT_FEEDBACK_CATEGORY_ITEMS] =
            {
                iterationBegin = CUSTOMER_SERVICE_SUBMIT_FEEDBACK_SUBCATEGORY_ITEMS_1,
                iterationEnd = CUSTOMER_SERVICE_SUBMIT_FEEDBACK_SUBCATEGORY_ITEMS_END - 1,
                detailsTitle = GetString(SI_CUSTOMER_SERVICE_ITEM_NAME),
            },
            [CUSTOMER_SERVICE_SUBMIT_FEEDBACK_CATEGORY_CROWN_STORE] =
            {
                iterationBegin = CUSTOMER_SERVICE_SUBMIT_FEEDBACK_SUBCATEGORY_CROWN_STORE_1,
                iterationEnd = CUSTOMER_SERVICE_SUBMIT_FEEDBACK_SUBCATEGORY_CROWN_STORE_END - 1,
            },
            [CUSTOMER_SERVICE_SUBMIT_FEEDBACK_CATEGORY_GRAPHICS] =
            {
                iterationBegin = CUSTOMER_SERVICE_SUBMIT_FEEDBACK_SUBCATEGORY_GRAPHICS_1,
                iterationEnd = CUSTOMER_SERVICE_SUBMIT_FEEDBACK_SUBCATEGORY_GRAPHICS_END - 1,
            },
            [CUSTOMER_SERVICE_SUBMIT_FEEDBACK_CATEGORY_QUESTS] =
            {
                iterationBegin = CUSTOMER_SERVICE_SUBMIT_FEEDBACK_SUBCATEGORY_QUESTS_1,
                iterationEnd = CUSTOMER_SERVICE_SUBMIT_FEEDBACK_SUBCATEGORY_QUESTS_END - 1,
                detailsTitle = GetString(SI_CUSTOMER_SERVICE_QUEST_NAME),
            },
            [CUSTOMER_SERVICE_SUBMIT_FEEDBACK_CATEGORY_TEXT] =
            {
                iterationBegin = CUSTOMER_SERVICE_SUBMIT_FEEDBACK_SUBCATEGORY_TEXT_1,
                iterationEnd = CUSTOMER_SERVICE_SUBMIT_FEEDBACK_SUBCATEGORY_TEXT_END - 1,
            },
            [CUSTOMER_SERVICE_SUBMIT_FEEDBACK_CATEGORY_DUNGEONS] =
            {
                iterationBegin = CUSTOMER_SERVICE_SUBMIT_FEEDBACK_SUBCATEGORY_DUNGEONS_1,
                iterationEnd = CUSTOMER_SERVICE_SUBMIT_FEEDBACK_SUBCATEGORY_DUNGEONS_END - 1,
            },
            [CUSTOMER_SERVICE_SUBMIT_FEEDBACK_CATEGORY_HOUSING] =
            {
                iterationBegin = CUSTOMER_SERVICE_SUBMIT_FEEDBACK_SUBCATEGORY_HOUSING_1,
                iterationEnd = CUSTOMER_SERVICE_SUBMIT_FEEDBACK_SUBCATEGORY_HOUSING_END - 1,
            },
            [CUSTOMER_SERVICE_SUBMIT_FEEDBACK_CATEGORY_JUSTICE] =
            {
                iterationBegin = CUSTOMER_SERVICE_SUBMIT_FEEDBACK_SUBCATEGORY_JUSTICE_1,
                iterationEnd = CUSTOMER_SERVICE_SUBMIT_FEEDBACK_SUBCATEGORY_JUSTICE_END - 1,
            },
            [CUSTOMER_SERVICE_SUBMIT_FEEDBACK_CATEGORY_PERFORMANCE] =
            {
                iterationBegin = CUSTOMER_SERVICE_SUBMIT_FEEDBACK_SUBCATEGORY_PERFORMANCE_1,
                iterationEnd = CUSTOMER_SERVICE_SUBMIT_FEEDBACK_SUBCATEGORY_PERFORMANCE_END - 1,
            },
            [CUSTOMER_SERVICE_SUBMIT_FEEDBACK_CATEGORY_UI] =
            {
                iterationBegin = CUSTOMER_SERVICE_SUBMIT_FEEDBACK_SUBCATEGORY_UI_1,
                iterationEnd = CUSTOMER_SERVICE_SUBMIT_FEEDBACK_SUBCATEGORY_UI_END - 1,
            },
        },
        invalidEntry = CUSTOMER_SERVICE_SUBMIT_FEEDBACK_SUBCATEGORY_NONE,
    },
}

ZO_HELP_ASK_FOR_HELP_CATEGORY_INFO =
{
    impactStringName = "SI_CUSTOMERSERVICEASKFORHELPIMPACT",
    impacts =
    {
        {
            id = CUSTOMER_SERVICE_ASK_FOR_HELP_IMPACT_NONE,
        },
        {
            id = CUSTOMER_SERVICE_ASK_FOR_HELP_IMPACT_CHARACTER_ISSUE,
            categoryStringName = "SI_CUSTOMERSERVICEASKFORHELPCHARACTERISSUECATEGORY",
            categoryDescriptionStringName = "SI_CUSTOMERSERVICEASKFORHELPCHARACTERISSUECATEGORY_DESCRIPTION",
            categories =
            {
                {
                    id = CUSTOMER_SERVICE_ASK_FOR_HELP_CHARACTER_ISSUE_CATEGORY_NONE,
                },
                {
                    id = CUSTOMER_SERVICE_ASK_FOR_HELP_CHARACTER_ISSUE_CATEGORY_CHARACTER_RESTORATION,
                    ticketCategory = 891,
                },
                {
                    id = CUSTOMER_SERVICE_ASK_FOR_HELP_CHARACTER_ISSUE_CATEGORY_GROUP_ACTIVITIES,
                    ticketCategory = 978,
                },
                {
                    id = CUSTOMER_SERVICE_ASK_FOR_HELP_CHARACTER_ISSUE_CATEGORY_CHAT_AND_VENDORS,
                    ticketCategory = 1186,
                },
                {
                    id = CUSTOMER_SERVICE_ASK_FOR_HELP_CHARACTER_ISSUE_CATEGORY_SKILLS_AND_ACHIEVEMENTS,
                    ticketCategory = 893,
                },
            },
        },
        {
            id = CUSTOMER_SERVICE_ASK_FOR_HELP_IMPACT_REPORT_PLAYER,
            detailsTitle = GetString(SI_CUSTOMER_SERVICE_ASK_FOR_HELP_PLAYER_NAME),
            detailsRegistrationFunction = SetCustomerServiceTicketPlayerTarget,
            detailsRegistrationFormatText = ZO_FormatManualNameEntry,
            detailsGamepadDefaultText = zo_strformat(SI_GAMEPAD_HELP_TICKET_EDIT_REQUIRED_NAME_DISPLAY, ZO_GetPlatformAccountLabel()),
            categoryStringName = "SI_CUSTOMERSERVICEASKFORHELPREPORTPLAYERCATEGORY",
            categories = 
            {
                {
                    id = CUSTOMER_SERVICE_ASK_FOR_HELP_REPORT_PLAYER_CATEGORY_NONE,
                },
                {
                    id = CUSTOMER_SERVICE_ASK_FOR_HELP_REPORT_PLAYER_CATEGORY_REAL_WORLD_THREATS,
                    subcategoryStringName = "SI_CUSTOMERSERVICEASKFORHELPREPORTPLAYERSUBCATEGORY",
                    subcategoryDescriptionStringName = "SI_CUSTOMERSERVICEASKFORHELPREPORTPLAYERSUBCATEGORY_DESCRIPTION",
                    subcategories =
                    {
                        {
                            id = CUSTOMER_SERVICE_ASK_FOR_HELP_REPORT_PLAYER_SUBCATEGORY_NONE,
                        },
                        {
                            id = CUSTOMER_SERVICE_ASK_FOR_HELP_REPORT_PLAYER_SUBCATEGORY_CHILD_ABUSE,
                            ticketCategory = 1244
                        },
                        {
                            id = CUSTOMER_SERVICE_ASK_FOR_HELP_REPORT_PLAYER_SUBCATEGORY_TERRORISM,
                            ticketCategory = 1245
                        },
                        {
                            id = CUSTOMER_SERVICE_ASK_FOR_HELP_REPORT_PLAYER_SUBCATEGORY_SELF_HARM,
                            ticketCategory = 1246
                        },
                        {
                            id = CUSTOMER_SERVICE_ASK_FOR_HELP_REPORT_PLAYER_SUBCATEGORY_HARM_TO_OTHERS,
                            ticketCategory = 1247
                        },
                    }
                },
                {
                    id = CUSTOMER_SERVICE_ASK_FOR_HELP_REPORT_PLAYER_CATEGORY_BAD_LANGUAGE,
                    subcategoryStringName = "SI_CUSTOMERSERVICEASKFORHELPREPORTPLAYERSUBCATEGORY",
                    subcategoryDescriptionStringName = "SI_CUSTOMERSERVICEASKFORHELPREPORTPLAYERSUBCATEGORY_DESCRIPTION",
                    subcategories =
                    {
                        {
                            id = CUSTOMER_SERVICE_ASK_FOR_HELP_REPORT_PLAYER_SUBCATEGORY_NONE,
                        },
                        {
                            id = CUSTOMER_SERVICE_ASK_FOR_HELP_REPORT_PLAYER_SUBCATEGORY_HATE_SPEECH,
                            ticketCategory = 1249
                        },
                        {
                            id = CUSTOMER_SERVICE_ASK_FOR_HELP_REPORT_PLAYER_SUBCATEGORY_TROLLING,
                            ticketCategory = 1250
                        },
                        {
                            id = CUSTOMER_SERVICE_ASK_FOR_HELP_REPORT_PLAYER_SUBCATEGORY_SPAM,
                            ticketCategory = 1251
                        },
                        {
                            id = CUSTOMER_SERVICE_ASK_FOR_HELP_REPORT_PLAYER_SUBCATEGORY_PROFANE_VOICE_CHAT,
                            ticketCategory = 1252
                        },
                        {
                            id = CUSTOMER_SERVICE_ASK_FOR_HELP_REPORT_PLAYER_SUBCATEGORY_PROFANE_NAME,
                            ticketCategory = 11,
                            nameStringArgs = { ZO_GetPlatformAccountLabel() },
                            descriptionStringArgs = { ZO_GetPlatformAccountLabel() },
                        },
                    }
                },
                {
                    id = CUSTOMER_SERVICE_ASK_FOR_HELP_REPORT_PLAYER_CATEGORY_BAD_ACTIONS,
                    subcategoryStringName = "SI_CUSTOMERSERVICEASKFORHELPREPORTPLAYERSUBCATEGORY",
                    subcategoryDescriptionStringName = "SI_CUSTOMERSERVICEASKFORHELPREPORTPLAYERSUBCATEGORY_DESCRIPTION",
                    subcategories =
                    {
                        {
                            id = CUSTOMER_SERVICE_ASK_FOR_HELP_REPORT_PLAYER_SUBCATEGORY_NONE,
                        },
                        {
                            id = CUSTOMER_SERVICE_ASK_FOR_HELP_REPORT_PLAYER_SUBCATEGORY_SCAMMING,
                            ticketCategory = 1254
                        },
                        {
                            id = CUSTOMER_SERVICE_ASK_FOR_HELP_REPORT_PLAYER_SUBCATEGORY_DOXING,
                            ticketCategory = 1255
                        },
                        {
                            id = CUSTOMER_SERVICE_ASK_FOR_HELP_REPORT_PLAYER_SUBCATEGORY_CHEATING,
                            ticketCategory = 361
                        },
                        {
                            id = CUSTOMER_SERVICE_ASK_FOR_HELP_REPORT_PLAYER_SUBCATEGORY_HARASSMENT,
                            ticketCategory = 12
                        },
                    }
                },
            },
        },
        {
            id = CUSTOMER_SERVICE_ASK_FOR_HELP_IMPACT_REPORT_GUILD,
            detailsTitle = GetString(SI_CUSTOMER_SERVICE_ASK_FOR_HELP_GUILD_NAME),
            detailsRegistrationFunction = SetCustomerServiceTicketPlayerTarget,
            detailsRegistrationFormatText = ZO_FormatManualNameEntry,
            detailsGamepadDefaultText = GetString(SI_GAMEPAD_HELP_TICKET_EDIT_REQUIRED_NAME_GUILD),
            categoryStringName = "SI_CUSTOMERSERVICEASKFORHELPREPORTGUILDCATEGORY",
            categoryDescriptionStringName = "SI_CUSTOMERSERVICEASKFORHELPREPORTGUILDCATEGORY_DESCRIPTION",
            categories =
            {
                {
                    id = CUSTOMER_SERVICE_ASK_FOR_HELP_REPORT_GUILD_CATEGORY_NONE,
                },
                {
                    id = CUSTOMER_SERVICE_ASK_FOR_HELP_REPORT_GUILD_CATEGORY_INAPPROPRIATE_NAME,
                    ticketCategory = 1193,
                },
                {
                    id = CUSTOMER_SERVICE_ASK_FOR_HELP_REPORT_GUILD_CATEGORY_INAPPROPRIATE_LISTING,
                    ticketCategory = 1195,
                },
                {
                    id = CUSTOMER_SERVICE_ASK_FOR_HELP_REPORT_GUILD_CATEGORY_INAPPROPRIATE_DECLINE,
                    ticketCategory = 1194,
                },
            },
        },
        {
            id = CUSTOMER_SERVICE_ASK_FOR_HELP_IMPACT_REPORT_GROUP_FINDER_LISTING,
            externalInfoTitle = GetString(SI_CUSTOMER_SERVICE_ASK_FOR_HELP_GROUP_FINDER_LISTING_DETAILS),
            externalInfoInstructions = GetString(SI_CUSTOMER_SERVICE_ASK_FOR_HELP_GROUP_FINDER_LISTING_INSTRUCTIONS),
            externalInfoRegistrationFunction = ZO_HELP_GENERIC_TICKET_SUBMISSION_MANAGER.SetCustomerServiceTicketGroupFinderListingTarget,
            externalInfoKeyboardTooltipFunction = function(...) HELP_CUSTOMER_SERVICE_ASK_FOR_HELP_KEYBOARD:ShowGroupFinderListingTooltip(...) end,
            externalInfoGamepadTooltipFunction = function(...) HELP_CUSTOMER_SERVICE_GAMEPAD:ShowGroupFinderListingTooltip(...) end,
            categoryStringName = "SI_CUSTOMERSERVICEASKFORHELPREPORTGROUPFINDERLISTINGCATEGORY",
            categoryDescriptionStringName = "SI_CUSTOMERSERVICEASKFORHELPREPORTGROUPFINDERLISTINGCATEGORY_DESCRIPTION",
            categories =
            {
                {
                    id = CUSTOMER_SERVICE_ASK_FOR_HELP_REPORT_GROUP_FINDER_LISTING_CATEGORY_NONE,
                },
                {
                    id = CUSTOMER_SERVICE_ASK_FOR_HELP_REPORT_GROUP_FINDER_LISTING_CATEGORY_INAPPROPRIATE_TITLE,
                    ticketCategory = 1315,
                },
                {
                    id = CUSTOMER_SERVICE_ASK_FOR_HELP_REPORT_GROUP_FINDER_LISTING_CATEGORY_INAPPROPRIATE_DESCRIPTION,
                    ticketCategory = 1314,
                },
            },
        },
    },
}

function ZO_GetAskForHelpListEntryName(listStringName, entryData)
    local entryName = GetString(listStringName, entryData.id)
    local stringArgs = entryData.nameStringArgs
    if stringArgs then
        if type(stringArgs) == "function" then
            stringArgs = stringArgs()
        end
        entryName = zo_strformat(entryName, unpack(stringArgs))
    end
    return entryName
end

function ZO_GetAskForHelpListEntryDescription(listDescriptionStringName, entryData)
    if listDescriptionStringName then
        local entryDescription = GetString(listDescriptionStringName, entryData.id)
        if entryDescription and entryDescription ~= "" then
            local stringArgs = entryData.descriptionStringArgs
            if stringArgs then
                if type(stringArgs) == "function" then
                    stringArgs = stringArgs()
                end
                entryDescription = zo_strformat(entryDescription, unpack(stringArgs))
            end
            return entryDescription
        end
    end
    return nil
end