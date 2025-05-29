Config = {}

-- Framework Configuration
Config.Framework = 'qb' -- 'qb', 'qbx', or 'esx'
Config.MenuType = 'ox_lib' -- 'qb-menu' or 'ox_lib'
Config.TargetSystem = 'ox_target' -- 'qb-target' or 'ox_target'

-- Debug Settings
Config.Debug = false -- Enable/disable debug mode
Config.DebugPoly = false -- Show target zones in debug mode
Config.DebugMarkers = false -- Show part markers in debug mode

-- History Configuration
Config.History = {
    enabled = true,
    maxEntries = 10, -- Maximum number of entries to keep in history
    showInMenu = true, -- Show history in the main menu
    showDetails = {
        vehicleName = true,
        plate = true,
        date = true,
        parts = true,
        earnings = true
    },
    format = {
        date = "%Y-%m-%d %H:%M", -- Date format for history entries
        currency = "$" -- Currency symbol for earnings
    }
}

-- Chop Shop Locations
Config.ChopShops = {
    {
        name = "Chop Shop 1",
        coords = vector3(2340.0, 3128.0, 48.2),
        radius = 50.0,
        blip = {
            sprite = 446,
            color = 1,
            scale = 0.8,
            label = "Chop Shop"
        }
    }
}

-- Chop Shop Ped
Config.ChopShopPed = {
    model = "s_m_y_construct_01", -- Construction worker ped
    coords = vector4(2340.0, 3128.0, 48.2, 180.0), -- x, y, z, heading
    scenario = "WORLD_HUMAN_CLIPBOARD", -- Ped animation
    options = {
        {
            label = "Open Chop Shop Menu",
            icon = "fas fa-car",
            event = "meta_chopshop:client:openMenu"
        }
    }
}

-- Drop Locations
Config.DropLocations = {
    {
        name = "Drop Point 1",
        coords = vector3(2345.0, 3130.0, 48.2),
        radius = 3.0,
        xp = 10
    }
}

-- Part Selling Configuration
Config.PartSelling = {
    enabled = true,
    locations = {
        {
            name = "Part Buyer 1",
            coords = vector3(2348.0, 3132.0, 48.2),
            radius = 3.0,
            blip = {
                sprite = 446,
                color = 2,
                scale = 0.8,
                label = "Part Buyer"
            }
        }
    },
    notifications = {
        success = "Sold part for $%d",
        failed = "Failed to sell part",
        no_parts = "You don't have any parts to sell"
    }
}

-- Blip Configuration
Config.Blips = {
    enabled = true, -- Toggle for all blips
    chopShop = {
        enabled = true, -- Toggle for chop shop blip
        sprite = 446,
        color = 1,
        scale = 0.7,
        label = "Chop Shop",
        coords = vector3(2340.0, 3128.0, 48.2)
    },
    partBuyer = {
        enabled = true, -- Toggle for part buyer blip
        sprite = 446,
        color = 2,
        scale = 0.7,
        label = "Part Buyer",
        locations = {
            vector4(2348.0, 3132.0, 48.2, 180.0), -- Original location
            vector4(1240.0, -1626.0, 53.2, 30.0), -- New location 1
            vector4(-1153.0, -1525.0, 4.3, 35.0), -- New location 2
            vector4(195.0, -934.0, 30.6, 144.0),  -- New location 3
            vector4(-1833.0, -1223.0, 13.3, 310.0) -- New location 4
        }
    }
}

-- Part Buyer Ped
Config.PartBuyerPed = {
    model = "s_m_y_dealer_01",
    scenario = "WORLD_HUMAN_CLIPBOARD",
    options = {
        {
            label = "Sell Parts",
            icon = "fas fa-dollar-sign",
            event = "meta_chopshop:client:openSellingMenu"
        }
    }
}

