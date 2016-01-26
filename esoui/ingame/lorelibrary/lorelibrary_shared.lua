function ZO_LoreLibrary_ReadBook(categoryIndex, collectionIndex, bookIndex)
    local title = GetLoreBookInfo(categoryIndex, collectionIndex, bookIndex)
    local body, medium, showTitle = ReadLoreBook(categoryIndex, collectionIndex, bookIndex)
    LORE_READER:Show(title, body, medium, showTitle, "loreLibrary")
end