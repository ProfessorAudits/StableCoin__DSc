// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import {ERC20Burnable, ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract DScCoin is ERC20Burnable, Ownable {
    constructor() ERC20("DScCoin", "DSc") Ownable(msg.sender) {}

    function burn(uint256 amount) public virtual override onlyOwner {
        uint256 acBalance = balanceOf(msg.sender);
        if (amount == 0) {
            revert();
        }
        if (acBalance < amount) {
            revert();
        }

        super.burn(amount);
    }

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
}
