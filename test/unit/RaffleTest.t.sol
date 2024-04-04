// SPDX-License-Identifier: MIT

import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {Raffle} from "../../src/Raffle.sol";
import {Test, console} from "forge-std/Test.sol";

pragma solidity ^0.8.19;

contract RaffleTest is Test {

Raffle raffle;

address public 

function setUp() external {
    DeployRaffle deployer = new DeployRaffle();
     raffle = deployer.run();

}


}
