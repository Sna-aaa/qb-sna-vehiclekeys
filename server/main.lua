local QBCore = exports['qb-core']:GetCoreObject()
local VehicleList = {}

local function ChangeLocks(plate)
	MySQL.query('SELECT * FROM player_vehicles WHERE plate = ?', {plate}, function(result)
		if result[1] then
			local mods = json.decode(result[1].mods)
			if mods.lock then
				mods.lock = mods.lock + 1
			else
				mods.lock = 4321
			end
			MySQL.update('UPDATE player_vehicles SET mods = ? WHERE plate = ?', {json.encode(mods), plate})
		end
	end)
end

local function GiveKey(plate, model, player, src)
	MySQL.query('SELECT * FROM player_vehicles WHERE plate = ?', {plate}, function(result)
		if result[1] then
			local mods = json.decode(result[1].mods)
			local info = {}
			print(mods.lock)
			if mods.lock then
				info.lock = mods.lock
				info.plate = plate
				info.model = model
				player.Functions.AddItem('vehiclekey', 1, nil, info)
				TriggerClientEvent('QBCore:Notify', src, Lang:t("message.key_received"), 'success')
			else
				TriggerClientEvent('QBCore:Notify', src, Lang:t("message.not_initialized"), 'error')
			end
		end
	end)
end

RegisterNetEvent('qb-vehiclekeys:server:BuyVehicle', function(plate, model)
	local src = source
	local Player = QBCore.Functions.GetPlayer(src)
	ChangeLocks(plate)
	Wait(100)
	GiveKey(plate, model, Player, src)
end)

RegisterNetEvent('qb-vehiclekeys:server:GiveTempKey', function(plate)
	local src = source
    local citizenid = QBCore.Functions.GetPlayer(src).PlayerData.citizenid

    if not VehicleList[plate] then VehicleList[plate] = {} end
    VehicleList[plate][citizenid] = true
	TriggerClientEvent('QBCore:Notify', src, Lang:t("message.temp_key_received"))

end)

RegisterNetEvent('qb-vehiclekeys:server:ChangeLocks', function(data)
	local src = source
	local Player = QBCore.Functions.GetPlayer(src)
	local plate = data.plate
	local cashBalance = Player.PlayerData.money["cash"]

    if Player then
		if cashBalance >= Config.ResetPrice then
			Player.Functions.RemoveMoney("cash", Config.ResetPrice, "Reset-Locks")
			ChangeLocks(plate)
			TriggerClientEvent('QBCore:Notify', src, Lang:t("message.locks_reset"), 'success')
		else
			TriggerClientEvent('QBCore:Notify', src, Lang:t("message.not_enough_money"), 'error')
		end
	end

end)

RegisterNetEvent('qb-vehiclekeys:server:GiveKey', function(data)
	local src = source
	local Player = QBCore.Functions.GetPlayer(src)
	local plate = data.plate
	local model = data.model
	local cashBalance = Player.PlayerData.money["cash"]

    if Player then
		if cashBalance >= Config.KeyPrice then
			Player.Functions.RemoveMoney("cash", Config.KeyPrice, "Get-Key")
			GiveKey(plate, model, Player, src)
		else
			TriggerClientEvent('QBCore:Notify', src, Lang:t("message.not_enough_money"), 'error')
		end
	end
end)

QBCore.Functions.CreateCallback('qb-vehiclekeys:server:HasKey', function(source, cb, plate)
	local src = source
	local Player = QBCore.Functions.GetPlayer(src)
    local citizenid = QBCore.Functions.GetPlayer(src).PlayerData.citizenid
	local ok = false
    if Player then
		if VehicleList[plate] and VehicleList[plate][citizenid] then
			cb(true)				
		else
			MySQL.query('SELECT * FROM player_vehicles WHERE plate = ?', {plate}, function(result)
				if result[1] then
					local mods = json.decode(result[1].mods)
					local items = Player.Functions.GetItemsByName('vehiclekey')
					if items then
						for _, v in pairs(items) do
							if v.info.plate == plate and v.info.lock == mods.lock then
								ok = true
							end
						end
					end
				end
				cb(ok)		
			end)	
		end
	end
end)
