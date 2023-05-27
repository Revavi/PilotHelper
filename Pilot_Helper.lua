script_name('PilotHelper')
script_author('Revavi')
script_version('1.1.1')
script_version_number(6)

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

local lfunc, fcmd = {}, {}

local wDir, this = getWorkingDirectory(), thisScript()

local mVec2, mVec4, mn = imgui.ImVec2, imgui.ImVec4, imgui.new
local zeroClr = mVec4(0,0,0,0)

local statsSt, mainSt, mwSy = mn.bool(false), mn.bool(false), 500
local cw, ct = mn.int(0), mn.int(0)

local aUCustP, showCharacters, lareCost = mn.bool(true), mn.bool(true), mn.bool(false)

local nextChar = 'Неизвестно(Обратитесь к разработчику)'
local firstChar = false
local oculist = false

local f18, f25 = nil, nil

local day, hour, diff = true, 6, 0

local cost = {
	tidex = mn.int(0),
	award = mn.int(0),
	pilot = mn.int(0)
}

local dirs = {
	cfg = 'config',
	dev = 'config//Revavi',
	main = 'config//Revavi//Pilot Helper'
}
for _, path in pairs(dirs) do if not doesDirectoryExist(wDir..'//'..path) then createDirectory(wDir..'//'..path) end end

local directIni = 'Revavi//Pilot Helper//Settings.ini'
local setts = inicfg.load({
	main = {
		pX = select(1, getScreenResolution())/2-160,
		pY = select(2, getScreenResolution())/2-143,
		aUCustP = true,
		statsSt = false,
		showCharacters = true,
		lareCost = false,
		spX = 10,
		spY = 350
	},
	custom = {
		cw = 11,
		ct = 6,
		tw = false,
		tt = false
	},
	cost = {
		tidex = 0,
		award = 0,
		pilot = 0
	}
}, directIni)

local stats = inicfg.load({
	main = {
		tidex = 0,
		money = 0,
		award = 0,
		pilot = 0,
		countD = 0,
		countN = 0
	},
	timer = {
		count = 0,
		state = false
	}
}, 'Revavi//Pilot Helper//Statistics.ini')

local proxyCfg = {} -- Спасибо why ega
setmetatable(proxyCfg, {
	__index = function(self, k)
        inicfg.save(setts, directIni)
        return setts[k]
    end,
    __newindex = function(self, k, v)
        inicfg.save(setts, directIni)
        setts[k] = v
   end
})
local proxyStats = {}
setmetatable(proxyStats, {
	__index = function(self, k)
        inicfg.save(stats, 'Revavi//Pilot Helper//Statistics.ini')
        return stats[k]
    end,
    __newindex = function(self, k, v)
        inicfg.save(stats, 'Revavi//Pilot Helper//Statistics.ini')
        stats[k] = v
   end
})

local function msg(arg) if arg ~= nil then return sampAddChatMessage('[PilotHelper] {FFFFFF}'..tostring(arg), 0x33b333) end end

function lfunc.loadcfg()
	lareCost[0]=setts.main.lareCost
	showCharacters[0]=setts.main.showCharacters
	cost.tidex[0]=setts.cost.tidex
	cost.pilot[0]=setts.cost.pilot
	cost.award[0]=setts.cost.award
	aUCustP[0]=setts.main.aUCustP
	statsSt[0]=setts.main.statsSt
	cw[0]=setts.custom.cw
	ct[0]=setts.custom.ct
end

function main()
	if not isSampLoaded() or not isSampfuncsLoaded() then return end
	repeat wait(0) until isSampAvailable()
	
	lfunc.loadcfg()
	lfunc.counter()
	
	sampRegisterChatCommand('pilot', function() mainSt[0] = not mainSt[0] end)
	sampRegisterChatCommand('ptimer', fcmd.turnTimer)
	
	msg('Скрипт запущен | Открыть меню: /pilot | Автор: '..table.concat(this.authors, ", "))
	
	while true do
		wait(0)
		
		if setts.custom.tw then forceWeatherNow(cw[0]) end
		if setts.custom.tt then memory.write(0xB70153, ct[0], 1, false) end
		
		hour = tonumber(os.date('%H', os.time() + diff))
		day = not (hour >= 21 or hour < 5)
	end
end

