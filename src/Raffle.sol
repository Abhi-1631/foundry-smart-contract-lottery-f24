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

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

/**
 * @title A sample Raffale Contract
 * @author Abhi1631
 * @notice This contract is for creating a sample raffle
 * @dev Implements Chainlink VRFv2
 */

contract Raffle is VRFConsumerBaseV2 {
    // custom errors
    //best practice -> Name it with a prefix of name of contract
    // Why? - when working with multiple contracts -> helps u to know which error comes from what contract
    error Raffle_NotEnoughEthSent();
    error Raffle_TransferFailed();
    error Raffle_RaffleNotOpen();
    error Raffle_UpkeepNotNeeded(
        uint256 currentBalance,
        uint256 numPlayers,
        uint256 raffleState
    );

    /** Type Declarations */

    enum RaffleState {
        OPEN,
        CALCULATING
    }

    // State Variables
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    uint256 private immutable i_entranceFee; // i -> immutable variable
    // @dev Duration of lottery in seconds
    uint256 private immutable i_interval;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;

    address[] private s_players; // s -> storage variables
    uint256 private s_lastTimeStamp;
    address private s_recentWinner;
    RaffleState private s_raffleState;
    /** Events */
    // 1. Make migration easier
    // 2. Makes front end "indexing" easier
    event EnteredRaffle(address indexed player);
    event PickedWinner(address indexed winner);

    constructor(
        uint256 enteranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 gasLane,
        uint64 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2(vrfCoordinator) {
        i_entranceFee = enteranceFee;
        i_interval = interval;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;

        s_raffleState = RaffleState.OPEN;
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

    // When is the winner supposed to be picked?
    /**
 * @dev This is the function that the Chainlink Automation nodes call
 * to see if it's time to perform an uupkeep.
 * The following should be true for this to return true:
 * 1. The time interval has passed between raffle runs
 * 2. The raffle is in the OPEN state
 * 3. The contract has ETH (aka, players)
 * 4. (Implicit) The subscription is funded with LINK
 
 */
    function checkUpkeep(
        bytes memory /*checkData*/
    ) public view returns (bool upkeeepNeeded, bytes memory /*performData*/) {
        bool timeHasPassed = (block.timestamp - s_lastTimeStamp) < i_interval;
        bool isOpen = RaffleState.OPEN == s_raffleState;
        bool hasBalance = address(this).balance > 0;
        bool hasPlayers = s_players.length > 0;
        upkeeepNeeded = (timeHasPassed && isOpen && hasBalance && hasPlayers);
        return (upkeeepNeeded, "0x0");
    }

    // 1. Get a random number
    // 2. Use the random number to pick a player
    // 3. Be automatically called
    function performUpkeep(bytes calldata /* performData */) external {
        // Check to see if enough time is passed to pick a winner
        // 1000 - 500 = 500. interval is 600s . means not enough time passed
        // 1200 -500 = 700 . intrval 600 . 700>600 .enough time passed
        // if ((block.timestamp - s_lastTimeStamp) < i_interval) {
        // revert();
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Raffle_UpkeepNotNeeded(
                address(this).balance,
                s_players.length,
                uint256(s_raffleState)
            );
        }

        // 1. Request the RNG
        // 2. Get the random number
        s_raffleState = RaffleState.CALCULATING;
        //uint256 requestId
        i_vrfCoordinator.requestRandomWords(
            i_gasLane, // gas lane
            i_subscriptionId, // id funded with link
            REQUEST_CONFIRMATIONS, // number of block confirmations
            i_callbackGasLimit, // not to overspend
            NUM_WORDS // number of random numbers
        );
    }

    // CEI: Checks, Effects, Interactions
    function fulfillRandomWords(
        uint256 /* requestId */,
        uint256[] memory randomWords
    ) internal override {
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable winner = payable(s_players[indexOfWinner]);
        s_recentWinner = winner;
        s_raffleState = RaffleState.OPEN;

        s_players = new address payable[](0);
        s_lastTimeStamp = block.timestamp;
        emit PickedWinner(winner);
        // Interactons (Other Contracts)

        (bool success, ) = winner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle_TransferFailed();
        }
        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle_RaffleNotOpen();
        }
    }

    /** Getter Functions */

    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }
}
