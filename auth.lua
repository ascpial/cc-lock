if not fs.exists("GuiH") then
    shell.run("wget run https://github.com/9551-Dev/Gui-h/raw/main/installer.lua")
end

local guih = require("GuiH")
local window_manager = require("cc-lock.window")
local sha1 = require("cc-lock.otp")("sha1")
local totp = require("cc-lock.otp")("totp")

AuthenticationWindow = {
    gui = nil,
    parentFrame = nil,
    frame = nil,
    running = true,
    window = nil,
    child = nil,
    input = {
        username = "username",
        password = "password",
    },
    globalScreen=nil,
    screen1 = nil,
    screen2 = nil,
    credentials={
        username="username",
        password="HASH",
        totpSecret="SECRET",
    },
    instanceTOTP=nil,
    authentificated=false,
}

function AuthenticationWindow:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self

    self.gui = guih.create_gui(term.current())
    local termWidth, termHeight = term.getSize()
    print(termHeight, termWidth)
    self.parentFrame, self.frame = window_manager.createWindow(
        self.gui,
        {
            width = 20, height=8,
            x=math.ceil(termWidth/2-10), y=math.ceil(termHeight/2-4),
            title="Login",
            on_quit = function() self.running = false end
        }
    )
    
    self.window = self.frame.window
    self.child = self.frame.child

    self.running = true

    self.credentials = {}

    self.authentificated=false

    return o
end

function AuthenticationWindow:loadCredentials(filename)
    filename = "credentials" or filename
    local file = fs.open(filename, 'r')
    self.credentials = textutils.unserialiseJSON(file.readAll())
    file.close()
end
function AuthenticationWindow:loadTOTP()
    self.instanceTOTP = totp.new(self.credentials.totpSecret, 6, "sha1", 30)
end

function AuthenticationWindow:blitAt(x, y, text, fg, bg)
    self.window.setCursorPos(x, y)
    if #fg == 1 then
        self.window.blit(text, (fg):rep(#text), (bg):rep(#text))
    else
        self.window.blit(text, fg, bg)
    end
end
function AuthenticationWindow:writeAt(x, y, text, fg, bg)
    self.window.setCursorPos(x, y)
    if fg ~= nil then
        self.window.setTextColor(fg)
    end
    if bg ~= nil then
        self.window.setBackgroundColor(bg)
    end
    self.window.write(text)
end
function AuthenticationWindow:clearContent()
    self.window.setBackgroundColor(colors.black)
    for line=1, 5 do
        self.window.setCursorPos(1, line)
        self.window.clearLine()
    end
end

function AuthenticationWindow:placeGlobalScreen()
    self.globalScreen = {}
    self.globalScreen.cancel = self.child.create.button({
        name="cancel",
        x=1, y=6, height=1, width=6,
        text=self.gui.text({
            text="Cancel",
            blit={"000000", "EEEEEE"},
        }),
        on_click = function() self.running = false end
    })
    self.globalScreen.login = self.child.create.button({
        name="login",
        x=14, y=6, height=1, width=5,
        text=self.gui.text({
            text="Login",
            blit={"00000", "DDDDD"},
        }),
        on_click=function() self:login() end
    })
end

function AuthenticationWindow:drawScreen1()
    self:writeAt(1, 1, "Username")
    self:writeAt(1, 3, "Password")
end
function AuthenticationWindow:placeScreen1()
    self.screen1 = {}
    self.screen1.username = self.child.create.inputbox({
        name="username",
        x=1, y=2, width=17,
        char_limit=10,
        selected=true,
        background_color=colors.gray,
    })
    self.screen1.password = self.child.create.inputbox({
        name="password",
        x=1, y=4, width=17,
        char_limit=math.huge,
        replace_char="*",
        background_color=colors.gray,
    })
    
end
function AuthenticationWindow:setScreen1()
    self:drawScreen1()
    self:placeScreen1()
end
function AuthenticationWindow:hideScreen1()
    for key, component in pairs(self.screen1) do
        component.visible = false
    end
    self:clearContent()
end

function AuthenticationWindow:drawScreen2()
    self:writeAt(1, 2, "Enter a TOTP code")
end
function AuthenticationWindow:placeScreen2()
    self.screen2 = {}
    self.screen2.totp = self.child.create.inputbox({
        name="totp",
        x=1, y=3, width=6,
        background_color=colors.gray,
        order=2,
    })
end
function AuthenticationWindow:setScreen2()
    self:drawScreen2()
    self:placeScreen2()
    self.globalScreen.login.on_click = function() self:totpCheck() end
end

function AuthenticationWindow:login()
    self:loadCredentials()
    self.input = {}
    self.input.username = self.screen1.username.input
    self.input.password = sha1.sha1(self.screen1.password.input)
    local file = fs.open("output", 'w')
    if self.input.username ~= self.credentials.username or self.input.password ~= self.credentials.password then
        self:writeAt(1, 5, "Wrong credentials", colors.red, colors.black)
    else
        if self.credentials.totpSecret ~= nil then
            self:loadTOTP()
            self:hideScreen1()
            self:setScreen2()
        else
            self.authentificated = true
            self.running = false
        end
    end
end

function AuthenticationWindow:totpCheck()
    local now = math.floor(os.epoch("utc") / 1000)
    if not totp.verify(self.instanceTOTP, self.screen2.totp.input, now) then
        self:writeAt(1, 4, "Wront TOTP", colors.red, colors.black)
        self.screen2.totp.input = ""
    else
        self.authentificated = true
        self.running = false
    end
end

function AuthenticationWindow:start()
    self:placeGlobalScreen()
    self:setScreen1()
    self.gui.execute(
        function ()
            while self.running do
                sleep()
            end
        end
    )
end

return AuthenticationWindow