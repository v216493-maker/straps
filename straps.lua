local sampev = require 'lib.samp.events'
local imgui = require 'imgui'
local encoding = require 'encoding'
encoding.default = 'CP1251'
u8 = encoding.UTF8

local strapsWindow = imgui.ImBool(false)
local selectedRank = imgui.ImInt(1)
local targetId = imgui.ImInt(-1)

local currentVersion = '1.0'
local updateUrl = 'https://raw.githubusercontent.com/v216493-maker/straps/main/autoupdate'

local shortNames = {
    u8'PROB', u8'SPC', u8'SNR', u8'SUP', u8'OPS',
    u8'AST', u8'SPC2', u8'DIR', u8'DEP', u8'FLD'
}

local fullNames = {
    u8'Probationary Agent',
    u8'Special Agent',
    u8'Senior Special Agent',
    u8'Supervisory Special Agent',
    u8'Operational Specialist',
    u8'Assistant Special Agent',
    u8'Special Agent',
    u8'Assistant Director',
    u8'Deputy Director',
    u8'Field Director'
}

function main()
    if not isSampLoaded() or not isSampfuncsLoaded() then return end
    while not isSampAvailable() do wait(100) end

    sampAddChatMessage('{3399FF}Скрипт загружен, использование: /straps [id]', -1)
    sampAddChatMessage('{00FF33}Разработано командой BENNET TEAM, для сервера Pride', -1)

    sampRegisterChatCommand('straps', cmd_straps)
    sampRegisterChatCommand('update', cmd_update)
    
    wait(-1)
end

function cmd_update(arg)
    sampAddChatMessage('{3399FF}Проверка обновлений...', -1)
    checkUpdate()
end

function checkUpdate()
    sampAddChatMessage('{3399FF}Проверка обновлений...', -1)
    
    local updateFile = getWorkingDirectory() .. '\\update_check.txt'
    
    downloadUrlToFile(updateUrl, updateFile, function(id, status, p1, p2)
        if status == 6 then
            if doesFileExist(updateFile) then
                local file = io.open(updateFile, 'r')
                if file then
                    local content = file:read('*a')
                    file:close()
                    os.remove(updateFile)
                    
                    -- Ищем версию в тексте
                    local version = content:match('"version"%s*:%s*"([^"]+)"')
                    local url = content:match('"url"%s*:%s*"([^"]+)"')
                    
                    if version then
                        sampAddChatMessage(string.format('{00FF00}Версия на сервере: %s', version), -1)
                        
                        if version ~= currentVersion then
                            sampAddChatMessage(string.format('{00FF00}Есть обновление! Версия: %s', version), -1)
                            
                            if url then
                                sampAddChatMessage('{3399FF}Скачиваю обновление...', -1)
                                downloadUrlToFile(url, thisScript().path, function(id2, status2, p12, p22)
                                    if status2 == 6 then
                                        sampAddChatMessage('{00FF00}Обновление скачано! Перезагружаю скрипт...', -1)
                                        lua_thread.create(function()
                                            wait(500)
                                            thisScript():reload()
                                        end)
                                    end
                                end)
                            else
                                sampAddChatMessage('{FF0000}Ссылка на скачивание не найдена', -1)
                            end
                        else
                            sampAddChatMessage('{00FF00}У вас последняя версия!', -1)
                        end
                    else
                        sampAddChatMessage('{FF0000}Не удалось найти информацию о версии', -1)
                        sampAddChatMessage(string.format('{FFAA00}Содержимое: %s', content:sub(1, 200)), -1)
                    end
                end
            end
        else
            sampAddChatMessage('{FF0000}Ошибка скачивания', -1)
        end
    end)
end

function cmd_straps(arg)
    local id = tonumber(arg:match('(%d+)'))
    if id then
        targetId.v = id
        strapsWindow.v = true
        imgui.Process = true
    else
        sampAddChatMessage('{FF0000}Используйте: /straps [ID]', -1)
    end
end

function sendToR()
    local targetNick = sampGetPlayerNickname(targetId.v)
    local selectedText = fullNames[selectedRank.v]
    
    if targetNick and targetNick ~= '' then
        sampSendChat(string.format('/r изменил погоны %s на %s', targetNick, selectedText))
    else
        sampSendChat(string.format('/r изменил погоны на %s', selectedText))
    end
end

