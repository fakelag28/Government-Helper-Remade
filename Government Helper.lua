script_name("Government Helper Remade")
script_properties("work-in-pause")
script_author("fakelag / Rice.")
script_version("1.5f")

require "moonloader"
require "lib.vkeys"
local dlstatus = require "moonloader".download_status
local inicfg = require "inicfg"
local memory = require "memory"
local ffi = require 'ffi'
ffi.cdef[[
    intptr_t LoadKeyboardLayoutA(const char* pwszKLID, unsigned int Flags);
    int PostMessageA(intptr_t hWnd, unsigned int Msg, unsigned int wParam, long lParam);
    intptr_t GetActiveWindow();
]]
local sampev = require("samp.events")
local raknet = require("lib.samp.raknet")
local imguicheck, imgui = pcall(require, "imgui")
local encodingcheck, encoding = pcall(require, "encoding")
encoding.default = "CP1251"
u8 = encoding.UTF8
imgui._SmoothScroll = {
    defaultSpeed = 30,
    xAxisKey = 0x10,
    pos = {}
}
local SS = imgui.ImBool(true)
local speed = imgui.ImInt(25)

local fa = {
    ["ICON_FA_UNIVERSITY"] = "\xef\x86\x9c",
    ["ICON_FA_TIMES_CIRCLE"] = "\xef\x81\x97",
    ["ICON_FA_USER_CIRCLE"] = "\xef\x8a\xbd",
    ["ICON_FA_USER"] = "\xef\x80\x87",
    ["ICON_FA_COG"] = "\xef\x80\x93",
    ["ICON_FA_PEN"] = "\xef\x8c\x84",
    ["ICON_FA_TRASH"] = "\xef\x87\xb8",
    ["ICON_FA_CHILD"] = "\xef\x86\xae",
    ["ICON_FA_MOBILE"] = "\xef\x84\x8b",
    ["ICON_FA_PLUS_CIRCLE"] = "\xef\x81\x95",
    ["ICON_FA_LINK"] = "\xef\x83\x81",
    ["ICON_FA_INFO_CIRCLE"] = "\xef\x81\x9a",
    ["ICON_FA_SHARE"] = "\xef\x81\xa4",
    ["ICON_FA_CLIPBOARD"] = "\xef\x83\xaa",
    ["ICON_FA_QUESTION_CIRCLE"] = "\xef\x81\x99",
    ["ICON_FA_ARROWS_ALT"] = "\xef\x82\xb2",
    ["ICON_FA_RETWEET"] = "\xef\x81\xb9"
}

local MIN_ICON, MAX_ICON = 0xf000, 0xf83e

