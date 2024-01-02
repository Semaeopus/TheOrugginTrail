import { mudConfig } from "@latticexyz/world/register";

export default mudConfig({
    enums: {
        // all places on the 2d map grid are either Void or Place:
        // 0x00 | 0x01
        // Voids/None have no Objects cant be travelled through etc.
        //
        // Places have Objects
        // Objects have Actions, eg Chests can Open or not.
        // Actions generate NESS or Bool
        // ie. "Lock Door":
        // the Room/Place with Door with Lock -> Lock-NESS -> Place(Door(Lock(NESS(1))))
        // NB This doesn't equate to Open-NESS, a door could be LockY AND OpenY
        //
        // NB Something else abour Doors
        // They are DirectionObjects.
        // DirectionObjects also have a Direction
        // an ObjectType, when they are in a map they are a Portal. It allows us to
        // map a map, and it allows us to link a Places Door to the portal that it
        // links to. Portals connect non void places on the map.
        //
        // For now fuck it...
        //
        // we will use the keys for left shifting values
        // in a 32 bit var so we have maskable state from the
        // map data
        TypeKeys: [
            "None", "BiomeTypes", "TerrainTypes",
            "RoomType", "ActionType",
        ],
        // probably pointless
        BiomeType: [
            "None", "Tundra", "Arctic", "Temporate",
            "Alpine", "Jungle", "Faery"
        ],
        // Terrain has paths
        TerrainType: [
            "None", "Path", "Forest", "Plains",
            "Mud", "DirtPath", "Portal"
        ],
        // Rooms have doors/exits
        RoomType: [
            "None", "WoodCabin", "Store",
            "Cavern", "StoneCabin", "Fort"
        ],
        // use these to set direction bits on a DirectionObject
        // such as a door
        DirectionType: [
            "None", "North", "South", "East", "West",
            "Up", "Down", "Forward", "Backwards"
        ],
        // add a direction action to these to connect rooms
        // then add them to a room
        DirObjectType: [
            "None", "Door", "Window", "Stairs", "Ladder"
        ],
        // use these in the parser, they are VERBS
        //
        ActionType: [
            "None", "Go", "Move", "Loot", "Describe",
            "Take", "Kick", "Lock", "Unlock", "Open", "Drop"
        ],
        // add these to rooms for stuff to do
        ObjectType: [
            "None", "Ball", "Key", "Knife", "Bottle"
        ],
        GrammarType: ["None", "DefiniteArticle", "Preposition"],
        MaterialType: ["None", "Wood", "Stone", "Iron", "Shit", "IKEA", "Flesh"],
        TexDefType: ["None", "Door", "WoodCabin", "DirtPath"],
        CommandError: ["NONE", "LEN", "NOP", "GONOWHERE", "GOWHERE"],
    },
    tables: {
        // all rooms take a description and a set of Objects that themselves
        // have descriptions and Actions.
        RoomStore: {
            keySchema: {
                roomId: "uint32",
            },
            valueSchema: {
                roomType: "RoomType",
                textDefId: "uint32",
                description: "string", //temp
                objectIds: "uint32[]",
                dirObjIds: "uint32[]",
            },
        },
        // Actions have a NESSy property
        // like are they doable, do'y
        // eg a Winow can have an Open ActionType
        // so that would make it NESSy OpenY
        // this isn't the same as it being Open
        // it's wether it can be opened, Openy
        ActionStore: {
            keySchema: {
                actionId: "uint32",
            },
            valueSchema: {
                actionType: "ActionType",
                texDefId: "uint32",
                // the next 2 are a pair really a door is a good example
                // is it nESSy: ie. is it just a prop
                // if it IS then CAN it be, like has it been unlocked
                nESSy: "bool", // can it be used?
                enabled: "bool" // is it useable if it CAN be used
            },
        },
        // attach to rooms/paths to set the exits
        // give it a DirObjType like DOOR
        // then give it a directionType like NORTH
        // then give it an Action like OPEN or LOCKED
        // or BOTH!
        DirObjStore: {
            keySchema: {
                dirObjId: "uint32",
            },
            valueSchema: {
                objType: "DirObjectType", // Door/Window/CaveMouth etc
                dirType: "DirectionType", // North, South, Up etc
                destId: "uint32",
                objectActionIds: "uint32[]" // Open/Lock/Break etc
            },
        },
        ObjectStore: {
            keySchema: {
                objectId: "uint32",
            },
            valueSchema: {
                objectType: "ObjectType",
                materialType: "MaterialType",
                texDefId: "uint32",
                objectActionIds: "uint32[]",
            },
        },
        // we are going to store a hash over the actual description
        // string/s here (keccak256) that will then be used as the key for the compressed
        // data on the client which de-compresses it from some form of hash map or what have you
        // it should be generated by build tools. It isn't.
        TextDef: {
            keySchema: {
                texDefId: "uint32",
                texDefType: "uint8",
            },
            valueSchema: "bytes",
        },
        Output: {
            keySchema: {},
            valueSchema: "string",
        },
        CurrentPlayerId: {
            keySchema: {},
            valueSchema: "uint32",
        },
        Player: {
            keySchema: {
                playerId: "uint32",
            },
            valueSchema: {
                roomId: "uint32",
                objectIds: "uint32[]",
            },
        },
    },
});
