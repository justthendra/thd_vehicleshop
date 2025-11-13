# thd_vehicleshop

## Overview

thd_vehicleshop is a fully featured QB-Core compatible vehicle shop for
FiveM.\
It includes: - Dynamic vehicle preview system\
- Category-based browsing\
- Customizable UI with modern styling\
- Persistent randomized vehicle stats stored in MySQL\
- Built-in showroom camera\
- Automatic stat generation for all vehicles\
- Test-drive support\
- Clean and modular client/server structure

## Features

-   Random & realistic performance stats (max speed, acceleration,
    handling, brakes)
-   Server-side stat generator with MySQL persistence
-   NUI-based interactive vehicle shop interface
-   Smooth category and vehicle list navigation
-   Automatic UI camera system
-   Optimized performance
-   Easy to configure

## Installation

1.  Place the resource folder inside your FiveM `resources` directory.

2.  Add the following to your `server.cfg`:

        ensure oxmysql
        ensure thd_vehicleshop

3.  Run the SQL file to create required tables:

    -   `thd_vehicle_stats`
    -   Any vehicle shop related tables

## Image Showcase

![Showcase](https://i.imgur.com/ZUP4E5B.png)

## Requirements

-   [QB-Core Framework](https://github.com/qbcore-framework)
-   [oxmysql](https://github.com/overextended/oxmysql)

## Support

[You can come to my discord server for help.](https://discord.gg/JWx8qJ7B8W)