local characters = {
	{[0] = "1545.7757568359", [1] = "11.8175048828", [2] = "А"},
	{[0] = "1545.9359130859", [1] = "11.8175048828", [2] = "Б"},
	{[0] = "1546.1060791016", [1] = "11.8175048828", [2] = "В"},
	{[0] = "1546.0473632813", [1] = "11.3670654297", [2] = "Г"},
	{[0] = "1546.1975097656", [1] = "11.2869873047", [2] = "Д"},
	{[0] = "1546.3376464844", [1] = "11.2869873047", [2] = "Е"},
	{[0] = "1546.7366943359", [1] = "11.8175048828", [2] = "Ё"},
	{[0] = "1545.8360595703", [1] = "11.6873779297", [2] = "Ж"},
	{[0] = "1545.9962158203", [1] = "11.6873779297", [2] = "З"},
	{[0] = "1546.1363525391", [1] = "11.6873779297", [2] = "И"},
	{[0] = "1546.2764892578", [1] = "11.6873779297", [2] = "Й"},
	{[0] = "1546.4066162109", [1] = "11.6873779297", [2] = "К"},
	{[0] = "1546.5367431641", [1] = "11.6873779297", [2] = "Л"},
	{[0] = "1546.3576660156", [1] = "11.3670654297", [2] = "М"},
	{[0] = "1545.9465332031", [1] = "11.5672607422", [2] = "Н"},
	{[0] = "1546.0666503906", [1] = "11.5672607422", [2] = "О"},
	{[0] = "1546.4077148438", [1] = "11.3670654297", [2] = "П"},
	{[0] = "1546.2968750000", [1] = "11.5672607422", [2] = "Р"},
	{[0] = "1546.4169921875", [1] = "11.5672607422", [2] = "С"},
	{[0] = "1546.5270996094", [1] = "11.5672607422", [2] = "Т"},
	{[0] = "1546.6271972656", [1] = "11.5672607422", [2] = "У"},
	{[0] = "1545.9874267578", [1] = "11.4571533203", [2] = "Ф"},
	{[0] = "1546.1075439453", [1] = "11.4571533203", [2] = "Х"},
	{[0] = "1546.1674804688", [1] = "11.3670654297", [2] = "Ц"},
	{[0] = "1546.3277587891", [1] = "11.4571533203", [2] = "Ч"},
	{[0] = "1546.4578857422", [1] = "11.4571533203", [2] = "Ш"},
	{[0] = "1546.5880126953", [1] = "11.4571533203", [2] = "Щ"},
	{[0] = "1546.2662353516", [1] = "11.8175048828", [2] = "Г"},
	{[0] = "1546.0974121094", [1] = "11.3670654297", [2] = "П"},
	{[0] = "1546.2076416016", [1] = "11.4571533203", [2] = "Ц"},
	{[0] = "1546.2275390625", [1] = "11.3670654297", [2] = "Р"},
	{[0] = "1546.2475585938", [1] = "11.2869873047", [2] = "Ф"},
	{[0] = "1546.6868896484", [1] = "11.6873779297", [2] = "М"},
	{[0] = "1546.1867675781", [1] = "11.5672607422", [2] = "П"},
	{[0] = "1546.4063720703", [1] = "11.8074951172", [2] = "Д"},
	{[0] = "1546.5378417969", [1] = "11.3670654297", [2] = "Н"},
	{[0] = "1546.2976074219", [1] = "11.2869873047", [2] = "Й"},
	{[0] = "1546.1574707031", [1] = "11.2869873047", [2] = "А"},
	{[0] = "1546.4777832031", [1] = "11.3670654297", [2] = "Д"},
	{[0] = "1546.2875976563", [1] = "11.3670654297", [2] = "Ф"},
	{[0] = "1546.1074218750", [1] = "11.2869873047", [2] = "Й"},
	{[0] = "1546.5765380859", [1] = "11.8074951172", [2] = "Е"},
	{[0] = "1546.3876953125", [1] = "11.2869873047", [2] = "Ь"},
	{[0] = "1546.4277343750", [1] = "11.2869873047", [2] = "Ы"},
	{[0] = "1546.4777832031", [1] = "11.2869873047", [2] = "Х"}
}

function lfunc.getCharacter(pos)
	for i, v in ipairs(characters) do
		if ("%.10f"):format(pos.x) == v[0] and ("%.10f"):format(pos.z) == v[1] then return v[2] end end
	return 'Неизвестно(Обратитесь к разработчику)'
end

