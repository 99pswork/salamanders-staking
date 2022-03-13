import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

// Point to remember that airdrop is counted as mint.
// Owner honey pot withdraw multiple times (Is there need to restrict which is 50%)

// NFT Count 8888
// White list - 888,  @0.15 ETH, Max 1 Per Pax
// Public Sale - 8000, @0.2 ETH, Max 5 Per Pax
// Every 25%, 3ETH to charity wallet
// NFT Reaveal Post one week 
// 40% of minting profits divided between 80 rare NFT holders 
// 5% of minting profits divided between 8 ultra-rare holders.

contract BeesNFT is ERC721Enumerable, Ownable, ReentrancyGuard {

    using SafeMath for uint256;
    using Strings for uint256;

    bool public preSaleActive = false;
    bool public publicSaleActive = false;

    bool public paused = true;
    bool public revealed = false;
    bool public withdrawHoneyAllowed = false;

    uint256 public maxSupply; // 8888
    uint256 public preSalePrice; // 0.15ETH
    uint256 public publicSalePrice; // 0.2ETH
    uint256 public preSaleTotal; // 888 
    uint256 public currentPreSale;
    uint256 public storeRevealBalance; 

    uint public maxPreSale; // 1
    uint public maxPublicSale; // 5

    uint private startLegend = 1; // 1
    uint private endLegend = 8; // 8
    uint private startRare = 9; // 9
    uint private endRare = 888; // 88

    string private _baseURIextended;
    
    string public NETWORK_PROVENANCE = "";
    string public notRevealedUri;

    uint256 public donationAmount; // 3 ETH
    address public charityBeesAddress; // Set Donation Address

    uint256 public amountDonatedSoFar;
    uint256 public raffleReward = 1000000000000000000; // 1 ETH

    mapping(address => bool) public isWhiteListed; 
    mapping(uint => bool) public amountClaimed;

    constructor(string memory name, string memory symbol, uint256 _preSalePrice, uint256 _publicSalePrice, uint256 _maxPreSale, uint256 _maxPublicSale, uint256 _preSaleTotal, uint256 _maxSupply) ERC721(name, symbol) ReentrancyGuard() {
        preSalePrice = _preSalePrice;
        publicSalePrice = _publicSalePrice;
        maxPreSale = _maxPreSale;
        maxPublicSale = _maxPublicSale;
        preSaleTotal = _preSaleTotal;
        maxSupply = _maxSupply;
    }

    function preSaleMint(uint256 _amount) external payable nonReentrant{
        require(preSaleActive, "NFT-Bees Pre Sale is not Active");
        require(isWhiteListed[msg.sender], "NFT-Bees Message Sender is not whitelisted");
        require(currentPreSale <= preSaleTotal, "NFT-Bees Pre Sale Max Limit Reached");
        require(balanceOf(msg.sender).add(_amount) <= maxPreSale, "NFT-Bees Max Pre Sale Mint Reached");
        currentPreSale += _amount;
        mint(_amount, true);
    }

    function publicSaleMint(uint256 _amount) external payable nonReentrant {
        require(publicSaleActive, "NFT-Bees Public Sale is not Active");
        require(balanceOf(msg.sender).add(_amount) <= maxPublicSale, "NFT-Bees Max Public Sale Mint Reached");
        mint(_amount, false);
    }

    function mint(uint256 amount,bool state) internal {
        require(!paused, "NFT-Bees Minting is Paused");
        require(totalSupply().add(amount) <= maxSupply, "NFT-Bees Max Minting Reached");
        if(state){
            require(preSalePrice*amount <= msg.value, "NFT-Bees ETH Value Sent for Pre Sale is not enough");
        }
        else{
            require(publicSalePrice*amount <= msg.value, "NFT-Bees ETH Value Sent for Public Sale is not enough");
        }
        uint mintIndex = totalSupply();
        for(uint ind = 1;ind<=amount;ind++){
            _safeMint(msg.sender, mintIndex.add(ind));
        }
    }

    function _baseURI() internal view virtual override returns (string memory){
        return _baseURIextended;
    }

    function setBaseURI(string calldata baseURI_) external onlyOwner {
        _baseURIextended = baseURI_;
    }

    function addWhiteListAddress(address[] memory _address) external onlyOwner {
        for (uint i=0; i<_address.length; i++){
            isWhiteListed[_address[i]] = true;
        }
    }

    function togglePauseState() external onlyOwner {
        paused = !paused;
    }

    function togglePreSale() external onlyOwner {
        preSaleActive = !preSaleActive;
    }

    function togglePublicSale() external onlyOwner {
        publicSaleActive = !publicSaleActive;
    }

    function setPreSalePrice(uint256 _preSalePrice) external onlyOwner {
        preSalePrice = _preSalePrice;
    }

    function setPublicSalePrice(uint256 _publicSalePrice) external onlyOwner {
        publicSalePrice = _publicSalePrice;
    }

    function setHoneyPotBalance() external onlyOwner {
        storeRevealBalance = address(this).balance;
    }

    function setRaffleReward(uint256 _reward) onlyOwner external {
        raffleReward = _reward;
    }

    function airDrop(address[] memory _address) external onlyOwner {
        uint256 mintIndex = totalSupply();
        require(totalSupply().add(_address.length) <= maxSupply, "NFT-Bees Maximum Supply Reached");
        for(uint i=1; i <= _address.length; i++){
            _safeMint(_address[i-1], mintIndex.add(i));
        }
    }

    // Automatically Honey Pot Withdraw allowed after reveal
    function reveal() external onlyOwner {
        revealed = true;
        withdrawHoneyAllowed = true;
        storeRevealBalance = address(this).balance;
    }

    function toggleWithdrawHoneyPot() external onlyOwner {
        withdrawHoneyAllowed = !withdrawHoneyAllowed;
    }

    // Need to take care of Honey Pot Withdraw (40%, 5%, 5%)
    // Should owner has only access to 50% of funds? 
    function withdrawTotal() external onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
        storeRevealBalance = 0;
    }

    function ownerHoneyWithdraw() external onlyOwner {
        require(withdrawHoneyAllowed, "NFT-Bees: Withdraw Honey Pot Not Allowed Yet!");
        require(storeRevealBalance!=0, "NFT-Bees: Honey Pot Over");
        payable(msg.sender).transfer(storeRevealBalance/2);
    }


    function isLegendary(uint _tokenId) public view returns (bool) {
        require(_exists(_tokenId), "NFT-Bees URI For Token Non-existent");
        if(_tokenId <= endLegend && _tokenId >= startLegend)
        {
            return true;
        }
        return false;
    }

    function isRare(uint _tokenId) public view returns (bool) {
        require(_exists(_tokenId), "NFT-Bees URI For Token Non-existent");
        if(_tokenId <= endRare && _tokenId >= startRare)
        {
            return true;
        }
        return false;
    }

    // 45 For Rare & 5% for Legendary
    function withdrawHoneyPot(uint _tokenId) external nonReentrant {
        require(withdrawHoneyAllowed, "NFT-Bees: Withdraw Honey Pot Not Allowed Yet!");
        require(msg.sender == ownerOf(_tokenId), "NFT-Bees: You are not the owner of this token");
        require(amountClaimed[_tokenId] == false, "NFT-Bees: Honey Pot Already Claimed");
        require(storeRevealBalance!=0, "NFT-Bees: Honey Pot Over");
        require(isLegendary(_tokenId) || isRare(_tokenId), "NFT-Bees: Your NFT not eligible for Honey Pot");
        // 5% Among Legendary NFT Holders
        if(isLegendary(_tokenId)){
            payable(msg.sender).transfer(storeRevealBalance*5/(100*8));
        }
        // 45% Among Rare NFT Holders
        else if(isRare(_tokenId)){
            payable(msg.sender).transfer(storeRevealBalance*45/(100*880));
        }
        amountClaimed[_tokenId] = true;
    }

    // 45 For Rare & 5% for Legendary
    function checkHoneyPot(uint _tokenId, address _address) public view returns (uint256) {
        require(_address == ownerOf(_tokenId), "NFT-Bees: You are not the owner of this token");
        require(amountClaimed[_tokenId] == false, "NFT-Bees: Honey Pot Already Claimed");
        require(isLegendary(_tokenId) || isRare(_tokenId), "NFT-Bees: Your NFT not eligible for Honey Pot");
        require(storeRevealBalance!=0, "NFT-Bees: Honey Not Yet Started");
        // 5% Among Legendary NFT Holders
        if(isLegendary(_tokenId)){
            return storeRevealBalance*5/(100*8);
        }
        // 45% Among Rare NFT Holders
        else if(isRare(_tokenId)){
            return storeRevealBalance*45/(100*880);
        }
        return 0;
    }


    function setProvenanceHash(string memory provenanceHash) external onlyOwner {
        NETWORK_PROVENANCE = provenanceHash;
    }

    function setNotRevealedURI(string memory _notRevealedUri) external onlyOwner {
        notRevealedUri = _notRevealedUri;
    }

    function setCharityAddress(address _address) external onlyOwner {
        charityBeesAddress = _address;
    }

    function setDonationAmount(uint256 _donationAmount) external onlyOwner {
        donationAmount = _donationAmount;
    }

    // Need to make sure that the 25th% transaction is not affected because of donate.
    function donateETH() external onlyOwner {
        require(charityBeesAddress != address(0), "NFT-Bees Address cannot be zero");
        require(donationAmount != 0, "NFT-Bees Donation Amount cannot be zero");
        payable(charityBeesAddress).transfer(donationAmount);
        amountDonatedSoFar += donationAmount;
    }

    // Do you want this to be onlyOwner function ?
    function raffleNumberGenerator(uint _limit) public view returns(uint256) {
    uint256 seed = uint256(keccak256(abi.encodePacked(
        block.timestamp + block.difficulty + ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (block.timestamp)) +
        block.gaslimit + ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (block.timestamp)) + block.number
    )));

    return 1 + (seed - ((seed / _limit) * _limit));
    
    }

    function sendRaffleReward(address _address) external onlyOwner nonReentrant {
        require(_address != address(0), "NFT-Bees Address cannot be zero");
        payable(_address).transfer(raffleReward);
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "NFT-Bees URI For Token Non-existent");
        if(!revealed){
            return notRevealedUri;
        }
        string memory currentBaseURI = _baseURI(); 
        return bytes(currentBaseURI).length > 0 ? 
        string(abi.encodePacked(currentBaseURI,_tokenId.toString(),".json")) : "";
    }
}