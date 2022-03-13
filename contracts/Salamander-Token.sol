// SPDX-License-Identifier: UNLICENSED

pragma solidity >= 0.8.1;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract SalamanderToken is ERC20{

    constructor(string memory _name, string memory _symbol, uint256 _supply) ERC20(_name, _symbol) {
        _mint(msg.sender, _supply * 10 ** 18);
    }
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }
}
