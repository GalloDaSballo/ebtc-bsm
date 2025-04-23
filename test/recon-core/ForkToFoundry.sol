// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {FoundryAsserts} from "@chimera/FoundryAsserts.sol";
import "forge-std/console2.sol";

import {TargetFunctions} from "./TargetFunctions.sol";

// forge test --match-contract ForkToFoundry -vv --rpc-url RPC
contract ForkToFoundry is Test, TargetFunctions, FoundryAsserts {
    function setUp() public {
        // add your rpc url to the .env file to run tests using a forked chain state
        string memory FORK_RPC_URL = vm.envString("MAINNET_RPC_URL");
        uint256 FORK_BLOCK_NUMBER = vm.envUint("MAINNET_BLOCK_NUMBER");

        // create a fork from the given rpc url at the block number set in Setup contract
        vm.createSelectFork(FORK_RPC_URL, FORK_BLOCK_NUMBER);

        setup();
        

        _setupFork();
        _govFuzzing();


    }

    // forge test --match-test test_crytic -vvv
    function test_crytic() public {
        bsmTester_updateEscrow();
    }

    // forge test --match-test test_property_total_minted_eq_total_asset_deposits_fork -vvv  --rpc-url RPC
    function test_property_total_minted_eq_total_asset_deposits_fork() public {

        bsmTester_sellAsset(2);

        bsmTester_buyAsset(10000009564);

        property_total_minted_eq_total_asset_deposits();

    }

    // forge test --match-test test_bsmTester_sellAsset_0 -vvv --rpc-url RPC
function test_bsmTester_sellAsset_0() public {

    bsmTester_sellAsset(1e6);

 }

    function test_equivalence_bsm_previewBuyAsset() public {
        uint256 balance = mockAssetToken.balanceOf(_getActor());
        console2.log("balance of actor", balance);
        equivalence_bsm_previewBuyAsset(balance);
    }
}
