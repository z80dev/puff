// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {PuffDeployer, HuffDeployer} from "../src/Deployers.sol";

interface IAddsUints {
    function addUints(uint256, uint256) external returns (uint256);
}

interface ISaysHello {
    function sayHello() external returns (bytes32);
}

interface ISafeOps {
    function op(uint256 x, uint256 y, uint256 z) external returns (uint256);
}

contract PuffTest is Test {
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

    function test_jump() public {
        address newContract = puffDeployer.deployContract("examples/jump.huff");
        ISaysHello jumper = ISaysHello(newContract);
        bytes32 message = jumper.sayHello();
        assertEq(message, 0x0000000000000000000000000000000000000048656c6c6f2c20576f726c6421);
    }

    function test_macro_args() public {
        address newContract = puffDeployer.deployContract("examples/macro_args.huff");
        ISafeOps ops = ISafeOps(newContract);
        uint256 result = ops.op(2, 5, 10);
        assertEq(result, 13);
    }
}
