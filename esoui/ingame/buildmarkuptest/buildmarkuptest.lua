
assert(not BuildMarkupTest)
assert(not IsInternalBuild())
function BuildMarkupTest()
    d("Public")
    local control = CreateControlFromVirtual("BuildMarkupTestControl", nil, "BuildMarkupTestTemplate")
    assert(control)
end

















