local function main()
    local pullEvent_old = os.pullEvent
    os.pullEvent = os.pullEventRaw
    
    local auth_manager = require("auth")

    local authWindow = auth_manager:new()
    
    authWindow:start()
    
    if not authWindow.authentificated then
        os.shutdown()
    else
        print("Welcome!")
        os.pullEvent = pullEvent_old
    end
end

if not fs.exists("credentials") then
    print("Use the register command to lock the computer.")
else
    shell.setDir("/")
    package.path = "/cc-lock/?;/cc-lock/?.lua;/?;/?.lua;/?/init.lua;" .. package.path
    local shield = require("shield")
    shield(main)
end