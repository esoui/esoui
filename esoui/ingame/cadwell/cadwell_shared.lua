function ZO_CadwellSort(entry1, entry2)
    if entry1.order == entry2.order then
        return entry1.name < entry2.name
    else
        return entry1.order < entry2.order
    end
end