-- Vehicle Parts Configuration
Config.VehicleParts = {
    {
        name = "door_ds",
        label = "Driver Side Door",
        item = "vehicledoor_lf",
        time = 5000,
        bones = {
            primary = "door_dside_f",
            secondary = {"door_dside_f", "door_dside_r"},
            offset = vector3(-0.8, 0.0, 0.0),
            rotation = vector3(0.0, 0.0, 0.0)
        },
        reward = {
            item = "vehicledoor_lf",
            amount = {min = 1, max = 1},
            keep_part = true,
            sell_price = {min = 500, max = 1000}
        },
        animation = {
            dict = "mini@repair",
            anim = "fixing_a_ped"
        }
    },
    {
        name = "door_ps",
        label = "Passenger Side Door",
        item = "vehicledoor_rf",
        time = 5000,
        bones = {
            primary = "door_pside_f",
            secondary = {"door_pside_f", "door_pside_r"},
            offset = vector3(0.8, 0.0, 0.0),
            rotation = vector3(0.0, 0.0, 0.0)
        },
        reward = {
            item = "vehicledoor_rf",
            amount = {min = 1, max = 1},
            keep_part = true,
            sell_price = {min = 500, max = 1000}
        },
        animation = {
            dict = "mini@repair",
            anim = "fixing_a_ped"
        }
    },
    {
        name = "door_lr",
        label = "Left Rear Door",
        item = "vehicledoor_lr",
        time = 5000,
        bones = {
            primary = "door_dside_r",
            secondary = {"door_dside_r", "door_dside_f"},
            offset = vector3(-0.8, -0.5, 0.0),
            rotation = vector3(0.0, 0.0, 0.0)
        },
        reward = {
            item = "vehicledoor_lr",
            amount = {min = 1, max = 1},
            keep_part = true,
            sell_price = {min = 400, max = 800}
        },
        animation = {
            dict = "mini@repair",
            anim = "fixing_a_ped"
        }
    },
    {
        name = "door_rr",
        label = "Right Rear Door",
        item = "vehicledoor_rr",
        time = 5000,
        bones = {
            primary = "door_pside_r",
            secondary = {"door_pside_r", "door_pside_f"},
            offset = vector3(0.8, -0.5, 0.0),
            rotation = vector3(0.0, 0.0, 0.0)
        },
        reward = {
            item = "vehicledoor_rr",
            amount = {min = 1, max = 1},
            keep_part = true,
            sell_price = {min = 400, max = 800}
        },
        animation = {
            dict = "mini@repair",
            anim = "fixing_a_ped"
        }
    },
    {
        name = "hood",
        label = "Hood",
        item = "vehiclehood",
        time = 5000,
        bones = {
            primary = "bonnet",
            secondary = {"bonnet", "engine"},
            offset = vector3(0.0, 1.2, 0.5),
            rotation = vector3(0.0, 0.0, 0.0)
        },
        reward = {
            item = "vehiclehood",
            amount = {min = 1, max = 1},
            keep_part = true,
            sell_price = {min = 600, max = 1200}
        },
        animation = {
            dict = "mini@repair",
            anim = "fixing_a_ped"
        }
    },
    {
        name = "trunk",
        label = "Trunk",
        item = "vehicletrunk",
        time = 5000,
        bones = {
            primary = "boot",
            secondary = {
                "boot", "boot_r", "boot_l", "boot_hatch", "trunk", "trunk_r", "trunk_l", 
                "trunk_hatch", "boot_dummy", "boot_cover", "boot_cover_r", "boot_cover_l",
                "trunk_cover", "trunk_cover_r", "trunk_cover_l", "boot_hinge", "trunk_hinge"
            },
            offset = vector3(0.0, -0.8, 0.2),
            rotation = vector3(0.0, 0.0, 0.0)
        },
        reward = {
            item = "vehicletrunk",
            amount = {min = 1, max = 1},
            keep_part = true,
            sell_price = {min = 600, max = 1200}
        },
        animation = {
            dict = "mini@repair",
            anim = "fixing_a_ped"
        }
    },
    {
        name = "wheel_lf",
        label = "Left Front Wheel",
        item = "vehiclewheel_lf",
        time = 5000,
        bones = {
            primary = "wheel_lf",
            secondary = {"wheel_lf", "wheel_lf_dummy"},
            offset = vector3(-0.8, 1.2, -0.5),
            rotation = vector3(0.0, 0.0, 0.0)
        },
        reward = {
            item = "vehiclewheel_lf",
            amount = {min = 1, max = 1},
            keep_part = true,
            sell_price = {min = 300, max = 600}
        },
        animation = {
            dict = "mini@repair",
            anim = "fixing_a_ped"
        }
    },
    {
        name = "wheel_rf",
        label = "Right Front Wheel",
        item = "vehiclewheel_rf",
        time = 5000,
        bones = {
            primary = "wheel_rf",
            secondary = {"wheel_rf", "wheel_rf_dummy"},
            offset = vector3(0.8, 1.2, -0.5),
            rotation = vector3(0.0, 0.0, 0.0)
        },
        reward = {
            item = "vehiclewheel_rf",
            amount = {min = 1, max = 1},
            keep_part = true,
            sell_price = {min = 300, max = 600}
        },
        animation = {
            dict = "mini@repair",
            anim = "fixing_a_ped"
        }
    },
    {
        name = "wheel_lr",
        label = "Left Rear Wheel",
        item = "vehiclewheel_lr",
        time = 5000,
        bones = {
            primary = "wheel_lr",
            secondary = {"wheel_lr", "wheel_lr_dummy"},
            offset = vector3(-0.8, -1.2, -0.5),
            rotation = vector3(0.0, 0.0, 0.0)
        },
        reward = {
            item = "vehiclewheel_lr",
            amount = {min = 1, max = 1},
            keep_part = true,
            sell_price = {min = 300, max = 600}
        },
        animation = {
            dict = "mini@repair",
            anim = "fixing_a_ped"
        }
    },
    {
        name = "wheel_rr",
        label = "Right Rear Wheel",
        item = "vehiclewheel_rr",
        time = 5000,
        bones = {
            primary = "wheel_rr",
            secondary = {"wheel_rr", "wheel_rr_dummy"},
            offset = vector3(0.8, -1.2, -0.5),
            rotation = vector3(0.0, 0.0, 0.0)
        },
        reward = {
            item = "vehiclewheel_rr",
            amount = {min = 1, max = 1},
            keep_part = true,
            sell_price = {min = 300, max = 600}
        },
        animation = {
            dict = "mini@repair",
            anim = "fixing_a_ped"
        }
    }
}