function fcmd.turnTimer()
	proxyStats.timer.state = not stats.timer.state
	msg(stats.timer.state and 'Счётчик запущен' or 'Счётчик остановлен')
end

function lfunc.resetStat()
	proxyStats.main={ tidex = 0, money = 0, award = 0, pilot = 0, countD = 0, countN = 0 }
	msg('Статистика сброшена')
end

local mainWin = imgui.OnFrame(function() return mainSt[0] and not isGamePaused() and not isPauseMenuActive() end,
function(self)
	mwSy = lareCost[0] and 342 or 242
	imgui.SetNextWindowPos(mVec2(setts.main.pX, setts.main.pY), imgui.Cond.FirstUseEver, mVec2(0, 0))
	imgui.SetNextWindowSize(mVec2(320, mwSy), 1)
	self.HideCursor = not mainSt[0]
	
    imgui.Begin('##MainWindow', _, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoSavedSettings + imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoCollapse)
		setts.main.pX, setts.main.pY = imgui.GetWindowPos().x, imgui.GetWindowPos().y
		imgui.PushFont(f18)
			imgui.CenterText(u8'PILOT HELPER v'..this.version)
		imgui.PopFont()
		imgui.CenterText('by '..table.concat(this.authors, ", "), 1)
		imgui.Separator()
		
		if imgui.Button(statsSt[0] and u8'Скрыть статистику' or u8'Показать статистику', mVec2(148, 24)) then statsSt[0] = not statsSt[0]; proxyCfg.main.statsSt = statsSt[0] end
		imgui.SameLine()
		if imgui.Button(u8'Сбросить статистику', mVec2(148, 24)) then lfunc.resetStat() end
		
		if imgui.Button(stats.timer.state and u8'Выключить счётчик' or u8'Включить счётчик', mVec2(148, 24)) then fcmd.turnTimer() end
		imgui.SameLine()
		if imgui.Button(u8'Сбросить счётчик', mVec2(148, 24)) then lfunc.resetTimer() end

		if imgui.Checkbox(u8'Авто-выбор частного самолёта', aUCustP) then proxyCfg.main.aUCustP = aUCustP[0] end
		
		imgui.PushItemWidth(162)
		if imgui.Button(fa('POWER_OFF')..'##weather', mVec2(22, 20)) then proxyCfg.custom.tw = not setts.custom.tw msg('Авто-изменение погоды: '..(setts.custom.tw and '{00ff00}Включено' or '{ff0000}Выключено')) end imgui.SameLine()
		if imgui.SliderInt(u8'Локальная погода', cw, 0, 45) then proxyCfg.custom.cw = cw[0] end
		if imgui.Button(fa('POWER_OFF')..'##time', mVec2(22, 20)) then proxyCfg.custom.tt = not setts.custom.tt end imgui.SameLine()
		if imgui.SliderInt(u8'Локальное время', ct, 0, 23) then proxyCfg.custom.ct = ct[0] end
		
		if imgui.Checkbox(u8'Распознавание букв у окулиста', showCharacters) then 
			proxyCfg.main.showCharacters = showCharacters[0]
			if showCharacters[0] and oculist then
				msg('Следующая буква: '..(nextChar:find('Неизвестно') and '{FF0000}' or '{00FF00}')..nextChar)
			end
		end
		if imgui.Checkbox(u8'Подсчёт цены ларцов', lareCost) then proxyCfg.main.lareCost = lareCost[0] end
		
		if lareCost[0] then
			imgui.PushItemWidth(210)
			imgui.Separator()
			imgui.CenterText(u8'Цены ларцов')
			if imgui.InputInt(u8'Ларец Tidex', cost.tidex, 0, 0) then
				if cost.tidex[0] < 0 then cost.tidex[0] = 0 end
				proxyCfg.cost.tidex = cost.tidex[0]
			end
			if imgui.InputInt(u8'Ларец Премии', cost.award, 0, 0) then
				if cost.award[0] < 0 then cost.award[0] = 0 end
				proxyCfg.cost.award = cost.award[0]
			end
			if imgui.InputInt(u8'Ларец Пилота', cost.pilot, 0, 0) then
				if cost.pilot[0] < 0 then cost.pilot[0] = 0 end
				proxyCfg.cost.pilot = cost.pilot[0]
			end
		end
		
		imgui.SetCursorPos(mVec2(imgui.GetWindowWidth()-47, 11))
		imgui.TextDisabled(fa('CIRCLE_QUESTION'))
		imgui.Hint('hint', u8'--- Автор:\nRevavi - t.me/SosuPercocet\n\n--- Команды скрипта:\n/pilot - открыть/закрыть меню\n/ptimer - включить/выключить счётчик\n\n--- Предупреждение\nДля корректного распознавания текущего времени суток (день/ночь), нужно перед началом смены звонить в службу точного времени.')
		
		imgui.SetCursorPos(mVec2(imgui.GetWindowWidth()-28, 8))
		imgui.PushStyleColor(imgui.Col.Button, zeroClr)
		imgui.PushStyleColor(imgui.Col.ButtonHovered, mVec4(0.8,0,0,0.36))
		imgui.PushStyleColor(imgui.Col.ButtonActive, zeroClr)
		if imgui.Button(fa('XMARK'), mVec2(20, 20)) then mainSt[0] = false end
		imgui.PopStyleColor(3)
    imgui.End()
end)

