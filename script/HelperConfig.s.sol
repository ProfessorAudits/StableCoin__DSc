// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import "forge-std/Script.sol";
import "../src/tokens/DScCoin.sol";
import "../src/core/DScEngine.sol";
import "../test/mocks/MockV3Aggregrator.sol";
import "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

// ProfessorAudits
contract HelperConfig is Script {
    struct NetworkCofig {
        address wethPriceFeed;
        address linkPriceFeed;
        address weth;
        address link;
        uint256 deployerKey;
    }

    NetworkCofig public activeNetworkConfig;

    constructor() {
        if (block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaEthConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilConfig();
        }
    }

    function getSepoliaEthConfig() public returns (NetworkCofig memory) {
        return NetworkCofig({
            // WHY we taking the eth/usd price feed address
            // instead of weth/usd?? bcz chainlink doesn't havr weth/usd feed ... IS IT RIGHT TO USE ETH/USD PriceFeed?
            wethPriceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306,
            linkPriceFeed: 0xc59E3633BAAC79493d908e63626716e204A45EdF,
            weth: 0x7b79995e5f793A07Bc00c21412e50Ecae098E7f9,
            link: 0x779877A7B0D9E8603169DdbD7836e478b4624789,
            deployerKey: vm.envUint("PRIVATE_KEY")
        });
    }

    function getOrCreateAnvilConfig() public returns (NetworkCofig memory) {
        // when tests will call run() it might redeploy it change addresses, So to avoid that if
        if (activeNetworkConfig.weth != address(0)) {
            return activeNetworkConfig;
        }
        vm.startBroadcast();
        MockV3Aggregator ethUsdPriceFeed = new MockV3Aggregator(8, 2000e8);
        MockV3Aggregator linkUsdPriceFeed = new MockV3Aggregator(8, 10e8);
        ERC20Mock wethMock = new ERC20Mock("WETH", "WETH", msg.sender, 2000e8);
        ERC20Mock linkMock = new ERC20Mock("LINK", "LINK", msg.sender, 10e8);

        vm.stopBroadcast();
        return NetworkCofig({
            // WHY we taking the eth/usd price feed address
            // instead of weth/usd?? bcz chainlink doesn't havr weth/usd feed ... IS IT RIGHT TO USE ETH/USD PriceFeed?
            wethPriceFeed: address(ethUsdPriceFeed),
            linkPriceFeed: address(linkUsdPriceFeed),
            weth: address(wethMock),
            link: address(linkMock),
            // from anvil private key
            deployerKey: 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
        });
    }
}
