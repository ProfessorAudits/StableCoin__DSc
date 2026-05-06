# ProfessorAudits__DSc StableCoin Protocol - Developer README

## Overview

DSc StableCoin Protocol is a collateralized stablecoin system built around two contracts:

- `DScCoin`: the ERC20 stablecoin token.
- `DScEngine`: the core engine that accepts collateral, mints/burns DSC, and enforces health factor rules.

The protocol currently supports only:
- WETH as collateral.
- LINK as collateral.

No additional collateral tokens are planned for now. If more tokens are ever added, they must be supported by Chainlink price feeds and compatible with the protocol’s decimal assumptions. Chainlink feed answers are commonly 8 decimals, but feed decimals are not guaranteed to always be 8, so this assumption should be handled carefully in future expansions [web:21][web:30].

---

## Architecture

### `DScCoin`
`DScCoin` is the stablecoin users receive after depositing collateral in the engine. It inherits from `ERC20Burnable` and `Ownable`.

Important behaviors:
- Only the owner can mint and burn.
- `mint(uint256 _amount, address _to)` mints tokens to a user.
- `burn(uint256 amount)` burns tokens from the caller’s balance.

Example:
```solidity
function mint(uint256 _amount, address _to) public onlyOwner returns (bool) {
    if (_amount == 0) {
        revert();
    }

    if (_to == address(0)) {
        revert();
    }
    _mint(_to, _amount);

    return true;
}
```

This design ensures that the engine controls DSC issuance and destruction.

---

### `DScEngine`
`DScEngine` is the core protocol contract. It:
- accepts allowed collateral,
- tracks deposits,
- tracks DSC minted per user,
- computes health factor,
- allows liquidation of unhealthy positions.

It uses:
- `ReentrancyGuard` for external state-changing functions,
- `IERC20` for collateral transfers,
- `AggregatorV3Interface` for Chainlink price feeds.

---

## State Model

The engine stores three main pieces of protocol state:

```solidity
mapping(address => mapping(address => uint256)) private s_collateralDeposited;
mapping(address => uint256) private s_DScMinted;
mapping(address => address) private s_priceFeeds;
```

Meaning:
- each user can deposit multiple collateral tokens,
- each user has a DSC mint balance,
- each collateral token maps to one price feed.

The approved collateral token list is stored in:

```solidity
address[] private s_collateralTokens;
```

At the moment, this list should contain only WETH and LINK.

---

## Collateral Flow

### Deposit collateral
Users deposit allowed collateral into the engine.

```solidity
function depositCollateral(address _tokenCollateralAddress, uint256 _amountofCollateralTokens)
    public
    tokenAddressNotZero(_tokenCollateralAddress)
    amountNotZero(_amountofCollateralTokens)
    nonReentrant
{
    s_collateralDeposited[msg.sender][_tokenCollateralAddress] += _amountofCollateralTokens;
    emit CollateralDeposited(msg.sender, _tokenCollateralAddress, _amountofCollateralTokens);

    bool success = IERC20(_tokenCollateralAddress).transferFrom(
        msg.sender,
        address(this),
        _amountofCollateralTokens
    );

    if (!success) {
        revert DSCEngine__TransferFromcalldidfailedL165();
    }
}
```

How it works:
1. The token must be allowed.
2. The amount must be greater than zero.
3. User approval is required before calling `transferFrom`.
4. Deposit state is updated.
5. The contract pulls tokens from the user.

---

### Mint DSC
Users can mint DSC only if their position remains healthy.

```solidity
function mintDSc(uint256 amountDScToMint) public amountNotZero(amountDScToMint) {
    s_DScMinted[msg.sender] += amountDScToMint;
    emit DScCoinsMinted(msg.sender, amountDScToMint);
    _revertIfHealthFactorIsBroken(msg.sender);

    bool minted = i_dscCoin.mint(amountDScToMint, msg.sender);
    if (!minted) {
        revert DSCEngine__MintCallfailedL54();
    }
}
```

Important detail:
- the engine updates the mint record first,
- then checks health factor,
- then mints DSC.

This means the minting logic depends on collateral backing.

---

### Burn DSC
Burning reduces the user’s debt position.

```solidity
function burnDSc(uint256 _amountOfDScToBurn) public amountNotZero(_amountOfDScToBurn) {
    _BurnDSc(_amountOfDScToBurn, msg.sender, msg.sender);
}
```

The private helper does the actual accounting and token burn:
```solidity
function _BurnDSc(uint256 amountDScToBurn, address onBehalfOf, address dscFrom) private {
    s_DScMinted[onBehalfOf] -= amountDScToBurn;
    emit DScCoinBurned(dscFrom, amountDScToBurn);

    bool success = i_dscCoin.transferFrom(dscFrom, address(this), amountDScToBurn);
    if (!success) {
        revert DSCEngine__TransferFromcalldidfailedL201();
    }
    i_dscCoin.burn(amountDScToBurn);
}
```

