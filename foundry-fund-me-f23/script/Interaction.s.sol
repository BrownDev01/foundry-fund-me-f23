//SPDX-License-Identifier: MIT

// Fund
// Withdraw

pragma solidity ^0.8.18;

import {Script, console} from "forge-std/Script.sol";
import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";
import {FundMe} from "../src/FundMe.sol";
contract FundFundMe is Script {
    uint256 constant SEND_VALUE = 0.01 ether;
  function fundFundMe(address mostRecentlyDeployed) public {
    
    FundMe(payable(mostRecentlyDeployed)).fund{value: SEND_VALUE}();
   
    console.log("Funded FundMe with %s", SEND_VALUE);
  }

   function run() external{
        address mostRecenlyDeployed = DevOpsTools.get_most_recent_deployment(
            "FundMe",
            block.chainid
            );
            vm.startBroadcast();
            fundFundMe(mostRecenlyDeployed);
             vm.stopBroadcast();
   }

}

contract WithdrawFundMe is Script {
       
  function withdrawFundMe(address mostRecentlyDeployed) public {
    vm.startBroadcast();
    FundMe(payable(mostRecentlyDeployed)).withdraw();
   vm.stopBroadcast();
  }

   function run() external{
        address mostRecenlyDeployed = DevOpsTools.get_most_recent_deployment(
            "FundMe",
            block.chainid
            );
            vm.startBroadcast();
            FundFundMe(mostRecenlyDeployed);
             vm.stopBroadcast();
   }

}