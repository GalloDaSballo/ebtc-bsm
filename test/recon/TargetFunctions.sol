// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

// Chimera deps
import {vm} from "@chimera/Hevm.sol";

// Targets
// NOTE: Always import and apply them in alphabetical order, so much easier to debug!
import {AdminTargets} from "./targets/AdminTargets.sol";
import {InlinedTests} from "./targets/InlinedTests.sol";
import {ManagersTargets} from "./targets/ManagersTargets.sol";

import {OpType} from "./BeforeAfter.sol";

abstract contract TargetFunctions is AdminTargets, InlinedTests, ManagersTargets {
    function bsmTester_buyAssetWithEbtc(uint256 _ebtcAmountIn) public updateGhostsWithType(OpType.BUY_ASSET_WITH_EBTC) asActor {
        bsmTester.buyAssetWithEbtc(_ebtcAmountIn);
    }

    function bsmTester_buyEbtcWithAsset(uint256 _assetAmountIn) public updateGhosts asActor {
        bsmTester.buyEbtcWithAsset(_assetAmountIn);
    }

    function inlined_migration_causes_no_loss() public stateless {
        address[] memory actors = _getActors();

        // if a migration has happened, all depositAmount should be able to be withdrawn
        if(hasMigrated) {
            // setup adds in unbacked eBTC and underlying asset
            // so we just need to check that if we migrate, the actors can withdraw up to the depositAmount
            for (uint256 i = 0; i < actors.length; i++) {
                address actor = actors[i];
                uint256 depositAmount = assetVault.depositAmount();
                uint256 actorBalance = mockEbtcToken.balanceOf(actor);
                
                if(depositAmount >= actorBalance) {
                    vm.prank(actor);
                    bsmTester_buyAssetWithEbtc(actorBalance);
                } else {
                    vm.prank(actor);
                    bsmTester_buyAssetWithEbtc(depositAmount);
                }
            }

            // the depositAmount should be 0 after all the actors have withdrawn
            eq(assetVault.depositAmount(), 0, "depositAmount should be 0 after all the actors have exchanged eBTC for underlying asset");
        }
    }

    // Donations directly to the underlying vault
    function externalVault_mint(uint256 _amount) public updateGhosts asActor {
        externalVault.deposit(_amount, _getActor());
    }

    function externalVault_withdraw(uint256 _amount) public updateGhosts asActor{
        externalVault.withdraw(_amount, _getActor(), _getActor());
    }
}
