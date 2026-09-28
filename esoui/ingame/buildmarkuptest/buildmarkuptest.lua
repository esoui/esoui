
assert(not BuildMarkupTest)
if not ShouldLoadPublicTags or ShouldLoadPublicTags() == false then
    assert(not IsInternalBuild())
end
function BuildMarkupTest()
    d("Public")
    local control = CreateControlFromVirtual("BuildMarkupTestControl", nil, "BuildMarkupTestTemplate")
    assert(control)
end

















