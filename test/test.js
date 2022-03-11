const fs = require('fs');
const truffleContract = require('@truffle/contract');

const CONFIG = require("../credentials");

contract("Staking Test Cases", () => {
    let masterChef;
    let smartChefFactory;
    let smartChef;
    let supply;
    let x;
    let y;
    let z;
    let accounts;

    const smartChefABI = (JSON.parse(fs.readFileSync('./artifacts/contracts/SmartChefInitializable2.sol/SmartChefInitializable.json', 'utf8'))).abi;
    const provider = new Web3.providers.HttpProvider("http://127.0.0.1:8545");
    // const provider = new Web3.providers.HttpProvider(CONFIG.polygonTestnet.url);


    before(async () => {
        accounts = await web3.eth.getAccounts()

        // const X = await ethers.getContractFactory("X")
        // x = await X.deploy()

        // const Y = await ethers.getContractFactory("Y")
        // y = await Y.deploy()

        // const Z = await ethers.getContractFactory("Z")
        // z = await Z.deploy()

        // const MASTERCHEF = await ethers.getContractFactory("MasterChef");
        // masterChef = await MASTERCHEF.deploy(x.address, accounts[0], 1000, 1000, 100000);

        // const SMARTCHEF = await ethers.getContractFactory("SmartChefFactory");
        // smartChefFactory = await SMARTCHEF.deploy();

        // const SUPPLY = await ethers.getContractFactory("Supply");
        // supply = await SUPPLY.deploy(masterChef.address, x.address);

        const X = artifacts.require("X");
        const Y = artifacts.require("Y");
        const Z = artifacts.require("Z");
        const SMARTCHEF = artifacts.require("SmartChefFactory");

        x = await X.new()
        X.setAsDeployed(x)
        x = await X.deployed()

        y = await Y.new()
        Y.setAsDeployed(y)
        y = await Y.deployed()

        z = await Z.new()
        Z.setAsDeployed(z)
        z = await Z.deployed()

        smartChefFactory = await SMARTCHEF.new()
        SMARTCHEF.setAsDeployed(smartChefFactory)
        smartChefFactory = await SMARTCHEF.deployed()

        console.log({
            smartChefFactory: smartChefFactory.address,
            x: x.address,
            y: y.address,
            z: z.address,
        })

    })

    after(async () => {
        console.log('\u0007');
        console.log('\u0007');
        console.log('\u0007');
        console.log('\u0007');
    })

    const advanceBlock = () => new Promise((resolve, reject) => {
        web3.currentProvider.send({
            jsonrpc: '2.0',
            method: 'evm_mine',
            id: new Date().getTime()
        }, async (err, result) => {
            if (err) { return reject(err) }
            // const newBlockHash =await web3.eth.getBlock('latest').hash
            return resolve()
        })
    })
    
    const advanceBlocks = async (num) => {
        let resp = []
        for (let i = 0; i < num; i += 1) {
            resp.push(advanceBlock())
        }
        await Promise.all(resp)
    }

    it("should be able to deploy a pool through smart chef factory", async () => {
        await smartChefFactory.deployPool(x.address, y.address, 1000, 100, 100000, 0, accounts[0])
        smartChefAddress = await smartChefFactory.deployedPools(0);
        console.log({smartChefAddress})
        
        smartChef = truffleContract({ abi: smartChefABI });
        smartChef.setProvider(provider);
        smartChef = await smartChef.at(smartChefAddress)
    
        // smartChef = new ethers.Contract(
        //     smartChef,
        //     smartChefABI,
        //     accounts[2]
        // );

    })

    it ("should transfer reward token, then stake lp token and claim reward", async () => {
        console.log({
            smartChef: smartChef.address,
        })
        stakedTokenAddress = await smartChef.stakedToken();
        rewardTokenAddress = await smartChef.rewardToken();
        rewardPerBlock = await smartChef.rewardPerBlock();
        startBlock = await smartChef.startBlock();
        bonusEndBlock = await smartChef.bonusEndBlock();
        owner = await smartChef.owner();
        poolLimitPerUser = await smartChef.poolLimitPerUser();

        assert.equal(stakedTokenAddress, x.address)
        assert.equal(rewardTokenAddress, y.address)
        assert.equal(rewardPerBlock, 1000)
        assert.equal(startBlock, 100)
        assert.equal(bonusEndBlock, 100000)
        assert.equal(owner, accounts[0])
        assert.equal(poolLimitPerUser, 0)

        await y.transfer(smartChef.address, "1000000000")
        await x.transfer(accounts[2], 1);
        await x.approve(smartChef.address, "100000000000000000000000000000", { from: accounts[2] })
        await advanceBlocks(101)

        const balX0 = await x.balanceOf(accounts[2])
        const balY0 = await y.balanceOf(accounts[2])
        await smartChef.deposit(1, { from: accounts[2] });
        const balX1 = await x.balanceOf(accounts[2])
        const balY1 = await y.balanceOf(accounts[2])
        await advanceBlocks(10)
        await smartChef.deposit(0, { from: accounts[2] });
        const balX2 = await x.balanceOf(accounts[2])
        const balY2 = await y.balanceOf(accounts[2])

        console.log({
            balX0: balX0.toString(),
            balX1: balX1.toString(),
            balX2: balX2.toString(),
            balY0: balY0.toString(),
            balY1: balY1.toString(),
            balY2: balY2.toString(),
        })

        assert.equal(balY1.sub(balY0).toString(), 0)
        assert.equal(balX2.sub(balX1).toString(), 0)
        assert.equal(balX0.sub(balX1).toString(), 1)
        assert.equal(balY2.sub(balY1).toString(), 11 * 1000)
    })

    it ("should stake tokens by more users", async () => {
        await x.transfer(accounts[1], 2);
        await x.approve(smartChef.address, "100000000000000000000000000000", { from: accounts[1] });

        const bal0Acc1 = await y.balanceOf(accounts[1])
        const bal0Acc2 = await y.balanceOf(accounts[2])
        const balAcc1BefX = await x.balanceOf(accounts[1])

        await smartChef.deposit(2, { from: accounts[1] });
        await smartChef.deposit(0, { from: accounts[2] });

        const bal1Acc1 = await y.balanceOf(accounts[1])
        const bal1Acc2 = await y.balanceOf(accounts[2])
        const balAcc1AftX = await x.balanceOf(accounts[1])

        await advanceBlocks(10)
        await smartChef.deposit(0, { from: accounts[1] });
        await smartChef.withdraw(0, { from: accounts[2] });

        const bal2Acc1 = await y.balanceOf(accounts[1])
        const bal2Acc2 = await y.balanceOf(accounts[2])

        console.log({
            bal0Acc1: bal0Acc1.toString(),
            bal0Acc2: bal0Acc2.toString(),
            bal1Acc1: bal1Acc1.toString(),
            bal1Acc2: bal1Acc2.toString(),
            bal2Acc1: bal2Acc1.toString(),
            bal2Acc2: bal2Acc2.toString(),
            tokensEarnedAcc1: bal2Acc1.sub(bal1Acc1).toString(),
            tokensEarnedAcc2: bal2Acc2.sub(bal1Acc2).toString()
        })

        assert.equal(balAcc1BefX.sub(balAcc1AftX).toString(), 2)
        assert.equal(bal1Acc1.sub(bal0Acc1).toString(), 0)
        assert.equal(bal1Acc2.sub(bal0Acc2).toString(), parseInt(3 * 1000 + (1 / 3 * 1000)))
        assert.equal(bal2Acc1.sub(bal1Acc1).toString(), parseInt(12 * (2/3 * 1000)) - 1)
        assert.equal(bal2Acc2.sub(bal1Acc2).toString(), parseInt(12 * (1/3 * 1000)))
    })
})