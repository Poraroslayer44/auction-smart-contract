// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Auction {
    address public owner;
    address public highestBidder;
    uint public highestBid;
    uint public startTime;
    uint public endTime;
    uint public commissionPercent = 2;

    struct Bid {
        address bidder;
        uint amount;
    }

    mapping(address => uint[]) public userBids;
    mapping(address => uint) public refundable;
    Bid[] public bids;

    bool public ended = false;

    event NewBid(address indexed bidder, uint amount);
    event AuctionEnded(address winner, uint amount);

    modifier onlyWhileActive() {
        require(block.timestamp < endTime && !ended, "Auction has ended");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this");
        _;
    }

    constructor(uint _durationMinutes) {
        owner = msg.sender;
        startTime = block.timestamp;
        endTime = startTime + (_durationMinutes * 1 minutes);
    }

    function placeBid() external payable onlyWhileActive {
        require(msg.value > 0, "You must send ETH");
        require(msg.value >= (highestBid * 105) / 100, "Bid must be at least 5% higher than current highest");

        if (userBids[msg.sender].length > 0) {
            uint previousBid = userBids[msg.sender][userBids[msg.sender].length - 1];
            refundable[msg.sender] += previousBid;
        }

        userBids[msg.sender].push(msg.value);
        bids.push(Bid(msg.sender, msg.value));
        highestBid = msg.value;
        highestBidder = msg.sender;

        // Extend auction if bid placed within last 10 minutes
        if (block.timestamp + 10 minutes > endTime) {
            endTime = block.timestamp + 10 minutes;
        }

        emit NewBid(msg.sender, msg.value);
    }

    function getWinner() external view returns (address, uint) {
        require(ended, "Auction is still active");
        return (highestBidder, highestBid);
    }

    function getAllBids() external view returns (Bid[] memory) {
        return bids;
    }

    function endAuction() external onlyOwner {
        require(!ended, "Auction already ended");
        require(block.timestamp >= endTime, "Auction still in progress");

        ended = true;
        emit AuctionEnded(highestBidder, highestBid);
    }

    function withdrawOverbid() external {
        uint amount = refundable[msg.sender];
        require(amount > 0, "Nothing to withdraw");

        refundable[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }

    function refundAllExceptWinner() external onlyOwner {
        require(ended, "Auction must be ended first");

        for (uint i = 0; i < bids.length; i++) {
            address bidder = bids[i].bidder;
            uint amount = bids[i].amount;

            if (bidder != highestBidder) {
                uint refund = (amount * (100 - commissionPercent)) / 100;
                payable(bidder).transfer(refund);
            }
        }

        // Send commission to the owner
        payable(owner).transfer(address(this).balance);
    }
}
