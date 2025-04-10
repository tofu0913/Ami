_addon.name = 'Ami'
_addon.author = 'Cliff'
_addon.version = '1.1.0'
_addon.commands = {'ami'}

require('logger')
require('mylibs/utils')
config = require('config')
require('actions')
res = require('resources')

local atp = false
local aws = false
local lastCheck = os.clock()

local texts = require('texts')
local default_settings = {
	widget = {
		pos = {
			x = 150,
			y = 500
		}
	},
	ws = 'エクズデーション'
}
settings = config.load('data\\settings.xml',default_settings)

-- Widget
local texts = require('texts')
function setup_text(text)
    text:bg_alpha(255)
    text:bg_visible(true)
    text:font('ＭＳ ゴシック')
    text:size(20)
    text:color(255,255,255,255)
    text:stroke_alpha(200)
    text:stroke_color(20,20,20)
    text:stroke_width(2)
	text:show()
end
local widget = texts.new("${msg}", settings.widget, {})

function updateWidget()
	str = ''
	if aws then
		str = str ..'射'
	else
		str = str ..'不射'
	end
	if atp then
		str = str ..'吸'
	else
		str = str ..'不吸'
	end
	widget.msg = str
end

function hasSilence()
    for i,v in pairs(windower.ffxi.get_player()['buffs']) do
        if v == 6 then
            return true
        end
    end
    return false
end

function findTarget()
	local bt = windower.ffxi.get_mob_by_target('bt')
	return bt
end

windower.register_event('prerender', function(...)
    if (os.clock() - lastCheck) > 1 then
		local target = findTarget()
		if target then
			if atp and isSubJob('DRK') and windower.ffxi.get_spell_recasts()[275] == 0 and not hasSilence() then
				windower.send_command(windower.to_shift_jis('input /ma アブゾタック <bt>'))
			elseif aws and windower.ffxi.get_player().vitals.tp >= 1000 and target.distance < 15 then
				windower.send_command(windower.to_shift_jis('input /ws '..settings.ws..' <bt>'))
			end
		end
		lastCheck = os.clock()
    end
end)

function action_handler(act)
    local actionpacket = ActionPacket.new(act)
    local category = actionpacket:get_category_string()
	
    if not (T{'spell_finish'}:contains(category)) or act.param == 0 then
        return
    end

    local actor = actionpacket:get_id()
	if actor ~= windower.ffxi.get_player().id then--Only me
		return
	end
    local target = actionpacket:get_targets()()
    local action = target:get_actions()()
    local message_id = action:get_message_id()
    local param, resource, action_id, interruption, conclusion = action:get_spell()
	if T{454,114}:contains(message_id) and action_id == 275 then
		if message_id == 454 and param >= 200 then
			windower.send_command(windower.to_shift_jis("input /p ('◇')ゞ 報告! 吸 "..param.."!!!"))
		elseif message_id == 114 then
			-- log('missed')
			windower.send_command(windower.to_shift_jis("input /p (ﾉд-｡) 沒吸.... Miss...."))
		end
	end
end
ActionPacket.open_listener(action_handler)

windower.register_event('status change', function(new, old)
    if new == 2 then
        windower.send_command('ami off')
    end
end)

windower.register_event('addon command', function(command, ...)
	local args = T{...}
	
    if T{"tp"}:contains(command) then
		if args[1] then	
			atp = (args[1] == 'on')
		else
			atp = not atp
		end
        log('Auto AbsorbTP: '..tostring(atp))
		updateWidget()
        
    elseif T{"ws"}:contains(command) then
		if args[1] then	
			aws = (args[1] == 'on')
		else
			aws = not aws
		end
        log('Auto WS: '..tostring(aws))
		updateWidget()
        
    elseif T{"off"}:contains(command) then
		aws = false
		atp = false
        log('Auto AbsorbTP: '..tostring(atp))
        log('Auto WS: '..tostring(aws))
		updateWidget()
        
    elseif T{"on"}:contains(command) then
		aws = true
		atp = true
        log('Auto AbsorbTP: '..tostring(atp))
        log('Auto WS: '..tostring(aws))
		updateWidget()
        
	elseif command == 'save' then
		settings:save()
		log('Settings saved.')
	end
end)

windower.register_event('load', function()
    log('===========loaded===========')
    windower.send_command('bind @w input //ami ws')
    windower.send_command('bind @t input //ami tp')
	setup_text(widget)
	updateWidget()
end)

windower.register_event('unload', function()
    windower.send_command('unbind @w')
    windower.send_command('unbind @t')
end)