# qb-sna-vehiclekeys
Vehicle keys as items

## Features
- The key is created with the vehicle plate and model in item description
- Keys are given at car buy (events available), can be bought and managed at the locksmith
- There is an option to change the locks for a specific car at the locksmith
- When a player tries to enter the car, it check the lock value of the car
- Npc cars are accessible the gta way (carjacking or window breaking)
- If car is locked the player can lockpick it, else the player can enter
- Once in the car check is made for the item in inventory for the key to start the engine
- If the player have no key he can try to hotwire the car

- Add fee payment

## Requirements
- [qb-core](https://github.com/qbcore-framework/qb-core)

## Installation
- Delete qb-vehiclekeys

- Copy the vehiclekeys image in img folder into qb-inventory\html\images

- Add in qb-core/shared/items.lua
```lua
	['vehiclekey'] 				 	 = {['name'] = 'vehiclekey',					['label'] = 'Vehicle key', 					['weight'] = 0, 		['type'] = 'item', 		['image'] = 'vehiclekeys.png', 				['unique'] = true, 	['useable'] = true, 	['shouldClose'] = true,	   ['combinable'] = nil,   ['description'] = "This is a car key, take good care of it, if you lose it you probably won't be able to use your car"},
```
- Add item info to qb-inventory\html\js\app.js in function FormatItemInfo
```js
        } else if (itemData.name == "vehiclekey") {
            $(".item-info-title").html('<p>' + itemData.info.model + '</p>');
            $(".item-info-description").html('<p>Plate : ' + itemData.info.plate + '</p>');
```

