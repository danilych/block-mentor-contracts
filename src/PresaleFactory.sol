// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import { Ownable } from "@openzeppelin-contracts/access/Ownable.sol";
import { Presale } from "./Presale.sol";
import { Errors } from "./libraries/Errors.sol";

/// @title Presale Factory Contract
/// @notice Factory contract for deploying Presale contracts
contract PresaleFactory is Ownable {
    /// @notice Array of all presale contracts created by this factory
    address[] public allPresales;

    /// @notice Mapping to track if an address is a presale created by this factory
    mapping(address => bool) public isPresale;

    event PresaleCreated(
        address indexed presaleAddress,
        address indexed token,
        uint256 price,
        uint256 limit,
        uint256 start,
        uint256 end
    );

    /// @param _initialOwner The initial owner of the factory
    constructor(address _initialOwner) Ownable(_initialOwner) {}

    /// @notice Get the total number of presales created by this factory
    /// @return The number of presales created
    function presaleCount() external view returns (uint256) {
        return allPresales.length;
    }

    /// @notice Create a new presale contract
    /// @param _token Address of the ERC20 token to sell
    /// @param _price Price of one token in wei
    /// @param _limit Amount of tokens allocated for the presale
    /// @param _start Start timestamp (unix)
    /// @param _end End timestamp (unix)
    /// @return presaleAddress The address of the newly created presale contract
    function createPresale(
        address _token,
        uint256 _price,
        uint256 _limit,
        uint256 _start,
        uint256 _end
    ) external onlyOwner returns (address presaleAddress) {
        Presale presale = new Presale(
            _token,
            _price,
            _limit,
            _start,
            _end
        );
        
        // Transfer ownership of the new presale to the factory owner
        presale.transferOwnership(owner());
        
        // Store the presale address
        address newPresale = address(presale);
        allPresales.push(newPresale);
        isPresale[newPresale] = true;
        
        emit PresaleCreated(newPresale, _token, _price, _limit, _start, _end);
        
        return newPresale;
    }

    /// @notice Get all presale addresses created by this factory
    /// @return Array of all presale addresses
    function getAllPresales() external view returns (address[] memory) {
        return allPresales;
    }

    /// @notice Get paginated list of presales
    /// @param page Page number (1-based)
    /// @param pageSize Number of items per page
    /// @return Array of presale addresses for the requested page
    function getPresalesPaginated(uint256 page, uint256 pageSize) external view returns (address[] memory) {
        if (page == 0 || pageSize == 0) revert Errors.InvalidPagination();
        
        uint256 startIndex = (page - 1) * pageSize;
        if (startIndex >= allPresales.length) {
            return new address[](0);
        }
        
        uint256 endIndex = startIndex + pageSize;
        if (endIndex > allPresales.length) {
            endIndex = allPresales.length;
        }
        
        address[] memory result = new address[](endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; i++) {
            result[i - startIndex] = allPresales[i];
        }
        
        return result;
    }
}
