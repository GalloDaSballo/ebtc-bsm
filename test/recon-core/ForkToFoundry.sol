// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {FoundryAsserts} from "@chimera/FoundryAsserts.sol";
import "forge-std/console2.sol";

import {TargetFunctions} from "./TargetFunctions.sol";

// forge test --match-contract ForkToFoundry -vv --rpc-url https://eth-mainnet.g.alchemy.com/v2/mUhSl9trIQUL4usawoforWzPFxtruAm7
contract ForkToFoundry is Test, TargetFunctions, FoundryAsserts {
    function setUp() public {
        setup();
        _setupFork();
        _govFuzzing();

        vm.warp(1745430839);
        vm.roll(22333324);
    }

    // forge test --match-test test_crytic -vvv
    function test_crytic() public {
        bsmTester_updateEscrow();
    }

    // forge test --match-test test_property_total_minted_eq_total_asset_deposits_0 -vvv  --rpc-url https://eth-mainnet.g.alchemy.com/v2/mUhSl9trIQUL4usawoforWzPFxtruAm7
    function test_property_total_minted_eq_total_asset_deposits_0() public {

        bsmTester_sellAsset(2);

        bsmTester_buyAsset(10000009564);

        property_total_minted_eq_total_asset_deposits();

    }

    // forge test --match-test test_bsmTester_sellAsset_0 -vvv --rpc-url https://eth-mainnet.g.alchemy.com/v2/mUhSl9trIQUL4usawoforWzPFxtruAm7
function test_bsmTester_sellAsset_0() public {

    bsmTester_sellAsset(1e6);

 }

    function test_equivalence_bsm_previewBuyAsset() public {
        uint256 balance = mockAssetToken.balanceOf(_getActor());
        console2.log("balance of actor", balance);
        equivalence_bsm_previewBuyAsset(balance);
    }
}
