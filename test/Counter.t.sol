// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Counter} from "../src/Counter.sol";
import {CreateX} from "../src/CreateX.sol";
import {PuffDeployer, HuffDeployer} from "../src/Deployers.sol";

interface IAddsUints {
    function addUints(uint256, uint256) external returns (uint256);
}

contract CounterTest is Test {
    CreateX public createx;
    PuffDeployer public puffDeployer;
    HuffDeployer public huffDeployer;

    function setUp() public {
        createx = new CreateX();
        puffDeployer = new PuffDeployer();
        huffDeployer = new HuffDeployer();
    }

    function test_addNumbers() public {
        address newContract = puffDeployer.deployContract("examples/add_two.huff");
        IAddsUints adder = IAddsUints(newContract);
        uint256 sum = adder.addUints(1, 2);
        assertEq(sum, 3);
    }
}
