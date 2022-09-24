local QBCore = exports['qb-core']:GetCoreObject()

RegisterNetEvent('qb-vehiclekeys:server:ChangeLocks', function(data)
	local src = source
	local Player = QBCore.Functions.GetPlayer(src)
	local plate = data.plate
    if Player then
		MySQL.query('SELECT * FROM player_vehicles WHERE plate = ?', {plate}, function(result)
			if result[1] then
				local mods = json.decode(result[1].mods)
				if mods.lock then
					mods.lock = mods.lock + 1
				else
					mods.lock = 4321
				end
				MySQL.update('UPDATE player_vehicles SET mods = ? WHERE plate = ?', {json.encode(mods), plate})
				TriggerClientEvent('QBCore:Notify', src, Lang:t("message.locks_reset"), 'success')
			end
		end)
	end

end)

RegisterNetEvent('qb-vehiclekeys:server:GiveKey', function(data)
	local src = source
	local Player = QBCore.Functions.GetPlayer(src)
	local plate = data.plate
	local model = data.model
	local info = {}
    if Player then
		MySQL.query('SELECT * FROM player_vehicles WHERE plate = ?', {plate}, function(result)
			if result[1] then
				local mods = json.decode(result[1].mods)
				if mods.lock then
					info.lock = mods.lock
					info.plate = plate
					info.model = model
					Player.Functions.AddItem('vehiclekey', 1, nil, info)
					TriggerClientEvent('QBCore:Notify', src, Lang:t("message.key_received"), 'success')
				else
					TriggerClientEvent('QBCore:Notify', src, Lang:t("message.not_initialized"), 'error')
				end
			end
		end)
	end
end)

QBCore.Functions.CreateCallback('qb-vehiclekeys:server:HasKey', function(source, cb, plate)
	local src = source
	local Player = QBCore.Functions.GetPlayer(src)
	local ok = false
    if Player then
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
end)
