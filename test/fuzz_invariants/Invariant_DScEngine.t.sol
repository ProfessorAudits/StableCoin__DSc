// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import "forge-std/Test.sol";
import "../../script/DeployDSC.s.sol";
import "forge-std/StdInvariant.sol";
import "../../src/tokens/DScCoin.sol";
import "../../src/core/DScEngine.sol";
import "../../script/HelperConfig.s.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../mocks/ERC20mock.sol";
// import "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import "./HandlerInvariant_DScEngine.t.sol";

contract ForInvariant_DScEngine is StdInvariant, Test {
    DeployDSc deployDSc;
    DScEngine dsc_Engine;
    DScCoin dscCoin;
    HelperConfig hconfig;
    HandlerInvariant_DScEngine handlerForInvariant;

    address wethPriceFeed;
    address linkPriceFeed;
    address weth;
    address link;

    uint256 deployerKey;

    function setUp() external {
        deployDSc = new DeployDSc();
        (dsc_Engine, dscCoin, hconfig) = deployDSc.run();
        (wethPriceFeed, linkPriceFeed, weth, link, deployerKey) = hconfig.activeNetworkConfig();
        handlerForInvariant = new HandlerInvariant_DScEngine(dscCoin, dsc_Engine);
        targetContract(address(handlerForInvariant));
    }

    //   function testValuesAmount() public {
    //         uint256 balanceOfWethinDSC_asCollateral = ERC20Mock(weth).balanceOf(address(dscEngine));
    //         uint256 balanceOflinkinDSC_asCollateral = ERC20Mock(link).balanceOf(address(dscEngine));
    //         uint256 totalSupplyofDScCoin = dscCoin.totalSupply();

    //         uint256 usdValueofAllWethinDSc = dscEngine.getUsdValue(address(weth), balanceOfWethinDSC_asCollateral);
    //         uint256 usdValueofAlllinkinDSc = dscEngine.getUsdValue(address(link), balanceOflinkinDSC_asCollateral);

    //         console.log("INVARIANTFILE__DScCoin TotalSupply:" , totalSupplyofDScCoin);
    //         console.log("INVARIANTFILE__Weth Amount in contract:", balanceOfWethinDSC_asCollateral);
    //         console.log("INVARIANTFILE__link Amount in contract:", balanceOflinkinDSC_asCollateral);
    //         console.log("INVARIANTFILE__weth USDAmount in contract:", usdValueofAllWethinDSc);
    //         console.log("INVARIANTFILE__link USDAmount in contract:", usdValueofAlllinkinDSc);

    //     }

    function invariant_CollateralMustbeGreaterThan_TotalSupplyOfDSC() public {
        uint256 balanceOfWethinDSC_asCollateral = ERC20Mock(weth).balanceOf(address(dsc_Engine));
        uint256 balanceOflinkinDSC_asCollateral = ERC20Mock(link).balanceOf(address(dsc_Engine));
        uint256 totalSupplyofDScCoin = dscCoin.totalSupply();

        uint256 usdValueofAllWethinDSc = dsc_Engine.getUsdValue(address(weth), balanceOfWethinDSC_asCollateral);
        uint256 usdValueofAlllinkinDSc = dsc_Engine.getUsdValue(address(link), balanceOflinkinDSC_asCollateral);

        assert((usdValueofAllWethinDSc + usdValueofAlllinkinDSc) >= totalSupplyofDScCoin);
    }
}
