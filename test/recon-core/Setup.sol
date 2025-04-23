// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

// Chimera deps
import {BaseSetup} from "@chimera/BaseSetup.sol";
import {vm} from "@chimera/Hevm.sol";

// Managers
import {ActorManager} from "./managers/ActorManager.sol";
import {AssetManager} from "./managers/AssetManager.sol";

import {BSMBase} from "../BSMTestBase.sol";

import {Governor} from "../../src/Dependencies/Governor.sol";
import {EbtcBSM} from "../../src/EbtcBSM.sol";
import {BaseEscrow} from "../../src/BaseEscrow.sol";
import {RateLimitingConstraint} from "../../src/RateLimitingConstraint.sol";
import "../mocks/MockAssetToken.sol";

import "forge-std/console2.sol";

abstract contract Setup is BaseSetup, BSMBase, ActorManager, AssetManager {
    address second_actor = address(0x411c3);
    bool hasMigrated; // TODO: Check this again

    // CONFIG
    bool constant ALLOWS_REKT = bool(true);
    uint8 constant DECIMALS = uint8(8);

    function setup() internal virtual override {
        // TODO: create a separate tester for tokens with different decimals
        BSMBase.baseSetup(DECIMALS);

        // New Actor, beside address(this)
        _addActor(second_actor);

        // Add deployed assets to manager
        _addAsset(address(mockEbtcToken));
        _addAsset(address(mockAssetToken));
        _enableAsset(address(mockEbtcToken));

        // TODO: Standardize Mint and allowances to all actors
        mockAssetToken.mint(second_actor, type(uint88).max);
        mockEbtcToken.mint(second_actor, type(uint88).max);

        vm.prank(second_actor);
        mockAssetToken.approve(address(bsmTester), type(uint256).max);
        vm.prank(second_actor);
        mockEbtcToken.approve(address(bsmTester), type(uint256).max);

        vm.prank(defaultGovernance);
        authority.setUserRole(address(this), 16, true);
        vm.prank(defaultGovernance);
        authority.setUserRole(address(second_actor), 16, true);

        mockAssetToken.mint(address(this), type(uint88).max);
        mockEbtcToken.mint(address(this), type(uint88).max);
        mockAssetToken.approve(address(bsmTester), type(uint256).max);
        mockEbtcToken.approve(address(bsmTester), type(uint256).max);
    }

    // NOTE: LIMITATION You can use these modifier only for one call, so use them for BASIC TARGETS
    modifier asAdmin() {
        vm.prank(address(defaultGovernance));
        _;
    }

    modifier asTechops() {
        vm.prank(address(techOpsMultisig));
        _;
    }

    modifier asActor() {
        vm.prank(_getActor());
        _;
    }

    modifier stateless() {
        _;
        revert("stateless");
    }


    function _setupFork() internal {
        vm.warp(1745430839);
        vm.roll(22333324);

        defaultGovernance = address(0xaDDeE229Bd103bb5B10C3CdB595A01c425dd3264);
        authority = Governor(address(0x2A095d44831C26cFB6aCb806A6531AE3CA32DBc1));

        bsmTester = EbtcBSM(0x828787A14fd4470Ef925Eefa8a56C88D85D4a06A);
        escrow = BaseEscrow(address(bsmTester.escrow()));

        mockAssetToken = MockAssetToken(address(bsmTester.ASSET_TOKEN()));
        mockEbtcToken = ERC20Mock(address(bsmTester.EBTC_TOKEN()));

        rateLimitingConstraint = RateLimitingConstraint(address(0x6c289F91A8B7f622D8d5DcF252E8F5857CAc3E8B));

        // TODO: Whales
        address cbBTC_whale = 0x5c647cE0Ae10658ec44FA4E11A51c96e94efd1Dd;
        uint256 toTransfer = mockAssetToken.balanceOf(cbBTC_whale) / 2;

        vm.prank(cbBTC_whale);
        mockAssetToken.transfer(address(this), toTransfer);
        vm.prank(cbBTC_whale);
        mockAssetToken.transfer(address(second_actor), toTransfer);
    }

    function _govFuzzing() internal {
        // We need to approve all the stuff from the timelock

        // Also the mint
        setUserRole(address(bsmTester), 1, true);
        setUserRole(address(bsmTester), 2, true);

        setRoleName(15, "BSM: Governance");
        setRoleName(16, "BSM: AuthorizedUser");
        setRoleCapability(
            15,
            address(bsmTester),
            bsmTester.setFeeToBuy.selector,
            true
        );
        setRoleCapability(
            15,
            address(bsmTester),
            bsmTester.setFeeToSell.selector,
            true
        );
        setRoleCapability(
            15,
            address(bsmTester),
            bsmTester.updateEscrow.selector,
            true
        );
        setRoleCapability(
            15,
            address(bsmTester),
            bsmTester.pause.selector,
            true
        );
        setRoleCapability(
            15,
            address(bsmTester),
            bsmTester.unpause.selector,
            true
        );
        setRoleCapability(
            15,
            address(bsmTester),
            bsmTester.setOraclePriceConstraint.selector,
            true
        );
        setRoleCapability(
            15,
            address(bsmTester),
            bsmTester.setRateLimitingConstraint.selector,
            true
        );
        setRoleCapability(
            15,
            address(bsmTester),
            bsmTester.setBuyAssetConstraint.selector,
            true
        );
        setRoleCapability(
            15,
            address(escrow),
            escrow.claimProfit.selector,
            true
        );
        setRoleCapability(
            15,
            address(escrow),
            escrow.claimTokens.selector,
            true
        );

        setRoleCapability(
            15,
            address(oraclePriceConstraint),
            oraclePriceConstraint.setMinPrice.selector,
            true
        );
        setRoleCapability(
            15,
            address(oraclePriceConstraint),
            oraclePriceConstraint.setOracleFreshness.selector,
            true
        );
        setRoleCapability(
            15,
            address(rateLimitingConstraint),
            rateLimitingConstraint.setMintingConfig.selector,
            true
        );
        // Give ebtc tech ops role 15
        setUserRole(techOpsMultisig, 15, true);
        setRoleCapability(
            16,
            address(bsmTester),
            bsmTester.sellAssetNoFee.selector,
            true
        );
        setRoleCapability(
            16,
            address(bsmTester),
            bsmTester.buyAssetNoFee.selector,
            true
        );
        // Give authorizedUser role 16
        setUserRole(testAuthorizedUser, 16, true);

        vm.prank(techOpsMultisig);
        rateLimitingConstraint.setMintingConfig(address(bsmTester), RateLimitingConstraint.MintingConfig(1000, 0, false));


        // Grant allowance
        vm.prank(address(this));
        mockAssetToken.approve(address(bsmTester), type(uint256).max);
        vm.prank(address(this));
        mockEbtcToken.approve(address(bsmTester), type(uint256).max);
        vm.prank(address(second_actor));
        mockAssetToken.approve(address(bsmTester), type(uint256).max);
        vm.prank(address(second_actor));
        mockEbtcToken.approve(address(bsmTester), type(uint256).max);
    }
}
