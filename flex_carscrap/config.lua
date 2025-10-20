Config = {}

Config.Debug = false
Config.Lang = 'nl'
Config.CoreName = {
    qb = 'qb-core',
    esx = 'es_extended',
    ox = 'ox_core',
    ox_inv = 'ox_inventory',
    qbx = 'qbx_core',
    qb_radial = 'qb-radialmenu',
}

Config.ContractItem = 'scrap_contract'
Config.ScrapListCommand = false -- Command to show the car list (false to disable / use radialmenu)
Config.RadialAddon = true -- If true it will add a radial option to show the scrap list (qb / qbx -core only)
-- OR TRIGGER 'flex_carscrap:Server:ShowScrapList'

Config.Notify = {
    client = function(msg, type, time)
        lib.notify({
            title = msg,
            type = type,
            time = time or 5000,
        })
    end,
    server = function(src, msg, type, time)
        lib.notify(src, {
            title = msg,
            type = type,
            time = time or 5000,
        })
    end,
}

Config.ProgressTime = {
    scrap = math.random(5, 7), -- Time to take of a part in seconds
    sell = math.random(2, 4), -- Time in seconds to sell
}

Config.SellPeds = {
    [1] = {
        ped = 'a_m_o_acult_02', -- If nill it creates a boxzone
        coords = vector4(859.48, -2366.16, 30.36, 0.12),
        boxzone = vec3(2.0, 4.0, 2.0),
    }
}
Config.ScrappingZones = {
    { -- vector 2 polyzone for the scrap area
        vec2(888.04, -2382.68),
        vec2(894.76, -2329.88),
        vec2(862.6, -2325.8),
        vec2(864.12, -2302.72),
        vec2(842.56, -2299.32),
        vec2(825.0, -2366.6),
        vec2(863.96, -2366.44)
    },
}

Config.DefaultContract = {
    type = {
        'c', -- Contract C
        'b', -- Contract B
        'a', -- Contract A
        'a+', -- Contract A+
    },
    amount = math.random(1,2), -- Amount of vehicles
}

Config.ScrapVehicles = {
    ['c'] = { -- Contract type
        'blista', -- Vehicle name for that contact
        'issi2', -- Vehicle name for that contact
        -- 'dilettante', -- Vehicle name for that contact
        'rhapsody', -- Vehicle name for that contact
        'panto', -- Vehicle name for that contact
        'manana', -- Vehicle name for that contact
    },
    ['b'] = {
        'stanier',
        'primo',
        'asea',
        'intruder',
        'tailgater',
        'asterope',
        'premier',
        'washington',
        'glendale',
    },
    ['a'] = {
        'zion',
        'jackal',
        'oracle',
        'sentinel',
        'futo',
        'felon',
        'penumbra',
        'windsor2',
    },
    ['a+'] = {
        'baller',
        'habanero',
        'landstalker',
        'fq2',
        'cavalcade',
        'seminole',
        'rocoto',
        'serrano',
        'granger',
    },
}

Config.SellWithoutAnim = false -- If true no check for anim 'anim@heists@box_carry@' 'idle'
Config.Reward = {
    ['vehicle_wheel'] = { item = 'recyclable_materials', amount = math.random(1,2), info = nil},
    ['vehicle_door'] = { item = 'recyclable_materials', amount = math.random(1,2), info = nil},
    ['vehicle_hood'] = { item = 'recyclable_materials', amount = math.random(1,2), info = nil},
    ['vehicle_trunk'] = { item = 'recyclable_materials', amount = math.random(1,2), info = nil},
}

Config.ContractRewards = {
    ['c'] = { -- Contract type
        [1] = {
            item = 'xdevice_blueprint', -- Item to give
            amount = 1, -- Amount to give
            info = nil, -- Info for the item
        },
        [2] = {
            item = 'tracker_blueprint', -- Item to give
            amount = 1, -- Amount to give
            info = nil, -- Info for the item
        },
        [3] = {
            item = 'hackusb_blueprint', -- Item to give
            amount = 1, -- Amount to give
            info = nil, -- Info for the item
        },
        [4] = {
            item = 'radio_blueprint', -- Item to give
            amount = 1, -- Amount to give
            info = nil, -- Info for the item
        },
        [5] = {
            item = 'recyclable_materials', -- Item to give
            amount = math.random(5,7), -- Amount to give
            info = nil, -- Info for the item
        },
        [6] = {
            item = 'blackmoney', -- Item to give
            amount = math.random(650,750), -- Amount to give
            info = nil, -- Info for the item
        },
        [7] = {
            item = 'crate',
            amount = 1,
            info = nil,
        }
    },
    ['b'] = {
        [1] = {
            item = 'xdevice_blueprint', -- Item to give
            amount = 1, -- Amount to give
            info = nil, -- Info for the item
        },
        [2] = {
            item = 'tracker_blueprint', -- Item to give
            amount = 1, -- Amount to give
            info = nil, -- Info for the item
        },
        [3] = {
            item = 'hackusb_blueprint', -- Item to give
            amount = 1, -- Amount to give
            info = nil, -- Info for the item
        },
        [4] = {
            item = 'radio_blueprint', -- Item to give
            amount = 1, -- Amount to give
            info = nil, -- Info for the item
        },
        [5] = {
            item = 'recyclable_materials', -- Item to give
            amount = math.random(25,35), -- Amount to give
            info = nil, -- Info for the item
        },
        [6] = {
            item = 'blackmoney', -- Item to give
            amount = math.random(650,750), -- Amount to give
            info = nil, -- Info for the item
        },
    },
    ['a'] = {
        [1] = {
            item = 'xdevice_blueprint', -- Item to give
            amount = 1, -- Amount to give
            info = nil, -- Info for the item
        },
        [2] = {
            item = 'tracker_blueprint', -- Item to give
            amount = 1, -- Amount to give
            info = nil, -- Info for the item
        },
        [3] = {
            item = 'hackusb_blueprint', -- Item to give
            amount = 1, -- Amount to give
            info = nil, -- Info for the item
        },
        [4] = {
            item = 'radio_blueprint', -- Item to give
            amount = 1, -- Amount to give
            info = nil, -- Info for the item
        },
        [5] = {
            item = 'recyclable_materials', -- Item to give
            amount = math.random(5,7), -- Amount to give
            info = nil, -- Info for the item
        },
        [6] = {
            item = 'blackmoney', -- Item to give
            amount = math.random(650,750), -- Amount to give
            info = nil, -- Info for the item
        },
    },
    ['a+'] = {
        [1] = {
            item = 'xdevice_blueprint', -- Item to give
            amount = 1, -- Amount to give
            info = nil, -- Info for the item
        },
        [2] = {
            item = 'tracker_blueprint', -- Item to give
            amount = 1, -- Amount to give
            info = nil, -- Info for the item
        },
        [3] = {
            item = 'hackusb_blueprint', -- Item to give
            amount = 1, -- Amount to give
            info = nil, -- Info for the item
        },
        [4] = {
            item = 'radio_blueprint', -- Item to give
            amount = 1, -- Amount to give
            info = nil, -- Info for the item
        },
        [5] = {
            item = 'recyclable_materials', -- Item to give
            amount = math.random(8,9), -- Amount to give
            info = nil, -- Info for the item
        },
        [6] = {
            item = 'blackmoney', -- Item to give
            amount = math.random(750,850), -- Amount to give
            info = nil, -- Info for the item
        },
    },
}