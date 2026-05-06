// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import "forge-std/Script.sol";
import "../src/tokens/DScCoin.sol";
import "../src/core/DScEngine.sol";
import "./HelperConfig.s.sol";

contract DeployDSc is Script {
    address[] public tokenAddresses;
    address[] public priceFeedAddresses;

    function run() external returns (DScEngine, DScCoin, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        (address wethPriceFeed, address linkPriceFeed, address weth, address link, uint256 deployerKey) =
            helperConfig.activeNetworkConfig();
        tokenAddresses = [weth, link];
        priceFeedAddresses = [wethPriceFeed, linkPriceFeed];
        vm.startBroadcast();
        DScCoin dscCoin = new DScCoin();
        DScEngine dscEngine = new DScEngine(address(dscCoin), tokenAddresses, priceFeedAddresses);
        dscCoin.transferOwnership(address(dscEngine));

        vm.stopBroadcast();
        return (dscEngine, dscCoin, helperConfig);
    }
}
