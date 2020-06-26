Layer = {
    window = nil,
    startX = 1,
    startY = 1,
    data = {}
}

function Layer:new(o, w, stx, sty, d)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    self.window = w or window.create(term.current(), 1, 1, 51, 19, false)
    self.startX = stx
    self.startY = sty
    self.data = d or {}

    if self.data == nil or #self.data == 0 then
        for i = 1, 19 do
            self.data[i] = {}
        end
    end

    return o
end

function Layer:setPixel(x, y, c)
    if self.data == nil then
        self.data = {}

        for i = 1, 19 do
            self.data[i] = {}
        end
    end

    self.data[y][x] = c
end

function Layer:drawPixel(x, y, c)
    if self.data == nil then
        self.data = {}

        for i = 1, 19 do
            self.data[i] = {}
        end
    end

    self.data[y][x] = c

    if self.window == nil then
        self.window = window.create(term.current(), 1, 1, 51, 19)
    end

    self.window.setCursorPos(x, y)
    self.window.setBackgroundColor(c or colors.black)
    self.window.setTextColor(colors.gray)

    if c == nil then self.window.write("\127") else self.window.write(" ") end
end

function Layer:draw(w, drawBG)
    w = w or self.window
    drawBG = drawBG or true

    for y = 1, #self.data do
        local row = self.data[y + self.startY - 1] or {}

        for x = 1, #row do
            local clr = row[x + startX - 1] or nil

            w.setCursorPos(x, y)
            w.setBackgroundColor(clr or colors.black)
            w.setTextColor(colors.gray)

            if clr == nil then
                if drawBG then w.write("\127") end
            else
                w.write(" ")
            end
        end
    end
end

function Layer:write(xp, yp, txt, bc, tc)
    if xp ~= nil and yp ~= nil then self.window.setCursorPos(xp, yp) end
    if bc ~= nil then self.window.setBackgroundColor(bc) end
    if tc ~= nil then self.window.setTextColor(tc) end
    if txt ~= nil then self.window.write(txt) end
end

---

unsaved = false
menuOpen = false
horizontalScroll = false
move = false
rulers = true
merged = false
layerCount = 0
currentLayer = 0
px = 1
py = 1
sx = 1
sy = 1
prevX = 1
prevY = 1
layers = {}
saveFile = ""
blocks = {0x1, 0x2, 0x4, 0x8, 0x10, 0x20, 0x40, 0x80, 0x100, 0x200, 0x400, 0x800, 0x1000, 0x2000, 0x4000, 0x8000}
blockIndex = 1
altBlockIndex = #blocks
block = blocks[blockIndex]
altBlock = blocks[altBlockIndex]
native = term.current()
w, h = native.getSize()
running = true

-- GUI

gui = window.create(native, 1, 1, w, h)

-- FILE MENU

fileMenu = window.create(native, 1, 2, 9, 7, false)

-- EDIT MENU

editMenu = window.create(native, 6, 2, 16, 8, false)

-- VIEW MENU

viewMenu = window.create(native, 11, 2, 13, 7, false)

-- PROJECT MENU

projectMenu = window.create(native, 16, 2, 15, 6, false)

-- EDITOR

editor = window.create(gui, 1, 4, w, h - 3)

-- RULERS

rulerX = window.create(editor, 2, 1, w - 1, 1)
rulerY = window.create(editor, 1, 2, 1, h - 4)

-- SAVE DIALOG

saveDialog = window.create(native, 1, h - 1, w, 2, false)
saveTextBox = window.create(saveDialog, 17, 2, w - 18, 1, false)

--

function drawBlock(xPos, yPos, bType)
    if menuOpen then return end

    if rulers then
        px = sx + xPos - 1
        py = sy + yPos - 4
    else
        px = sx + xPos
        py = sy + yPos - 3
    end

    if px < 1 or py < 1 then
        return
    end

    if layers[2][currentLayer].data[py] == nil then
        layers[2][currentLayer].data[py] = {}
    end
    
    layers[2][currentLayer].data[py][px] = bType or block

    local overPainted = false
    local underPaint

    if merged then
        for i = currentLayer + 1, layerCount do
            if layers[2][i] ~= nil and layers[2][i][py] ~= nil and layers[2][i][py][px] ~= nil and layers[2][i][py][px] ~= colors.black then
                overPainted = true
            end
        end

        if currentLayer > 1 and ((bType or block) == nil or (bType or block) == colors.black) then
            for i = 1, currentLayer - 1 do
                if layers[2][i] ~= nil and layers[2][i][py] ~= nil and layers[2][i][py][px] ~= nil and layers[2][i][py][px] ~= colors.black then
                    underPaint = layers[2][i][py][px]
                end
            end
        end
    end

    if not overPainted then
        if (bType or block) == nil or (bType or block) == colors.black then
            layerW:write(px - sx, py - sy, nil, underPaint or colors.black, colors.gray)

            if underPaint ~= nil then layerW:write(nil, nil, " ", nil, nil) else layerW:write(nil, nil, "\127", nil, nil) end
        else
            layerW:write(px - sx, py - sy, " ", bType or block, nil)
        end
    end