local function unicode_to_utf8(code)
    local t, h = {}, 128
    while code >= h do
        t[#t + 1] = 128 + code % 64
        code = math.floor(code / 64)
        h = h > 32 and 32 or h / 2
    end
    t[#t + 1] = 256 - 2 * h + code
    return string.char(unpack(t)):reverse()
end

setmetatable(
    fa,
    {
        __call = function(t, v)
            if (type(v) == "string") then
                return t["ICON_" .. v:upper()] or "?"
            elseif (type(v) == "number" and v >= MIN_ICON and v <= MAX_ICON) then
                return unicode_to_utf8(v)
            end
            return "?"
        end,
        __index = function(t, i)
            if type(i) == "string" then
                if i == "min_range" then
                    return MIN_ICON
                elseif i == "max_range" then
                    return MAX_ICON
                end
            end

            return t[i]
        end
    }
)

local fa_font = nil
local fontsize20 = nil
local fontsize50 = nil
local fontsize501 = nil
local fontsize5011 = nil
local fontsize5012 = nil
local fa_glyph_ranges = imgui.ImGlyphRanges({fa.min_range, fa.max_range})
function imgui.BeforeDrawFrame()
    if fa_font == nil then
        local font_config = imgui.ImFontConfig()
        font_config.MergeMode = true
        fa_font =
            imgui.GetIO().Fonts:AddFontFromFileTTF(
            "moonloader/resource/fonts/fa-solid-900.ttf",
            15.0,
            font_config,
            fa_glyph_ranges
        )
    end

    if fontsize20 == nil then
        fontsize20 =
            imgui.GetIO().Fonts:AddFontFromFileTTF(
            "moonloader/resource/fonts/fa-solid-900.ttf",
            20.0,
            font_config,
            fa_glyph_ranges
        )
    end

    if fontsize50 == nil then
        fontsize50 =
            imgui.GetIO().Fonts:AddFontFromFileTTF(
            "moonloader/resource/fonts/fa-solid-900.ttf",
            40.0,
            font_config,
            fa_glyph_ranges
        )
    end

    if fontsize501 == nil then
        fontsize501 =
            imgui.GetIO().Fonts:AddFontFromFileTTF(
            getFolderPath(0x14) .. "\\trebucbd.ttf",
            45.0,
            nil,
            imgui.GetIO().Fonts:GetGlyphRangesCyrillic()
        )
    end

    if fontsize5011 == nil then
        fontsize5011 =
            imgui.GetIO().Fonts:AddFontFromFileTTF(
            getFolderPath(0x14) .. "\\trebucbd.ttf",
            25.0,
            nil,
            imgui.GetIO().Fonts:GetGlyphRangesCyrillic()
        )
    end

    if fontsize5012 == nil then
        fontsize5012 =
            imgui.GetIO().Fonts:AddFontFromFileTTF(
            getFolderPath(0x14) .. "\\trebucbd.ttf",
            18.0,
            nil,
            imgui.GetIO().Fonts:GetGlyphRangesCyrillic()
        )
    end
end

local cfg =
    inicfg.load(
    {
        Settings = {
            FirstSettings = false,
            fixdoor = false,
            bindopengate = false,
            nonrpchat = false,
            advoverlay = false,
            rank = "��������",
            rankAndNumber = "1",
            RP = true,
            waitRP = 2.5,
            expelreason = '�.�.�.',
            autolog = false,
            autologvid = '{my:name} | {my:rank} | GOV | {date} | {timeo} | {player:name} | � X �� {player:rank} (X)',
            sex = 1
        },
        Pos = {
            x = 625,
            y = 915
        },
        Binds_Name = {[1] = "������� (������)"},
        Binds_Action = {[1] = "/me {sex:������|�������} �� ������� �� ����� \"{my:name} - {my:rank}\"."},
        Binds_Deleay = {[1] = 2500}
    },
    "Government Helper"
)

local tag = "{FFF332}[Government Helper Remade] {FFFFFF}"
local date = os.date("%d.%m.%Y")
local timeo = os.date("%H:%M")
local mc = 0xFFF332
local sc = "{FFF332}"
local dopmenu = imgui.ImBool(false)
local window = imgui.ImBool(false)
local advoverlay = imgui.ImBool(cfg.Settings.advoverlay)
local advstate = false
local fixdoor = imgui.ImBool(cfg.Settings.fixdoor)
local nonrpchat = imgui.ImBool(cfg.Settings.nonrpchat)
local bindopengate = imgui.ImBool(cfg.Settings.bindopengate)
local rank = imgui.ImBuffer("" .. cfg.Settings.rank, 30)
local rankAndNumber = imgui.ImBuffer("" .. cfg.Settings.rankAndNumber, 30)
local RP = imgui.ImBool(cfg.Settings.RP)
local waitRP = imgui.ImFloat(cfg.Settings.waitRP)
local sex = imgui.ImInt(cfg.Settings.sex)
local expelreason = imgui.ImBuffer(u8("" .. cfg.Settings.expelreason), 30)
local autolog = imgui.ImBool(cfg.Settings.autolog)
local autologvid = imgui.ImBuffer(u8("" .. cfg.Settings.autologvid), 200)
local FirstSettings = imgui.ImBool(cfg.Settings.FirstSettings)
local binder_delay = imgui.ImInt(2500)
local text_binder = imgui.ImBuffer(65536)
local text_ustav = imgui.ImBuffer(65536)
local binder_name = imgui.ImBuffer(35)
local ReasonUval = imgui.ImBuffer(50)
local giverankInt = imgui.ImInt(1)
local freeInt = imgui.ImInt(0)
local IDplayer = imgui.ImInt(0)
local posX, posY = cfg.Pos.x, cfg.Pos.y
fileconfig = getWorkingDirectory() .. "//config//Government Helper.ini"
local getRankInStats = false
local owner = false
local convicts = {data = {}}
local department = {
    ['Los Santos'] = 'LSPD',
    ['San Fierro'] = 'SFPD',
    ['Las Venturas'] = 'LVPD',
    ['Red County'] = 'RCSD'
}

function main()
    if not isSampfuncsLoaded() or not isSampLoaded() then
        return
    end
    while not isSampAvailable() do
        wait(200)
    end
    while not sampIsLocalPlayerSpawned() do
        wait(0)
    end

    log("���������� � �������...")

    imgui.Process = false

    _, id = sampGetPlayerIdByCharHandle(PLAYER_PED)
    nick = sampGetPlayerNickname(id)


    GHsms("������ �������! ��������� - /gh")
    checkOrg()

    sampRegisterChatCommand(
        "gh",
        function()
            if not dopmenu.v then
                window.v = not window.v
                menu = 1
            else
                GHsms("��������� ���� ��������������, ����� ������� ������ ����!")
            end
        end
    )
    sampRegisterChatCommand(
        "gha",
        function()
            advstate = not advstate
            if advstate == true then
                GHsms("������� ����� �������� ����������� � ���.")
            else
                    GHsms("�������� ����� �������� ����������� � ���.")
            end
        end
    )
    sampRegisterChatCommand(
        "ghm",
        function(player_id)
            dopmenu.v = not dopmenu.v
            if player_id ~= nil then
                IDplayer.v = player_id
            else
                IDplayer.v = 0
            end
            imgui.Process = true
            imgui.ShowCursor = true
        end
    )

    if cfg.Settings.RP == true then
        sampRegisterChatCommand(
            "givevisa",
            function(givevisa_id)
                local givevisa_id = givevisa_id:match("(%d+)")
                if tonumber(givevisa_id) and sampIsPlayerConnected(tonumber(givevisa_id)) then
                    lua_thread.create(
                        function()
                            sampSendChat(
                                "/me {sex:������|�������} �� �������� ������ ����� � {sex:�������|��������} ��� ����� ���������"
                            )
                            wait(waitRP.v * 1000)
                            sampSendChat(
                                "/todo ��� ����� ����� ��������� ��� ���� � ���������*��������� ����� ��������"
                            )
                            wait(waitRP.v * 1000)
                            sampSendChat("/givevisa " .. givevisa_id)
                            wait(waitRP.v * 1000)
                            sampSendChat("/do ��� ������ ���� � ��������� ���� ���������.")
                            wait(waitRP.v * 1000)
                            sampSendChat("/me {sex:��������|���������} ���������� ���� � {sex:����|�������} �� � ����")
                            wait(waitRP.v * 1000)
                            sampSendChat("/todo �������� ���!*��������� ������ ��������� ���� ��������")
                        end
                    )
                else
                    GHsms("�����������: /givevisa [id]")
                end
            end
        )
    else
        sampUnregisterChatCommand("givevisa")
    end

    if cfg.Settings.RP == true then
        sampRegisterChatCommand(
            "givepass",
            function(givepass_id)
                local givepass_id = givepass_id:match("(%d+)")
                if tonumber(givepass_id) and sampIsPlayerConnected(tonumber(givepass_id)) then
                    lua_thread.create(
                        function()
                            sampSendChat(
                                "/me {sex:������|�������} ������ ��������� � �������������� ������ � {sex:�������|��������} ��� ����� ���������"
                            )
                            wait(waitRP.v * 1000)
                            sampSendChat(
                                "/todo ��� ����� ����� ��������� ��� ���� � ���������*��������� ����� ��������"
                            )
                            wait(waitRP.v * 1000)
                            sampSendChat("/givepass " .. givepass_id)
                            wait(waitRP.v * 1000)
                            sampSendChat("/do ��� ������ ���� � ��������� ���� ���������.")
                            wait(waitRP.v * 1000)
                            sampSendChat(
                                "/me {sex:��������|���������} ���������� ���� � {sex:����|�������} �� � ���������"
                            )
                            wait(waitRP.v * 1000)
                            sampSendChat("/todo �������� ���!*��������� ��������� ��������")
                        end
                    )
                else
                    GHsms("�����������: /givepass [id]")
                end
            end
        )
    else
        sampUnregisterChatCommand("givepass")
    end

    if cfg.Settings.RP == true then
        sampRegisterChatCommand(
            "givewbook",
            function(givewbook_id)
                local givewbook_id, givewbook_price = givewbook_id:match("(%d+) (.+)")
                if tonumber(givewbook_id) and tostring(givewbook_price) and sampIsPlayerConnected(tonumber(givewbook_id)) then
                    lua_thread.create(
                        function()
                            sampSendChat(
                                "/me {sex:������|�������} ������ ��������� � �������������� ������ � {sex:�������|��������} ��� ����� ���������"
                            )
                            wait(waitRP.v * 1000)
                            sampSendChat(
                                "/todo ��� ����� ����� ��������� ��� ���� � ���������*��������� ����� ��������"
                            )
                            wait(waitRP.v * 1000)
                            sampSendChat("/givewbook " .. givewbook_id .. ' ' .. tostring(givewbook_price))
                            wait(waitRP.v * 1000)
                            sampSendChat("/do ��� ������ ���� � ��������� ���� ���������.")
                            wait(waitRP.v * 1000)
                            sampSendChat(
                                "/me {sex:��������|���������} ���������� ���� � {sex:����|�������} �� � �������� ������"
                            )
                            wait(waitRP.v * 1000)
                            sampSendChat("/todo �������� ���!*��������� �������� ������ ��������")
                        end
                    )
                else
                    GHsms("�����������: /givewbook [id] [price (100$ - 50.000$)]")
                end
            end
        )
    else
        sampUnregisterChatCommand("givewbook")
    end

    if cfg.Settings.RP == true then
        sampRegisterChatCommand(
            "uninvite",
            function(uninv_id)
                local uninv_id, uninv_reason = uninv_id:match("(%d+) (.+)")
                if tonumber(uninv_id) and tostring(uninv_reason) ~= "" and sampIsPlayerConnected(tonumber(uninv_id)) then
                    lua_thread.create(
                        function()
                            sampSendChat("/me {sex:������|�������} ������� � {sex:������|�������} ���� ������")
                            wait(waitRP.v * 1000)
                            sampSendChat(
                                "/me {sex:�������|�������} � ������ ����������� � {sex:�����|�����} ��� " ..
                                    rpNick(tonumber(uninv_id))
                            )
                            wait(waitRP.v * 1000)
                            sampSendChat("/me {sex:������|�������} ���������� � {sex:�����|������} ���������")
                            wait(waitRP.v * 1000)
                            sampSendChat("/uninvite " .. tostring(uninv_id) .. " " .. tostring(uninv_reason))
                        end
                    )
                else
                    GHsms("�����������: /uninvite [id] [�������]")
                end
            end
        )
    else
        sampUnregisterChatCommand("uninvite")
    end

    if cfg.Settings.RP == true then
        sampRegisterChatCommand(
            "invite",
            function(invite_id)
                local invite_id = invite_id:match("(%d+)")
                if tonumber(invite_id) and sampIsPlayerConnected(tonumber(invite_id)) then
                    lua_thread.create(
                        function()
                            sampSendChat("/me {sex:������|�������} ������� � {sex:������|�������} ���� ������")
                            wait(waitRP.v * 1000)
                            sampSendChat(
                                "/me {sex:�������|�������} � ������ ����������� � {sex:���|������} ���� ������ ���������� " ..
                                    rpNick(tonumber(invite_id))
                            )
                            wait(waitRP.v * 1000)
                            sampSendChat("/me {sex:�������|��������} ���������� ����� �� ��������")
                            wait(waitRP.v * 1000)
                            sampSendChat("/invite " .. tostring(invite_id))
                        end
                    )
                else
                    GHsms("�����������: /invite [id]")
                end
            end
        )
    else
        sampUnregisterChatCommand("invite")
    end

    if cfg.Settings.RP == true then
        sampRegisterChatCommand(
            "giverank",
            function(giverank_id)
                local giverank_id, giverank_rank = giverank_id:match("(%d+) (%d+)")
                if tonumber(giverank_id) and tonumber(giverank_rank) and sampIsPlayerConnected(tonumber(giverank_id)) then
                    lua_thread.create(
                        function()
                            sampSendChat("/me {sex:������|�������} �� ������� ���")
                            wait(waitRP.v * 1000)
                            sampSendChat("/me {sex:�������|��������} ��� � {sex:�����|�����} � ������ �����������")
                            wait(waitRP.v * 1000)
                            sampSendChat("/me {sex:������|�������} ���������� " .. rpNick(tonumber(giverank_id)))
                            wait(waitRP.v * 1000)
                            sampSendChat("/me {sex:�������|��������} ��������� ����������")
                            wait(waitRP.v * 1000)
                            sampSendChat("/giverank " .. tostring(giverank_id) .. " " .. tostring(giverank_rank))
                        end
                    )
                else
                    GHsms("�����������: /giverank [id] [rank]")
                end
            end
        )
    else
        sampUnregisterChatCommand("giverank")
    end

    if cfg.Settings.RP == true then
        sampRegisterChatCommand(
            "fwarn",
            function(fwarn_id)
                local fwarn_id, fwarn_reason = fwarn_id:match("(%d+) (.+)")
                if tonumber(fwarn_id) and tostring(fwarn_reason) ~= "" and sampIsPlayerConnected(tonumber(fwarn_id)) then
                    lua_thread.create(
                        function()
                            sampSendChat("/me {sex:������|�������} �� ������� ���")
                            wait(waitRP.v * 1000)
                            sampSendChat("/me {sex:�������|��������} ��� � {sex:�����|�����} � ������ �����������")
                            wait(waitRP.v * 1000)
                            sampSendChat("/me {sex:������|�������} ���������� " .. rpNick(tonumber(fwarn_id)))
                            wait(waitRP.v * 1000)
                            sampSendChat("/me � ���� {sex:������|�������} ����� ������� �������")
                            wait(waitRP.v * 1000)
                            sampSendChat("/fwarn " .. tostring(fwarn_id) .. " " .. tostring(fwarn_reason))
                        end
                    )
                else
                    GHsms("�����������: /fwarn [id] [reason]")
                end
            end
        )
    else
        sampUnregisterChatCommand("fwarn")
    end

    if cfg.Settings.RP == true then
        sampRegisterChatCommand(
            "demoute",
            function(demoute_id)
                local demoute_id, demoute_reason = demoute_id:match("(%d+) (.+)")
                if tonumber(demoute_id) and tostring(demoute_reason) and sampIsPlayerConnected(tonumber(demoute_id)) then
                    lua_thread.create(
                        function()
                            sampSendChat("/me {sex:������|�������} �� ������� ���")
                            wait(waitRP.v * 1000)
                            sampSendChat(
                                "/me {sex:�������|��������} ��� � {sex:�����|�����} � ������ ���������������� �����������"
                            )
                            wait(waitRP.v * 1000)
                            sampSendChat("/me {sex:������|�������} ���������� " .. rpNick(tonumber(demoute_id)))
                            wait(waitRP.v * 1000)
                            sampSendChat("/me {sex:�����|�������} ���������� �� ���� ������")
                            wait(waitRP.v * 1000)
                            sampSendChat("/demoute " .. tostring(demoute_id) .. " " .. tostring(demoute_reason))
                        end
                    )
                else
                    GHsms("�����������: /demoute [id] [reason]")
                end
            end
        )
    else
        sampUnregisterChatCommand("demoute")
    end

    if cfg.Settings.RP == true then
        sampRegisterChatCommand(
            "free",
            function(free_id)
                local free_id, free_price = free_id:match("(%d+) (.+)")
                if tonumber(free_id) and tostring(free_price) and sampIsPlayerConnected(tonumber(free_id)) then
                    lua_thread.create(
                        function()
                            sampSendChat("/do ����� � �������������� ����������� � ����� ����.")
                            wait(waitRP.v * 1000)
                            sampSendChat(
                                "/me {sex:������|�������} �����, {sex:������|�������} ����� �������� � {sex:��������|���������} �������� �������� ��������."
                            )
                            wait(waitRP.v * 1000)
                            sampSendChat('/todo ����������� ��� ���.*������ ������ � ����� "�������"')
                            wait(waitRP.v * 1000)
                            sampSendChat("/free " .. tostring(free_id) .. " " .. tostring(free_price))
                        end
                    )
                else
                    GHsms("�����������: /free [id] [price]")
                end
            end
        )
    else
        sampUnregisterChatCommand("free")
    end

    if cfg.Settings.RP == true then
        sampRegisterChatCommand(
            "showvisit",
            function(showvisit_id)
                local showvisit_id = showvisit_id:match("(%d+)")
                if tonumber(showvisit_id) and sampIsPlayerConnected(tonumber(showvisit_id)) then
                    lua_thread.create(
                        function()
                            sampSendChat(
                                "/me {sex:������|�������} �� ������� ������� ��������, {sex:������|�������} ��� � {sex:������|�������} ������ �������"
                            )
                            wait(waitRP.v * 1000)
                            sampSendChat('/do � ������� ��������: ��������������� ������� "{my:name}".')
                            wait(waitRP.v * 1000)
                            sampSendChat("/todo �������*��������� �������")
                            wait(waitRP.v * 1000)
                            sampSendChat("/showvisit " .. tostring(showvisit_id))
                        end
                    )
                else
                    GHsms("�����������: /showvisit [id]")
                end
            end
        )
    else
        sampUnregisterChatCommand("showvisit")
    end

    if cfg.Settings.RP == true then
        sampRegisterChatCommand(
            "uninviteoff",
            function(uninviteoff_nick)
                local uninviteoff_nick = uninviteoff_nick:match("(.+)")
                if uninviteoff_nick == nil or uninviteoff_nick == "" then
                    GHsms("�����������: /uninviteoff [nick]")
                else
                    lua_thread.create(
                        function()
                            sampSendChat("/me {sex:������|�������} ��� � {sex:������|�������} ���� ������")
                            wait(waitRP.v * 1000)
                            sampSendChat("/me {sex:�������|�������} � ������ �����������")
                            wait(waitRP.v * 1000)
                            sampSendChat("/me {sex:������|�������} ���������� � {sex:�����|������} ���������")
                            wait(waitRP.v * 1000)
                            sampSendChat("/uninviteoff " .. tostring(uninviteoff_nick))
                        end
                    )
                end
            end
        )
    else
        sampUnregisterChatCommand("uninviteoff")
    end

    if cfg.Settings.RP == true then
        sampRegisterChatCommand(
            "expel",
            function(expel_id)
                local expel_id, expel_reason = expel_id:match("(%d+) (.+)")
                if tonumber(expel_id) and tostring(expel_reason) and sampIsPlayerConnected(tonumber(expel_id)) then
                    lua_thread.create(
                        function()
                            sampSendChat("��� ������� ������� ��� �� ������ �������������.")
                            wait(waitRP.v * 1000)
                            sampSendChat(
                                "/me {sex:�������|��������} �� ���� � {sex:����|������} � ������ " ..
                                    rpNick(tonumber(expel_id))
                            )
                            wait(waitRP.v * 1000)
                            sampSendChat("/todo � ������ ��������� ��� ����� ����������!*�������� ����� ������..")
                            wait(waitRP.v * 1000)
                            sampSendChat("/expel " .. tostring(expel_id) .. " " .. tostring(expel_reason))
                        end
                    )
                else
                    GHsms("�����������: /expel [id] [reason]")
                end
            end
        )
    else
        sampUnregisterChatCommand("expel")
    end

    if cfg.Settings.RP == true then
        sampRegisterChatCommand(
            "unfwarn",
            function(unfwarn_id)
                local unfwarn_id = unfwarn_id:match("(%d+)")
                if tonumber(unfwarn_id) and sampIsPlayerConnected(tonumber(unfwarn_id)) then
                    lua_thread.create(
                        function()
                            sampSendChat("/me {sex:������|�������} �� ������� ���")
                            wait(waitRP.v * 1000)
                            sampSendChat("/me {sex:�������|��������} ��� � {sex:�����|�����} � ������ �����������")
                            wait(waitRP.v * 1000)
                            sampSendChat("/me {sex:������|�������} ���������� " .. rpNick(tonumber(unfwarn_id)))
                            wait(waitRP.v * 1000)
                            sampSendChat("/me � ���� {sex:������|�������} ����� ������ �������")
                            wait(waitRP.v * 1000)
                            sampSendChat("/unfwarn " .. tostring(fwarn_id))
                        end
                    )
                else
                    GHsms("�����������: /unfwarn [id]")
                end
            end
        )
    else
        sampUnregisterChatCommand("unfwarn")
    end

    log("������ ����� � ������!")

    while true do
        wait(0)
        if fixdoor.v then
            if not sampIsChatInputActive() then
                if isKeyJustPressed(VK_H) then
                    local posX, posY, posZ = getCharCoordinates(playerPed)
                    local res, text, color, x, y, z, distance, ignoreWalls, player, vehicle =
                        Search3Dtext(posX, posY, posZ, 50.0, "")
                    if text:find("�������") then
                        sampSendChat("/opengate")
                        if bindopengate.v then
                            wait(500)
                            sampSendChat("/opengate")
                            sampSendChat("/me ������ ID �����, �������� � � �����������.")
                            wait(500)
                        end
                    end
                end
            end
        end
        if window.v or dopmenu.v then
            imgui.Process = true
            imgui.ShowCursor = true
        else
            imgui.Process = false
            imgui.ShowCursor = false
        end
        if advoverlay.v then
            imgui.Process = true
        end
        local result, id = sampGetPlayerIdOnTargetKey(VK_Q)
        if result then
            GHsms("������ �����: " .. sampGetPlayerNickname(id) .. " [" .. id .. "]")
            IDplayer.v = id
            window.v = false
            dopmenu.v = true
            imgui.Process = true
            imgui.ShowCursor = true
        end
    end
end

function sampGetPlayerIdOnTargetKey(key)
    local result, ped = getCharPlayerIsTargeting(PLAYER_HANDLE)
    if result then
        if isKeyJustPressed(key) then
            return sampGetPlayerIdByCharHandle(ped)
        end
    end
    return false
end

lua_thread.create(function ()
    while true do
        wait(2000)
        if advstate then
            convicts:eraseTable("data")
            sampSendChat('/zeks')
        end
    end
end)

function convicts:eraseTable(tab)
    if (#self[tab] > 0) then
        self[tab] = {}
    end
end

function GHsms(text)
    sampAddChatMessage(tag .. text, 0xFFF332)
end

function imgui.OnDrawFrame()
    if advoverlay.v then
        local sw, sh = getScreenResolution()
      imgui.SetNextWindowPos(imgui.ImVec2(40, 600), imgui.Cond.Always)
      imgui.Begin(
         u8 "##menu3",
         _,
         imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.AlwaysAutoResize
      )
      local text = table.concat(convicts.data, "\n")
      if text == '' then
        text = u8'�����������'
      end
      imgui.Text(text)
      imgui.End()
    end
    if dopmenu.v then
        local sw, sh = getScreenResolution()
        local buttonCount = 0
        imgui.SetNextWindowPos(imgui.ImVec2(posX, posY), imgui.Cond.Always)
        imgui.Begin(
            u8 "##menu2",
            _,
            imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoTitleBar +
                imgui.WindowFlags.AlwaysAutoResize
        )
        imgui.PushItemWidth(90)
        imgui.CenterText(sampGetPlayerNickname(IDplayer.v) .. " [" .. IDplayer.v .. "]")
        imgui.PopItemWidth()
        if IDplayer.v > 999 then
            IDplayer.v = 999
        end
        if IDplayer.v < 0 then
            IDplayer.v = 0
        end
        imgui.BeginChild("##menu2Child", imgui.ImVec2(665, 105), true)
        if imgui.Button(u8 "�����������##menu2", imgui.ImVec2(160, 20)) then
            sampProcessChatInput("������� ������� �����! � {my:rank}, ��� ���� ��� ������?")
        end
        imgui.SameLine()
        if imgui.Button(u8 "������ � �����������##menu2", imgui.ImVec2(160, 20)) then
            sampProcessChatInput("/givepass " .. tonumber(IDplayer.v))
        end
        imgui.SameLine()
        if imgui.Button(u8 "�������##menu2", imgui.ImVec2(160, 20)) then
            sampProcessChatInput("/expel " .. tonumber(IDplayer.v) .. u8:decode(expelreason.v))
        end
        imgui.SameLine()
        if imgui.Button(u8 "������ ��##menu2", imgui.ImVec2(160, 20)) then
            --sampProcessChatInput("/givewbook " .. tonumber(IDplayer.v))
            imgui.OpenPopup(u8'������ ��##1menu2')
        end
        if imgui.Button(u8 "������� ���. ����������##menu2", imgui.ImVec2(160, 20)) then
            imgui.OpenPopup(u8 "�������##2menu2")
        end
        imgui.SameLine()
        if imgui.Button(u8 "������� � ���.##menu2", imgui.ImVec2(160, 20)) then
            sampProcessChatInput("/invite " .. tonumber(IDplayer.v))
        end
        imgui.SameLine()
        if imgui.Button(u8 "������� �� ���.##menu2", imgui.ImVec2(160, 20)) then
            imgui.OpenPopup(u8 "�������##1menu2")
        end
        imgui.SameLine()
        if imgui.Button(u8 "������ �������##menu2", imgui.ImVec2(160, 20)) then
            imgui.OpenPopup(u8 "�������##menu2")
        end
        if imgui.Button(u8 "����� �������##menu2", imgui.ImVec2(160, 20)) then
            sampProcessChatInput("/unfwarn " .. tonumber(IDplayer.v))
        end
        imgui.SameLine()
        if imgui.Button(u8 "�������� ���������##menu2", imgui.ImVec2(160, 20)) then
            imgui.OpenPopup(u8 "���������##menu2")
        end
        imgui.SameLine()
        if imgui.Button(u8 "�������� �������##menu2", imgui.ImVec2(160, 20)) then
            sampProcessChatInput("/showvisit " .. tonumber(IDplayer.v))
        end
        imgui.SameLine()
        if imgui.Button(u8 "���������� �� ���##menu2", imgui.ImVec2(160, 20)) then
            imgui.OpenPopup(u8 "�������##menu5")
        end
        if imgui.BeginPopupModal(u8 "������ ��##1menu2", _, imgui.WindowFlags.AlwaysAutoResize) then
            imgui.PushItemWidth(150)
            imgui.InputText(u8 "��������� ��##������ ��", ReasonUval)
            imgui.PopItemWidth()
            if imgui.Button(u8 "���������##������ ��", imgui.ImVec2(200, 20)) then
                sampProcessChatInput("/givewbook " .. tonumber(IDplayer.v) .. " " .. ReasonUval.v)
                imgui.CloseCurrentPopup()
                ReasonUval.v = ""
            end
            imgui.SameLine()
            if imgui.Button(u8 "�������##������ ��", imgui.ImVec2(200, 20)) then
                imgui.CloseCurrentPopup()
                ReasonUval.v = ""
            end
            imgui.EndPopup()
        end
        if imgui.BeginPopupModal(u8 "�������##1menu2", _, imgui.WindowFlags.AlwaysAutoResize) then
            imgui.PushItemWidth(150)
            imgui.InputText(u8 "������� ����������##������� �� ���.", ReasonUval)
            imgui.PopItemWidth()
            if imgui.Button(u8 "���������##������� �� ���.", imgui.ImVec2(200, 20)) then
                sampProcessChatInput("/uninvite " .. tonumber(IDplayer.v) .. " " .. ReasonUval.v)
                imgui.CloseCurrentPopup()
                ReasonUval.v = ""
            end
            imgui.SameLine()
            if imgui.Button(u8 "�������##������� �� ���.", imgui.ImVec2(200, 20)) then
                imgui.CloseCurrentPopup()
                ReasonUval.v = ""
            end
            imgui.EndPopup()
        end
        if imgui.BeginPopupModal(u8 "�������##2menu2", _, imgui.WindowFlags.AlwaysAutoResize) then
            imgui.PushItemWidth(150)
            imgui.InputText(u8 "������� ����������##������� ���. ����������", ReasonUval)
            imgui.PopItemWidth()
            if imgui.Button(u8 "���������##������� ���. ����������", imgui.ImVec2(200, 20)) then
                sampProcessChatInput("/demoute " .. tonumber(IDplayer.v) .. " " .. ReasonUval.v)
                imgui.CloseCurrentPopup()
                ReasonUval.v = ""
            end
            imgui.SameLine()
            if imgui.Button(u8 "�������##������� ���. ����������", imgui.ImVec2(200, 20)) then
                imgui.CloseCurrentPopup()
                ReasonUval.v = ""
            end
            imgui.EndPopup()
        end
        if imgui.BeginPopupModal(u8 "�������##menu2", _, imgui.WindowFlags.AlwaysAutoResize) then
            imgui.PushItemWidth(150)
            imgui.InputText(u8 "������� ��������##3menu2", ReasonUval)
            imgui.PopItemWidth()
            if imgui.Button(u8 "���������##3menu2", imgui.ImVec2(200, 20)) then
                sampProcessChatInput("/fwarn " .. tonumber(IDplayer.v) .. " " .. ReasonUval.v)
                imgui.CloseCurrentPopup()
                ReasonUval.v = ""
            end
            imgui.SameLine()
            if imgui.Button(u8 "�������##3menu2", imgui.ImVec2(200, 20)) then
                imgui.CloseCurrentPopup()
                ReasonUval.v = ""
            end
            imgui.EndPopup()
        end
        if imgui.BeginPopupModal(u8 "���������##menu2", _, imgui.WindowFlags.AlwaysAutoResize) then
            imgui.PushItemWidth(70)
            imgui.InputInt(u8 "����� ���������##4menu2", giverankInt)
            imgui.PopItemWidth()
            if giverankInt.v > 9 then
                giverankInt.v = 9
            end
            if giverankInt.v < 1 then
                giverankInt.v = 1
            end
            if imgui.Button(u8 "���������##4menu2", imgui.ImVec2(200, 20)) then
                sampProcessChatInput("/giverank " .. tonumber(IDplayer.v) .. " " .. giverankInt.v)
                imgui.CloseCurrentPopup()
                ReasonUval.v = ""
            end
            imgui.SameLine()
            if imgui.Button(u8 "�������##4menu2", imgui.ImVec2(200, 20)) then
                imgui.CloseCurrentPopup()
                ReasonUval.v = ""
            end
            imgui.EndPopup()
        end
        if imgui.BeginPopupModal(u8 "�������##menu5", _, imgui.WindowFlags.AlwaysAutoResize) then
            imgui.PushItemWidth(70)
            imgui.InputInt(u8 "���� �������##5menu2", freeInt)
            imgui.PopItemWidth()
            if imgui.Button(u8 "����������##5menu2", imgui.ImVec2(200, 20)) then
                sampProcessChatInput("/free " .. tonumber(IDplayer.v) .. " " .. freeInt.v)
                imgui.CloseCurrentPopup()
            end
            imgui.SameLine()
            if imgui.Button(u8 "�������##5menu2", imgui.ImVec2(200, 20)) then
                imgui.CloseCurrentPopup()
            end
            imgui.EndPopup()
        end
        if #cfg.Binds_Name > 0 then
            for key_bind, name_bind in pairs(cfg.Binds_Name) do
                if buttonCount == 1 or buttonCount == 2 or buttonCount == 3 then
                    imgui.SameLine()
                    if imgui.Button(u8(name_bind) .. "##" .. key_bind, imgui.ImVec2(160, 20)) then
                        play_bind(key_bind)
                        window.v = false
                    end
                elseif buttonCount == 0 then
                    if imgui.Button(u8(name_bind) .. "##" .. key_bind, imgui.ImVec2(160, 20)) then
                        play_bind(key_bind)
                        window.v = false
                    end
                else
                    if imgui.Button(u8(name_bind) .. "##" .. key_bind, imgui.ImVec2(160, 20)) then
                        play_bind(key_bind)
                        window.v = false
                    end
                end
                if buttonCount == 4 then
                    buttonCount = 0
                end
                buttonCount = buttonCount + 1
            end
         end
        imgui.EndChild()
        imgui.SetCursorPosX((imgui.GetWindowWidth() - 200) / 2)
        if imgui.Button(u8 "�������##menu2", imgui.ImVec2(150, 20)) then
            dopmenu.v = false
            imgui.ShowCursor = false
        end
        imgui.SameLine()
        if imgui.Button(fa.ICON_FA_ARROWS_ALT, imgui.ImVec2(23, 20)) then
            lua_thread.create(
                function()
                    showCursor(true, true)
                    checkCursor_menu = true
                    sampSetCursorMode(4)
                    GHsms("������� {ADFF2F}ENTER{FFFFFF} ����� ��������� �������")
                    while checkCursor_menu do
                        local cX, cY = getCursorPos()
                        posX, posY = cX, cY
                        if isKeyDown(13) then
                            sampSetCursorMode(0)
                            cfg.Pos.x, cfg.Pos.y = posX, posY
                            checkCursor_menu = false
                            showCursor(false, false)
                            inicfg.save(cfg, "Government Helper.ini")
                        end
                        wait(0)
                    end
                end
            )
        else
            imgui.Hint(u8 "�������� �������������� ����")
        end
        imgui.SameLine()
        if imgui.Button(fa.ICON_FA_RETWEET, imgui.ImVec2(27, 20)) then
            cfg.Pos.x, cfg.Pos.y = 625, 915
            inicfg.save(cfg, "Government Helper.ini")
            posX, posY = cfg.Pos.x, cfg.Pos.y
        else
            imgui.Hint(u8 "������� ���� � ����������� ��������������")
        end
        imgui.End()
    end
    if window.v then
        local sw, sh = getScreenResolution()
        imgui.SetNextWindowPos(imgui.ImVec2(sw / 2, sh / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
        imgui.Begin(
            u8 "##MainMenu",
            _,
            imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoTitleBar +
                imgui.WindowFlags.AlwaysAutoResize
        )
        imgui.BeginGroup()
        imgui.PushFont(fontsize50)
        imgui.TextColored(imgui.GetStyle().Colors[imgui.Col.CheckMark], fa.ICON_FA_UNIVERSITY)
        imgui.PopFont()
        imgui.SameLine()
        imgui.PushFont(fontsize501)
        imgui.TextColoredRGB("{fff332}Government Helper")
        imgui.PopFont()
        imgui.SameLine()
        imgui.PushFont(fontsize5011)
        imgui.TextColoredRGB("{fff332}Remade")
        imgui.PopFont()
        imgui.SetCursorPos(imgui.ImVec2(imgui.GetWindowWidth() - 40, 25))
        if imgui.CloseButton(12) then window.v = not window.v end
        imgui.EndGroup()
        imgui.BeginGroup()
        imgui.BeginChild("up", imgui.ImVec2(250, 150), true)
        imgui.SetCursorPosY(25)
        imgui.PushFont(fontsize50)
        imgui.CenterText(fa.ICON_FA_USER_CIRCLE, imgui.GetStyle().Colors[imgui.Col.CheckMark])
        imgui.PopFont()
        imgui.Dummy(imgui.ImVec2(0, 2.5))
        local _, id = sampGetPlayerIdByCharHandle(PLAYER_PED)
        local nick = sampGetPlayerNickname(id)
        imgui.CenterTextColoredRGB(sc .. string.format("%s[%d]", nick, id))
        imgui.CenterTextColoredRGB(sc .. cfg.Settings.rank .. " " .. "[" .. cfg.Settings.rankAndNumber .. "]")
        imgui.Dummy(imgui.ImVec2(0, 2.5))
        imgui.SetCursorPosX((imgui.GetWindowWidth() - 150) / 2)
        if imgui.Button(u8 "�������� ������", imgui.ImVec2(150, 20)) then
            checkOrg()
        else
            imgui.Hint(u8 "�������, ����� �������� ������ ����������.")
        end
        imgui.EndChild()
        if imgui.Button(fa.ICON_FA_USER .. u8 " ������ ��������������", imgui.ImVec2(250, 30)) then
            menu = 1
        end
        if imgui.Button(fa.ICON_FA_INFO_CIRCLE .. u8 " ������", imgui.ImVec2(250, 30)) then
            menu = 2
        end
        if imgui.Button(fa.ICON_FA_RETWEET .. u8 " �������� �����������", imgui.ImVec2(250, 30)) then
            menu = 4
        end
        if imgui.Button(fa.ICON_FA_COG .. u8 " ���������", imgui.ImVec2(250, 30)) then
            menu = 3
        end
        imgui.EndGroup()
        imgui.SameLine()
        imgui.BeginGroup()
        imgui.BeginChild("right", imgui.ImVec2(400, 300), true)
        if SS.v then imgui.SmoothScroll("main_window", speed.v)
        end
        if menu == 1 then
                imgui.CenterTextColoredRGB("� ������ ���� �� ������ ���������/��������/�������\n���.����� ��� ���� ��������������\n" .. sc .. '(/ghm [id] | ��� + Q �� ������)')
            imgui.CenterTextColoredRGB('��� ������� �� �������� �����, �� ����� ������������.')
            imgui.Dummy(imgui.ImVec2(0, 2.5))
            imgui.Separator()
            imgui.Dummy(imgui.ImVec2(0, 2.5))
            if #cfg.Binds_Name > 0 then
                for key_bind, name_bind in pairs(cfg.Binds_Name) do
                    if imgui.Button(u8(name_bind) .. "##" .. key_bind, imgui.ImVec2(312, 30)) then
                        play_bind(key_bind)
                        window.v = false
                    end
                    imgui.SameLine()
                    if imgui.Button(fa.ICON_FA_PEN .. "##" .. key_bind, imgui.ImVec2(30, 30)) then
                        EditOldBind = true
                        name_old_bild = cfg.Binds_Name[key_bind]
                        getpos = key_bind
                        binder_delay.v = cfg.Binds_Deleay[key_bind]
                        local returnwrapped = tostring(cfg.Binds_Action[key_bind]):gsub("~", "\n")
                        text_binder.v = u8(returnwrapped)
                        binder_name.v = tostring(u8(cfg.Binds_Name[key_bind]))
                        imgui.OpenPopup(u8 "������")
                    end
                    imgui.SameLine()
                    if imgui.Button(fa.ICON_FA_TRASH .. "##" .. key_bind, imgui.ImVec2(30, 30)) then
                        GHsms("���� {FFF332}�" .. cfg.Binds_Name[key_bind] .. "�{FFFFFF} �����!")
                        table.remove(cfg.Binds_Name, key_bind)
                        table.remove(cfg.Binds_Action, key_bind)
                        table.remove(cfg.Binds_Deleay, key_bind)
                        inicfg.save(cfg, "Government Helper.ini")
                    end
                end
            else
                imgui.CenterTextColoredRGB("����� ���� ���� ����� ������.")
                imgui.CenterTextColoredRGB("�� ����� �������!")
                imgui.SetCursorPosX((imgui.GetWindowWidth() - 25) / 2)
                imgui.PushFont(fontsize50)
                imgui.Text(fa.ICON_FA_CHILD)
                imgui.PopFont()
            end
            imgui.Dummy(imgui.ImVec2(0, 2.5))
            imgui.Separator()
            imgui.Dummy(imgui.ImVec2(0, 2.5))
            if imgui.Button(fa.ICON_FA_PLUS_CIRCLE .. u8 " ������� ����", imgui.ImVec2(-1, 30)) then
                imgui.OpenPopup(u8 "������")
                binder_delay.v = 2500
            end
        end

        if
            imgui.BeginPopupModal(
                u8 "������",
                false,
                imgui.WindowFlags.NoResize + imgui.WindowFlags.AlwaysAutoResize + imgui.WindowFlags.NoTitleBar
            )
         then
            imgui.BeginChild("##EditBinder", imgui.ImVec2(600, 337), true)
            imgui.PushItemWidth(150)
            imgui.InputInt(u8("�������� ����� �������� � �������������"), binder_delay)
            imgui.SameLine()
            imgui.Vopros()
            imgui.Hint(u8 "�� ������ 60.000 ms!\n(1 sec = 1000 ms)")
            imgui.PopItemWidth()
            if binder_delay.v <= 0 then
                binder_delay.v = 1
            elseif binder_delay.v >= 60001 then
                binder_delay.v = 60000
            end
            imgui.SameLine()
            if imgui.Button(u8 "��������� ����##LocalTag", imgui.ImVec2(140, 20)) then
                imgui.OpenPopup(u8 "��������� ����")
            end
            localtag()
            imgui.InputTextMultiline("##EditMultiline", text_binder, imgui.ImVec2(-1, 250))
            imgui.Text(u8 "�������� ����� (�����������):")
            imgui.SameLine()
            imgui.PushItemWidth(200)
            imgui.InputText("##binder_name", binder_name)
            imgui.PopItemWidth()

            if #binder_name.v > 0 and #text_binder.v > 0 then
                imgui.SameLine()
                if imgui.Button(u8 "���������##bind1", imgui.ImVec2(-1, 20)) then
                    if not EditOldBind then
                        refresh_text = text_binder.v:gsub("\n", "~")
                        table.insert(cfg.Binds_Name, u8:decode(binder_name.v))
                        table.insert(cfg.Binds_Action, u8:decode(refresh_text))
                        table.insert(cfg.Binds_Deleay, binder_delay.v)
                        if inicfg.save(cfg, "Government Helper.ini") then
                            GHsms("���� {FFF332}�" .. u8:decode(binder_name.v) .. "�{FFFFFF} ������� ��������!")
                            binder_name.v, text_binder.v = "", ""
                        end
                        imgui.CloseCurrentPopup()
                    else
                        refresh_text = text_binder.v:gsub("\n", "~")
                        table.insert(cfg.Binds_Name, getpos, u8:decode(binder_name.v))
                        table.insert(cfg.Binds_Action, getpos, u8:decode(refresh_text))
                        table.insert(cfg.Binds_Deleay, getpos, binder_delay.v)
                        table.remove(cfg.Binds_Name, getpos + 1)
                        table.remove(cfg.Binds_Action, getpos + 1)
                        table.remove(cfg.Binds_Deleay, getpos + 1)
                        if inicfg.save(cfg, "Government Helper.ini") then
                            GHsms("���� {FFF332}�" .. name_old_bild .. "�{FFFFFF} ������� ��������������!")
                            binder_name.v, text_binder.v = "", ""
                        end
                        EditOldBind = false
                        imgui.CloseCurrentPopup()
                    end
                end
            else
                imgui.SameLine()
                imgui.DisableButton(u8 "���������##bind2", imgui.ImVec2(-1, 20))
                imgui.Hint(u8 "��������� �� ��� ������!")
            end

            if imgui.Button(u8 "�������", imgui.ImVec2(-1, 20)) then
                if not EditOldBind then
                    imgui.CloseCurrentPopup()
                    binder_name.v, text_binder.v = "", ""
                else
                    EditOldBind = false
                    imgui.CloseCurrentPopup()
                    binder_name.v, text_binder.v = "", ""
                end
            end
            imgui.EndChild()
            imgui.EndPopup()
        end
        if menu == 2 then
            imgui.CenterTextColoredRGB(
                "� ������ ���� ������������ ������� ������� ���������\n����������� �������������, ������� � �������\n������� �������� ����-���������."
            )
            imgui.Dummy(imgui.ImVec2(0, 2.5))
            imgui.Separator()
            imgui.Dummy(imgui.ImVec2(0, 2.5))
            imgui.PushFont(fontsize5012)
            imgui.CenterTextColoredRGB(sc .. "������� � ������� �������")
            imgui.PopFont()
            imgui.CenterTextColoredRGB(sc .. "/gh {FFFFFF}- �������� ���� �������")
            imgui.CenterTextColoredRGB(sc .. "/gha {FFFFFF}- �������� ����� �������� ����������� � ���")
            imgui.CenterTextColoredRGB(sc .. "/ghm [id] {FFFFFF}- ���� �������������� � �������")
            imgui.CenterTextColoredRGB("{FFFFFF}���� �� ����� �������� ID ������, �� ����� ������ 0.")
            imgui.CenterTextColoredRGB(sc .. "��� + Q {FFFFFF}- ���� �������������� � �������")
            imgui.CenterTextColoredRGB("{FFFFFF}�������� ��� ����� ������ �� ������!")
            imgui.Dummy(imgui.ImVec2(0, 2.5))
            imgui.Separator()
            imgui.Dummy(imgui.ImVec2(0, 2.5))
            imgui.PushFont(fontsize5012)
            imgui.CenterTextColoredRGB(sc .. "�������������� � ������������")
            imgui.PopFont()
            imgui.CenterTextColoredRGB(sc .. "/invite [id] {FFFFFF}- ������� �������� � �����������")
            imgui.CenterTextColoredRGB(sc .. "/uninvite [id] [reason] {FFFFFF}- ������� ���������� �� �����������")
            imgui.CenterTextColoredRGB(sc .. "/uninviteoff [id] [reason] {FFFFFF}- ������� ���������� � ��������")
            imgui.CenterTextColoredRGB(sc .. "/giverank [id] [rank] {FFFFFF}- �������� ���� ����������")
            imgui.CenterTextColoredRGB(sc .. "/fwarn [id] [reason] {FFFFFF}- ������ ������� ����������")
            imgui.CenterTextColoredRGB(sc .. "/unfwarn [id] {FFFFFF}- ����� ������� ����������")
            imgui.Dummy(imgui.ImVec2(0, 2.5))
            imgui.Separator()
            imgui.Dummy(imgui.ImVec2(0, 2.5))
            imgui.PushFont(fontsize5012)
            imgui.CenterTextColoredRGB(sc .. "�������������� � ��������")
            imgui.PopFont()
            imgui.CenterTextColoredRGB(sc .. "/expel [id] [reason] {FFFFFF}- ������� �������� �� ������ �������������")
            imgui.CenterTextColoredRGB(sc .. "/givepass [id] {FFFFFF}- ������ ������� ��������")
            imgui.CenterTextColoredRGB(sc .. "/givevisa [id] {FFFFFF}- ������ ���� ��������")
            imgui.CenterTextColoredRGB(sc .. "/givewbook [id] [price (100$ - 50.000$)]{FFFFFF}- ������ �������� ������ ��������")
            imgui.CenterTextColoredRGB(sc .. "/demoute [id] [reason] {FFFFFF}- ������� ���. ����������")
            imgui.CenterTextColoredRGB(sc .. "/free [id] [price] {FFFFFF}- ���������� �� ���")
            imgui.CenterTextColoredRGB(sc .. "/showvisit [id] {FFFFFF}- �������� ������� ��������")
            imgui.Dummy(imgui.ImVec2(0, 2.5))
        end
        if menu == 4 then
                imgui.PushFont(fontsize5012)
            imgui.CenterTextColoredRGB(sc .. "�������� �����������")
            imgui.PopFont()
            imgui.CenterTextColoredRGB("� ������ ���� ������������ ���. �����������,\n���������� � Government Helper 1.5f.")
            imgui.Dummy(imgui.ImVec2(0, 2.5))
            imgui.Separator()
            imgui.Dummy(imgui.ImVec2(0, 2.5))
            if imgui.CollapsingHeader(u8'����-��� /giverank') then
                if imgui.Checkbox(u8 "##adv", autolog) then
                    cfg.Settings.autolog = autolog.v
                    inicfg.save(cfg, "Government Helper.ini")
                end
                imgui.Hint(
                    u8("��� ��������� ����� ��������� ������ � ��� ����� ������ ����� ������������� ���������� ���, ������� �� ���������� ����.")
                )
                imgui.SameLine()
                imgui.Text(u8("�������������� ���"))
                imgui.Hint(
                    u8("��� ��������� ����� ��������� ������ � ��� ����� ������ ����� ������������� ���������� ���, ������� �� ���������� ����.")
                )
                imgui.Separator()
                imgui.Text(u8'��� ��������������� ����:')
                imgui.PushItemWidth(-1)
                    if imgui.InputText(u8"", autologvid) then
                        cfg.Settings.autologvid = u8:decode(autologvid.v)
                        inicfg.save(cfg, "Government Helper.ini")
                    end
                    imgui.PopItemWidth()
                    imgui.Text(u8'��� �������� ������������ ��������� ����!')
                    imgui.Hint(
                    u8("�������� ������ ��, ��� �������� � �������� �� ���������")
                )
                imgui.Separator()
                    if imgui.Button(u8 "��������� ����##LocalTag", imgui.ImVec2(150, 20)) then
                imgui.OpenPopup(u8 "��������� ����")
                end
                localtag()
                imgui.SameLine()
                if imgui.Button(u8 "��������", imgui.ImVec2(150, 20)) then
                cfg.Settings.autologvid = '{my:name} | {my:rank} | GOV | {date} | {timeo} | {player:name} | � X �� {player:rank} (X)'
                        autologvid.v = cfg.Settings.autologvid
                        inicfg.save(cfg, "Government Helper.ini")
                end
            end
             if imgui.CollapsingHeader(u8'������ ���������') then
                if imgui.Checkbox(u8 "##adv", advoverlay) then
                    cfg.Settings.advoverlay = advoverlay.v
                    inicfg.save(cfg, "Government Helper.ini")
                end
                imgui.Hint(
                    u8("��� ��������� � ��� ���������� ������� � ����������� � ����������� ������� � ���.")
                )
                imgui.SameLine()
                imgui.Text(u8("������ ����������� �� ������"))
                imgui.Hint(
                    u8("��� ��������� � ��� ���������� ������� � ����������� � ����������� ������� � ���.")
                )
                imgui.TextColoredRGB('��� �� �������� ������ ��������� �������� ����� ��������!\n'.. sc .. '/gha {FFFFFF}- �������� ����� �������� ����������� � ���')
            end
            if imgui.CollapsingHeader(u8'�������� ������') then
                if imgui.Checkbox(u8 "##FIXDOORS", fixdoor) then
                    cfg.Settings.fixdoor = fixdoor.v
                    inicfg.save(cfg, "Government Helper.ini")
                end
                imgui.Hint(
                    u8(
                        '������ ���� ��������� ��������, ����� ��� ������� ������� "H" ����� ��� ������ ����� �� ��������� � ������� ����.'
                    )
                )
                imgui.SameLine()
                imgui.Text(u8("���� �������� ������"))
                imgui.Hint(
                    u8(
                        '������ ���� ��������� ��������, ����� ��� ������� ������� "H" ����� ��� ������ ����� �� ��������� � ������� ����.'
                    )
                )
                if imgui.Checkbox(u8 "##BINDOORS", bindopengate) then
                    cfg.Settings.bindopengate = bindopengate.v
                    inicfg.save(cfg, "Government Helper.ini")
                end
                imgui.Hint(
                    u8(
                        "���� ��������: ��� �������� ����� ����� ������������� � ��� ���������:\n/me ������ ID �����, �������� � � �����������."
                    )
                )
                imgui.SameLine()
                imgui.Text(u8("��������� ��� �������� ������"))
                imgui.Hint(
                    u8(
                        "���� ��������: ��� �������� ����� ����� ������������� � ��� ���������:\n/me ������ ID �����, �������� � � �����������."
                    )
                )
            end
            if imgui.CollapsingHeader(u8'������') then
                if imgui.Checkbox(u8 "##NRPCHAT", nonrpchat) then
                cfg.Settings.nonrpchat = nonrpchat.v
                inicfg.save(cfg, "Government Helper.ini")
                end
                imgui.Hint(
                    u8("��� ��������� ��� ������� ������� ������ ����� ������������ ����� ������� �� ������� � NonRP ���.")
                )
                imgui.SameLine()
                imgui.Text(u8("NonRP ��� ��� ������� ������"))
                imgui.Hint(
                    u8("��� ��������� ��� ������� ������� ������ ����� ������������ ����� ������� �� ������� � NonRP ���.")
                )
            end
        end
        if menu == 3 then
            imgui.PushFont(fontsize5012)
            imgui.CenterTextColoredRGB(sc .. "��������� �������")
            imgui.PopFont()
            imgui.CenterTextColoredRGB("� ������ ���� �� ������ �������� ���������\n�������, � ����� ������ ���������� � ��.")
            imgui.Dummy(imgui.ImVec2(0, 2.5))
            imgui.Separator()
            imgui.Dummy(imgui.ImVec2(0, 2.5))
            if imgui.Checkbox(u8 "##RP", RP) then
                cfg.Settings.RP = RP.v
                if inicfg.save(cfg, "Government Helper.ini") then
                    GHsms("������ ��� ������������, ����� ��������� �������� � ����!")
                    showCursor(false)
                    thisScript():reload()
                end
            else
                imgui.Hint(u8 "����� ��������� ����������� ����� ������������� ������.")
            end
            imgui.SameLine()
            imgui.Text(u8("�������������� �� ���������"))
            imgui.Hint(u8 "����� ��������� ����������� ����� ������������� ������.")
            imgui.PushItemWidth(150)
                if imgui.InputText(u8"������� /expel", expelreason) then
                    cfg.Settings.expelreason = u8:decode(expelreason.v)
                    inicfg.save(cfg, "Government Helper.ini")
                end
                imgui.PopItemWidth()
                imgui.Hint(u8 "��� ������� ����� ������������ � �������, ��� ��������� ��� \"{expel:reason}\".")
            imgui.Text(u8("�������� � �������������� �� ����������:"))
            imgui.PushItemWidth(150)
            if imgui.SliderFloat("##waitRP", waitRP, 0.5, 10.0, u8 "%0.2f �.") then
                if waitRP.v < 0.5 then
                    waitRP.v = 0.5
                end
                if waitRP.v > 10.0 then
                    waitRP.v = 10.0
                end
                cfg.Settings.waitRP = waitRP.v
                inicfg.save(cfg, "Government Helper.ini")
            end
            imgui.PopItemWidth()
            imgui.SameLine()
            if imgui.Button(u8 "1.5 ���.", imgui.ImVec2(65, 20)) then
                waitRP.v = 1.5
                cfg.Settings.waitRP = waitRP.v
                inicfg.save(cfg, "Government Helper.ini")
            end
            imgui.SameLine()
            if imgui.Button(u8 "2.5 ���.", imgui.ImVec2(65, 20)) then
                waitRP.v = 2.5
                cfg.Settings.waitRP = waitRP.v
                inicfg.save(cfg, "Government Helper.ini")
            end
            imgui.SameLine()
            if imgui.Button(u8 "3.5 ���.", imgui.ImVec2(65, 20)) then
                waitRP.v = 3.5
                cfg.Settings.waitRP = waitRP.v
                inicfg.save(cfg, "Government Helper.ini")
            end
            imgui.Text(u8("��� ������ ���������:"))
            if imgui.RadioButton(u8 "�������##sex", sex, 1) then
                cfg.Settings.sex = sex.v
                inicfg.save(cfg, "Government Helper.ini")
            end
            if imgui.RadioButton(u8 "�������##sex", sex, 2) then
                cfg.Settings.sex = sex.v
                inicfg.save(cfg, "Government Helper.ini")
            end
            imgui.Dummy(imgui.ImVec2(0, 2.5))
            imgui.Separator()
            imgui.Dummy(imgui.ImVec2(0, 2.5))
            imgui.PushFont(fontsize5012)
            imgui.CenterTextColoredRGB(sc .. "���������� � �������")
            imgui.PopFont()
            imgui.CenterTextColoredRGB('������� ������ �������:' .. sc .. ' 1.5f')
            imgui.CenterTextColoredRGB("������ �������:")
            imgui.CenterTextColoredRGB(sc .. "Rice. [Government Helper 1.4]")
            imgui.CenterTextColoredRGB(sc .. "fakelag [Government Helper Remade]")
            imgui.CenterTextColoredRGB("{868686}����� ������ ��� ���� �����������?\n{868686}������ � ���� �� ������.")
            imgui.Dummy(imgui.ImVec2(0, 2.5))
            imgui.Separator()
            imgui.Dummy(imgui.ImVec2(0, 2.5))
            imgui.PushFont(fontsize5012)
            imgui.CenterTextColoredRGB(sc .. "�������� �� ��������")
            imgui.PopFont()
            if imgui.Button(u8 "������������� ��������� ���������", imgui.ImVec2(-1, 30)) then
                inicfg.save(cfg, "Government Helper.ini")
                GHsms("��������� ������� ���� ������������� ���������!")
            end
            if imgui.Button(u8 "������������� ������", imgui.ImVec2(-1, 30)) then
                showCursor(false)
                thisScript():reload()
            end
            if imgui.Button(u8 "��������� ������", imgui.ImVec2(-1, 30)) then
                showCursor(false)
                GHsms("������ ��������.")
                thisScript():unload()
            end
            if imgui.Button(u8 "�������� ���������", imgui.ImVec2(-1, 30)) then
                imgui.OpenPopup(u8 "##sbros")
            end

            if
                imgui.BeginPopupModal(
                    u8 "##sbros",
                    false,
                    imgui.WindowFlags.NoResize + imgui.WindowFlags.AlwaysAutoResize + imgui.WindowFlags.NoTitleBar
                )
             then
                imgui.TextColoredRGB("�� �������, ��� ������ {FF0000}��������{FFFFFF} ��������� �������?")
                if imgui.Button(u8 "�����������", imgui.ImVec2(160, 20)) then
                    if os.remove(fileconfig) then
                        GHsms("��������� ���� ������� ��������!")
                        showCursor(false)
                        thisScript():reload()
                    end
                end
                imgui.SameLine()
                if imgui.Button(u8 "������", imgui.ImVec2(160, 20)) then
                    imgui.CloseCurrentPopup()
                end
                imgui.EndPopup()
            end
        end
        imgui.EndChild()
        imgui.EndGroup()
        imgui.End()
    end
end

function theme()
    imgui.SwitchContext()
    local style = imgui.GetStyle()
    local colors = style.Colors
    local clr = imgui.Col
    local ImVec4 = imgui.ImVec4
    local ImVec2 = imgui.ImVec2

    style.WindowPadding = imgui.ImVec2(8, 8)
    style.WindowRounding = 5
    style.ChildWindowRounding = 5
    style.FramePadding = imgui.ImVec2(5, 3)
    style.FrameRounding = 2.5
    style.ItemSpacing = imgui.ImVec2(5, 4)
    style.ItemInnerSpacing = imgui.ImVec2(4, 4)
    style.IndentSpacing = 21
    style.ScrollbarSize = 10.0
    style.ScrollbarRounding = 13
    style.GrabMinSize = 8
    style.GrabRounding = 1
    style.WindowTitleAlign = imgui.ImVec2(0.5, 0.5)
    style.ButtonTextAlign = imgui.ImVec2(0.5, 0.5)

    colors[clr.Text] =                  ImVec4(1.00, 1.00, 1.00, 1)
    colors[clr.TextDisabled] =      ImVec4(0.36, 0.42, 0.47, 1.00)
    colors[clr.WindowBg] =          ImVec4(0.11, 0.15, 0.17, 1.00)
    colors[clr.ChildWindowBg] =         ImVec4(0.13, 0.16, 0.19, 1.00)
    colors[clr.PopupBg] =               ImVec4(0.13, 0.16, 0.19, 0.94)
    colors[clr.Border] =                ImVec4(1, 0.95, 0.2, 0.50)
    colors[clr.BorderShadow] =      ImVec4(0.00, 0.00, 0.00, 0.00)
    colors[clr.FrameBg] =               ImVec4(0.08, 0.1, 0.12, 1.00)
    colors[clr.FrameBgHovered] =    ImVec4(0.12, 0.20, 0.28, 1.00)
    colors[clr.FrameBgActive] =         ImVec4(0.09, 0.12, 0.14, 1.00)
    colors[clr.TitleBg] =               ImVec4(0.09, 0.12, 0.14, 0.65)
    colors[clr.TitleBgActive] =         ImVec4(0.71, 0.66, 0, 1.00)
    colors[clr.TitleBgCollapsed] =  ImVec4(0.00, 0.00, 0.00, 0.51)
    colors[clr.MenuBarBg] =             ImVec4(0.15, 0.18, 0.22, 1.00)
    colors[clr.ScrollbarBg] =       ImVec4(0.02, 0.02, 0.02, 0.39)
    colors[clr.ScrollbarGrab] =         ImVec4(0.20, 0.25, 0.29, 1.00)
    colors[clr.ScrollbarGrabHovered] = ImVec4(0.18, 0.22, 0.25, 1.00)
    colors[clr.ScrollbarGrabActive] = ImVec4(0.09, 0.21, 0.31, 1.00)
    colors[clr.ComboBg] = ImVec4(0.20, 0.25, 0.29, 1.00)
    colors[clr.CheckMark] = ImVec4(1, 0.95, 0.2, 1.00)
    colors[clr.SliderGrab] = ImVec4(1, 0.95, 0.2, 1.00)
    colors[clr.SliderGrabActive] = ImVec4(0.9, 0.85, 0.1, 1.00)
    colors[clr.Button] = ImVec4(0.08, 0.1, 0.12, 1.00)
    colors[clr.ButtonHovered] = ImVec4(0.71, 0.66, 0, 1.00)
    colors[clr.ButtonActive] = ImVec4(1, 0.95, 0.2, 1.00)
    colors[clr.Header] = ImVec4(0.09, 0.12, 0.14, 1.00)
    colors[clr.HeaderHovered] = ImVec4(0.71, 0.66, 0, 1.00)
    colors[clr.HeaderActive] = ImVec4(0.54, 0.5, 0, 1.00)
    colors[clr.Separator] = ImVec4(0.50, 0.50, 0.50, 1.00)
    colors[clr.SeparatorHovered] = ImVec4(0.60, 0.60, 0.70, 1.00)
    colors[clr.SeparatorActive] = ImVec4(0.70, 0.70, 0.90, 1.00)
    colors[clr.ResizeGrip] = ImVec4(0.68, 0.98, 0.26, 0.25)
    colors[clr.ResizeGripHovered] = ImVec4(0.72, 0.98, 0.26, 0.67)
    colors[clr.ResizeGripActive] = ImVec4(0.06, 0.05, 0.07, 1.00)
    colors[clr.CloseButton] = ImVec4(0.40, 0.39, 0.38, 0.16)
    colors[clr.CloseButtonHovered] = ImVec4(0.40, 0.39, 0.38, 0.39)
    colors[clr.CloseButtonActive] = ImVec4(0.40, 0.39, 0.38, 1.00)
    colors[clr.PlotLines] = ImVec4(0.61, 0.61, 0.61, 1.00)
    colors[clr.PlotLinesHovered] = ImVec4(1.00, 0.43, 0.35, 1.00)
    colors[clr.PlotHistogram] = ImVec4(0.90, 0.70, 0.00, 1.00)
    colors[clr.PlotHistogramHovered] = ImVec4(1.00, 0.60, 0.00, 1.00)
    colors[clr.TextSelectedBg] = ImVec4(1, 0.95, 0.2, 0.43)
    colors[clr.ModalWindowDarkening] = ImVec4(1.00, 0.98, 0.95, 0.73)
end
theme()

function imgui.CenterText(text, color)
    color = color or imgui.GetStyle().Colors[imgui.Col.Text]
    local width = imgui.GetWindowWidth()
    for line in text:gmatch("[^\n]+") do
        local lenght = imgui.CalcTextSize(line).x
        imgui.SetCursorPosX((width - lenght) / 2)
        imgui.TextColored(color, line)
    end
end

function Search3Dtext(x, y, z, radius, patern)
    local text = ""
    local color = 0
    local posX = 0.0
    local posY = 0.0
    local posZ = 0.0
    local distance = 0.0
    local ignoreWalls = false
    local player = -1
    local vehicle = -1
    local result = false

    for id = 0, 2048 do
        if sampIs3dTextDefined(id) then
            local text2, color2, posX2, posY2, posZ2, distance2, ignoreWalls2, player2, vehicle2 =
                sampGet3dTextInfoById(id)
            if getDistanceBetweenCoords3d(x, y, z, posX2, posY2, posZ2) < radius then
                if string.len(patern) ~= 0 then
                    if string.match(text2, patern, 0) ~= nil then
                        result = true
                    end
                else
                    result = true
                end
                if result then
                    text = text2
                    color = color2
                    posX = posX2
                    posY = posY2
                    posZ = posZ2
                    distance = distance2
                    ignoreWalls = ignoreWalls2
                    player = player2
                    vehicle = vehicle2
                    radius = getDistanceBetweenCoords3d(x, y, z, posX, posY, posZ)
                end
            end
        end
    end

    return result, text, color, posX, posY, posZ, distance, ignoreWalls, player, vehicle
end
function play_bind(num)
    lua_thread.create(
        function()
            if num ~= -1 then
                for bp in cfg.Binds_Action[num]:gmatch("[^~]+") do
                    sampSendChat(tostring(bp))
                    wait(cfg.Binds_Deleay[num])
                end
                num = -1
            end
        end
    )
end
function imgui.Hint(text, delay, action)
    if imgui.IsItemHovered() then
        if go_hint == nil then
            go_hint = os.clock() + (delay and delay or 0.0)
        end
        local alpha = (os.clock() - go_hint) * 5
        if os.clock() >= go_hint then
            imgui.PushStyleVar(imgui.StyleVar.WindowPadding, imgui.ImVec2(10, 10))
            imgui.PushStyleVar(imgui.StyleVar.Alpha, (alpha <= 1.0 and alpha or 1.0))
            imgui.PushStyleColor(imgui.Col.PopupBg, imgui.GetStyle().Colors[imgui.Col.PopupBg])
            imgui.BeginTooltip()
            imgui.PushTextWrapPos(700)
            imgui.TextColored(
                imgui.GetStyle().Colors[imgui.Col.ButtonActive],
                fa.ICON_FA_INFO_CIRCLE .. u8 " ���������:"
            )
            imgui.TextUnformatted(text)
            if action ~= nil then
                imgui.TextColored(
                    imgui.GetStyle().Colors[imgui.Col.TextDisabled],
                    "\n" .. fa.ICON_FA_SHARE .. " " .. action
                )
            end
            if not imgui.IsItemVisible() and imgui.GetStyle().Alpha == 1.0 then
                go_hint = nil
            end
            imgui.PopTextWrapPos()
            imgui.EndTooltip()
            imgui.PopStyleColor()
            imgui.PopStyleVar(2)
        end
    end
end

function imgui.DisableButton(text, size)
    imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.0, 0.0, 0.0, 0.2))
    imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.0, 0.0, 0.0, 0.2))
    imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0.0, 0.0, 0.0, 0.2))
    local button = imgui.Button(text, size)
    imgui.PopStyleColor(3)
    return button
