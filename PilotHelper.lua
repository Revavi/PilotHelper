script_name('PilotHelper')
script_author('Revavi')
script_version('1.0.2')

require("moonloader")
local encoding = require 'encoding'
local imgui = require 'mimgui'
local fa = require 'fAwesome6'
local inicfg = require 'inicfg'
local vkeys = require 'vkeys'
local sampev = require 'lib.samp.events'
local memory = require 'memory'

encoding.default = 'CP1251'
local u8 = encoding.UTF8

local wDir = getWorkingDirectory()

local mVec2 = imgui.ImVec2
local mVec4 = imgui.ImVec4
local mn = imgui.new

local statsSt = mn.bool(false)
local mainSt = mn.bool(false)
local cw = mn.int(0)
local ct = mn.int(0)

local timerSt = false
local timer = 0

local aUCustP = mn.bool(true)
local winPos = {x = select(2, getScreenResolution()) / 2-100, y = 140}

local f18 = nil
local f25 = nil

local stats = {
	tidex = 0,
	money = 0,
	award = 0,
	pilot = 0,
	count = 0
}

local dirs = {
	cfg = 'config',
	dev = 'config//Revavi',
	main = 'config//Revavi//PilotHelper'
}
for _, path in pairs(dirs) do if not doesDirectoryExist(wDir..'//'..path) then createDirectory(wDir..'//'..path) end end

local directIni = 'Revavi//PilotHelper//Settings.ini'
local setts = inicfg.load({
	main = {
		x = 140,
		y = select(2, getScreenResolution()) / 2-100,
		aUCustP = true,
		statsSt = false
	},
	weather = {
		cw = 11,
		ct = 6
	},
	stats = {
		tidex = 0,
		money = 0,
		award = 0,
		pilot = 0,
		count = 0
	},
	timer = {
		count = 0,
		state = false
	}
}, directIni)

local function msg(arg) if arg ~= nil then return sampAddChatMessage('[PilotHelper] {FFFFFF}'..tostring(arg), 0x009900) end end

function loadcfg()
	winPos.x=setts.main.x
	winPos.y=setts.main.y
	aUCustP[0]=setts.main.aUCustP
	statsSt[0]=setts.main.statsSt
	cw[0]=setts.weather.cw
	ct[0]=setts.weather.ct
	stats.tidex=setts.stats.tidex
	stats.money=setts.stats.money
	stats.award=setts.stats.award
	stats.pilot=setts.stats.pilot
	stats.count=setts.stats.count
	timer=setts.timer.count
	timerSt=setts.timer.state
end

function main()
	if not isSampLoaded() or not isSampfuncsLoaded() then return end
	repeat wait(0) until isSampAvailable()
	
	loadcfg()
	counter()
	sampRegisterChatCommand('pilot', om)
	sampRegisterChatCommand('ptimer', turnTimer)
	
	msg('Скрипт запущен | Открыть меню: /pilot | Автор: '..thisScript().authors[1])
	
	while true do
		wait(0)
		forceWeatherNow(cw[0])
		memory.write(0xB70153, ct[0], 1, false)
	end
end

function om()
	mainSt[0] = not mainSt[0]
end

function turnTimer()
	timerSt = not timerSt
	setts.timer.state=timerSt
	inicfg.save(setts, directIni)
	msg(timerSt and 'Счётчик запущен' or 'Счётчик остановлен')
end

function resetStat()
	stats = {
		tidex = 0,
		money = 0,
		award = 0,
		pilot = 0,
		count = 0
	}
	setts.stats=stats
	inicfg.save(setts, directIni)
	msg('Статистика сброшена')
end

function imgui.CenterText(text, arg)
	local arg = arg or 0
	imgui.SetCursorPosX(imgui.GetWindowWidth() / 2 - imgui.CalcTextSize(text).x / 2 )
	if arg == 0 then imgui.Text(text) elseif arg == 1 then imgui.TextDisabled(text) end
end

function imgui.KolhozText(sign, text)
	imgui.SetCursorPosX(16 - imgui.CalcTextSize(sign).x / 2 )
	imgui.Text(sign)
	imgui.SameLine()
	imgui.SetCursorPosX(30)
	imgui.Text(text)
end

function imgui.Hint(str_id, hint)
	imgui.SameLine()
	imgui.TextDisabled(fa('CIRCLE_QUESTION'))
	if imgui.IsItemHovered() then
		imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, mVec2(10, 10))
		imgui.BeginTooltip()
		imgui.PushTextWrapPos(450)
		imgui.TextColored(imgui.GetStyle().Colors[imgui.Col.ButtonHovered], fa('CIRCLE_INFO')..u8' Подсказка:')
		imgui.TextUnformatted(hint)
		imgui.PopTextWrapPos()
		imgui.EndTooltip()
		imgui.PopStyleVar()
	end
end

