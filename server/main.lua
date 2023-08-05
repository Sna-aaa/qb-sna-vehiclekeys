local QBCore = exports['qb-core']:GetCoreObject()
local VehicleList = {}

local function ChangeLocks(plate)
	local result = MySQL.single.await('SELECT `lock` FROM player_vehicles WHERE plate = ?', { plate })
	if result then
		local lock = result.lock
		if lock then
			lock = lock + 1
		else
			lock = 4321
		end
		MySQL.update('UPDATE player_vehicles SET `lock` = ? WHERE plate = ?', {lock, plate})
	end
end

local function GiveKey(plate, model, player, src)
	local result = MySQL.single.await('SELECT `lock` FROM player_vehicles WHERE plate = ?', { plate })
	if result then
		local lock = result.lock
		local info = {}
		if lock then
			info.lock = lock
			info.plate = plate
			info.model = model
			player.Functions.AddItem('vehiclekey', 1, nil, info)
			TriggerClientEvent("inventory:client:ItemBox", src, QBCore.Shared.Items["vehiclekey"], "add")
			TriggerClientEvent('QBCore:Notify', src, Lang:t("message.key_received"), 'success')
		else
			TriggerClientEvent('QBCore:Notify', src, Lang:t("message.not_initialized"), 'error')
		end
	end
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

RegisterNetEvent('qb-vehiclekeys:server:breakLockpick', function(itemName)
	local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    if not (itemName == "lockpick" or itemName == "advancedlockpick") then return end
    if Player.Functions.RemoveItem(itemName, 1) then
            TriggerClientEvent("inventory:client:ItemBox", src, QBCore.Shared.Items[itemName], "remove")
    end
end)

RegisterNetEvent('qb-vehiclekeys:server:RemoveKey', function(plate)
	local src = source
	local Player = QBCore.Functions.GetPlayer(src)
	local items = Player.Functions.GetItemsByName('vehiclekey')
	if items then
		for _, v in pairs(items) do
			if v.info.plate == plate then
				if Player.Functions.RemoveItem('vehiclekey', 1, v.slot) then
					TriggerClientEvent("inventory:client:ItemBox", src, QBCore.Shared.Items['vehiclekey'], "remove")
				end
			end
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
			local items = Player.Functions.GetItemsByName('vehiclekey')
			if items then
				for _, v in pairs(items) do
					if v.info.plate == plate then
						local result = MySQL.single.await('SELECT `lock` FROM player_vehicles WHERE plate = ?', { plate })
						if result then
							local lock = result.lock
							if v.info.lock == lock then
								ok = true
							end
						else
							ok = true
						end
					end
				end
			end
			cb(ok)		
		end
	end
end)

QBCore.Functions.CreateCallback('qb-vehiclekeys:server:GetPlayerVehicles', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    local Vehicles = {}

    MySQL.query('SELECT * FROM player_vehicles WHERE citizenid = ?', {Player.PlayerData.citizenid}, function(result)
        if result[1] then
            for _, v in pairs(result) do
                local VehicleData = QBCore.Shared.Vehicles[v.vehicle]

                local fullname
                if VehicleData["brand"] ~= nil then
                    fullname = VehicleData["brand"] .. " " .. VehicleData["name"]
                else
                    fullname = VehicleData["name"]
                end
                Vehicles[#Vehicles+1] = {
                    fullname = fullname,
                    brand = VehicleData["brand"],
                    model = VehicleData["name"],
                    plate = v.plate,
                    state = v.state,
                    fuel = v.fuel,
                    engine = v.engine,
                    body = v.body
                }
            end
            cb(Vehicles)
        else
            cb(nil)
        end
    end)
end)
