//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";
import {FundFundMe, WithdrawFundMe} from "../../script/Interaction.s.sol";
contract InteractionsTest is Test {
     FundMe fundMe;
        address  USER = makeAddr("user");
     uint256 constant SEND_VALUE = 0.1 ether; // 10000000000000000
     uint256 constant STARTING_BALANCE = 10 ether;
     uint256 constant GAS_PRICE = 1;

    function setUp() external {
        DeployFundMe deploy = new DeployFundMe();
        fundMe = deploy.run();
        vm.deal(USER, STARTING_BALANCE);
    }

    function testUserCanFundInteractions() public {
        FundFundMe fundFundMe = new FundFundMe();
        vm.deal(address(fundFundMe), 1 ether);
         fundFundMe.fundFundMe(address(fundMe));
      WithdrawFundMe withdrawFundMe = new WithdrawFundMe();
      withdrawFundMe.withdrawFundMe(address(fundMe));
      assert(address(fundMe).balance == 0);
       

    }
}