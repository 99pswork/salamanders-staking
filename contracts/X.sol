// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract X is ERC20{
    constructor() public ERC20('X Token', 'X') {
        _mint(msg.sender, 2_500_000_000 * 10 ** 18);
    }
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }
}