end

function imgui.CenterTextColoredRGB(text)
    local width = imgui.GetWindowWidth()
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
        if color:sub(1, 6):upper() == "SSSSSS" then
            local r, g, b = colors[1].x, colors[1].y, colors[1].z
            local a = tonumber(color:sub(7, 8), 16) or colors[1].w * 255
            return ImVec4(r, g, b, a / 255)
        end
        local color = type(color) == "string" and tonumber(color, 16) or color
        if type(color) ~= "number" then
            return
        end
        local r, g, b, a = explode_argb(color)
        return imgui.ImColor(r, g, b, a):GetVec4()
    end

    local render_text = function(text_)
        for w in text_:gmatch("[^\r\n]+") do
            local textsize = w:gsub("{.-}", "")
            local text_width = imgui.CalcTextSize(u8(textsize))
            imgui.SetCursorPosX(width / 2 - text_width.x / 2)
            local text, colors_, m = {}, {}, 1
            w = w:gsub("{(......)}", "{%1FF}")
            while w:find("{........}") do
                local n, k = w:find("{........}")
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
            else
                imgui.Text(u8(w))
            end
        end
    end
    render_text(text)
end

function imgui.SmoothScroll (id, speed, lockX, lockY)
    if imgui._SmoothScroll.pos[id] == nil then
        imgui._SmoothScroll.pos[id] = {x = 0.0, y = 0.0}
    end
    speed = speed or imgui._SmoothScroll.defaultSpeed
    if imgui.IsItemHovered() or (imgui.IsWindowHovered() and not imgui.IsItemHovered()) then
        if not imgui.IsMouseDown(0) then
            if not lockY and imgui.GetIO().MouseWheel ~= 0 and (not isKeyDown(imgui._SmoothScroll.xAxisKey) or lockX) then
                imgui._SmoothScroll.pos[id].y = imgui.GetScrollY() + (-imgui.GetIO().MouseWheel)*speed
            end
            imgui._SmoothScroll.pos[id].y = math.max(math.min(imgui._SmoothScroll.pos[id].y, imgui.GetScrollMaxY()-0), 0)
            imgui.SetScrollY(imgui.GetScrollY() + speed*(imgui._SmoothScroll.pos[id].y - imgui.GetScrollY())/100)

            if not lockX and imgui.GetIO().MouseWheel ~= 0 and (isKeyDown(imgui._SmoothScroll.xAxisKey) or lockY) then
                imgui._SmoothScroll.pos[id].x = imgui.GetScrollX() + (-imgui.GetIO().MouseWheel)*speed
            end
            imgui._SmoothScroll.pos[id].x = math.max(math.min(imgui._SmoothScroll.pos[id].x, imgui.GetScrollMaxX()-0), 0)
            imgui.SetScrollX(imgui.GetScrollX() + speed*(imgui._SmoothScroll.pos[id].x - imgui.GetScrollX())/100)
        else
            imgui._SmoothScroll.pos[id].x = imgui.GetScrollX()
            imgui._SmoothScroll.pos[id].y = imgui.GetScrollY()
        end
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
        if color:sub(1, 6):upper() == "SSSSSS" then
            local r, g, b = colors[1].x, colors[1].y, colors[1].z
            local a = tonumber(color:sub(7, 8), 16) or colors[1].w * 255
            return ImVec4(r, g, b, a / 255)
        end
        local color = type(color) == "string" and tonumber(color, 16) or color
        if type(color) ~= "number" then
            return
        end
        local r, g, b, a = explode_argb(color)
        return imgui.ImColor(r, g, b, a):GetVec4()
    end

    local render_text = function(text_)
        for w in text_:gmatch("[^\r\n]+") do
            local text, colors_, m = {}, {}, 1
            w = w:gsub("{(......)}", "{%1FF}")
            while w:find("{........}") do
                local n, k = w:find("{........}")
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
            else
                imgui.Text(u8(w))
            end
        end
    end
    render_text(text)
