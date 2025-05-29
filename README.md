# 🚗 Meta Chop Shop

A comprehensive vehicle chopping system for FiveM servers, featuring advanced part removal, material exchange, and a dynamic economy system.

## 📝 Description

Meta Chop Shop is an advanced vehicle chopping system that allows players to dismantle vehicles for parts and materials. This resource provides a realistic and engaging experience for players who want to make money through vehicle chopping.

### ✨ Key Features
- 🔧 **Realistic Part Removal**: Physically remove vehicle parts with animations and effects
- 💱 **Material Exchange**: Convert vehicle parts into valuable crafting materials
- 💰 **Dynamic Economy**: Configurable prices and exchange rates
- 📍 **Multiple Locations**: Various chop shop and part buyer locations across the map
- 👮 **Police Integration**: Alert system and wanted levels for illegal activities
- ⭐ **XP System**: Progress through levels by chopping vehicles
- 📊 **History Tracking**: Keep track of your chopping activities and earnings

### 🛠️ Framework Support
- QB-Core
- QBX
- ESX

### 🎯 Target System Support
- ox_target
- qb-target

### 📱 Menu System Support
- ox_lib
- qb-menu

## 🚀 Features

- **🔧 Advanced Vehicle Part Removal**
  - Realistic part removal animations
  - Physical part objects with physics
  - Multiple part types (doors, hood, trunk, wheels)
  - Bone-based targeting system

- **💱 Material Exchange System**
  - Exchange vehicle parts for crafting materials
  - Multiple material types with different exchange rates
  - Configurable prices and ratios
  - Material value fluctuations

- **💰 Dynamic Economy**
  - Configurable prices for parts and materials
  - Multiple part buyer locations
  - Price ranges for different part conditions
  - Material value system

- **👮 Police Integration**
  - Configurable police requirements
  - Alert system for illegal activities
  - Wanted level system
  - Police notification system

- **⭐ XP and Leveling System**
  - Player progression through chopping
  - Level-based rewards
  - XP tracking and history
  - Achievement system

- **💻 User Interface**
  - Modern menu system (ox_lib or qb-menu)
  - Target system integration (ox_target or qb-target)
  - Progress bars and notifications
  - Detailed part status display

## 📦 Dependencies