---

### Redeem collateral
Users can withdraw collateral as long as their position stays safe.

```solidity
function redeemCollateral(address _tokenCollateralAddress, uint256 _amountofCollateralTokens)
    public
    amountNotZero(_amountofCollateralTokens)
    nonReentrant
{
    __RedeemCollateral(_tokenCollateralAddress, _amountofCollateralTokens, msg.sender, msg.sender);
    _revertIfHealthFactorIsBroken(msg.sender);
}
```

The engine:
1. decreases the user’s collateral balance,
2. transfers collateral back,
3. checks whether the position remains healthy.

---

## Health Factor

The protocol uses a health factor to determine if a position is safe.

```solidity
function _healthFactor(address _user) private view returns (uint256) {
    (uint256 totalDScMinted, uint256 collateralValueInUsd) = getAccountInformation(_user);
    uint256 collateralAdjustedForThreshold = (collateralValueInUsd * 50) / 100;

    if (totalDScMinted == 0) {
        return type(uint256).max;
    }

    uint256 c_collateralAdjusted = (collateralAdjustedForThreshold * 1e18) / totalDScMinted;
    return c_collateralAdjusted;
}
```

Interpretation:
- if health factor is below `1e18`, the position is considered unsafe,
- positions below that threshold can be liquidated.

The liquidation path is enforced by:
```solidity
function _revertIfHealthFactorIsBroken(address _user) internal view {
    uint256 UserHealthFactor = _healthFactor(_user);
    if (UserHealthFactor < 1e18) {
        revert DSCEngine__BrokenHealthL94();
    }
}
```

---

## Price Calculation

The engine uses Chainlink price feeds to convert collateral amounts to USD values.

```solidity
function getUsdValue(address _token, uint256 _amount) public view returns (uint256) {
    AggregatorV3Interface priceFeed = AggregatorV3Interface(s_priceFeeds[_token]);
    (, int256 price,,,) = priceFeed.latestRoundData();
    uint256 usdValue = (((uint256(price) * 1e10) * _amount) / 1e18);
    return usdValue;
}
```

This code assumes the price feed answer is scaled to 8 decimals. Chainlink feeds often use 8 decimals, but that is not universal, so future collateral onboarding must verify feed decimals first [web:21][web:30].

### Current collateral policy
- Only WETH and LINK are allowed.
- No other collateral will be added for now.
- Any future collateral token must be supported by the protocol’s price-feed logic and decimal handling.

WETH and LINK both have 18 token decimals in common deployments, while Chainlink feed decimals may vary by feed [web:22][web:23][web:21].

---

## Main User Functions

### Deposit and mint in one call
```solidity
function depositCollateralAndMintDSc(
    address _tokenCollateralAddress,
    uint256 _amountofCollateralTokens,
    uint256 amountDScToMint
) external {
    depositCollateral(_tokenCollateralAddress, _amountofCollateralTokens);
    mintDSc(amountDScToMint);
}
```

This is the standard user entrypoint.

---

### Burn and redeem in one call
```solidity
function redeemCollateralForDSc(
    uint256 _amountOfDScToBurn,
    address _tokenCollateralAddress,
    uint256 _amountofCollateralTokens
) external {
    burnDSc(_amountOfDScToBurn);
    redeemCollateral(_tokenCollateralAddress, _amountofCollateralTokens);
}
```

This helps users reduce debt and withdraw collateral in one flow.

---

### Liquidation
```solidity
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
```

Liquidation is intended to improve an unhealthy user’s position by repaying their debt and taking collateral with a bonus. The current implementation should be reviewed carefully, because the collateral bonus calculation and token amounts appear inconsistent with the intended liquidation flow.

---

## Developer Notes

### Required approvals
Before calling `depositCollateral`, the user must approve the engine to spend the collateral token.

Example:
```solidity
IERC20(weth).approve(address(engine), amount);
engine.depositCollateral(weth, amount);
```

### Reentrancy protection
All functions that move external tokens should remain protected with `nonReentrant`.

### Suggested cleanup
The contract would benefit from:
- consistent naming (`DSC` vs `DSc`),
- a cleaner liquidation implementation,
- a dedicated interface file,
- a safer feed-decimal approach using `AggregatorV3Interface.decimals()` if future tokens are added [web:21][web:30].

---

## Testing Areas

Recommended test coverage:
- deposit allowed collateral,
- reject zero deposits,
- reject unsupported tokens,
- mint within safe collateral limits,
- revert on broken health factor,
- burn DSC and redeem collateral,
- liquidation path,
- price feed integration,
- reentrancy protection.

---

## Future Extensibility

The protocol is intentionally limited to WETH and LINK for now.

If new collateral tokens are ever added:
- only add assets with reliable Chainlink support,
- verify the price feed decimal format,
- do not assume every feed has 8 decimals,
- update collateral onboarding logic before deployment [web:21][web:30].

---
