if not getMoonloaderVersion then
    return print("This script requires MoonLoader to be installed")
end

require("moonloader")
require("SA-MP API")

script_name("Admin Helper")
script_author("Meow Zanetti")
script_description("Admins information system")
script_version("0.6")

local imgui = require("imgui")
local key = require("vkeys")

local encoding = require("encoding")
local dl = require("SA-MP API.init")
local u8 = encoding.UTF8
encoding.default = "CP1251"
local lfs = require('lfs')

local bNotf, notf = pcall(import, "imgui_notf.lua")

local dlstatus = require('moonloader').download_status

local copas = require 'copas'
local http = require 'copas.http'

local fa = require 'fAwesome5'
local lfs = require 'lfs'

local directIni = getWorkingDirectory().."\\settings.ini"
local inicfg = require 'inicfg'

local HLcfg = inicfg.load({
    config = {
        checkbox1 = false;
        checkbox2 = false;
        checkbox3 = false;
        checkbox4 = false;
        theme = 1;
    }
}, directIni)
inicfg.save(HLcfg, directIni)

local ffi = require("ffi")
ffi.cdef[[
int __stdcall GetVolumeInformationA(
    const char* lpRootPathName,
    char* lpVolumeNameBuffer,
    uint32_t nVolumeNameSize,
    uint32_t* lpVolumeSerialNumber,
    uint32_t* lpMaximumComponentLength,
    uint32_t* lpFileSystemFlags,
    char* lpFileSystemNameBuffer,
    uint32_t nFileSystemNameSize
);
]]
local serial = ffi.new("unsigned long[1]", 0)
ffi.C.GetVolumeInformationA(nil, nil, 0, serial, nil, nil, nil, 0)
serial = serial[0]

local update_url = "https://raw.githubusercontent.com/LamprechtTawer/AdminHelper/master/update.ini"
local script_url = "https://github.com/LamprechtTawer/AdminHelper/blob/main/AdminHelper.luac?raw=true"
local script_path = thisScript().path
local update_path = getWorkingDirectory().."\\update.ini"
local update_state = false
local script_vers = 3

local urls = "https://gta-samp.ru/index.php?option=com_content&view=article&id=140"

local me_link = 'https://vk.com/voskresensky2k'

local site = 'https://github.com/LamprechtTawer/AdminHelper/raw/main/admins.txt'

local main_window_state = imgui.ImBool(false)
local vehs_window_state = imgui.ImBool(false)
local su_window_state = imgui.ImBool(false)
local active_window = 0
local active_veh = 1

local themes = import "lib\\imgui_themes.lua"
local checked_radio = imgui.ImInt(HLcfg.config.theme)

local osk_window_state = imgui.ImBool(HLcfg.config.checkbox1)
local sec_window_state = imgui.ImBool(HLcfg.config.checkbox2)
local time_window_state = imgui.ImBool(HLcfg.config.checkbox3)
local swatch_window_state = imgui.ImBool(HLcfg.config.checkbox4)

local checkbox_osk = imgui.ImBool(osk_window_state.v)
local checkbox_sec = imgui.ImBool(sec_window_state.v)
local checkbox_time = imgui.ImBool(time_window_state.v)
local checkbox_swatch = imgui.ImBool(swatch_window_state.v)

local main_buffer = imgui.ImBuffer(256)
local su_buffer = imgui.ImBuffer(4)
local vk_buffer = imgui.ImBuffer(256)

local login_buffer = imgui.ImBuffer(tostring(HLcfg.config.login), 100)
local pass_buffer = imgui.ImBuffer(tostring(HLcfg.config.pass), 100)

function getDatePC(arg)
	local t = os.date("*t")
	if tonumber(arg) == 1 then return tostring(t.year) end
	if tonumber(arg) == 2 then return tostring(t.month) end
	if tonumber(arg) == 3 then return tostring(t.day) end
end

local year_buffer = imgui.ImBuffer(os.date("%Y"), 5)
local month_buffer = imgui.ImBuffer(getDatePC(2), 3)
local day_buffer = imgui.ImBuffer(getDatePC(3), 3)
local accnumb_buffer = imgui.ImBuffer(100)

if not doesDirectoryExist(getWorkingDirectory().."\\logs") then createDirectory(getWorkingDirectory().."\\logs") end
if not doesDirectoryExist(getWorkingDirectory().."\\logs\\temp") then createDirectory(getWorkingDirectory().."\\logs\\temp") end

local strLogs = {}

local iconfont = nil
local fontsize15 = nil
local fontsize20 = nil
local result = nil

local timeLog = {}
local timer = {
	bool = false,
	start_time = 0,
	time = 0
}

local rod = 0
local statlog = 'Ожидание'

local cmt = 'FFFFFF'
local smt = 'FADC32'
local rmt = 'FF0000'
local gmt = '008000'

function main()
    repeat wait(0); until dl.GetIsAvailable();
	
	local bool, users = getTableUsersByUrl(site)
	if not bool then printlog("Ошибка лицензии") end
	if not isAvailableUser(users, tostring(serial)) then printlog("Срок лицензии просрочен либо не выдан") end
	
	local fullip = dl.getServerIp()..':'..dl.getServerPort()
	if fullip ~= "185.71.66.95:7771" then
		dl.AddMessageToChat(4, "["..thisScript().name.."] {FFFFFF}Admin Helper отключен!", "", 0xBA55D3, 0xBA55D3)
		printlog("Выгрузка вне сервера")
		thisScript():unload()
		return
	end
	
	downloadUrlToFile(update_url, update_path, function(id, status)
        if status == dlstatus.STATUS_ENDDOWNLOADDATA and doesFileExist(update_path) then
            local updateIni = inicfg.load(nil, update_path)
			if updateIni then
				if tonumber(updateIni.info.vers) > script_vers then
					if bNotf then
						notf.addNotification("Доступна версия " .. updateIni.info.vers_text .. ".", 4, HLcfg.config.theme)
					end
					update_state = true
					printlog("Обновление скрипта...")
				end
			else
				printlog("Ошибка обновления")
			end
            os.remove(update_path)
        end
    end)
	
	imgui.Process = true
	imgui.SwitchContext()
	themes.SwitchColorTheme(HLcfg.config.theme)
	
	dl.RegisterClientCommand("on", Vkl, "on")
	threadon = lua_thread.create_suspended(thread_on)
	
	dl.AddMessageToChat(4, "["..thisScript().name.."] {FFFFFF}Admin Helper запущен. Текущая версия: {"..smt.."}" ..thisScript().version..".", "", 0xBA55D3, 0xBA55D3) -- 4 это тип сообщения, Hello men текст, "" префикс (не используется), и последнии два параметра цвет текст и префикса
	dl.AddMessageToChat(4, "["..thisScript().name.."] {FFFFFF}Открыть главное окно можно кнопкой {"..smt.."}F2 {FFFFFF}или чит-кодом {"..smt.."}GH.", "", 0xBA55D3, 0xBA55D3)
	
	while true do
        wait(0)
        if testCheat('GH') or isKeyJustPressed(VK_F2) then
			if not main_window_state.v then
				main_window_state.v = true
				imgui.Process = main_window_state.v
			else
				main_window_state.v = not main_window_state.v
			end
        end
		if testCheat('CARS') or isKeyJustPressed(VK_F3) then
			if not vehs_window_state.v then
				vehs_window_state.v = true
				imgui.Process = vehs_window_state.v
			else
				vehs_window_state.v = not vehs_window_state.v
			end
        end
		if testCheat('SU') then
			if not su_window_state.v then
				su_window_state.v = true
				imgui.Process = su_window_state.v
			else
				su_window_state.v = not su_window_state.v
			end
        end
		if update_state then
            downloadUrlToFile(script_url, script_path, function(id, status)
                if status == dlstatus.STATUS_ENDDOWNLOADDATA then
					if bNotf then
						notf.addNotification("Admin Helper обновлен!", 4, HLcfg.config.theme)
					end
					printlog("Перезагрузка после обновления скрипта...")
                    thisScript():reload()
                end
            end)
            break
        end
		if not main_window_state.v and not vehs_window_state.v then
			imgui.SetMouseCursor(imgui.MouseCursor.None)
			imgui.ShowCursor = false
		else
			imgui.ShowCursor = true
		end
		if isKeyJustPressed(VK_F4) then
			if imgui.Process then
				imgui.Process = false
			else
				imgui.Process = true
			end
        end
    end
end

function onScriptTerminate(script, quitGame)
	if script == thisScript() then
		showCursor(false)
		lockPlayerControl(false)
		dl.AddMessageToChat(4, "["..thisScript().name.."] {FFFFFF}Bye bye :c", "", 0xBA55D3, 0xBA55D3)
	end
end

function onExitScript()
    dl.DeleteClientCommand("on")
end

function Vkl()
	threadon:run()
end

function thread_on()
	--[[
	dl.SendChat("/пнр Franklin_Excellent Жалоба на игроков во фракции №678") -- без докв вывел чела из мэрии
	wait(1000)
	dl.SendChat("/т Byter_Nelson 18000 Жалоба на игроков во фракции №670") -- убил чела на авс без докв
	]]
end

local deletedir
deletedir = function(dir)
    for file in lfs.dir(dir) do
        local file_path = dir..'/'..file
        if file ~= "." and file ~= ".." then
            if lfs.attributes(file_path, 'mode') == 'file' then
                os.remove(file_path)
                print('remove file',file_path)
            elseif lfs.attributes(file_path, 'mode') == 'directory' then
                print('dir', file_path)
                deletedir(file_path)
            end
        end
    end
    lfs.rmdir(dir)
    print('remove dir',dir)
end

