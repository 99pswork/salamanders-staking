// File: contracts/SmartChefInitializable.sol

pragma solidity >= 0.8.1;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC721 {
    // List functions to invoke.
    function ownerOf(uint256 tokenId) external view returns (address);
}

contract RewardSalamander is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC721 public nftAddress;

    // The address of the smart chef factory
    address public SMART_CHEF_FACTORY;

    // Whether it is initialized
    bool public isInitialized;

    // The block number when CAKE mining ends.
    uint256 public bonusEndBlock;

    // The block number when CAKE mining starts.
    uint256 public startBlock;

    // The block number of the last pool update
    uint256 public lastRewardBlock;         

    // CAKE tokens created per block.
    uint256 public rewardPerBlock;      // 78 with 10^5 precision

    // The precision factor
    uint256 public PRECISION_FACTOR;

    // Token Decimals
    uint256 public tokenDecimals;

    // The Salamander Token
    IERC20 public rewardToken;

    // Info of each user that stakes tokens (stakedToken)
    mapping(uint256 => uint256) public tokenLastReward;

    event Deposit(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);
    event NewStartAndEndBlocks(uint256 startBlock, uint256 endBlock);
    event NewRewardPerBlock(uint256 rewardPerBlock);
    event NewPoolLimit(uint256 poolLimitPerUser);
    event RewardsStop(uint256 blockNumber);
    event Withdraw(address indexed user, uint256 amount);

    constructor() ReentrancyGuard() {
        SMART_CHEF_FACTORY = msg.sender;
    }

    /*
     * @notice Initialize the contract
     * @param _stakedToken: staked token address
     * @param _rewardToken: reward token address
     * @param _rewardPerBlock: reward per block (in rewardToken)
     * @param _startBlock: start block
     * @param _bonusEndBlock: end block
     * @param _poolLimitPerUser: pool limit per user in stakedToken (if any, else 0)
     * @param _admin: admin address with ownership
     */
    function initialize(
        IERC20 _rewardToken,
        IERC721 _nftAddress,
        uint256 _rewardPerBlock,
        uint256 _startBlock,
        uint256 _bonusEndBlock,
        uint256 _tokenDecimal,
        uint256 _precision_factor,
        address _admin
    ) external {
        require(!isInitialized, "Already initialized");
        require(msg.sender == SMART_CHEF_FACTORY, "Not factory");

        // Make this contract initialized
        isInitialized = true;
        rewardToken = _rewardToken;
        nftAddress = _nftAddress;

        rewardPerBlock = _rewardPerBlock;
        startBlock = _startBlock;
        bonusEndBlock = _bonusEndBlock;

        // Set the lastRewardBlock as the startBlock
        lastRewardBlock = startBlock;

        tokenDecimals = _tokenDecimal;
        PRECISION_FACTOR = _precision_factor;
        // Transfer ownership to the admin address who becomes owner of the contract
        transferOwnership(_admin);
    }

    /* Calculate Rewards */
    /// MAP to NFT not Address
    function calculateReward(uint256 _tokenId) view internal returns (uint256) {
        uint256 countBlock;
        if(tokenLastReward[_tokenId]!=0){
            countBlock = block.number - tokenLastReward[_tokenId];
        }
        else{
            countBlock = block.number - startBlock;
        }
        return countBlock*rewardPerBlock*(10**tokenDecimals)/(10**PRECISION_FACTOR);
    }

    // Check for endblock < block.number

     /*
     * @notice Withdraw staked tokens and collect reward tokens
     * @param _amount: amount to withdraw (in rewardToken)
     */
    function claimRewards(uint256 _tokenId) external nonReentrant {

        require(msg.sender == nftAddress.ownerOf(_tokenId), "You are not owner of token");
        require(block.number < bonusEndBlock, "Rewards Have Been Stopped");
        
        uint256 tokenReward = calculateReward(_tokenId);
        uint256 tokenBal = rewardToken.balanceOf(address(this));
        
        require(tokenReward <= tokenBal, "Not enough Tokens Available");
        tokenLastReward[_tokenId] = block.number;
        rewardToken.safeTransfer(address(msg.sender), tokenReward);
        emit Withdraw(msg.sender, tokenReward);
    }

    // Function Owner Withdraw

    function safeRewardClaim(uint256 _tokenId) external nonReentrant {

        require(msg.sender == nftAddress.ownerOf(_tokenId), "You are not owner of token");
        require(block.number < bonusEndBlock, "Rewards Have Been Stopped");
        
        uint256 tokenReward = calculateReward(_tokenId);
        tokenLastReward[_tokenId] = block.number;
        safeTokenTransfer(msg.sender, tokenReward);
    }

    function safeTokenTransfer(address _to, uint256 _amount) internal {
        uint256 tokenBal = rewardToken.balanceOf(address(this));
        if (_amount > tokenBal) {
            rewardToken.safeTransfer(_to, tokenBal);
        } else {
            rewardToken.safeTransfer(_to, _amount);
        }
    }

    /*
     * @notice Stop rewards
     * @dev Only callable by owner. Needs to be for emergency.
     */
    function emergencyRewardWithdraw(uint256 _amount) external onlyOwner {
        rewardToken.safeTransfer(address(msg.sender), _amount);
    }

    /*
     * @notice Stop rewards
     * @dev Only callable by owner
     */
    function stopReward() external onlyOwner {
        bonusEndBlock = block.number;
    }

    /*
     * @notice Update reward per block
     * @dev Only callable by owner.
     * @param _rewardPerBlock: the reward per block
     */
    function updateRewardPerBlock(uint256 _rewardPerBlock) external onlyOwner {
        require(block.number < startBlock, "Pool has started");
        rewardPerBlock = _rewardPerBlock;
        emit NewRewardPerBlock(_rewardPerBlock);
    }

    /**
     * @notice It allows the admin to update start and end blocks
     * @dev This function is only callable by owner.
     * @param _startBlock: the new start block
     * @param _bonusEndBlock: the new end block
     */
    function updateStartAndEndBlocks(uint256 _startBlock, uint256 _bonusEndBlock) external onlyOwner {
        require(block.number < startBlock, "Pool has started");
        require(_startBlock < _bonusEndBlock, "New startBlock must be lower than new endBlock");
        require(block.number < _startBlock, "New startBlock must be higher than current block");

        startBlock = _startBlock;
        bonusEndBlock = _bonusEndBlock;

        // Set the lastRewardBlock as the startBlock
        lastRewardBlock = startBlock;

        emit NewStartAndEndBlocks(_startBlock, _bonusEndBlock);
    }

    function updateEndBlock(uint256 _bonusEndBlock) external onlyOwner {
        require(block.number < _bonusEndBlock, "End Block cannot be less than current Block");
        bonusEndBlock = _bonusEndBlock;
    }


    function balanceOfRewards() view external returns(uint256) {
        return rewardToken.balanceOf(address(this));
    }
}