end

function imgui.Vopros()
    imgui.TextDisabled(fa.ICON_FA_QUESTION_CIRCLE)
end

function imgui.CloseButton(rad)
    local pos = imgui.GetCursorScreenPos()
    local poss = imgui.GetCursorPos()
    local a, b, c, d = pos.x - rad, pos.x + rad, pos.y - rad, pos.y + rad
    local e, f = poss.x - rad, poss.y - rad
    local DL = imgui.GetWindowDrawList()
    imgui.SetCursorPos(imgui.ImVec2(e, f))
    local result = imgui.InvisibleButton('##CLOSE_BUTTON', imgui.ImVec2(rad * 2, rad * 2))
    DL:AddLine(imgui.ImVec2(a, d), imgui.ImVec2(b, c), 0xFF666666, 3)
    DL:AddLine(imgui.ImVec2(b, d), imgui.ImVec2(a, c), 0xFF666666, 3)
    return result
end

function log(text)
    sampfuncsLog(sc .. "Government-Helper: {FFFFFF}" .. text)
end

function rpNick(id)
    local nick = sampGetPlayerNickname(id)
    if nick:match("_") then
        return nick:gsub("_", " ")
    end
    return nick
end

function checkOrg()
    while not sampIsLocalPlayerSpawned() do
        wait(1000)
    end
    if sampIsLocalPlayerSpawned() then
        getRankInStats = true
        sampSendChat("/stats")
    end
