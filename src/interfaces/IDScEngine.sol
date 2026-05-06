// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

interface IDScEngine {
    /// @notice Deposits collateral tokens into the engine.
    function depositCollateral(address _tokenCollateralAddress, uint256 _amountofCollateralTokens) external;

    /// @notice Redeems collateral tokens from the engine.
    function redeemCollateral(address _tokenCollateralAddress, uint256 _amountofCollateralTokens) external;

    /// @notice Mints DSC tokens for the caller.
    function mintDSc(uint256 amountDScToMint) external;

    /// @notice Burns DSC tokens from the caller's position.
    function burnDSc(uint256 _amountOfDScToBurn) external;

    /// @notice Liquidates an undercollateralized user by covering their debt and taking collateral.
    function liquidate(address _user, uint256 amountofDebtToCover, address _tokenOfDebt) external;

    /// @notice Burns DSC and redeems collateral in a single call.
    function redeemCollateralForDSc(
        uint256 _amountOfDScToBurn,
        address _tokenCollateralAddress,
        uint256 _amountofCollateralTokens
    ) external;

    /// @notice Deposits collateral and mints DSC in a single call.
    function depositCollateralAndMintDSc(
        address _tokenCollateralAddress,
        uint256 _amountofCollateralTokens,
        uint256 amountDScToMint
    ) external;

    /// @notice Returns all collateral token addresses allowed by the engine.
    function getAllowedCollateralTokensAddress() external view returns (address[] memory);

    /// @notice Returns how much of a specific collateral token a user has deposited.
    function getCollateralAmountDepositedByUser(address _user, address _collateralTokenAddress)
        external
        view
        returns (uint256);

    /// @notice Returns how much DSC a user has minted.
    function getDScCoinMintedByUser(address _user) external view returns (uint256 amountOfDScCoinMinted);

    /// @notice Returns a user's total DSC minted and total collateral value in USD.
    function getAccountInformation(address user) external view returns (uint256, uint256);

    /// @notice Returns the total USD value of all collateral deposited by a user.
    function getAccountCollateralValueInUsd(address user) external view returns (uint256 totalCollateralValueInUsd);

    /// @notice Returns the USD value of a token amount.
    function getUsdValue(address _token, uint256 _amount) external view returns (uint256);

    /// @notice Returns the Chainlink price feed address for a collateral token.
    function getPriceFeedAddress_ofCollateralTokens(address _collateralTokenAddress) external view returns (address);

    /// @notice Returns the health factor of a user.
    function getHealthFactor(address _user) external view returns (uint256);
}
