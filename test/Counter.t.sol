// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Counter} from "../src/Counter.sol";
import {CreateX} from "../src/CreateX.sol";

interface IReturnsString {
    function getString() external returns (bytes32);
}

interface IReturnsUint {
    function getUint() external returns (uint);
}

contract CounterTest is Test {
    Counter public counter;
    CreateX public createx;

    function setUp() public {
        counter = new Counter();
        counter.setNumber(0);
        createx = new CreateX();
    }

    function test_canDeploy() public {
        bytes memory bytecode = hex"600d8060093d393df3611234611234015f5260205ff3";
        bytes memory otherBytecode = hex"600d8060093d393df3611234611234015f5260205ff3";
        address newContract = createx.deployCreate(bytecode);
        IReturnsUint stringReturner = IReturnsUint(newContract);
        stringReturner.getUint();
        address otherNewContract = createx.deployCreate(otherBytecode);
        IReturnsUint otherStringReturner = IReturnsUint(otherNewContract);
        otherStringReturner.getUint();
    }

    function test_returnString() public {
        bytes memory bytecode = hex"601b8060093d393df36c48656c6c6f2c20576f726c64215f526016565f5ffd5b60205ff3";
        bytes memory otherBytecode = hex"601c8060093d393df36c48656c6c6f2c20576f726c64215f52610017565f5ffd5b60205ff3";
        address newContract = createx.deployCreate(bytecode);
        IReturnsString stringReturner = IReturnsString(newContract);
        stringReturner.getString();
        //string memory result = stringReturner.getString();
    }

}
