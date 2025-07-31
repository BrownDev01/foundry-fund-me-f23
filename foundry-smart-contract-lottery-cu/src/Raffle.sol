// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {VRFConsumerBaseV2Plus} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

/**
 * @title  A sample Raffle contract
 * @author  Fappy(BrownDev)
 * @notice  This contract is for creating a sample raffle
 * @dev Implements Chainlink VRFv2.5
 */

contract Raffle is VRFConsumerBaseV2Plus {
    /* Errors*/
    error Raffle__SendMoreToEnterRaffle();
    error Raffle__Transferfailed();
    error Raffle__RaffleNotOpen();
    error Raffle__UpKeepNotNeeded(uint256 balance,uint256 playersLength, uint256 raffleState);
   /**Type Declaration */
  enum RaffleState{
    OPEN, //0
    CALCULATING //1
  }
   /**state variable */
    uint16 private constant REQUEST_CONFIRMATION = 3;
    uint32 private constant NUM_WORDS = 1;
    uint256 private immutable i_entranceFee;
    // @dev The duration of the lottery in seconds
    uint256 private i_interval;
    bytes32 private immutable i_keyHash;
    uint256 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    address payable[] private s_players;
    uint256 private s_lastTimeStamp;
    address private s_recentWinner;
    RaffleState private s_raffleState; // dtart as  open

    /*Events*/
    event RaffleEntered(address indexed player);
    event WinnerPicked(address indexed winner);
    event RequestedRaffleWinner(uint256 indexed requestId);

    //what data structure should we use? How to keep track of all players?
    constructor(
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 gaslane,
        uint256 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2Plus(vrfCoordinator) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        i_keyHash = gaslane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
         s_lastTimeStamp = block.timestamp;
        s_raffleState = RaffleState.OPEN;
    }

    function enterRaffle() external payable {
       
        //reuire(msg.value >= i_entranceFee, "Not enough ETH sent");
        //reuire(msg.value >= i_entranceFee, SendMoreToEnterRaffle());
        if (msg.value < i_entranceFee) {
            revert Raffle__SendMoreToEnterRaffle();
        }
        s_players.push(payable(msg.sender));
        // 1. Makes migration easier
        // 2. makes frony end "indexing" easier
        emit RaffleEntered(msg.sender);
        if (s_raffleState != RaffleState.OPEN){
            revert Raffle__RaffleNotOpen();
        }
    }
    //1. Get a random number
    //2. Use random number to pick a player


  //when should the winner be picked?
  /**
   * @dev This is the function that the lottery will call to see
   * if the lottery is ready for the winner to be picked
   * The following should betrue in order for upKeepNeeded to be true:
   * 1. The time intetrval has passed between raffle runs
   * 2.The Lottery is open
   * 3. Implicitly. your Subscription  has LINK
   * @param - ignored
   * @return upKeepNeeded - true if it's  time to restart the lottery
   * @return 
   */
    function checkUpKeep(bytes memory /* checkData*/)
     public 
     view 
     returns(bool upKeepNeeded, bytes memory /* performData*/){
       bool timeHasPassed = ((block.timestamp - s_lastTimeStamp) >= i_interval); 
        bool isOpen = s_raffleState == RaffleState.OPEN;
        bool hasBalance = address(this).balance > 0;
        bool hasPlayers = s_players.length > 0;
        upKeepNeeded = timeHasPassed && isOpen && hasBalance && hasPlayers;
        return (upKeepNeeded, "");
     }

    //3. Be automatically called

    function performUpKeep(bytes calldata /*performData*/) external {
        //check to see if enough time as passed

        (bool upKeepNeeded,) = checkUpKeep("");
        if (!upKeepNeeded) {
            revert Raffle__UpKeepNotNeeded(address(this).balance, s_players.length, uint256(s_raffleState));
        }
        
        s_raffleState = RaffleState.CALCULATING;
        VRFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient.RandomWordsRequest({
            keyHash: i_keyHash,
            subId: i_subscriptionId,
            requestConfirmations: REQUEST_CONFIRMATION,
            callbackGasLimit: i_callbackGasLimit,
            numWords: NUM_WORDS,
            extraArgs: VRFV2PlusClient._argsToBytes(
                // Set nativePayment to true to pay for VRF requests with Sepolia ETH instead of LINK
                VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
            )
        });
        // Get  random number 2.5
        // 1. Request RNG
        // 2. Get RNG
     uint256 requestId = s_vrfCoordinator.requestRandomWords(request);

     emit RequestedRaffleWinner(requestId);   //it's redundant bcos the chainlink vrfcoordinator already emits the requestId
    }
  //CEIs Checks, Effects, Interactions pattern
    function fulfillRandomWords(uint256 /*requestId*/, uint256[] calldata randomWords) internal override {
       //Checks
       //conditional



       // s_player = 10
       // rng = 12
       // 12 % 10 =2 <-
       //68747332647485848388589 % 10 = 9

       // Effect (Internal Contract state)
      uint256 indexOfOwner = randomWords[0] % s_players.length;
      address payable recentWinner = s_players[indexOfOwner];
      s_recentWinner = recentWinner;
     s_raffleState = RaffleState.OPEN;
      s_players = new address payable[](0);
    s_lastTimeStamp = block.timestamp;
    emit WinnerPicked(s_recentWinner);

    // Interactions (External Contract Interactions)
      (bool success,) = recentWinner.call{value: address(this).balance}("");
          if (!success){
            revert Raffle__Transferfailed();
          }
          
          
    }
    /**
     * Getter Function
     */

    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }
    function getRaffleState() external view returns(RaffleState){
            return s_raffleState;
    }

    function getPlayer(uint256 indexOfPlayer) external view returns(address)
    {
        return s_players[indexOfPlayer];
    }

    function getLastTimeStamp() external view  returns(uint256){
         return s_lastTimeStamp;
    }
    function getRecentWinner() external view returns(address){
        return s_recentWinner;
    }
}

