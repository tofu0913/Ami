
local timer = os.clock()

stats = {}
stats.widget = nil

local TARGET = 'Aminon'
local wsdamage = {}
local wscount = {}
local wsd_total = 0
local absotptime = nil
local absotpsum = 0
local absotp = {}
local zerodamage = {}

local function show_count(num)
	if num ~= nil then
		return '%2d':format(num)
	end
	return '%2d':format(0)
end

local function wsd_rate(num)
	if num ~= nil and wsd_total>0 then
		return '%2.2f%%':format(num/wsd_total*100)
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

function calc_absoavg()
	local rate = 0
	if absotptime then
		local totaltime = os.clock() - absotptime
		if totaltime > 0 then
			rate = absotpsum / totaltime
		end
	end
	return '%2.2f tp/s':format(rate)
end

function total_rate(data)
	local total = 0
	local success = 0
	for k,v in pairs(data) do
		total = total + v.total
		success = success + v.success
	end
	if total > 0 then
		return '%2.2f%%':format(success/total*100)
	end
	return '0.00%'
end

local function update_wifget()
	local msg = '%25s\n':format('ZeroRate')
	if settings.PLD ~= '' then
		msg = msg ..'PLD %-12s %6s\n\n':format('('..settings.PLD..')', calc_rate(zerodamage))
	end
	msg = msg .. '%20s %8s% 12s\n':format('Ws','Damage','AbsoTp')
	if DNC ~= '' then
		msg = msg ..'DNC %-12s %2s %10s\n':format('('..settings.DNC..')', show_count(wscount[settings.DNC]), wsd_rate(wsdamage[settings.DNC]))
	end
	if COR ~= '' then
		msg = msg ..'COR %-12s %2s %10s, %13s\n':format('('..settings.COR..')', show_count(wscount[settings.COR]), wsd_rate(wsdamage[settings.COR]), calc_rate(absotp[settings.COR]))
	end
	if RDM ~= '' then
		msg = msg ..'RDM %-12s %2s %10s, %13s\n':format('('..settings.RDM..')', show_count(wscount[settings.RDM]), wsd_rate(wsdamage[settings.RDM]), calc_rate(absotp[settings.RDM]))
	end
	if BRD ~= '' then
		msg = msg ..'BRD %-12s %2s %10s, %13s\n':format('('..settings.BRD..')', show_count(wscount[settings.BRD]), wsd_rate(wsdamage[settings.BRD]), calc_rate(absotp[settings.BRD]))
	end
	if GEO ~= '' then
		msg = msg ..'GEO %-12s %2s %10s, %13s\n':format('('..settings.GEO..')', show_count(wscount[settings.GEO]), wsd_rate(wsdamage[settings.GEO]), calc_rate(absotp[settings.GEO]))
	end
	msg = msg .. '\n%45s':format(calc_absoavg())
	
	stats.widget.msg = msg
end

function stats.report()
	windower.send_command(windower.to_shift_jis('input /p ===== Aminon Rport =====; wait 1.5;'..
												'input /p Zero damage rate: %s; wait 1.5;':format(calc_rate(zerodamage))..
												'input /p Abso Tp avg.:      %s (%s); wait 1.5;':format(calc_absoavg(),total_rate(absotp)))
	)
end

windower.register_event('prerender', function(...)
    if (os.clock() - timer) > 2 and stats.widget then
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
		-- if mob then
		if mob and mob.name == TARGET then
			local message_id = action:get_message_id()
			local param, resource, action_id, interruption, conclusion = action:get_spell()
			local player = windower.ffxi.get_mob_by_id(actor).name
			if T{185}:contains(message_id) then
				if not wsdamage[player] then
					wsdamage[player] = 0
				end
				wsd_total = wsd_total + param
				wsdamage[player] = param + wsdamage[player]
				if not wscount[player] then
					wscount[player] = 0
				end
				wscount[player] = wscount[player] + 1
			elseif T{454,114}:contains(message_id) and action_id == 275 then
				if message_id == 454 and param > 0 then
					if not absotptime then
						absotptime = os.clock()
					end
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
					-- log(absotp[player].total)
					absotpsum = absotpsum + param
				elseif message_id == 114 then
					if not absotptime then
						absotptime = os.clock()
					end
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
		for target in actionpacket:get_targets() do
			for action in target:get_actions() do
				local player = windower.ffxi.get_mob_by_id(target.id).name
				if player == settings.PLD then
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
		end
	end
end)

return stats