end

function sampev.onSendChat(msg)
        if msg:find("{sex:%A+|%A+}") then
            local male, female = msg:match("{sex:(%A+)|(%A+)}")
            if cfg.Settings.sex == 1 then
                local returnMsg = msg:gsub("{sex:%A+|%A+}", male, 1)
                sampSendChat(tostring(returnMsg))
                return false
            else
                local returnMsg = msg:gsub("{sex:%A+|%A+}", female, 1)
                sampSendChat(tostring(returnMsg))
                return false
            end
        end
        if msg:find("{my:name}") then
            local _, myid = sampGetPlayerIdByCharHandle(PLAYER_PED)
            local returnMsg = msg:gsub("{my:name}", rpNick(myid))
            sampSendChat(returnMsg)
            return false
        end
        if msg:find("{my:id}") then
            local _, myid = sampGetPlayerIdByCharHandle(PLAYER_PED)
            local returnMsg = msg:gsub("{my:id}", myid)
            sampSendChat(returnMsg)
            return false
        end
        if msg:find("{my:rank}") then
            local returnMsg = msg:gsub("{my:rank}", cfg.Settings.rank)
            sampSendChat(returnMsg)
            return false
        end
        if msg:find("{date}") then
            local returnMsg = msg:gsub("{date}", date)
            sampSendChat(returnMsg)
            return false
        end
        if msg:find("{timeo}") then
            local returnMsg = msg:gsub("{timeo}", timeo)
            sampSendChat(returnMsg)
            return false
        end
        if msg:find("{player:id}") then
            local returnMsg = msg:gsub("{player:id}", tonumber(IDplayer.v))
            sampSendChat(returnMsg)
            return false
        end
        if msg:find("{player:name}") then
            local returnMsg = msg:gsub("{player:name}", rpNick(IDplayer.v))
            sampSendChat(returnMsg)
            return false
        end
        if msg:find("{expel:reason}") then
            local returnMsg = msg:gsub("{expel:reason}", tostring(u8:decode(expelreason.v)))
            sampSendChat(returnMsg)
            return false
        end
        if msg:find("{time}") then
            local returnMsg = msg:gsub("{time}", "/time")
            sampSendChat(returnMsg)
            return false
        end
        if msg:find("{screen}") then
            Screen()
            local returnMsg = msg:gsub("{screen}", "")
            sampSendChat(returnMsg)
            return false
        end
    end

