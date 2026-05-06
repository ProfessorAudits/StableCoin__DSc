# ProfessorAudits__DSc StableCoin Protocol

## What is DSc StableCoin Protocol?

DSc Protocol is a collateral-backed stablecoin system. Users deposit supported crypto assets as collateral and can mint DSC, a stablecoin issued by the protocol.

The protocol currently supports only:
- WETH.
- LINK.

No other collateral tokens are supported right now. In the future, if the protocol ever adds more collateral, it will only add tokens with compatible Chainlink price feeds and careful decimal handling. Chainlink price feeds commonly use 8 decimals, but feed decimals are not always the same for every asset.

---

## How it works

You deposit supported collateral into the protocol and borrow DSC against it.

Basic flow:
1. Deposit WETH or LINK.
2. Mint DSC based on your collateral value.
3. Keep your position healthy.
4. Repay DSC when you want to unlock your collateral.
5. If your position becomes unsafe, it can be liquidated.

---

## Main features

### Collateral deposits
You can deposit:
- WETH
- LINK

These are the only accepted collateral token addresses for now.

### DSC minting
After depositing collateral, you can mint DSC. The amount you can mint depends on how much collateral you have and whether your position stays safe.

### Collateral redemption
You can burn DSC and withdraw collateral later.

### Combined actions
The protocol also supports convenience actions:
- deposit collateral and mint DSC in one transaction,
- burn DSC and redeem collateral in one transaction.

### Liquidation
If a user’s position becomes too risky, another user can help liquidate it. Liquidation is designed to keep the protocol safe.

---

## Health factor

Each account has a health factor.

- A healthy position means the user has enough collateral for the DSC they minted.
- If the health factor becomes too low, the account can be liquidated.
- The system uses a threshold-based safety check to prevent undercollateralization.

You do not need to calculate this manually in normal use, but it is the main risk metric of the protocol.

---

## Supported tokens

Right now the protocol supports only:
- WETH.
- LINK.

That means you cannot deposit any other token.

If the team adds more collateral later, those tokens must match the protocol’s technical requirements, including price-feed compatibility and decimal handling. Chainlink price feeds are often 8 decimals, but that must be verified per asset [web:21][web:30].

---

## What you need to use it

To interact with the protocol, you need:
- a wallet,
- WETH or LINK for collateral,
- DSC if you want to repay debt or redeem collateral.

If you are depositing collateral, you must first approve the protocol to spend your tokens.

---

## Simple example

A typical user flow looks like this:

1. Approve WETH:
```solidity
IERC20(weth).approve(address(engine), amount);
```

2. Deposit and mint:
```solidity
engine.depositCollateralAndMintDSc(weth, amount, mintAmount);
```

3. Later, repay and redeem:
```solidity
engine.redeemCollateralForDSc(burnAmount, weth, collateralAmount);
```

---

## Safety rules

The protocol only allows safe borrowing against collateral. If your position becomes too risky:
- minting more DSC may fail,
- withdrawing too much collateral may fail,
- liquidation may become possible.

This is how the protocol protects itself and keeps DSC backed by assets.

---

## Important note

The protocol is not a general multi-collateral system yet.

It is intentionally limited to:
- WETH,
- LINK.

No additional tokens will be accepted for now.