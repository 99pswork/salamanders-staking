const fs = require('fs');
const truffleContract = require('@truffle/contract');
const { expect } = require("chai");
const { ethers } = require("hardhat");

const CONFIG = require("../credentials");
const provider = new Web3.providers.HttpProvider("http://127.0.0.1:8545");

describe("Staking Test Cases", () => {

    before(async () => {
    
    const NFT = await ethers.getContractFactory("BeesNFT");
    nft = await NFT.deploy("Honey Pot", "HONEY", "150000000000000000", "200000000000000000", 1, 5, 10, 20);
    await nft.deployed();

    const TOKEN = await ethers.getContractFactory("SalamanderToken");
    token = await TOKEN.deploy("Salamander", "Sal", 20000);

    const STAKING = await ethers.getContractFactory("RewardSalamander");
    reward = await STAKING.deploy();

    accounts = await ethers.getSigners();

    })

    it("should be able to deploy a pool through smart chef factory", async () => {
        console.log("NFT ADDRESS: ", nft.address);
        expect(await nft.owner()).to.equal(accounts[0].address);
        
        console.log("TOKEN ADDRESS: ", token.address);
        console.log("Total Supply: ",await token.totalSupply());
        
        console.log("Staking Address: ", reward.address);
        expect(await reward.owner()).to.equal(accounts[0].address);

        await nft.togglePauseState();
        await nft.togglePublicSale();

        await nft.addWhiteListAddress([accounts[1].address, accounts[2].address, accounts[3].address, accounts[4].address]);

        await nft.connect(accounts[1]).publicSaleMint(4, {value: ethers.utils.parseEther("0.8")});
        await nft.connect(accounts[5]).publicSaleMint(4, {value: ethers.utils.parseEther("0.8")});
        await nft.connect(accounts[2]).publicSaleMint(2, {value: ethers.utils.parseEther("0.4")});
        await nft.connect(accounts[6]).publicSaleMint(2, {value: ethers.utils.parseEther("0.4")});

        //await reward.initialize(reward.address, nft.address, 78)
    })

})