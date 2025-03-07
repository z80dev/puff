// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {PuffDeployer, HuffDeployer} from "../src/Deployers.sol";

// These interfaces define callable functions on our test contracts
interface ISaysHello {
    function sayHello() external view returns (bytes32);
}

contract LongJumpsTest is Test {
    PuffDeployer public puffDeployer;
    HuffDeployer public huffDeployer;

    function setUp() public {
        puffDeployer = new PuffDeployer();
        huffDeployer = new HuffDeployer();
    }

    function test_longJump() public {
        address newContract = puffDeployer.deployContract("examples/long_jump.huff");
        ISaysHello jumper = ISaysHello(newContract);
        bytes32 message = jumper.sayHello();
        
        // The expected output is "Hello, World!" right-aligned in a bytes32

        assertEq(message, 0x0000000000000000000000000000000000000048656c6c6f2c20576f726c6421);
    }

    function test_longJump_Huff() public {
        address newContract = huffDeployer.deployContract("examples/long_jump.huff");
        ISaysHello jumper = ISaysHello(newContract);
        bytes32 message = jumper.sayHello();

        // The expected output is "Hello, World!" right-aligned in a bytes32

        assertEq(message, 0x0000000000000000000000000000000000000048656c6c6f2c20576f726c6421);
    }

}