function imgui.OnDrawFrame()
    if not strapsWindow.v then 
        imgui.Process = false
        return 
    end
    
    imgui.Process = true
    
    local resX, resY = getScreenResolution()
    local sizeX, sizeY = resX / 2, resY / 2
    imgui.SetNextWindowPos(imgui.ImVec2(resX / 2 - sizeX / 2, resY / 2 - sizeY / 2), imgui.Cond.Always)
    imgui.SetNextWindowSize(imgui.ImVec2(sizeX, sizeY), imgui.Cond.Always)
    

    imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(0.01, 0.02, 0.06, 0.98))
    imgui.PushStyleColor(imgui.Col.TitleBg, imgui.ImVec4(0.01, 0.02, 0.06, 1.0))
    imgui.PushStyleColor(imgui.Col.TitleBgActive, imgui.ImVec4(0.01, 0.02, 0.06, 1.0))
    imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.02, 0.03, 0.10, 1.0))
    imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.03, 0.05, 0.15, 1.0))
    imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0.05, 0.08, 0.25, 1.0))
    
 
    local nick = sampGetPlayerNickname(targetId.v)
    local titleText
    if nick and nick ~= '' then
        titleText = u8(string.format('Выдача погон %s[%d]', nick, targetId.v))
    else
        titleText = u8(string.format('Выдача погон [%d]', targetId.v))
    end
    
    imgui.Begin(titleText, strapsWindow)
    
    imgui.Spacing()
    
    local buttonWidth = sizeX / 4 - 15
    local buttonHeight = 50
    
    for i = 1, 4 do
        if selectedRank.v == i then
            imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.15, 0.30, 0.60, 1.0))
            local clicked = imgui.Button(shortNames[i], imgui.ImVec2(buttonWidth, buttonHeight))
            imgui.PopStyleColor()
            if clicked then selectedRank.v = i sendToR() end
        else
            if imgui.Button(shortNames[i], imgui.ImVec2(buttonWidth, buttonHeight)) then
                selectedRank.v = i sendToR()
            end
        end
        imgui.SameLine()
    end
    imgui.NewLine()
    

    for i = 1, 4 do
        local textWidth = imgui.CalcTextSize(fullNames[i]).x
        local offsetX = (buttonWidth - textWidth) / 2
        imgui.SetCursorPosX(imgui.GetCursorPosX() + offsetX)
        imgui.TextColored(imgui.ImVec4(0.70, 0.75, 0.85, 1.0), fullNames[i])
        imgui.SameLine()
        imgui.SetCursorPosX(imgui.GetCursorPosX() + (buttonWidth - textWidth - offsetX))
        imgui.SameLine()
    end
    imgui.NewLine()
    imgui.Spacing()
    

    for i = 5, 8 do
        if selectedRank.v == i then
            imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.15, 0.30, 0.60, 1.0))
            local clicked = imgui.Button(shortNames[i], imgui.ImVec2(buttonWidth, buttonHeight))
            imgui.PopStyleColor()
            if clicked then selectedRank.v = i sendToR() end
        else
            if imgui.Button(shortNames[i], imgui.ImVec2(buttonWidth, buttonHeight)) then
                selectedRank.v = i sendToR()
            end
        end
        imgui.SameLine()
    end
    imgui.NewLine()
    

    for i = 5, 8 do
        local textWidth = imgui.CalcTextSize(fullNames[i]).x
        local offsetX = (buttonWidth - textWidth) / 2
        imgui.SetCursorPosX(imgui.GetCursorPosX() + offsetX)
        imgui.TextColored(imgui.ImVec4(0.70, 0.75, 0.85, 1.0), fullNames[i])
        imgui.SameLine()
        imgui.SetCursorPosX(imgui.GetCursorPosX() + (buttonWidth - textWidth - offsetX))
        imgui.SameLine()
    end
    imgui.NewLine()
    imgui.Spacing()
    

    for i = 9, 10 do
        if selectedRank.v == i then
            imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.15, 0.30, 0.60, 1.0))
            local clicked = imgui.Button(shortNames[i], imgui.ImVec2(buttonWidth, buttonHeight))
            imgui.PopStyleColor()
            if clicked then selectedRank.v = i sendToR() end
        else
            if imgui.Button(shortNames[i], imgui.ImVec2(buttonWidth, buttonHeight)) then
                selectedRank.v = i sendToR()
            end
        end
        imgui.SameLine()
    end
    imgui.NewLine()
    

    for i = 9, 10 do
        local textWidth = imgui.CalcTextSize(fullNames[i]).x
        local offsetX = (buttonWidth - textWidth) / 2
        imgui.SetCursorPosX(imgui.GetCursorPosX() + offsetX)
        imgui.TextColored(imgui.ImVec4(0.70, 0.75, 0.85, 1.0), fullNames[i])
        imgui.SameLine()
        imgui.SetCursorPosX(imgui.GetCursorPosX() + (buttonWidth - textWidth - offsetX))
        imgui.SameLine()
    end
    imgui.NewLine()
    
    imgui.Spacing()
    imgui.Separator()
    imgui.Spacing()
    

    imgui.TextColored(imgui.ImVec4(0.70, 0.75, 0.85, 1.0), u8('Выбрано: '))
    imgui.SameLine()
    imgui.TextColored(imgui.ImVec4(0.40, 0.60, 0.90, 1.0), fullNames[selectedRank.v])
    
    imgui.End()
    
    imgui.PopStyleColor(6)
end

function onScriptTerminate(script, quitGame)
    if script == thisScript() then
        imgui.Process = false
    end
end

function sampev.onToggleCursor(cursorActive)
    if cursorActive then
        strapsWindow.v = false
        imgui.Process = false
    end
end