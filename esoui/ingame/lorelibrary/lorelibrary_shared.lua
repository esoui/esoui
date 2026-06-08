function ZO_LoreLibrary_ReadBook(categoryIndex, collectionIndex, bookIndex)
    local title, _, _, bookId = GetLoreBookInfo(categoryIndex, collectionIndex, bookIndex)
    local body, medium, showTitle = ReadLoreBook(categoryIndex, collectionIndex, bookIndex)
    local overrideImage, overrideImageTitlePosition = GetLoreBookOverrideImageFromBookId(bookId)
    LORE_READER:Show(title, body, medium, showTitle, overrideImage, overrideImageTitlePosition)
end

function ZO_LoreLibrary_ReadHirelingCorrespondence(hirelingType, index)
    local _, subject, message = GetHirelingCorrespondenceInfoByIndex(hirelingType, index)
    local SHOW_TITLE = false
    local LETTER_MEDIUM = 4 -- The old enum value for BOOK_MEDIUM_LETTER (4) is now the def id for the equivalent medium
    LORE_READER:Show(subject, message, LETTER_MEDIUM, SHOW_TITLE)
end

function ZO_LoreLibrary_ReadMailFromMailList(mailListIndex, mailIndex)
    local _, subject, message = GetMailInfoFromMailList(mailListIndex, mailIndex)
    local SHOW_TITLE = false
    local LETTER_MEDIUM = 4 -- The old enum value for BOOK_MEDIUM_LETTER (4) is now the def id for the equivalent medium
    LORE_READER:Show(subject, message, LETTER_MEDIUM, SHOW_TITLE)
end

local function MailListSort(left, right)
    if left.type ~= right.type then
        return left.type < right.type
    end

    if left.name ~= right.name then
        return left.name < right.name
    end

    return left.mailListIndex < right.mailListIndex
end

function ZO_LoreLibrary_GetSortedMailLists()
    local mailLists = {}
    local numMailLists = GetNumMailLists()
    for mailListIndex = 1, numMailLists do
        local name = GetMailListName(mailListIndex)
        local type = GetMailListType(mailListIndex)
        local numUnlocked, total = GetNumUnlockedMailsInMailList(mailListIndex)
        local mailListInfo =
        {
            mailListIndex = mailListIndex,
            name = name,
            type = type,
            numUnlocked = numUnlocked,
            total = total,
        }

        table.insert(mailLists, mailListInfo)
    end

    table.sort(mailLists, MailListSort)

    return mailLists
end
