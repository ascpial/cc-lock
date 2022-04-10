fs.makeDir("/cc-lock")
fs.makeDir("/startup")

local github_api = http.get("https://api.github.com/repos/ascpial/cc-lock/git/trees/main?recursive=1")
local list = textutils.unserialiseJSON(github_api.readAll())
local ls = {}
local len = 0
github_api.close()
for k,v in pairs(list.tree) do
    if v.type == "blob" and v.path:lower():match(".+%.lua") then
        ls["https://raw.githubusercontent.com/ascpial/cc-lock/main/"..v.path] = v.path
        len = len + 1
    end
end
local percent = 100/len
local finished = 0
for k,v in pairs(ls) do
    local web = http.get(k)
    local file = fs.open("/"..v,"w")
    file.write(web.readAll())
    file.close()
    web.close()
    finished = finished + 1
    print("downloading "..v.."  "..tostring(math.ceil(finished*percent)).."%")
end
print("Finished downloading cc-lock!")
print("Go to your root folder and type register to setup your login!")