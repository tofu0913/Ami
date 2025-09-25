
local timer = os.clock()

stats = {}
stats.widget = nil

local PLD = 'Frieren'
local DNC = 'Felicya'
local BRD = 'Mikahu'
local GEO = 'Zeusroars'
local COR = 'Dorithy'
local RDM = 'Lynnix'
local TARGET = 'Aminon'
local wsdamage = {}
local absotp = {}
local zerodamage = {}

local function wsd_rate(num)
	if num ~= nil then
		return '%2.2f%%':format(num/5000000*100)
	end
	return '%2.2f%%':format(0)
end

local function calc_rate(data)
	if data then
		if data.total == nil then
			return '0/0 %2.2f%%':format(0)
		elseif data.total ~= nil and data.success ~= nil then
			return '%s/%s (%2.2f%%)':format(data.success, data.total, data.success/data.total*100)
		end
	end
	return '0/0 %2.2f%%':format(0)
end

local function update_wifget()
	local msg = '%25s\n':format('ZeroRate')
	if PLD ~= '' then
		msg = msg ..'PLD %-12s %6s\n\n':format('('..PLD..')', calc_rate(zerodamage))
	end
	msg = msg .. '%25s%10s\n':format('WsDamage','AbsoTp')
	if DNC ~= '' then
		msg = msg ..'DNC %-12s %6s\n':format('('..DNC..')', wsd_rate(wsdamage[DNC]))
	end
	if COR ~= '' then
		msg = msg ..'COR %-12s %6s, %16s\n':format('('..COR..')', wsd_rate(wsdamage[COR]), calc_rate(absotp[COR]))
	end
	if RDM ~= '' then
		msg = msg ..'RDM %-12s %6s, %16s\n':format('('..RDM..')', wsd_rate(wsdamage[RDM]), calc_rate(absotp[RDM]))
	end
	if BRD ~= '' then
		msg = msg ..'BRD %-12s %6s, %16s\n':format('('..BRD..')', wsd_rate(wsdamage[BRD]), calc_rate(absotp[BRD]))
	end
	if GEO ~= '' then
		msg = msg ..'GEO %-12s %6s, %16s\n':format('('..GEO..')', wsd_rate(wsdamage[GEO]), calc_rate(absotp[GEO]))
	end
	
	stats.widget.msg = msg
end

windower.register_event('prerender', function(...)
    if (os.clock() - timer) > 1 and stats.widget then
		update_wifget()
		timer = os.clock()
	end
end)

ActionPacket.open_listener(function(act)
    local actionpacket = ActionPacket.new(act)
    local category = actionpacket:get_category_string()
	-- log(category)
    if not (T{'weaponskill_finish','spell_finish','mob_tp_finish','melee'}:contains(category)) or act.param == 0 then
        return
    end

    local actor = actionpacket:get_id()
	if T{'weaponskill_finish','spell_finish'}:contains(category) and isInParty(actor) then
		local target = actionpacket:get_targets()()
		local action = target:get_actions()()
		local mob = windower.ffxi.get_mob_by_id(target.id or 0)
		if mob then--and mob.name == TARGET then
			local message_id = action:get_message_id()
			local param, resource, action_id, interruption, conclusion = action:get_spell()
			local player = windower.ffxi.get_mob_by_id(actor).name
			if T{185}:contains(message_id) then
				if not wsdamage[player] then
					wsdamage[player] = 0
				end
				wsdamage[player] = param + wsdamage[player]
			elseif T{454,114}:contains(message_id) and action_id == 275 then
				if message_id == 454 and param > 0 then
					if not absotp[player] then
						absotp[player] = {}
					end
					if not absotp[player].total then
						absotp[player].total = 0
					end
					if not absotp[player].success then
						absotp[player].success = 0
					end
					absotp[player].success = absotp[player].success + 1
					absotp[player].total = absotp[player].total + 1
					log(absotp[player].total)
				elseif message_id == 114 then
					if not absotp[player] then
						absotp[player] = {}
					end
					if not absotp[player].total then
						absotp[player].total = 0
					end
					absotp[player].total = absotp[player].total + 1
				end
			end
		end
	elseif T{'mob_tp_finish','melee'}:contains(category) and isMob(actor) then
		local target = actionpacket:get_targets()()
		local action = target:get_actions()()
		if isInParty(target.id) then
			local message_id = action:get_message_id()
			local param, resource, action_id, interruption, conclusion = action:get_spell()
			if (message_id == 1 and param == 0) or message_id == 373 then
				if not zerodamage.total then
					zerodamage.total = 0
				end
				if not zerodamage.success then
					zerodamage.success = 0
				end
				zerodamage.success = zerodamage.success + 1
				zerodamage.total = zerodamage.total + 1
			elseif message_id == 1 and param > 0 then
				if not zerodamage.total then
					zerodamage.total = 0
				end
				zerodamage.total = zerodamage.total + 1
			end
		end
	end
end)

return stats