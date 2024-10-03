// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract EnergyTradingPlatform is Ownable {
    struct User {
        address userAddress;
        uint256 producedEnergy; // in kWh
        uint256 consumedEnergy; // in kWh
        uint256 balance; // in Wei
        bool isProducer;
    }

    mapping(address => User) public users;

    event UserRegistered(address indexed user, bool isProducer);
    event EnergyProduced(address indexed producer, uint256 amount);
    event EnergyConsumed(address indexed consumer, uint256 amount);
    event EnergyTraded(address indexed from, address indexed to, uint256 amount, uint256 totalCost);

    constructor() Ownable(msg.sender) {
        
    }

    // Register as a producer or consumer
    function registerUser(bool _isProducer) public {
        require(users[msg.sender].userAddress == address(0), "User already registered.");
        users[msg.sender] = User({
            userAddress: msg.sender,
            producedEnergy: 0,
            consumedEnergy: 0,
            balance: 0,
            isProducer: _isProducer
        });
        emit UserRegistered(msg.sender, _isProducer);
    }

    // Function for producers to report their energy production
    function produceEnergy(uint256 amount) public {
        require(users[msg.sender].isProducer, "Only producers can report energy production.");
        users[msg.sender].producedEnergy += amount;
        emit EnergyProduced(msg.sender, amount);
    }

    // Function for consumers to report their energy consumption
    function consumeEnergy(uint256 amount) public {
        require(!users[msg.sender].isProducer, "Producers cannot report consumption.");
        users[msg.sender].consumedEnergy += amount;
        emit EnergyConsumed(msg.sender, amount);
    }

    // Trade energy between users
    function tradeEnergy(address to, uint256 amount) public {
        require(users[msg.sender].isProducer, "Only producers can trade energy.");
        require(users[to].isProducer == false, "Cannot trade to a producer.");
        require(users[msg.sender].producedEnergy >= amount, "Insufficient energy produced.");
        
        // Calculate cost (for simplicity, we assume 1 kWh = 0.01 Ether)
        uint256 cost = amount * 0.01 ether;

        // Update balances and energy records
        users[msg.sender].producedEnergy -= amount;
        users[to].consumedEnergy += amount;
        users[to].balance += cost;
        users[msg.sender].balance -= cost; // Deduct cost from producer's balance

        emit EnergyTraded(msg.sender, to, amount, cost);
    }

    // Function for users to withdraw their balance
    function withdrawBalance() public {
        uint256 amount = users[msg.sender].balance;
        require(amount > 0, "No balance to withdraw.");
        users[msg.sender].balance = 0; // Reset balance before transfer
        payable(msg.sender).transfer(amount);
    }

    // Function to view user details
    function getUserDetails(address user) public view returns (User memory) {
        return users[user];
    }

    // Fallback function to accept Ether
    receive() external payable {}
}
