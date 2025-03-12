extends Node


const PLANET_CONFIGS = [
    {
        "id": "Planet_1",
        "name": "Alpha Station",
        "posX": -800,
        "posY": 0,
        "scale": 4.0,
        "texture": "planet",  # Base texture name in res://Textures/
        "resource_cost": {
            "gas": 10,
            "scrap": 5
        }
    },
    {
        "id": "Planet_2",
        "name": "Beta Outpost",
        "posX": -400,
        "posY": 200,
        "scale": 4.5,
        "texture": "planet_red",
        "resource_cost": {
            "gas": 20,
            "scrap": 10
        }
    },
    {
        "id": "Planet_3",
        "name": "Gamma Haven",
        "posX": 0,
        "posY": -150,
        "scale": 5.0,
        "texture": "planet_blue",
        "resource_cost": {
            "gas": 30,
            "scrap": 15
        }
    }
]