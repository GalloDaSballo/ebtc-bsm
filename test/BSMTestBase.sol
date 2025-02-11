// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import "@openzeppelin/contracts/mocks/token/ERC4626Mock.sol";
import {MockAssetOracle} from "./mocks/MockAssetOracle.sol";
import {MockActivePool} from "./mocks/MockActivePool.sol";
import "../src/Dependencies/Governor.sol";
import "../src/EbtcBSM.sol";
import "../src/OraclePriceConstraint.sol";
import "../src/RateLimitingConstraint.sol";
import "../src/ERC4626AssetVault.sol";

contract BSMTestBase is Test {
    ERC20Mock internal mockAssetToken;
    ERC20Mock internal mockEbtcToken;
    ERC4626Mock internal externalVault;
    ERC4626AssetVault internal assetVault;
    MockAssetOracle internal mockAssetOracle;
    MockActivePool internal mockActivePool;
    OraclePriceConstraint internal oraclePriceConstraint;
    RateLimitingConstraint internal rateLimitingConstraint;
    EbtcBSM internal bsmTester;
    address internal testMinter;
    address internal testBuyer;
    Governor internal authority;
    address internal defaultGovernance;
    address internal defaultFeeRecipient;
    address internal techOpsMultisig;
    address internal testAuthorizedUser;

    modifier prankDefaultGovernance() {
        vm.prank(defaultGovernance);
        _;
    }

    function setUp() public virtual {
        defaultGovernance = vm.addr(0x123456);
        defaultFeeRecipient = vm.addr(0x234567);
        authority = new Governor(defaultGovernance);
        mockAssetToken = new ERC20Mock();
        mockEbtcToken = new ERC20Mock();
        mockActivePool = new MockActivePool(mockEbtcToken);
        externalVault = new ERC4626Mock(address(mockAssetToken));
        mockAssetOracle = new MockAssetOracle(18);
        oraclePriceConstraint = new OraclePriceConstraint(
            address(mockAssetOracle),
            address(authority)
        );
        rateLimitingConstraint = new RateLimitingConstraint(
            address(mockActivePool),
            address(authority)
        );
        testMinter = vm.addr(0x11111);
        testBuyer = vm.addr(0x22222);
        testAuthorizedUser = vm.addr(0x33333);
        techOpsMultisig = 0x690C74AF48BE029e763E61b4aDeB10E06119D3ba;

        bsmTester = new EbtcBSM(
            address(mockAssetToken),
            address(oraclePriceConstraint),
            address(rateLimitingConstraint),
            address(mockEbtcToken),
            address(authority)
        );

        assetVault = new ERC4626AssetVault(
            address(externalVault),
            address(mockAssetToken),
            address(bsmTester),
            address(authority),
            address(defaultFeeRecipient)
        );
        
        bsmTester.initialize(address(assetVault));

        // create initial ebtc supply
        mockEbtcToken.mint(defaultGovernance, 50e18);
        mockAssetOracle.setPrice(1e18);
        mockAssetOracle.setUpdateTime(block.timestamp);

        vm.prank(testMinter);
        mockAssetToken.approve(address(bsmTester), type(uint256).max);
        mockAssetToken.mint(testMinter, 10e18);

        vm.prank(testAuthorizedUser);
        mockAssetToken.approve(address(bsmTester), type(uint256).max);
        vm.prank(testAuthorizedUser);
        mockEbtcToken.approve(address(bsmTester), type(uint256).max);
        
        mockAssetToken.mint(testAuthorizedUser, 10e18);
        mockEbtcToken.mint(testAuthorizedUser, 10e18);

        vm.prank(testBuyer);
        mockEbtcToken.mint(testBuyer, 10e18);

        // give eBTC minter and burner roles to BSM tester
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
            bsmTester.updateAssetVault.selector,
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
        authority.setRoleCapability(
            15,
            address(bsmTester),
            bsmTester.setRateLimitingConstraint.selector,
            true
        );
        setRoleCapability(
            15,
            address(assetVault),
            assetVault.claimProfit.selector,
            true
        );
        setRoleCapability(
            15,
            address(assetVault),
            assetVault.depositToExternalVault.selector,
            true
        );
        setRoleCapability(
            15,
            address(assetVault),
            assetVault.redeemFromExternalVault.selector,
            true
        );
        setRoleCapability(
            15,
            address(oraclePriceConstraint),
            oraclePriceConstraint.setMinPrice.selector,
            true
        );
        authority.setRoleCapability(
            15,
            address(rateLimitingConstraint),
            rateLimitingConstraint.setMintingCap.selector,
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
        bsmTester.updateAssetVault(address(assetVault));
        // Set minting cap to 10%
        vm.prank(techOpsMultisig);
        rateLimitingConstraint.setMintingCap(address(bsmTester), RateLimitingConstraint.MintingCap(1000, 0, false));
    }

    function setUserRole(address _user, uint8 _role, bool _enabled) internal prankDefaultGovernance {
        authority.setUserRole(_user, _role, _enabled);
    }

    function setRoleCapability(uint8 _role,
            address _target,
            bytes4 _functionSig,
            bool _enabled) internal prankDefaultGovernance {
        authority.setRoleCapability(
            _role,
            _target,
            _functionSig,
            _enabled
        );
    }

    function setRoleName(uint8 _role, string memory _roleName) internal prankDefaultGovernance {
        authority.setRoleName(_role, _roleName);
    }

    function testBsmCannotBeReinitialize() public {
        vm.expectRevert(abi.encodeWithSelector(Initializable.InvalidInitialization.selector));
        bsmTester.initialize(address(assetVault));
    }
}
