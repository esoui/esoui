EVENT_MANAGER = GetEventManager()


--App implementation of zo_mixin 
------------------------------

function zo_mixin(object, ...)
    for i = 1, select("#", ...) do
        local source = select(i, ...)
        for k,v in pairs(source) do
            object[k] = v
        end
    end
end

