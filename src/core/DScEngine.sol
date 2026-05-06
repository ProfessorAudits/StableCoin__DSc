// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import "../tokens/DScCoin.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

// LINk USD price feed; 0xc59E3633BAAC79493d908e63626716e204A45EdF
// link address sepolia 0x779877A7B0D9E8603169DdbD7836e478b4624789;

contract DScEngine is ReentrancyGuard {
    error DSCEngine__BrokenHealthL94();
    error DSCEngine__TokenNotAllowedL37();
    error DSCEngine__AmountZeroNotAllowedL44();
    error DSCEngine__MintCallfailedL54();
    error DSCEngine__BrokenHealthL122();
    error DSCEngine__BrokenHealthL132();
    error DSCEngine__TransferFromcalldidfailedL165();
    error DSCEngine__TransfercalldidfailedL193();
    error DSCEngine__TransferFromcalldidfailedL201();

    DScCoin public immutable i_dscCoin;

    event CollateralDeposited(
        address indexed user, address indexed collateraltokenAddr, uint256 indexed amountofTokensDeposited
    );

    event DScCoinsMinted(address indexed MinterAddress, uint256 indexed amountMinted);

    event CollateralRedeemed(
        address indexed CollateralRedeemedByWhom,
        address indexed RedeemedCollateralAddress,
        uint256 indexed amountofCollateralRedeemed
    );

    event DScCoinBurned(address indexed DScCoinBurnedByWhom, uint256 indexed amountofDScBurned);

    mapping(address tokenCollateralAddr => address chainlinkPriceFeedAddr) private s_priceFeeds;

    mapping(address user => mapping(address Collateraltoken => uint256 amountDeposited)) private s_collateralDeposited;

    mapping(address => uint256) private s_DScMinted;

    address[] private s_collateralTokens;

    modifier tokenAddressNotZero(address _token) {
        if (s_priceFeeds[_token] == address(0)) {
            revert DSCEngine__TokenNotAllowedL37();
        }
        _;
    }

    modifier amountNotZero(uint256 _amount) {
        if (_amount == 0) {
            revert DSCEngine__AmountZeroNotAllowedL44();
        }
        _;
    }

    constructor(address DscAddr, address[] memory tokenAddresses, address[] memory priceFeedAddresses) {
        if (tokenAddresses.length != priceFeedAddresses.length) {
            revert();
        }
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            s_priceFeeds[tokenAddresses[i]] = priceFeedAddresses[i];
            s_collateralTokens.push(tokenAddresses[i]);
        }
        i_dscCoin = DScCoin(DscAddr);
    }

    ////////// Public Functions ///////////

    // @notice: whenever we work with external contracts the best idea is to use nonReentrant
    function depositCollateral(address _tokenCollateralAddress, uint256 _amountofCollateralTokens)
        public
        tokenAddressNotZero(_tokenCollateralAddress)
        amountNotZero(_amountofCollateralTokens)
        nonReentrant
    {
        s_collateralDeposited[msg.sender][_tokenCollateralAddress] += _amountofCollateralTokens;
        emit CollateralDeposited(msg.sender, _tokenCollateralAddress, _amountofCollateralTokens);
        bool success =
            IERC20(_tokenCollateralAddress).transferFrom(msg.sender, address(this), _amountofCollateralTokens);
        // @notice: should we calculate the USDprice here also?
        if (!success) {
            revert DSCEngine__TransferFromcalldidfailedL165();
        }
    }

    function redeemCollateral(address _tokenCollateralAddress, uint256 _amountofCollateralTokens)
        public
        amountNotZero(_amountofCollateralTokens)
        nonReentrant
    {
        __RedeemCollateral(_tokenCollateralAddress, _amountofCollateralTokens, msg.sender, msg.sender);
        _revertIfHealthFactorIsBroken(msg.sender);
    }

    function mintDSc(uint256 amountDScToMint) public amountNotZero(amountDScToMint) {
        s_DScMinted[msg.sender] += amountDScToMint;
        emit DScCoinsMinted(msg.sender, amountDScToMint);
        _revertIfHealthFactorIsBroken(msg.sender);
        bool minted = i_dscCoin.mint(amountDScToMint, msg.sender);
        if (!minted) {
            revert DSCEngine__MintCallfailedL54();
        }
    }

    function burnDSc(uint256 _amountOfDScToBurn) public amountNotZero(_amountOfDScToBurn) {
        _BurnDSc(_amountOfDScToBurn, msg.sender, msg.sender);
    }

    ////////// External Functions ///////////

    function liquidate(address _user, uint256 amountofDebtToCover, address _tokenOfDebt) external {
        uint256 healthFactor = _healthFactor(_user);
        if (healthFactor < 1e18) {
            revert DSCEngine__BrokenHealthL122();
        }
        uint256 _collateralValueInUsd = getTokenAmountFromUsd(_tokenOfDebt, amountofDebtToCover);
        uint256 bonusCollateral = (_collateralValueInUsd * 10) / 100;
        uint256 totalCollateralToRedeem = bonusCollateral * _collateralValueInUsd;
        __RedeemCollateral(_tokenOfDebt, amountofDebtToCover, _user, msg.sender);
        _BurnDSc(amountofDebtToCover, _user, msg.sender);

        uint256 newhealthFactor = _healthFactor(_user);
        if (newhealthFactor <= healthFactor) {
            revert DSCEngine__BrokenHealthL132();
        }
    }

    function redeemCollateralForDSc(
        uint256 _amountOfDScToBurn,
        address _tokenCollateralAddress,
        uint256 _amountofCollateralTokens
    ) external {
        burnDSc(_amountOfDScToBurn);
        redeemCollateral(_tokenCollateralAddress, _amountofCollateralTokens);
    }

    function depositCollateralAndMintDSc(
        address _tokenCollateralAddress,
        uint256 _amountofCollateralTokens,
        uint256 amountDScToMint
    ) external {
        depositCollateral(_tokenCollateralAddress, _amountofCollateralTokens);
        mintDSc(amountDScToMint);
    }

    ////////// Internal Functions ///////////

    function getTokenAmountFromUsd(address _token, uint256 _amountInWei) internal returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(s_priceFeeds[_token]);
        (, int256 price,,,) = priceFeed.latestRoundData();
        uint256 usdAmountInwei = ((_amountInWei * 1e18) / (uint256(price) * 1e10));
        return usdAmountInwei;
    }

    ////////// Private Functions ///////////

    function __RedeemCollateral(address _tokenCollateralAddr, uint256 amountCollateral, address _from, address _to)
        private
    {
        s_collateralDeposited[_from][_tokenCollateralAddr] -= amountCollateral;
        emit CollateralRedeemed(_to, _tokenCollateralAddr, amountCollateral);
        bool success = IERC20(_tokenCollateralAddr).transfer(_to, amountCollateral);
        if (!success) {
            revert DSCEngine__TransfercalldidfailedL193();
        }
    }

    function _BurnDSc(uint256 amountDScToBurn, address onBehalfOf, address dscFrom) private {
        s_DScMinted[onBehalfOf] -= amountDScToBurn; // @notice: see what happens to this when a liquidator has to call it
        emit DScCoinBurned(dscFrom, amountDScToBurn);
        bool success = i_dscCoin.transferFrom(dscFrom, address(this), amountDScToBurn);
        if (!success) {
            revert DSCEngine__TransferFromcalldidfailedL201();
        }
        i_dscCoin.burn(amountDScToBurn);
    }

    /////////// PUBLIC VIEW FUNCTIONS ////////////////

    function getAllowedCollateralTokensAddress() public view returns (address[] memory) {
        return s_collateralTokens;
    }

    function getCollateralAmountDepositedByUser(address _user, address _collateralTokenAddress)
        public
        view
        returns (uint256)
    {
        uint256 AmountofCollateralDeposited = s_collateralDeposited[_user][_collateralTokenAddress];
        return AmountofCollateralDeposited;
    }

    function getDScCoinMintedByUser(address _user) public view returns (uint256 amountOfDScCoinMinted) {
        amountOfDScCoinMinted = s_DScMinted[_user];
    }

    function getAccountInformation(address user) public view returns (uint256, uint256) {
        uint256 totalDScMinted = s_DScMinted[user];
        uint256 collateralvalueInUsd = getAccountCollateralValueInUsd(user);
        return (totalDScMinted, collateralvalueInUsd);
    }

    function getAccountCollateralValueInUsd(address user) public view returns (uint256 totalCollateralValueInUsd) {
        for (uint256 i = 0; i < s_collateralTokens.length; i++) {
            address token = s_collateralTokens[i];
            uint256 amount = s_collateralDeposited[user][token];
            totalCollateralValueInUsd += getUsdValue(s_collateralTokens[i], amount);
        }
        return totalCollateralValueInUsd;
    }

    function getUsdValue(address _token, uint256 _amount) public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(s_priceFeeds[_token]);
        (, int256 price,,,) = priceFeed.latestRoundData();
        // @notice should allow only those tokens that have 8 decimals
        uint256 usdValue = (((uint256(price) * 1e10) * _amount) / 1e18);
        return usdValue;
        // price = real price×10^8
        // 100 * 5 = 500
        // 100,1e18
        // 5,  1e18
    }

    function getPriceFeedAddress_ofCollateralTokens(address _collateralTokenAddress) public view returns (address) {
        address PriceFeedAddressofToken = s_priceFeeds[_collateralTokenAddress];
        return PriceFeedAddressofToken;
    }

    /////////// PRIVATE VIEW FUNCTIONS ////////////////

    function _healthFactor(address _user) private view returns (uint256) {
        (uint256 totalDScMinted, uint256 collateralValueInUsd) = getAccountInformation(_user);
        uint256 collateralAdjustedForThreshold = (collateralValueInUsd * 50) / 100;
        if (totalDScMinted == 0) {
            return type(uint256).max;
        }
        uint256 c_collateralAdjusted = (collateralAdjustedForThreshold * 1e18) / totalDScMinted;
        return c_collateralAdjusted; // if less than 1 , get him/her liquidated
    }

    /////////// INTERNAL VIEW FUNCTIONS ////////////////

    function _revertIfHealthFactorIsBroken(address _user) internal view {
        uint256 UserHealthFactor = _healthFactor(_user);
        if (UserHealthFactor < 1e18) {
            revert DSCEngine__BrokenHealthL94();
        }
    }

    /////////// EXTERNAL VIEW FUNCTIONS ////////////////

    function getHealthFactor(address _user) external view returns (uint256) {
        uint256 healthFactor = _healthFactor(_user);
        return healthFactor;
    }
}