function sampev.onSendCommand(cmd)
        if cmd:find("{sex:%A+|%A+}") then
            local male, female = cmd:match("{sex:(%A+)|(%A+)}")
            if cfg.Settings.sex == 1 then
                local returnMsg = cmd:gsub("{sex:%A+|%A+}", male, 1)
                sampSendChat(tostring(returnMsg))
                return false
            else
                local returnMsg = cmd:gsub("{sex:%A+|%A+}", female, 1)
                sampSendChat(tostring(returnMsg))
                return false
            end
        end
        if cmd:find("{my:name}") then
            local _, myid = sampGetPlayerIdByCharHandle(PLAYER_PED)
            local returnMsg = cmd:gsub("{my:name}", rpNick(myid))
            sampSendChat(returnMsg)
            return false
        end
        if cmd:find("{date}") then
            local returnMsg = cmd:gsub("{date}", date)
            sampSendChat(returnMsg)
            return false
        end
        if cmd:find("{timeo}") then
            local returnMsg = cmd:gsub("{timeo}", timeo)
            sampSendChat(returnMsg)
            return false
        end
        if cmd:find("{my:id}") then
            local _, myid = sampGetPlayerIdByCharHandle(PLAYER_PED)
            local returnMsg = cmd:gsub("{my:id}", myid)
            sampSendChat(returnMsg)
            return false
        end
        if cmd:find("{my:rank}") then
            local returnMsg = cmd:gsub("{my:rank}", cfg.Settings.rank)
            sampSendChat(returnMsg)
            return false
        end
        if cmd:find("{player:id}") then
            local returnMsg = cmd:gsub("{player:id}", IDplayer.v)
            sampSendChat(returnMsg)
            return false
        end
        if cmd:find("{player:name}") then
            local returnMsg = cmd:gsub("{player:name}", rpNick(IDplayer.v))
            sampSendChat(returnMsg)
            return false
        end
        if cmd:find("{expel:reason}") then
            local returnMsg = cmd:gsub("{expel:reason}", tostring(u8:decode(expelreason.v)))
            sampSendChat(returnMsg)
            return false
        end
        if cmd:find("{time}") then
            local returnMsg = cmd:gsub("{time}", "/time")
            sampSendChat(returnMsg)
            return false
        end
        if cmd:find("{screen}") then
            Screen()
            local returnMsg = cmd:gsub("{screen}", "")
            sampSendChat(returnMsg)
            return false
        end
    end

