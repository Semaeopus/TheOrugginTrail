// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

// get some debug OUT going
import {console} from "forge-std/console.sol";
import {System} from "@latticexyz/world/src/System.sol";
import {Output, CurrentRoomId, RoomStore, RoomStoreData, ActionStore, TextDef, DirObjStore} from "../codegen/index.sol";
import {ActionType, RoomType, ObjectType, CommandError, DirectionType} from "../codegen/common.sol";

// NOTE of interest in the return types of the functions, these
// are later used in the logs of the game provided by the MUD
// dev tooling
contract GameSetupSystem is System {

    uint32 dirId = 0;

    function init() public returns (uint32) {

        setupWorld();

        // we are right now initing the data in the
        Output.set('init called...');
        return 0;
    }

    // we need to somewhere somehow read in the possible verbs if we
    // want users to have their own VERBS
    function setupCmds(uint32 cmds) public returns (uint32) {
        // maybe populate the unused VERB tables etc? for now we just use
        // the mapping thats in the GE.
        return 23;
    }

    function setupWorld() private {
        // really wanted the code to look like this
        // createRoom(KPlain, 'You are on a plain with the wind blowing', [createDir(DirectionType.North,KBarn),createDir(DirectionType.East, KMountainPath)]);
        // but the dynamic arrays we use must be etup and passed as they are below

        uint32 KPlain = 2;
        uint32 KBarn = 1;
        uint32 KMountainPath = 0;

        // plain has two exits, the mountain path and the barn
        RoomStore.pushDirObjIds(KPlain,  createDir(DirectionType.North, KBarn));
        RoomStore.pushDirObjIds(KPlain,  createDir(DirectionType.East, KMountainPath));
        RoomStore.setDescription(KPlain,  'You are on a plain with the wind blowing');

        // barn has one exit, back to the plain
        RoomStore.pushDirObjIds(KBarn,  createDir(DirectionType.South, KPlain));
        RoomStore.setDescription(KBarn, 'You are in the barn');

        // mountain path has only one exit now, back to the plain
        RoomStore.pushDirObjIds(KMountainPath,  createDir(DirectionType.North, KPlain));
        RoomStore.pushDirObjIds(KMountainPath,  createDir(DirectionType.South, KPlain));
        RoomStore.pushDirObjIds(KMountainPath,  createDir(DirectionType.East, KPlain));
        RoomStore.pushDirObjIds(KMountainPath,  createDir(DirectionType.West, KPlain));
        RoomStore.pushDirObjIds(KMountainPath,  createDir(DirectionType.North, KPlain));
        RoomStore.setDescription(KMountainPath,  'You are on the mountain path, you cant go any further though');

    }

    function createDir(DirectionType directionType, uint32 roomId) private returns (uint32){
        DirObjStore.setDirType(dirId, directionType);
        DirObjStore.setRoomId(dirId, roomId);

        return ++dirId;
    }
}

