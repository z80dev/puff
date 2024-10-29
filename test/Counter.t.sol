// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {PuffDeployer, HuffDeployer} from "../src/Deployers.sol";

interface IAddsUints {
    function addUints(uint256, uint256) external returns (uint256);
}

contract CounterTest is Test {
    PuffDeployer public puffDeployer;

    function setUp() public {
        puffDeployer = new PuffDeployer();
    }

    function test_addNumbers() public {
        address newContract = puffDeployer.deployContract("examples/add_two.huff");
        IAddsUints adder = IAddsUints(newContract);
        uint256 sum = adder.addUints(1, 2);
        assertEq(sum, 3);
    }
}
