// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import { console } from "forge-std/console.sol";

import {System} from "@latticexyz/world/src/System.sol";

import { IWorld } from "../codegen/world/IWorld.sol";

import { GameConstants, ErrCodes, ResCodes } from "../constants/defines.sol";

import { ITokeniserSystem } from '../codegen/world/ITokeniserSystem.sol';

import {ActionType, RoomType, ObjectType, CommandError, DirectionType} from "../codegen/common.sol";

import { RoomStore, RoomStoreData, ActionStore, DirObjectStore } from "../codegen/index.sol";

contract DirectionSystem is System {

    address world;

    function initDFS(address tokeniser, address wrld) public returns (address) {
        //console.log("--->initDFS: %s", wrld);
        world = wrld;
        return address(this);
    }

    function getNextRoom(string[] memory tokens, uint32 currRm) public returns (uint8 e, uint32 nxtRm) {
        //console.log("----->DF_NXT_RM tok: ", tokens[0]);

        (string memory tok, uint8 tok_err) = _fishDirectionTok(tokens);

        if ( tok_err != 0 ) {
            return (tok_err, 0x10000);
        }

        /* Test DIRECTION */
        DirectionType DIR = IWorld(world).meat_TokeniserSystem_getDirectionType(tok);
 
        (bool mv, uint32 dObjId) = _directionCheck(currRm, DIR);
        if (mv) {
            //console.log("->DF--->DOBJ:", dObjId);

            uint32 nxtRm = DirObjectStore.getDestId(dObjId);
            //console.log("->DF --------->NXTRM:", nxtRm);
            return (0, nxtRm);
        }else { 
            //console.log("--->DF:0000"); 
            // check reason we didnt move this can currently only 
            // be cannot actually move that way because no exit
            //string memory errMsg;
            //errMsg = _insultMeat(GO_NO_EXT, tok);
            //Output.set(errMsg);
            return (ResCodes.GO_NO_EXIT, dObjId);
        }
    }

    function _canMove() private view returns (bool success) {
       // check LOCK/UNLOCK, OPEN/CLOSED 
        return true;
    }


    /* NB this is ONLY checking that an exit exists TODO add an openable check */
    function _directionCheck (uint32 rId, DirectionType d) private view returns (bool success, uint32 next) {
        //console.log("---->DC room:", rId, "---> DR:", uint8(d));
        uint32[] memory exitIds = RoomStore.getDirObjIds(rId);  

        //console.log("---->DC room:", rId, "---> EXITIDS.LEN:", uint8(exitIds.length));
        for (uint8 i = 0; i < exitIds.length; i++) {

            //console.log( "-->i:", i, "-->[]", uint32(exitIds[i]) );
            // just for debug output
            DirectionType dt = DirObjectStore.getDirType(exitIds[i]);
            //console.log( "-->i:", i, "-->", uint8(dt) );
            if ( DirObjectStore.getDirType(exitIds[i]) == d) { 

                if (_canMove() == true){
                    return (true, exitIds[i]); 
                }
            } 
        }  
        // bad idea but we use 0 as a roomId
        // need to fix, we should stick with Solidity idiom
        // which is 0 is always false/None/Null
        return (false, 0x10000);
    }

    function _fishDirectionTok(string[] memory tokens) private returns (string memory tok, uint8 err)  {
        
        if (IWorld(world).meat_TokeniserSystem_getDirectionType(tokens[0]) != DirectionType.None) {
            //console.log("--->DIR %s", tokens[0]);
            /* Direction form
            *
            * dir = n | e | s | w
            *
            */
            tok = tokens[0];
        } else if (IWorld(world).meat_TokeniserSystem_getActionType(tokens[0]) != ActionType.None ) {
            //console.log("--->GO %s", tok);
            /* GO form
            * 
            * go_cmd = go, [(pp da)], dir | obj 
            * pp = "to";
            * da = "the";
            * dir = n | e | s | w
            */
            if ( tokens.length >= 4 ) {
                //console.log("--->GO_LNG %s", tokens[3]);
                /* long form */
                /* go_cmd = go, ("to" "the"), dir|obj */
                tok = tokens[3]; // dir | obj
            } else if (tokens.length == 2) {
                //console.log("--->GO_SHRT %s", tokens[1]);
                /* short form */
                /* go_cmd = go, dir|obj */
                tok = tokens[1]; // dir | obj
                //TODO: handle for obj we probably dont even need it tbh
                // but anyway its here because I get carried away...
            }

            if (IWorld(world).meat_TokeniserSystem_getDirectionType(tok) != DirectionType.None ) {
                return (tok, 0); 
            } else {
                return (tok, ErrCodes.ER_DR_ND);
            }
        }
    }

}