end

function renderEmptyLayer()
    repositionLayer()

    for y = 1, h - 3 do
        for x = 1, w do
            layerW:write(x, y, string.char(127), colors.black, colors.gray)
        end
    end
end

function newLayer()
    local lW

    if rulers then
        lW = window.create(editor, 2, 2, w, h - 3)
    else
        lW = window.create(editor, 1, 1, w, h - 3)
    end

    currentLayer = currentLayer + 1
    layerCount = layerCount + 1

    for i = layerCount, currentLayer do
        layers[i] = layers[i - 1]
    end
    
    layers[currentLayer] = Layer:new(nil, lW, 1, 1, nil)

    layerW = layers[currentLayer]

    if not merged then layerW:draw() end
end

function deleteLayer(lno)
    lno = lno or currentLayer

    if currentLayer > 1 then
        currentLayer = currentLayer - 1
    end

    tempArr = {}
    tempArr[1] = layers[1]
    tempArr[2] = {}
    tempW = {}
    ci = 1

    for i = 1, layerCount do
        if i ~= lno then
            tempArr[2][ci] = layers[2][i]
            tempW[ci] = layerWindows[i]
            ci = ci + 1
        end
    end

    layers = tempArr
    layerWindows = tempW
    layerCount = #layerWindows
    
    if layerCount == 0 then
        currentLayer = 0
        newLayer()
    else
        layerW = layerWindows[currentLayer]
        drawLayer()
    end
end

function printLayerNo()
    gui.setCursorPos(w - 16, 1)
    gui.setBackgroundColor(colors.gray)
    gui.setTextColor(colors.lightGray)
    gui.write("                 ")

    if merged then
        gui.setCursorPos(w - 16, 1)
        gui.write("Merged")
    else
        gui.setCursorPos(w - 15, 1)
        gui.write("Layer")
    end

    gui.setCursorPos(w - 9, 1)
    gui.write(currentLayer)
    gui.setCursorPos(w - 5, 1)
    gui.write("of")
    gui.setCursorPos(w - 2, 1)
    gui.write(layerCount)
end

function toggleRulers()
    rulers = not rulers

    rulerX.setVisible(rulers)
    rulerY.setVisible(rulers)

    if rulers then
        editor.setCursorPos(1, 1)
        editor.setBackgroundColor(colors.black)
        editor.setTextColor(colors.gray)
        editor.write("+")
    end
        
    drawLayer()
end

function refreshRulers()
    rulerX.setCursorPos(1, 1)
    rulerY.setCursorPos(1, 1)
    rulerX.setBackgroundColor(colors.black)
    rulerX.setTextColor(colors.gray)
    rulerY.setBackgroundColor(colors.black)
    rulerY.setTextColor(colors.gray)

    for i = 1, w do
        if i % 5 == 0 then
            rulerX.write("+")
        else
            rulerX.write("-")
        end
    end

    for i = 1, h - 3 do
        rulerY.setCursorPos(1, i)

        if i % 5 == 0 then
            rulerY.write("+")
        else
            rulerY.write("|")
        end
    end

    rulerX.setCursorPos(1, 1)
    rulerX.write(sx)

    for i = 1, #tostring(sy) do
        rulerY.setCursorPos(1, i)
        rulerY.write(string.sub(tostring(sy), i))
    end
end

function repositionLayer()
    if layerW == nil then return end

    if rulers then
        layerW.window.reposition(2, 2)
    else
        layerW.window.reposition(1, 1)
    end
end

function drawLayer()
    if merged then
        mergedView()
        return
    end

    layerW:draw()
end

