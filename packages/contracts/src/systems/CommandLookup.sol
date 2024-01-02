// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;


//import {System} from "@latticexyz/world/src/System.sol";
import {Output} from "../codegen/index.sol";
import {ObjectType, ActionType, DirectionType, GrammarType} from "../codegen/common.sol";

contract CommandLookups {

    // some maps for lookups
    mapping (string => ActionType) public cmdLookup;
    mapping (string => ObjectType) public objLookup;
    mapping (string => DirectionType) public dirLookup;
    mapping (string => GrammarType) public grammarLookup;

    function initCLS() public returns (uint32) {
        Output.set('initCES called...');
        setupCmds();
        setupObjects();
        setupDirs();
        setupGrammar();
        return 0;
    }

    // we need to somewhere somehow read in the possible verbs if we
    // want users to have their own VERBS
    // how do we dynamically populate this ??
    function setupCmds() private returns (uint32) {
        cmdLookup["GO"]         = ActionType.Go;
        cmdLookup["MOVE"]       = ActionType.Move;
        cmdLookup["LOOT"]       = ActionType.Loot;
        cmdLookup["DESCRIBE"]   = ActionType.Describe;
        cmdLookup["TAKE"]       = ActionType.Take;
        cmdLookup["KICK"]       = ActionType.Kick;
        cmdLookup["LOCK"]       = ActionType.Lock;
        cmdLookup["UNLOCK"]     = ActionType.Unlock;
        cmdLookup["OPEN"]       = ActionType.Open;
    }

    // this could autogen because we just take set of "str"
    // iterate and gen a line for each str.
    // fooLookup["FOO"] = FoosType.foo;
    function setupDirs () private returns (uint32) {
        dirLookup["NORTH"]  = DirectionType.North;
        dirLookup["SOUTH"]  = DirectionType.South;
        dirLookup["EAST"]   = DirectionType.East;
        dirLookup["WEST"]   = DirectionType.West;
        dirLookup["UP"]     = DirectionType.Up;
        dirLookup["DOWN"]   = DirectionType.Down;
    }


    function setupObjects () private returns (uint32) {
        objLookup["BALL"]  = ObjectType.Ball;
        objLookup["KEY"]  = ObjectType.Key;
        objLookup["KNIFE"]   = ObjectType.Knife;
        objLookup["BOTTLE"]   = ObjectType.Bottle;
    }

    function setupGrammar () private returns (uint32) {
       grammarLookup["The"] = GrammarType.DefiniteArticle;
       grammarLookup["To"]  = GrammarType.Preposition;
    }

}
