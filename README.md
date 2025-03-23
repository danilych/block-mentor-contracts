# Block Mentor Contracts

Block Mentor is a suite of smart contracts for token creation and vesting management, built using Foundry. This project enables users to create standard ERC20 tokens, omnichain tokens with bridging capabilities, and flexible vesting schedules for token distribution.

## Overview

The Block Mentor Contracts include:

1. **Token Creation:**
   - Standard ERC20 tokens through `TokenFactory`
   - Omnichain tokens with cross-chain functionality through `OmnichainToken`

2. **Vesting System:**
   - Token vesting schedules with equal distribution per period
   - Factory pattern for easy deployment and configuration
   - Claiming functionality for beneficiaries

## Smart Contracts

### Token System

- **Token**: Standard ERC20 token with mint and burn capabilities.
- **OmnichainToken**: Cross-chain compatible token that can be bridged between supported networks using ViaLabs messaging system.
- **TokenFactory**: Factory contract that allows users to create standard or omnichain tokens.

### Vesting System

- **Vesting**: Manages vesting schedules for token distribution with equal amounts per period.
- **VestingFactory**: Creates vesting contracts and optionally sets up vesting schedules.

## Getting Started

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- [Node.js](https://nodejs.org) (optional for NPM dependencies)

### Installation

1. Clone the repository:
   ```shell
   git clone <repository-url>
   cd block-mentor-contracts
   ```

2. Install dependencies:
   ```shell
   forge soldeer install
   ```

3. Set up environment variables:
   ```shell
   cp .env.example .env
   # Add your API keys and private keys
   ```

## Development

### Build

```shell
forge build
```

### Test

```shell
forge test
```

### Format

```shell
forge fmt
```

### Gas Snapshots

```shell
forge snapshot
```

### Deploy

#### Deploy VestingFactory
```shell
forge script script/DeployVestingFactory.s.sol --rpc-url <your_rpc_url> --private-key <your_private_key> --broadcast
```

#### Deploy OmnichainToken
```shell
forge script script/DeployOmnichainToken.s.sol --rpc-url <your_rpc_url> --private-key <your_private_key> --broadcast
```

## Usage

### Creating Tokens

1. **Standard ERC20 Token**
   
   Use the `createToken` function in the `TokenFactory` contract:
   
   ```solidity
   // Parameters: name, ticker, initial supply
   address tokenAddress = tokenFactory.createToken("My Token", "MTK", 1000000 * 10**18);
   ```

2. **Omnichain Token**
   
   Use the `createOmnichainToken` function in the `TokenFactory` contract:
   
   ```solidity
   // Parameters: name, ticker, initial supply
   address omnichainTokenAddress = tokenFactory.createOmnichainToken("My Omnichain Token", "OCT", 1000000 * 10**18);
   ```
   
   For bridging tokens:
   ```solidity
   // Parameters: destination chain ID, recipient address, amount
   omnichainToken.bridge(10, recipientAddress, 1000 * 10**18);
   ```

### Managing Vesting

1. **Create a Vesting Contract**
   
   ```solidity
   // Parameters: token address
   address vestingAddress = vestingFactory.createVestingContract(tokenAddress);
   ```

2. **Create a Vesting Schedule**
   
   ```solidity
   // Parameters: beneficiary, start timestamp, period duration, total periods, total amount
   Vesting(vestingAddress).createVestingSchedule(
       beneficiaryAddress,
       block.timestamp,
       30 days,
       12,
       12000 * 10**18
   );
   ```

3. **Claim Vested Tokens**
   
   As a beneficiary:
   ```solidity
   Vesting(vestingAddress).claimTokens();
   ```

4. **Check Claimable Amount**
   
   ```solidity
   uint256 claimable = Vesting(vestingAddress).calculateClaimableAmount(beneficiaryAddress);
   ```

## Recent Updates

The vesting contract has been updated to simplify the vesting process by removing the unlockAmounts array. Instead, the contract now calculates an equal amount to distribute per period based on the total amount and number of periods.

Key changes:
1. Removed unlockAmounts array from VestingSchedule struct
2. Added amountPerPeriod calculation in createVestingSchedule
3. Added AmountNotDivisible error for cases where total amount is not evenly divisible
4. Updated VestingFactory to reflect changes in Vesting contract
5. Modified all tests to work with the new implementation

This simplification makes the contract more gas efficient, easier to understand, and enforces equal distribution of tokens across all vesting periods.

## Deployments

### OmnichainToken

- **Network**: Arbitrum Sepolia
- **Address**: `0x24260d046005f74aCa953e3aA00028DEFadABdC7`

- **Network**: Base Sepolia
- **Address**: `0xbd39A7fAbBc9D92df06d93B226C62EA820CCf325`

## License

This project is licensed under the UNLICENSED License - see the [LICENSE](LICENSE) file for details.
