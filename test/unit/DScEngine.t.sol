// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import "forge-std/Test.sol";
import "../../script/DeployDSC.s.sol";
import "../../src/tokens/DScCoin.sol";
import "../../src/core/DScEngine.sol";
import "../../script/HelperConfig.s.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract DScEngineTest is Test {
    DeployDSc deployDSc;
    DScEngine dscEngine;
    DScCoin dscCoin;
    HelperConfig hconfig;

    address wethPriceFeed;
    address linkPriceFeed;
    address weth;
    address link;

    uint256 deployerKey;

    function setUp() public {
        deployDSc = new DeployDSc();
        (dscEngine, dscCoin, hconfig) = deployDSc.run();
        (wethPriceFeed, linkPriceFeed, weth, link, deployerKey) = hconfig.activeNetworkConfig();
    }

    function testGetUSDValue() public {
        uint256 expectedUsd = 30000e18;
        uint256 ethAmount = 15e18;
        uint256 actualUsd = dscEngine.getUsdValue(weth, ethAmount);
        assertEq(actualUsd, expectedUsd);
    }

    function testcreatePosition() public {
        // User made and funded
        address UserA = makeAddr("UserA");
        vm.startPrank(UserA);
        deal(weth, address(UserA), 100e18);
        IERC20(weth).approve(address(dscEngine), 100e18);

        uint256 balanceTokensofUserA = IERC20(weth).balanceOf(UserA);
        console.log("UserA weth balance:", balanceTokensofUserA);

        (uint256 ValueofgivenUsdagainstWeth) = dscEngine.getUsdValue(weth, 100e18);
        console.log("The total usd value of UserA given weth is:", ValueofgivenUsdagainstWeth);
        console.log("address of User A:", UserA);
        console.log("address of Msg Sender:", msg.sender);
        dscEngine.depositCollateralAndMintDSc(address(weth), 100e18, ValueofgivenUsdagainstWeth / 2);
        console.log("The dsc Minted amount is:", ValueofgivenUsdagainstWeth / 2);

        // Something else:
        (uint256 a, uint256 b) = dscEngine.getAccountInformation(UserA);
        console.log("total DSc Minted:", a);
        console.log("total Collateral value:", b);

        // health factor check
        (uint256 c) = dscEngine.getHealthFactor(UserA);
        console.log("health factor of User A:", c);

        vm.stopPrank();
    }

      

}
// ProfessorAudits