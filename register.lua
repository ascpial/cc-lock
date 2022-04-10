if not fs.exists("GuiH") then
    shell.run("wget run https://github.com/9551-Dev/Gui-h/raw/main/installer.lua")
end

local guih = require("GuiH")
local window_manager = require("cc-lock.window")

local textures = {
    switchOff = guih.load_texture({[3]={[5]={t="f",s=" ",b="0",},},[4]={[5]={t="f",s=" ",b="e",},},offset={3,9,11,4,},}),
    switchOn = guih.load_texture({[3]={[5]={t="d",s=" ",b="d",},},[4]={[5]={t="d",s=" ",b="0",},},offset={3,9,11,4,},}),
}

RegisterWindow = {
    gui=nil,
    parentFrame=nil,
    frame=nil,
    window=nil,
    child=nil,
    running=true,
    globalScreen=nil,
    screen1=nil,
    screen2=nil,
    input={
        username="username",
        password="password",
        enable2FA=true,
        otpInstance={},
    },
    marginX=1, -- indicate the size of the qrcode in screen2
}

function RegisterWindow:new(o)
    -- preparing the object
    o = o or {}
    setmetatable(o, self)
    self.__index = self

    -- getting frame and visual stuffs ready
    self.gui = guih.create_gui(term.current())
    local termWidth, termHeight = term.getSize()
    self.parentFrame, self.frame = window_manager.createWindow(
        self.gui,
        {
            width = 45, height = 19,
            x=math.ceil(termWidth/2-10), y=math.ceil(termHeight/2-4),
            title = "Authentication manager",
            on_quit = function() self.running=false end
        }
    )

    self.window = self.frame.window
    self.child = self.frame.child

    self.globalScreen = {}

    self.running = true

    return o
end