function lfunc.sumFormat(a, plus)
	if plus == nil then plus = true end
	if a == 0 then
		return 0
	else
		local b = ('%d'):format(a)
		local c = b:reverse():gsub('%d%d%d', '%1.')
		local d = c:reverse():gsub('^%.', '')
		if plus then return '+'..d else return d end
	end
end

local statsWin = imgui.OnFrame(function() return statsSt[0] and not isGamePaused() and not isPauseMenuActive() end,
function(self)
	imgui.SetNextWindowPos(mVec2(setts.main.spX, setts.main.spY), imgui.Cond.FirstUseEver, mVec2(0, 0))
	imgui.SetNextWindowSize(mVec2(300, 160))
	self.HideCursor = true
	
    imgui.Begin('##StatsWindow', _, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoSavedSettings + imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoCollapse)
		setts.main.spX, setts.main.spY = imgui.GetWindowPos().x, imgui.GetWindowPos().y
		imgui.PushFont(f18)
			imgui.CenterText(u8'Работа Пилота')
		imgui.PopFont()
		
		imgui.KolhozText(fa('DOLLAR_SIGN'), 'Зарплата:{ffffff} $'..lfunc.sumFormat(stats.main.money, false))
		imgui.KolhozText(fa('PLANE_ARRIVAL'), 'Рейсов: {ffffff}'..lfunc.sumFormat(stats.main.countD, false)..' {ffffff66}(День) {ffffff}| '..lfunc.sumFormat(stats.main.countN, false)..' {ffffff66}(Ночь)')
		imgui.KolhozText(fa('BOX_DOLLAR'), 'Ларцов премии: {ffffff}'..lfunc.sumFormat(stats.main.award))
		if lareCost[0] then imgui.SameLine(); imgui.TextDisabled('($'..lfunc.sumFormat(stats.main.award*cost.award[0])..')') end
		imgui.KolhozText(fa('PLANE_TAIL'), 'Ларцов пилота: {ffffff}'..lfunc.sumFormat(stats.main.pilot))
		if lareCost[0] then imgui.SameLine(); imgui.TextDisabled('($'..lfunc.sumFormat(stats.main.pilot*cost.pilot[0])..')') end
		imgui.KolhozText(fa('BOX'), 'Ларцов Tidex: {ffffff}'..lfunc.sumFormat(stats.main.tidex))
		if lareCost[0] then imgui.SameLine(); imgui.TextDisabled('($'..lfunc.sumFormat(stats.main.tidex*cost.tidex[0])..')') end
		
		imgui.PushFont(f25)
			imgui.CenterText(lfunc.getTimer(stats.timer.count))
		imgui.PopFont()
    imgui.End()
end)

function lfunc.counter()
	lua_thread.create(function()
		while true do
			wait(1000)
			if stats.timer.state then 
				stats.timer.count = stats.timer.count + 1
			end
		end
	end)
end

function lfunc.resetTimer()
	proxyStats.timer.count = 0
	proxyStats.timer.state = false
    msg('Счётчик сброшен.')
end

function lfunc.getTimer(time)
    local time2 = 86400 - os.date('%H', 0) * 3600
    if tonumber(time) >= 86400 then onDay = true else onDay = false end
    return os.date((onDay and math.floor(time / 86400)..u8'д ' or '')..'%H:%M:%S', time + time2)
end

