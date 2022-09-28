local QBCore = exports['qb-core']:GetCoreObject()
local VehicleList = {}

local function ChangeLocks(plate)
	MySQL.single("SELECT IFNULL(JSON_VALUE(p.mods,'$.lock'),0) AS 'lock' FROM player_vehicles p WHERE plate = ?", { plate }
		,
		function(result)
			local mods = tonumber(result.lock) == 0 and 4321 or tonumber(result.lock) +1
			MySQL.update("UPDATE player_vehicles SET player_vehicles.mods = JSON_SET(player_vehicles.mods,'$.lock',?) WHERE plate = ?"
				, { mods, plate })
		end)
end

local function GiveKey(plate, model, player, src)
	MySQL.single("SELECT IFNULL(JSON_VALUE(p.mods,'$.lock'),0) AS 'lock' FROM player_vehicles p WHERE plate = ?", { plate }
		,
		function(result)
			local mods = tonumber(result.lock)
			local info = {}
			if mods == 0 then TriggerClientEvent('QBCore:Notify', src, Lang:t("message.not_initialized"), 'error') return end
			info.lock = mods
			info.plate = plate
			info.model = model
			player.Functions.AddItem('vehiclekey', 1, nil, info)
			TriggerClientEvent('QBCore:Notify', src, Lang:t("message.key_received"), 'success')
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
			MySQL.single("SELECT IFNULL(JSON_VALUE(v.mods,'$.lock'),0) AS vlock FROM  player_vehicles v  WHERE v.plate = ?",
				{ plate },
				function(result)
					if tonumber(result.vlock) == 0 then
						cb(false)
					end
					local mods = tonumber(result.vlock)
					local items = Player.Functions.GetItemsByName('vehiclekey')
					if items then
						for _, v in pairs(items) do
							print(type(result.vlock), type(v.info.lock), result.vlock, v.info.lock)
							if v.info.plate == plate and v.info.lock == mods then
								ok = true
							end
						end
					end
					cb(ok)
				end)
		end
	end
end)
