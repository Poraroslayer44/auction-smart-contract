# 🧾 Smart Contract - Auction (Trabajo Final Módulo 2)

This project implements a decentralized auction using Solidity, deployed on the Sepolia testnet.

## Contract Verified

🔗 Verified contract address on Sepolia:  
[https://sepolia.etherscan.io/address/YOUR_CONTRACT_ADDRESS](https://sepolia.etherscan.io/address/YOUR_CONTRACT_ADDRESS)

## Features

- Anyone can place ETH bids.
- Bids must be at least 5% higher than the current highest.
- Auction can extend 10 minutes if a bid is placed near the end.
- Only the owner can end the auction.
- Winner is the highest bidder.
- Non-winners can withdraw their deposits minus 2% commission.

## Functions

- `placeBid()`: Place a bid.
- `getWinner()`: Get the winner.
- `getAllBids()`: See all bids.
- `withdrawOverbid()`: Withdraw extra bids.
- `refundAllExceptWinner()`: Refund non-winners.
- `endAuction()`: End the auction.

## Events

- `NewBid`: Emitted on new bid.
- `AuctionEnded`: Emitted when auction ends.

## Security

- Uses `require` for validation.
- Uses modifiers for access control.
- Proper event usage.

## How to test

Use [Remix](https://remix.ethereum.org) with Metamask connected to Sepolia.
