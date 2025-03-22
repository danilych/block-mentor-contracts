// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import { MessageClient } from "@vialabs-io/npm-contracts/MessageClient.sol";
import { ERC20Burnable } from "@openzeppelin-contracts/token/ERC20/extensions/ERC20Burnable.sol";
import { ERC20 } from "@openzeppelin-contracts/token/ERC20/ERC20.sol";

contract OmnichainToken is ERC20Burnable, MessageClient {
    constructor(string memory name, string memory ticker, address initialOwner, uint256 initialAmount)
        ERC20(name, ticker)
    {
        _mint(initialOwner, initialAmount);
        MESSAGE_OWNER = initialOwner;
    }

    function bridge(uint256 _destChainId, address _recipient, uint256 _amount) external onlyActiveChain(_destChainId) {
        _burn(msg.sender, _amount);

        _sendMessage(_destChainId, abi.encode(_recipient, _amount));
    }

    function messageProcess(uint256, uint256 _sourceChainId, address _sender, address, uint256, bytes calldata _data)
        external
        override
        onlySelf(_sender, _sourceChainId)
    {
        (address _recipient, uint256 _amount) = abi.decode(_data, (address, uint256));

        _mint(_recipient, _amount);
    }
}
