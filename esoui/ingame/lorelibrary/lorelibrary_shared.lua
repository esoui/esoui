function ZO_LoreLibrary_ReadBook(categoryIndex, collectionIndex, bookIndex)
    local title, _, _, bookId = GetLoreBookInfo(categoryIndex, collectionIndex, bookIndex)
    local body, medium, showTitle = ReadLoreBook(categoryIndex, collectionIndex, bookIndex)
    local overrideImage, overrideImageTitlePosition = GetLoreBookOverrideImageFromBookId(bookId)
    LORE_READER:Show(title, body, medium, showTitle, overrideImage, overrideImageTitlePosition)
end