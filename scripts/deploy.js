const fs = require('fs');
const truffleContract = require('@truffle/contract');
const CONFIG = require("../credentials.js");

const ownerAddress = "0x7E85585e3e3f4A1ce734f14bf0C0C951Cd887880"

contract("stake Deployment", () => {
    let smartChefFactory;
    let smartChef;
    let x;
    let y;
    let z;
    let tx;

    const smartChefABI = (JSON.parse(fs.readFileSync('./artifacts/contracts/SmartChefInitializable2.sol/SmartChefInitializable.json', 'utf8'))).abi;

    const provider = new ethers.providers.JsonRpcProvider(`https://rpc.testnet.fantom.network/`)
    // const provider = new ethers.providers.JsonRpcProvider(`https://data-seed-prebsc-1-s1.binance.org:8545/`)

    const signer = new ethers.Wallet(CONFIG.wallet.PKEY);
    const account = signer.connect(provider);

    // const imfAddress = "0x2cc70ff666530fca0d0f7a1dc6e0cb1a15ebf796"


    before(async () => {
        const blockNum = await provider.getBlockNumber()

        // accounts = await web3.eth.getAccounts()

        const X = await ethers.getContractFactory("X")
        x = await X.deploy()

        const Y = await ethers.getContractFactory("Y")
        y = await Y.deploy()

        const Z = await ethers.getContractFactory("Z")
        z = await Z.deploy()

        console.log(blockNum)

        // const SMARTCHEF = await ethers.getContractFactory("SmartChefFactory");
        // smartChefFactory = await SMARTCHEF.deploy();
        const SMARTCHEF = await ethers.getContractFactory("contracts/SmartChefInitializable2.sol:SmartChefInitializable");
        smartChef = await SMARTCHEF.deploy();

        console.log({
            // smartChefFactory: smartChefFactory.address,
            smartChef: smartChef.address,
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

    // it("should be able to deploy a pool through smart chef factory", async () => {
    //     const blockNum = await provider.getBlockNumber()

    //     tx = await smartChefFactory.deployPool(x.address, y.address, "10000000000000000000", blockNum, blockNum + 1000000, 0, account.address)
    //     await tx.wait()
    //     smartChefAddress = await smartChefFactory.deployedPools(0);

    //     // smartChef = truffleContract({ abi: smartChefABI });
    //     // smartChef.setProvider(provider);
    //     // smartChef = await smartChef.at(smartChefAddress)
    
    //     smartChef = new ethers.Contract(
    //         smartChefAddress,
    //         smartChefABI,
    //         account
    //     );
    //     console.log({
    //         smartChef: smartChef.address
    //     })

    // })

    it ("should initialize smartchef", async () => {
        const blockNum = await provider.getBlockNumber()

        tx = await smartChef.initialize(x.address, y.address, "10000000000000000000", blockNum, blockNum + 1000000, 0, account.address)
        await tx.wait()
        console.log({
            smartChef: smartChef.address
        })
    })

    it ("should transfer reward token, then stake lp token and claim reward", async () => {
        console.log({
            smartChef: smartChef.address,
        })
        let tx = await y.transfer(smartChef.address, "10000000000000000000000000")
        await tx.wait()
        tx = await x.approve(smartChef.address, "100000000000000000000000000000")
        await tx.wait()
        tx = await smartChef.deposit("5000000000000000000");
        await tx.wait()
        tx = await smartChef.withdraw("2000000000000000000");
        await tx.wait()
    })

    it ("should transfer ownership, and transfer x tokens", async () => {
        tx = await smartChef.transferOwnership(ownerAddress)
        await tx.wait()
        // tx = await smartChefFactory.transferOwnership(ownerAddress)
        tx = await x.transfer(ownerAddress, "100000000000000000000000")
        await tx.wait()
    })
})