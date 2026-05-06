// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import "forge-std/Test.sol";
import "../../script/DeployDSC.s.sol";
import "forge-std/StdInvariant.sol";
import "../../src/tokens/DScCoin.sol";
import "../../src/core/DScEngine.sol";
import "../../script/HelperConfig.s.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract HandlerInvariant_DScEngine is StdInvariant, Test {
    DScCoin _DscCoin;
    DScEngine dscEngine;
    address[] public AllowedTokensAddr;

    constructor(DScCoin _dscCoin, DScEngine _dscEngine) {
        _DscCoin = _dscCoin;
        dscEngine = _dscEngine;
        AllowedTokensAddr = dscEngine.getAllowedCollateralTokensAddress();
    }

    function depositCollateralDScEngine__Handler(
        uint256 _tokenCollateralAddressSeed,
        uint256 _amountForCollateralDepositMoney
    ) public {
        _amountForCollateralDepositMoney = bound(_amountForCollateralDepositMoney, 1, type(uint96).max);
        address UserB = makeAddr("UserB");
        vm.startPrank(UserB);

        if (_tokenCollateralAddressSeed % 2 == 0) {
            AllowedTokensAddr[0];
            deal(AllowedTokensAddr[0], UserB, _amountForCollateralDepositMoney);
            // ERC20Mock(AllowedTokensAddr[0]).mint(UserB, _amountForCollateralDepositMoney);
            ERC20Mock(AllowedTokensAddr[0]).approve(address(dscEngine), _amountForCollateralDepositMoney);
            dscEngine.depositCollateral(AllowedTokensAddr[0], _amountForCollateralDepositMoney);
                    
            uint256 balanceOfwethinDScEngine = ERC20Mock(AllowedTokensAddr[0]).balanceOf(address(dscEngine));
            uint256 UsdValueOfwethasCollateral = dscEngine.getUsdValue(AllowedTokensAddr[0], balanceOfwethinDScEngine);
            console.log("DepositFunctionInHandlercontract; Usd Value of weth :", UsdValueOfwethasCollateral );
            uint256 DScCoinTotalSupply = _DscCoin.totalSupply();
            console.log("DepositFunctionInHandlercontract; Total Supply of DSc Coin:", DScCoinTotalSupply);
       
        } else {
            AllowedTokensAddr[1];
            // ERC20Mock(AllowedTokensAddr[0]).mint(UserB, _amountForCollateralDepositMoney);

            deal(AllowedTokensAddr[1], UserB, _amountForCollateralDepositMoney);
            ERC20Mock(AllowedTokensAddr[1]).approve(address(dscEngine), _amountForCollateralDepositMoney);
            dscEngine.depositCollateral(AllowedTokensAddr[1], _amountForCollateralDepositMoney);                    
            uint256 balanceOfwbtcinDScEngine = ERC20Mock(AllowedTokensAddr[1]).balanceOf(address(dscEngine));
            uint256 UsdValueOfwbtcasCollateral = dscEngine.getUsdValue(AllowedTokensAddr[1], balanceOfwbtcinDScEngine);

        console.log("DepositFunctionInHandlercontract; Usd Value of link:",  UsdValueOfwbtcasCollateral);
        uint256 aDScCoinTotalSupply = _DscCoin.totalSupply();
        console.log("DepositFunctionInHandlercontract; Total Supply of DSc Coin:", aDScCoinTotalSupply);
        }



        vm.stopPrank();
    }

    function mintDSc__Handler(uint256 _tokenCollateralAddressSeed, uint256 _amountForCollateralDepositMoney) public {
        vm.startPrank(msg.sender);
        _amountForCollateralDepositMoney = bound(_amountForCollateralDepositMoney, 1, type(uint96).max);

        if (_tokenCollateralAddressSeed % 2 == 0) {
            AllowedTokensAddr[0];
            deal(AllowedTokensAddr[0], msg.sender, _amountForCollateralDepositMoney);

            ERC20Mock(AllowedTokensAddr[0]).approve(address(dscEngine), _amountForCollateralDepositMoney);
            dscEngine.depositCollateral(AllowedTokensAddr[0], _amountForCollateralDepositMoney);

            // get usd value of Collateral:
            (uint256 UsdValueOfCollateral) =
                dscEngine.getUsdValue(AllowedTokensAddr[0], _amountForCollateralDepositMoney);

            // mint half of collateral Value
            uint256 mintDScAmount = UsdValueOfCollateral / 2;
            mintDScAmount = bound(mintDScAmount, 1, mintDScAmount);
            dscEngine.mintDSc(mintDScAmount);
        } else {
            AllowedTokensAddr[1];
            deal(AllowedTokensAddr[1], msg.sender, _amountForCollateralDepositMoney);

            ERC20Mock(AllowedTokensAddr[1]).approve(address(dscEngine), _amountForCollateralDepositMoney);
            dscEngine.depositCollateral(AllowedTokensAddr[1], _amountForCollateralDepositMoney);

            // get usd value of Collateral:
            (uint256 UsdValueOfCollateral) =
                dscEngine.getUsdValue(AllowedTokensAddr[1], _amountForCollateralDepositMoney);

            // mint half of collateral Value
            uint256 mintDScAmount = UsdValueOfCollateral / 2;
            mintDScAmount = bound(mintDScAmount, 1, mintDScAmount);
            dscEngine.mintDSc(mintDScAmount);
        }

        uint256 balanceOfwethinDScEngine = ERC20Mock(AllowedTokensAddr[0]).balanceOf(address(dscEngine));
        uint256 balanceOfwbtcinDScEngine = ERC20Mock(AllowedTokensAddr[1]).balanceOf(address(dscEngine));

        (uint256 UsdValueOfwethasCollateral) = dscEngine.getUsdValue(AllowedTokensAddr[0], balanceOfwethinDScEngine);
        (uint256 UsdValueOfwbtcasCollateral) = dscEngine.getUsdValue(AllowedTokensAddr[1], balanceOfwbtcinDScEngine);

        console.log("MintFunctionInhandler;Usd Value of weth and link:", (UsdValueOfwethasCollateral + UsdValueOfwbtcasCollateral));

        uint256 DScCoinTotalSupply = _DscCoin.totalSupply();
        console.log("MintFunctionInhandler; Total Supply of DSc Coin:", DScCoinTotalSupply);

        vm.stopPrank();
    }
}

// // setting user:
// // address UserC = makeAddr("UserB");

// // do deposit of Collateral:

// if (_tokenCollateralAddressSeed % 2 == 0) {
//    address weth =  AllowedTokensAddr[0];
//    depositCollateralDScEngine(_tokenCollateralAddressSeed, _amountForCollateralDepositMoney);

// (uint UsdValueOfColl)= dscEngine.getUsdValue(weth,  _amountForCollateralDepositMoney);
// // Set max mint
// uint newAmountForCollateralMint = UsdValueOfColl / 3 ;
// amountDScToMint = bound(amountDScToMint,1 ,newAmountForCollateralMint);
// dscEngine.mintDSc(newAmountForCollateralMint);
// }
// else{
//     address btc= AllowedTokensAddr[1];
//     depositCollateralDScEngine(_tokenCollateralAddressSeed, _amountForCollateralDepositMoney);
//     (uint UsdValueOfColl)= dscEngine.getUsdValue(btc, _amountForCollateralDepositMoney);
// // Set max mint
//     uint newAmountForCollateralMint = UsdValueOfColl / 3 ;
//     amountDScToMint = bound(amountDScToMint, 1 ,newAmountForCollateralMint);
//     dscEngine.mintDSc(newAmountForCollateralMint);

// }