function drawGUI()
    gui.reposition(1, 1, w, h)

    gui.setBackgroundColor(colors.black)
    gui.clear()

    term.redirect(gui)

    gui.setBackgroundColor(colors.gray)
    gui.setCursorPos(1, 1)

    for c = 1, w do
        gui.write(" ")
    end

    gui.setBackgroundColor(colors.lightGray)
    gui.setCursorPos(1, 2)

    for c = 1, w do
        gui.write(" ")
    end

    gui.setCursorPos(1, 3)
    gui.setTextColor(colors.gray)

    for c = 1, w do
        gui.write("_")
    end

    gui.setCursorPos(8, 2)
    gui.blit("+              -", "f000000000000000", "0123456789abcdef")

    gui.setBackgroundColor(colors.gray)
    gui.setTextColor(colors.lightGray)
    gui.setCursorPos(1, 1)
    gui.write("File Edit View Project")
    gui.setTextColor(colors.white)
    gui.setBackgroundColor(colors.lightGray)
    gui.setCursorPos(1, 2)
    gui.write("Blocks")
end

function drawEditor()
    editor.reposition(1, 4, w, h - 3)

    editor.setBackgroundColor(colors.black)
    editor.clear()
    editor.setCursorPos(1, 1)
    editor.setBackgroundColor(colors.black)
    editor.setTextColor(colors.gray)
    editor.write("+")

    rulerX.reposition(2, 1, w - 1, 1)
    rulerY.reposition(1, 2, 1, h - 4)
end

function drawMenus()
    fileMenu.setBackgroundColor(colors.white)
    fileMenu.setTextColor(colors.gray)
    fileMenu.clear()

    fileMenu.setCursorPos(2, 2)
    fileMenu.write("New")
    fileMenu.setCursorPos(2, 3)
    fileMenu.write("Open")
    fileMenu.setCursorPos(2, 4)
    fileMenu.write("Save")
    fileMenu.setCursorPos(2, 5)
    fileMenu.write("Save as")
    fileMenu.setCursorPos(2, 6)
    fileMenu.write("Exit")

    editMenu.setBackgroundColor(colors.white)
    editMenu.setTextColor(colors.gray)
    editMenu.clear()

    editMenu.setCursorPos(2, 2)
    editMenu.write("New layer")
    editMenu.setCursorPos(2, 3)
    editMenu.write("Delete layer")
    editMenu.setCursorPos(2, 4)
    editMenu.write("Next layer ^")
    editMenu.setCursorPos(2, 5)
    editMenu.write("Prev layer v")
    editMenu.setCursorPos(2, 6)
    editMenu.write("Go to layer >")
    editMenu.setCursorPos(2, 7)
    editMenu.write("Go to position")

    viewMenu.setBackgroundColor(colors.white)
    viewMenu.setTextColor(colors.gray)
    viewMenu.clear()
    
    viewMenu.setCursorPos(2, 2)
    viewMenu.write("Show rulers")
    viewMenu.setCursorPos(2, 3)
    viewMenu.write("Project to")
    viewMenu.setCursorPos(2, 4)
    viewMenu.write("Shortcuts")
    viewMenu.setCursorPos(2, 5)
    viewMenu.write("Layer view")
    viewMenu.setCursorPos(2, 6)
    viewMenu.write("Merged view")

    projectMenu.setBackgroundColor(colors.white)
    projectMenu.setTextColor(colors.gray)
    projectMenu.clear()

    projectMenu.setCursorPos(2, 2)
    projectMenu.write("Set up turtle")
    projectMenu.setCursorPos(2, 3)
    projectMenu.write("Upload")
    projectMenu.setCursorPos(2, 4)
    projectMenu.write("Start")
    projectMenu.setCursorPos(2, 5)
    projectMenu.write("Status")
end

function drawSaveDialog()
    saveDialog.reposition(1, h - 1, w, 2)
    saveTextBox.reposition(14, 2, w - 15, 1)
    saveDialog.setBackgroundColor(colors.lightGray)
    saveDialog.clear()

    writeBox(1, 1, w, 2, colors.lightGray, saveDialog)

    saveTextBox.redraw()

    saveDialog.setBackgroundColor(colors.lightGray)
    saveDialog.setTextColor(colors.gray)
    saveDialog.setCursorPos(3, 2)
    saveDialog.write("Save name: ")
end

function writeBox(xStart, yStart, xEnd, yEnd, clr, win)
    win.setBackgroundColor(clr)
    
    for y = yStart, yEnd do
        for x = xStart, xEnd do
            win.setCursorPos(x, y)
            win.write(" ")
        end
    end
end

