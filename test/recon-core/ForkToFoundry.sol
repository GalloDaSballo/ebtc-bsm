// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {FoundryAsserts} from "@chimera/FoundryAsserts.sol";
import "forge-std/console2.sol";

import {TargetFunctions} from "./TargetFunctions.sol";

// forge test --match-contract ForkToFoundry -vv --rpc-url URL
contract ForkToFoundry is Test, TargetFunctions, FoundryAsserts {
    function setUp() public {
        setup();
        _setupFork();
        _govFuzzing();
    }

    // forge test --match-test test_crytic -vvv
    function test_crytic() public {
        bsmTester_updateEscrow();
    }

    // forge test --match-test test_property_total_minted_eq_total_asset_deposits_0 -vvv 
    function test_property_total_minted_eq_total_asset_deposits_0() public {

        bsmTester_sellAsset(2);

        bsmTester_buyAsset(10000009564);

        property_total_minted_eq_total_asset_deposits();

    }
}
