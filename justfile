default:
  @just --choose

static-analysis:
  slither . --config-file slither.config.json

deploy-omnichain-token:
  forge clean && forge script script/DeployOmnichainToken.s.sol:DeployOmnichainToken --rpc-url base-sepolia --sender 0x25Fbb765998134400f6e2D4191e89C37dB40fa98 --account block-mentor-deployer --verify --broadcast

configure-omnichain-token:
  forge script script/tasks/ConfigureOmnichainClient.s.sol:ConfigureOmnichainClient --rpc-url base-sepolia --sender 0x25Fbb765998134400f6e2D4191e89C37dB40fa98 --account block-mentor-deployer --verify --broadcast
  
bridge-tokens:
  forge script script/tasks/BridgeTokens.s.sol:BridgeTokens --rpc-url arbitrum-sepolia --sender 0x25Fbb765998134400f6e2D4191e89C37dB40fa98 --account block-mentor-deployer --broadcast

deploy-vesting-factory:
  forge clean && forge script script/DeployVestingFactory.s.sol:DeployVestingFactory --rpc-url arbitrum-sepolia --sender 0x25Fbb765998134400f6e2D4191e89C37dB40fa98 --account block-mentor-deployer --verify --broadcast
