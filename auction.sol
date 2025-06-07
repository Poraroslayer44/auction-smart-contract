// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract Auction {
    address public owner;
    uint256 public auctionEndTime;
    bool public ended;

    address public highestBidder;
    uint256 public highestBid;

    mapping(address => uint256) public userHighestBids;
    mapping(address => uint256) public withdrawnAmounts;

    event NewBid(address indexed bidder, uint256 amount);
    event AuctionEnded(address winner, uint256 amount);

    constructor(uint256 durationMinutes) {
        owner = msg.sender;
        auctionEndTime = block.timestamp + (durationMinutes * 1 minutes);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this");
        _;
    }

    modifier auctionActive() {
        require(block.timestamp < auctionEndTime, "Auction has ended");
        _;
    }

    modifier auctionEnded() {
        require(block.timestamp >= auctionEndTime || ended, "Auction is still active");
        _;
    }

    function placeBid() external payable auctionActive {
        uint256 minBid = highestBid + (highestBid * 5 / 100);
        require(msg.value >= minBid, "Bid must be at least 5% higher than current");

        uint256 totalBid = userHighestBids[msg.sender] + msg.value;
        require(totalBid >= minBid, "Combined bid too low");

        userHighestBids[msg.sender] = totalBid;
        highestBid = totalBid;
        highestBidder = msg.sender;

        // Extend auction time by 10 minutes if bid comes in last 10 minutes
        if (auctionEndTime - block.timestamp <= 10 minutes) {
            auctionEndTime += 10 minutes;
        }

        emit NewBid(msg.sender, totalBid);
    }

    function endAuction() external onlyOwner {
        require(!ended, "Auction already ended");
        require(block.timestamp >= auctionEndTime, "Auction still active");
        ended = true;
        emit AuctionEnded(highestBidder, highestBid);
    }

    function withdrawOverbid() external {
        require(msg.sender != highestBidder, "Winner cannot withdraw overbids");

        uint256 available = userHighestBids[msg.sender] - withdrawnAmounts[msg.sender];
        require(available > 0, "No overbid to withdraw");

        withdrawnAmounts[msg.sender] += available;
        payable(msg.sender).transfer(available);
    }

    function refundAllExceptWinner(address[] calldata bidders) external onlyOwner auctionEnded {
        for (uint256 i = 0; i < bidders.length; i++) {
            address bidder = bidders[i];

            if (bidder != highestBidder) {
                uint256 refund = userHighestBids[bidder] - withdrawnAmounts[bidder];
                if (refund > 0) {
                    withdrawnAmounts[bidder] += refund;

                    uint256 commission = (refund * 2) / 100;
                    uint256 finalRefund = refund - commission;

                    payable(bidder).transfer(finalRefund);
                }
            }
        }
    }

    function getWinner() external view auctionEnded returns (address, uint256) {
        return (highestBidder, highestBid);
    }

    function getUserBid(address user) external view returns (uint256) {
        return userHighestBids[user];
    }
}

