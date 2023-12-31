// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

// get some debug OUT going
import { console } from "forge-std/console.sol";
import { System } from "@latticexyz/world/src/System.sol";
import { ErrCodes } from '../constants/defines.sol';
import { Description, ObjectStore, ObjectStoreData , DirObjectStore, DirObjectStoreData, Player, Output, CurrentPlayerId, RoomStore, RoomStoreData, ActionStore, TextDefStore } from "../codegen/index.sol";
import { ActionType, RoomType, ObjectType, CommandError, DirectionType, DirObjectType, TxtDefType, MaterialType } from "../codegen/common.sol";

// NOTE of interest in the return types of the functions, these
// are later used in the logs of the game provided by the MUD
// dev tooling
contract GameSetupSystem is System {

    uint32 dirObjId = 1;
    uint32 objId = 1;
    uint32[256] private map;

    function init() public returns (uint32) {

        setupWorld();

        // we are right now initing the data in the
        Output.set('init called...');
        return 0;
    }

    function getArrayValue(uint8 index) public view returns (uint32, uint8 er) {
        if (index > 255) {
            return (0, ErrCodes.ER_AR_BNDS);
        }
        return (map[index], 0);
    }

    function setupWorld() private {
        setupRooms();
        setupPlayer();
    }
    
    function guid() private view returns (uint32) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                block.timestamp, 
                block.prevrandao, 
                blockhash(block.number - 1), 
                msg.sender
            )
        );
        return uint32(uint256(hash));
    }

    function setupPlayer() private {
        // tim, whats the method to create a random int32????
        // Daren, there is no pseudo random number gen but there
        // is some semi entropic stuff we can hash see guid()
        CurrentPlayerId.set(guid());
    }

    function clearArr(uint32[] memory arr) private pure {
        for (uint8 i = 0; i < 32; i++) {
            arr[i] = 0;
        }
    }

    function createPlace(uint32 id, uint32[] memory dirObjects, uint32[] memory objects, bytes32 txtId) public { 
        for (uint8 i = 0; i < dirObjects.length; i++) {
            RoomStore.pushDirObjIds(id, dirObjects[i]);
        }
        for (uint8 i = 0; i < objects.length ; i++) {
            RoomStore.pushObjectIds(id, objects[i]);
        }
        RoomStore.setTxtDefId(id,txtId);
    }

    function setupRooms() private {
        uint32 KPlain = 2;
        uint32 KBarn = 1;
        uint32 KMountainPath = 0;

        // much bigger than this and it seems to blow up the stack?
        // panic capicty error hence I assume blown stack
        uint32[] memory dids = new uint32[](32);
        uint32[] memory oids = new uint32[](32);

        // KPLAIN
        dids[0] = createDirObj(DirectionType.North, KBarn, 
                              DirObjectType.Path, MaterialType.Dirt, 
                              "A Path");

        dids[1] = createDirObj(DirectionType.East, KMountainPath, 
                              DirObjectType.Path, MaterialType.Mud,
                              "A path");
        
        oids[0] = createObject(ObjectType.Football, MaterialType.Flesh,
                                "A slightly deflated knock off uefa football,"
                                "not quite speherical, it's "
                                "kickable though");

        RoomStore.setDescription(KPlain,  'A Plain');
        
        bytes32 tid_plain = keccak256(abi.encodePacked('You are on a plain'));
        TextDefStore.set(tid_plain, TxtDefType.Place, KPlain, "You are on a plain with the wind blowing"
                                                                " bison skulls in piles taller than houses"
                                                                " cover the plains as far as your eye can see"
                                                                " the air tastes of burnt grease and bensons.");
                                                                
        createPlace(KPlain, dids, oids, tid_plain); 


        //KBARN
        clearArr(dids);
        clearArr(oids);

        dids[0] = createDirObj(DirectionType.South, KPlain,
                                DirObjectType.Door, MaterialType.Wood,
                                "A Door"
                               ); 

        bytes32 tid_barn = keccak256(abi.encodePacked("The Barn"));
        TextDefStore.set(tid_barn, TxtDefType.Place, KBarn,
                                                    "The place is dusty and full of spiderwebs,"
                                                    " something died in here, possibly your own self"
                                                    " plenty of corners and dark shadows");

        RoomStore.setDescription(KBarn, 'A Barn');// this should be auto gen

        createPlace(KBarn, dids, oids, tid_barn);

        // KPATH
        clearArr(dids);
        clearArr(oids);
        dids[0] = createDirObj(DirectionType.West, KPlain,
                               DirObjectType.Path, MaterialType.Dirt,
                               "A PaTh");

        bytes32 tid_mpath = keccak256(abi.encodePacked("Mountain Track"));
        TextDefStore.set(tid_mpath, TxtDefType.Place, KMountainPath,
                         "A high pass through the mountains, the path is treacheorus"
                         " trees cover the perilous valley sides below you, toilet papered"
                         " on closer inspection it might be the remains of a criket team"
                         " it's brass monkeys.");
        
        RoomStore.setDescription(KMountainPath,  "A Mountain Track");
        createPlace(KMountainPath, dids, oids, tid_mpath);
    }

    

    function createDirObj(DirectionType dirType, uint32 dstId, DirObjectType dOType,
                                                    MaterialType mType,string memory desc) 
                                                                    private returns (uint32) {
        bytes32 txtId = keccak256(abi.encodePacked(desc));
        TextDefStore.set(txtId, TxtDefType.DirObject, dirObjId, desc);
        uint32[] memory actions = new uint32[](0);
        DirObjectStoreData memory dirObjData = DirObjectStoreData(dOType, dirType, mType, dstId, txtId, actions); 
        DirObjectStore.set(dirObjId, dirObjData);

        return dirObjId++;
    }

    function createObject(ObjectType objType, MaterialType mType, string memory desc) private returns (uint32){
        bytes32 txtId = keccak256(abi.encodePacked(desc));
        TextDefStore.set(txtId, TxtDefType.Object, objId, desc); 
        uint32[] memory actions = new uint32[](0);
        ObjectStoreData memory objData = ObjectStoreData(objType, mType, txtId, actions); 
        ObjectStore.set(objId, objData);
        return objId++;
    }
}