function sampev.onShowDialog(dialogId, style, title, button1, button2, text)
        if dialogId == 235 and getRankInStats then

            for DialogLine in text:gmatch("[^\r\n]+") do
                local nameRankStats, getStatsRank = DialogLine:match("���������: {......}(.+)%((%d+)%)")
                local pol = DialogLine:match("���: {......}%[(.+)%]")
                if pol == "�������" and FirstSettings.v == false then
                    GHsms('��� ������������� ���������� "�������". �������� ����� � ���������� �������.')
                    sex.v = 1
                    cfg.Settings.sex = sex.v
                    FirstSettings.v = true
                    cfg.Settings.FirstSettings = FirstSettings.v
                    inicfg.save(cfg, "Government Helper.ini")
                elseif pol == "�������" and FirstSettings.v == false then
                    GHsms('��� ������������� ���������� "�������". �������� ����� � ���������� �������.')
                    sex.v = 2
                    cfg.Settings.sex = sex.v
                    FirstSettings.v = true
                    cfg.Settings.FirstSettings = FirstSettings.v
                    inicfg.save(cfg, "Government Helper.ini")
                end
                if tonumber(getStatsRank) then
                    if tonumber(getStatsRank) ~= cfg.Settings.rankAndNumber then
                        cfg.Settings.rankAndNumber = tonumber(getStatsRank)
                        cfg.Settings.rank = tostring(nameRankStats)
                        GHsms("���� ������� �� " .. tostring(nameRankStats) .. "(" .. tostring(getStatsRank) .. ")")
                        inicfg.save(cfg, "Government Helper.ini")
                    end
                end
            end
            sampSendDialogResponse(dialogId, 0, _, _)
            getRankInStats = false
            return false
        end
    end

