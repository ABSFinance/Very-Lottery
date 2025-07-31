const { ethers } = require("hardhat");

async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);

    // 1. ContractRegistry 배포
    console.log("Deploying ContractRegistry...");
    const ContractRegistry = await ethers.getContractFactory("ContractRegistry");
    const contractRegistry = await ContractRegistry.deploy();
    await contractRegistry.waitForDeployment();
    console.log("ContractRegistry deployed to:", await contractRegistry.getAddress());

    // 2. 기본 컨트랙트들 배포
    console.log("Deploying basic contracts...");
    
    const SimpleOwnable = await ethers.getContractFactory("SimpleOwnable");
    const simpleOwnable = await SimpleOwnable.deploy();
    await simpleOwnable.waitForDeployment();
    console.log("SimpleOwnable deployed to:", await simpleOwnable.getAddress());

    const TreasuryManager = await ethers.getContractFactory("TreasuryManager");
    const treasuryManager = await TreasuryManager.deploy();
    await treasuryManager.waitForDeployment();
    console.log("TreasuryManager deployed to:", await treasuryManager.getAddress());

    const CryptolottoReferral = await ethers.getContractFactory("CryptolottoReferral");
    const cryptolottoReferral = await CryptolottoReferral.deploy();
    await cryptolottoReferral.waitForDeployment();
    console.log("CryptolottoReferral deployed to:", await cryptolottoReferral.getAddress());

    const StatsAggregator = await ethers.getContractFactory("StatsAggregator");
    const statsAggregator = await StatsAggregator.deploy();
    await statsAggregator.waitForDeployment();
    console.log("StatsAggregator deployed to:", await statsAggregator.getAddress());

    const FundsDistributor = await ethers.getContractFactory("FundsDistributor");
    const fundsDistributor = await FundsDistributor.deploy();
    await fundsDistributor.waitForDeployment();
    console.log("FundsDistributor deployed to:", await fundsDistributor.getAddress());
    
    // 3. ContractRegistry에 컨트랙트들 등록
    console.log("Registering contracts in ContractRegistry...");
    
    const contractNames = [
        "TreasuryManager",
        "CryptolottoReferral", 
        "StatsAggregator",
        "FundsDistributor",
        "SimpleOwnable"
    ];
    
    const contractAddresses = [
        await treasuryManager.getAddress(),
        await cryptolottoReferral.getAddress(),
        await statsAggregator.getAddress(),
        await fundsDistributor.getAddress(),
        await simpleOwnable.getAddress()
    ];

    await contractRegistry.registerBatchContracts(contractNames, contractAddresses);
    console.log("Contracts registered in ContractRegistry");

    // 4. 게임 구현체들 배포
    console.log("Deploying game implementations...");
    
    const Cryptolotto1Day = await ethers.getContractFactory("Cryptolotto1Day");
    const cryptolotto1DayImpl = await Cryptolotto1Day.deploy();
    await cryptolotto1DayImpl.waitForDeployment();
    console.log("Cryptolotto1Day implementation deployed to:", await cryptolotto1DayImpl.getAddress());

    const Cryptolotto7Days = await ethers.getContractFactory("Cryptolotto7Days");
    const cryptolotto7DaysImpl = await Cryptolotto7Days.deploy();
    await cryptolotto7DaysImpl.waitForDeployment();
    console.log("Cryptolotto7Days implementation deployed to:", await cryptolotto7DaysImpl.getAddress());
    
    // 5. GameFactory 배포
    console.log("Deploying GameFactory...");
    const GameFactory = await ethers.getContractFactory("GameFactory");
    const gameFactory = await GameFactory.deploy();
    await gameFactory.waitForDeployment();
    console.log("GameFactory deployed to:", await gameFactory.getAddress());

    // 6. GameFactory 초기화
    console.log("Initializing GameFactory...");
    await gameFactory.initialize(
        deployer.address,
        await simpleOwnable.getAddress(),
        await statsAggregator.getAddress(),
        await cryptolottoReferral.getAddress(),
        await fundsDistributor.getAddress(),
        await cryptolotto1DayImpl.getAddress(),
        await cryptolotto7DaysImpl.getAddress(),
        await contractRegistry.getAddress()
    );
    console.log("GameFactory initialized");

    // 7. ContractRegistry에 게임 구현체들 등록
    console.log("Registering game implementations in ContractRegistry...");
    await contractRegistry.registerBatchContracts(
        ["OneDayImplementation", "SevenDaysImplementation"],
        [await cryptolotto1DayImpl.getAddress(), await cryptolotto7DaysImpl.getAddress()]
    );
    
    // 8. 배포 결과 출력
    console.log("\n=== Deployment Summary ===");
    console.log("ContractRegistry:", await contractRegistry.getAddress());
    console.log("TreasuryManager:", await treasuryManager.getAddress());
    console.log("CryptolottoReferral:", await cryptolottoReferral.getAddress());
    console.log("StatsAggregator:", await statsAggregator.getAddress());
    console.log("FundsDistributor:", await fundsDistributor.getAddress());
    console.log("SimpleOwnable:", await simpleOwnable.getAddress());
    console.log("Cryptolotto1Day Implementation:", await cryptolotto1DayImpl.getAddress());
    console.log("Cryptolotto7Days Implementation:", await cryptolotto7DaysImpl.getAddress());
    console.log("GameFactory:", await gameFactory.getAddress());
    
    // 9. ContractRegistry 검증
    console.log("\n=== ContractRegistry Verification ===");
    const treasuryAddress = await contractRegistry.getContract("TreasuryManager");
    console.log("TreasuryManager from registry:", treasuryAddress);
    console.log("Expected address:", await treasuryManager.getAddress());
    console.log("Match:", treasuryAddress === await treasuryManager.getAddress());

    const registeredCount = await contractRegistry.getContractCount();
    console.log("Total registered contracts:", registeredCount.toString());

    console.log("\nDeployment completed successfully!");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    }); 