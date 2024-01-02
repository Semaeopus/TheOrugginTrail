// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

// get some debug OUT going
import {console} from "forge-std/console.sol";

import {System} from "@latticexyz/world/src/System.sol";
import {ObjectStoreData, ObjectStore, Player, Output, CurrentPlayerId, RoomStore, RoomStoreData, ActionStore, DirObjStore, DirObjStoreData, TextDef} from "../codegen/index.sol";
import {ActionType, RoomType, ObjectType, CommandError, DirectionType} from "../codegen/common.sol";
import {CommandLookups} from "./CommandLookup.sol";
import {GameConstants, ErrCodes, ResCodes} from "../constants/defines.sol";

// an attempt at calling another system
// we nneed the below
import {SystemSwitch} from "@latticexyz/world-modules/src/utils/SystemSwitch.sol";
// then the system interface
import {IGameSetupSystem} from "../codegen/world/IGameSetupSystem.sol";

import {console} from "forge-std/console.sol";

contract MeatPuppetSystem is System, GameConstants, ErrCodes, ResCodes, CommandLookups {

    // TODO:
    // * common parser should be the same for actions as for
    //   directions:
    //   dircmd = "go", ["to"], target | dir;
    //   dir = north | south | east | west;
    //   target = object;
    //   object = ...

    event debugLog(string msg, uint8 val);

    // we call this from the post deploy contract
    function initGES() public returns (uint32) {
        Output.set('initGES called...');

        // i dont like this there must be a cleaner way
        // perhaps we should init() all systems via postdeploy ??
        initCLS();

        // our empty test function from the GSS that just returns a uint32
        // for ref of how to call another systen, I think the system has to
        // be in the root namespace but it would be handy to figure out
        // how to actually use namespaces properly, its in the docs but not
        // exactly clear
        uint32 returnValue = abi.decode(
            SystemSwitch.call(
                abi.encodeCall(IGameSetupSystem.setupCmds, (22))
            ),
            (uint32)
        );

        spawn(0);
        return 0;
    }

    function spawn(uint32 startId) public {
        console.log("spawn");
        // start on the plain
        _enterRoom(1);
    }

    function _describeRoom(uint32 rId) private returns (string memory) {
        console.log("--------->DescribeRoom:");
        RoomStoreData memory currRoom = RoomStore.get(rId);
        return string(abi.encodePacked(currRoom.description, "\n",
            "You can go", _describeActions(rId), _describeObjects(rId))
        );
    }

    // MOVE TO OWN SYSTEM -- MEATWHISPERER
    /* build up the text description strings for general output */
    function _describeActions(uint32 rId) private returns (string memory) {
        console.log("--------->DescribeActions:");
        RoomStoreData memory currRm = RoomStore.get(rId);
        string[8] memory dirStrings;
        string memory msgStr;
        for (uint8 i = 0; i < currRm.dirObjIds.length; i++) {
            DirObjStoreData memory dir = DirObjStore.get(currRm.dirObjIds[i]);

            if (dir.dirType == DirectionType.North) {
                dirStrings[i] = " North";
            } else if (dir.dirType == DirectionType.East) {
                dirStrings[i] = " East";
            } else if (dir.dirType == DirectionType.South) {
                dirStrings[i] = " South";
            } else if (dir.dirType == DirectionType.West) {
                dirStrings[i] = " West";
            } else {dirStrings[i] = " to hell";}
        }
        for (uint16 i = 0; i < dirStrings.length; i++) {
            msgStr = string(abi.encodePacked(msgStr, dirStrings[i]));
        }
        return msgStr;
    }

    function _describeObjects(uint32 rId) private returns (string memory) {
        console.log("--------->DescribeObjects:");

        RoomStoreData memory currRm = RoomStore.get(rId);

        if (currRm.objectIds.length == 0) return "";

        string[8] memory objStrings;
        string memory msgStr;
        for (uint8 i = 0; i < currRm.objectIds.length; i++) {
            ObjectStoreData memory obj = ObjectStore.get(currRm.objectIds[i]);

            if (obj.objectType == ObjectType.Ball) {
                objStrings[i] = " Ball";
            } else if (obj.objectType == ObjectType.Key) {
                objStrings[i] = " Key";
            } else if (obj.objectType == ObjectType.Knife) {
                objStrings[i] = " Knife";
            } else if (obj.objectType == ObjectType.Bottle) {
                objStrings[i] = " Bottle";
            }
        }

        msgStr = "\nThis room contains";
        for (uint16 i = 0; i < objStrings.length; i++) {
            msgStr = string(abi.encodePacked(msgStr, objStrings[i]));
        }
        return msgStr;
    }

    function _enterRoom(uint32 rId) private returns (uint8 err) {
        console.log("--------->CURR_RM:", rId);
        Player.setRoomId(CurrentPlayerId.get(), rId);
        Output.set(_describeRoom(rId));
        return 0;
    }

    // MOVE TO OWN SYSTEM -- MEATCOMMANDER
    /* handle NON MOVEMENT VERBS */
    function _handleAction(string[] memory tokens, uint32 rId) private returns (uint8 err) {
        console.log("---->HDL_ACT", tokens[1]);

        string memory tok1 = tokens[0];

        if (cmdLookup[tok1] == ActionType.Take) {
            return _take(tokens, rId);
        }

        return 0;
    }


    function _take(string[] memory tokens, uint32 rId) private returns (uint8 err) {
        console.log("----->TAKE :", tokens[1]);
        uint8 tok_err;
        string memory tok = tokens[1];

        ObjectType objType = objLookup[tok];

        if (objType != ObjectType.None) {

            uint32[] memory objIds = RoomStore.getObjectIds(rId);

            for(uint8 i = 0 ; i < objIds.length ; i++) {

                ObjectType testType = ObjectStore.getObjectType(objIds[i]);

                if(testType == objType) {

                    Output.set("You picked it up");
                    Player.pushObjectIds(CurrentPlayerId.get(), objIds[i]);

                    objIds[i] = 999;

                    RoomStore.setObjectIds(rId, objIds);
                    break;
                }
            }
        }

        return 0;
    }


    // MOVE TO ITS OWN SYTEM -- MEATMOVER
    /* handle MOVEMENT to DIRECTIONs or THINGs */
    function _movePlayer(string[] memory tokens, uint32 currRmId) private returns (uint8 err) {
        console.log("----->MV_PL to: ", tokens[0]);
        uint8 tok_err;
        string memory tok = tokens[0];
        if (dirLookup[tok] != DirectionType.None) {
            /* Direction form
            *
            * dir = n | e | s | w
            *
            */
            tok_err = 0;
        } else if (cmdLookup[tok] == ActionType.Go) {
            /* GO form
            *
            * go_cmd = go, [(pp da)], dir | obj
            * pp = "to";
            * da = "the";
            * dir = n | e | s | w
            */
            if (tokens.length >= 4) {
                /* long form */
                /* go_cmd = go, ("to" "the"), dir|obj */
                tok = tokens[3];
            } else if (tokens.length == 2) {
                /* short form */
                /* go_cmd = go, dir|obj */
                tok = tokens[1];
                // dir | obj
                if (dirLookup[tok] == DirectionType.None) {return ER_DR_ND;}
                //TODO: handle for obj
                tok_err = 0;
            }

        }

        if (tok_err != 0) {return tok_err;}
        /* do direction tests */
        DirectionType DIR = dirLookup[tok];
        (bool mv, uint32 dObjId) = _directionCheck(currRmId, DIR);
        if (mv) {
            console.log("->MP--->DOBJ:", dObjId);
            uint32 nxtRm = DirObjStore.getDestId(dObjId);
            console.log("->MP --------->NXTRM:", nxtRm);
            _enterRoom(nxtRm);
            return 0;
        } else {
            console.log("--->DC:0000");
            // check reason we didnt move this can currently only
            // be cannot actually move that way because no exit
            //string memory errMsg;
            //errMsg = _insultMeat(GO_NO_EXT, tok);
            //Output.set(errMsg);
            return GO_NO_EXIT;
        }
    }

    // currently just handles if the DIR matches an dirObjs dirType value
    // needs to also test lockedness/openability
    function _directionCheck(uint32 rId, DirectionType d) private returns (bool success, uint32 next) {
        console.log("---->DC room:", rId, "---> DR:", uint8(d));
        uint32[] memory exitIds = RoomStore.getDirObjIds(rId);

        console.log("---->DC room:", rId, "---> EXITIDS.LEN:", uint8(exitIds.length));
        for (uint8 i = 0; i < exitIds.length; i++) {

            console.log("-->i:", i, "-->[]", uint32(exitIds[i]));
            // just for debug output
            DirectionType dt = DirObjStore.getDirType(exitIds[i]);
            console.log("-->i:", i, "-->", uint8(dt));
            if (DirObjStore.getDirType(exitIds[i]) == d) {return (true, exitIds[i]);}
        }
        // bad idea but we use 0 as a roomId
        // need to fix, we should stick with Solidity idiom
        // which is 0 is always false/None/Null
        return (false, 0x10000);
    }

    // intended soley to process tokens and then hand off to other systems
    // checks for first TOKEN which can be either a GO or another VERB.
    // Assuming these look good then in an ideal world drops token[0] and
    // passes the tail to either the movement system or the actions system
    // Actually we dont because actually doing that is an expensive op in Sol
    // and therefore the EVM (???) so we pass the whole thing
    function processCommandTokens(string[] calldata tokens) public returns (uint8 err) {
        /* see action diagram in VP (tokenise) for logic */

        uint32 rId = Player.getRoomId(CurrentPlayerId.get());

        uint8 err;
        // guaranteed to init to 0 value
        if (tokens.length > MAX_TOK) {
            err = ER_PR_TK_CX;
        }

        string memory tok1 = tokens[0];
        console.log("---->PR", tok1);
        console.log("---->PR ---->TOK[0]", uint8(dirLookup[tok1]));
        if (dirLookup[tok1] != DirectionType.None) {
            err = _movePlayer(tokens, rId);
        } else if (cmdLookup[tok1] != ActionType.None) {
            if (tokens.length >= 2) {
                if (cmdLookup[tok1] == ActionType.Go) {
                    err = _movePlayer(tokens, rId);
                } else {
                    err = _handleAction(tokens, rId);
                }
            } else {
                err = ER_PR_NO;
            }
        } else {
            err = ER_PR_NOP;
        }

        /* we have gone through the TOKENS, give err feedback if needed */
        if (err != 0) {
            console.log("----->PCR_ERR: err:", err);
            string memory errMsg;
            errMsg = _insultMeat(err, "");
            Output.set(errMsg);
            return err;
        }
    }

    //MOVE TO ITS OWN SYTEM - MEATINSULTOR
    /* process errors and build up err output */
    function _insultMeat(uint8 ce, string memory badCmd) private pure returns (string memory) {
        string memory eMsg;
        if (ce == ER_PR_TK_CX) {
            eMsg = "WTF, slow down cowboy, your gonna hurt yourself";
        } else if (ce == ER_PR_NOP || ce == ER_PR_TK_C1) {
            eMsg = "Nope, gibberish\n"
            "Stop breathing with your mouth.";
        } else if (ce == ER_PR_ND || ce == ER_DR_ND) {
            eMsg = "Go where pilgrim?";
        } else if (ce == ER_DR_NOP) {
            eMsg = string(abi.encodePacked("Go ", badCmd, " is nowhere I know of bellend"));
        } else if (ce == GO_NO_EXIT) {
            eMsg = string(abi.encodePacked("Can't go that away", badCmd));
        }
        return eMsg;
    }


}