- [qb-core](https://github.com/qbcore-framework/qb-core) or [es_extended](https://github.com/esx-framework/esx-legacy)
- [ox_lib](https://github.com/overextended/ox_lib)
- [qb-target](https://github.com/qbcore-framework/qb-target) or [ox_target](https://github.com/overextended/ox_target)

## 🎒 Required Items

The following items need to be added to your inventory system:

### 🚪 Vehicle Parts
```lua
['vehicledoor_lf'] = {
    label = 'Left Front Door',
    weight = 1000,
    stack = true,
    close = true,
    description = 'A left front vehicle door'
},
['vehicledoor_rf'] = {
    label = 'Right Front Door',
    weight = 1000,
    stack = true,
    close = true,
    description = 'A right front vehicle door'
},
['vehicledoor_lr'] = {
    label = 'Left Rear Door',
    weight = 1000,
    stack = true,
    close = true,
    description = 'A left rear vehicle door'
},
['vehicledoor_rr'] = {
    label = 'Right Rear Door',
    weight = 1000,
    stack = true,
    close = true,
    description = 'A right rear vehicle door'
},
['vehiclehood'] = {
    label = 'Vehicle Hood',
    weight = 1000,
    stack = true,
    close = true,
    description = 'A vehicle hood'
},
['vehicletrunk'] = {
    label = 'Vehicle Trunk',
    weight = 1000,
    stack = true,
    close = true,
    description = 'A vehicle trunk'
},
['vehiclewheel_lf'] = {
    label = 'Left Front Wheel',
    weight = 1000,
    stack = true,
    close = true,
    description = 'A left front vehicle wheel'
},
['vehiclewheel_rf'] = {
    label = 'Right Front Wheel',
    weight = 1000,
    stack = true,
    close = true,
    description = 'A right front vehicle wheel'
},
['vehiclewheel_lr'] = {
    label = 'Left Rear Wheel',
    weight = 1000,
    stack = true,
    close = true,
    description = 'A left rear vehicle wheel'
},
['vehiclewheel_rr'] = {
    label = 'Right Rear Wheel',
    weight = 1000,
    stack = true,
    close = true,
    description = 'A right rear vehicle wheel'
}
```

### 🛠️ Crafting Materials
```lua
['metalscrap'] = {
    label = 'Metal Scrap',
    weight = 100,
    stack = true,
    close = true,
    description = 'Scrap metal from vehicle parts'
},
['plastic'] = {
    label = 'Plastic',
    weight = 50,
    stack = true,
    close = true,
    description = 'Plastic from vehicle parts'
},
['rubber'] = {
    label = 'Rubber',
    weight = 50,
    stack = true,
    close = true,
    description = 'Rubber from vehicle parts'
},
['glass'] = {
    label = 'Glass',
    weight = 50,
    stack = true,
    close = true,
    description = 'Glass from vehicle parts'
},
['aluminum'] = {
    label = 'Aluminum',
    weight = 75,
    stack = true,
    close = true,
    description = 'Aluminum from vehicle parts'
},
['copper'] = {
    label = 'Copper',
    weight = 75,
    stack = true,
    close = true,
    description = 'Copper from vehicle parts'
}

Note: You'll need to add corresponding images for these items in your inventory system's image folder.

## 📥 Installation

1. Download the resource
2. Place it in your server's resources folder
3. Add the following to your server.cfg:
```cfg
ensure meta_chopshop
```

## ⚙️ Configuration

The resource is highly configurable through the `config.lua` file:

### 🛠️ Framework Settings
```lua
Config.Framework = 'qb' -- 'qb', 'qbx', or 'esx'
Config.MenuType = 'ox_lib' -- 'qb-menu' or 'ox_lib'
Config.TargetSystem = 'ox_target' -- 'qb-target' or 'ox_target'
```

### 📍 Blip Configuration
```lua
Config.Blips = {
    enabled = true,
    chopShop = {
        enabled = true,
        sprite = 446,
        color = 1,
        scale = 0.7,
        label = "Chop Shop"
    },
    partBuyer = {
        enabled = true,
        sprite = 446,
        color = 2,
        scale = 0.7,
        label = "Part Buyer"
    }
}
```

### 💱 Material Exchange
```lua
Config.MaterialExchange = {
    enabled = true,
    materials = {
        {
            name = "metalscrap",
            label = "Metal Scrap",
            ratio = 2,
            maxAmount = 25,
            price = {min = 25, max = 50}
        }
        -- Add more materials as needed
    }
}
```

## ⚡ Performance Considerations

The resource has been optimized for performance:

- Efficient thread management
- Proper resource cleanup
- Optimized target system
- Cached vehicle data
- Efficient menu updates

### 💡 Performance Tips

1. **Server Configuration**
   - Adjust police requirements based on server size
   - Configure appropriate cooldowns
   - Set reasonable price ranges

2. **Client Optimization**
   - Adjust debug settings
   - Configure appropriate target distances
   - Set reasonable part removal times

3. **Resource Management**
   - Monitor server performance
   - Adjust configuration as needed
   - Regular maintenance of vehicle parts

## 🆘 Support

For support, please:
1. 📚 Check the [documentation](docs/README.md)
2. 💬 Join our Discord: [discord.gg/gyHsE3ZvQs](https://discord.gg/gyHsE3ZvQs)
3. 🐛 Open an issue on GitHub

## 📄 License

This resource is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👥 Credits

- Original concept and development by namicKIDDO from Meta Scripts
- Special thanks to the FiveM community
- Contributors and testers

## 📝 Changelog

### Version 1.0.0
- Initial release
- Basic chop shop functionality
- Material exchange system
- Police integration
