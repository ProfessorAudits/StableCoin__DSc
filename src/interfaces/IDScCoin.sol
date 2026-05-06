// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

interface IDScCoin {
    /// @notice Burns a specified amount of DSC from the caller's balance.
    function burn(uint256 amount) external;

    /// @notice Mints a specified amount of DSC to a recipient address.
    function mint(uint256 _amount, address _to) external returns (bool);
}
