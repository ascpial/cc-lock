local function main()
    local pullEvent_old = os.pullEvent
    os.pullEvent = os.pullEventRaw

    if not fs.exists("credentials") then
        print("Use the register command to lock the computer.")
    else
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
end

shell.setDir("/")
package.path = "/cc-lock/"
local shield = require("shield")
shield(main)
shell.setDir("/startup")