-- Police Configuration
Config.Police = {
    required = 0, -- Minimum police required
    wanted = {
        enabled = true,
        level = 2
    },
    alert = {
        enabled = true,
        chance = 30, -- Percentage chance to alert police
        cooldown = 60 -- Seconds between alerts
    }
}

-- Blacklisted Vehicles
Config.BlacklistedVehicles = {
    "police",
    "police2",
    "police3",
    "police4",
    "policeb",
    "policet",
    "sheriff",
    "sheriff2",
    "ambulance",
    "firetruk"
}

-- Notifications
Config.Notifications = {
    in_vehicle = "You cannot chop parts while in a vehicle",
    too_far = "You are too far from the chop shop",
    blacklisted = "This vehicle cannot be chopped",
    failed = "Failed to chop part",
    alert = "Chop shop activity reported at %s"
}

-- Features
Config.UseAnimations = true
Config.UseProgressBar = true

-- Material Exchange Configuration
Config.MaterialExchange = {
    enabled = true,
    materials = {
        {
            name = "metalscrap",
            label = "Metal Scrap",
            icon = "cog",
            ratio = 2,
            maxAmount = 25,
            price = {min = 25, max = 50},
            requiredParts = "Any 2 vehicle parts",
            description = "Exchange any 2 vehicle parts for 1 metal scrap"
        },
        {
            name = "plastic",
            label = "Plastic",
            icon = "flask",
            ratio = 3,
            maxAmount = 25,
            price = {min = 15, max = 35},
            requiredParts = "Any 3 vehicle parts",
            description = "Exchange any 3 vehicle parts for 1 plastic"
        },
        {
            name = "rubber",
            label = "Rubber",
            icon = "circle",
            ratio = 2,
            maxAmount = 25,
            price = {min = 10, max = 25},
            requiredParts = "Any 2 vehicle parts",
            description = "Exchange any 2 vehicle parts for 1 rubber"
        },
        {
            name = "glass",
            label = "Glass",
            icon = "window-maximize",
            ratio = 3,
            maxAmount = 25,
            price = {min = 20, max = 40},
            requiredParts = "Any 3 vehicle parts",
            description = "Exchange any 3 vehicle parts for 1 glass"
        },
        {
            name = "aluminum",
            label = "Aluminum",
            icon = "cube",
            ratio = 3,
            maxAmount = 25,
            price = {min = 30, max = 60},
            requiredParts = "Any 3 vehicle parts",
            description = "Exchange any 3 vehicle parts for 1 aluminum"
        },
        {
            name = "copper",
            label = "Copper",
            icon = "bolt",
            ratio = 4,
            maxAmount = 25,
            price = {min = 35, max = 75},
            requiredParts = "Any 4 vehicle parts",
            description = "Exchange any 4 vehicle parts for 1 copper"
        }
    },
    notifications = {
        success = "Successfully exchanged %d parts for %d %s",
        failed = "Failed to exchange parts",
        no_parts = "You don't have enough parts for this exchange",
        max_reached = "You've reached the maximum amount for this material",
        exchange_info = "You need %d parts to exchange for %s",
        available_parts = "You have %d parts available for exchange"
    }
} 