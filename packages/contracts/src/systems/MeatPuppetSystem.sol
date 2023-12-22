// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

// get some debug OUT going
import { console } from "forge-std/console.sol";

import {System} from "@latticexyz/world/src/System.sol";
import {Output, CurrentRoomId, RoomStore, RoomStoreData, ActionStore, DirObjStore, DirObjStoreData, TextDef} from "../codegen/index.sol";
import {ActionType, RoomType, ObjectType, CommandError, DirectionType} from "../codegen/common.sol";
import { CommandLookups } from "./CommandLookup.sol";
import { GameConstants } from "../constants/defines.sol";

contract MeatPuppetSystem is System, GameConstants, CommandLookups  {

    // we call this from the post deploy contract
    function initGES() public returns (uint32) {
        Output.set('initGES called...');
        initCLS();
        spawn(0);
        return 0;
    }

    function spawn(uint32 startId) public {
       _enterRoom(0);
    }

    // we are building these up but they should be attached to the DirObj ??
    // but either this is wrong or we dont have any direction types set
    function _describeActions(uint32 rId) private returns (string memory) {
        RoomStoreData memory currRm = RoomStore.get(rId);
        string[8] memory dirStrings;
        string memory msgStr;
        for(uint8 i = 0; i < currRm.dirObjIds.length; i++) {
            DirObjStoreData memory dir = DirObjStore.get(currRm.dirObjIds[1]);
            if (uint8(dir.dirType) == uint8(DirectionType.North)) {
                dirStrings[i] = "North";
            }else if (uint8(dir.dirType) == uint8(DirectionType.East)) {
                dirStrings[i] = "East";
            }else {
                dirStrings[i] = "to Hell";
            }
        }
        for(uint16 i = 0; i < dirStrings.length; i++) {
            msgStr = string(abi.encodePacked(msgStr, " ", dirStrings[i]));
        }
        return msgStr;
    }

    function _enterRoom(uint32 rId) private returns (uint32 err) {
        // TODO:  on entering describe the room
        CurrentRoomId.set(rId);
        RoomStoreData memory currRoom = RoomStore.get(CurrentRoomId.get());
        string memory actions = _describeActions(rId);
        string memory pack = string(abi.encodePacked(currRoom.description, "\n",
                                                      "You can go ", _describeActions(rId))
                                   );
        Output.set(pack);

        return 0;
    }

    // we really should return a id to a hash table of compressed data, we shouldnt
    // be storing this shite here
    function _beWitty(CommandError ce, string memory badCmd) private pure returns (string memory) {
        string memory eMsg;
        if (ce == CommandError.LEN) {
        eMsg = "WTF, slow down cowboy, your gonna hurt yourself";
        } else if (ce == CommandError.NOP) {
            eMsg = "Nope, gibberish\n"
            "Stop breathing with your mouth.";
        } else if (ce == CommandError.GONOWHERE) {
            eMsg = "Go where pilgrim?";
        } else if (ce == CommandError.GOWHERE) {
            eMsg = string(abi.encodePacked("Go ", badCmd, " is nowhere I know of bellend"));
        }
        return eMsg;
    }


    // should probably not return a uint8 but a CommandError
    function processCommandTokens(string[] calldata tokens) public returns (uint8 err) {

        if (tokens.length > MAX_TOK ) {
            string memory response = _beWitty(CommandError.LEN, "");
            Output.set(response);
            return uint8(CommandError.LEN);
        }

        for (uint8 i = 0; i < tokens.length; i++) {
            // we want to compare against our mapped sting => enum
            // data structure which takes strings we have tokenised
            string memory vrb = tokens[i];
            if (cmdLookup[vrb] != ActionType.None) {
                ActionType VERB = cmdLookup[vrb];
                if (VERB == ActionType.Go && tokens.length >= 2) {
                    // hand off here to the engine it should take the current room id
                    // this is just a start... GO is easy
                    DirectionType DIR = dirLookup[tokens[1]];
                    if (DIR != DirectionType.None) {


                        //----
                        uint32 currentRoomId = CurrentRoomId.get();
                        uint32[] memory dirs = RoomStore.getDirObjIds(currentRoomId);
                        for (uint8 i = 0 ; i < dirs.length ; i ++) {
                            DirObjStoreData memory dirObjectStoreData = DirObjStore.get(dirs[i]);



                            if (dirObjectStoreData.dirType == uint8(DIR)) {

                            }
                        }
                        //----

                        _enterRoom(currentRoomId);
                        return uint8(CommandError.NONE);
                    }else {
                        Output.set(_beWitty(CommandError.GOWHERE, tokens[1]));
                        return uint8(CommandError.NOP);
                    }
                } else {
                    // didnt give use enough tokens for verb
                    Output.set(_beWitty(CommandError.GONOWHERE, ""));
                    return 12; //uint8(CommandError.NOP);
                }
            }else {
                Output.set(_beWitty(CommandError.NOP, ""));
                return 3;}
        }
       return 0;
    }
}

