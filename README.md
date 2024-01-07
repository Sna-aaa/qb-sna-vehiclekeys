# qb-sna-vehiclekeys
Vehicle keys as items

## Support
Please join my discord : https://discord.gg/kvSwVzD8Rd

## Features
- The key is created with the vehicle plate and model in item description
- Keys are given at car buy (events available)
- The locksmith is used to buy additional keys and change locks of a car
- When a player tries to enter the car, it check the lock value of the car
- Npc cars are accessible the gta way (carjacking or window breaking)
- If car is locked the player can lockpick it, else the player can enter
- Once the player is in the car a check is made for the key item in inventory to start the engine
- If the player have no key he can try to hotwire the car
- For admin cars (/car) the car is now yours temporarly, so you have an "old style invisible key"
- When a job spawn a free car, the player receives the same old style key, so no hotwire
- When a car is sold, the key can be removed
- Keys are never deleted or removed, and not given by the garage anymore, you need to keep the keys in your inventory or storage

## Requirements
- [qb-core](https://github.com/qbcore-framework/qb-core)

## Installation
- Delete qb-vehiclekeys from qbcore

- Install the new resource with a name THAT IS NOT qb-vehiclekeys

- Copy the vehiclekeys image in img folder into qb-inventory\html\images

- Import player_vehicles.sql into your database

- Add in qb-core/shared/items.lua
```lua
    vehiclekey                   = { name = 'vehiclekey', label = 'Vehicle key', weight = 10, type = 'item', image = 'vehiclekeys.png', unique = true, useable = true, shouldClose = true, combinable = nil, description = "This is a car key, take good care of it, if you lose it you probably won't be able to use your car" },
```

- Add item info to qb-inventory\html\js\app.js around line 395 in function generateDescription
```js
        case "labkey":
            return `<p>Lab: ${itemData.info.lab}</p>`;
        case "vehiclekey":                                                                      //Change Add
                return `<p><strong>Car: </strong><span>${itemData.info.model}</span></p>
                <p><strong>Plate: </strong><span>${itemData.info.plate}</span></p>`;            //Change Add
        default:
            return itemData.description;
```

Basically 2 events are used for the vehicle keys in qb-vehicleshop/client.lua
One event that will create a key when you buy the car 'qb-vehiclekeys:server:BuyVehicle' that you need to insert into your vehicle shop like this
One event that will give a temporary key used for admin spawn car or job car 'vehiclekeys:client:SetOwner' that you need to remove/comment in the vehicleshop like this (this event is used in the complete qbcore solution, but sometimes a dev tries to be original and use an event nobody use 'qb-vehiclekeys:server:AcquireVehicleKeys', this is the same as 'vehiclekeys:client:SetOwner')
```lua
RegisterNetEvent('qb-vehicleshop:client:buyShowroomVehicle', function(vehicle, plate)
    tempShop = insideShop -- temp hacky way of setting the shop because it changes after the callback has returned since you are outside the zone
    QBCore.Functions.TriggerCallback('QBCore:Server:SpawnVehicle', function(netId)
        local veh = NetToVeh(netId)
        exports['LegacyFuel']:SetFuel(veh, 100)
        SetVehicleNumberPlateText(veh, plate)
        SetEntityHeading(veh, Config.Shops[tempShop]["VehicleSpawn"].w)
        --TriggerEvent("vehiclekeys:client:SetOwner", QBCore.Functions.GetPlate(veh))                                                       --Change comment
        TriggerServerEvent("qb-vehicletuning:server:SaveVehicleProps", QBCore.Functions.GetVehicleProperties(veh))
        TriggerServerEvent('qb-vehiclekeys:server:BuyVehicle', plate, GetLabelText(GetDisplayNameFromVehicleModel(GetEntityModel(veh))))   --Change Add
    end, vehicle, Config.Shops[tempShop]["VehicleSpawn"], true)
end)
```

As the keys are already given by the shop, you need to remove the temporary key given in the garage 'vehiclekeys:client:SetOwner' so you need to remove/comment it in the gagare you use like this in qb-garage/client/main.lua
```lua
RegisterNetEvent('qb-garages:client:takeOutGarage', function(data)
    local type = data.type
    local vehicle = data.vehicle
    local garage = data.garage
    local index = data.index
    QBCore.Functions.TriggerCallback('qb-garage:server:IsSpawnOk', function(spawn)
        if spawn then
            local location
            if type == "house" then
                location = garage.takeVehicle
            else
                location = garage.spawnPoint
            end
            QBCore.Functions.TriggerCallback('qb-garage:server:spawnvehicle', function(netId, properties)
                local veh = NetToVeh(netId)
                QBCore.Functions.SetVehicleProperties(veh, properties)
                exports['LegacyFuel']:SetFuel(veh, vehicle.fuel)
                doCarDamage(veh, vehicle)
                TriggerServerEvent('qb-garage:server:updateVehicleState', 0, vehicle.plate, index)
                closeMenuFull()
                --TriggerEvent("vehiclekeys:client:SetOwner", QBCore.Functions.GetPlate(veh))                   --Change comment
                SetVehicleEngineOn(veh, true, true)
                if type == "house" then
                    exports['qb-core']:DrawText(Lang:t("info.park_e"), 'left')
                    InputOut = false
                    InputIn = true
                end
            end, vehicle, location, true)
        else
            QBCore.Functions.Notify(Lang:t("error.not_impound"), "error", 5000)
        end
    end, vehicle.plate, type)
end)
```

This event can be used to automatically remove a key from player's inventory
```lua
    TriggerServerEvent('qb-vehiclekeys:server:RemoveKey', plate)
```