function imgui.OnDrawFrame()
	if not main_window_state.v and not osk_window_state.v and not sec_window_state.v and not time_window_state.v and not swatch_window_state.v and not vehs_window_state.v and not su_window_state.v then
		imgui.Process = false
		active_window = 0
		active_vehs = 1
	end
	if HLcfg.config.theme == 6 then
		cmt = '000000'
		smt = 'D3AE31'
	else
		cmt = 'FFFFFF'
		smt = 'FADC32'
	end
	if main_window_state.v then
		local sw, sh = getScreenResolution()
		imgui.SetNextWindowPos(imgui.ImVec2(sw / 2, sh / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.915, 0.4))
		imgui.SetNextWindowSize(imgui.ImVec2(1000, 600), imgui.Cond.FirstUseEver)
		imgui.Begin(u8(thisScript().name .. " v" ..thisScript().version), main_window_state, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.AlwaysAutoResize + imgui.WindowFlags.MenuBar)
		if active_window == 0 then
			imgui.BeginChild(u8"Привет!", imgui.ImVec2(992, 550), true)
				imgui.PushFont(fontsize15)
				imgui.TextColoredRGB("{"..rmt.."}Привет! Прочитай текст ниже для ознакомления с Helper'ом")
				imgui.SameLine()
				imgui.Link(me_link, u8"VK разработчика")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..cmt.."}Вверху Вы видите меню-бар, подробнее о нем:")
				imgui.TextColoredRGB("{"..smt.."}1. {"..cmt.."}'Меню' - перезагрузка и выключение скрипта")
				imgui.TextColoredRGB("{"..cmt.."}Чтобы включить скрипт после выключения нажмите {"..smt.."}Ctrl+R")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}2. {"..cmt.."}'Нормативы по фракциям' - расписаны наказания, которые относятся к выбранной фракции")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}3. {"..cmt.."}'Общие нормативы' - Общие нормативы наказаний, которые не относятся к фракциям")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}4. {"..cmt.."}'Багоюз/Читы' - Нормативы наказаний по багоюзу и читам, ракботы")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}5. {"..cmt.."}'Нормативы чата' - Нормативы наказаний по чату")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}6. {"..cmt.."}'Информация' - информация по сейфу домов, работ мэрии, скиллов оружия, рисунках на транспорте")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}7. {"..cmt.."}'Настройки' - включение/выключение окон с оскорблениями и нормативами чата,")
				imgui.TextColoredRGB("{"..cmt.."}конвертер минут в секунды, выбор темы, сохранение админ. логина и пароля")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}8. {"..cmt.."}'Обновить' - проверить Helper на наличие обновлений")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}9. {"..cmt.."}'Логи' - проверка логов чата игроков")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}10. {"..cmt.."}'Главная' - переход на эту вкладку из других")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..cmt.."}Закрыть это окно можно крестиком в верхнем правом углу либо комбинацией {"..smt.."}HM {FFFFFF}или кнопкой {"..smt.."}F2")
				imgui.TextColoredRGB("{"..cmt.."}Временно скрыть все окна на {"..smt.."}F4")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..cmt.."}Меню транспорта можно открыть комбинацией {"..smt.."}CARS {FFFFFF}или кнопкой {"..smt.."}F3")
				imgui.PopFont()
			imgui.EndChild()
		end
		if imgui.BeginMenuBar() then
            if imgui.BeginMenu(u8'Меню') then
				if imgui.MenuItem(u8'Перезагрузить') then thisScript():reload() end
                if imgui.MenuItem(u8'Выключить') then thisScript():unload() end
                imgui.EndMenu()
            end
            if imgui.BeginMenu(u8'Нормативы по фракциям') then
                if imgui.MenuItem(u8'Полиция') then active_window = 1 end
                if imgui.MenuItem(u8'Армия') then active_window = 2 end
                if imgui.MenuItem(u8'Ghetto') then active_window = 5 end
                if imgui.MenuItem(u8'Мафия') then active_window = 6 end
                if imgui.MenuItem(u8'СМИ') then active_window = 8 end
                if imgui.MenuItem(u8'Мэрия') then active_window = 9 end
                if imgui.MenuItem(u8'Больница') then active_window = 10 end
                imgui.EndMenu()
            end
			if imgui.MenuItem(u8'Общие нормативы') then active_window = 3 end
			 if imgui.BeginMenu(u8'Багоюз/Читы') then
                if imgui.MenuItem(u8'Нормативы') then active_window = 11 end
                if imgui.MenuItem(u8'Ракботы') then active_window = 14 end
                imgui.EndMenu()
            end
			if imgui.MenuItem(u8'Нормативы чата') then active_window = 12 end
			if imgui.MenuItem(u8'Информация') then active_window = 13 end
			if imgui.MenuItem(u8'Настройки') then active_window = 4 end
			if imgui.MenuItem(u8'Обновить') then updateHelper() end
			if imgui.MenuItem(u8'Логи') then active_window = 15 end
			if imgui.MenuItem(u8'Главная') then active_window = 0 end
		end
        imgui.EndMenuBar()
		
		if active_window == 15 then
			imgui.NewInputText('##SearchBarY', year_buffer, 60, u8'Год', 1)
			imgui.SameLine()
			imgui.NewInputText('##SearchBarM', month_buffer, 60, u8'Месяц', 1)
			imgui.SameLine()
			imgui.NewInputText('##SearchBarD', day_buffer, 60, u8'День', 1)
			imgui.SameLine()
			imgui.NewInputText('##SearchBarA', accnumb_buffer, 180, u8'Ник или номер аккаунта', 1)
			
			imgui.SameLine()
			imgui.SetCursorPosX(727)
			--imgui.SetCursorPos(imgui.ImVec2(отступ слева, отступ сверху))
			if imgui.Button(u8 "Удалить логи за эту дату") then
				local logf = getWorkingDirectory().."\\logs\\temp\\"..tostring(year_buffer.v).."."..tostring(month_buffer.v).."."..tostring(day_buffer.v)..".txt"
				if doesFileExist(logf) then
					statlog = 'Введенный лог удален!'
					os.remove(logf)
					if bNotf then
						notf.addNotification("Удалено!", 4, HLcfg.config.theme)
					end
					printlog("Введенный лог удален")
				else
					if bNotf then
						notf.addNotification("Лог не найден!", 4, HLcfg.config.theme)
					end
					printlog("Данные не введены")
				end
			end
			imgui.SameLine()
			if imgui.Button(u8 "Удалить все логи") then
				if doesFileExist(getWorkingDirectory()..'\\logs\\temp') then
					statlog = 'Все логи удалены!'
					deletedir(getWorkingDirectory().."\\logs\\temp")
					createDirectory(getWorkingDirectory().."\\logs\\temp")
					if bNotf then
						notf.addNotification("Удалено!", 4, HLcfg.config.theme)
					end
					printlog("Все логи удалены")
				else
					printlog("Все логи отсутствуют")
				end
			end
			
			if imgui.Button(u8 "Загрузить") then
				if accnumb_buffer.v then
					statlog = 'Загрузка...'
					downLogs(year_buffer.v, month_buffer.v, day_buffer.v, accnumb_buffer.v)
				end
			end
			
			imgui.SameLine()
			imgui.TextQuestion(u8"(?)", "Логин и пароль во вкладке 'Настройки'")
			imgui.SameLine()
			if statlog ~= nil then imgui.Text(u8"Статус: "..u8(statlog)) end
			
			imgui.BeginChild(u8"Логи", imgui.ImVec2(992, 550), true, imgui.WindowFlags.VerticalScrollbar)
			if rod == 1 then
				for i,v in ipairs(strLogs) do
					imgui.Text(u8(v))
				end
			else
				imgui.Text(u8"Пусто")
			end
			imgui.EndChild()
		end
		
		--if doesFileExist(os.getenv("TEMP").."\\"..name_log_file..".txt") then
		--local rrdd = io.open(os.getenv("TEMP").."\\"..name_log_file..".txt")
		if active_window == 1 then
			imgui.BeginChild(u8"Полиция", imgui.ImVec2(992, 550), true)
				imgui.PushFont(fontsize15)
				imgui.TextColoredRGB("{"..smt.."}1) nonRP поведение сотрудника МВД:{"..cmt.."} (/т [id] 3600 nonRP поведение сотрудника МВД) (1ч)")
				imgui.TextColoredRGB("{"..cmt.."}-> Наручники без причины")
				imgui.TextColoredRGB("{"..cmt.."}-> Тайзер без причины")
				imgui.TextColoredRGB("{"..cmt.."}-> Посадка в транспорт без причины")
				imgui.TextColoredRGB("{"..cmt.."}-> Полицейский выкидывает на ходу игроков из транспорта, находясь при этом за рулем патрульного автомобиля")
				imgui.TextColoredRGB("{"..rmt.."}(искл. если нарушитель находится на любом виде вело-транспорта, на авто/мото у которых макс. скорость 200 км/ч и выше)")
				imgui.Spacing()
				imgui.TextColoredRGB("{"..cmt.."}-> Выдача розыска после своей смерти")
				imgui.TextColoredRGB("{"..cmt.."}-> Тайзер на лету {FF0000}(искл. нарушитель стреляет со снайперки)")
				imgui.TextColoredRGB("{"..cmt.."}-> Посадка игрока в КПЗ, который не подает каких-либо признаков жизни")
				imgui.TextColoredRGB("{"..cmt.."}-> Посадка игрока в КПЗ, который находился в маске {FF0000}(искл. если маска была надета при сотруднике МВД)")
				imgui.Spacing()
				imgui.TextColoredRGB("{"..cmt.."}-> Садить в авто, находясь в движении. В мото {008000}разрешено {"..cmt.."}только если нарушитель стреляет со снайперки")
				imgui.TextColoredRGB("{"..cmt.."}-> Использовать возможность задержать игрока в воде через отыгровку,")
				imgui.TextColoredRGB("{"..cmt.."}при этом находясь от игрока на большом расстоянии или отыгрывая подряд только строку с задержанием")
				imgui.Spacing()
				imgui.TextColoredRGB("{"..cmt.."}-> Взлом двери дома без причины или отыгровки")
				imgui.TextColoredRGB("{"..cmt.."}-> Поставить/убрать водную подушку без RP отыгровки")
				imgui.TextColoredRGB("{"..cmt.."}-> Ликвидация/посадка в КПЗ с лишним розыском")
				imgui.TextColoredRGB("{"..cmt.."}-> Кинуть тайзер/наручники через стены/высокие заборы")
				imgui.TextColoredRGB("{"..cmt.."}-> Сажать в КПЗ прямо из транспорта, а так же стоя посреди полицейского участка либо далеко от решеток")
				imgui.TextColoredRGB("{"..cmt.."}-> Поставить/убрать блокиратор колес без RP отыгровки")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}2) nonRP полицейский:{"..cmt.."} (/пнр [id] nonRP police)")
				imgui.TextColoredRGB("{"..cmt.."}-> Убийство без отыгровок/TK/Слишком явное превышение своих полномочий (в ситуациях когда абузят правила)")
				imgui.TextColoredRGB("{"..cmt.."}-> Если одновременно сделано много киллов, то за 1-ый даётся варн, за все остальные наказывать как за обычный DM")
				imgui.TextColoredRGB("{"..cmt.."}-> Ликвидация игрока, который в AFK с надписью над головой")
				imgui.TextColoredRGB("{"..cmt.."}(будьте внимательны при выдаче наказания, т.к. если игрок ушел AFK во время погони, сотрудник МВД имеет право его ликвидировать)")
				imgui.Spacing()
				imgui.TextColoredRGB("{"..cmt.."}-> Злоупотребление запрещёнными пунктами из норматива 'nonRP поведение сотрудника МВД'")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}3) Мониторинг бизвара:{"..cmt.."} (/т [id] 7200 Мониторинг бизвара) (2ч)")
				imgui.TextColoredRGB("{"..cmt.."}-> Мониторить бизвар, находясь на территории самого бизвара или рядом с ним (стоять с целью поиска любых нарушений от мафиози)")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}4) PG:{"..cmt.."} (/т [id] 7200 PG) (2ч)")
				imgui.TextColoredRGB("{"..cmt.."}-> Штраф/арест на бизваре из-за имеющегося розыска. {FF0000}Если розыск выдан полицейским - арестовывать можно")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}5) RK:{"..cmt.."} (/т [id] 18000 RК) (5ч)")
				imgui.TextColoredRGB("{"..cmt.."}-> Полицейский вернулся после смерти к игроку, который его убил и далее без каких-либо приветствий/просьб показать паспорт,")
				imgui.TextColoredRGB("{"..cmt.."}начал проводить арест (кидать тайзер, надевать наручники, ликвидировать и т.д.)")
				imgui.Spacing()
				imgui.TextColoredRGB("{"..rmt.."}-> Полицейские могут отправлять запросы помощи другим копам, учтите это")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}6) Убийство игрока в клетке:{"..cmt.."} (/т [id] 7200 Убийство игрока в клетке) (2ч)")
				imgui.TextColoredRGB("{"..cmt.."}-> Полицейский через решетку убивает игрока, находящегося за решеткой КПЗ")
				imgui.TextColoredRGB("{"..cmt.."}-> Если у игрока был розыск и после ликвидации срок кпз увеличился - варн")
				imgui.TextColoredRGB("{"..cmt.."}Сделано это для того, чтобы полицейским было неповадно убивать своих же заключенных")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}7) Биндер с запрещённым функционалом:{"..cmt.."} (/чм [id])")
				imgui.TextColoredRGB("{"..cmt.."}-> Кидать в читерский мир сразу не нужно. Поговорите с игроком, объясните, что у него не так с биндером и укажите на его ошибки")
				imgui.TextColoredRGB("{"..cmt.."}-> В случае, если игрок злоупотребляет запрещенным функционалом, разрешается кинуть его в ЧМ без каких-либо диалогов")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}8) Бред в выдаче розыска:{"..cmt.."} (/зк [id] 3600 Бред в выдаче розыска) (1ч)")
				imgui.TextColoredRGB("{"..cmt.."}-> Пример: розыск с причиной 'кек'")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}9) Ошибка в RP отыгровках:{"..cmt.."} (/т [id] 1800 Не полная/не верная отыгровка) (30м)")
				imgui.TextColoredRGB("{"..cmt.."}-> Пропуск действий в RP, которые сделаны в спец. темах и имеют конкретный шаблон обязательных действий")
				imgui.TextColoredRGB("{"..cmt.."}-> Неверный порядок действий в RP, которые сделаны в спец. темах и имеют конкретный шаблон обязательных действий")
				imgui.TextColoredRGB("{"..cmt.."}-> Наличие отсчёта цифрами, а не словами")
				imgui.TextColoredRGB("{"..cmt.."}-> Присутствует прогон и RP отыгровка оружия, но убили игрока не дожидаясь его ухода с прогоняемой территории")
				imgui.TextColoredRGB("{"..cmt.."}-> Пропущено название оружия, которое пишется в ковычках")
				imgui.TextColoredRGB("{"..cmt.."}-> Пропущен тип оружия, которое пишется перед названием, но при этом название в ковычках есть")
				imgui.TextColoredRGB("{"..cmt.."}-> Пропущено уточнение откуда достал и куда убрал оружие")
				imgui.TextColoredRGB("{"..cmt.."}-> Пропущена отыгровка как игрок убирает оружие")
				imgui.TextColoredRGB("{"..cmt.."}-> Гравировка на служебном оружии")
				imgui.TextColoredRGB("{"..cmt.."}-> На тренировке/пвп сделана RP отыгровка оружия огнестрельного, а не пневматического")
				imgui.TextColoredRGB("{"..cmt.."}-> Посадка в ТС/Наручники/Взлом двери дома без отыгровки")
				imgui.TextColoredRGB("{"..cmt.."}-> В текстах отыгровок полицейскому нельзя применять оскорбления/хамство или любые недопустимые для сотрудника полиции выражения")
				imgui.TextColoredRGB("{"..cmt.."}(Например: /фд Кусок мяса*... ; /фд Садись на бутылочку*закрывая решетку КПЗ)")
				imgui.Spacing()
				imgui.TextColoredRGB("{"..cmt.."}-> Пропущено уточнение какими патронами было заряжено оружие")
				imgui.TextColoredRGB("{"..cmt.."}-> Нанесение урона/стрельба в сторону игрока из оружия с GPS патронами")
				imgui.TextColoredRGB("{"..cmt.."}-> Стрельба по транспорту из оружия с GPS патронами (после выстрела и успешной установки датчика должны перезарядить")
				imgui.TextColoredRGB("{"..cmt.."}оружие боевыми патронами и только потом продолжать стрельбу по т/c)")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}10) RP отыгровка оружия/кулаков и т.д в ситуациях когда убивают другого игрока")
				imgui.TextColoredRGB("{"..cmt.."}-> Наказывать как за DM, но не варном, а КПЗ. Срок КПЗ как для игрока без фракции")
				imgui.TextColoredRGB("{"..cmt.."}-> Если не отыграли как достали оружие/кулаки и убили игрока, но при этом отыграно что убрали оружие/кулаки")
				imgui.TextColoredRGB("{"..cmt.."}-> Если отыграли что убрали оружие и убили игрока")
				imgui.TextColoredRGB("{"..cmt.."}-> Отыграно не то оружие с которого убили/стреляли")
				imgui.TextColoredRGB("{"..cmt.."}-> Отыграно что достали оружие уже после убийства")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..rmt.."}(!) Пневматическое оружие могут передать по RP игроку с заглушкой и оно действует на время кб/дуэли")
				imgui.PopFont()
			imgui.EndChild()
		end
		if active_window == 2 then
			imgui.BeginChild(u8"Армия", imgui.ImVec2(992, 550), true)
				imgui.PushFont(fontsize15)
				imgui.TextColoredRGB("{"..smt.."}1) Бронь в бою: {"..cmt.."}(/т [id] 3600 Бронь в бою) (1ч)")
				imgui.TextColoredRGB("{"..cmt.."}-> Наказывать только тогда, когда игрок вёл с кем-то бой/выцеливал и т.п. и после этого побежал на маркер")
				imgui.TextColoredRGB("{"..cmt.."}-> В каких-то ситуациях бывают исключения, лучше советуйтесь в ВК")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}2) DM/TK/Игнор кода-3: {"..cmt.."}(/т [id] 18000 DM/TK/Игнор кода-3) (5ч)")
				imgui.TextColoredRGB("{"..cmt.."}-> Игнор кода-3. Например, подвезти бандита/мафиози на базу/АВС с целью помощи или же не убивать в какой-то ситуации")
				imgui.TextColoredRGB("{"..rmt.."}-> Полно нюансов, лучше советуйтесь в ВК")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}3) Стрельба/Урон/Убийство согласно правилу 'Брат за брата':")
				imgui.TextColoredRGB("{"..cmt.."}/т [id] 1800 nonRP стрельба (30м)")
				imgui.TextColoredRGB("{"..cmt.."}/т [id] 3600 Нанесение урона (1ч)")
				imgui.TextColoredRGB("{"..cmt.."}/т [id] 18000 DM (5ч)")
				imgui.TextColoredRGB("{"..rmt.."}-> Третьему лицу разрешено вмешиваться только при налиции доказательств нападения и RP-отыгровки")
				imgui.TextColoredRGB("{"..cmt.."}-> Если убивают вообще без отыгровок то наказывать полным сроком по нормативу DM")
				imgui.TextColoredRGB("{"..cmt.."}-> Использовать правило можно везде, не только вблизи базы/зон обстрела или обороны")
				imgui.TextColoredRGB("{"..cmt.."}-> В жалобах на форуме можете смело наказывать, если игрок не предоставил доказательств нападения")
				imgui.TextColoredRGB("{"..cmt.."}-> Могут возникнуть спорные ситуации, по которым желательно советоваться, поскольку норматив новый")
				imgui.TextColoredRGB("{"..cmt.."}-> Норматив также распространяется на ситуации, где военные могут защищать министра от нападения")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}4) SK: {"..cmt.."}(/т [id] 18000 SK) (5ч)")
				imgui.TextColoredRGB("{"..cmt.."}-> Если военный вышел из казармы и остался в синей зоне, при этом начал перестрелку")
				imgui.TextColoredRGB("{"..rmt.."}-> Если военный возвращается в синюю зону с целью забайтить бандита на нарушение")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}5) Стрельба/Урон/Убийство вне территории АВС:")
				imgui.TextColoredRGB("{"..cmt.."}/т [id] 1800 nonRP стрельба (30м)")
				imgui.TextColoredRGB("{"..cmt.."}/т [id] 3600 Нанесение урона (1ч)")
				imgui.TextColoredRGB("{"..cmt.."}/т [id] 18000 Слив вне терры АВС (5ч)")
				imgui.TextColoredRGB("{"..cmt.."}-> Перестрелки ведутся в зеленой зоне (либо в красной, если смотреть по радару на карте)")
				imgui.TextColoredRGB("{"..cmt.."}-> Если стреляют/наносят урон/сливают игрока, находясь вне зоны, наказывать по этому нормативу")
				imgui.TextColoredRGB("{"..rmt.."}-> Будьте внимательнее, потому что в таких ситуациях возможна самооборона")
				imgui.TextColoredRGB("{"..cmt.."}-> Также если военный/мафиози покинул зону, но был в ней, то его разрешается догнать и слить")
				imgui.Spacing()
				imgui.TextColoredRGB("{"..cmt.."}В жалобах чаще всего недостаточно доказательств, но иногда прям видно нарушение. По жалобам лучше советоваться в ВК")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}6) Байт на границе территории АВС: {"..cmt.."}(/т [id] 7200 Байт на АВС) (2ч)")
				imgui.TextColoredRGB("{"..cmt.."}-> Наказывать по данному нормативу, когда стоят/ходят у границы с целью байта")
				imgui.TextColoredRGB("{"..rmt.."}-> Игрокам, которые подвергаются байту запрещено сливать 'байтеров'. Как их наказывать, будет описано в следующем нормативе")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}7) Байт на границах зон обстрела/погони: {"..cmt.."}(/т [id] 7200 Байт на границах зон обстрела/погони) (2ч)")
				imgui.TextColoredRGB("{"..cmt.."}-> Наказывать по данному нормативу, когда стоят/ходят/ездят у границы с целью байта")
				imgui.TextColoredRGB("{"..cmt.."}-> Наказывать по данному нормативу, когда игрок выезжает из зоны погони и сразу же возвращается назад,")
				imgui.TextColoredRGB("{"..cmt.."}якобы 'обнуляя' своё присутствие в зоне")
				imgui.Spacing()
				imgui.TextColoredRGB("{"..cmt.."}Игрокам, которые подвергаются байту не запрещено сливать 'байтеров'")
				imgui.TextColoredRGB("{"..rmt.."}Для того, чтобы слить игрока за байт, необходимо иметь железные доказательства нарушения. Обращайте на это внимание в жалобах")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}8) Слив вне территории АВС после байта: {"..cmt.."}(/т [id] 7200 Слив вне территории АВС) (2ч)")
				imgui.TextColoredRGB("{"..cmt.."}-> Варнить за такое слишком жестко, поэтому выдается КПЗ")
				imgui.TextColoredRGB("{"..rmt.."}По понятным причинам это описано только в нормативах, игрокам этого не нужно знать, во избежания злоупотребления")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}9) Стрельба/Урон/Убийство вне зоны обстрела/погони:")
				imgui.TextColoredRGB("{"..cmt.."}/т [id] 1800 nonRP стрельба (30м)")
				imgui.TextColoredRGB("{"..cmt.."}/т [id] 3600 Нанесение урона (1ч)")
				imgui.TextColoredRGB("{"..cmt.."}/т [id] 18000 DM (5ч)")
				imgui.TextColoredRGB("{"..cmt.."}-> Помимо системной ЗЗ, сливать военных/бандитов можно также в зонах обстрела/погони")
				imgui.TextColoredRGB("{"..cmt.."}-> Военный может убить бандита в желтой зоне в случае, если: бандит в маске/проявляет агрессию/открыл огонь первым")
				imgui.TextColoredRGB("{"..cmt.."}-> На бандитов правило не распространяется, они могут убивать военных в желтой зоне даже без маски")
				imgui.TextColoredRGB("{"..cmt.."}-> Для того, чтобы вести огонь в фиолетовой зоне, оба игрока должны были быть изначально в желтой зоне")
				imgui.TextColoredRGB("{"..cmt.."}-> Если стреляет/наносит урон/убивает из вне территории, то наказывать за стрельбу/урон/убийство")
				imgui.TextColoredRGB("{"..cmt.."}-> Наказывать только если игрока вообще не было в желтой зоне")
				imgui.TextColoredRGB("{"..rmt.."}-> Если видите ситуацию в игре, либо в жалобе,")
				imgui.TextColoredRGB("{"..rmt.."}где ведется погоня и игрок успевает выехать из зоны погони и при этом его сливают в последний момент - наказывать не нужно")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}10) Слив склада: {"..cmt.."}(/т [id] 36000 Слив склада) (10ч)")
				imgui.TextColoredRGB("{"..cmt.."}-> Воровать патроны в количестве от 1.000 единиц с целью продать их")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}11) Ошибка в RP отыгровках: {"..cmt.."}(/т [id] 1800 Не полная/не верная отыгровка) (30м)")
				imgui.TextColoredRGB("{"..cmt.."}-> Пропуск действий в RP, которые сделаны в спец. темах и имеют конкретный шаблон обязательных действий")
				imgui.TextColoredRGB("{"..cmt.."}-> Неверный порядок действий в RP, которые сделаны в спец. темах и имеют конкретный шаблон обязательных действий")
				imgui.TextColoredRGB("{"..cmt.."}-> Отсутствие отсчёта")
				imgui.TextColoredRGB("{"..cmt.."}-> Присутствует прогон и RP отыгровка оружия, но убили игрока не дожидаясь его ухода с прогоняемой территории")
				imgui.TextColoredRGB("{"..cmt.."}-> Наличие отсчёта цифрами, а не словами")
				imgui.TextColoredRGB("{"..cmt.."}-> Пропущено название оружия, которое пишется в ковычках")
				imgui.TextColoredRGB("{"..cmt.."}-> Пропущен тип оружия, которое пишется перед названием, но при этом название в ковычках есть")
				imgui.TextColoredRGB("{"..cmt.."}-> Пропущено уточнение откуда достал и куда убрал оружие")
				imgui.TextColoredRGB("{"..cmt.."}-> Пропущена отыгровка как игрок убирает оружие")
				imgui.TextColoredRGB("{"..cmt.."}-> Гравировка на служебном оружии")
				imgui.TextColoredRGB("{"..cmt.."}-> На тренировке/пвп сделана RP отыгровка оружия огнестрельного, а не пейтбольного")
				imgui.TextColoredRGB("{"..cmt.."}-> Если не отыграли как достали оружие/кулаки и убили игрока, но при этом отыграно что убрали оружие/кулаки")
				imgui.TextColoredRGB("{"..cmt.."}-> Если отыграли что убрали оружие и убили игрока")
				imgui.TextColoredRGB("{"..cmt.."}-> Отыграно не то оружие с которого убили/стреляли")
				imgui.TextColoredRGB("{"..cmt.."}-> Отыграно что достали оружие уже после убийства")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..rmt.."}(!) Страйбольное оружие могут передать по RP игроку с заглушкой и оно действует на время кб/дуэли")
				imgui.PopFont()
			imgui.EndChild()
		end
		if active_window == 3 then
			imgui.BeginChild(u8"Общие нормативы", imgui.ImVec2(992, 550), true)
				imgui.PushFont(fontsize15)
				imgui.TextColoredRGB("{"..smt.."}1) Нанесение урона: {"..cmt.."}1-3LVL (/т [id] 1800 Нанесение урона) | 4+ LVL (/т [id] 3600 Нанесение урона) (30м/1ч)")
				imgui.TextColoredRGB("{"..cmt.."}-> За 1-2 удара можно посадить на 5 минут (Остынь)")
				imgui.TextColoredRGB("{"..cmt.."}-> Если применяют самооборону против ярого nonRP копа – не наказывать, как и против читера")
				imgui.TextColoredRGB("{"..cmt.."}-> Должно быть видно, что нет RP отыгровки/причины у игрока который наносит урон, если игрока положили на анимку от 4 хп, то это уже DM")
				imgui.TextColoredRGB("{"..cmt.."}-> Сюда входит и нанесение урона транспортом. Наказуемо любое нанесение урона с помощью ТС,")
				imgui.TextColoredRGB("{"..rmt.."}кроме случайного наезда или наезда копа на преступника")
				imgui.Spacing()
				imgui.TextColoredRGB("{"..cmt.."}-> Нанесение урона дубинкой (достаточно одного удара)")
				imgui.Spacing()
				imgui.TextColoredRGB("{"..cmt.."}-> Вертолёт/самолёт/квадрокоптер - не нужно отказывать всё подряд под предлогом мало док-в. - 'А что забыл этот вид транспорта в данном месте?'")
				imgui.TextColoredRGB("{"..cmt.."}-> Если игрок сбивает другого игрока специально чтоб получить преимущество пока тот в анимке и убить его,")
				imgui.TextColoredRGB("{"..cmt.."}то нужно садить не как за нанесение урона, а как за DM. Наказывать нужно только если убили во время анимки или спустя пару сек после неё")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}2) DM:")
				imgui.TextColoredRGB("{"..cmt.."}1-3LVL (/т [id] 1800 DM) (30м)")
				imgui.TextColoredRGB("{"..cmt.."}4+ LVL (/т [id] 7200 DM) (2ч)")
				imgui.TextColoredRGB("{"..cmt.."}Гос. фракции (кроме МО) (/пнр [id] DM/nonRP 'фракция')")
				imgui.TextColoredRGB("{"..cmt.."}Ghetto/Мафия/МО (/т [id] 18000 DM) (5ч)")
				imgui.TextColoredRGB("{"..cmt.."}-> Если применяют самооборону против ярого nonRP копа – не наказывать, как и против читера")
				imgui.TextColoredRGB("{"..cmt.."}-> Должно быть видно, что нет RP отыгровки/причины у игрока который убил. По килл-чату (логам) на свой страх и риск")
				imgui.TextColoredRGB("{"..rmt.."}-> По данному нормативу время не плюсуется")
				imgui.TextColoredRGB("{"..cmt.."}-> Сюда входит и убийство транспортом. Наказуемо любое убийство с помощью ТС, кроме случайного наезда")
				imgui.TextColoredRGB("{"..cmt.."}-> Вертолёт/самолёт/квадрокоптер - не нужно отказывать всё подряд под предлогом мало док-в. - 'А что забыл этот вид транспорта в данном месте?'")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}3) DM 2+ одновременно:")
				imgui.TextColoredRGB("{"..cmt.."}1-3LVL (/т [id] 1800 DM) (30м)")
				imgui.TextColoredRGB("{"..cmt.."}4+ LVL (/т [id] 18000 DM) (5ч)")
				imgui.TextColoredRGB("{"..cmt.."}Гос. фракции (кроме МО) (/пнр [id] nonRP 'фракция' + /т [id] 18000 DM) (5ч)")
				imgui.TextColoredRGB("{"..cmt.."}Ghetto/Мафия/МО (/т [id] 18000 DM) (5ч)")
				imgui.Spacing()
				imgui.TextColoredRGB("{"..cmt.."}-> По данному нормативу время кпз плюсуется за каждый килл")
				imgui.TextColoredRGB("{"..cmt.."}-> Остальные уточнения из пункта 2 относятся сюда тоже")
				imgui.TextColoredRGB("{"..cmt.."}-> Не вздумайте плюсовать варны, он даётся только за первый килл, а дальше КПЗ")
				imgui.TextColoredRGB("{"..cmt.."}-> Если вы проверяете жалобы на форуме и один человек DM'ит несколько раз (пусть даже и в разных жб), то наказывать по данному нормативу")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}4) Остынь:{"..cmt.."} (/т [id] 300 Остынь) (5м)")
				imgui.TextColoredRGB("{"..cmt.."}-> Попытка урона в GZ")
				imgui.TextColoredRGB("{"..cmt.."}-> Когда оба дерутся/стреляются и вы не знаете кто первый начал")
				imgui.TextColoredRGB("{"..cmt.."}-> Когда выкидывают много раз водителя не давая уехать и так же с вертолётом")
				imgui.TextColoredRGB("{"..cmt.."}-> Когда наносят 1-2 удара по игроку/машине с игром/машине без игрока")
				imgui.TextColoredRGB("{"..cmt.."}-> Убийство игрока в клетке (когда игрок через решетку убивает игрока, находящегося за решеткой КПЗ)")
				imgui.TextColoredRGB("{"..rmt.."}Если оба игрока в клетке и убивают друг друга - наказывать не нужно")
				imgui.Spacing()
				imgui.TextColoredRGB("{"..cmt.."}-> Можно применять в ситуациях когда игрок специально 'достаёт' других игроков разными методами. Например: ")
				imgui.TextColoredRGB("{"..cmt.."}анимкой пинает, сигналит долго в местах скопления людей и т.д. {FF0000}(только не надо наказывать прям за единичные случаи)")
				imgui.TextColoredRGB("{"..cmt.."}Если игрок не понял и продолжил наглым образом делать тоже самое - давать nonRP поведение")
				imgui.TextColoredRGB("{"..rmt.."}-> Ношение оружия в открытую. ВАЖНО! Наказывать только если игрок целится в кого-то, не стреляя при этом")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}5) nonRP стрельба:{"..cmt.."} (/т [id] 1800 nonRP стрельба) (30м)")
				imgui.TextColoredRGB("{"..cmt.."}-> Если применяют самооборону против ярого nonRP копа – не наказывать, как и против читера")
				imgui.TextColoredRGB("{"..cmt.."}-> Когда игрок просто так стреляет")
				imgui.TextColoredRGB("{"..cmt.."}-> Когда стреляет по игроку без RP отыгровки/RP причины и не попадает")
				imgui.TextColoredRGB("{"..cmt.."}-> Если игрок стреляет без причин не попадая в игрока/авто, наказывать не нужно (речь про безлюдные места и если это не кач скиллов)")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}6) nonRP поведение: {"..cmt.."}1-3LVL (/т [id] 1800 nonRP поведение) | 4+ LVL (/т [id] 3600 nonRP поведение) (30м/1ч)")
				imgui.TextColoredRGB("{"..cmt.."}-> NonRP респ машины (МО на базах могут взорвать т/с бандитов без RP и мафии на АВС)")
				imgui.TextColoredRGB("{"..cmt.."}-> Порча имущества")
				imgui.TextColoredRGB("{"..cmt.."}-> Выталкивать игрока из-за стола в казино")
				imgui.TextColoredRGB("{"..cmt.."}-> Сталкивать машины в воду")
				imgui.TextColoredRGB("{"..cmt.."}-> NonRP аптечка (юзать без помощи или без RP отыгровки, лёжа на анимке 4хп)")
				imgui.TextColoredRGB("{"..cmt.."}-> Стрельба по машинам")
				imgui.TextColoredRGB("{"..cmt.."}-> Нападение бандитов на замороженную банду")
				imgui.TextColoredRGB("{"..cmt.."}-> Обстрел других банд от замороженной банды")
				imgui.TextColoredRGB("{"..cmt.."}-> Дефф свободного бизнеса от замороженной мафии (Если мафия заморожена, ей запрещено ходить на дефф свободных бизнесов)")
				imgui.TextColoredRGB("{"..cmt.."}-> Таксист задним ходом везёт пассажира, тем самым не даёт выбраться из транспорта")
				imgui.TextColoredRGB("{"..cmt.."}-> Убивать игроков в больнице {"..rmt.."}(относится к тем игрокам, что находятся там после смерти с ~10 хп)")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}7) TK:{"..cmt.."} (/т [id] 7200/18000 ТК) (2ч/5ч)")
				imgui.TextColoredRGB("{"..cmt.."}-> Наказывать по такому же принципу как и DM (пункт 2/3)")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}8) FF:{"..cmt.."} (/т [id] 3600 FF) (1ч)")
				imgui.TextColoredRGB("{"..cmt.."}-> Наказывать по такому же принципу как и Нанесение урона (пункт 1)")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}9) PG: {"..cmt.."}1-3LVL (/т [id] 1800 PG) | 4+ LVL (/т [id] 7200 PG) (30м/2ч)")
				imgui.TextColoredRGB("{"..cmt.."}-> С кулаками на вооруженного - искл военный на своей базе (когда пытаются ударить, но не ударяют - не садить)")
				imgui.TextColoredRGB("{"..cmt.."}-> Нахождение игрока в военном складе (исключение: военные, полицейские, бандиты)")
				imgui.TextColoredRGB("{"..cmt.."}-> Похищение человека мафией в людном месте (именно когда много людей рядом)")
				imgui.TextColoredRGB("{"..cmt.."}-> Самоубийство с целью получения выгоды для себя (уход от погони и т.д)")
				imgui.TextColoredRGB("{"..cmt.."}-> Пассажиров за PG нужно наказывать только в ситуации где однозначно видно что он умер специально")
				imgui.TextColoredRGB("{"..rmt.."}Не забывайте что пассажир не управляет авто и он может отвлечься от пк на пару секунд")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}10) Интерьер в бою/при аресте/инта на бизваре:")
				imgui.TextColoredRGB("{"..cmt.."}1-3LVL (/т [id] 1800 Инта в бою/при аресте) (30м)")
				imgui.TextColoredRGB("{"..cmt.."}4+ LVL (/т [id] 7200 Инта в бою/при аресте/инта на бизваре) (2ч)")
				imgui.TextColoredRGB("{"..cmt.."}-> Прятаться в интерьере во время боя (в случае если игрок стрелял и убежал в инту)")
				imgui.TextColoredRGB("{"..cmt.."}-> Заходить в инту и выходить из неё туда сюда очень много раз")
				imgui.TextColoredRGB("{"..cmt.."}-> При аресте (склад МО сюда не относится)")
				imgui.TextColoredRGB("{"..cmt.."}-> Наказывать только когда забегают в закрытую инту (казармы, дома в аренде закрытые, личные дома закрытые, респа банды и т.д)")
				imgui.TextColoredRGB("{"..cmt.."}-> Если игрок заходит/выходит из инты много раз в бою и инта является открытой, то нужно наказывать")
				imgui.TextColoredRGB("{"..cmt.."}-> Если военный едет с больки и по нему стреляют, а он забегает в казарму - такое не наказуемо, потому что у них оружие в казарме")
				imgui.TextColoredRGB("{"..cmt.."}-> Тоже самое касается бандитов на капте")
				imgui.TextColoredRGB("{"..rmt.."}Искл. бандит на капте обязательно должен после этого выйти из инты почти сразу иначе это будет как инта на капте и нужно садить")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}11) Помеха сдающим на права | Помеха при работе: водитель поезда и трамвая/дальнобой:{"..cmt.."} (/т [id] 7200 Помеха работе) (2ч)")
				imgui.TextColoredRGB("{"..rmt.."}-> Если стреляют по тс/взорвали тс - наказывать по этому нормативу")
				imgui.TextColoredRGB("{"..rmt.."}-> Всё остальное наказывается по стандартным нормативам DM и т.д")
				imgui.TextColoredRGB("{"..rmt.."}-> Помеха в работе наказуема только водитель поезда и трамвая/дальнобойщик!")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}12) Помеха:{"..cmt.."} (/т [id] 1 Помеха)")
				imgui.TextColoredRGB("{"..cmt.."}-> Примеры: AFK на дороге, стоять в проходе и т.д")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}13) Продажа/покупка оружия/патронов в открытую:{"..cmt.."} (/з [id] 3600 Продажа/покупка оружия/патронов в открытую) (1ч)")
				imgui.TextColoredRGB("{"..cmt.."}-> Разрешено продавать/покупать дома, в гетто, в глуши. Если кричат 'продам/куплю ган/патроны' в людных местах - это так же наказуемо")
				imgui.TextColoredRGB("{"..cmt.."}-> Продажу/покупку патронов разрешено маскировать по типу 'продам шарики с краской для пейнтбола', 'куплю макет оружия' и т.д")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}14) nonRP кач скиллов:{"..cmt.."} (/т [id] 18000 nonRP кач скиллов) (5ч)")
				imgui.TextColoredRGB("{"..cmt.."}-> Прокачка навыков оружия вне полигона")
				imgui.TextColoredRGB("{"..cmt.."}-> Бандиты могут качать скилы в гетто на своих отведенных под это местах")
				imgui.TextColoredRGB("{"..rmt.."}PD: Если отыгровка перезарядки присутствует - сажать такого игрока ЗАПРЕЩЕНО. Делать подобное разрешено только в гараже департамента")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}15) Продажа/покупка аккаунта:{"..cmt.."} (/блок [id] -1 Продажа аккаунта)")
				imgui.TextColoredRGB("{"..cmt.."}-> Покупка аккаунта наказуема в ситуации когда массово пишут что купят аккаунт (так делают разводилы часто)")
				imgui.TextColoredRGB("{"..rmt.."}Если просто кто-то пытается купить акк, то максимум можно выдать за MG, если это в IC чате")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}16) nonRP развод:{"..cmt.."} (/блок [id] -1 nonRP развод)")
				imgui.TextColoredRGB("{"..cmt.."}Если не более 10K (/блок [id] 36000 nonRP развод) (10ч)")
				imgui.TextColoredRGB("{"..cmt.."}Если не более 100K (/блок [id] 86400 nonRP развод) (1д)")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}17) Передача аккаунта:{"..cmt.."} (/блок [id] -1 Передача аккаунта)")
				imgui.TextColoredRGB("{"..cmt.."}-> Банить по логам IP разрешено только если видна явная передача (регистрация в одной стране, а на момент проверки играет с другой страны)")
				imgui.TextColoredRGB("{"..cmt.."}Так же нельзя банить если на короткое время менялись города/страна,")
				imgui.TextColoredRGB("{"..cmt.."}потому что много случаев взлома и случаев когда провайдер пишет разные города сам по себе")
				imgui.Spacing()
				imgui.TextColoredRGB("{"..rmt.."}Для бана за передачу у вас должны быть док-ва еще кроме логов")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}18) Обход наказания:{"..cmt.."} (/т [id] 'срок наказания' Обход наказания)")
				imgui.TextColoredRGB("{"..cmt.."}-> Играть (именно играть, а не когда два аккаунта AFK стоят) с твинка, пока другой аккаунт отбывает КПЗ")
				imgui.TextColoredRGB("{"..cmt.."}-> Срок наказания - на столько, на сколько закрыт второй аккаунт. {FF0000}Из наказаний только КПЗ наказуемо обходом")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}19) Выход из игры в бою/при аресте:")
				imgui.TextColoredRGB("{"..cmt.."}1-3LVL (/т [id] 7200 Выход в бою/при аресте) (2ч)")
				imgui.TextColoredRGB("{"..cmt.."}Не по фракции (/т [id] 18000 Выход в бою/при аресте) (5ч)")
				imgui.TextColoredRGB("{"..cmt.."}Во фракции (/пнр [id] Выход в бою/при аресте)")
				imgui.Spacing()
				imgui.TextColoredRGB("{"..cmt.."}-> Игрок обошел систему каким-либо способом - наказывать по этому нормативу")
				imgui.TextColoredRGB("{"..cmt.."}-> Если игрок в погоне от копов уплыл/улетел за пределы карты, наказывать по данному нормативу")
				imgui.TextColoredRGB("{"..cmt.."}-> Если игрок умер в погоне от копов и попал в больницу, то примерно 5м ему нельзя офаться с игры")
				imgui.TextColoredRGB("{"..cmt.."}Не надо высчитывать прям точное время, а примерное")
				imgui.Spacing()
				imgui.TextColoredRGB("{"..cmt.."}Оффнется = выход из игры при аресте")
				imgui.Spacing()
				imgui.TextColoredRGB("{"..rmt.."}-> Если игрока наказала система и посадила в кпз, НАКАЗЫВАТЬ НЕ НАДО САМИМ")
				imgui.TextColoredRGB("{"..rmt.."}-> Выйти мгновенно из игры при краше/закрытии игры за читы/офф инета - невозможно!")
				imgui.TextColoredRGB("{"..rmt.."}15с будет лаг над головой, а при краше 15сек. с момента закрытия окна с крашем")
				imgui.Spacing()
				imgui.TextColoredRGB("{"..cmt.."}-> Запрещено наказывать игрока за офф, в ситуации когда он выходит из игры со значком лага/паузы")
				imgui.TextColoredRGB("{"..cmt.."}Если такое повторяется периодически от одного игрока, то есть вероятно что просто офает инет и тогда уже можно наказать")
				imgui.TextColoredRGB("{"..rmt.."}-> Если игрок в погоне вышел и зашел в игру в течение ~5м и был практически сразу ликвидирован тем же полицейским - не нужно наказывать,")
				imgui.TextColoredRGB("{"..rmt.."}потому что по итогу ситуация была закончена и игрок не смог избежать наказания nonRP путем (при проверке жалобы обращайте на это внимание)")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}20) Мультиаккаунт:{"..cmt.."} (/пнр [id] Аккаунты в 'фракция')")
				imgui.TextColoredRGB("{"..cmt.."}-> В бандах и армии")
				imgui.TextColoredRGB("{"..cmt.."}-> В бандах и полиции")
				imgui.TextColoredRGB("{"..cmt.."}-> В разных бандах")
				imgui.TextColoredRGB("{"..cmt.."}-> В одной фракции или одном министерстве")
				imgui.TextColoredRGB("{"..cmt.."}-> В мафии и твин в другой фракции {FF0000}(исключение ниже)")
				imgui.TextColoredRGB("{"..cmt.."}-> Более двух аккаунтов в разных фракциях")
				imgui.Spacing()
				imgui.TextColoredRGB("{"..cmt.."}-> Перед тем, как наказать убедитесь в том, что второй аккаунт это действительно твинк, а не брат/друг")
				imgui.TextColoredRGB("{"..rmt.."}Наказание даётся  варн твинку и увольнение основного аккаунта")
				imgui.Spacing()
				imgui.TextColoredRGB("{"..rmt.."}-> Если бандиты злоупотребляют этим делом, не боясь за увольнение основы - можно и на основу варн выдать")
				imgui.TextColoredRGB("{"..cmt.."}-> Разрешается иметь аккаунты в банде и мафии")
				imgui.TextColoredRGB("{F0000}-> Yakuza имеют право кидать твины в любые другие фракции, кроме других мафий и МО, не нарушая кол-во твинов во фраках")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}21) Продажа гос. имущества: {"..cmt.."}1-3LVL (/т [id] 1800 Продажа гос. имущества) (30м) | 4+ LVL (/т [id] 3600 Продажа гос. имущества) (1ч)")
				imgui.TextColoredRGB("{"..cmt.."}-> Примеры: 'Продам стол в казино 5к'; 'Уступлю трамвай, плати 10к'")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}22) Игнорирование RP отыгровок: {"..cmt.."}1-3LVL (/т [id] 1800 Отказ от RP) (30м) | 4+ LVL (/т [id] 3600 Отказ от RP) (1ч)")
				imgui.TextColoredRGB("{"..cmt.."}-> Охранник мэрии отыграл RP, что скрутил нарушителя, а игрок никак не реагирует на это и дальше бегает нарушает")
				imgui.TextColoredRGB("{"..cmt.."}-> Ставит объекты в проходах чтобы полицейские не посадили")
				imgui.TextColoredRGB("{"..cmt.."}-> Полицейский отыграл захват игрока, а игрок игнорирует это")
				imgui.TextColoredRGB("{"..cmt.."}-> Полицейский отыграл задержание игрока в воде, на адекватном расстоянии от преступника, а игрок игнорирует задержание")
				imgui.TextColoredRGB("{"..cmt.."}-> Помните что игрок не обязан реагировать мгновенно")
				imgui.TextColoredRGB("{"..rmt.."}-> В случае, если полицейский требует снять маску, то игрок имеет полное право НЕ снимать ее системно, а сделать это с помощью RP отыгровок")
				imgui.TextColoredRGB("{"..rmt.."}Если сотрудник МВД не обратит внимание на отыгровку, а будет дальше требовать снять маску - наказывать полицейского за отказ от RP")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}23) SK:{"..cmt.."} (сроки наказаний как за DM, только без варнов)")
				imgui.TextColoredRGB("{"..cmt.."}-> Урон, стрельба в сторону игрока - это наказывается по одному принципу")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}24) Анимации в складе:{"..cmt.."} (/т [id] 36000 Анимации в складе) (10ч)")
				imgui.TextColoredRGB("{"..rmt.."}Если там нет никаких перестрелок, то не надо наказывать сразу, а предупредите игрока через репорт. Потому что это не очевидная вещь для игроков")
				imgui.TextColoredRGB("{"..rmt.."}-> Приветствие и 'ку' не наказуемы")
				imgui.TextColoredRGB("{"..rmt.."}-> Не нужно наказывать, если анимацию заюзали всего на несколько секунд")
				imgui.TextColoredRGB("{"..rmt.."}-> Не нужно наказывать, если анимацию заюзали для того, чтобы встать на пикап при масс-коде")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}25) Прием во фракцию за деньги/продажа ранга:{"..cmt.."} (/пнр [id] Прием во фракцию за деньги/продажа ранга)")
				imgui.TextColoredRGB("{"..cmt.."}-> Относится ко всем фракциям. Имеются в виду не только деньги, но и любое вознаграждение - дом/машина/бизнес и т.д")
				imgui.TextColoredRGB("{"..rmt.."}Принимать в банду за мт/пт можно")
				imgui.TextColoredRGB("{"..rmt.."}Если это предлагает игрок без фракции или ниже 8-го ранга - то наказывать как за развод")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}26) Слив лидера:{"..cmt.."} (/блок [id] 86400 Слив лидера) (1д)")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}27) Автокликер в казино/Авторыбалка:{"..cmt.."} (/т [id] 3600 Автокликеh/Авторыбалка) (1ч)")
				imgui.TextColoredRGB("{"..cmt.."}-> Спрашиваете через репорт 'Вы тут? Напишите что-нибудь в чат', если игрок без заглушки и стоит молча секунд 30, то сажать его")
				imgui.TextColoredRGB("{"..cmt.."}Если игрок с заглушкой, то просите его заюзать анимацию любую")
				imgui.TextColoredRGB("{"..cmt.."}-> При проверке игрока на использование авторыбалки обязательно фиксируйте,")
				imgui.TextColoredRGB("{"..cmt.."}что игрок проигнорировал ваши ответы с вопросами через репорт и забросил удочку")
				imgui.Spacing()
				imgui.TextColoredRGB("{"..cmt.."}-> Проверить можно без вопросов игроку, а просто последить за ним")
				imgui.TextColoredRGB("{"..cmt.."}Автокликер обычно срабатывает каждые 25сек и если вы видите что каждые 25с крупье крутит допустим, то можно смело садить")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}28) Работа крупье с нескольких аккаунтов:{"..cmt.."} (/т [id] 3600 Крупье с твинов) (1ч)")
				imgui.TextColoredRGB("{"..cmt.."}-> 1 аккаунт оставляете, все остальные в КПЗ")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}29) Нападение в скинах начальных работ:{"..cmt.."} (/пнр [id] Нападение в скине начальных работ)")
				imgui.TextColoredRGB("{"..cmt.."}-> Если игрок во фракции нападёт на военку в скине шахтера например или на капт/бизвар пойдет")
				imgui.TextColoredRGB("{"..cmt.."}-> Наказываем когда игрок целится/стреляет/убивает на бизваре/капте")
				imgui.TextColoredRGB("{"..rmt.."}Если просто стоит на территории капта или же бизвара, то просто через /от говорим ему чтобы ушел с территории")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}30) Игрок лагает в бою:{"..cmt.."} (/т 300 Лаги/Потери в бою) (5м)")
				imgui.TextColoredRGB("{"..cmt.."}-> В бою, на бизваре, на капте, на захвате военки - запрещено быть с лагами")
				imgui.TextColoredRGB("{"..rmt.."}Перед тем, как сажать игрока за лаги, зафиксируйте его потерю, пинг и то, как он лагает")
				imgui.TextColoredRGB("{"..cmt.."}Пример лагов: 'Игрок перемещается с задержкой', 'Игроку не проходит урон' и т.д")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}31) Покупка или продажа игрового имущества за реальные деньги:{"..cmt.."} (/блок [id] -1 Покупка/Продажа ...) (вечность)")
				imgui.TextColoredRGB("{"..cmt.."}-> Если покупают вирты или продают - бан. Попытка продать или купить - бан")
				imgui.TextColoredRGB("{"..cmt.."}Естественно что речь про игрок - игроку")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}32) Ввод в заблуждение в жалобах на игроков:{"..cmt.."} (Выдавать наказание автору, которое должно было быть игроку на которого написали жб)")
				imgui.TextColoredRGB("{"..cmt.."}-> Если автор жалобы предоставил специально док-ва которые показывают не полную ситуацию,")
				imgui.TextColoredRGB("{"..cmt.."}из-за чего администратор может выдать неверное наказание")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}33) Злоупотребление любыми наказаниями:{"..cmt.."} (/т [id] 86400/-1 Неоднократные нарушения) (От 1д до вечности)")
				imgui.TextColoredRGB("{"..cmt.."}-> Наказывать игроков которым срать на стандартные наказания, но сразу прям выдавать бан нельзя")
				imgui.TextColoredRGB("{"..cmt.."}По нарастающей сроки выдавайте и уже тем кому и такое не ставит мозги на место бан давать")
				imgui.TextColoredRGB("{"..cmt.."}-> Нарушения от таких игроков должны быть серьёзными, а не по мелочи что-то")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}34) Блок по собственному желанию:{"..cmt.."} (/блок [id] 864000 По с/ж) (10д)")
				imgui.TextColoredRGB("{"..rmt.."}-> ОБЯЗАТЕЛЬНО сообщите игроку перед блоком, что замены наказания потом не будет. Если согласится на это, блочьте")
				imgui.TextColoredRGB("{"..rmt.."}-> Исключение: игрокам 1-го уровня блок не выдается")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}35) Ник с оскорблением игрока/админа/сервера/реклама в нике:{"..cmt.."} (/сблок [id] ...) (вечность)")
				imgui.TextColoredRGB("{"..rmt.."}-> В ЧМ кидать больше не нужно! Только если по кд создают много акков таких.")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}36) Ник, не соответствующий RP сервера:{"..cmt.."} (попросить, чтобы сменил или сменить его самостоятельно, предварительно предупредив об этом игрока)")
				imgui.TextColoredRGB("{"..rmt.."}-> Примеры: Морковка_Овощ; Зеленый_Попугай; Вкусный_Чай. nonRP ник можно сменить игроку бесплатно один раз на RP ник и только до 5 уровня")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}37) Ник как у администратора:{"..cmt.."} (/сблок [id] -1 Фейк админа) (вечность)")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}38) nonRP крыша:{"..cmt.."} (/т [id] 7200 nonRP крыша) (2ч)")
				imgui.TextColoredRGB("{"..cmt.."}-> Запрет распространяется на мафиози")
				imgui.TextColoredRGB("{008000}-> Разрешено {FFFFFF}залезть на крышу и слить военного, после чего спуститься вниз")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}39) Ошибка в RP отыгровках:{"..cmt.."} (/т [id] 1800 Не полная/не верная отыгровка) (30м)")
				imgui.TextColoredRGB("{"..cmt.."}-> Пропуск действий в RP, которые сделаны в спец. темах и имеют конкретный шаблон обязательных действий")
				imgui.TextColoredRGB("{"..cmt.."}-> Неверный порядок действий в RP, которые сделаны в спец. темах и имеют конкретный шаблон обязательных действий")
				imgui.TextColoredRGB("{"..cmt.."}-> Пропущено название оружия, которое пишется в ковычках")
				imgui.TextColoredRGB("{"..cmt.."}-> Пропущен тип оружия, которое пишется перед названием, но при этом название в ковычках есть")
				imgui.TextColoredRGB("{"..cmt.."}-> Пропущено уточнение откуда достал и куда убрал оружие")
				imgui.TextColoredRGB("{"..cmt.."}-> Пропущена отыгровка как игрок убирает оружие")
				imgui.TextColoredRGB("{"..cmt.."}-> Присутствует прогон и RP отыгровка оружия, но убили игрока не дожидаясь его ухода с прогоняемой территории")
				imgui.TextColoredRGB("{"..cmt.."}-> Если не отыграли как достали оружие/кулаки и убили игрока, но при этом отыграно что убрали оружие/кулаки")
				imgui.TextColoredRGB("{"..cmt.."}-> Если отыграли что убрали оружие и убили игрока")
				imgui.TextColoredRGB("{"..cmt.."}-> Отыграно не то оружие с которого убили/стреляли")
				imgui.TextColoredRGB("{"..cmt.."}-> Отыграно что достали оружие уже после убийства")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}40) Если убивают лежащего на анимке от 4хп: (нанесение урона)")
				imgui.TextColoredRGB("{"..cmt.."}-> Думаю понятно, что речь о том что вообще другой игрок это делает и делает там, где запрещено это")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}41) Нападение на МО:{"..cmt.."} Наказывать по принципу норматива DM/Нанесение урона")
				imgui.TextColoredRGB("{"..cmt.."}-> Могут быть ситуации, где игрок не стреляет, а просто бегает рядом с бандитами/сливает инфу и так далее")
				imgui.TextColoredRGB("{"..rmt.."}Это тоже можно посчитать нападением и наказать по данному нормативу на 1 час КПЗ. В таких ситуациях лучше всегда советуйтесь")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}42) Похищение военных/других мафиози на АВС:{"..cmt.."} (/пнр [id] Похищение военных/других мафиози на АВС)")
				imgui.TextColoredRGB("{"..cmt.."}-> Наказуемо даже если один раз используют")
				imgui.PopFont()
			imgui.EndChild()
		end
		if active_window == 4 then
			imgui.BeginChild(u8"Настройки", imgui.ImVec2(992, 550), true)
				imgui.PushFont(iconfont)
				if imgui.Checkbox(fa.ICON_FA_DIZZY..u8" Разрешенные оск. ", checkbox_osk) then
					osk_window_state.v = checkbox_osk.v
					HLcfg.config.checkbox1 = checkbox_osk.v
					save()
				end
				if imgui.Checkbox(fa.ICON_FA_HANDSHAKE..u8" Нормативы чата ", checkbox_sec) then
					sec_window_state.v = checkbox_sec.v
					HLcfg.config.checkbox2 = checkbox_sec.v
					save()
				end
				if imgui.Checkbox(fa.ICON_FA_RULER_COMBINED..u8" Конвертер минут ", checkbox_time) then
					time_window_state.v = checkbox_time.v
					HLcfg.config.checkbox3 = checkbox_time.v
					save()
				end
				imgui.SameLine()
				imgui.TextQuestion(u8"(?)", "Перевод введенного кол-ва минут в секунды")
				if imgui.Checkbox(fa.ICON_FA_STOPWATCH..u8" Секундомер ", checkbox_swatch) then
					swatch_window_state.v = checkbox_swatch.v
					HLcfg.config.checkbox4 = checkbox_swatch.v
					save()
				end
				imgui.Separator()
				
				imgui.Text(u8"Никнейм")
				imgui.SameLine()
				imgui.PushItemWidth(200)
				imgui.InputText("##l", login_buffer)
				imgui.PopItemWidth()
				
				imgui.Text(u8"Пароль   ")
				imgui.SameLine()
				imgui.PushItemWidth(200)
				imgui.InputText("##p", pass_buffer, imgui.InputTextFlags.Password)
				imgui.PopItemWidth()
				
				if imgui.Button(u8 "Сохранить") then
					if login_buffer.v and pass_buffer.v then
						if bNotf then
							notf.addNotification("Cохранено!", 4, HLcfg.config.theme)
						end
						printlog("Настройки сохранены")
						HLcfg.config.login = login_buffer.v
						HLcfg.config.pass = pass_buffer.v
						save()
					else
						if bNotf then
							notf.addNotification("Проверьте данные!", 4, HLcfg.config.theme)
						end
					end
				end
				imgui.Separator()
				imgui.Text(u8"Выберите тему:")
				imgui.BeginChild("ChildWindow2", imgui.ImVec2(200, 205), true)
					for i, value in ipairs(themes.colorThemes) do
						if imgui.RadioButton(value, checked_radio, i) then
							themes.SwitchColorTheme(i)
							HLcfg.config.theme = i
							save()
						end
					end
				imgui.EndChild()
				imgui.Separator()
				if imgui.Button(u8 "Удалить логи скрипта") then
					if bNotf then
						notf.addNotification("Удалено!", 4, HLcfg.config.theme)
					end
					if doesDirectoryExist(getWorkingDirectory().."\\logs\\script") then
						deletedir(getWorkingDirectory().."\\logs\\script")
						printlog("Логи скрипта удалены")
					end
				end
				
				imgui.Text('')
				imgui.Text(u8"Сообщить о проблеме")
				imgui.SameLine()
				imgui.InputText("", vk_buffer)
				imgui.SameLine()
				if imgui.Button(u8 "Отправить") then
					if tostring(vk_buffer.v) then
						vkreq(tostring(vk_buffer.v))
						if bNotf then
							notf.addNotification("Отправлено!", 4, HLcfg.config.theme)
						end
					else
						if bNotf then
							notf.addNotification("Введите текст!", 4, HLcfg.config.theme)
						end
					end
				end
				
				imgui.PopFont()
			imgui.EndChild()
		end
		if active_window == 5 then
			imgui.BeginChild(u8"Ghetto", imgui.ImVec2(992, 550), true)
				imgui.PushFont(fontsize15)
				imgui.TextColoredRGB("{"..smt.."}1) Снайперка за пределами GZ:{"..cmt.."} (/т [id] 3600 Снайперка за пределами GZ) (1ч)")
				imgui.TextColoredRGB("{"..rmt.."}-> Норматив применяется только к бандитам")
				imgui.TextColoredRGB("{"..cmt.."}-> Запрещены любые перестрелки за пределами системной GZ")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}2) Снайперка в складе:{"..cmt.."} (/т [id] 7200 Снайперка в складе) (2ч)")
				imgui.TextColoredRGB("{"..rmt.."}Если там нет никаких перестрелок, то не надо наказывать сразу, а предупредите игрока через репорт. Потому что это не очевидная вещь для игроков")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}3) Нападение на мороз МО:{"..cmt.."} (/т [id] 3600 Нападение на мороз МО) (1ч)")
				imgui.TextColoredRGB("{"..rmt.."}-> Если игрок просто заехал на военную базу/авианосец, сразу наказывать не нужно. Предупредите через репорт")
				imgui.TextColoredRGB("{"..cmt.."}-> Если игрок стреляет/наносит урон, наказывать по данному нормативу")
				imgui.TextColoredRGB("{"..rmt.."}-> Если игрок убивает, наказывать по нормативу как за DM (Если 2+ килла, садить на 10ч. 3 - 15ч и так далее)")
				imgui.TextColoredRGB("{"..rmt.."}-> Варны по данному нормативу не выдаются")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}4) Слив склада:{"..cmt.."} (/т [id] 36000 Слив склада) (10ч) | (/блок [id] 172800) (2д)")
				imgui.TextColoredRGB("{"..cmt.."}-> Умышлено брать патроны, препараты, материалы в количестве от 1.000 единиц")
				imgui.TextColoredRGB("{"..rmt.."}-> Требовать от игрока вернуть обратно украденное")
				imgui.TextColoredRGB("{"..rmt.."}В случае, если игрок возвращает - КПЗ 10 часов, но если игрок продал/отказывается, то наказывать блокировкой на пару дней")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}5) Прием в банду в людном месте/игрока ниже 7-го уровня:{"..cmt.."} (/т [id] 7200 Прием в банду в людном месте/игрока ниже 7 уровня) (2ч)")
				imgui.TextColoredRGB("{"..rmt.."} -> Игрока которого приняли нужно уволить")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}6) PG:{"..cmt.."} (/т [id] 7200 PG) (2ч)")
				imgui.TextColoredRGB("{"..cmt.."}-> Наказывается по тому же принципу, что и обычно. Так же если игрок 'станит' кулаком соперника, то такие ситуации наказуемы")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}7) TK:{"..cmt.."} (/т [id] 18000 TK) (5ч)")
				imgui.TextColoredRGB("{"..cmt.."}-> Наказывается по тому же принципу, что и обычно")
				imgui.TextColoredRGB("{"..rmt.."}-> На капте, если по игроку начал специально стрелять союзник, то разрешается убить этого союзника без отыгровок")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}8) Обстрел в запрещенное время:{"..cmt.."} (/т [id] 3600 Обстрел в запрещенное время) (1ч)")
				imgui.TextColoredRGB("{"..cmt.."}-> С 23:00 до 10:00 обстрел запрещен")
				imgui.PopFont()
				imgui.PushFont(fontsize20)
				imgui.TextColoredRGB("{"..cmt.."}Капты: {FF0000}(указывать в скобках банду)")
				imgui.PopFont()
				imgui.PushFont(fontsize15)
				imgui.TextColoredRGB("{"..smt.."}4) Стрельба с водительского/пассажирских мест на капте:{"..cmt.."} (/т [id] 3600/7200 Запрещенный способ стрельбы) (1ч/2ч)")
				imgui.TextColoredRGB("{"..rmt.."}-> В исключения к этому входит мотоцикл")
				imgui.TextColoredRGB("{"..cmt.."}-> В случае нанесения урона наказывать на 1 час, в случае убийства на 2 часа, в случае обычной стрельбы в соперника тоже на 1 час")
				imgui.TextColoredRGB("{"..cmt.."}-> Стрельба по игроку и/или убийство игрока из автомобиля на капте. Наказывать только в тех случаях, когда стрельба ведется с противником!")
				imgui.TextColoredRGB("{"..cmt.."}Например: идет капт между Vagos и Ballas, приезжает Rifa и открывает огонь по Ballas,")
				imgui.TextColoredRGB("{"..cmt.."}Ballas на капте убивает Rifa с транспорта. {FF0000}За это наказывать НЕ нужно")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}5) Помеха на капте:{"..cmt.."} (/т [id] 300 Помеха капту) (5м)")
				imgui.TextColoredRGB("{"..rmt.."}-> Когда на капте находятся любой другой игрок, можно только тем у кого идет капт")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}6) nonRP крыша:{"..cmt.."} (/т [id] 7200 nonRP крыша) (2ч)")
				imgui.TextColoredRGB("{"..cmt.."}-> Находиться во время капта на крыше, на которую нельзя забраться самому или с помощью подсадки через т/с")
				imgui.TextColoredRGB("{"..cmt.."}Любые другие способы запрещены. Так же наказуем {FF0000}обстрел {FFFFFF}с nonRP крыш")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}7) Антикилл/Антифраг:{"..cmt.."} (/т [id] 10800 Антифраг) (3ч)")
				imgui.TextColoredRGB("{"..cmt.."}-> Убить своего персонажа, например, спрыгнув с крыши или убить игрока своей фракции с целью чтобы сопернику не засчитали убийство")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}8) Запрещенное оружие на капте:{"..cmt.."} (/т [id] 7200 Запрещенное оружие на капте) (2ч)")
				imgui.TextColoredRGB("{"..cmt.."}-> Наказывать в том случае, если идет стрельба с запрещенного оружия по противнику на капте")
				imgui.TextColoredRGB("{"..cmt.."}-> Бандитам на капте разрешается использовать оружие только то, что они могут сделать самостоятельно")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}9) Трансфер состава:{"..cmt.."} (/т [id] 36000 Трансфер) (10ч)")
				imgui.TextColoredRGB("{"..cmt.."}-> Трансфер состава - идти на захват территорий минимум с двух банд в один день")
				imgui.TextColoredRGB("{"..cmt.."}-> Если вы были сегодня в Grove на капте, затем перешли в Ballas и пошли на капт - накажут за трансфер")
				imgui.TextColoredRGB("{"..cmt.."}-> Если вы были в Grove и не ходили сегодня на капты, потом перешли в Ballas и пошли на капт - это не трансфер")
				imgui.TextColoredRGB("{"..cmt.."}-> Если вы были в Grove на каптах, затем перешли в Ballas и не пошли на капты - это не трансфер")
				imgui.TextColoredRGB("{"..cmt.."}-> Трансфер разрешен при Gold союзе и если банда заморожена")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}10) Интерьер в бою/на капте:{"..cmt.."} (/т [id] 7200 Инта в бою/на капте) (2ч)")
				imgui.TextColoredRGB("{"..cmt.."}-> За интерьер в бою наказывать в том случае, если оба игрока стреляются и один из них забегают в интерьер, дабы спрятаться от соперника")
				imgui.TextColoredRGB("{"..cmt.."}-> Интерьер на капте считается, когда игрок заходит в интерьер с целью использовать аптечку/спрятаться там от соперников,")
				imgui.TextColoredRGB("{"..cmt.."}при этом бой не обязателен")
				imgui.TextColoredRGB("{"..cmt.."}-> Разрешается заходить в респу, либо 24/7, если рядом с игроком нет соперников, которые бы по нему стреляли")
				imgui.TextColoredRGB("{"..cmt.."}В случае, если по игроку ведется стрельба, то заходить в интерьеры запрещено, даже 24/7")
				imgui.TextColoredRGB("{"..rmt.."}Не стоит наказывать, если по игроку начали стрелять вне территории до 3й минуты и он после этого зашел в инту,")
				imgui.TextColoredRGB("{"..cmt.."}так как тут нарушение со стороны соперника")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}11) Любой DB:{"..cmt.."} (/т [id] 3600/18000 DB) (1ч/5ч)")
				imgui.TextColoredRGB("{"..rmt.."}-> Наказуемо только на капте, в исключения к этому входит мотоцикл, с мотоцикла можно стрелять пассажиру после 3й минуты капта")
				imgui.TextColoredRGB("{"..cmt.."}-> В случае нанесения урона наказывать на 1 час, в случае убийства на 2 часа, в случае обычной стрельбы в соперника тоже на 1 час")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}12) Прием в банду/увольнение из банды игрока после 7ой минуты капта:{"..cmt.."} (/т [id] 7200 Прием/увольнение после 7й минуты капта) (2ч)")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}13) Обстрел респы до 3 минуты капта:{"..cmt.."} (/т [id] 10800 Обстрел респы до 3 минуты) (3ч)")
				imgui.TextColoredRGB("{"..rmt.."}-> В случае, если соперник первый начал стрельбу с респы, то игроку, по которому велась стрельба разрешается в него стрелять")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}14) Слив на подготовительной минуте капта:{"..cmt.."} (/т [id] 18000 Слив на подготовительной минуте капта) (3ч)")
				imgui.TextColoredRGB("{"..rmt.."}->  Попытку слива наказывать одним часом КПЗ")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}15) Слив вне территории капта (до 3-х минут):{"..cmt.."} (/т [id] 10800 Слив вне терры капта) (3ч)")
				imgui.TextColoredRGB("{"..rmt.."}-> Попытка слива также наказуема (3 часа кпз)")
				imgui.TextColoredRGB("{"..cmt.."}-> Игроку разрешается самообороняться, если по нему вне территории начали стрелять, так же если в игрока целились,")
				imgui.TextColoredRGB("{"..cmt.."}то разрешается стрелять по тому, кто целился, это будет являться провокацией (мониторинг п.21)")
				imgui.Spacing()
				imgui.TextColoredRGB("{"..cmt.."}-> Слив в любом интерьере. {FF0000}Исключение: если за игроком изначально была погоня, то разрешается убить его в интерьере")
				imgui.TextColoredRGB("{"..cmt.."}-> Слив вне территории капта и попытки суммируются, то есть если игрок убил двоих,")
				imgui.TextColoredRGB("{"..cmt.."}то наказание будет в 6 часов кпз и нужно приписать 'х2', попытки работают по тому же принципу")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}16) Уход с Ghetto во время капта:{"..cmt.."} (/т [id] 10800 Уход с Ghetto) (3ч)")
				imgui.TextColoredRGB("{"..rmt.."} -> Можно только при погоне за игроком, который ушел с гетто во время капта")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}17) Нападение на АВС:{"..cmt.."} (/т [id] 7200 Нападение на АВС) (2ч)")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}18) На капте без Samp Addon или с выкл. античитом:{"..cmt.."} (/чм [id])")
				imgui.TextColoredRGB("{"..cmt.."}-> Наказывать без предупреждения и это +1 нарушение капта от любого игрока")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}19) Мониторинг за вражеской бандой вне территории капта/прилегающих территориях:{"..cmt.."} (/т [id] 3600 Мониторинг/Провокация) (1ч)")
				imgui.TextColoredRGB("{"..cmt.."}-> Целиться в противника вне территории каптура/вне прилегающих территориях; провоцировать любыми другими действиями противника")
			    imgui.TextColoredRGB("{"..cmt.."}-> Если игрок уезжает с территории, либо просто находится вне территории капта и следит за соперниками")
				imgui.TextColoredRGB("{"..cmt.."}(куда они едут, где собираются и т.п.) после чего сообщает эту информацию своим союзникам, то игрок наказывается")
				imgui.Spacing()
			    imgui.TextColoredRGB("{"..cmt.."}->Так же если игрок до 3й минуты специально выходит с территории к соперникам (при этом он с ними не стрелялся) и бегает возле них,")
				imgui.TextColoredRGB("{"..cmt.."}тем самым провоцируя, то в таком случае игрок наказывается")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}20) Обстрел чужой банды во время капта/обстрел банды у которой идет капт:{"..cmt.."} (/т [id] 3600/18000 Нанесение урона/DM) (1ч/5ч)")
				imgui.TextColoredRGB("{"..cmt.."}-> Если во время капта бандиты не участвующие в капте стреляют по бандитам, у которых капт, то сажаем по данному нормативу")
				imgui.TextColoredRGB("{"..cmt.."}Например капт Rifa - Grove, не участники капта - бандиты из банд Vagos, Aztecas и Ballas")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}21) Выход из игры на территории капта:{"..cmt.."} (/пнр [id] Выход из игры на капте)")
				imgui.TextColoredRGB("{"..cmt.."}-> Наказывать в случаях, если где-то рядом с игроком были соперники и он в этот момент вышел из игры и если это произошло на территории капта")
				imgui.TextColoredRGB("{"..cmt.."}-> Когда игрока кладут на анимацию 1-4 хп и при этом он выходит из игры, то наказывать не нужно,")
				imgui.TextColoredRGB("{"..cmt.."}так как при выходе убийство засчитывается тому, кто наносил урон и игрок умирает, наказывать нужно только если он не умер")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}22) SK:{"..cmt.."} (/т [id] 10800 SK) (3ч)")
				imgui.TextColoredRGB("{"..cmt.."}-> Если SK происходит вне капта, то сажать нужно по обычному нормативу (если двое в зоне SK)")
				imgui.TextColoredRGB("{"..rmt.."}Не сажать только в том случае, если игрок вышел с зоны SK, начал стреляться с соперником и потом побежал обратно в зону SK,")
				imgui.TextColoredRGB("{"..rmt.."}в таком случае сопернику разрешается догнать игрока и убить")
				imgui.Spacing()
			    imgui.TextColoredRGB("{"..cmt.."}-> На капте SK наказывается по тому же принципу, но есть исключения")
				imgui.TextColoredRGB("{"..cmt.."}Игроку, по которому стрельнули с зоны SK разрешается зайти в зону SK и начать стрельбу с тем, кто по нему стрелял")
				imgui.TextColoredRGB("{"..cmt.."}Разрешается только если соперник с респы начал первый стрелять и именно по тому игроку")
			    imgui.Spacing()
				imgui.TextColoredRGB("{"..cmt.."}-> Стрельба в SK зоне также наказуема, убивать не обязательно")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}23) Убийство в интерьере:{"..cmt.."} (/т [id] 18000 Убийство в интерьере) (5ч)")
				imgui.TextColoredRGB("{"..cmt.."}-> Наказывать в случае, если игрок заходит в магазин/дом и там убивает игрока с учетом того,")
				imgui.TextColoredRGB("{"..cmt.."}что убитый игрок до этого ни с кем не стрелялся и по нему не велась стрельба. Действительно на капте")
				imgui.PopFont()
			imgui.EndChild()
		end
		if active_window == 6 then
			imgui.BeginChild(u8"Мафия", imgui.ImVec2(992, 550), true)
				imgui.PushFont(fontsize15)
				imgui.TextColoredRGB("{"..smt.."}1) Стрельба с запрещенного оружия на теракте:{"..cmt.."} (/т [id] 1800 Стрельба со снайперки на теракте) (30м)")
				imgui.TextColoredRGB("{"..cmt.."}-> Запрещено использовать снайперскую винтовку на теракте")
				imgui.TextColoredRGB("{"..rmt.."}-> Если игрок никого не убил, то делаем предупреждение через /от, чтобы убрал оружие")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}Нанесение урона с запрещенного оружия на теракте:{"..cmt.."} (/т [id] 3600 Нанесение урона со снайперки на теракте) (1ч)")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}Убийство с запрещенного оружия на теракте:{"..cmt.."} (/т [id] 18000 Убийство со снайперки на теракте) (5ч)")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}2) Трансфер состава:{"..cmt.."} (/т [id] 36000 Трансфер) (10ч)")
				imgui.TextColoredRGB("{"..cmt.."}-> Уход с мафии и переход в другую с 14:00 до 23:00. Если игрок ушёл из мафии с основы и принялся с твина, то наказывается только твин")
				imgui.TextColoredRGB("{"..rmt.."}-> Трансфер из nonRP мафий [LCN/RM] в RP мафию [Yakuza] не запрещен, {FF0000}если не заключен RP союз с nonRP мафией")
				imgui.TextColoredRGB("{"..rmt.."}-> Трансфером не считается переход из одной мафии в другую, если игрок до этого не был на бизварах")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}3) Слив склада:{"..cmt.."} (/блок [id] 172800 или /т [id] 36000 Слив склада) (2д/10ч)")
				imgui.TextColoredRGB("{"..cmt.."}-> Умышлено брать патроны/металл в количестве от 1.000 единиц без разрешения лидера")
				imgui.TextColoredRGB("{"..rmt.."}-> Требовать от игрока вернуть обратно украденное")
				imgui.TextColoredRGB("{"..rmt.."}В случае, если игрок возвращает - КПЗ 10 часов, но если игрок продал/отказывается, то наказывать блокировкой")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}4) Прием в людном месте/без опроса/ниже 7-го уровня в мафию:{"..cmt.."} (/т [id] 7200 ...) (2ч)")
				imgui.TextColoredRGB("{"..cmt.."}-> Игрока которого приняли нужно уволить.")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}5) Аккаунты одновременно в мафии и в другой фракции:{"..cmt.."} (/пнр [id] Аккаунты в мафии и другой фракции)")
				imgui.TextColoredRGB("{"..rmt.."}-> Перед тем, как наказать убедитесь в том, что второй аккаунт это действительно твин, а не брат/друг")
				imgui.TextColoredRGB("{"..rmt.."}-> Наказание даётся в виде варна твину и увольнения основного аккаунта")
				imgui.TextColoredRGB("{"..rmt.."}-> Разрешено иметь один аккаунт в мафии, а другой в банде")
				imgui.TextColoredRGB("{"..rmt.."}-> Если один аккаунт находится в мафии Yakuza, то второй аккаунт можно иметь в ЛЮБОЙ фракции, кроме La Cosa Nostra/Russian Mafia/МО")
				imgui.TextColoredRGB("{"..rmt.."}-> Если один аккаунт находится в мафии RM/LCN, то второй аккаунт нельзя иметь в любой гос. фракции")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}6) Несоблюдение нормы количества 8 рангов:{"..cmt.."} (/т [id] 18000 Несоблюдение кол-ва 8 рангов) (5ч)")
				imgui.TextColoredRGB("{"..cmt.."}-> Наказание выдается только 9 рангам")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}7) Оскорбление в причине увольнения:{"..cmt.."} (/зк [id] 36000 Оскорбление в причине увольнения) (10ч)")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}8) Принятие/повышение игроков за игровую валюту:{"..cmt.."} (/пнр [id] Принятие в мафию за деньги/продажа ранга)")
				imgui.TextColoredRGB("{"..cmt.."}-> Сюда относятся не только деньги, но и любое вознаграждение - дом/машина/бизнес и т.д")
				imgui.TextColoredRGB("{"..cmt.."}-> Разрешено принимать/повышать за металл/патроны")
				imgui.TextColoredRGB("{"..rmt.."}-> Если это предлагает игрок ниже 8-го ранга то наказываем, как за развод")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}9) Установка бомбы без RP отыгровки:{"..cmt.."} (/т [id] 3600 Установка бомбы без RP отыгровки) (1ч)")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}10) Бизвар во время мороза одной из мафий:{"..cmt.."} (/т [id] 7200 Бизвар во время мороза) (2ч)")
				imgui.TextColoredRGB("{"..cmt.."}-> Если игрок любой мафии закаптил в мороз, наказывать по данному нормативу")
				imgui.TextColoredRGB("{"..rmt.."}-> В ситуациях, когда игроки специально сливают капт, создают кд - выдавать 10ч КПЗ")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}11) Стрельба на МО (кроме АВС):{"..cmt.."} (/т [id] 1800 nonRP стрельба) (30м)")
				imgui.TextColoredRGB("{"..cmt.."}-> Если игрок стреляет, наказывать по данному нормативу")
				imgui.TextColoredRGB("{"..cmt.."}-> Если игрок никого не убил, то делаем предупреждение через /от, чтобы покинул военную базу")
				imgui.TextColoredRGB("{"..rmt.."}-> Наказание выдается в случае, если игрок открыл огонь")
				imgui.TextColoredRGB("{"..cmt.."}-> Также могут быть ситуации, где игрок не стреляет, а просто бегает по военной базе/сливает инфу и так далее")
				imgui.TextColoredRGB("{"..cmt.."}В таких ситуациях нужно прогнать игрока через /от")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}Нанесение урона на МО (кроме АВС):{"..cmt.."} (/т [id] 3600 Нанесение урона) (1ч)")
				imgui.TextColoredRGB("{"..cmt.."}-> Если игрок наносит урон, наказывать по данному нормативу.")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}Нанесение урона на МО (кроме АВС):{"..cmt.."} (/т [id] 18000 Нападение мафии на МО) (5ч)")
				imgui.TextColoredRGB("{"..cmt.."}-> Если игрок убивает, наказывать по данному нормативу.")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}12) Ошибка в RP отыгровках:{"..cmt.."} (/т [id] 1800 Неполная/неверная отыгровка) (30м)")
				imgui.TextColoredRGB("{"..cmt.."}-> Пропуск действий в RP, которые сделаны в спец. темах и имеют конкретный шаблон обязательных действий")
				imgui.TextColoredRGB("{"..cmt.."}-> Неверный порядок действий в RP, которые сделаны в спец. темах и имеют конкретный шаблон обязательных действий")
				imgui.TextColoredRGB("{"..cmt.."}-> Пропущено название оружия, которое пишется в кавычках")
				imgui.TextColoredRGB("{"..cmt.."}-> Пропущен тип оружия, которое пишется перед названием, но при этом название в кавычках есть")
				imgui.TextColoredRGB("{"..cmt.."}-> Пропущено уточнение откуда достал и куда убрал оружие")
				imgui.TextColoredRGB("{"..cmt.."}-> Пропущена отыгровка, как игрок убирает оружие")
				imgui.TextColoredRGB("{"..cmt.."}-> Присутствует прогон и RP отыгровка оружия, но убили игрока не дожидаясь его ухода с прогоняемой территории")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}13) DM/TK:{"..cmt.."} (/т [id] 18000 DM) (5ч)")
				imgui.TextColoredRGB("{"..cmt.."}-> Если не отыграли как достали оружие/кулаки и убили игрока, но при этом отыграно что убрали оружие/кулаки")
				imgui.TextColoredRGB("{"..cmt.."}-> Если отыграли, что убрали оружие и убили игрока")
				imgui.TextColoredRGB("{"..cmt.."}-> Отыграно не то оружие с которого убили/стреляли")
				imgui.TextColoredRGB("{"..cmt.."}-> Отыграно, что достали оружие уже после убийства")
				imgui.TextColoredRGB("")
				imgui.PopFont()
				imgui.PushFont(fontsize20)
				imgui.TextColoredRGB("{"..cmt.."}Авианосец:")
				imgui.PopFont()
				imgui.PushFont(fontsize15)
				imgui.TextColoredRGB("{"..smt.."}14) Стрельба вне территории АВС:{"..cmt.."} (/т [id] 1800 nonRP стрельба) (30м)")
				imgui.TextColoredRGB("{"..cmt.."}-> Относится как к мафии {FF0000}(с 14:00 до 23:00), {FFFFFF}так и к военным")
				imgui.TextColoredRGB("{"..rmt.."}-> Перестрелки должны вестись в зеленой зоне (либо в красной, если смотреть по радару на карте)")
				imgui.TextColoredRGB("{"..cmt.."}-> Если стреляют, находясь вне зоны, наказывать по этому нормативу")
				imgui.TextColoredRGB("{"..cmt.."}-> В таких ситуациях возможна самооборона, не будет лишним запросить док-ва самообороны перед выдачей наказания")
				imgui.TextColoredRGB("{"..cmt.."}-> Если военный/мафиози покинул зону, но был в ней, то его разрешается догнать и слить в пределах зоны погони")
				imgui.TextColoredRGB("{"..cmt.."}-> В жалобах чаще всего недостаточно доказательств, но иногда прям видно нарушение. По жалобам лучше советоваться в ВК")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}Нанесение урона вне территории АВС:{"..cmt.."} (/т [id] 3600 Нанесение урона) (1ч)")
				imgui.TextColoredRGB("{"..cmt.."}-> Если наносят урон, находясь вне зоны, наказывать по этому нормативу.")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}Убийство вне территории АВС:{"..cmt.."} (/т [id] 18000 Слив вне территории АВС) (5ч)")
				imgui.TextColoredRGB("{"..cmt.."}-> Если сливают игрока, находясь вне зоны, наказывать по этому нормативу.")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}15) nonRP крыши на Авианосце:{"..cmt.."} (/т [id] 18000 nonRP крыша) (5ч)")
				imgui.TextColoredRGB("{"..cmt.."}-> Запрет распространяется только на мафиози. {FF0000}Если на авианосце нет никаких перестрелок , то просто выдайте предупреждение через /от игроку")
				imgui.TextColoredRGB("{"..rmt.."}-> Разрешено залезть на крышу, чтобы слить на ней находящихся военных")
				imgui.TextColoredRGB("{"..rmt.."}-> На элементах корабля авианосца запрещено находится как мафиози, так и военным")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}16) Содействие другой мафии на АВС:{"..cmt.."} (/т [id] 7200 Содействие другой мафии на АВС) (2ч)")
				imgui.TextColoredRGB("{"..rmt.."}Действует с 14:00 до 23:00:")
				imgui.TextColoredRGB("{"..cmt.."}-> Мафиози из разных фракций обязаны убивать друг друга")
				imgui.TextColoredRGB("{"..cmt.."}-> Убивать они обязаны только в случаях, когда открыто видят другого мафиози. Запрещено бегать и специально выискивать других мафиози")
				imgui.TextColoredRGB("{"..cmt.."}-> Отыгровки для убийства других мафиози также, как и для убийства военных, не нужны")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}17) Нападение на противоположную мафию на АВС:{"..cmt.."} (/т [id] 7200 Нападение на противоположную мафию на АВС) (2ч)")
				imgui.TextColoredRGB("{"..rmt.."}Действует с 23:00 до 14:00:")
				imgui.TextColoredRGB("{"..cmt.."}-> Мафиози из разных мафий не имеют право убивать друг друга на АВС (nonRP стрельба | Нанесение урона)")
				imgui.TextColoredRGB("{"..rmt.."}Исключение: самооборона. RP отыгровка обязательна")
				imgui.Spacing()
				imgui.TextColoredRGB("{"..smt.."}-> Убийство противоположной мафии после 23:00 (/т [id] 18000 Убийство другой мафии после 23:00 на АВС) (5ч)")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}18) Убийство мафии, с которой заключен RP союз:{"..cmt.."} (/т [id] 18000 Убийство союзной мафии) (5ч)")
				imgui.TextColoredRGB("{"..cmt.."}-> Запрещено стрелять, наносить урон, убивать союзную мафию в любое время (nonRP стрельба | Нанесение урона)")
				imgui.TextColoredRGB("{"..rmt.."}-> Если убито 2+ человека из противоположной мафии (в запрещённое время)/союзной мафии, то наказываем КПЗ, как за обычный DM")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}19) Байт на границе территории АВС:{"..cmt.."} (/т [id] 7200 Байт на АВС) (2ч)")
				imgui.TextColoredRGB("{"..cmt.."}-> Запрещено находиться на краю территории с целью провокации других игроков на нарушение")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}20) Слив вне территории АВС:{"..cmt.."} (/т [id] 18000 Слив вне территории АВС) (5ч)")
				imgui.TextColoredRGB("{"..cmt.."}Слив вне территории АВС после байта (/т [id] 7200 Слив вне территории АВС) (2ч)")
				imgui.TextColoredRGB("{"..rmt.."}-> По понятным причинам это описано только в нормативах, игрокам не нужно знать, во избежания злоупотребления")
				imgui.TextColoredRGB("")
				imgui.PopFont()
				imgui.PushFont(fontsize20)
				imgui.TextColoredRGB("{"..cmt.."}Похищения:")
				imgui.PopFont()
				imgui.PushFont(fontsize15)
				imgui.TextColoredRGB("{"..smt.."}21) nonRP похищение:{"..cmt.."} (/т [id] 3600 nonRP похищение) (1ч)")
				imgui.TextColoredRGB("{"..rmt.."}Важно! Если игрока похитили с целью убийства внутри территории АВС/бизвара, то выдается 3ч (10800) КПЗ")
				imgui.TextColoredRGB("{"..rmt.."}Если игрока похитили вне территории АВС/бизвара и завели его в территорию/зону видимости с территории (на бизваре) для убийства - варн")
				imgui.TextColoredRGB("{"..rmt.."}-> Похищение без RP отыгровок")
				imgui.TextColoredRGB("{"..rmt.."}-> Нарушены любые другие правила похищения")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}22) PG:{"..cmt.."} (/т [id] 7200 PG) (2ч)")
				imgui.TextColoredRGB("{"..cmt.."}-> Похищение в людном месте")
				imgui.TextColoredRGB("{"..cmt.."}-> Похищение с превышением своих возможностей. Пример: 1 жертва - 2 мафиози, 2 жертвы - 4 мафиози")
				imgui.TextColoredRGB("{"..rmt.."}-> Внимание! Если нарушается одновременно 17 и 18 пункты, то наказывать игрока нужно на 3 часа (10800) в сумме")
				imgui.TextColoredRGB("")
				imgui.PopFont()
				imgui.PushFont(fontsize20)
				imgui.TextColoredRGB("{"..cmt.."}Ограбления:")
				imgui.PopFont()
				imgui.PushFont(fontsize15)
				imgui.TextColoredRGB("{"..smt.."}23) nonRP ограбление:{"..cmt.."} (/т [id] 3600 nonRP ограбление) (1ч)")
				imgui.TextColoredRGB("{"..rmt.."}-> Важно! Проводить ограбление можно только дальнобойщиков")
				imgui.TextColoredRGB("{"..rmt.."}-> Важно! Ограбление разрешено проводить только RP мафии (Yakuza)")
				imgui.TextColoredRGB("{"..rmt.."}-> Ограбление в период с 10:00 до 22:00")
				imgui.TextColoredRGB("{"..cmt.."}-> Ограбление без RP отыгровок")
				imgui.TextColoredRGB("{"..cmt.."}-> Нарушены любые другие правила RP ограблений")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}24) PG:{"..cmt.."} (/т [id] 7200 PG) (2ч)")
				imgui.TextColoredRGB("{"..cmt.."}-> Ограбление в людном месте/при свидетелях")
				imgui.TextColoredRGB("{"..cmt.."}-> Ограбление с превышением своих возможностей. Ограбление проводится в составе от 2-х человек")
				imgui.TextColoredRGB("{"..rmt.."}-> Внимание! Если нарушается одновременно 22 и 23 пункты, то наказывать игрока нужно на 3 часа (10800) в сумме")
				imgui.TextColoredRGB("")
				imgui.PopFont()
				imgui.PushFont(fontsize20)
				imgui.TextColoredRGB("{"..cmt.."}Дальнобойщикам:")
				imgui.PopFont()
				imgui.PushFont(fontsize15)
				imgui.TextColoredRGB("{"..smt.."}25) Игнорирование RP отыгровок:{"..cmt.."} (/т [id] 3600 Отказ от RP) (1ч)")
				imgui.TextColoredRGB("{"..cmt.."}Например: во время погони дальнобойщик едет с пробитым колесом 2-3 минуты, игнорирует любые RP отыгровки,")
				imgui.TextColoredRGB("{"..cmt.."}а также их не соблюдает; воспользуется телефоном, когда у него его забрали по RP и т.д")
				imgui.Spacing()
				imgui.TextColoredRGB("{"..cmt.."}-> Запрещено покидать игру/уходить в AFK надолго при ограблении")
				imgui.TextColoredRGB("{"..rmt.."}-> Запрещено наплевательски относится ко всему процессу похищения и в частности к своей жизни")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}26) nonRP поведение:{"..cmt.."} (/т [id] 3600 nonRP поведение) (1ч)")
				imgui.TextColoredRGB("{"..cmt.."}-> Выход из игры при похищении/ограблении")
				imgui.TextColoredRGB("{"..cmt.."}Наказывать игроков, которые не хотят принимать в RP процессе участие")
				imgui.TextColoredRGB("")
				imgui.PopFont()
				imgui.PushFont(fontsize20)
				imgui.TextColoredRGB("{"..cmt.."}Бизвары: {FF0000}(указывать в скобках мафию)")
				imgui.PopFont()
				imgui.PushFont(fontsize15)
				imgui.TextColoredRGB("{"..smt.."}27) Слив на подготовительной минуте бизвара:{"..cmt.."} (/т [id] 18000 Слив на подготовительной минуте бизвара) (5ч)")
				imgui.TextColoredRGB("{"..cmt.."}-> Запрещено на подготовительной минуте убивать членов противоположной мафии на территории бизнеса")
				imgui.TextColoredRGB("{"..rmt.."}Исключение: самооборона")
				imgui.Spacing()
				imgui.TextColoredRGB("{"..rmt.."}-> Попытку слива наказывать одним часом КПЗ")
				imgui.TextColoredRGB("{"..rmt.."}Попытка включает в себя nonRP стрельбу/нанесение урона/nonRP поведение")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}28) Слив вне территории бизвара:{"..cmt.."} (/т [id] 18000 Слив вне территории бизвара) (5ч)")
				imgui.TextColoredRGB("{"..cmt.."}-> Слив вне территории бизвара подразумевает за собой, когда игрок вышел из территории/находится неподалеку/не касается зоны захвата")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}29) Попытка слива вне территории бизвара:{"..cmt.."} (/т [id] 10800 Попытка слива вне территории) (5ч)")
				imgui.TextColoredRGB("{"..cmt.."}-> Попытка включает в себя nonRP стрельбу/нанесение урона/nonRP поведение")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}30) Слив без RP отыгровки оружия на бизваре:{"..cmt.."} (/т [id] 18000 Слив без RP отыгровки оружия) (5ч)")
				imgui.TextColoredRGB("{"..rmt.."}ВАЖНО! RP ОТЫГРОВКА ОРУЖИЯ ПРОТИВ ПРОТИВОПОЛОЖНОЙ МАФИИ РЯДОМ С ТЕРРИТОРИЕЙ БИЗВАРА НЕ НУЖНА")
				imgui.TextColoredRGB("{"..cmt.."}-> Если на игрока напали вне территории (границ территории бизвара не видно на стандартном радаре),")
				imgui.TextColoredRGB("{"..cmt.."}то он обязан сделать RP отыгровку оружия и доказательства нападения")
				imgui.TextColoredRGB("{"..cmt.."}Если доказательств нападения нет - в причине пишем слив вне территории")
				imgui.Spacing()
				imgui.TextColoredRGB("{"..cmt.."}За отсутствие отыгровки наказываем, как за DM (/т [id] 18000 Убийство без RP отыгровки оружия) (5ч)")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}31) Помеха на бизваре:{"..cmt.."} (/т [id] 300 Помеха бизвару) (5м)")
				imgui.TextColoredRGB("{"..cmt.."}-> Когда во время бизвара игрок, не относящийся к мафии у которой захват, пытается всячески мешать и создавать помеху")
				imgui.TextColoredRGB("{"..cmt.."}Например, начинает отвлекать, подбегает с вопросами, бегает специально под прицелом, пытается ударить и т.д")
				imgui.Spacing()
				imgui.TextColoredRGB("{"..cmt.."}-> Игроки, которые просто проезжают мимо или просто стоят/занимаются своими делами")
				imgui.TextColoredRGB("{"..rmt.."}Например, продают свой транспорт на автосалоне - не являются помехой")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}32) Нападение в скинах начальных работ:{"..cmt.."} (/пнр [id] Скин начальных работ на бизваре)")
				imgui.TextColoredRGB("{"..cmt.."}-> Наказываем когда игрок целится/стреляет/убивает на бизваре")
				imgui.TextColoredRGB("{"..cmt.."}-> Если игрок просто стоит на территории бизвара, то делаем предупреждение через репорт, чтобы он покинул зону захвата")
				imgui.TextColoredRGB("{"..cmt.."}-> Если игрок игнорирует предупреждение, но при этом не нарушает, то наказываем, как за помеху")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}33) SK:{"..cmt.."} (/т [id] 10800 SК) (3ч)")
				imgui.TextColoredRGB("{"..cmt.."}-> -> Убийство безоружного мафиози, который только что вышел с больницы и бежит в сторону домов RK. Касается 27 и 96 бизнесов")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}34) Интерьер на бизваре/Интерьер в бою:{"..cmt.."} (/т [id] 7200 Интерьер на бизваре/в бою) (2ч)")
				imgui.TextColoredRGB("{"..cmt.."}-> Прятаться в интерьере во время боя. Наказывать в случае, когда игрок стрелял и убежал в инту")
				imgui.TextColoredRGB("{"..cmt.."}-> Запрещено заходить в помещения для починки, автомастерских, мастерская [ЭП]. Если игрок не был в бою и зашел, то наказывать не нужно")
				imgui.TextColoredRGB("{"..cmt.."}-> Интерьер на бизваре считается, когда игрок заходит в интерьер с целью использовать аптечку/спрятаться там от соперников,")
				imgui.TextColoredRGB("{"..cmt.."}при этом бой не обязателен. Исключение: разрешено зайти в интерьер, если на мини-карте(радаре) нет игроков из противоположной мафии")
				imgui.Spacing()
				imgui.TextColoredRGB("{"..cmt.."}-> Запрещено находиться под зоной захвата бизнеса. Например: в железнодорожном туннеле или в воде")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}35) Мафиози на бизваре без Samp Addon или с выкл. античитом:{"..cmt.."} (/чм [id])")
				imgui.TextColoredRGB("{"..cmt.."}-> Наказывать без предупреждения")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}36) Маска на бизваре:{"..cmt.."} (/т [id] 18000 Убийство в маске) (5ч)")
				imgui.TextColoredRGB("{"..cmt.."}-> Если игрок убил двоих - выдавать 10ч КПЗ, троих и более - за первое убийство выдаётся варн, за последующие КПЗ по 5ч")
				imgui.TextColoredRGB("{"..cmt.."}-> Наказывать если мафиози в маске рядом с территорией/на территории бизвара убил игрока противоположной мафии")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}37) nonRP крыша:{"..cmt.."} (/т [id] 18000 NonRP крыша) (5ч)")
				imgui.TextColoredRGB("{"..cmt.."}-> Находиться во время бизвара на крыше, на которую нельзя забраться самому или с помощью подсадки через транспортное средство")
				imgui.TextColoredRGB("{"..cmt.."}Любые другие способы запрещены")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}38) Антикилл/Антифраг:{"..cmt.."} (/т [id] 10800 Антикилл) (3ч)")
				imgui.TextColoredRGB("{"..cmt.."}-> Намеренно убить своего/союзного персонажа")
				imgui.TextColoredRGB("{"..cmt.."}Например: спрыгнуть с крыши или убить игрока своей фракции с целью, чтобы сопернику не засчитали убийство")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}39) Запрещенное оружие на бизваре:")
				imgui.TextColoredRGB("{"..cmt.."}(/т [id] 1800 Стрельба с запрещенного оружия) (30м)")
				imgui.TextColoredRGB("{"..cmt.."}(/т [id] 3600 Нанесение урона с запрещенного оружия) (1ч)")
				imgui.TextColoredRGB("{"..cmt.."}(/т [id] 18000 Запрещенное оружие на бизваре) (5ч)")
				imgui.TextColoredRGB("{"..cmt.."}-> Запрещено все оружие, которые мафиози не могут сделать самостоятельно")
				imgui.TextColoredRGB("{"..cmt.."}-> Сначала предупреждаем игрока через репорт, чтобы он убрал оружие")
				imgui.TextColoredRGB("{"..cmt.."}-> Наказывать только тогда, когда применили запрещенное оружие")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}40) Помощь другой мафии:{"..cmt.."} (/т [id] 3600 Помощь другой мафии) (1ч)")
				imgui.TextColoredRGB("{"..cmt.."}-> Наказывать, когда игроки из разных мафий помогают друг другу во время бизвара")
				imgui.TextColoredRGB("{"..cmt.."}Например, выдают/продают оружие, подвозят до места захвата бизнеса и тд")
				imgui.TextColoredRGB("{"..rmt.."}Исключение: при захвате пустого бизнеса первой мафией, вторая и третья мафия могут сотрудничать")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}41) Байт на границе территории бизвара:{"..cmt.."} (/т [id] 7200 Байт на границе территории бизнеса) (2ч)")
				imgui.TextColoredRGB("{"..cmt.."}-> Запрещено находиться на краю территории с целью провокации других игроков на нарушение")
				imgui.TextColoredRGB("{"..cmt.."}-> Байт определяется только следящими администраторами")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}42) Слив после окончания времени бизвара:")
				imgui.TextColoredRGB("{"..cmt.."}(/т [id] 3600 Нанесение урона) (1ч)")
				imgui.TextColoredRGB("{"..cmt.."}(/т [id] 18000 Слив после окончания времени бизвара) (5ч)")
				imgui.TextColoredRGB("{"..cmt.."}-> Бой, начатый во время бизвара разрешается закончить после окончания времени захвата")
				imgui.TextColoredRGB("{"..rmt.."}-> При самообороне после окончания бизвара нужна RP отыгровка")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}43) Анимация в бою:{"..cmt.."} (/т [id] 18000 Анимация в бою) (5ч)")
				imgui.TextColoredRGB("{"..cmt.."}-> Наказываем по факту нарушения")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}44) Сбив анимации:")
				imgui.TextColoredRGB("{"..cmt.."}1-3LVL (/т [id] 1800 Сбив анимации) (30м)")
				imgui.TextColoredRGB("{"..cmt.."}Во фракции (/пнр [id] Сбив анимации)")
				imgui.TextColoredRGB("{"..cmt.."}Не во фракции (/т [id] 36000 Сбив анимации) (10ч)")
				imgui.TextColoredRGB("{"..cmt.."}-> За сбив маски наказывать можно только если во время боя это происходило")
				imgui.TextColoredRGB("{"..rmt.."}-> За сбив аптечки ЗАПРЕЩЕНО наказывать если игрок сбил, но при этом стоит на месте")
				imgui.TextColoredRGB("{"..rmt.."}Так же запрещено наказывать если не видно самого момента сбива")
				imgui.TextColoredRGB("{"..rmt.."}Если не видно момент сбива, но уж слишком очевидно всё, то наказывайте")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}45) Лаги:{"..cmt.."} (/т [id] 300 Высокая потеря/Большой пинг) (5м)")
				imgui.TextColoredRGB("{"..cmt.."}-> Запрещено находиться на бизваре/стреле с потерей более 10%/пингом больше 200")
				imgui.TextColoredRGB("{"..rmt.."}Важно! Наглядно должно быть видно, что игрок лагает. Например: ему не проходит урон, он 'плавает' по карте")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}46) Нанесение урона/убийство транспортом:{"..cmt.."} (/т [id] 3600 Нанесение урона | /т [id] 18000 DB) (1ч/5ч)")
				imgui.TextColoredRGB("{"..cmt.."}-> Запрещено наносить урон с транспорта, а также сбивать с ног противоположную мафию")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}47) Увольнение без причины:{"..cmt.."} (/т [id] 7200 Увольнение во время бизвара) (2ч)")
				imgui.TextColoredRGB("{"..rmt.."}Важно! На подготовительной минуте увольнять игроков разрешено. Исключение: 8 ранги")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}48) Понижение игрока 8 ранга:{"..cmt.."} (/т [id] 7200 Понижение во время бизвара) (2ч)")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}49) Багоюз:{"..cmt.."} (/т [id] 36000 Багоюз) (10ч)")
				imgui.TextColoredRGB("{"..cmt.."}-> Передача денег с целью создать КД на передачу оружия")
				imgui.TextColoredRGB("{"..cmt.."}-> Подставная продажа оружия противоположной мафии за высокую стоимость")
				imgui.TextColoredRGB("{"..cmt.."}-> Стоять на транспорте с водителем и стрелять по игрокам противоположной мафии")
				imgui.TextColoredRGB("{"..cmt.."}-> Когда прыгают с высоты и используют любые анимации чтобы не получить урона от падения")
				imgui.TextColoredRGB("{"..cmt.."}(наказывать только за прыжки с большой высоты с которой игрок бы умер)")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}50) Уход с территории в бою:{"..cmt.."} (/т [id] 7200 Уход с территории в бою) (2ч)")
				imgui.TextColoredRGB("{"..cmt.."}-> Если стреляют в сторону игрока, который находится в территории")
				imgui.TextColoredRGB("{"..cmt.."}(даже если он в транспорте) из вне территории, ему запрещено выходить с территории более чем 50/50 положения клиста на границе территории")
				imgui.Spacing()
				imgui.TextColoredRGB("{"..cmt.."}-> Плюсовать наказания только если нарушение происходило в разных перестрелках/ситуациях")
				imgui.TextColoredRGB("{"..cmt.."}Когда много раз за одну ситуацию/против одного игрока бегает туда-сюда - выдавать 2ч")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}51) Мониторинг:{"..cmt.."} (/т [id] 7200 Мониторинг) (2ч)")
				imgui.TextColoredRGB("{"..cmt.."}-> Наказывается только когда игрок находится в маске на границе территории бизвара/в зоне стрима от границы территории бизвара на радаре")
				imgui.TextColoredRGB("{"..cmt.."}-> Если игрок в маске, приближаясь к территории видит игроков противоположной мафии на краю территории,")
				imgui.TextColoredRGB("{"..cmt.."}маску нужно обязательно снять, если продолжает бежать/ехать дальше к территории в маске - наказывать по данному нормативу")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}52) nonRP поведение:{"..cmt.."} (/т [id] 3600 nonRP поведение) (1ч)")
				imgui.TextColoredRGB("{"..cmt.."}-> Угон/попытка угона транспорта противоположной мафии на RK")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}53) PG:{"..cmt.."} (/т [id] 7200 PG) (2ч)")
				imgui.TextColoredRGB("{"..cmt.."}-> Запрещено наносить урон кулаками или любым оружием ближнего боя против огнестрельного оружия")
				imgui.TextColoredRGB("{"..cmt.."}-> Запрещено 'станить' соперника кулаком")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}54) Редактирование файлов Addon:{"..cmt.."} (/блок [id] 172800 Редактирование файлов Addon)")
				imgui.TextColoredRGB("{"..cmt.."}-> Игрок на бизваре без файла samp.asi")
				imgui.TextColoredRGB("{"..rmt.."}-> По статистике выдавать наказание запрещено!")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}55) Выход из игры на территории бизвара:{"..cmt.."} (/пнр [id] Выход из игры на бизваре)")
				imgui.TextColoredRGB("{"..cmt.."}-> Наказывать в случаях, если рядом с игроком были соперники/стреляли рядом с ним, и он в этот момент вышел из игры")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}56) Транспорт на очках:{"..cmt.."} (/т [id] 7200 Транспорт на очках) (2ч)")
				imgui.TextColoredRGB("{"..cmt.."}-> Мафиози во время бизвара садится на пассажирское сидение и качает очки. Машину взрывают, он садится в следующее")
				imgui.TextColoredRGB("{"..rmt.."}-> Наказывать только в зоне очков!")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}57) Провокация:{"..cmt.."} (/т [id] 3600 Провокация) (1ч)")
				imgui.TextColoredRGB("{"..cmt.."}-> Наказывать, если мафиози стоит около края территории и выцеливает игроков, которые находятся вне")
				imgui.PopFont()
			imgui.EndChild()
		end
		if active_window == 8 then
			imgui.BeginChild(u8"СМИ", imgui.ImVec2(992, 550), true)
				imgui.PushFont(fontsize15)
				imgui.TextColoredRGB("{"..smt.."}1) /обпр:{"..cmt.."} (/зк [id] 1800 /обпр) (30м)")
				imgui.TextColoredRGB("{"..cmt.."}-> Смотрите чтоб это было не случайность, а специально и желательно не единичный случай")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}2)  Ошибка при /обпр:{"..cmt.."} (/зк [id] 900 /обпр) (15м)")
				imgui.TextColoredRGB("{"..cmt.."}-> 2 грамматических либо 2 пунктуационные ошибки, либо обка без тэга")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}3) Умышленное изменение текста при /обпр или мат:{"..cmt.."} (/зк [id] 18000 /обпр) (5ч)")
				imgui.TextColoredRGB("{"..cmt.."}-> Пример: девушка написала 'куплю дом', ее отредачили как 'сосу дешево. цена 1$'")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}4) Нарушение правил билбордов, мат на билборде:{"..cmt.."} (/зк [id] 3600 Нарушение правил билбордов) (1ч)")
				imgui.TextColoredRGB("{"..cmt.."}-> Пример: Продам донат. Предоставляю интимные услуги. Любой мат")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}5) Разрешенные оскорбления на билбордах:{"..cmt.."} (/зк [id] 18000 Нарушение правил билбордов) (5ч)")
				imgui.TextColoredRGB("{"..cmt.."}-> Распространяется на разрешенные оскорбления (те, за которые не глушат админы)")
				imgui.TextColoredRGB("{"..cmt.."}-> Сюда так же входят нарушения, которые не тянут на варн, но имеют более тяжелый характер, чем 1 час")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}6) Нарушение правил прямого эфира - MG, много ошибок, откровенный бред:{"..cmt.."} (/з [id] 3600 Нарушение правил прямого эфира) (1ч)")
				imgui.TextColoredRGB("{"..cmt.."}-> Если это интервью, то наказывать нужно того кто допускает ошибки")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}7) DM / TK или оскорбления на билбордах:{"..cmt.."} (/пнр [id] nonRP СМИ)")
				imgui.TextColoredRGB("{"..cmt.."}-> Если одновременно сделано много киллов, то за 1-ый даётся варн, за все остальные наказывать как за обычный DM")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}8) Ошибка в RP отыгровках:{"..cmt.."} (/т [id] 1800 Не полная/не верная отыгровка) (30м)")
				imgui.TextColoredRGB("{"..cmt.."}-> Пропуск действий в RP, которые сделаны в спец. темах и имеют конкретный шаблон обязательных действий")
				imgui.TextColoredRGB("{"..cmt.."}-> Неверный порядок действий в RP, которые сделаны в спец. темах и имеют конкретный шаблон обязательных действий")
				imgui.TextColoredRGB("{"..cmt.."}-> Пропущено название оружия, которое пишется в ковычках")
				imgui.TextColoredRGB("{"..cmt.."}-> Пропущен тип оружия, которое пишется перед названием, но при этом название в ковычках есть")
				imgui.TextColoredRGB("{"..cmt.."}-> Пропущено уточнение откуда достал и куда убрал оружие")
				imgui.TextColoredRGB("{"..cmt.."}-> Пропущена отыгровка как игрок убирает оружие")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}9) RP отыгровка оружия/кулаков и т.д в ситуациях когда убивают другого игрока")
				imgui.TextColoredRGB("{"..cmt.."}-> Наказывать как за DM, но не варном, а КПЗ. Срок КПЗ как для игрока без фракции")
				imgui.TextColoredRGB("{"..cmt.."}-> Если не отыграли как достали оружие/кулаки и убили игрока, но при этом отыграно что убрали оружие/кулаки")
				imgui.TextColoredRGB("{"..cmt.."}-> Если отыграли что убрали оружие и убили игрока")
				imgui.TextColoredRGB("{"..cmt.."}-> Отыграно не то оружие с которого убили/стреляли")
				imgui.TextColoredRGB("{"..cmt.."}-> Отыграно что достали оружие уже после убийства")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}10) Если RP отыгровка оружия или причина для убийства отсутствует совсем:{"..cmt.."} (/пнр [id] nonRP СМИ)")
				imgui.PopFont()
			imgui.EndChild()
		end
		if active_window == 9 then
			imgui.BeginChild(u8"Мэрия", imgui.ImVec2(992, 550), true)
				imgui.PushFont(fontsize15)
				imgui.TextColoredRGB("{"..smt.."}1) Продажа лицензий вообще без RP отыгровок:{"..cmt.."} (/пнр [id] nonRP сотрудник мэрии)")
				imgui.TextColoredRGB("{"..cmt.."}-> Смотрите чтоб это было не случайность, а специально и желательно не единичный случай")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}2) DM / TK:{"..cmt.."} (/пнр [id] nonRP сотрудник мэрии)")
				imgui.TextColoredRGB("{"..cmt.."}-> Если одновременно сделано много киллов, то за 1-ый даётся варн, {FF0000}за все остальные наказывать как за обычный DM")
				imgui.TextColoredRGB("{"..rmt.."}-> За килл мафиозника на крыше во время бизвара - наказывать как за обычный ДМ 2 часа КПЗ")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}3) Ошибка в RP отыгровках:{"..cmt.."} (/т [id] 1800 Не полная/не верная отыгровка) (30м)")
				imgui.TextColoredRGB("{"..cmt.."}-> Пропуск действий в RP, которые сделаны в спец. темах и имеют конкретный шаблон обязательных действий")
				imgui.TextColoredRGB("{"..cmt.."}-> Неверный порядок действий в RP, которые сделаны в спец. темах и имеют конкретный шаблон обязательных действий")
				imgui.TextColoredRGB("{"..cmt.."}-> Пропуск действий вывода из мэрии в случае Код-2")
				imgui.TextColoredRGB("{"..cmt.."}-> Отсутствие отсчёта")
				imgui.TextColoredRGB("{"..cmt.."}-> Присутствует прогон и RP отыгровка оружия, но убили игрока не дожидаясь его ухода с прогоняемой территории")
				imgui.TextColoredRGB("{"..cmt.."}-> Наличие отсчёта цифрами, а не словами")
				imgui.TextColoredRGB("{"..cmt.."}-> Пропущено название оружия, которое пишется в ковычках")
				imgui.TextColoredRGB("{"..cmt.."}-> Пропущен тип оружия, которое пишется перед названием, но при этом название в ковычках есть")
				imgui.TextColoredRGB("{"..cmt.."}-> Пропущено уточнение откуда достал и куда убрал оружие")
				imgui.TextColoredRGB("{"..cmt.."}-> Пропущена отыгровка как игрок убирает оружие")
				imgui.TextColoredRGB("{"..cmt.."}-> Гравировка на служебном оружии")
				imgui.TextColoredRGB("{"..cmt.."}-> На тренировке сделана RP отыгровка оружия огнестрельного, а не пейтбольного")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}4) RP отыгровка оружия/кулаков и т.д в ситуациях когда убивают другого игрока")
				imgui.TextColoredRGB("{"..cmt.."}-> Наказывать как за DM, но не варном, а КПЗ. Срок КПЗ как для игрока без фракции")
				imgui.TextColoredRGB("{"..cmt.."}-> Если не отыграли как достали оружие/кулаки и убили игрока, но при этом отыграно что убрали оружие/кулаки")
				imgui.TextColoredRGB("{"..cmt.."}-> Если отыграли что убрали оружие и убили игрока")
				imgui.TextColoredRGB("{"..cmt.."}-> Отыграно не то оружие с которого убили/стреляли")
				imgui.TextColoredRGB("{"..cmt.."}-> Отыграно что достали оружие уже после убийства")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}5) Если RP отыгровка оружия или причина для убийства отсутствует совсем:{"..cmt.."} (/пнр [id] nonRP сотрудник мэрии)")
				imgui.PopFont()
			imgui.EndChild()
		end
		if active_window == 10 then
			imgui.BeginChild(u8"Больница", imgui.ImVec2(992, 550), true)
				imgui.PushFont(fontsize15)
				imgui.TextColoredRGB("{"..smt.."}1) Лечение вообще без RP отыгровок:{"..cmt.."} (/пнр [id] nonRP врач)")
				imgui.TextColoredRGB("{"..cmt.."}-> Смотрите чтоб это было не случайность, а специально и желательно не единичный случай")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}2) DM / TK:{"..cmt.."} (/пнр [id] nonRP врач)")
				imgui.TextColoredRGB("{"..cmt.."}-> Если одновременно сделано много киллов, то за 1-ый даётся варн, {FF0000}за все остальные наказывать как за обычный DM")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}3) Ошибка в RP отыгровках:{"..cmt.."} (/т [id] 1800 Не полная/не верная отыгровка) (30м)")
				imgui.TextColoredRGB("{"..cmt.."}-> Пропуск действий в RP, которые сделаны в спец. темах и имеют конкретный шаблон обязательных действий")
				imgui.TextColoredRGB("{"..cmt.."}-> Неверный порядок действий в RP, которые сделаны в спец. темах и имеют конкретный шаблон обязательных действий")
				imgui.TextColoredRGB("{"..cmt.."}-> Пропущено название оружия, которое пишется в ковычках")
				imgui.TextColoredRGB("{"..cmt.."}-> Пропущен тип оружия, которое пишется перед названием, но при этом название в ковычках есть")
				imgui.TextColoredRGB("{"..cmt.."}-> Пропущено уточнение откуда достал и куда убрал оружие")
				imgui.TextColoredRGB("{"..cmt.."}-> Пропущена отыгровка как игрок убирает оружие")
				imgui.TextColoredRGB("{"..cmt.."}-> На тренировке сделана RP отыгровка оружия огнестрельного, а не пейтбольного")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}4) RP отыгровка оружия/кулаков и т.д в ситуациях когда убивают другого игрока")
				imgui.TextColoredRGB("{"..cmt.."}-> Наказывать как за DM, но не варном, а КПЗ. Срок КПЗ как для игрока без фракции")
				imgui.TextColoredRGB("{"..cmt.."}-> Если не отыграли как достали оружие/кулаки и убили игрока, но при этом отыграно что убрали оружие/кулаки")
				imgui.TextColoredRGB("{"..cmt.."}-> Если отыграли что убрали оружие и убили игрока")
				imgui.TextColoredRGB("{"..cmt.."}-> Отыграно не то оружие с которого убили/стреляли")
				imgui.TextColoredRGB("{"..cmt.."}-> Отыграно что достали оружие уже после убийства")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}5) Если RP отыгровка оружия или причина для убийства отсутствует совсем:{"..cmt.."} (/пнр [id] nonRP врач)")
				imgui.PopFont()
			imgui.EndChild()
		end
		if active_window == 11 then
			imgui.BeginChild(u8"Нормативы", imgui.ImVec2(992, 550), true)
				imgui.PushFont(fontsize15)
				imgui.TextColoredRGB("{"..smt.."}1) Сбив анимации:")
				imgui.TextColoredRGB("{"..cmt.."}1-3LVL (/т [id] 1800 Сбив анимации) (30м)")
				imgui.TextColoredRGB("{"..cmt.."}Во фракции (/пнр [id] Сбив анимации)")
				imgui.TextColoredRGB("{"..cmt.."}Не во фракции (/т [id] 36000 Сбив анимации) (10ч)")
				imgui.TextColoredRGB("{"..cmt.."}-> За сбив маски наказывать можно только если во время боя это происходило")
				imgui.TextColoredRGB("{"..rmt.."}-> За сбив аптечки ЗАПРЕЩЕНО наказывать если игрок сбил, но при этом стоит на месте")
				imgui.TextColoredRGB("{"..rmt.."}Так же запрещено наказывать если не видно самого момента сбива")
				imgui.TextColoredRGB("{"..rmt.."}Если не видно момент сбива, но уж слишком очевидно всё, то наказывайте")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}2) Багоюз:{"..cmt.."} (/т [id] 36000 Багоюз) (10ч)")
				imgui.TextColoredRGB("{"..cmt.."}-> Использование твинков для перекачки денег через развозчиков еды/автомехаников/автобусы/такси и т.д")
				imgui.TextColoredRGB("{"..cmt.."}-> Высокие прыжки на велосипеде (наказывыйте только если это используется для получения преимущества в погоне и т.д,")
				imgui.TextColoredRGB("{"..cmt.."}а когда просто так прыгают - наказывайте на 5м по нормативу 'остынь'")
				imgui.Spacing()
				imgui.TextColoredRGB("{"..rmt.."}* В случаях, когда игрок намеренно багоюзит для того, чтобы получить преимущество можно наказывать после первого прыжка")
				imgui.TextColoredRGB("{"..cmt.."}-> Когда закрывают багом арендованные машины через Num6 (многократно это делают в одно время, за 1 раз достаточно 'Остынь')")
				imgui.TextColoredRGB("{"..cmt.."}-> Когда прыгают с высоты и используют любые анимации чтоб не получить урона от падения (высота с которой игрок бы умер)")
				imgui.TextColoredRGB("{"..cmt.."}-> Багоюз на поезде (заканчивать маршрут не доезжая до конечной, тем самым делая так что тебя не выкинет на конечной из поезда)")
				imgui.TextColoredRGB("{"..cmt.."}-> AFK через меню в бою/при аресте (наказывать только игроков по которым не будет идти урон)")
				imgui.TextColoredRGB("{"..cmt.."}-> Когда игрок вступает в бой с ящиком патронов 'на шее'")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}Багоюз связанный с фармом вирт:{"..cmt.."} (смотреть сколько нафармили и если сумма приличная - выдавать бан)")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}3) Использование читов:{"..cmt.."} (/чм [id], если игрок во фракции то его нужно уволить)")
				imgui.TextColoredRGB("{"..cmt.."}-> Помимо нарушения нужно так же зафиксировать на видео/скрин статистику игрока и его доп. инфу")
				imgui.TextColoredRGB("{"..cmt.."}-> За Cleo-анимации наказываются игроки только из МО, ПД, Ghetto и Мафии")
				imgui.TextColoredRGB("{"..rmt.."}Исключение: за анимацию 'писать/дрочить' наказываем всех без исключения")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}4) Замены дающие преимущество:{"..cmt.."} (/чм [id] с аддоном или сделать 3 попадания. Наказание даётся на 1 месяц)")
				imgui.TextColoredRGB("{"..cmt.."}-> Скины карликов / Скины без головы/Голова скина перенесена в другое место")
				imgui.TextColoredRGB("{"..cmt.."}-> Прозрачные замены")
				imgui.TextColoredRGB("{"..cmt.."}-> Замены на пакеты")
				imgui.TextColoredRGB("{"..cmt.."}-> Замены на авто (например авто 4-х дверное, а замена на 2-х дверное). Наказывать только когда копы из-за этого не могут посадить игрока в т/с")
				imgui.TextColoredRGB("{"..cmt.."}-> Замены на пальмы. Пальмы для начала просим удалить и наказывать только при повторе")
				imgui.TextColoredRGB("{"..cmt.."}-> Замены на транспорт дальнобойщиков, когда авто намного больше или меньше размером. Просим удалить и при игноре или повторе наказывать")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}5) Продажа/распространение читов:{"..cmt.."} (/блок [id] -1 Продажа/распространение читов)")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}6) nonRP relog: {"..cmt.."}Любая фракция (/пнр [id] nonRP relog) (10ч) | Без фракции (/т [id] 36000 nonRP relog) (10ч)")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}7) nonRP перекаты:")
				imgui.TextColoredRGB("{"..cmt.."}Не в бою (не наказуемо)")
				imgui.TextColoredRGB("{"..cmt.."}nonRP перекаты не в бою (/т [id] 7200 Причина) (2ч)")
				imgui.TextColoredRGB("{"..cmt.."}Стрельба +С не в бою (/т [id] 7200 Причина) (2ч)")
				imgui.TextColoredRGB("{"..cmt.."}+С отвод для всех не в бою (/т [id] 7200 Причина) (2ч)")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..cmt.."}Стрельба +С в бою (/т [id] 36000 Причина) (10ч)")
				imgui.TextColoredRGB("{"..cmt.."}+С отвод для всех в бою (/т [id] 36000 Причина) (10ч)")
				imgui.TextColoredRGB("{"..cmt.."}Анимации в бою  в бою (/т [id] 36000 Причина) (10ч)")
				imgui.TextColoredRGB("{"..cmt.."}-> Боем считается любая перестрелка и не важно сам игрок стреляет или в него стреляют")
				imgui.TextColoredRGB("{"..rmt.."}Наказывать только если игрок крутится на месте по кругу, без всяких там градусов")
				imgui.Spacing()
				imgui.TextColoredRGB("{"..rmt.."}-> Анимации в бою, что это такое? В тебя стреляют - ты юзаешь анимку")
				imgui.TextColoredRGB("{"..rmt.."}НАКАЗЫВАТЬ ТОЛЬКО ПРИ УСЛОВИИ ЧТО ВИДНО ИМЕННО СТРЕЛЬБУ В ИГРОКА. Использовать анимки чтоб спрыгнуть в небольшой высоты можно даже в бою")
				imgui.Spacing()
				imgui.TextColoredRGB("{"..rmt.."}-> Самое важное! Для наказания по нормативу нужно чтоб было минимум 2+ нарушения")
				imgui.TextColoredRGB("{"..rmt.."}(+с и сбив переката, два +с в разных ситуациях с не большим промежутком времени и т.д)")
				imgui.TextColoredRGB("{"..rmt.."}Сделали 2+ нарушения, вы наказали в общем на 2 или 10 часов")
				imgui.TextColoredRGB("{"..rmt.."}Нарушения в бою и не в бою не суммируются. Должно быть только в бою или только не в бою")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}8) Использование ракбота и подобных программ:{"..cmt.."} (/чм [id], если игрок во фракции то его нужно уволить)")
				imgui.TextColoredRGB("{"..cmt.."}-> Как определять таких игроков смотреть во вкладке Багоюз/Читы - Ракботы")
				imgui.TextColoredRGB("{FF0000}-> Samp Mobile можно использовать")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}9) Помощь читера:{"..cmt.."} (/блок [id] 86400 Помощь читера) (1д)")
				imgui.TextColoredRGB("{"..cmt.."} -> Если очевидно, что читер помогает как-то игроку, например: телепортирует или убивает кого-то по просьбе игрока")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}10) Обход Samp Addon:{"..cmt.."} (/блок [id] -1 Обход аддона + ЧМ с аддоном) (вечность)")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}11) Сбив выстрела:{"..cmt.."} (/т [id] 36000 Сбив выстрела) (10ч)")
				imgui.PopFont()
			imgui.EndChild()
		end
		if active_window == 14 then
			imgui.BeginChild(u8"Ракботы", imgui.ImVec2(992, 550), true)
				imgui.Columns(3, "Colums", true)
				-- 1
				imgui.TextColoredRGB("{"..cmt.."}Rakbot, rakdroid, raksamp, sampbot")
				imgui.NextColumn()
				imgui.TextColoredRGB("{"..cmt.."}Интерьер 0, Мир 0, FPS 0, Скин неизвестен")
				imgui.TextColoredRGB("{"..cmt.."}Действий обычно нет, урон не идет")
				imgui.NextColumn()
				imgui.TextColoredRGB("{"..cmt.."}noAFK включен: сверху ничего нет, .тпи в воздухе")
				imgui.Spacing()
				imgui.TextColoredRGB("{"..cmt.."}noAFK выключен: песочные часы и пауза секунды,")
				imgui.TextColoredRGB("{"..cmt.."}.тпи в воздухе счетчик паузы обнуляется")
				imgui.TextColoredRGB("")
				imgui.Separator()
				imgui.NextColumn()
				
				-- 2
				imgui.TextColoredRGB("{"..cmt.."}Игрок без Samp Addon свернувший игру или на паузе")
				imgui.NextColumn()
				imgui.TextColoredRGB("{"..cmt.."}FPS 0, Скин неизвестен")
				imgui.TextColoredRGB("{"..cmt.."}.тпи не меняет место и счетчик паузы не обнуляется")
				imgui.TextColoredRGB("{"..cmt.."}не идет урон")
				imgui.TextColoredRGB("")
				imgui.NextColumn()
				imgui.TextColoredRGB("{"..cmt.."}Песочные часы и пауза секунды")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("")
				imgui.Separator()
				imgui.NextColumn()
				
				-- 3
				imgui.TextColoredRGB("{"..cmt.."}Сторонний софт (не имеет функции NoAFK)")
				imgui.NextColumn()
				imgui.TextColoredRGB("{"..cmt.."}FPS любое значение, Скин неизвестен")
				imgui.TextColoredRGB("{"..cmt.."}Действий обычно нет, урон не идет")
				imgui.NextColumn()
				imgui.TextColoredRGB("{"..cmt.."}.тпи в воздухе")
				
				imgui.Columns(1)
				imgui.Separator()
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}Проверка игрока на ракбот:")
				imgui.TextColoredRGB("{"..cmt.."}- Проверка Samp Addon")
				imgui.TextColoredRGB("{"..cmt.."}- Проверка доп. информации (Ориг. модель скина: Неизвестно; FPS – чаще всего 0, но с последней программой может быть любое значение)")
				imgui.TextColoredRGB("{"..cmt.."}- Проверка на свёрнутую игру (при .тпи у ракбота сбрасывается счётчик AFK, у свернутой игры – нет)")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}Дополнение:")
				imgui.TextColoredRGB("{"..cmt.."}- При этом даже если игрок не в КПЗ")
				imgui.TextColoredRGB("{"..cmt.."}/тпи пауза не сбивается + не в воздухе, /доп FPS 0 + неизвестный скин")
				imgui.TextColoredRGB("{"..cmt.."}Только после отправки в ЧМ собьется таймер")
				imgui.Spacing()
				imgui.TextColoredRGB("{"..cmt.."}- Если у игрока анимация рыбы в руке (но рыбы нет) и игрок находится на паузе, то сразу в ЧМ")
				imgui.TextColoredRGB("{"..rmt.."}В данном случае на /тпи не проверить + наручники не помогут + нанесение урона")
				imgui.TextColoredRGB("{"..rmt.."}Чтобы проверить придется ждать пока игрок выйдет из КПЗ т.к. нам запрещено выпускать из КПЗ на время, а потом уже /тпи")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}Мини-дополнение:")
				imgui.TextColoredRGB("{"..cmt.."}Если при использовании rakdroid или rakbot пауза сбивалась при /тпи, то когда юзают другие - не сбивается")
				imgui.TextColoredRGB("{"..cmt.."}Выглядит как обычная свернутая игра без Samp Addon + пауза над головой (/тпи пауза не сбивается)")
				imgui.TextColoredRGB("{"..rmt.."}После /респ сбивается пауза, если игрок просто свернул игру без Samp Addon, то сбиваться не будет")
				
				--img = imgui.CreateTextureFromFile(getWorkingDirectory() .. "\\images\\header_mo.jpg")
				--imgui.(img, imgui.ImVec2(500, 150))
			imgui.EndChild()
		end
		if active_window == 12 then
			imgui.BeginChild(u8"Нормативы чата", imgui.ImVec2(992, 550), true)
				imgui.PushFont(fontsize15)
				imgui.TextColoredRGB("{"..smt.."}1) MG:{"..cmt.."} (/з [id] MG)")
				imgui.TextColoredRGB("{"..cmt.."}-> Игрокам 1 уровня - предупреждение через /от, при повторном заглушка")
				imgui.TextColoredRGB("{"..cmt.."}За MG на мероприятиях от администрации/в ЧМ/при разговоре с админом наказывать игроков не нужно")
				imgui.TextColoredRGB("{"..cmt.."}Всегда проверяйте еще раз допу игрока, после того как выдали наказание, на наличие закрытого MG")
				imgui.TextColoredRGB("{"..cmt.."}С момента MG должно пройти около минуты, чтобы у игрока была возможность исправить MG.")
				imgui.TextColoredRGB("{"..cmt.."}-> Не нужно выдавать заглушку за MG по /доп, если оно было ~5 минут назад")
				imgui.TextColoredRGB("{"..cmt.."}За это время могло многое произойти и от лица игрока выглядит это не особо адекватно")
				imgui.TextColoredRGB("{"..rmt.."}-> Исключения: чат банды, МАФИИ, чат дальнобойщиков")
				imgui.TextColoredRGB("{"..rmt.."}- > Не наказывать за точку/плюс/минус и т.д в чате без текста")
				imgui.TextColoredRGB("{"..cmt.."}Если пишут что-то наподобие $@$@@!##@%&%#+_#! - то уже надо наказывать")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}2) MG в командах для RP отыгровок:{"..cmt.."} (/з [id] Бред в /я)")
				imgui.TextColoredRGB("{"..cmt.."}-> Примеры: /я сказал дай skype")
				imgui.TextColoredRGB("{"..cmt.."}Всегда проверяйте еще раз допу игрока, после того как выдали наказание, на наличие закрытого MG")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}3) Caps Lock:{"..cmt.."} (/з [id] Caps Lock)")
				imgui.TextColoredRGB("{"..cmt.."}6 и более сообщения капсом в доп. инфе на момент проверки (разница между сообщениями не должна быть более 10 минут)")
				imgui.TextColoredRGB("{"..rmt.."}->Исключение: наказание не распространяется на чат мафии и банды")
				imgui.TextColoredRGB("{"..rmt.."}Важно! {"..cmt.."}Если на игрока летят многократные жалобы, что он создает помеху и в /доп вы видите,")
				imgui.TextColoredRGB("{"..cmt.."}что игрок капсит неадекватными словами/символами и тем самым злоупотребляет, то игрока можно наказать")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}4) Flood:{"..cmt.."} (/з [id] Flood)")
				imgui.TextColoredRGB("{"..cmt.."}->Например: когда игроки обходят антифлуд систему и пишут сообщения добавляя по одному символу (6+ строк это флуд)")
				imgui.TextColoredRGB("{"..cmt.."}Важно! Если проходит опрос на собеседовании, то не надо глушить тех кто опрашивает за флуд на тему опроса")
				imgui.TextColoredRGB("{"..rmt.."}->Исключение: наказание не распространяется на чат мафии и банды")
				imgui.TextColoredRGB("{"..rmt.."}Важно! {"..cmt.."}Если на игрока летят многократные жалобы, что он создает помеху и в /доп вы видите,")
				imgui.TextColoredRGB("{"..cmt.."}что игрок флудит неадекватными словами/символами и тем самым злоупотребляет, то игрока можно наказать")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}5) Оскорбление:{"..cmt.."} (/з [id] Оскорбление)")
				imgui.TextColoredRGB("{"..cmt.."}-> За разрешенные слова глушить не нужно (список во вкладке 'Вид')")
				imgui.TextColoredRGB("{"..cmt.."}Сравнение с животными, мут давать только за - собака, крыса, петух (только в случае если очевидное обращение к игроку")
				imgui.TextColoredRGB("{"..cmt.."}За 'соси' - мут не даётся, 'соси хуй' - даётся, 'ты сука' - мут не даётся, 'ты сука ебаная' - даётся")
				imgui.TextColoredRGB("{"..cmt.."}-> Старайтесь не глушить за простые оскорбления, когда очевидно, что было сказано в шутку без обид друг на друга")
				imgui.TextColoredRGB("{"..cmt.."}-> Старайтесь не глушить, когда очевидно, что речь идёт о третьем лице, которое вообще никак не увидит эти оскорбления")
				imgui.TextColoredRGB("{"..cmt.."}-> Если разрешенные слова сказаны в сторону администрации - заглушка от 10ч до 1 дня с причиной 'неуважение к адм.')")
				imgui.TextColoredRGB("{"..cmt.."}-> Наказание за злоупотребление разрешенными оскорблениями выдается, если в допе 3+ оскорбления за {FF0000}~{"..cmt.."}5 минут")
				imgui.TextColoredRGB("{"..cmt.."}-> Глушить смотря на ситуацию, а не по факту написанных слов. Они могут быть сказаны разным людям или нести не оскорбительный смысл")
				imgui.TextColoredRGB("{"..cmt.."}-> Иногда и 3+ оскорбления за ~5м может быть недостаточно. Всё решает контекст этих слов, поэтому внимательно смотрите за этим")
				imgui.TextColoredRGB("{"..rmt.."}->Исключение: наказание не распространяется на чат мафии и банды")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}6) Торговля в чате гос. фракций и работ:{"..cmt.."} (/з [id] Маркетинг)")
				imgui.TextColoredRGB("{"..rmt.."}-> Исключение: продажа доната, реклама бизнеса. Пример: !Приглашаю работяг посетить 24.7 у Мото салона в СФ")
				imgui.TextColoredRGB("{"..rmt.."}->Исключение: наказание не распространяется на чат мафии и банды")
				imgui.TextColoredRGB("{"..cmt.."}-> Примеры: '!Куплю Туризмо'; '!!*Продам дом'. Донат продавать можно")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}7) Злоупотребление знаками:{"..cmt.."} (/з [id] Злоупотребление знаками)")
				imgui.TextColoredRGB("{"..cmt.."}-> Большое количество знаков после текста")
				imgui.TextColoredRGB("{"..cmt.."}Примеры: Привет!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!; Как дела??????????????????**?::?*:::????????????")
				imgui.TextColoredRGB("{"..cmt.."}-> Большое количество повторяющихся букв так же наказуемо,")
				imgui.TextColoredRGB("{"..rmt.."}но при условии что букв действительно много (примерно как со знаками) и это как минимум в 2-х словах/сообщениях")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}8) Злоупотребление 'Кхм':{"..cmt.."} (/з [id] Злоупотребление 'Кхм')")
				imgui.TextColoredRGB("{"..cmt.."}-> Если очевидно, что игрок намеренно MG'шит и закрывает MG с помощью 'Кхм' уже много раз подряд за короткий промежуток времени")
				imgui.TextColoredRGB("{"..rmt.."}-> Наказание даётся если там было именно исправление MG, а не просто так")
				imgui.TextColoredRGB("{"..cmt.."}-> Наказывать после 3+ исправлений за короткий промеждуток времени (~10 минут)")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}9) Затрагивание/упоминание родных:{"..cmt.."} (/блок [id] 432000 Затрагивание родных) (5д)")
				imgui.TextColoredRGB("{"..cmt.."}-> Сюда относится затрагивание родных {FF0000}без оскорблений {"..cmt.."}с целью затроллить игрока")
				imgui.TextColoredRGB("{"..cmt.."}Примеры: mq, мк(по ситуации), мамке ку, еб твою мать, сын собаки")
				imgui.TextColoredRGB("{"..rmt.."}-> Если пишут что-то по типу 'сын лужи', то наказывать сразу не нужно. Только если от одного игрока подобное звучит часто")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}10) Оскорбление родных:{"..cmt.."} (/блок [id] -1 Оскорбление родных) (вечность)")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}11) Оскорбление проекта:{"..cmt.."} (/блок [id] -1 Оскорбление проекта) (вечность)")
				imgui.TextColoredRGB("{"..rmt.."}-> Смотрите по ситуации. Банить за всё не обязательно")
				imgui.TextColoredRGB("{"..cmt.."}Если там написали 'тупой сервер', достаточно будет мута по автозаглушке")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}12) Розжиг:{"..cmt.."} (/з [id] 172800 Розжиг межнациональной розни) (2д)")
				imgui.TextColoredRGB("{"..rmt.."}Примеры: чурка; хач; хохол и т.п")
				imgui.TextColoredRGB("{"..cmt.."}Негр; Нигер и т.п. - не наказуемо по данному нормативу")
				imgui.TextColoredRGB("{"..cmt.."}-> Опять же смотрите на ситуацию и с какой целью написано было")
				imgui.TextColoredRGB("{"..cmt.."}Мы наказываем за розжиг межнациональной розни, а не просто по приколу ведь")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}Розжиг в грубой форме:{"..cmt.."} (/блок [id] -1 Розжиг межнациональной розни) (вечность)")
				imgui.TextColoredRGB("{"..rmt.."}Пример: хачи ебаные всех вас сжечь")
				imgui.TextColoredRGB("{"..cmt.."}Негр; Нигер и т.п. - не наказуемо по данному нормативу")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}13) Оскорбление администрации:{"..cmt.."} (/з [id] 432000 Оскорбление администрации) (5д)")
				imgui.TextColoredRGB("{"..rmt.."}-> Огромная просьба, будьте чуть умнее и осознавайте такой момент,")
				imgui.TextColoredRGB("{"..cmt.."}что игрок может гореть по разным причинам и в том числе обоснованным")
				imgui.TextColoredRGB("{"..cmt.."}Если вы его посадили неверно, он сгорел и оскнул вас как-то не особо значительно, то не нужно бежать и выдавать заглушки ему")
				imgui.Spacing()
				imgui.TextColoredRGB("{"..rmt.."}-> Наказаний за неуважение к админу не существует!!")
				imgui.TextColoredRGB("{"..cmt.."}Есть только меньший срок в ситуации когда админ хочет наказать не на 5 дней, а меньше и указывается причина как неуважение к адм")
				imgui.Spacing()
				imgui.TextColoredRGB("{"..cmt.."}-> 800+ админы могут снять наказание без одобрено админу, если решат что оно не обоснованно дано")
				imgui.TextColoredRGB("{"..cmt.."}-> НАКАЗЫВАТЬ ЗА ВК ЗАПРЕЩЕНО и можно это делать только когда игрок максимальный неадекват ну или переходит на оск. родных к примеру")
				imgui.TextColoredRGB("{"..cmt.."}Так же ЗАПРЕЩЕНО указывать в причине наказаний пометку [VK]")
				imgui.TextColoredRGB("{"..cmt.."}Люди которые не в теме, думают что даже если написать что админ дурак, то сразу забанят и поэтому некоторые ещё и боятся вк своё привязывать")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}Оскорбление администрации с розжигом/затрагиванием или оском родных:{"..cmt.."} (/блок [id] -1 Оскорбление администрации) (вечность)")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}14) Реклама стороннего ресурса:{"..cmt.."} (/блок [id] -1 Реклама) (вечность)")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}15) Некорректная смена ника:{"..cmt.."} (/зк [id] 3600 Некорректная смена ника) (1ч)")
				imgui.TextColoredRGB("{"..cmt.."}-> Примеры: Aztecas_Sotka; Сладкое_Яблоко; Болькасф_Топ")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}16) Скрытая реклама или реклама какого-нибудь инстаграмм:{"..cmt.."} (/з [id] 36000 Скрытая реклама) (10ч)")
				imgui.TextColoredRGB("{"..cmt.."}-> Запрещено звать игроков на любой сторонний DM сервер. Если игрока зовут на RP сервер, то наказываем исходя из пункта 14")
				imgui.TextColoredRGB("{"..cmt.."}-> Примеры: го монсер, жду тебя лока [номер] и всё что связано с любым DM сервером")
				imgui.TextColoredRGB("{"..cmt.."}-> Если человек пиарит что-то, но это не связано с рекламой серверов и других запрещённых вещей, то действуйте по данному нормативу")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}17) Шантаж:{"..cmt.."} (/з [id] 10800 Шантаж) (3ч)")
				imgui.TextColoredRGB("{"..cmt.."}-> С целью выгоды угрожать любым наказанием от администратора или шантажировать удалением жалобы")
				imgui.TextColoredRGB("{"..cmt.."}Пример: плати мне 50к и я не буду писать жалобу, дай 5к или тебя в кпз посадят, дай мне машину или тебя забанят и т.д")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}18) Провокация на продажу гос. имущества:{"..cmt.."} (/з [id] 7200 Провокация на продажу гос. имущества) (2ч)")
				imgui.TextColoredRGB("{"..cmt.."}-> Примеры: 'Продай стол за 5к'; 'Давай я тебе 10к, а ты мне трамвай отдашь?'")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}19) Нарушение правил гос. новостей:{"..cmt.."} (/зк [id] 1800 /gnews) (30м)")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}20) Дезинформация:{"..cmt.."} (/з [id] 10800 Дезинформация) (3ч)")
				imgui.TextColoredRGB("{"..cmt.."}-> Намеренный обман игрока по поводу функционала сервера или игры в целом с целью троллинга/выгоды. Например: Напиши /q и получишь 50к'")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}21) Бред в командах после смерти:{"..cmt.."} (/з [id] Бред в командах после смерти)")
				imgui.TextColoredRGB("{"..cmt.."}-> Наказание распространяется на те случаи,")
				imgui.TextColoredRGB("{"..cmt.."}когда игрок лежа на анимации после своей смерти использует любую отыгровку в /я /де /пр /фд, еще до появления в больнице")
				imgui.TextColoredRGB("{"..cmt.."}-> Например: /де 0, /пр унижены, /де бичи, /я вин, /де жб и т.д")
				imgui.TextColoredRGB("{"..rmt.."}-> За отыгровки по типу - '/фд хана тебе*теряя сознани'е наказывать не нужно")
				imgui.TextColoredRGB("{"..rmt.."}Исключение: команда /даун")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}22) Выдача себя за администратора:{"..cmt.."} (/блок [id] 432000 Выдача себя за администратора) (5д)")
				imgui.TextColoredRGB("{"..cmt.."}-> Примеры: 'Если не сделаешь ..., то я тебя забаню'; 'Дай мне денег, а то я тебя посажу' и т.п.")
				imgui.TextColoredRGB("")
				imgui.PopFont()
				imgui.PushFont(fontsize20)
				imgui.TextColoredRGB("{"..cmt.."}Правила репорта:")
				imgui.PopFont()
				imgui.PushFont(fontsize15)
				imgui.TextColoredRGB("{"..smt.."}1) Оффтоп:{"..cmt.."} (/зр [id] Offtop в репорт)")
				imgui.TextColoredRGB("{"..cmt.."}-> Наказание распространяется на любые вопросы, которые не относятся к игровому процессу")
				imgui.TextColoredRGB("{"..rmt.."}Сначала делаете игроку предупреждение через /от, если игрок не понял и продолжил оффтопить, то закрываете репорт")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}2) Оффтоп:{"..cmt.."} (/зк [id] 1800 Offtop в репорт) (30м)")
				imgui.TextColoredRGB("{"..cmt.."}Когда пишут совсем полный бред, например: 'как подрочить?', в таком случае сразу выдаете зк на 30 минут. Сюда же входит 'троллинг' администрации")
				imgui.TextColoredRGB("{"..cmt.."}Пример:")
				imgui.TextColoredRGB("{"..cmt.."}Вопрос от игрока - Как дела у лучших админов?")
				imgui.TextColoredRGB("{"..cmt.."}Ответ админа - Хорошо")
				imgui.TextColoredRGB("{"..cmt.."}Вопрос игрока - А вы откуда знаете?")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}3) Флуд/Мат:{"..cmt.."} (/зр [id] Флуд/Мат в репорт)")
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("{"..smt.."}4) Обсуждение действий администрации:{"..cmt.."} (/з [id] 18000 Обсуждение действий администрации) (5ч)")
				imgui.TextColoredRGB("{"..cmt.."}-> Примеры: 'Лучше бы за читерами следили, а не меня наказывали', 'Другим даете 2ч, а мне целых 5ч'.")
				imgui.PopFont()
			imgui.EndChild()
		end
		if active_window == 13 then
			imgui.BeginChild(u8"Информация", imgui.ImVec2(992, 550), true)
				imgui.PushFont(fontsize20)
				imgui.TextColoredRGB("{"..smt.."}Аэрография")
				imgui.PopFont()
				imgui.PushFont(fontsize15)
				imgui.TextColoredRGB("{"..cmt.."}Y - Навигатор - Автомастерские - Wheel Arch Angels")
				imgui.TextColoredRGB("{"..cmt.."}- Flash (5 уровень - 95.000$)")
				imgui.TextColoredRGB("{"..cmt.."}- Stratum (6 уровень - 150.000$)")
				imgui.TextColoredRGB("{"..cmt.."}- Uranus (7 уровень - 190.000$)")
				imgui.TextColoredRGB("{"..cmt.."}- Elegy (13 уровень - 500.000$)")
				imgui.TextColoredRGB("{"..cmt.."}- Sultan (13 уровень - 600.000$)")
				imgui.Spacing()
				imgui.TextColoredRGB("{"..cmt.."}Y - Навигатор - Автомастерские - Loco Low Co")
				imgui.TextColoredRGB("{"..cmt.."}- Blade (5 уровень - 175.000$)")
				imgui.TextColoredRGB("{"..cmt.."}- Broadway (5 уровень - 75.000$)")
				imgui.TextColoredRGB("{"..cmt.."}- Tornado (5 уровень - 85.000$)")
				imgui.TextColoredRGB("{"..cmt.."}- Remington (7 уровень - 170.000$)")
				imgui.TextColoredRGB("{"..cmt.."}- Slamvan (7 уровень - 200.000$)")
				imgui.TextColoredRGB("{"..cmt.."}- Savanna (10 уровень - 200.000$)")
				imgui.TextColoredRGB("")
				imgui.PopFont()
				
				imgui.PushFont(fontsize20)
				imgui.TextColoredRGB("{"..smt.."}Сейфы домов")
				imgui.PopFont()
				imgui.PushFont(fontsize15)
				imgui.TextColoredRGB("{"..smt.."}Общая информация:")
				imgui.TextColoredRGB("{"..cmt.."}5.000.000$ - Максимум денег")
				imgui.TextColoredRGB("{"..cmt.."}5 - Количество снайперских винтовок в сейфах")
				imgui.TextColoredRGB("{"..cmt.."}10 - Количество остального оружия в сейфах")
				imgui.TextColoredRGB("{"..cmt.."}1 - Количество скинов")
				imgui.Spacing()
				
				imgui.Columns(7, "Colums", true)

				imgui.Separator()
				imgui.TextColoredRGB("{"..cmt.."}1 уровень")
				imgui.NextColumn()
				imgui.TextColoredRGB("{"..cmt.."}2 уровень")
				imgui.NextColumn()
				imgui.TextColoredRGB("{"..cmt.."}3 уровень")
				imgui.NextColumn()
				imgui.TextColoredRGB("{"..cmt.."}4 уровень")
				imgui.NextColumn()
				imgui.TextColoredRGB("{"..cmt.."}5 уровень")
				imgui.NextColumn()
				imgui.TextColoredRGB("{"..cmt.."}6 уровень")
				imgui.NextColumn()
				imgui.TextColoredRGB("{"..cmt.."}7 уровень")
				imgui.Separator()
				imgui.NextColumn()
				
				imgui.TextColoredRGB("{"..cmt.."}Металл - 100")
				imgui.TextColoredRGB("{"..cmt.."}Дерево - 100")
				imgui.TextColoredRGB("{"..cmt.."}Препараты - 100")
				imgui.TextColoredRGB("{"..cmt.."}Патроны - 1000")
				imgui.TextColoredRGB("{"..cmt.."}Объекты у дома - 1")
				imgui.NextColumn()
				imgui.TextColoredRGB("{"..cmt.."}Металл - 400")
				imgui.TextColoredRGB("{"..cmt.."}Дерево - 400")
				imgui.TextColoredRGB("{"..cmt.."}Препараты - 400")
				imgui.TextColoredRGB("{"..cmt.."}Патроны - 4000")
				imgui.TextColoredRGB("{"..cmt.."}Объекты у дома - 1")
				imgui.NextColumn()
				imgui.TextColoredRGB("{"..cmt.."}Металл - 600")
				imgui.TextColoredRGB("{"..cmt.."}Дерево - 600")
				imgui.TextColoredRGB("{"..cmt.."}Препараты - 600")
				imgui.TextColoredRGB("{"..cmt.."}Патроны - 6000")
				imgui.TextColoredRGB("{"..cmt.."}Объекты у дома - 2")
				imgui.NextColumn()
				imgui.TextColoredRGB("{"..cmt.."}Металл - 800")
				imgui.TextColoredRGB("{"..cmt.."}Дерево - 800")
				imgui.TextColoredRGB("{"..cmt.."}Препараты - 800")
				imgui.TextColoredRGB("{"..cmt.."}Патроны - 8000")
				imgui.TextColoredRGB("{"..cmt.."}Объекты у дома - 3")
				imgui.NextColumn()
				imgui.TextColoredRGB("{"..cmt.."}Металл - 1000")
				imgui.TextColoredRGB("{"..cmt.."}Дерево - 1000")
				imgui.TextColoredRGB("{"..cmt.."}Препараты - 1000")
				imgui.TextColoredRGB("{"..cmt.."}Патроны - 10000")
				imgui.TextColoredRGB("{"..cmt.."}Объекты у дома - 5")
				imgui.NextColumn()
				imgui.TextColoredRGB("{"..cmt.."}Металл - 1500")
				imgui.TextColoredRGB("{"..cmt.."}Дерево - 1500")
				imgui.TextColoredRGB("{"..cmt.."}Препараты - 1500")
				imgui.TextColoredRGB("{"..cmt.."}Патроны - 15000")
				imgui.TextColoredRGB("{"..cmt.."}Объекты у дома - 10")
				imgui.NextColumn()
				imgui.TextColoredRGB("{"..cmt.."}Металл - 2000")
				imgui.TextColoredRGB("{"..cmt.."}Дерево - 2000")
				imgui.TextColoredRGB("{"..cmt.."}Препараты - 2000")
				imgui.TextColoredRGB("{"..cmt.."}Патроны - 20000")
				imgui.TextColoredRGB("{"..cmt.."}Объекты у дома - 20")
				imgui.Columns(1)
				imgui.Separator()
				imgui.TextColoredRGB("")
				imgui.PopFont()
				
				imgui.PushFont(fontsize20)
				imgui.TextColoredRGB("{"..smt.."}Скиллы")
				imgui.PopFont()
				imgui.PushFont(fontsize15)
				imgui.Columns(6, "Colums", true)
				imgui.Separator()
				imgui.TextColoredRGB("{"..cmt.."}Desert Eagle")
				imgui.NextColumn()
				imgui.TextColoredRGB("{"..cmt.."}AK-47")
				imgui.NextColumn()
				imgui.TextColoredRGB("{"..cmt.."}M4A1")
				imgui.NextColumn()
				imgui.TextColoredRGB("{"..cmt.."}MP5")
				imgui.NextColumn()
				imgui.TextColoredRGB("{"..cmt.."}Sdpistols")
				imgui.NextColumn()
				imgui.TextColoredRGB("{"..cmt.."}Shotgun")
				imgui.Separator()

				imgui.NextColumn()
				imgui.TextColoredRGB("{"..cmt.."}2.400 патронов")
				imgui.NextColumn()
				imgui.TextColoredRGB("{"..cmt.."}10.000 патронов")
				imgui.NextColumn()
				imgui.TextColoredRGB("{"..cmt.."}10.000 патронов")
				imgui.NextColumn()
				imgui.TextColoredRGB("{"..cmt.."}7.500 патронов")
				imgui.NextColumn()
				imgui.TextColoredRGB("{"..cmt.."}3.000 патронов")
				imgui.NextColumn()
				imgui.TextColoredRGB("{"..cmt.."}1.500 патронов")
				imgui.Columns(1)
				imgui.Separator()
				imgui.TextColoredRGB("")
				imgui.PopFont()
				
				imgui.PushFont(fontsize20)
				imgui.TextColoredRGB("{"..smt.."}Работы")
				imgui.PopFont()
				imgui.PushFont(fontsize15)
				imgui.TextColoredRGB("{"..smt.."}1 уровень:")
				imgui.TextColoredRGB("{"..cmt.."}Продавец еды - ЗП от $10 до $200 за каждую продажу")
				imgui.Spacing()
				imgui.TextColoredRGB("{"..smt.."}2 уровень:")
				imgui.TextColoredRGB("{"..cmt.."}Автобусы")
				imgui.Columns(3, "Colums", true)
				-- 1
				imgui.Separator()
				imgui.TextColoredRGB("{"..cmt.."}Автовокзал ЛС - Автошкола")
				imgui.NextColumn()
				imgui.TextColoredRGB("{"..cmt.."}ЗП - $2575")
				imgui.NextColumn()
				imgui.TextColoredRGB("{"..cmt.."}Время в пути ~9м 50с")
				imgui.Separator()
				imgui.NextColumn()
				
				-- 1.1
				imgui.TextColoredRGB("{"..cmt.."}Автовокзал ЛС - Грузчики")
				imgui.NextColumn()
				imgui.TextColoredRGB("{"..cmt.."}ЗП - $1550")
				imgui.NextColumn()
				imgui.TextColoredRGB("{"..cmt.."}Время в пути ~5м 40с")
				imgui.Separator()
				imgui.NextColumn()
				
				-- 1.2
				imgui.TextColoredRGB("{"..cmt.."}Автовокзал ЛС - Завод")
				imgui.NextColumn()
				imgui.TextColoredRGB("{"..cmt.."}ЗП - $2400")
				imgui.NextColumn()
				imgui.TextColoredRGB("{"..cmt.."}Время в пути ~9м 30с")
				imgui.Separator()
				imgui.NextColumn()
				
				-- 2
				imgui.TextColoredRGB("{"..cmt.."}Автовокзал ЛС - Шахта")
				imgui.NextColumn()
				imgui.TextColoredRGB("{"..cmt.."}ЗП - $2375")
				imgui.NextColumn()
				imgui.TextColoredRGB("{"..cmt.."}Время в пути ~8м 20с")
				imgui.Separator()
				imgui.NextColumn()
				
				-- 3
				imgui.TextColoredRGB("{"..cmt.."}Междугородний ЛС - СФ")
				imgui.NextColumn()
				imgui.TextColoredRGB("{"..cmt.."}ЗП - $2775")
				imgui.NextColumn()
				imgui.TextColoredRGB("{"..cmt.."}Время в пути ~10м 40с")
				imgui.Separator()
				imgui.NextColumn()
				
				-- 4
				imgui.TextColoredRGB("{"..cmt.."}Междугородний ЛС - ЛВ")
				imgui.NextColumn()
				imgui.TextColoredRGB("{"..cmt.."}ЗП - $2425")
				imgui.NextColumn()
				imgui.TextColoredRGB("{"..cmt.."}Время в пути ~8м 30с")
				imgui.Separator()
				imgui.NextColumn()
				
				-- 5
				imgui.TextColoredRGB("{"..cmt.."}Внутригородской СФ")
				imgui.NextColumn()
				imgui.TextColoredRGB("{"..cmt.."}ЗП - $1700")
				imgui.NextColumn()
				imgui.TextColoredRGB("{"..cmt.."}Время в пути ~6м 30с")
				imgui.Separator()
				imgui.NextColumn()
				
				-- 6
				imgui.TextColoredRGB("{"..cmt.."}Пригород СФ")
				imgui.NextColumn()
				imgui.TextColoredRGB("{"..cmt.."}ЗП - $1950")
				imgui.NextColumn()
				imgui.TextColoredRGB("{"..cmt.."}Время в пути ~7м 10с")
				imgui.Separator()
				imgui.NextColumn()
				
				-- 7
				imgui.TextColoredRGB("{"..cmt.."}Междугородний СФ - ЛС")
				imgui.NextColumn()
				imgui.TextColoredRGB("{"..cmt.."}ЗП - $2600")
				imgui.NextColumn()
				imgui.TextColoredRGB("{"..cmt.."}Время в пути ~9м40с")
				imgui.Separator()
				imgui.NextColumn()
				
				-- 8
				imgui.TextColoredRGB("{"..cmt.."}Междугородний СФ - ЛВ")
				imgui.NextColumn()
				imgui.TextColoredRGB("{"..cmt.."}ЗП - $2950")
				imgui.NextColumn()
				imgui.TextColoredRGB("{"..cmt.."}Время в пути ~10м 40с")
				imgui.Separator()
				imgui.NextColumn()
				
				-- 9
				imgui.TextColoredRGB("{"..cmt.."}Внутригородской ЛВ")
				imgui.NextColumn()
				imgui.TextColoredRGB("{"..cmt.."}ЗП - $2325")
				imgui.NextColumn()
				imgui.TextColoredRGB("{"..cmt.."}Время в пути ~9м")
				imgui.Separator()
				imgui.NextColumn()
				
				-- 10
				imgui.TextColoredRGB("{"..cmt.."}Пригород ЛВ")
				imgui.NextColumn()
				imgui.TextColoredRGB("{"..cmt.."}ЗП - $3600")
				imgui.NextColumn()
				imgui.TextColoredRGB("{"..cmt.."}Время в пути ~14м 40с")
				imgui.Separator()
				imgui.NextColumn()
				
				-- 11
				imgui.TextColoredRGB("{"..cmt.."}Междугородний ЛВ")
				imgui.NextColumn()
				imgui.TextColoredRGB("{"..cmt.."}ЗП - $2725")
				imgui.NextColumn()
				imgui.TextColoredRGB("{"..cmt.."}Время в пути ~9М 50С")
				imgui.Separator()
				imgui.NextColumn()
				
				--6
				imgui.TextColoredRGB("{"..cmt.."}Междугородний ЛВ - СФ")
				imgui.NextColumn()
				imgui.TextColoredRGB("{"..cmt.."}ЗП - $3100")
				imgui.NextColumn()
				imgui.TextColoredRGB("{"..cmt.."}Время в пути ~10М 40с")
				imgui.Columns(1)
				imgui.Separator()
				imgui.TextColoredRGB("")
				
				imgui.TextColoredRGB("{"..smt.."}3 уровень:")
				imgui.TextColoredRGB("{"..cmt.."}Таксист - ЗП $2 за каждую секунду езды с пассажиром")
				imgui.Spacing()
				imgui.TextColoredRGB("{"..smt.."}4 уровень:")
				imgui.TextColoredRGB("{"..cmt.."}Таксист - ЗП $2 за каждую секунду езды с пассажиром")
				imgui.TextColoredRGB("{"..cmt.."}Водитель поезда - ЗП за 1 круг - $8250 | Время в пути ~19м")
				imgui.TextColoredRGB("{"..cmt.."}Водитель трамвая - ЗП за 1 круг - $2640 | Время в пути ~6м 20с")
				imgui.Spacing()
				imgui.TextColoredRGB("{"..smt.."}5 уровень:")
				imgui.TextColoredRGB("{"..cmt.."}Автомеханик")
				imgui.TextColoredRGB("{"..cmt.."}- Починить / Заправить транспорт - от $100 до $200")
				imgui.TextColoredRGB("{"..cmt.."}- Взять транспорт на буксир - от $10 до $100")
				imgui.TextColoredRGB("{"..cmt.."}- Заправить нитро - от $10 до $100")
				imgui.Spacing()
				imgui.TextColoredRGB("{"..smt.."}6 уровень:")
				imgui.TextColoredRGB("{"..cmt.."}Крупье в казино - ЗП - $3000 (максимум) за 10м работы (если игроки за столом)")
				imgui.Spacing()
				imgui.TextColoredRGB("{"..smt.."}7 уровень:")
				imgui.TextColoredRGB("{"..cmt.."}Дальнобойщик")
				
				imgui.Columns(4, "Colums", true)
				-- 1
				imgui.Separator()
				imgui.TextColoredRGB("{"..cmt.."}Уровень")
				imgui.NextColumn()
				imgui.TextColoredRGB("{"..cmt.."}Транспорт")
				imgui.NextColumn()
				imgui.TextColoredRGB("{"..cmt.."}Зарплата")
				imgui.NextColumn()
				imgui.TextColoredRGB("{"..cmt.."}Рейсы до след. уровня")
				imgui.Separator()
				imgui.NextColumn()
				
				imgui.TextColoredRGB("{"..cmt.."}1")
				imgui.NextColumn()
				imgui.TextColoredRGB("{"..cmt.."}Cement Truck")
				imgui.NextColumn()
				imgui.TextColoredRGB("{"..cmt.."}$4250")
				imgui.NextColumn()
				imgui.TextColoredRGB("{"..cmt.."}100")
				imgui.Separator()
				imgui.NextColumn()
				
				imgui.TextColoredRGB("{"..cmt.."}2")
				imgui.NextColumn()
				imgui.TextColoredRGB("{"..cmt.."}Tanker")
				imgui.NextColumn()
				imgui.TextColoredRGB("{"..cmt.."}$5000")
				imgui.NextColumn()
				imgui.TextColoredRGB("{"..cmt.."}200")
				imgui.Separator()
				imgui.NextColumn()
				
				imgui.TextColoredRGB("{"..cmt.."}3")
				imgui.NextColumn()
				imgui.TextColoredRGB("{"..cmt.."}Linerunner")
				imgui.NextColumn()
				imgui.TextColoredRGB("{"..cmt.."}$6000")
				imgui.NextColumn()
				imgui.TextColoredRGB("{"..cmt.."}300")
				imgui.Separator()
				imgui.NextColumn()
				
				imgui.TextColoredRGB("{"..cmt.."}4")
				imgui.NextColumn()
				imgui.TextColoredRGB("{"..cmt.."}Roadtrain")
				imgui.NextColumn()
				imgui.TextColoredRGB("{"..cmt.."}$7000")
				imgui.NextColumn()
				imgui.TextColoredRGB("{"..cmt.."}300")
				imgui.Separator()
				imgui.NextColumn()
				
				imgui.TextColoredRGB("{"..cmt.."}5 (последний)")
				imgui.NextColumn()
				imgui.TextColoredRGB("{"..cmt.."}Roadtrain (топливо)")
				imgui.NextColumn()
				imgui.TextColoredRGB("{"..cmt.."}$8000")
				imgui.NextColumn()
				imgui.TextColoredRGB("{"..cmt.."}бесконечно")
				imgui.Columns(1)
				imgui.PopFont()
			imgui.EndChild()
		end
		imgui.End()
	end
	
	
	
	if osk_window_state.v then
		local sw, sh = getScreenResolution()
		imgui.SetNextWindowPos(imgui.ImVec2(sw / 2, sh / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(-2.5, -0.5))
		imgui.SetNextWindowSize(imgui.ImVec2(265, 315), imgui.Cond.FirstUseEver)
		imgui.Begin(u8 "Разрешенные оскорбления", osk_window_state, imgui.WindowFlags.AlwaysAutoResize)
		imgui.PushFont(fontsize15)
		imgui.TextColoredRGB("{"..cmt.."}бич, бомж")
		imgui.TextColoredRGB("{"..cmt.."}пошел нах, придурок, помойка")
		imgui.TextColoredRGB("{"..cmt.."}падаль, падло")
		imgui.TextColoredRGB("{"..cmt.."}сыкло, скотина, сволочь, соска, сука")
		imgui.TextColoredRGB("{"..cmt.."}тупой, тормоз, транс")
		imgui.TextColoredRGB("{"..cmt.."}дурак, додик, дегенерат, дно, дебил")
		imgui.TextColoredRGB("{"..cmt.."}ноль, нуб, нытик")
		imgui.TextColoredRGB("{"..cmt.."}мусор, мудак")
		imgui.TextColoredRGB("{"..cmt.."}ушлепок, утырок, убогий, убожество")
		imgui.TextColoredRGB("{"..cmt.."}чёрт, чушка, чума, чувырло")
		imgui.TextColoredRGB("{"..cmt.."}гниль, гавно, гей, гомосек")
		imgui.TextColoredRGB("{"..cmt.."}овощ, опущенный, олух")
		imgui.TextColoredRGB("{"..cmt.."}идиот, иди нахуй")
		imgui.TextColoredRGB("{"..cmt.."}школьник, лох, ебало закрой")
		imgui.TextColoredRGB("{"..smt.."}Наказание за злоупотр. не более 5 мин")
		imgui.PopFont()
		imgui.End()
	else
		checkbox_osk.v = false
	end
	if sec_window_state.v then
		local sw, sh = getScreenResolution()
		imgui.SetNextWindowPos(imgui.ImVec2(sw / 2, sh / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(-2.5, -0.2))
		imgui.SetNextWindowSize(imgui.ImVec2(265, 510), imgui.Cond.FirstUseEver)
		imgui.Begin(u8 "Нормативы чата", sec_window_state, imgui.WindowFlags.AlwaysAutoResize)
		imgui.PushFont(fontsize15)
		imgui.TextColoredRGB("{"..smt.."}MG: {"..cmt.."}1 LVL - пред., повторно - мут")
		imgui.TextColoredRGB("{"..cmt.."}Не нужно если было ~5 минут назад")
		imgui.TextColoredRGB("{"..cmt.."}/я сказал дай skype (Бред в /я)")
		imgui.TextColoredRGB("")
		imgui.TextColoredRGB("{"..smt.."}Caps: {"..cmt.."}6+ СМС (разница не более 10 мин)")
		imgui.TextColoredRGB("{"..cmt.."}Исключение: чат мафии и банды")
		imgui.TextColoredRGB("{"..cmt.."}При многокр. репортаж можно наказать")
		imgui.TextColoredRGB("")
		imgui.TextColoredRGB("{"..smt.."}Flood: {"..cmt.."}6+ строк за 5 мин")
		imgui.TextColoredRGB("{"..cmt.."}Исключение: чат мафии и банды")
		imgui.TextColoredRGB("{"..cmt.."}При многокр. репортаж можно наказать")
		imgui.TextColoredRGB("")
		imgui.TextColoredRGB("{"..smt.."}Маркетинг: {"..cmt.."}гос. фраки и дальнобои")
		imgui.TextColoredRGB("{"..cmt.."}Исключение: чат банды, мафии и донат")
		imgui.TextColoredRGB("{"..cmt.."}!Куплю Туризмо, !!*Продам дом")
		imgui.TextColoredRGB("")
		imgui.TextColoredRGB("{"..smt.."}Злоупотр. знаками: {"..cmt.."}Около 10+")
		imgui.TextColoredRGB("{"..cmt.."}Буквы тоже наказуемы, но в 2 словах")
		imgui.TextColoredRGB("")
		imgui.TextColoredRGB("{"..smt.."}Злоупотр. кхм: {"..cmt.."}Если спецом мгшит")
		imgui.TextColoredRGB("")
		imgui.TextColoredRGB("{"..smt.."}Бред в командах после смерти:")
		imgui.TextColoredRGB("{"..cmt.."}/де 0, /пр унижены, /де бичи, /я вин")
		imgui.TextColoredRGB("{"..cmt.."}Исключение: команда /даун")
		imgui.TextColoredRGB("{"..cmt.."}/фд хана тебе*теряя сознание")
		imgui.PopFont()
		imgui.End()
	else
		checkbox_sec.v = false
	end
	
	if time_window_state.v then
		local sw, sh = getScreenResolution()
		imgui.SetNextWindowPos(imgui.ImVec2(sw / 2, sh / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(-1.7, -3.2))
		imgui.SetNextWindowSize(imgui.ImVec2(200, 100), imgui.Cond.FirstUseEver)
		imgui.Begin(u8 "Конверт минут в секунды", time_window_state, imgui.WindowFlags.AlwaysAutoResize)
		--imgui.InputText(u8 "mins", main_buffer)
		imgui.NewInputText('##SearchBar', main_buffer, 300, u8'Введите кол-во минут', 1)
		if imgui.Button(u8 "Перевод") then
			if tonumber(main_buffer.v) then
				local numResult = main_buffer.v * 60
				result = string.format('%s секунд', tostring(numResult))
				setClipboardText(tostring(numResult))
				if bNotf then
					notf.addNotification("Скопировано в буфер!", 4, HLcfg.config.theme)
				end
			else
				if bNotf then
					notf.addNotification("Введите кол-во минут!", 4, HLcfg.config.theme)
				end
			end
        end
		imgui.SameLine()
		if result then imgui.Text(u8(result)) end
		imgui.End()
	else
		checkbox_time.v = false
    end
	
	if swatch_window_state.v then
		local sw, sh = getScreenResolution()
		imgui.SetNextWindowPos(imgui.ImVec2(sw / 2, sh / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(-2, -0.5))
		imgui.SetNextWindowSize(imgui.ImVec2(200, 315), imgui.Cond.FirstUseEver)
		imgui.Begin(u8 "Секундомер", swatch_window_state, imgui.WindowFlags.NoResize)
		--imgui.Begin(u8 "ссщцбхощуу", swatch_window_state, imgui.WindowFlags.NoResize)
		
		if imgui.Button(u8"Старт") then
			timer.bool = true
			timer.start_time = os.time()
		end
		
		imgui.SameLine()
		
		if imgui.Button(u8"Стоп") then
			if timer.bool then
				timeLog[#timeLog+1] = os.time() - timer.start_time
				--timer.bool = false
				timer.start_time = os.time()
			end
		end
		
		imgui.SameLine()
		
		if imgui.Button(u8"Сброс") then
			timer.bool = false
			timer.time = ''
			timeLog = {}
		end
		
		imgui.SameLine()
		
		if timer.bool then
			timer.time = os.time() - timer.start_time
			imgui.Text(timer.time .. ' sec')
		end
		
		for i,v in ipairs(timeLog) do
			imgui.Text(u8(i..". "..v))
		end
		
		imgui.End()
	else
		checkbox_swatch.v = false
    end
	
	if su_window_state.v then
		local sw, sh = getScreenResolution()
		imgui.SetNextWindowPos(imgui.ImVec2(sw / 2, sh / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(-0.5, -0.5))
		imgui.SetNextWindowSize(imgui.ImVec2(200, 315), imgui.Cond.FirstUseEver)
		imgui.Begin(u8 "Розыск", su_window_state, imgui.WindowFlags.NoResize)
		
		imgui.NewInputText('##SuBar', su_buffer, 300, u8'ID', 1)
		if imgui.Button(u8"Выдать") then
			if su_buffer.v ~= nil then
				local id = tostring(su_buffer.v)
				dl.SendChat("/su "..id.." 2.2 У.К")
				dl.SendChat("/su "..id.." 2.2 У.К")
				dl.SendChat("/su "..id.." 2.2 У.К")
				dl.SendChat("/su "..id.." 2.2 У.К")
				dl.SendChat("/su "..id.." 2.2 У.К")
				dl.SendChat("/su "..id.." 2.2 У.К")
			end
		end
		
		imgui.SameLine()
		
		if imgui.Button(u8"Наручники") then
			if su_buffer.v ~= nil then
				local id = tostring(su_buffer.v)
				for i = 1, 15 do
					dl.SendChat("/cuff "..id)
				end
			end
		end
		
		imgui.End()
    end
	
	if vehs_window_state.v then
		local sw, sh = getScreenResolution()
		imgui.SetNextWindowPos(imgui.ImVec2(sw / 2, sh / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.52, 1.7))
		imgui.SetNextWindowSize(imgui.ImVec2(1000, 300), imgui.Cond.FirstUseEver)
		imgui.Begin(u8 "Меню транспорта", vehs_window_state, imgui.WindowFlags.NoResize + imgui.WindowFlags.MenuBar)
		if imgui.BeginMenuBar() then
			if imgui.MenuItem(u8'Спортивные') then active_veh = 1 end
			if imgui.MenuItem(u8'Внедорожники') then active_veh = 2 end
			if imgui.MenuItem(u8'Седаны') then active_veh = 3 end
			if imgui.MenuItem(u8'Классика') then active_veh = 4 end
			if imgui.MenuItem(u8'Служебные') then active_veh = 5 end
			if imgui.MenuItem(u8'Мотоциклы') then active_veh = 6 end
			if imgui.MenuItem(u8'Велики') then active_veh = 7 end
			if imgui.MenuItem(u8'Воздушный') then active_veh = 8 end
			if imgui.MenuItem(u8'Лодки') then active_veh = 9 end
			if imgui.MenuItem(u8'Обслуживание') then active_veh = 10 end
			if imgui.MenuItem(u8'Грузовики') then active_veh = 11 end
		end
        imgui.EndMenuBar()
		if active_veh == 1 then
			imgui.BeginChild(u8"Спортивные", imgui.ImVec2(992, 245), true)
				if imgui.Button("Infernus") then dl.SendChat("/машину 411") end
				imgui.SameLine()
				if imgui.Button("Buffalo") then dl.SendChat("/машину 402") end
				imgui.SameLine()
				if imgui.Button("Cheetah") then dl.SendChat("/машину 415") end
				imgui.SameLine()
				if imgui.Button("Banshee") then dl.SendChat("/машину 429") end
				imgui.SameLine()
				if imgui.Button("Turismo") then dl.SendChat("/машину 451") end
				imgui.SameLine()
				if imgui.Button("ZR-350") then dl.SendChat("/машину 477") end
				imgui.SameLine()
				if imgui.Button("Hotring Racer A") then dl.SendChat("/машину 502") end
				imgui.SameLine()
				if imgui.Button("Hotring Racer B") then dl.SendChat("/машину 503") end
				imgui.SameLine()
				if imgui.Button("Super GT") then dl.SendChat("/машину 506") end
				imgui.SameLine()
				if imgui.Button("Jester") then dl.SendChat("/машину 559") end
			imgui.EndChild()
		end
		if active_veh == 2 then
			imgui.BeginChild(u8"Спортивные", imgui.ImVec2(992, 245), true)
				if imgui.Button("Landstalker") then dl.SendChat("/машину 400") end
				imgui.SameLine()
				if imgui.Button("Bobcat") then dl.SendChat("/машину 422") end
				imgui.SameLine()
				if imgui.Button("BF Injection") then dl.SendChat("/машину 424") end
				imgui.SameLine()
				if imgui.Button("Monster") then dl.SendChat("/машину 444") end
				imgui.SameLine()
				if imgui.Button("Monster A") then dl.SendChat("/машину 556") end
				imgui.SameLine()
				if imgui.Button("Monster B") then dl.SendChat("/машину 557") end
				imgui.SameLine()
				if imgui.Button("Walton") then dl.SendChat("/машину 478") end
				imgui.SameLine()
				if imgui.Button("Rancher") then dl.SendChat("/машину 489") end
				imgui.SameLine()
				if imgui.Button("Rancher Lure") then dl.SendChat("/машину 505") end
				imgui.SameLine()
				if imgui.Button("Sandking") then dl.SendChat("/машину 495") end
				imgui.SameLine()
				if imgui.Button("Sadler") then dl.SendChat("/машину 543") end
				imgui.SameLine()
				if imgui.Button("Sadler Shit") then dl.SendChat("/машину 605") end
				imgui.SameLine()
				if imgui.Button("Yosemite") then dl.SendChat("/машину 554") end
				imgui.SameLine()
				if imgui.Button("Bandito") then dl.SendChat("/машину 568") end
				imgui.SameLine()
				if imgui.Button("Huntley") then dl.SendChat("/машину 579") end
			imgui.EndChild()
		end
		if active_veh == 5 then
			imgui.BeginChild(u8"Служебные", imgui.ImVec2(992, 245), true)
				imgui.TextColoredRGB("Министерство обороны")
				if imgui.Button("Patriot") then dl.SendChat("/машину 470") end
				imgui.SameLine()
				if imgui.Button("Mesa") then dl.SendChat("/машину 500") end
				imgui.SameLine()
				if imgui.Button("Hydra") then dl.SendChat("/машину 520") end
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("Министерство внутренних дел")
				if imgui.Button("Police Car LSPD") then dl.SendChat("/машину 596") end
				imgui.SameLine()
				if imgui.Button("Police Car SFPD") then dl.SendChat("/машину 597") end
				imgui.SameLine()
				if imgui.Button("Police Car LVPD") then dl.SendChat("/машину 598") end
				imgui.SameLine()
				if imgui.Button("Police Ranger") then dl.SendChat("/машину 599") end
				imgui.SameLine()
				if imgui.Button("S.W.A.T.") then dl.SendChat("/машину 601") end
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("СМИ")
				if imgui.Button("Newsvan") then dl.SendChat("/машину 582") end
			imgui.EndChild()
		end
		if active_veh == 10 then
			imgui.BeginChild(u8"Обслуживание", imgui.ImVec2(992, 245), true)
				imgui.TextColoredRGB("Транспорт")
				if imgui.Button("Firetruck LA") then dl.SendChat("/машину 544") end
				imgui.SameLine()
				if imgui.Button("Brownstreak Train") then dl.SendChat("/машину 538") end
				imgui.SameLine()
				if imgui.Button("Freight Train") then dl.SendChat("/машину 537") end
				imgui.SameLine()
				if imgui.Button("Combine Harvester") then dl.SendChat("/машину 532") end
				imgui.SameLine()
				if imgui.Button("Tractor") then dl.SendChat("/машину 531") end
				imgui.SameLine()
				if imgui.Button("Forklift") then dl.SendChat("/машину 530") end
				imgui.SameLine()
				if imgui.Button("Utility Van") then dl.SendChat("/машину 552") end
				imgui.SameLine()
				if imgui.Button("DFT-30") then dl.SendChat("/машину 578") end
				imgui.SameLine()
				if imgui.Button("Sweeper") then dl.SendChat("/машину 574") end
				imgui.SameLine()
				if imgui.Button("Tug") then dl.SendChat("/машину 583") end
				imgui.SameLine()
				if imgui.Button("Towtruck") then dl.SendChat("/машину 525") end
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("Прицепы")
				if imgui.Button("Baggage Trailer A") then dl.SendChat("/машину 606") end
				imgui.SameLine()
				if imgui.Button("Baggage Trailer B") then dl.SendChat("/машину 607") end
				imgui.SameLine()
				if imgui.Button("Tug Stairs Trailer") then dl.SendChat("/машину 608") end
				imgui.SameLine()
				if imgui.Button("Farm Trailer") then dl.SendChat("/машину 610") end
				imgui.SameLine()
				if imgui.Button("Utility Trailer") then dl.SendChat("/машину 611") end
				imgui.SameLine()
				if imgui.Button("Freight Box Trailer Train") then dl.SendChat("/машину 590") end
				imgui.SameLine()
				if imgui.Button("Streak Trailer Train") then dl.SendChat("/машину 570") end
				imgui.SameLine()
				if imgui.Button("Freight Flat Trailer Train") then dl.SendChat("/машину 569") end
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("Радиоуправляемый транспорт")
				if imgui.Button("RC Cam") then dl.SendChat("/машину 594") end
				imgui.SameLine()
				if imgui.Button("RC Tiger") then dl.SendChat("/машину 564") end
				imgui.SameLine()
			imgui.EndChild()
		end
		if active_veh == 11 then
			imgui.BeginChild(u8"Грузовики", imgui.ImVec2(992, 245), true)
				imgui.TextColoredRGB("Транспорт")
				if imgui.Button("Tanker") then dl.SendChat("/машину 514") end
				imgui.SameLine()
				if imgui.Button("Roadtrain") then dl.SendChat("/машину 515") end
				imgui.SameLine()
				if imgui.Button("Cement Truck") then dl.SendChat("/машину 524") end
				imgui.TextColoredRGB("")
				imgui.TextColoredRGB("Прицепы")
				if imgui.Button("Article Trailer") then dl.SendChat("/машину 435") end
				imgui.SameLine()
				if imgui.Button("Article Trailer 2") then dl.SendChat("/машину 450") end
				imgui.SameLine()
				if imgui.Button("Article Trailer 3") then dl.SendChat("/машину 591") end
				imgui.SameLine()
				if imgui.Button("Petrol Trailer") then dl.SendChat("/машину 584") end
				imgui.SameLine()
			imgui.EndChild()
		end
		imgui.End()
	end
end



function imgui.TextQuestion(label, description)
    imgui.TextColoredRGB("{696969}"..label)

    if imgui.IsItemHovered() then
        imgui.BeginTooltip()
            imgui.PushTextWrapPos(600)
                imgui.TextUnformatted(u8(description))
            imgui.PopTextWrapPos()
        imgui.EndTooltip()
    end
end

function save()
    inicfg.save(HLcfg, directIni)
end

function imgui.BeforeDrawFrame()
	if fontsize20 == nil then
        fontsize20 = imgui.GetIO().Fonts:AddFontFromFileTTF(getFolderPath(0x14) .. '\\trebucbd.ttf', 20.0, nil, imgui.GetIO().Fonts:GetGlyphRangesCyrillic())
    end
	if fontsize15 == nil then
        fontsize15 = imgui.GetIO().Fonts:AddFontFromFileTTF(getFolderPath(0x14) .. '\\trebucbd.ttf', 15.0, nil, imgui.GetIO().Fonts:GetGlyphRangesCyrillic())
    end
    if iconfont == nil then
        local font_config = imgui.ImFontConfig()
        font_config.MergeMode = true

        iconfont = imgui.GetIO().Fonts:AddFontFromFileTTF('moonloader\\resource\\fonts\\fa-solid-900.ttf', 13.0, font_config, imgui.ImGlyphRanges({ fa.min_range, fa.max_range }))
    end
end

function imgui.TextColoredRGB(string)
    local style = imgui.GetStyle()
    local colors = style.Colors
    local clr = imgui.Col

    local function color_imvec4(color)
        if color:upper() == 'SSSSSS' then return colors[clr.Text] end
        local color = type(color) == 'number' and ('%X'):format(color):upper() or color:upper()
        local rgb = {}
        for i = 1, #color/2 do rgb[#rgb+1] = tonumber(color:sub(2*i-1, 2*i), 16) end
        return imgui.ImVec4(rgb[1]/255, rgb[2]/255, rgb[3]/255, rgb[4] and rgb[4]/255 or colors[clr.Text].w)
    end

    local function render_text(string)
        local text, color = {}, {}
        local m = 1
        while string:find('{......}') do
            local n, k = string:find('{......}')
            text[#text], text[#text+1] = string:sub(m, n-1), string:sub(k+1, #string)
            color[#color+1] = color_imvec4(string:sub(n+1, k-1))
            local t1, t2 = string:sub(1, n-1), string:sub(k+1, #string)
            string = t1..t2
            m = k-7
        end
        if text[0] then
            for i, _ in ipairs(text) do
                imgui.TextColored(color[i] or colors[clr.Text], u8(text[i]))
                imgui.SameLine(nil, 0)
            end
            imgui.NewLine()
        else imgui.Text(u8(string)) end
    end

    render_text(string)
end

function imgui.Link(link,name,myfunc)
    myfunc = type(name) == 'boolean' and name or myfunc or false
    name = type(name) == 'string' and name or type(name) == 'boolean' and link or link
    local size = imgui.CalcTextSize(name)
    local p = imgui.GetCursorScreenPos()
    local p2 = imgui.GetCursorPos()
    local resultBtn = imgui.InvisibleButton('##'..link..name, size)
    if resultBtn then
        if not myfunc then
            os.execute('explorer '..link)
        end
    end
    imgui.SetCursorPos(p2)
	
    if imgui.IsItemHovered() then
		--[[if desc then
            imgui.BeginTooltip()
            imgui.PushTextWrapPos(600)
            imgui.TextUnformatted(desc)
            imgui.PopTextWrapPos()
            imgui.EndTooltip()

        end]]
		
        imgui.TextColored(imgui.ImVec4(0, 79, 168, 1), name)
        imgui.GetWindowDrawList():AddLine(imgui.ImVec2(p.x, p.y + size.y), imgui.ImVec2(p.x + size.x, p.y + size.y), imgui.GetColorU32(imgui.ImVec4(0, 0.5, 1, 1)))
    else
        imgui.TextColored(imgui.ImVec4(0, 113, 183, 1), name)
    end
	
    return resultBtn
end

function imgui.NewInputText(lable, val, width, hint, hintpos)
    local hint = hint and hint or ''
    local hintpos = tonumber(hintpos) and tonumber(hintpos) or 1
    local cPos = imgui.GetCursorPos()
    imgui.PushItemWidth(width)
    local result = imgui.InputText(lable, val)
    if #val.v == 0 then
        local hintSize = imgui.CalcTextSize(hint)
        if hintpos == 2 then imgui.SameLine(cPos.x + (width - hintSize.x) / 2)
        elseif hintpos == 3 then imgui.SameLine(cPos.x + (width - hintSize.x - 5))
        else imgui.SameLine(cPos.x + 5) end
        imgui.TextColored(imgui.ImVec4(1.00, 1.00, 1.00, 0.40), tostring(hint))
    end
    imgui.PopItemWidth()
    return result
end

function imgui.ButtonClickable(clickable, ...)
    if clickable then
        return imgui.Button(...)

    else
        local r, g, b, a = imgui.ImColor(imgui.GetStyle().Colors[imgui.Col.Button]):GetFloat4()
        imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(r, g, b, a/2) )
        imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(r, g, b, a/2))
        imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(r, g, b, a/2))
        imgui.PushStyleColor(imgui.Col.Text, imgui.GetStyle().Colors[imgui.Col.TextDisabled])
            imgui.Button(...)
        imgui.PopStyleColor()
        imgui.PopStyleColor()
        imgui.PopStyleColor()
        imgui.PopStyleColor()
    end
end




function httpRequest(request, body, handler) -- copas.http
    -- start polling task
    if not copas.running then
        copas.running = true
        lua_thread.create(function()
            wait(0)
            while not copas.finished() do
                local ok, err = copas.step(0)
                if ok == nil then error(err) end
                wait(0)
            end
            copas.running = false
        end)
    end
    -- do request
    if handler then
        return copas.addthread(function(r, b, h)
            copas.setErrorHandler(function(err) h(nil, err) end)
            h(http.request(r, b))
        end, request, body, handler)
    else
        local results
        local thread = copas.addthread(function(r, b)
            copas.setErrorHandler(function(err) results = {nil, err} end)
            results = table.pack(http.request(r, b))
        end, request, body)
        while coroutine.status(thread) ~= 'dead' do wait(0) end
        return table.unpack(results)
    end
end

function clearHTML(html)
    html = string.gsub(html, '<script[%a%A]->[%a%A]-</script>', '')
    html = string.gsub(html, '<style[%a%A]->[%a%A]-</style>', '')
	--html = string.gsub(html, '<[%a%A]->', '')
    --Delete blank lines
    html = string.gsub(html, '\n\r', '\n')
    html = string.gsub(html, '%s+\n', '\n')
    html = string.gsub(html, '\n+', '\n')
    html = string.gsub(html, '\n%s+', '\n')
        --Delete spaces before and after
    html = string.gsub(html, '^%s+', '')
    html = string.gsub(html, '%s+$', '')

    return html
end



-- bool, users = getTableUsersByUrl(url) - получить таблицу пользователей по ссылке на .txt файл списка.
-- * url - ссылка на .txt файл списка.
-- * users - таблица пользователей.
-- * bool - загрузка списка удалась (true/false)
-- * users[номер пользователя].name - имя пользователя; users[номер пользователя].date - окончательная дата работы скрипта (чтобы узнать, когда наступил окончательный..
-- ..срок, нужна функция isAvailableUser).
-- availabled = isAvailableUser(users, name) - узнать, находится ли пользователь в списке и узнать, не закончился ли срок.
-- * users - таблица пользователей.
-- * name - имя пользователя.
-- * availabled - доступность (true/false).

function getTableUsersByUrl(url)
    local n_file, bool, users = os.getenv('TEMP')..os.time(), false, {}
    downloadUrlToFile(url, n_file, function(id, status)
        if status == 6 then bool = true end
    end)
    while not doesFileExist(n_file) do wait(0) end
    if bool then
        local file = io.open(n_file, 'r')
        for w in file:lines() do
            local n, d = w:match('(.*): (.*)')
            users[#users+1] = { name = n, date = d }
        end
        file:close()
        os.remove(n_file)
    end
    return bool, users
end

function isAvailableUser(users, name)
    for i, k in pairs(users) do
        if k.name == name then
            local d, m, y = k.date:match('(%d+)%.(%d+)%.(%d+)')
            local time = {
                day = tonumber(d),
                isdst = true,
                wday = 0,
                yday = 0,
                year = tonumber(y),
                month = tonumber(m),
                hour = 0
            }
            if os.time(time) >= os.time() then return true end
        end
    end
    return false
end

function saveLogs(god, mesac, den, arg)
	local pyt = god.."."..mesac.."."..den
	
	local nn2 = getWorkingDirectory().."\\logs\\temp\\"..pyt..".txt"
	
	local rrdd2
	
	if rrdd2 ~= nil then rrdd2:close() end
	
	rrdd2 = io.open(nn2,"r")
	if rrdd2 == nil then
		rrdd2 = nil
		printlog("Ошибка временного лога 2, "..arg)
		rrdd2 = io.open(nn2,"r")
	end
	
	rrdd2:seek("set",0)
	for line in rrdd2:lines() do
		if line:find(arg) then
			strLogs[#strLogs+1] = line
		end
	end
	rrdd2:close()
	rod = 1
	statlog = 'Загружено!'
end

function loadLogs(god, mesac, den, arg)
	if not doesDirectoryExist(getWorkingDirectory().."\\logs\\temp") then
		createDirectory(getWorkingDirectory().."\\logs\\temp")
		printlog("Создана папка для временных логов")
	end
	if bNotf then
		notf.addNotification("Загрузка логов...", 4, HLcfg.config.theme)
	end
	strLogs = {}
	
	httpRequest(urls, 'AdminNick=' ..HLcfg.config.login.. '&pas=' ..HLcfg.config.pass.. '&year=' ..god.. '&month=' ..mesac .. '&day=' ..den, function(responsed, code2, headers, status)
		if responsed ~= nil then
			printlog("Загрузка логов успешна, " ..status.. ", по дате: " ..god.. "." ..mesac.. "." ..den)
			local tt = clearHTML(responsed)
			local strData = {}
			for line in tt:gmatch("(.-)\n") do
				strData[#strData+1] = line
			end
			if (strData[69]:match('php/server_log/')) then
				local adres = strData[69]:match("<a href='php/server_log/(.*)%.log'>")
				if adres ~= nil then
					downloadUrlToFile("https://gta-samp.ru/php/server_log/" ..adres.. ".log", getWorkingDirectory().. "\\logs\\temp\\" ..(god).. "." ..mesac.. "." ..den.. ".txt")
					printlog("Временный лог успешно загружен")
					saveLogs(god, mesac, den, arg)
				else
					printlog("Ошибка скачивания временного лога")
				end
			else
				if bNotf then
					notf.addNotification("Загрузка логов отклонена!", 4, HLcfg.config.theme)
				end
				printlog("Авторизация отменена")
				printlog(strData[69])
			end
			strData = {}
		else
			printlog("Ошибка скачивания временных логов с сайта, "..code2)
		end
	end)
	
end

function downLogs(god, mesac, den, arg)
	local emmp = tostring(god).."."..tostring(mesac).."."..tostring(den) -- путь к директории по введенной дате
	if tonumber(god) and tonumber(mesac) and tonumber(den) then -- проверка на ввод данных
		if emmp ~= os.date("%Y").."."..getDatePC(2).."."..getDatePC(3) and den <= getDatePC(3) then -- проверка, если введена не сегодняшняя дата
			statlog = 'Скачивание лога...'
			printlog("Скачивание и запись старых логов аккаунта, "..arg)
			loadLogs(tostring(god), tostring(mesac), tostring(den), tostring(arg))
		else
			statlog = 'Скачивание лога...'
			printlog("Скачивание и запись сегодняшних логов аккаунта, "..arg)
			loadLogs(tostring(os.date("%Y")), tostring(getDatePC(2)), tostring(getDatePC(3)), tostring(arg))
		end
	else
		printlog("Введенная дата пуста либо содержит не только цифры")
	end
end

function updateHelper()
	downloadUrlToFile(update_url, update_path, function(id, status)
        if status == dlstatus.STATUS_ENDDOWNLOADDATA then
            local updateIni = inicfg.load(nil, update_path)
			if updateIni then
				if tonumber(updateIni.info.vers) > script_vers then
					if bNotf then
						notf.addNotification("Доступна версия " .. updateIni.info.vers_text .. ".", 4, HLcfg.config.theme)
					end
					update_state = true
					printlog("Обновление скрипта...")
				end
			else
				printlog("Ошибка обновления")
			end
            os.remove(update_path)
        end
    end)
end

function isDateCorrect(dateString)
    local d, m, Y = dateString:match("(%d+)%.(%d+)%.(%d+)")
    if d and m and Y then
        local epoch = os.time({year = Y, month = m, day = d})
        local date = string.format("%02d.%02d.%04d", d, m, Y)
        return date == os.date("%d.%m.%Y", epoch)
    end
    return false
end

function isTimeCorrect(timeString)
    local H, M, S = timeString:match("(%d+):(%d+):(%d+)")
    if H and M and S then
        local epoch = os.time({year = 2021, month = 12, day = 31, hour = H, min = M, sec = S})
        local time = string.format("%02d:%02d:%02d", H, M, S)
        return time == os.date("%H:%M:%S", epoch)
    end
    return false
end

function vkKeyboard()
	local keyboard = {}
	keyboard.one_time = false
	keyboard.buttons = {}
	keyboard.buttons[1] = {}
	local row = keyboard.buttons[1]
	row[1] = {}
	row[1].action = {}
	row[1].color = 'positive'
	row[1].action.type = 'text'
	row[1].action.payload = '{"button": "status"}'
	row[1].action.label = 'Активные аккаунты'
	return encodeJson(keyboard)
end

function char_to_hex(str)
  return string.format("%%%02X", string.byte(str))
end

function url_encode(str)
  local str = string.gsub(str, "\\", "\\")
  local str = string.gsub(str, "([^%w])", char_to_hex)
  return str
end

function vkreq(msg)
	msg = msg:gsub('{......}', '')
	msg = "["..string.gsub(dl.getLocalUsername(), "_", " ").."]: ".. msg
	msg = u8(msg)
	msg = url_encode(msg)
	local keyboard = vkKeyboard()
	keyboard = u8(keyboard)
	keyboard = url_encode(keyboard)
	msg = msg .. '&keyboard=' .. keyboard
	httpRequest('https://api.vk.com/method/messages.send', 'user_id=301769883&message=' .. msg .. '&access_token=69af5b2716f6f9f7daa4633e17ea276c5a510ca7c6931155258a27739e988299ef3d726382cd308cdcb08&v=5.80', function(response, code, headers, status)
		--[[if response then
			print('yes')
		else
			print('not ' ..code)
		end]]
		printlog("Отправлено сообщение боту")
	end)
end

function printlog(text)
	local pyt = os.date("%Y").."."..getDatePC(2).."."..getDatePC(3)
	local tim = os.date("%H").."."..os.date("%M").."."..os.date("%S")
	if not doesDirectoryExist(getWorkingDirectory().."\\logs\\script") then
		createDirectory(getWorkingDirectory().."\\logs\\script")
		print("Create a folder for logs")
	end
	local path
	if doesFileExist(getWorkingDirectory().."\\logs\\script\\"..pyt..".txt") then
		path, err, code = assert(io.open(getWorkingDirectory().."\\logs\\script\\"..pyt..".txt","a"))
	else
		path, err, code = assert(io.open(getWorkingDirectory().."\\logs\\script\\"..pyt..".txt","w"))
	end
	if path  == nil then print(code, path, err) end
	path:write("["..pyt.." "..tim.."] "..text.."\n")
	path:flush()
	path:close()
end

function lastline(path, how_many)
    how_many = (how_many) or 1
    how_many = how_many + 1
	
	local path2
	if path == 'chatlog' then
		path2 = "C:\\users\\" ..os.getenv('USERNAME').. "\\Documents\\GTA San Andreas User Files\\SAMP\\chatlog.txt"
	else
		path2 = path
	end
	
    local f = assert(io.open(path2))
    local new_lines_found = 0
    
    local len = f:seek("end")
    for back_by=1, len do
        f:seek("end", -back_by)
        if f:read(1) == '\n' then
            new_lines_found = new_lines_found + 1
            if new_lines_found == how_many then
                local last_lines = f:read("a")
				last_lines = string.gsub(last_lines, '%[..:..:..%] ', '')
				last_lines = string.gsub(last_lines, '{......}', '')
                return last_lines
            end
        end
    end

    f:close()
end

function imgui.printText(mass, arg)

	local primer_text = {}
	if mass == 'first' then
		primer_text = {'Текст 1', 'Текст 2'}
	end
				
	imgui.TextColoredRGB(primer_text[arg])
	if imgui.IsItemClicked() then
		setClipboardText(primer_text[arg])
	end
end

function deleteLine(filePath, text)
    local tableOfLines = {}   
    for line in io.lines(filePath) do
        if not u8:decode(line):find(text) then
            table.insert(tableOfLines, line)
        end
    end
    local file = io.open(filePath, 'w+')
    file:write(table.concat(tableOfLines), "\n")
    file:close()
end

--[[
function main()
    sampRegisterChatCommand("openmenu", function()
        mimgui_loader_circle, mimgui_loader_time, mimgui_loader_finish = 1, os.clock(), 0
        mimgui_loading_window[0] = true -- Показываем окно с лоадером
        lua_thread.create(function()
            wait(5000) -- Ожидаем 5 секунд, эмитируя загрузку
            mimgui_loader_finish = 1 -- Завершаем процесс загрузки
        end)
    end)
end

-- Код ниже нужно поместить куда-нибудь в тело mimgui окна
local lspeed = 0.3 -- Задаём скорость мигания точек
if mimgui_loader_finish >= 1 then lspeed = 0.005 end -- Задаём скорость соединения точек
mimgui_loader(lspeed, 0xFFFFFFFF) -- Производим рисование точечно-кругового рендера

local mimgui_loader_circle, mimgui_loader_time, mimgui_loader_finish = 1, os.clock(), 0
local function mimgui_loader(speed, color)
    if not color then color = 0xFFFFFFFF end
    local draw_list = imgui.GetWindowDrawList()
    local p = imgui.GetCursorScreenPos()
    if mimgui_loader_finish < 1 then
        draw_list:AddCircleFilled(imgui.ImVec2(p.x, p.y), 14.0, (mimgui_loader_circle == 1 and 0x25FFFFFF or color), 30)
        draw_list:AddCircleFilled(imgui.ImVec2(p.x + 64, p.y), 14.0, (mimgui_loader_circle == 2 and 0x25FFFFFF or color), 30)
        draw_list:AddCircleFilled(imgui.ImVec2(p.x + 128, p.y), 14.0, (mimgui_loader_circle == 3 and 0x25FFFFFF or color), 30)
        draw_list:AddCircleFilled(imgui.ImVec2(p.x + 192, p.y), 14.0, (mimgui_loader_circle == 4 and 0x25FFFFFF or color), 30)
        if mimgui_loader_time + speed < os.clock() then  mimgui_loader_time = os.clock()
            if mimgui_loader_circle == 4 then mimgui_loader_circle = 1
            else mimgui_loader_circle = mimgui_loader_circle + 1 end
        end
    elseif mimgui_loader_finish >= 1 then
        draw_list:AddCircleFilled(imgui.ImVec2(p.x + mimgui_loader_finish / 2, p.y), 14.0, color, 30)
        draw_list:AddCircleFilled(imgui.ImVec2(p.x + 64 + mimgui_loader_finish, p.y), 14.0, color, 30)
        draw_list:AddCircleFilled(imgui.ImVec2(p.x + 128 - mimgui_loader_finish, p.y), 14.0, color, 30)
        draw_list:AddCircleFilled(imgui.ImVec2(p.x + 192 - mimgui_loader_finish / 2, p.y), 14.0, color, 30)
        if mimgui_loader_time + speed < os.clock() then mimgui_loader_time = os.clock()
            if mimgui_loader_finish < 88 then mimgui_loader_finish = mimgui_loader_finish + 1 end
        end
    end
end



sampRegisterChatCommand({"command", "cmd", "cm", "comm"}, function()
  sampAddChatMessage("Hello world, how are you?", -1)
end)

local originalSampRegisterChatCommand = sampRegisterChatCommand
local originalSampUnregisterChatCommand = sampUnregisterChatCommand
function sampRegisterChatCommand(commands, callback)
  if type(commands) == "table" then
    local all_registered = true
    for i, v in ipairs(commands) do
      local temp = originalSampRegisterChatCommand(v, callback)
      all_registered = all_registered and temp
    end
    return all_registered
  else
    return originalSampRegisterChatCommand(commands, callback)
  end
end
function sampUnregisterChatCommand(commands)
  if type(commands) == "table" then
    local all_unregistered = true
    for i, v in ipairs(commands) do
      local temp = originalSampUnregisterChatCommand(v)
      all_unregistered = all_unregistered and temp
    end
    return all_unregistered
  else
    return originalSampUnregisterChatCommand(commands)
  end
end
]]