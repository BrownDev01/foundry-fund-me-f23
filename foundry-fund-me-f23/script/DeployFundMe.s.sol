//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {FundMe} from "../src/FundMe.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
contract DeployFundMe is Script {
    function run() external returns (FundMe){
        //Before startBroadcast --> Not a "real" tx
       HelperConfig helperConfig = new HelperConfig();
       address ethUsdPriceFeed = helperConfig.activeNetworkConfig();

       // After startBroadcast --> Real tx
        vm.startBroadcast();
        FundMe fundMe = new FundMe(ethUsdPriceFeed);
        vm.stopBroadcast();
        return  fundMe;
    }

}
