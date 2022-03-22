// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {

  ExampleExternalContract public exampleExternalContract;
  mapping(address => uint) public balances;
  uint256 public constant threshold = 1 ether;
  uint256 public deadline;
  bool openForWithdraw;
  bool isExecuted;

  event Stake(address, uint);

  constructor(address exampleExternalContractAddress) public {
      exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
      deadline = block.timestamp + 72 hours;
  }
  modifier notCompleted() {
    bool completed = exampleExternalContract.completed();
    require(!completed, "staking process already completed");
    _;
  }
  // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
  //  ( make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )
  function stake() public payable {
    require(block.timestamp < deadline, "deadline reached");
    require(msg.value > 0, "Insufficient value");
    balances[msg.sender] += msg.value;
    emit Stake(msg.sender, msg.value);
  }


  // After some `deadline` allow anyone to call an `execute()` function
  //  It should either call `exampleExternalContract.complete{value: address(this).balance}()` to send all the value
  function execute() external notCompleted {
    require(!isExecuted, "Already executed");
    require(block.timestamp > deadline, "deadline not reached");
    if(address(this).balance >= threshold) {
      (bool sent,) = address(exampleExternalContract).call{value: address(this).balance}(abi.encodeWithSignature("complete()"));
      require(sent, "exampleExternalContract.complete failed");
    } else {
      openForWithdraw = true;
    }
    isExecuted = !isExecuted;
  }


  // if the `threshold` was not met, allow everyone to call a `withdraw()` function


  // Add a `withdraw(address payable)` function lets users withdraw their balance
  function withdraw(address payable _addr) external notCompleted {
    require(openForWithdraw, "can't withdraw");
    require(balances[_addr] > 0, "Insufficient fund");
    uint amount = balances[_addr];
    balances[_addr] = 0;
    (bool sent,) = _addr.call{value: amount}("");
    require(sent, "Failed to send user balance back to the user");
  }


  // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
  function timeLeft() public view returns(uint _timeLeft) {
    if(block.timestamp >= deadline) {
      _timeLeft = 0;
    } else {
      _timeLeft = deadline - block.timestamp;
    }
  }

  // Add the `receive()` special function that receives eth and calls stake()
  receive() external payable {
    stake();
  }

}
