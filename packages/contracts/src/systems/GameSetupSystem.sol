// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

// get some debug OUT going
import {console} from "forge-std/console.sol";
import {System} from "@latticexyz/world/src/System.sol";
import {ObjectStore, Player, Output, CurrentPlayerId, RoomStore, RoomStoreData, ActionStore, TextDef, DirObjStore} from "../codegen/index.sol";
import {ActionType, RoomType, ObjectType, CommandError, DirectionType} from "../codegen/common.sol";

// NOTE of interest in the return types of the functions, these
// are later used in the logs of the game provided by the MUD
// dev tooling
contract GameSetupSystem is System {

    uint32 dirId = 0;
    uint32 objId = 0;

    function init() public returns (uint32) {

        setupWorld();

        // we are right now initing the data in the
        Output.set('init called...');
        return 0;
    }

    // left in here as an example for how to call systems via the world
    // see MeatPuppetSystem for call
    function setupCmds(uint32 cmds) public returns (uint32) {
       // maybe populate the unused VERB tables etc? for now we just use
       // the mapping thats in the GE.
       return 23;
    }

    function setupWorld() private {
        setupRooms();
        setupPlayer();
    }

    function setupPlayer() private {
        // tim, whats the method to create a random int32????
        CurrentPlayerId.set(1);
    }

    function setupRooms() private {
        uint32 KPlain = 2;
        uint32 KBarn = 1;
        uint32 KMountainPath = 0;

        // plain has two exits, the mountain path and the barn
        RoomStore.pushDirObjIds(KPlain,  createDir(DirectionType.North, KBarn));
        RoomStore.pushDirObjIds(KPlain,  createDir(DirectionType.East, KMountainPath));
        RoomStore.setDescription(KPlain,  'You are on a plain with the wind blowing');
        RoomStore.pushObjectIds(KPlain, createObject(ObjectType.Ball));

        // barn has one exit, back to the plain
        RoomStore.pushDirObjIds(KBarn,  createDir(DirectionType.South, KPlain));
        RoomStore.setDescription(KBarn, 'You are in the barn');

        // mountain path has only one exit now, back to the plain
        RoomStore.pushDirObjIds(KMountainPath,  createDir(DirectionType.West, KPlain));
        RoomStore.setDescription(KMountainPath,  'You are on the mountain path, you cant go any further though');
    }

    // this is where the bug was, we should get rid of this and create a UID or something
    // this is the case for all the id's really... well perhaps?
    function createDir(DirectionType directionType, uint32 dstRoomId) private returns (uint32){
        DirObjStore.setDirType(dirId, directionType);
        DirObjStore.setDestId(dirId, dstRoomId);
        return dirId++;
    }


    function createObject(ObjectType objectType) private returns (uint32){
        ObjectStore.setObjectType(objId, objectType);
        return objId++;
    }

}

