//SPDX-License-Interaction:MIT
pragma solidity 0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig, CodeConstants} from "script/HelperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "test/mocks/LinkToken.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

contract CreateSubscription is Script {
    function createSubscriptionUsingConfig() public returns (uint256, address) {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        address account = helperConfig.getConfig().account;
        (uint256 subId, ) = createSubscription(vrfCoordinator, account);
        return (subId, vrfCoordinator);
    }

    // create subscription...
    function createSubscription(
        address vrfCoordinator, address account
    ) public returns (uint256, address) {
        console.log("Creatin subscription on chain Id", block.chainid);
        vm.startBroadcast(account);
        uint256 subId = VRFCoordinatorV2_5Mock(vrfCoordinator)
            .createSubscription();
        vm.stopBroadcast();
        console.log("Your subscription Id is:", subId);
        console.log(
            "Please update the subscription Id in your HelperConfig.s.sol"
        );
        return (subId, vrfCoordinator);
    }

    function run() public {
        createSubscriptionUsingConfig();
    }
}

contract FundSubscription is Script, CodeConstants {
    uint256 public constant FUND_AMOUNT = 3 ether; //3 LINK

    function FundSUbscriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        uint256 subscriptionId = helperConfig.getConfig().subscriptionId;
        address linkToken = helperConfig.getConfig().link;
        address account = helperConfig.getConfig().account;
        fundSubscription(vrfCoordinator, subscriptionId, linkToken, account);
    }

    function fundSubscription(
        address vrfcoordinator,
        uint256 subscriptionId,
        address linkToken, address account
    ) public {
        console.log("Funding subscription:", subscriptionId);
        console.log("Using vrfcoordinator:", vrfcoordinator);
        console.log("on ChainId: ", block.chainid);

        if (block.chainid == LOCAL_CHAIN_ID) {
            vm.startBroadcast();
            VRFCoordinatorV2_5Mock(vrfcoordinator).fundSubscription(
                subscriptionId,
                FUND_AMOUNT * 100
            );
            vm.stopBroadcast();
        } else {
            vm.startBroadcast(account);
            LinkToken(linkToken).transferAndCall(
                vrfcoordinator,
                FUND_AMOUNT,
                abi.encode(subscriptionId)
            );
            vm.stopBroadcast();
        }
    }

    function run() public {
        FundSUbscriptionUsingConfig();
    }
}

contract AddConsumer is Script {

  function addConsumerUsingConfig(address mostRecentlyDeployed) public{
    HelperConfig helperConfig = new HelperConfig();
    uint256 subId = helperConfig.getConfig().subscriptionId;
    address vrfcoordinator = helperConfig.getConfig().vrfCoordinator;
    address account = helperConfig.getConfig().account;
    addConsumer(mostRecentlyDeployed, vrfcoordinator,subId,account);
  }



function addConsumer (address contractToAddToVrf, address vrfCoordinator,uint256 subId, address account) public {
    console.log("Adding consumer to consumer contract:", vrfCoordinator);
    console.log ("To vrfCoordinato:", vrfCoordinator);
    console.log ("on Chain:", block.chainid);
    vm.startBroadcast(account);
      VRFCoordinatorV2_5Mock(vrfCoordinator).addConsumer(subId, contractToAddToVrf);
    vm.stopBroadcast();
}
  function run() external {
address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("Raffle", block.chainid);
addConsumerUsingConfig(mostRecentlyDeployed);
  }
}