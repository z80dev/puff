// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Counter} from "../src/Counter.sol";
import {CreateX} from "../src/CreateX.sol";

interface IAddsUints {
    function addUints(uint256, uint256) external returns (uint256);
}

contract CounterTest is Test {
    Counter public counter;
    CreateX public createx;

    function setUp() public {
        counter = new Counter();
        counter.setNumber(0);
        createx = new CreateX();
    }

    function test_addNumbers() public {
        bytes memory bytecode = hex"600c8060093d393df3600435602435015952595ff3";
        address newContract = createx.deployCreate(bytecode);
        IAddsUints adder = IAddsUints(newContract);
        uint256 sum = adder.addUints(1, 2);
        assertEq(sum, 3);
    }
}
