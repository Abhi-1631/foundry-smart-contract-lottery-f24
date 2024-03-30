// SPDX-License-Identifier: MIT

// Layout of Contract
// Version
// imports
// errors
// Interfaces, libraries, contracts
// Type declaration
// State variables
// Events
// Modifiers
// Functions

// Layout of function
// constructor
// recieve
// recieve function (if any)
// fallback function (if any)
//external
// public
// internal
// private
// view & pure functions

pragma solidity ^0.8.19;

/**
 * @title A sample Raffale Contract
 * @author Abhi1631
 * @notice This contract is for creating a sample raffle
 * @dev Implements Chainlink VRFv2
 */

contract Raffle {
    // custom errors
    //best practice -> Name it with a prefix of name of contract
    // Why? - when working with multiple contracts -> helps u to know which error comes from what contract
    error Raffle_NotEnoughEthSent();

    // State Variables
    uint256 private immutable i_entranceFee; // i -> immutable variable
    // @dev Duration of lottery in seconds
    uint256 private immutable i_interval;
    address private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;

    address[] private s_players; // s -> storage variables
    uint256 private s_lastTimeStamp;

    /** Events */
    // 1. Make migration easier
    // 2. Makes front end "indexing" easier
    event EnteredRaffle(address indexed player);

    constructor(
        uint256 enteranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 gasLane,
        uint64 subscriptionId
    ) {
        i_entranceFee = enteranceFee;
        i_interval = interval;
        i_vrfCoordinator = vrfCoordinator;
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        s_lastTimeStamp = block.timestamp;
    }

    function enterRaffle() external payable {
        // require(msg.value >= i_entranceFee, "Not enough ETH sent");
        // More Gas Efficient way
        if (msg.value < i_entranceFee) {
            revert Raffle_NotEnoughEthSent();
        }
        s_players.push(payable(msg.sender)); // Payable -> To make an address allow to get ETh/ Tokens

        emit EnteredRaffle(msg.sender);
    }

    // 1. Get a random number
    // 2. Use the random number to pick a player
    // 3. Be automatically called
    function pickWinner() external {
        // Check to see if enough time is passed to pick a winner
        // 1000 - 500 = 500. interval is 600s . means not enough time passed
        // 1200 -500 = 700 . intrval 600 . 700>600 .enough time passed
        if ((block.timestamp - s_lastTimeStamp) < i_interval) {
            revert();
        }

        // 1. Request the RNG
        // 2. Get the random number
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            keyHash, // gas lane
            s_subscriptionId, // id funded with link
            requestConfirmations, // number of block confirmations
            callbackGasLimit, // not to overspend
            numWords // number of random numbers
        );
    }

    /** Getter Functions */

    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }
}