local mainWin = imgui.OnFrame(function() return mainSt[0] and not isGamePaused() end,
function(self)
	local sw, sh = getScreenResolution()
	imgui.SetNextWindowPos(mVec2(sw / 2, sh / 2), imgui.Cond.FirstUseEver, mVec2(0.5, 0.5))
	imgui.SetNextWindowSize(mVec2(320, 214), 1)
	self.HideCursor = not mainSt[0]
	
    imgui.Begin('##MainWindow', _, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoSavedSettings + imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoCollapse)
		imgui.PushFont(f18)
			imgui.CenterText(u8'PILOT HELPER v'..thisScript().version)
		imgui.PopFont()
		imgui.CenterText('by '..thisScript().authors[1], 1)
		imgui.Separator()
		
		imgui.CenterText(u8'Список команд'); imgui.Hint('1', u8'/pilot - открыть/закрыть меню\n/ptimer - включить/выключить счётчик')
		if imgui.Button(statsSt[0] and u8'Скрыть статистику' or u8'Показать статистику', mVec2(148, 24)) then statsSt[0] = not statsSt[0]; setts.main.statsSt = statsSt[0] end
		imgui.SameLine()
		if imgui.Button(u8'Сбросить статистику', mVec2(148, 24)) then resetStat() end
		
		if imgui.Button(timerSt and u8'Выключить счётчик' or u8'Включить счётчик', mVec2(148, 24)) then turnTimer() end
		imgui.SameLine()
		if imgui.Button(u8'Сбросить счётчик', mVec2(148, 24)) then resetTimer() end

		if imgui.Checkbox(u8'Авто-выбор частного самолёта', aUCustP) then
			setts.main.aUCustP = aUCustP[0]
			inicfg.save(setts, directIni)
		end
		
		imgui.PushItemWidth(190); if imgui.SliderInt(u8'Кастомная погода', cw, 0, 45) then setts.weather.cw = cw[0]; inicfg.save(setts, directIni) end
		imgui.PushItemWidth(190); if imgui.SliderInt(u8'Кастомное время', ct, 0, 23) then setts.weather.ct = ct[0]; inicfg.save(setts, directIni) end
    imgui.End()
end)

function sumFormat(a)
    local b, e = ('%d'):format(a):gsub('^%-', '')
    local c = b:reverse():gsub('%d%d%d', '%1.')
    local d = c:reverse():gsub('^%.', '')
    return (e == 1 and '-' or '')..d
end

local statsWin = imgui.OnFrame(function() return statsSt[0] and not isGamePaused() end,
function(self)
	imgui.SetNextWindowPos(mVec2(setts.main.x, setts.main.y), imgui.Cond.FirstUseEver, mVec2(0, 0))
	imgui.SetNextWindowSize(mVec2(340, 160), 1)
	self.HideCursor = true
	
    imgui.Begin('##StatsWindow', _, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoSavedSettings + imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoCollapse)
		winPos = imgui.GetWindowPos()
		imgui.PushFont(f18)
			imgui.CenterText(u8'Общая статистика на работе пилота')
		imgui.PopFont()
		
		imgui.KolhozText(fa('DOLLAR_SIGN'), u8'Общая зарплата: $'..sumFormat(stats.money))
		imgui.KolhozText(fa('PLANE_ARRIVAL'), u8'Кол-во успешных рейсов: '..tostring(stats.count))
		imgui.KolhozText(fa('BOX_DOLLAR'), u8'Получено ларцов премии: '..tostring(stats.award))
		imgui.KolhozText(fa('PLANE_TAIL'), u8'Получено ларцов пилота: '..tostring(stats.pilot))
		imgui.KolhozText(fa('BOX'), u8'Получено ларцов Tidex: '..tostring(stats.tidex))
		
		imgui.PushFont(f25)
			imgui.CenterText(getTimer(timer))
		imgui.PopFont()
    imgui.End()
end)

function counter()
	lua_thread.create(function()
		while true do
			wait(1000)
			if timerSt then 
				timer = timer + 1
				setts.timer.count=timer
				inicfg.save(setts, directIni)
			end
		end
	end)
end

function resetTimer()
	timer = 0
	timerSt = false
	setts.timer.count=timer
	setts.timer.state=timerSt
	inicfg.save(setts, directIni)
    msg('Счётчик сброшен.')
end

function getTimer(time)
    local time2 = 86400 - os.date('%H', 0) * 3600
    if tonumber(time) >= 86400 then onDay = true else onDay = false end
    return os.date((onDay and math.floor(time / 86400)..u8'д ' or '')..'%H:%M:%S', time + time2)
end

function sampev.onServerMessage(color, text)
	text = text:gsub('%{......%}', '')
	text = text:gsub(',', '')
	
	if text:find('%[Подсказка%] Рейс успешно завершен! Заработано за рейс: $(%d+) за смену всего: $(%d+)') then
		local money = text:match('Заработано за рейс: $(%d+)')
		stats.count = stats.count + 1
		stats.money = stats.money + money
	end
	if text:find('Благодаря улучшениям вашей семьи вы получаете дополнительную зарплату: $(%d+)') then
		local money = text:match('дополнительную зарплату: $(%d+)')
		stats.money = stats.money + money
	end
	if text:find('За работу в рабочее время вашей организации вы получаете прибавку к зарплате: $(%d+).') then
		local money = text:match('прибавку к зарплате: $(%d+).')
        stats.money = stats.money + money
    end
	if text:find('Получено вознаграждение: (.+)') then
		local larec = text:match('Получено вознаграждение: (.+)')
		if larec == 'Ларец Tidex.' then stats.tidex = stats.tidex + 1 end
		if larec == 'Ларец с премией.' then stats.award = stats.award + 1 end
		if larec == 'Ларец пилота.' then stats.pilot = stats.pilot + 1 end
	end
	setts.stats=stats
	inicfg.save(setts, directIni)
