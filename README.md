# SightCoin (SGC) Smart Contract

## Overview
SightCoin (SGC) is a secure, production-ready ERC20 token implementation built on Ethereum, featuring advanced security controls, governance capabilities, and flexible minting mechanisms. The contract is built using OpenZeppelin's battle-tested contracts with additional security features and operational controls.

## Features

### Core Functionality
- ERC20 compliant token
- Fixed maximum supply (1 billion tokens)
- Controlled minting with time bounds
- Burning capability
- Pausable transfers
- Flash mint support
- Governance voting capabilities

### Security Features
- Role-based access control
- Transaction rate limiting
- Daily minting limits
- Blacklist functionality
- Emergency pause mechanism
- Reentrancy protection
- Emergency token recovery
- Comprehensive event logging

### Roles
- `DEFAULT_ADMIN_ROLE`: Super admin role for managing other roles
- `MINTER_ROLE`: Authorized to mint new tokens
- `PAUSER_ROLE`: Can pause/unpause token transfers
- `GOVERNANCE_ROLE`: Controls administrative functions

## Technical Specifications

### Token Details
- Name: 4sightCoin
- Symbol: SGC
- Decimals: 18
- Maximum Supply: 1,000,000,000 tokens
- Mint Limit Per Transaction: 1,000,000 tokens
- Transfer Limit Per Transaction: 100,000 tokens

### Dependencies
- OpenZeppelin Contracts v4.x
- Solidity ^0.8.17

## Installation

1. Install dependencies:
```bash
npm install @openzeppelin/contracts
```

2. Import the contract:
```solidity
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// ... other imports
```

## Deployment

### Prerequisites
- Node.js v14+ and npm
- Hardhat or Truffle
- Ethereum wallet with sufficient ETH for deployment

### Deployment Steps

1. Configure deployment parameters:
```javascript
const MINTING_START_TIME = /* Unix timestamp */;
const MINTING_END_TIME = /* Unix timestamp */;
const INITIAL_GOVERNOR = /* Address */;
```

2. Deploy the contract:
```javascript
const SightCoin = await ethers.getContractFactory("SightCoin");
const token = await SightCoin.deploy(
    MINTING_START_TIME,
    MINTING_END_TIME,
    INITIAL_GOVERNOR
);
await token.deployed();
```

## Usage

### Minting Tokens
```javascript
// Only addresses with MINTER_ROLE
await token.mint(recipientAddress, amount);
```

### Transfer Tokens
```javascript
await token.transfer(recipientAddress, amount);
```

### Administrative Functions

#### Pause/Unpause
```javascript
// Only PAUSER_ROLE
await token.pause();
await token.unpause();
```

#### Update Blacklist
```javascript
// Only GOVERNANCE_ROLE
await token.updateBlacklist(address, isBlacklisted);
```

#### Update Daily Mint Limit
```javascript
// Only GOVERNANCE_ROLE
await token.updateDailyMintLimit(minterAddress, newLimit);
```

## Security Considerations

### Role Management
- Always use multi-sig wallets for administrative roles
- Regularly audit role assignments
- Follow principle of least privilege

### Operational Security
- Monitor large transactions
- Set up alerts for security events
- Regular security reviews
- Maintain emergency response procedures

### Best Practices
- Test thoroughly before deployment
- Conduct professional security audit
- Monitor contract events
- Maintain upgrade plans

## Events

The contract emits the following events:
- `MintingPeriodSet`
- `EmergencyWithdraw`
- `BlacklistUpdated`
- `DailyMintLimitUpdated`
- `SecurityPause`

## Testing

```bash
# Install dependencies
npm install

# Run tests
npx hardhat test

# Run coverage
npx hardhat coverage
```

## License
This project is licensed under the MIT License - see the LICENSE file for details.

## Contributing
1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a new Pull Request

## Changelog
- v1.0.0 (2025-01-15)
  - Initial release
  - Comprehensive security features
  - Role-based access control
  - Transaction limits
  - Blacklist functionality