function sampev.onServerMessage(color, text)
            if autolog.v then
                if text:find('�� �������� ������') then
                    local itog = u8:decode(autologvid.v)
                    local player_name, player_rank = text:match('.+ (%w+_%w+)% �� (%d)% �����')
                    if itog:find("{my:name}") then
                        local _, myid = sampGetPlayerIdByCharHandle(PLAYER_PED)
                    itog = itog:gsub("{my:name}", sampGetPlayerNickname(myid))
                    end
                    if itog:find('{my:rank}') then
                        itog = itog:gsub("{my:rank}", cfg.Settings.rank)
                    end
                    if itog:find('{date}') then
                        itog = itog:gsub("{date}", date)
                    end
                    if itog:find('{timeo}') then
                        itog = itog:gsub("{timeo}", timeo)
                    end
                    if itog:find('{player:name}') then
                        itog = itog:gsub("{player:name}", player_name)
                    end
                    if itog:find('{player:rank}') then
                        itog = itog:gsub("{player:rank}", player_rank)
                    end
                    GHsms('\"' .. itog .. '\"')
                    GHsms('����-��� ���������/��������� ������� ���������� � ����� ������!')
                    ffi.C.LoadKeyboardLayoutA('00000419', 1)
                    setClipboardText(itog)
                    ffi.C.LoadKeyboardLayoutA('00000409', 1)
                end
            end
            if advstate then
            if text:find('(.+)%((%d+)%) | �����: (%d+) ��� | �����: %$%d+ | ���: (.+) PD | (.+)') then
                local pname, pid, ptime, ppd, padv = text:match('(.+)%((%d+)%) | �����: (%d+) ��� | �����: %$%d+ | ���: (.+) PD | (.+)')
                if padv:find("� �������� ��������") then
                    for k,v in pairs(department) do
                        if ppd == k then
                            table.insert(convicts.data, ("%s[%s] | %s min | %s"):format(pname, pid, ptime, v))
                        end
                    end
                end
                return false
            end
            if text:find('%[������%] %{FFFFFF%}� ������ ������ � ��� ����������� �����������!') then
                return false
            end
            end
        if nonrpchat.v == true then
            if text:find("%(%( %S+%[%d+%]: {B7AFAF}.-{FFFFFF} %)%)") then
                local id, t = text:match("%(%( %S+%[(%d+)%]: {B7AFAF}(.-){FFFFFF} %)%)")
                local _, char = sampGetCharHandleBySampPlayerId(id)
                if _ then
                    t = "(( {B7AFAF}" .. t .. " {FFFFFF}))"
                    local bs = raknetNewBitStream()
                    raknetBitStreamWriteInt16(bs, id)
                    raknetBitStreamWriteInt32(bs, -1)
                    raknetBitStreamWriteFloat(bs, 15)
                    raknetBitStreamWriteInt32(bs, 6000)
                    raknetBitStreamWriteInt8(bs, #t)
                    raknetBitStreamWriteString(bs, t)
                    raknetEmulRpcReceiveBitStream(raknet.RPC.CHATBUBBLE, bs)
                    raknetDeleteBitStream(bs)
                end
            end
        end
        if text:find("����� .+ ������� �� %d+ �����") then
            lua_thread.create(
                function()
                    wait(1)
                    getRankInStats = true
                    sampSendChat("/stats")
                end
            )
        end
        if text:find("{......}.+ ������ ��� �� �����������%. �������: .+") then
            lua_thread.create(
                function()
                    wait(1)
                    getRankInStats = true
                    sampSendChat("/stats")
                end
            )
        end
    end

function Screen()
    lua_thread.create(
        function()
            wait(500)
            setVirtualKeyDown(VK_F8, true)
            wait(10)
            setVirtualKeyDown(VK_F8, false)
        end
    )
end

function localtag()
    if
        imgui.BeginPopupModal(
            u8 "��������� ����",
            false,
            imgui.WindowFlags.NoResize + imgui.WindowFlags.AlwaysAutoResize + imgui.WindowFlags.NoTitleBar
        )
     then
        imgui.CenterTextColoredRGB("����:")
        if imgui.Button("{sex:man|woman}") then
            setClipboardText("{sex:man|woman}")
            GHsms('��� "{sex:man|woman}" ���������� � ����� ������!')
        else
            imgui.Hint(u8 "�������, ����� �����������")
        end
        imgui.SameLine()
        imgui.TextColoredRGB("����� �������� ������ �������� � ����������� �� ���� ���������\n(\"man\" - �������� �� ������� ��������, \"woman\" - �������� �� ������� ��������).")
        if imgui.Button("{my:name}") then
            setClipboardText("{my:name}")
            GHsms('��� "{my:name}" ���������� � ����� ������!')
        else
            imgui.Hint(u8 "�������, ����� �����������")
        end
        imgui.SameLine()
        imgui.TextColoredRGB("������� ���� ��� � �� �������")
        if imgui.Button("{my:id}") then
            setClipboardText("{my:id}")
            GHsms('��� "{my:id}" ���������� � ����� ������!')
        else
            imgui.Hint(u8 "�������, ����� �����������")
        end
        imgui.SameLine()
        imgui.TextColoredRGB("������� ��� ��")
        if imgui.Button("{my:rank}") then
            setClipboardText("{my:rank}")
            GHsms('��� "{my:rank}" ���������� � ����� ������!')
        else
            imgui.Hint(u8 "�������, ����� �����������")
        end
        imgui.SameLine()
        imgui.TextColoredRGB("������� ���� ���������")
        if imgui.Button("{player:id}") then
            setClipboardText("{player:id}")
            GHsms('��� "{player:id}" ���������� � ����� ������!')
        else
            imgui.Hint(u8 "�������, ����� �����������")
        end
        imgui.SameLine()
        imgui.TextColoredRGB("������� �� ������ �� �������� �� ��������")
        if imgui.Button("{player:name}") then
            setClipboardText("{player:name}")
            GHsms('��� "{player:name}" ���������� � ����� ������!')
        else
            imgui.Hint(u8 "�������, ����� �����������")
        end
        imgui.SameLine()
        imgui.TextColoredRGB("������� ��� ������ �� �������� �� �������� � �� �������")
        if imgui.Button("{expel:reason}") then
            setClipboardText("{expel:reason}")
            GHsms('��� "{expel:reason}" ���������� � ����� ������!')
        else
            imgui.Hint(u8 "�������, ����� �����������.")
        end
        imgui.SameLine()
        imgui.TextColoredRGB('������� ������� /expel, ������������� � ����������')
        if imgui.Button("{date}") then
            setClipboardText("{date}")
            GHsms('��� "{date}" ���������� � ����� ������!')
        else
            imgui.Hint(u8 "�������, ����� �����������.")
        end
        imgui.SameLine()
        imgui.TextColoredRGB('������� ����������� ���� � ������� \"����.�����.���\"')
        if imgui.Button("{timeo}") then
            setClipboardText("{timeo}")
            GHsms('��� "{timeo}" ���������� � ����� ������!')
        else
            imgui.Hint(u8 "�������, ����� �����������.")
        end
        imgui.SameLine()
        imgui.TextColoredRGB('������� ������� ����� � ������� \"����:������\"')
        if imgui.Button("{time}") then
            setClipboardText("{time}")
            GHsms('��� "{time}" ���������� � ����� ������!')
        else
            imgui.Hint(u8 "�������, ����� �����������.\n� ������� ������������ �� ����� �������!")
        end
        imgui.SameLine()
        imgui.TextColoredRGB('������� "/time" � ���')
        if imgui.Button("{screen}") then
            setClipboardText("{screen}")
            GHsms('��� "{screen}" ���������� � ����� ������!')
        else
            imgui.Hint(
                u8 "�������, ����� �����������.\n� ������� ������� ������������ � ������� � �������, ����� ����� ������ ������ � ����!"
            )
        end
        imgui.SameLine()
        imgui.TextColoredRGB("������ �������� ������ (F8)")
        if imgui.Button(u8 "�������##LocalTag", imgui.ImVec2(-1, 20)) then
            imgui.CloseCurrentPopup()
        end
        imgui.EndPopup()
    end
end

if memory.tohex(getModuleHandle("samp.dll") + 0xBABE, 10, true) == "E86D9A0A0083C41C85C0" then
    sampIsLocalPlayerSpawned = function()
        local res, id = sampGetPlayerIdByCharHandle(PLAYER_PED)
        return sampGetGamestate() == 3 and res and sampGetPlayerAnimationId(id) ~= 0
    end
end

function onScriptTerminate(script, quit)
    if script == thisScript() then
        imgui.ShowCursor = false
        imgui.Process = false
        showCursor(false, false)
    end
end