// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

// Layout of Contract:
// version
// imports
// interfaces, libraries, contracts
// errors
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// internal
// private
// view & pure functions

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

/*
 * @Title: Rebase Token
 * @Author: 0xJund
 * @Notice: This is a cross chain rebase token that incentivises users to deposit into a vault and gain interests in rewards
 * @Notice: The interest rate in the smart contract can only decrease
 * @Notice: Each user will have their own interest rate which is the global interest at the time of depositing
*/

contract RebaseToken is ERC20, Ownable, AccessControl {
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error RebaseToken__InterestRateCanOnlyDecrease(uint256 currentInterestRate, uint256 newInterestRate);

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    uint256 private constant PRECISION_FACTOR = 1e18;
    uint256 private s_interestRate = (5 * PRECISION_FACTOR) / 1e8; // 10^-8 == 1 / 10^8
    bytes32 private constant MINT_AND_BURN_ROLE = keccak256("MINT_AND_BURN_ROLE");
    mapping(address => uint256) private s_userInterestRate;
    mapping(address => uint256) private s_userLastUpdatedTimestamp;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event InterestRateSet(uint256 newInterestRateSet);

    /*//////////////////////////////////////////////////////////////
                               FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    constructor() ERC20("Rebase Token", "RBT") Ownable(msg.sender) {}

    /*//////////////////////////////////////////////////////////////
                           EXTERNAL FUNCTIONS
    /////////////////////////////////////////////////////////////*/

    function grantMintAndBurnRole(address _account) external onlyOwner {
        _grantRole(MINT_AND_BURN_ROLE, _account);
    }

    /*
     * @notice Set the interest rate
     * @param _newInterestRate The new interest rate to be set
     * @dev The interest rate can only decrease
     */

    function setInterestRate(uint256 _newInterestRate) external onlyOwner {
        // Set the interest rate
        if (_newInterestRate >= s_interestRate) {
            revert RebaseToken__InterestRateCanOnlyDecrease(s_interestRate, _newInterestRate);
        }
        s_interestRate = _newInterestRate;
        emit InterestRateSet(_newInterestRate);
    }

    /*
     * @notice Get a principle balance of a user. This is the number of tokens that have currently been minted to the user not including any interest that has been accrued since the last time the user intereacted with the protocol
     * @param _user The user to get the principle balance for
     * @return The principle balance of the user
     */

    function principleBalanceOf(address _user) external view returns (uint256) {
        return super.balanceOf(_user);
    }

    /*
     * @notice Mint the user tokens when they deposit into the vault
     * @param _to The user to mint the tokens to
     * @param _amount The amount of tokens to mint
     */

    function mint(address _to, uint256 _amount) external onlyRole(MINT_AND_BURN_ROLE) {
        _mintAccruedInterest(_to);
        s_userInterestRate[_to] = s_interestRate;
        _mint(_to, _amount);
    }

    /*
    * @notice burn the user tokens when they withdraw from the vault 
    * @param The amount of tokens to burn 
    */

    function burn(address _from, uint256 _amount) external onlyRole(MINT_AND_BURN_ROLE) {
        _mintAccruedInterest(_from);
        _burn(_from, _amount);
    }

    /*
     * calculate the balance of the user including the interest since the last update
     * (principle balance) +  interest that has accrued
     * @param _user The user to calculate the balance for
     * @return The balance of the user including the interest that has accumulated since the last update
     */

    function balanceOf(address _user) public view override returns (uint256) {
        // get the current principle balance of the user
        // X the balance by the interest accumulated since the last update
        return super.balanceOf(_user) * _calculateUserAccumulatedInterestSinceLastUpdate(_user) / PRECISION_FACTOR;
    }

    /*
     * @notice Transfer tokens from one to another
     * @param _recipient The user to transfer the tokens to
     * @param _amount The amount of tokens to transfer
     * @return True if transfer was successful
     */
    function transfer(address _recipient, uint256 _amount) public override returns (bool) {
        _mintAccruedInterest(msg.sender);
        _mintAccruedInterest(_recipient);
        if (_amount == type(uint256).max) {
            _amount = balanceOf(msg.sender);
        }
        if (balanceOf(_recipient) == 0) {
            s_userInterestRate[_recipient] = s_userInterestRate[msg.sender];
        }
        return super.transfer(_recipient, _amount);
    }

    /*
     * @notice Transfer tokens from one user to another
     * @param _sender The user to transfer the tokens from
     * @param _recipient The user to transfer the tokens to
     * @param _amount The amount of tokens to transfer
     * @return True if the transfer was succesful
     */

    function transferFrom(address _sender, address _recipient, uint256 _amount) public override returns (bool) {
        _mintAccruedInterest(_sender);
        _mintAccruedInterest(_recipient);
        if (_amount == type(uint256).max) {
            _amount = balanceOf(msg.sender);
        }
        if (balanceOf(_recipient) == 0) {
            s_userInterestRate[_recipient] = s_userInterestRate[_sender];
        }
        return super.transferFrom(_sender, _recipient, _amount);
    }

    /*
     * @notice Calculate the interest that has accumulated since the last update
     * @param _user The user to calculate the interest accumulated for / PRECISION_FACTOR
     * @return The interest that has accumuilate since the last update
     */

    function _calculateUserAccumulatedInterestSinceLastUpdate(address _user)
        internal
        view
        returns (uint256 linearInterest)
    {
        // determine the interest since the last update
        // this is going to be linear growth with time
        // 1. Calculate the time since the last update
        // 2. Calculate the amount of linear growth
        uint256 timeElapsed = block.timestamp - s_userLastUpdatedTimestamp[_user];
        linearInterest = PRECISION_FACTOR + (s_userInterestRate[_user] * timeElapsed);
    }

    /*
    * @notice Mint the accured interest to the user since the last time they intereacted with the protocol 
    * @param _user The user to mint the accrued interest to 
    */

    function _mintAccruedInterest(address _user) internal {
        uint256 previousPrincipleBalance = super.balanceOf(_user);
        uint256 currentBalance = balanceOf(_user);
        uint256 balanceIncrease = currentBalance - previousPrincipleBalance;
        s_userLastUpdatedTimestamp[_user] = block.timestamp;
        _mint(_user, balanceIncrease);
    }

    /*//////////////////////////////////////////////////////////////
                   PUBLIC AND EXTERNAL VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /*
     * @notice Get the interest rate for the contract
     * @return The interest rate for the contract
     */

    function getInterestRate() external view returns (uint256) {
        return s_interestRate;
    }

    /*
     * @notice Get the interest rate for the user
     * @param The user to get the interest rate for
     * @return The interest rate for the user
     */

    function getUserInterestRate(address _user) external view returns (uint256) {
        return s_userInterestRate[_user];
    }
}
