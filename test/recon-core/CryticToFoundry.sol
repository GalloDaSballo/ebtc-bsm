// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {FoundryAsserts} from "@chimera/FoundryAsserts.sol";
import "forge-std/console2.sol";

import {TargetFunctions} from "./TargetFunctions.sol";

// forge test --match-contract CryticToFoundry -vv
contract CryticToFoundry is Test, TargetFunctions, FoundryAsserts {
    function setUp() public {
        setup();

        vm.label(address(mockAssetToken), "mockAssetToken");
        vm.label(address(mockEbtcToken), "mockEbtcToken");
        vm.label(address(second_actor), "second_actor");
        vm.label(address(this), "actor");
        vm.label(address(bsmTester), "bsmTester");
        vm.label(address(techOpsMultisig), "techOpsMultisig");
        vm.label(address(escrow), "escrow");
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


    function test_can_I_scam() public {
        bsmTester_setFeeToSell(123);
        bsmTester_setFeeToBuy(123);

        bsmTester_sellAsset(1e18);

        console2.log("ebtc b4", mockEbtcToken.balanceOf(_getActor()));
        console2.log("asset b4", mockAssetToken.balanceOf(_getActor()));

        bsmTester_buyAsset(1e10);

        console2.log("ebtc after", mockEbtcToken.balanceOf(_getActor()));
        console2.log("asset after", mockAssetToken.balanceOf(_getActor()));
    }
}