end

function sampGetListboxItemByText(text, plain)
    if not sampIsDialogActive() then return -1 end
        plain = not (plain == false)
    for i = 0, sampGetListboxItemsCount() - 1 do
        if sampGetListboxItemText(i):find(text, 1, plain) then
            return i
        end
    end
    return -1
end

function sampev.onShowDialog(id, style, title, button1, button2, text)
	if title:find('Выберите самолет') and aUCustP[0] then
		lua_thread.create(function()
			wait(0)
			local listbox = sampGetListboxItemByText('Частный самолет')
			sampSendDialogResponse(id, 1, listbox, nil)
			sampCloseCurrentDialogWithButton(0)
		end)
	end
end

function onWindowMessage(msg, arg, argg)
    if msg == 0x100 or msg == 0x101 then
        if (arg == vkeys.VK_ESCAPE and mainSt[0]) and not isPauseMenuActive() then
            consumeWindowMessage(true, false)
            if msg == 0x101 then
                mainSt[0] = false
            end
        end
    end
end

function onScriptTerminate(script, quitGame)
	if script == thisScript() then
        setts.main.x = winPos.x
        setts.main.y = winPos.y
		inicfg.save(setts, directIni)
	end
end

function theme()
	imgui.SwitchContext()
	local style = imgui.GetStyle()
	local colors = style.Colors
	local clr = imgui.Col
	
    style.WindowPadding = mVec2(8, 8)
    style.ItemSpacing = mVec2(5, 5)

    style.WindowBorderSize = 0
    style.PopupBorderSize = 0
    style.FrameBorderSize = 0
    style.ScrollbarSize = 0
	
    style.WindowRounding = 7
    style.ChildRounding = 7
    style.FrameRounding = 7
    style.PopupRounding = 7

    colors[clr.Text]                   = mVec4(1.00, 1.00, 1.00, 1.00)
    colors[clr.TextDisabled]           = mVec4(1.00, 1.00, 1.00, 0.40)
    colors[clr.WindowBg]               = mVec4(0.00, 0.07, 0.00, 0.90)
    colors[clr.PopupBg]                = mVec4(0.01, 0.07, 0.02, 0.90)
    colors[clr.BorderShadow]           = mVec4(0.00, 0.00, 0.00, 0.00)
    colors[clr.FrameBg]                = mVec4(0.01, 0.10, 0.02, 0.70)
    colors[clr.FrameBgHovered]         = mVec4(0.01, 0.10, 0.02, 0.90)
    colors[clr.FrameBgActive]          = mVec4(0.01, 0.10, 0.02, 0.75)
    colors[clr.CheckMark]              = mVec4(1.00, 1.00, 1.00, 1.00)
    colors[clr.Button]                 = mVec4(0.00, 0.40, 0.00, 0.24)
    colors[clr.ButtonHovered]          = mVec4(0.00, 0.60, 0.00, 0.40)
    colors[clr.ButtonActive]           = mVec4(0.00, 0.50, 0.00, 0.32)
    colors[clr.Separator]              = mVec4(0.00, 0.40, 0.00, 0.41)
    colors[clr.SeparatorHovered]       = mVec4(0.00, 0.40, 0.00, 0.78)
	colors[clr.SeparatorActive]        = mVec4(0.00, 0.40, 0.00, 1.00)
	colors[clr.SliderGrab]             = mVec4(0.00, 0.25, 0.00, 0.70)
	colors[clr.SliderGrabActive]       = mVec4(0.00, 0.40, 0.00, 0.70)
end

imgui.OnInitialize(function()
    theme()
	
	imgui.GetIO().IniFilename = nil
    local config = imgui.ImFontConfig()
    config.MergeMode = true
    config.PixelSnapH = true
    iconRanges = mn.ImWchar[3](fa.min_range, fa.max_range, 0)
    imgui.GetIO().Fonts:AddFontFromMemoryCompressedBase85TTF(fa.get_font_data_base85('solid'), 14, config, iconRanges)
	f18 = imgui.GetIO().Fonts:AddFontFromFileTTF(getFolderPath(0x14) .. '//trebucbd.ttf', 18, _, imgui.GetIO().Fonts:GetGlyphRangesCyrillic())
	f25 = imgui.GetIO().Fonts:AddFontFromFileTTF(getFolderPath(0x14) .. '//trebucbd.ttf', 25, _, imgui.GetIO().Fonts:GetGlyphRangesCyrillic())
end)