function RegisterWindow:blitAt(x, y, text, fg, bg)
    self.window.setCursorPos(x, y)
    if #fg == 1 then
        self.window.blit(text, (fg):rep(#text), (bg):rep(#text))
    else
        self.window.blit(text, fg, bg)
    end
end
function RegisterWindow:writeAt(x, y, text, fg, bg)
    self.window.setCursorPos(x, y)
    if fg ~= nil then
        self.window.setTextColor(fg)
    end
    if bg ~= nil then
        self.window.setBackgroundColor(bg)
    end
    self.window.write(text)
end
function RegisterWindow:clearContent()
    self.window.setBackgroundColor(colors.black)
    for line=1, 12 do
        self.window.setCursorPos(1, line)
        self.window.clearLine()
    end
end

function RegisterWindow:placeGlobalScreen()
    self.globalScreen.cancel = self.child.create.button({
        name="cancel",
        x=1, y=15, height=3, width=8,
        text=self.gui.text({
            text="Cancel",
            blit={"FFFFFF", "EEEEEE"}
        }),
        background_color=colors.red,
        on_click=function()
            self.running=false
        end
    })
    self.globalScreen.continue = self.child.create.button({
        name="continue",
        x=34, y=15, height=3, width=10,
        text=self.gui.text({
            text="Continue",
            blit={"FFFFFFFF", "DDDDDDDD"}
        }),
        background_color=colors.green,
        on_click=function() self:screen1Continue() end,
    })
end

function RegisterWindow:drawScreen1()
    self:writeAt(1, 1, "Create your account")
    self:writeAt(1, 3, "Username")
    self:writeAt(1, 5, "Password")
    self:writeAt(1, 7, "Retype password")
    self:writeAt(1, 9, "Use two factors authentication")
end
function RegisterWindow:placeScreen1()
    self.screen1 = {}
    self.screen1.username = self.child.create.inputbox({
        name="username",
        x=17, y=3, width=10,
        selected=true,
        background_color=colors.gray,
    })
    self.screen1.password1 = self.child.create.inputbox({
        name="password1",
        x=17, y=5, width=10,
        char_limit=math.huge,
        replace_char="*",
        background_color=colors.gray,
    })
    self.screen1.password2 = self.child.create.inputbox({
        name="password2",
        x=17, y=7, width=10,
        char_limit=math.huge,
        replace_char="*",
        background_color=colors.gray,
    })
    self.screen1.enable2FA = self.child.create.switch({
        name="2fa",
        x=34, y=9, width=2, height=1,
        tex=textures.switchOff,
        tex_on=textures.switchOn,
    })
end
function RegisterWindow:setScreen1()
    self:drawScreen1()
    self:placeScreen1()
end
function RegisterWindow:hideScreen1()
    for key, component in pairs(self.screen1) do
        component.visible = false
    end
    self:clearContent()
end


function RegisterWindow:drawScreen2()
    self:writeAt(self.marginX, 1, "Setup 2FA")
    self:writeAt(self.marginX, 3, "Your secret key is:")
    self:writeAt(self.marginX, 6, "Type the TOTP here:")
    -- self:writeAt(1, 3, "Please wait...") useless?...
end
function RegisterWindow:placeScreen2()
    self.screen2 = {}
    self.screen2.validationCode = self.child.create.inputbox({
        x=self.marginX, y=7, width=6,
        selected=true,
        background_color=colors.gray,
    })
end
function RegisterWindow:setScreen2()
    
    self.totp = require("cc-lock.otp")("totp")
    self.util = require("cc-lock.otp")("util")
    self.qrencode = require("cc-lock.qrencode")
    self.canvas_manager = require("cc-lock.canvas")
    
    local secretKey = self.util.random_base32()
    self.input.otpInstance = self.totp.new(secretKey, 6, "sha1", 30)

    local uri = self.totp.as_uri(
        self.input.otpInstance,
        self.input.username,
        "CraftOS Lock"
    )

    local _, qrcode = self.qrencode.qrcode(uri)
    
    local canvas = self.canvas_manager.Canvas:new(nil, self.window)
    canvas.x, canvas.y = 1, 1
    canvas:showQRCode(qrcode)
    canvas:refresh()
    
    self.marginX = canvas.width + 1
    
    self:drawScreen2()
    self:writeAt(self.marginX, 4, self.input.otpInstance.secret)

    self:placeScreen2()

    self.globalScreen.continue.on_click = function() self:screen2Continue() end
end
function RegisterWindow:hideScreen2()
    for key, component in pairs(self.screen2) do
        component.visible = false
    end
    self:clearContent()
end

function RegisterWindow:screen1Continue()
    local message
    if self.screen1.password1.input ~= self.screen1.password2.input then
        message = "Passwords does not match"
    end
    if #(self.screen1.password1.input) < 4 then
        message = "Passwords eeds to be at least 4 chars"
    end
    if self.screen1.username.input == "" then
        message = "Field username is required"
    end
    if message then
        self.window.setCursorPos(1, 11)
        self.window.setBackgroundColor(colors.black)
        self.window.clearLine()
        self:blitAt(1, 11, message, "e", "f")
    else
        self.input.username = self.screen1.username.input
        self.input.password = self.screen1.password1.input
        self.input.enable2FA = self.screen1.enable2FA.value
        if self.screen1.enable2FA.value then
            self:hideScreen1()
            self:setScreen2()
        else
            self:saveCredential()
            self.running = false
        end
    end
end

function RegisterWindow:screen2Continue()
    if self.screen2.validationCode.input == self.lastInput then
        return
    end

    local now = math.floor(os.epoch("utc") / 1000)
    if #(self.screen2.validationCode.input) < 6 then
        self.window.setCursorPos(self.marginX, 9)
        self.window.setBackgroundColor(colors.black)
        self.window.setTextColor(colors.red)
        self.window.write("Enter a 6-digit code")
    elseif not self.totp.verify(
        self.input.otpInstance,
        self.screen2.validationCode.input,
        now
    ) then
        self.window.setCursorPos(self.marginX, 9)
        self.window.setBackgroundColor(colors.black)
        self.window.setTextColor(colors.red)
        self.window.write("Incorrect TOTP      ")
    else
        self.window.setBackgroundColor(colors.black)
        self.window.setTextColor(colors.green)
        self.window.setCursorPos(self.marginX, 9)
        self.window.write("TOTP correct!       ")
        self.window.setCursorPos(self.marginX, 10)
        self.window.write("Click continue to save")
        self.window.setCursorPos(self.marginX, 11)
        self.window.write("your credentials")
        self.globalScreen.continue.on_click = function()
            self:saveCredential()
            self.running = false
        end
    end
    
    self.lastInput = self.screen2.validationCode.input
end

function RegisterWindow:saveCredential(filename)
    filename = filename or ".credentials"
    local file = fs.open(filename, 'w')
    local credentials = {
        username=self.input.username,
    }
    if self.input.enable2FA ~= nil then
        credentials.totpSecret = self.input.otpInstance.secret
    end
    local sha1 = require("cc-lock.otp")("sha1")
    local password = sha1.sha1(self.input.password)
    credentials.password = password
    file.write(
        textutils.serializeJSON(credentials)
    )
    file.close()
end

function RegisterWindow:start()
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

local registerWindow = RegisterWindow:new(nil)

registerWindow:start()