function sampev.onServerMessage(color, text)
	text = text:gsub('%{......%}', '')
	text = text:gsub(',', '')
	if not text:find('(.+)_(.+)%[(%d+)%]') then
		if text:find('Присаживайтесь на стул напротив доски') then firstChar = true end
		if text:find('Врач--окулист: Произносите как называется выделенная буква') then
			oculist = true
			if showCharacters[0] then lua_thread.create(function() wait(50); msg('Следующая буква: '..(nextChar:find('Неизвестно') and '{FF0000}' or '{00FF00}')..nextChar) end) end
			firstChar = false
		end
		if text:find('Врач--окулист: Хорошо со зрением у Вас всё впорядке проходите к') or text:find('Врач--окулист: Увы Вы не правильно назвали выделенную букву') then oculist=false nextChar='Неизвестно(Обратитесь к разработчику)' end
		if text:find('%[Подсказка%] Рейс успешно завершен! Заработано за рейс: $(%d+) за смену всего: $(%d+)') then
			local money = text:match('Заработано за рейс: $(%d+)')
			if day then proxyStats.main.countD = stats.main.countD + 1 else proxyStats.main.countN = stats.main.countN + 1 end
			proxyStats.main.money = stats.main.money + money
		end
		if text:find('Благодаря улучшениям вашей семьи вы получаете дополнительную зарплату: $(%d+)') then
			local money = text:match('дополнительную зарплату: $(%d+)')
			proxyStats.main.money = stats.main.money + money
		end
		if text:find('За работу в рабочее время вашей организации вы получаете прибавку к зарплате: $(%d+).') then
			local money = text:match('прибавку к зарплате: $(%d+).')
			proxyStats.main.money = stats.main.money + money
		end
		if text:find('Получено вознаграждение: (.+)') then
			local larec = text:match('Получено вознаграждение: (.+)')
			if larec == 'Ларец Tidex.' then proxyStats.main.tidex = stats.main.tidex + 1 end
			if larec == 'Ларец с премией.' then proxyStats.main.award = stats.main.award + 1 end
			if larec == 'Ларец пилота.' then proxyStats.main.pilot = stats.main.pilot + 1 end
		end
	end
end

function sampev.onMoveObject(id, lastpos, newpos, speed, rot)
	if speed == 2 and isCharInArea2d(1, 1548, 1395, 1544, 1399, false) then
		if oculist or firstChar then 
			nextChar = lfunc.getCharacter(newpos)
			if showCharacters[0] and not firstChar then msg('Следующая буква: '..(nextChar:find('Неизвестно') and '{FF0000}' or '{00FF00}')..nextChar) end
		end
	end
end

