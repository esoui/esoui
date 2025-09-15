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