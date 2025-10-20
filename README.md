# carscrap
FiveM carscrap system with contracts

# What you need?
- ox_lib
- Ox inv or any
- Any framework

If you use holding props based on items like the one from DemiAutomatic
```
['vehicle_hood'] = {
        walkOnly = true,
        blockVehicle = true,
        anim = {
            dict = 'anim@heists@box_carry@',
            clip = 'idle',
            flag = 51
        },
        prop = {
            bone = 60309,
            model = `imp_prop_impexp_bonnet_01a`,
            placement = {
                pos = vector3(0.235, -0.1700, 0.14),
                rot = vector3(-35.0, 107.0, 7.0),
            },
        },
    },
    ['vehicle_wheel'] = {
        walkOnly = false,
        blockVehicle = true,
        anim = {
            dict = 'anim@heists@box_carry@',
            clip = 'idle',
            flag = 51
        },
        prop = {
            bone = 60309,
            model = `prop_tornado_wheel`,
            placement = {
                pos = vector3(-0.067, 0.1500, 0.3),
                rot = vector3(45.0, 7.0, 40.0),
            },
        },
    },
    ['vehicle_trunk'] = {
        walkOnly = true,
        blockVehicle = true,
        anim = {
            dict = 'anim@heists@box_carry@',
            clip = 'idle',
            flag = 51
        },
        prop = {
            bone = 60309,
            model = `imp_prop_impexp_trunk_02a`,
            placement = {
                pos = vector3(-0.43, 0.51, 0.5),
                rot = vector3(-55.0, 107.0, 10.0),
            },
        },
    },
    ['vehicle_door'] = {
        walkOnly = true,
        blockVehicle = true,
        anim = {
            dict = 'anim@heists@box_carry@',
            clip = 'idle',
            flag = 51
        },
        prop = {
            bone = 60309,
            model = `imp_prop_impexp_car_door_05a`,
            placement = {
                pos = vector3(-0.105, 0.3000, 1.0),
                rot = vector3(-104.0, 180.0, -45.0),
            },
        },
    },
```
