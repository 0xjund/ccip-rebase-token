// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {IRebaseToken} from "./Interfaces/IRebaseToken.sol";

contract Vault{

    IRebaseToken private immutable i_rebaseToken;

    event Deposit(address indexed user, uint256 amount);
    event Redeem(address indexed user, uint256 amount);

    error Vault__RedeemFailed();

    constructor(IRebaseToken _rebaseToken) {
        i_rebaseToken = _rebaseToken;
    }

    receive() external payable {}

    /*
     * @notice Allows users to deposit ETH and mint rebase tokens in return
     *
        */

    function deposit() external payable {
        // need to get the amount of ETH the user has sent to mint tokens to the user
        i_rebaseToken.mint(msg.sender, msg.value);
        emit Deposit(msg.sender, msg.value);
    }

    /*
     * @notice Allows users to redeem their rebase tokens for ETH
     * @param _amount The amount of rebase tokens to redeem
        */

    function redeem(uint256 _amount) external {
        if (_amount == type(uint256).max) {
           _amount =  i_rebaseToken.balanceOf(msg.sender);
        }
        // Follow CEI!


        // Burn the tokens
        i_rebaseToken.burn(msg.sender, _amount);
        // Send the user ETH
        (bool success,) = payable(msg.sender).call{value: _amount}("");
        if (!success) {
            revert Vault__RedeemFailed();
        }
        emit Redeem(msg.sender, _amount);
    }

    /*
     * @notice Get the address of the rebase token
     * @return The address of the rebase token
     */

    function getRebaseTokenAddress() external view returns (address) {
        return address (i_rebaseToken);
    }
}
