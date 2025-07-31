//SPDX-License-Integration:MIT
pragma solidity 0.8.19;

import {Test} from "forge-std/Test.sol";
import {DeployRaffle} from "script/DeployRaffle.s.sol";
import {Raffle} from "../../src/Raffle.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {Vm} from "forge-std/Vm.sol";
import {VRFCoordinatorV2_5Mock} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {CodeConstants} from "script/HelperConfig.s.sol";
contract RaffleTest is CodeConstants, Test {
    Raffle public raffle;
    HelperConfig public helperConfig;

    uint256 entranceFee;
    uint256 interval;
    address vrfCoordinator;
    bytes32 gaslane;
    uint256 subscriptionId;
    uint32 callbackGasLimit;

    address public PLAYER = makeAddr("player");
    uint256 public constant STARTING_PLAYER_BALANCE = 10 ether;

    /*Events*/
    event RaffleEntered(address indexed player);
    event WinnerPicked(address indexed winner);

    function setUp() external {
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.deployContract();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        entranceFee = config.entranceFee;
        interval = config.interval;
        gaslane = config.gaslane;
        vrfCoordinator = config.vrfCoordinator;
        subscriptionId = config.subscriptionId;
        callbackGasLimit = uint32(config.callbackGasLimit);

        vm.deal(PLAYER, STARTING_PLAYER_BALANCE);
    }

    function testRaffleInitializesInOpenState() public view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }

    /*//////////////////////////////////////////////////////////////
                           ENTER RAFFLE
//////////////////////////////////////////////////////////////*/
    function testRaffleRevertsWhenYouDontPayEnough() public {
        // Arrange
        vm.prank(PLAYER);
        // Act / Assert
        vm.expectRevert(Raffle.Raffle__SendMoreToEnterRaffle.selector);
        raffle.enterRaffle();
    }

    function testRaffleRecordsPlayersWhenTheyEnter() public {
        //Arrange
        vm.prank(PLAYER);
        //Act
        raffle.enterRaffle{value: entranceFee}();
        //Assert
        address playerRecorded = raffle.getPlayer(0);
        assert(playerRecorded == PLAYER);
    }

    function testEnteringRaffleEmitsEvent() public {
        //Arrange
        vm.prank(PLAYER);
        //Act
        vm.expectEmit(true, false, false, false, address(raffle));
        emit RaffleEntered(PLAYER);
        //Assert
        raffle.enterRaffle{value: entranceFee}();
    }

    function testDontAllowPlayerToEnterWhileRaffleIsCalculating() public {
        // Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffle.performUpKeep(""); // <-


        //Act
        //Assert
        vm.expectRevert(Raffle.Raffle__RaffleNotOpen.selector);
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
    }


    /*//////////////////////////////////////////////////////////////
                           CHECKUPKEEP
//////////////////////////////////////////////////////////////*/
  function testCheckUpKeepReturnsFalseIfItHasNoBalance() public {
    //Arrange
     vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        //Act
        (bool upKeepNeeded,) = raffle.checkUpKeep("");

        //Assert
        assert(!upKeepNeeded);

  }

  function testCheckUpKeepReturnsFalseIfRaffleIsNotOpen() public {
    //Arrange
     vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffle.performUpKeep("");

        //Act
        (bool upKeepNeeded,) = raffle.checkUpKeep("");

        //assert
        assert(!upKeepNeeded);
  }
  // Challenge
  function testCheckUpKeepReturnsFalseIfEnoughTimeHasntpassed()public {
    //Arrange
    vm.prank(PLAYER);
    raffle.enterRaffle{value: entranceFee}();
    
       
        //Act
      (bool upKeepNeeded,) = raffle.checkUpKeep("");

        //Assert
        assert(!upKeepNeeded);

  }
  function testCheckUpKeepReturnsFalseIfEnoughTimeHaspassed()public {
    //Arrange
    vm.prank(PLAYER);
    raffle.enterRaffle{value: entranceFee}();
      vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffle.performUpKeep("");
       
        //Act
      (bool upKeepNeeded,) = raffle.checkUpKeep("");

        //Assert
        assert(!upKeepNeeded);

  }
  // testCheckUpKeepReturnsTrueWhenParametersAreGood
  function testCheckUpkeepReturnsTrueWhenParametersGood() public {
        // Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        // Act
        (bool upkeepNeeded,) = raffle.checkUpKeep("");

        // Assert
        assert(upkeepNeeded);
    }
      /*//////////////////////////////////////////////////////////////
                           PERFORMUPKEEP
//////////////////////////////////////////////////////////////*/
function testPerformUpKeepCanOnlyRunIfCheckUpKeepIstrue() public {
    //Arrange

    vm.prank(PLAYER);
    raffle.enterRaffle{value: entranceFee}();
      vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        //Act /Assert
        raffle.performUpKeep("");
}
function testPerformUpKeepRevertIfCheckUpKeepIsfalse() public {
    //Arrange
    uint256 currentBalance = 0;
    uint256 numPlayers = 0;
    Raffle.RaffleState rState = raffle.getRaffleState();

    vm.prank(PLAYER);
    raffle.enterRaffle{value: entranceFee}();
    currentBalance = currentBalance + entranceFee;
    numPlayers =1;
    //Act/Assert
    vm.expectRevert(
        abi.encodeWithSelector(Raffle.Raffle__UpKeepNotNeeded.selector, currentBalance,
         numPlayers, rState)
    ); 
    raffle.performUpKeep("");
}
modifier raffleEntered() {
    vm.prank(PLAYER);
   raffle.enterRaffle{value: entranceFee}();
      vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        _;
}
    //what if we need to get data from emitted events in our tests?
    function  testPerformUpKeepUpdatesRaffleStateAndEmitsRequedstId() public raffleEntered {
        //Act
        vm.recordLogs();
        raffle.performUpKeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1]. topics[1];

        //Assert
        Raffle.RaffleState raffleState = raffle.getRaffleState();
        assert(uint256 (requestId) > 0);
        assert(uint256(raffleState) == 1);
    }
   /*//////////////////////////////////////////////////////////////
                           FULFILRANDOMWORDS
//////////////////////////////////////////////////////////////*/
 modifier skipFork() {
    if(block.chainid != LOCAL_CHAIN_ID){
        return;
    }
    _;
 }
 
 function testFulfillRandomWordsCanOnlyBeCalledAfterPerformUpKeep(uint256  randomRequestId) public raffleEntered skipFork {
    //Arrange /Act/Assert
    vm.expectRevert(VRFCoordinatorV2_5Mock.InvalidRequest.selector);
    VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords
    ( randomRequestId, address(raffle));
    
 }
  function testFulfillRandomWordsPickWinnerResetAndSendMoney() public raffleEntered skipFork {
    //Arrange
    uint256 additionalEntrants =3; //4 total
    uint256 startingIndex = 1;
    address expectedWinner = address(1);

    for(uint256 i=startingIndex; i< startingIndex + additionalEntrants; i++){
        address newPlayer = address(uint160(i));
        hoax(newPlayer, 1 ether);                                                //Adding 3 more players to the existing players
        raffle.enterRaffle{value: entranceFee}();
    }
    uint256 startingTimeStamp = raffle.getLastTimeStamp();

    //Act
     vm.recordLogs();
        raffle.performUpKeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1]. topics[1];
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(uint256(requestId), address(raffle));


        //Assert
        address recentWinner = raffle.getRecentWinner();
        Raffle.RaffleState raffleState = raffle.getRaffleState();
        uint256 winnerBalalnce = recentWinner.balance;
        uint256 endingTimeStamp = raffle.getLastTimeStamp();
        uint256 prize = entranceFee * (additionalEntrants + 1);
     
     assert(recentWinner == expectedWinner);
     assert(uint256(raffleState) == 0);
     assert (endingTimeStamp > startingTimeStamp);
  }
 
}   
