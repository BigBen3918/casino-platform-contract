const fs = require("fs");
const colors = require("colors");
const { ethers, waffle } = require("hardhat");

const StakingPoolABI = require("../artifacts/contracts/staking.sol/StakingPool.json").abi;
const ERC20ABI =
    require("../artifacts/contracts/ERC20.sol/ERC20.json").abi;

const routerABI = require("../artifacts/contracts/router.sol/StakingRouter.json").abi;
const treasuryABI = require("../artifacts/contracts/router.sol/Treasury.json").abi;

async function main() {
    // get network
    var [owner] = await ethers.getSigners();

    const provider = waffle.provider;
    const { chainId } = await provider.getNetwork()

    console.log(chainId, owner.address);

    const AtariToken = await ethers.getContractFactory("ERC20");
    var atariToken = await AtariToken.deploy("ATARI", "ATRI", "0", "100000000000000");
    await atariToken.deployed();

    // var atariToken = {address : process.env.ATARIADDRESS};

    const Router = await ethers.getContractFactory("StakingRouter");
    var stakingRouter = await Router.deploy(owner.address, atariToken.address);
    await stakingRouter.deployed();

    var treasuryAddress = await stakingRouter.treasury();

    /*------------- contract objects --------------- */

    var treasury = { address: treasuryAddress, abi: treasuryABI };
    var router = {address: stakingRouter.address, abi: routerABI};
    var stakingPool = {abi: StakingPoolABI};

    var atari = {
        address: atariToken.address,
        abi: ERC20ABI
    } 

    const contracts = {
        atari,
        router,
        treasury,
        stakingPool
    }

    fs.writeFileSync(
    	`./build/${chainId}.json`,
    	JSON.stringify(contracts, undefined, 4)
    );
}

main()
    .then(() => {
        console.log("complete".green);
    })
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
