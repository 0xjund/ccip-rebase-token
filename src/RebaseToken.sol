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
// public
// internal
// private
// view & pure functions

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/*
 * @Title: Rebase Token
 * @Author: 0xJund
 * @Notice: This is a cross chain rebase token that incentivises users to deposit into a vault and gain interests in rewards
 * @Notice: The interest rate in the smart contract can only decrease
 * @Notice: Each user will have their own interest rate which is the global interest at the time of depositing
*/


contract RebaseToken is ERC20 {

/*//////////////////////////////////////////////////////////////
                                 ERRORS
//////////////////////////////////////////////////////////////*/

error RebaseToken__InterestRateCanOnlyDecrease(uint256 currentInterestRate, uint256 newInterestRate);



/*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
//////////////////////////////////////////////////////////////*/

    uint256 private constant PRECISION_FACTOR = 1e18;
    uint256 private s_interestRate = 5e10;
    mapping(address => uint256) private s_userInterestRate;
    mapping(address => uint256) private s_userLastUpdatedTimestamp;

/*//////////////////////////////////////////////////////////////
                                 EVENTS
//////////////////////////////////////////////////////////////*/

    event InterestRateSet(uint256 newInterestRateSet);

/*//////////////////////////////////////////////////////////////
                               FUNCTIONS
//////////////////////////////////////////////////////////////*/

    constructor() ERC20("Rebase Token", "RBT"){}
// Only Owner    constructor()


/*//////////////////////////////////////////////////////////////
                           EXTERNAL FUNCTIONS
/////////////////////////////////////////////////////////////*/

    /*
     * @notice Set the interest rate
     * @param _newInterestRate The new interest rate to be set
     * @dev The interest rate can only decrease
     */


    function setInterestRate(uint256 _newInterestRate) external {
        // Set the interest rate
        if (_newInterestRate < s_interestRate) {
          revert RebaseToken__InterestRateCanOnlyDecrease(s_interestRate, _newInterestRate);
        }
        s_interestRate = _newInterestRate;
        emit InterestRateSet(_newInterestRate);
    }

    /*
     * @notice Mint the user tokens when they deposit into the vault
     * @param _to The user to mint the tokens to
     * @param _amount The amount of tokens to mint
     */


    function mint(address _to, uint256 _amount) external {
        _mintAccruedInterest(_to);
        s_userInterestRate[_to] = s_interestRate;
        _mint(_to, _amount);
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
        return super.balanceOf(_user) * _calculateUserAccumulatedInterestSinceLastUpdate(_user);
    }

    /*
     * @notice Calculate the interest that has accumulated since the last update
     * @param _user The user to calculate the interest accumulated for
     * @return The interest that has accumuilate since the last update
     */

    function _calculateUserAccumulatedInterestSinceLastUpdate(address _user) internal view returns (uint256 linearInterest){
        // determine the interest since the last update
        // this is going to be linear growth with time
        // 1. Calculate the time since the last update
        // 2. Calculate the amount of linear growth
        uint256 timeElapsed = block.timestamp - s_userLastUpdatedTimestamp[_user];
        linearInterest = PRECISION_FACTOR + (s_userInterestRate[_user] * timeElapsed);
    }


    function _mintAccruedInterest(address _user) internal {
        s_userLastUpdatedTimestamp[_user] = block.timestamp;
    }

/*//////////////////////////////////////////////////////////////
                   PUBLIC AND EXTERNAL VIEW FUNCTIONS
//////////////////////////////////////////////////////////////*/
    /*
     * @notice Get the interest rate for the user
     * @param The user to get the interest rate for
     * @return The interest rate for the user
     */

    function getUserInterestRate(address _user) external view returns (uint256) {
        return s_userInterestRate[_user];
    }

}