function showSaveDialog()
    saveDialog.setVisible(true)
    saveTextBox.setVisible(true)

    drawSaveDialog()

    while true do
        saveTextBox.redraw()
        saveTextBox.setBackgroundColor(colors.black)
        saveTextBox.setTextColor(colors.white)
        saveTextBox.clear()
        saveTextBox.setCursorPos(1, 1)

        local e, p1, p2, p3, p4, p5, p6 = os.pullEventRaw()

        if e == "terminate" then
            break
        end
        
        if e == "mouse_click" then
            if p2 >= 14 and p2 <= w - 2 and p3 == h then
                term.redirect(saveTextBox)
                saveTextBox.setCursorBlink(true)
                saveFile = read()
                term.redirect(native)
                break
            end
        end

        if e == "key" then
            if p1 == keys.backspace then
                break
            end
        end
    end

    saveDialog.setVisible(false)
    saveTextBox.setVisible(false)
    drawGUI()
    drawEditor()
    drawLayer()
    refreshRulers()
    printLayerNo()

    if saveFile ~= nil and saveFile ~= "" then
        saveFile = saveFile .. ".ncp"
        saveProject(saveFile)
    end
end

function saveProject(fPath)
    if fs.exists(fPath) then
        fs.delete(fPath)
    end

    local file = fs.open(fPath, "w")

    file.write(textutils.serialize(layers))
    file.close()

    unsaved = false
end

function drawError(txt, err)
    txt = txt or ""
    err = err or ""

    gui.setCursorPos(26, 2)
    gui.setTextColor(colors.red)
    gui.setBackgroundColor(colors.lightGray)
    gui.write("[ERROR] " .. txt or "" .. " : " .. err or "")
end

function mergedView()
    editor.redraw()

    for lc = 1, layerCount do
        local lyr = layers[2][lc]

        lyr:draw(nil, false)
    end
end