function sampev.onShowDialog(dialogId, style, title, button1, button2, text)
	if title:find('Выберите самолет') and dialogId == 1421 and aUCustP[0] then
		lua_thread.create(function()
			wait(0)
			local tLines = lfunc.split(text, '\n')
			sampSendDialogResponse(dialogId, 1, #tLines-2 , nil)
			wait(1)
			sampCloseCurrentDialogWithButton(0)
		end)
	end
	if text:match("Текущее время") then
		day, month, year = text:match("Сегодняшняя дата: 	{2EA42E}(%d+):(%d+):(%d+)")
		hour, minu, sec = text:match("Текущее время: 	{345690}(%d+):(%d+):(%d+)")
		datetime = {year = year,month = month,day = day,hour = hour,min = minu,sec = sec}
		diff = tostring(os.time(datetime)) - os.time()
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
	if script == this then
		inicfg.save(setts, directIni)
	end
end

function lfunc.theme()
	imgui.SwitchContext()
	local style = imgui.GetStyle()
	local colors = style.Colors
	local clr = imgui.Col

	style.WindowPadding = mVec2(8, 8)
	style.ItemSpacing = mVec2(5, 5)

	style.WindowBorderSize = 0
	style.PopupBorderSize = 0
	style.FrameBorderSize = 0
	style.ScrollbarSize = 9

	style.WindowRounding = 7
	style.ChildRounding = 7
	style.FrameRounding = 4
	style.PopupRounding = 7
	style.GrabRounding = 7
	style.TabRounding = 7

	colors[clr.Text] = mVec4(1.00, 1.00, 1.00, 1.00)
	colors[clr.TextDisabled] = mVec4(1.00, 1.00, 1.00, 0.40)
	colors[clr.BorderShadow] = zeroClr
	colors[clr.FrameBg] = mVec4(0.50, 0.50, 0.50, 0.30)
	colors[clr.FrameBgHovered] = mVec4(0.50, 0.50, 0.50, 0.50)
	colors[clr.FrameBgActive] = mVec4(0.50, 0.50, 0.50, 0.20)
	colors[clr.CheckMark] = mVec4(1.00, 1.00, 1.00, 1.00)
	colors[clr.Button] = colors[clr.FrameBg]
	colors[clr.ButtonHovered] = colors[clr.FrameBgHovered]
	colors[clr.ButtonActive] = colors[clr.FrameBgActive]
	colors[clr.Separator] = mVec4(0.80, 0.80, 0.80, 0.50)
	colors[clr.SeparatorHovered] = colors[clr.Separator]
	colors[clr.SeparatorActive] = colors[clr.Separator]
	colors[clr.SliderGrab] = mVec4(0.50, 0.50, 0.50, 0.50)
	colors[clr.SliderGrabActive] = mVec4(0.50, 0.50, 0.50, 0.70)
end

imgui.OnInitialize(function()
    lfunc.theme()
	
	imgui.GetIO().IniFilename = nil
    local config = imgui.ImFontConfig()
    config.MergeMode = true
    config.PixelSnapH = true
    iconRanges = mn.ImWchar[3](fa.min_range, fa.max_range, 0)
    imgui.GetIO().Fonts:AddFontFromMemoryCompressedBase85TTF(fa.get_font_data_base85('solid'), 14, config, iconRanges)
	f18 = imgui.GetIO().Fonts:AddFontFromFileTTF(getFolderPath(0x14) .. '//trebucbd.ttf', 18, _, imgui.GetIO().Fonts:GetGlyphRangesCyrillic())
	f25 = imgui.GetIO().Fonts:AddFontFromFileTTF(getFolderPath(0x14) .. '//trebucbd.ttf', 25, _, imgui.GetIO().Fonts:GetGlyphRangesCyrillic())
end)

function lfunc.split(str, delim, plain)
	local tokens, pos, plain = {}, 1, not (plain == false)
	repeat
		local npos, epos = string.find(str, delim, pos, plain)
		table.insert(tokens, string.sub(str, pos, npos and npos - 1))
		pos = epos and epos + 1
	until not pos
	return tokens
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
	imgui.TextColoredRGB(text)
end

function imgui.Hint(str_id, hint)
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

function imgui.TextColoredRGB(text)
    local style = imgui.GetStyle()
    local colors = style.Colors
    local ImVec4 = imgui.ImVec4

    local explode_argb = function(argb)
        local a = bit.band(bit.rshift(argb, 24), 0xFF)
        local r = bit.band(bit.rshift(argb, 16), 0xFF)
        local g = bit.band(bit.rshift(argb, 8), 0xFF)
        local b = bit.band(argb, 0xFF)
        return a, r, g, b
    end

    local getcolor = function(color)
        if color:sub(1, 6):upper() == 'SSSSSS' then
            local r, g, b = colors[1].x, colors[1].y, colors[1].z
            local a = tonumber(color:sub(7, 8), 16) or colors[1].w * 255
            return ImVec4(r, g, b, a / 255)
        end
        local color = type(color) == 'string' and tonumber(color, 16) or color
        if type(color) ~= 'number' then return end
        local r, g, b, a = explode_argb(color)
        return imgui.ImVec4(r/255, g/255, b/255, a/255)
    end

    local render_text = function(text_)
        for w in text_:gmatch('[^\r\n]+') do
            local text, colors_, m = {}, {}, 1
            w = w:gsub('{(......)}', '{%1FF}')
            while w:find('{........}') do
                local n, k = w:find('{........}')
                local color = getcolor(w:sub(n + 1, k - 1))
                if color then
                    text[#text], text[#text + 1] = w:sub(m, n - 1), w:sub(k + 1, #w)
                    colors_[#colors_ + 1] = color
                    m = n
                end
                w = w:sub(1, n - 1) .. w:sub(k + 1, #w)
            end
            if text[0] then
                for i = 0, #text do
                    imgui.TextColored(colors_[i] or colors[1], u8(text[i]))
                    imgui.SameLine(nil, 0)
                end
                imgui.NewLine()
            else imgui.Text(u8(w)) end
        end
    end

    render_text(text)
end