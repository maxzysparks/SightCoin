// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20FlashMint.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract SightCoin is 
    ERC20, 
    ERC20Burnable, 
    ERC20Pausable, 
    ERC20Permit, 
    ERC20Votes,
    ERC20FlashMint,
    AccessControl, 
    ReentrancyGuard 
{
    using Address for address;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant GOVERNANCE_ROLE = keccak256("GOVERNANCE_ROLE");
    
    uint256 public constant MAX_SUPPLY = 1000000000 * 10**18; // 1 billion tokens
    uint256 public immutable mintingStartTime;
    uint256 public immutable mintingEndTime;
    
    uint256 public constant MINT_LIMIT_PER_TX = 1000000 * 10**18; // 1 million tokens
    uint256 public constant TRANSFER_LIMIT_PER_TX = 100000 * 10**18; // 100k tokens
    
    mapping(address => bool) public blacklisted;
    mapping(address => uint256) public lastMintTimestamp;
    mapping(address => uint256) public dailyMintLimit;
    
    constructor(
        uint256 _mintingStartTime,
        uint256 _mintingEndTime,
        address _initialGovernor
    ) ERC20("4sightCoin", "SGC") ERC20Permit("4sightCoin") {
        require(_mintingEndTime > _mintingStartTime, "SightCoin: End time must be after start time");
        require(_initialGovernor != address(0), "SightCoin: Invalid governor address");
        
        _grantRole(DEFAULT_ADMIN_ROLE, _initialGovernor);
        _grantRole(MINTER_ROLE, _initialGovernor);
        _grantRole(PAUSER_ROLE, _initialGovernor);
        _grantRole(GOVERNANCE_ROLE, _initialGovernor);
        
        mintingStartTime = _mintingStartTime;
        mintingEndTime = _mintingEndTime;
        
        emit MintingPeriodSet(_mintingStartTime, _mintingEndTime);
    }
    
    // Events
    event MintingPeriodSet(uint256 startTime, uint256 endTime);
    event EmergencyWithdraw(address indexed token, address indexed to, uint256 amount);
    event BlacklistUpdated(address indexed account, bool isBlacklisted);
    event DailyMintLimitUpdated(address indexed minter, uint256 limit);
    event SecurityPause(address indexed trigger, string reason);
    
    function mint(
        address to, 
        uint256 amount
    ) public nonReentrant onlyRole(MINTER_ROLE) whenNotPaused {
        require(block.timestamp >= mintingStartTime, "SightCoin: Minting not started");
        require(block.timestamp <= mintingEndTime, "SightCoin: Minting ended");
        require(to != address(0), "SightCoin: Cannot mint to zero address");
        require(!blacklisted[to], "SightCoin: Recipient is blacklisted");
        require(amount <= MINT_LIMIT_PER_TX, "SightCoin: Exceeds tx mint limit");
        require(totalSupply() + amount <= MAX_SUPPLY, "SightCoin: Would exceed max supply");
        
        // Daily mint limit check
        uint256 today = block.timestamp / 1 days;
        uint256 lastMintDay = lastMintTimestamp[msg.sender] / 1 days;
        if (today > lastMintDay) {
            dailyMintLimit[msg.sender] = 0;
        }
        require(dailyMintLimit[msg.sender] + amount <= MINT_LIMIT_PER_TX * 10, "SightCoin: Daily mint limit exceeded");
        
        dailyMintLimit[msg.sender] += amount;
        lastMintTimestamp[msg.sender] = block.timestamp;
        
        _mint(to, amount);
    }
    
    function transfer(
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        require(!blacklisted[msg.sender], "SightCoin: Sender is blacklisted");
        require(!blacklisted[to], "SightCoin: Recipient is blacklisted");
        require(amount <= TRANSFER_LIMIT_PER_TX, "SightCoin: Exceeds transfer limit");
        require(to != address(this), "SightCoin: Cannot transfer to token contract");
        
        return super.transfer(to, amount);
    }
    
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        require(!blacklisted[from], "SightCoin: Sender is blacklisted");
        require(!blacklisted[to], "SightCoin: Recipient is blacklisted");
        require(amount <= TRANSFER_LIMIT_PER_TX, "SightCoin: Exceeds transfer limit");
        require(to != address(this), "SightCoin: Cannot transfer to token contract");
        
        return super.transferFrom(from, to, amount);
    }
    
    function updateBlacklist(
        address account,
        bool isBlacklisted
    ) external onlyRole(GOVERNANCE_ROLE) {
        require(account != address(0), "SightCoin: Invalid address");
        blacklisted[account] = isBlacklisted;
        emit BlacklistUpdated(account, isBlacklisted);
    }
    
    function updateDailyMintLimit(
        address minter,
        uint256 limit
    ) external onlyRole(GOVERNANCE_ROLE) {
        require(minter != address(0), "SightCoin: Invalid address");
        require(hasRole(MINTER_ROLE, minter), "SightCoin: Address is not a minter");
        dailyMintLimit[minter] = limit;
        emit DailyMintLimitUpdated(minter, limit);
    }
    
    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
        emit SecurityPause(msg.sender, "Manual pause triggered");
    }
    
    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }
    
    function emergencyWithdraw(
        address token,
        address to,
        uint256 amount
    ) external nonReentrant onlyRole(GOVERNANCE_ROLE) {
        require(to != address(0), "SightCoin: Cannot withdraw to zero address");
        require(token != address(this), "SightCoin: Cannot withdraw native tokens");
        require(IERC20(token).balanceOf(address(this)) >= amount, "SightCoin: Insufficient balance");
        
        IERC20(token).transfer(to, amount);
        emit EmergencyWithdraw(token, to, amount);
    }
    
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20, ERC20Pausable) {
        super._beforeTokenTransfer(from, to, amount);
    }
    
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20, ERC20Votes) {
        super._afterTokenTransfer(from, to, amount);
    }
    
    function _mint(
        address to,
        uint256 amount
    ) internal virtual override(ERC20, ERC20Votes) {
        super._mint(to, amount);
    }
    
    function _burn(
        address account,
        uint256 amount
    ) internal virtual override(ERC20, ERC20Votes) {
        super._burn(account, amount);
    }
}