Canvas = {
    x = 0,
    y = 0,
    width = 0,
    height = 0,
    screen = {},
    foreground="0",
    background="f",
}

function Canvas:new(o, term, width, height, fg, bg)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    self.term = term
    self.x, self.y = self.term.getCursorPos()
    self.width = width or 1
    self.height = height or 1
    self.screen = {}
    self.foreground = fg or "0"
    self.background = bg or "f"
    self:_ClearScreen()
    return o
end

function Canvas:_ClearScreen()
    for y=1, self.height*3, 1 do
        local line = {}
        for x=1, self.width*2, 1 do
            line[x] = 0
        end
        self.screen[y] = line
    end
end

function Canvas:clear()
    self:_ClearScreen()
    for y=self.y, self.width+self.y, 1 do
        self.term.setCursorPos(self.x, y)
        for x=self.x, self.height+self.x, 1 do
            self.term.write(" ")
        end
    end
end

function Canvas:getCharId(line, column)
    local id = 0
    for localY=3, 1, -1 do
        for localX=2, 1, -1 do
            id = id * 2 + self.screen[(line-1)*3+localY][(column-1)*2+localX]
        end
    end
    return id
end

function Canvas:getChar(line, column)
    local charId = self:getCharId(line, column)
    if charId < 32 then
        return string.char(charId + 128)
    else
        return string.char(63 - charId + 128)
    end
end

function Canvas:getFgColor(line, column)
    local charId = self:getCharId(line, column)
    if charId < 32 then
        return self.foreground
    else
        return self.background
    end
end

function Canvas:getBgColor(line, column)
    local charId = self:getCharId(line, column)
    if charId < 32 then
        return self.background
    else
        return self.foreground
    end
end

function Canvas:refresh()
    local charLine, bgLine, fgLine
    for line=1, self.height, 1 do
        self.term.setCursorPos(self.x, line + self.y - 1)
        charLine = ""
        bgLine = ""
        fgLine = ""
        for column=1, self.width, 1 do
            charLine = charLine .. self:getChar(line, column)
            fgLine = fgLine .. self:getFgColor(line, column)
            bgLine = bgLine .. self:getBgColor(line, column)
        end
        self.term.blit(charLine, fgLine, bgLine)
    end
end

function Canvas:showQRCode(code)
    local height = math.ceil(#(code) / 3)
    local width = math.ceil(#(code) / 2)
    self.height = height
    self.width = width
    self:_ClearScreen()
    local line
    for y=1, #(code), 1 do
        line = code[y]
        for x=1, #(line), 1 do
            if line[x] > 0 then
                self.screen[y][x] = 1
            end
        end
    end
end

function Canvas:setPixel(x, y, value)
    self.screen[y][x] = value
end

function Canvas:getPixel(x, y)
    return self.screen[y][x]
end

return { Canvas = Canvas }