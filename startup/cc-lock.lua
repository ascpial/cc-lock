local function main()
    local pullEvent_old = os.pullEvent
    os.pullEvent = os.pullEventRaw

    if not fs.exists("credentials") then
        print("Use the register command to lock the computer.")
    else
        local auth_manager = require("cc-lock.auth")

        local authWindow = auth_manager:new()
        
        authWindow:start()
        
        if not authWindow.authentificated then
            os.shutdown()
        else
            print("Welcome!")
            os.pullEvent = pullEvent_old
        end
    end
end

shell.setDir("/")
local shield = require("/cc-lock.shield")
shield(main)
shell.setDir("/startup")