function main()
    local e, p1, p2, p3, p4, p5, p6 = os.pullEventRaw()

    if e == "terminate" then
        running = false
    end

    if e == "term_resize" then
        w, h = native.getSize()
        gui.redraw()
        editor.redraw()
        drawGUI()
        drawMenus()
        drawEditor()
        refreshRulers()
        repositionLayer()
        printLayerNo()
        if merged then viewMerged() else drawLayer() end
    end

    if e == "key" then
        if p1 == keys.leftShift or p1 == keys.rightShift or p1 == keys.leftCtrl or p1 == keys.rightCtrl or p1 == keys.space then
            horizontalScroll = true
            move = true
        end

        if p1 == keys.up or p1 == keys.right and layerCount > 0 then
            if currentLayer < layerCount then
                currentLayer = currentLayer + 1
                
                if not merged then
                    layerW = layerWindows[currentLayer]
                    drawLayer()
                end
                
                printLayerNo()
            end
        end

        if p1 == keys.down or p1 == keys.left and layerCount > 0 then
            if currentLayer > 1 then
                currentLayer = currentLayer - 1
                
                if not merged then
                    layerW = layerWindows[currentLayer]
                    drawLayer()
                end
                
                printLayerNo()
            end
        end

        if p1 == keys.n and layerCount < 999 then
            unsaved = true
            newLayer()
            printLayerNo()
        end

        if p1 == keys.d then
            unsaved = true
            deleteLayer()
            printLayerNo()
        end

        if p1 == keys.r then
            toggleRulers()
        end

        if p1 == keys.s then
            if saveFile ~= "" and fs.exists(saveFile) then
                saveProject(saveFile)
            else
                showSaveDialog()
            end
        end

        if p1 == keys.m then
            merged = not merged
            if merged then mergedView() else drawLayer() end
        end

        printLayerNo()
    end

    if e == "key_up" then
        if p1 == keys.leftShift or p1 == keys.rightShift or p1 == keys.leftCtrl or p1 == keys.rightCtrl or p1 == keys.space then
            horizontalScroll = false
            move = false
        end
    end

    if e == "mouse_scroll" then
        local scrolled = true

        if horizontalScroll and sx >= 1 then
            sx = sx + p1
        elseif sy >= 1 then
            sy = sy + p1
        end

        if sx <= 0 then
            sx = 1
            scrolled = false
        end

        if sy <= 0 then
            sy = 1
            scrolled = false
        end
        
        if not merged then
            layers[2][currentLayer].startX = sx
            layers[2][currentLayer].startY = sy
        end

        unsaved = true

        if scrolled then
            refreshRulers()
            if merged then mergedView() else drawLayer() end
        end
    end

    if e == "mouse_drag" then
        if menuOpen then
            menuOpen = false
            fileMenu.setVisible(false)
            editMenu.setVisible(false)
            projectMenu.setVisible(false)
            gui.redraw()
            editor.redraw()
            rulerX.setVisible(rulers)
            rulerY.setVisible(rulers)
            drawLayer()
        elseif move then
            if sx >= 1 then
                if prevX > p2 then sx = sx + 1 else sx = sx - 1 end
            end

            if sy >= 1 then
                if prevY > p3 then sy = sy + 1 else sy = sy - 1 end
            end

            if sx <= 0 then sx = 1 end
            if sy <= 0 then sy = 1 end

            prevX = p2
            prevY = p3

            layers[2][currentLayer].startX = sx
            layers[2][currentLayer].startY = sy
            unsaved = true

            drawLayer()
        elseif p3 > 3 then
            unsaved = true
            if p1 == 1 then
                drawBlock(p2, p3)
            else
                drawBlock(p2, p3, altBlock)
            end
        end
    elseif e == "mouse_click" then
        fileMenu.setVisible(false)
        editMenu.setVisible(false)
        viewMenu.setVisible(false)
        projectMenu.setVisible(false)
        gui.redraw()
        editor.redraw()

        if p3 == 1 and p2 >= 1 and p2 <= 5 then
            gui.setCursorPos(1, 1)
            gui.blit("File ", "77777", "88888")
            menuOpen = true
        elseif p3 == 1 and p2 >= 6 and p2 <= 10 then
            gui.setCursorPos(6, 1)
            gui.blit("Edit ", "77777", "88888")
            menuOpen = true
        elseif p3 == 1 and p2 >= 10 and p2 <= 15 then
            gui.setCursorPos(11, 1)
            gui.blit("View ", "77777", "88888")
            menuOpen = true
        elseif p3 == 1 and p2 >= 16 and p2 <= 23 then
            gui.setCursorPos(16, 1)
            gui.blit("Project ", "77777777", "88888888")
            menuOpen = true
        end

        if p3 == 2 and p2 >= 8 and p2 <= 24 then
            gui.setCursorPos(8, 2)
            gui.blit("               \127", "0000000000000007", "0123456789abcdef")

            if p1 == 1 then
                blockIndex = p2 - 7
                block = blocks[blockIndex]
            else
                altBlockIndex = p2 - 7
                altBlock = blocks[altBlockIndex]
            end

            if block == colors.white then
                gui.setTextColor(colors.black)
            else
                gui.setTextColor(colors.white)
            end

            gui.setCursorPos(blockIndex + 7, 2)
            gui.setBackgroundColor(block)
            gui.write("+")

            if altBlock == colors.white then
                gui.setTextColor(colors.black)
            else
                gui.setTextColor(colors.white)
            end

            gui.setCursorPos(altBlockIndex + 7, 2)
            gui.setBackgroundColor(altBlock)
            gui.write("-")

            if block == altBlock then
                gui.setCursorPos(p2, 2)
                gui.write("\177")
            end
            
            printLayerNo()
        end

        if p3 > 3 then
            unsaved = true

            if p1 == 1 then
                drawBlock(p2, p3)
            else
                drawBlock(p2, p3, altBlock)
            end
            
            printLayerNo()
        end

        rulerX.setVisible(rulers)
        rulerY.setVisible(rulers)
    elseif e == "mouse_up" then
        gui.setCursorPos(1, 1)
        gui.blit("File ", "88888", "77777")
        gui.setCursorPos(6, 1)
        gui.blit("Edit ", "88888", "77777")
        gui.setCursorPos(11, 1)
        gui.blit("View ", "88888", "77777")
        gui.setCursorPos(16, 1)
        gui.blit("Project ", "88888888", "77777777")
        
        if p3 == 1 and p2 >= 1 and p2 <= 5 then
            fileMenu.setVisible(true)
            menuOpen = true
        elseif p3 == 1 and p2 >= 6 and p2 <= 10 then
            editMenu.setVisible(true)
            menuOpen = true
        elseif p3 == 1 and p2 >= 10 and p2 <= 15 then
            viewMenu.setVisible(true)
            menuOpen = true
        elseif p3 == 1 and p2 >= 16 and p2 <= 23 then
            projectMenu.setVisible(true)
            menuOpen = true
        else
            menuOpen = false
            printLayerNo()
        end
    end
end

--

drawGUI()
drawMenus()
drawEditor()
newLayer()
printLayerNo()
refreshRulers()
term.redirect(native)
term.setCursorPos(1,1)

while true do
    if not running then break end

    local stat, err = pcall(main)

    if not stat then
        drawError(err.code, err)
    end
end

term.setBackgroundColor(colors.black)
term.setTextColor(colors.white)
term.clear()
term.setCursorPos(1, 1)