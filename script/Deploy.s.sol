// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../contracts/modules/lottery/Cryptolotto1Day.sol";
import "../contracts/modules/lottery/Cryptolotto7Days.sol";
import "../contracts/modules/lottery/CryptolottoAd.sol";
import "../contracts/modules/lottery/AdToken.sol";
import "../contracts/modules/treasury/TreasuryManager.sol";
import "../contracts/modules/treasury/CryptolottoReferral.sol";
import "../contracts/modules/treasury/FundsDistributor.sol";
import "../contracts/modules/analytics/StatsAggregator.sol";
import "../contracts/modules/lottery/SimpleOwnable.sol";
import "../contracts/shared/utils/ContractRegistry.sol";
import "../lib/openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract DeployScript is Script {
    // 배포된 컨트랙트 주소들을 저장할 변수들
    SimpleOwnable public ownable;
    StatsAggregator public stats;
    FundsDistributor public fundsDistributor;
    CryptolottoReferral public referral;
    AdToken public adToken;
    ContractRegistry public registry;
    TreasuryManager public treasuryManager;
    Cryptolotto1Day public lottery1Day;
    Cryptolotto7Days public lottery7Days;
    CryptolottoAd public lotteryAd;

    function setUp() public {}

    function run() public {
        // 환경변수에서 private key 가져오기
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);

        // Deploy core contracts
        _deployCoreContracts();

        // Deploy lottery contracts
        _deployLotteryContracts();

        // Setup and configure
        _setupContracts();

        // Register contracts
        _registerContracts();

        vm.stopBroadcast();

        // Log deployment summary
        _logDeploymentSummary();
    }

    function _deployCoreContracts() internal {
        // Get deployer address
        address deployer = vm.addr(vm.envUint("PRIVATE_KEY"));

        // Deploy core contracts
        ownable = new SimpleOwnable();
        stats = new StatsAggregator();
        fundsDistributor = new FundsDistributor();
        referral = new CryptolottoReferral();
        adToken = new AdToken(1000000 * 10 ** 18); // 1M tokens initial supply
        registry = new ContractRegistry(deployer); // Set deployer as owner
        treasuryManager = new TreasuryManager();

        // Create treasuries
        treasuryManager.createTreasury(
            "unique_test_lottery_1day",
            1000000000000000000000
        );
        treasuryManager.createTreasury(
            "unique_test_lottery_7days",
            1000000000000000000000
        );
        treasuryManager.createTreasury(
            "unique_test_lottery_ad",
            1000000000000000000000
        );
    }

    function _deployLotteryContracts() internal {
        // Deploy implementations
        Cryptolotto1Day implementation1Day = new Cryptolotto1Day();
        Cryptolotto7Days implementation7Days = new Cryptolotto7Days();
        CryptolottoAd implementationAd = new CryptolottoAd();

        // Get deployer address
        address deployer = vm.addr(vm.envUint("PRIVATE_KEY"));

        // Prepare initialization data with proper parameters
        bytes memory initData1Day = abi.encodeWithSelector(
            Cryptolotto1Day.initialize.selector,
            deployer, // owner
            address(fundsDistributor), // distributor
            address(stats), // statsA
            address(referral), // referralSystem
            address(treasuryManager), // _treasuryManager
            "unique_test_lottery_1day" // _treasuryName
        );

        bytes memory initData7Days = abi.encodeWithSelector(
            Cryptolotto7Days.initialize.selector,
            deployer, // owner
            address(fundsDistributor), // distributor
            address(stats), // statsA
            address(referral), // referralSystem
            address(treasuryManager), // _treasuryManager
            "unique_test_lottery_7days" // _treasuryName
        );

        bytes memory initDataAd = abi.encodeWithSelector(
            CryptolottoAd.initialize.selector,
            deployer, // owner
            address(fundsDistributor), // distributor
            address(stats), // statsA
            address(referral), // referralSystem
            address(treasuryManager), // _treasuryManager
            "unique_test_lottery_ad" // _treasuryName
        );

        // Deploy proxy contracts
        ERC1967Proxy proxy1Day = new ERC1967Proxy(
            address(implementation1Day),
            initData1Day
        );

        ERC1967Proxy proxy7Days = new ERC1967Proxy(
            address(implementation7Days),
            initData7Days
        );

        ERC1967Proxy proxyAd = new ERC1967Proxy(
            address(implementationAd),
            initDataAd
        );

        // Cast proxies to their respective types
        lottery1Day = Cryptolotto1Day(payable(address(proxy1Day)));
        lottery7Days = Cryptolotto7Days(payable(address(proxy7Days)));
        lotteryAd = CryptolottoAd(payable(address(proxyAd)));
    }

    function _setupContracts() internal {
        // Set registry for lottery contracts (needed after initialization)
        lottery1Day.setRegistry(address(registry));
        lottery7Days.setRegistry(address(registry));
        lotteryAd.setRegistry(address(registry));

        // Set treasury names for lottery contracts (registry is already set in initialize)
        lottery1Day.setTreasuryName("unique_test_lottery_1day");
        lottery7Days.setTreasuryName("unique_test_lottery_7days");
        lotteryAd.setTreasuryName("unique_test_lottery_ad");

        // Set AdToken for Ad Lottery
        lotteryAd.setAdToken(address(adToken));

        // Set test mode for easier testing
        lottery1Day.setTestMode(true);
        lottery7Days.setTestMode(true);
        lotteryAd.setTestMode(true);
    }

    function _registerContracts() internal {
        // Register contracts in registry
        string[] memory names = new string[](8);
        address[] memory contracts = new address[](8);

        names[0] = "TreasuryManager";
        names[1] = "CryptolottoReferral";
        names[2] = "StatsAggregator";
        names[3] = "FundsDistributor";
        names[4] = "SimpleOwnable";
        names[5] = "AdToken";
        names[6] = "Cryptolotto1Day";
        names[7] = "Cryptolotto7Days";

        contracts[0] = address(treasuryManager);
        contracts[1] = address(referral);
        contracts[2] = address(stats);
        contracts[3] = address(fundsDistributor);
        contracts[4] = address(ownable);
        contracts[5] = address(adToken);
        contracts[6] = address(lottery1Day);
        contracts[7] = address(lotteryAd);

        registry.registerBatchContracts(names, contracts);
    }

    function _logDeploymentSummary() internal {
        address deployer = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

        // Log deployed addresses
        console.log("=== DEPLOYMENT SUMMARY ===");
        console.log("Deployer:", deployer);
        console.log("Ownable deployed at:", address(ownable));
        console.log("StatsAggregator deployed at:", address(stats));
        console.log("FundsDistributor deployed at:", address(fundsDistributor));
        console.log("CryptolottoReferral deployed at:", address(referral));
        console.log("AdToken deployed at:", address(adToken));
        console.log("ContractRegistry deployed at:", address(registry));
        console.log("TreasuryManager deployed at:", address(treasuryManager));
        console.log("Cryptolotto1Day deployed at:", address(lottery1Day));
        console.log("Cryptolotto7Days deployed at:", address(lottery7Days));
        console.log("CryptolottoAd deployed at:", address(lotteryAd));
        console.log("=== DEPLOYMENT COMPLETE ===");

        // Log addresses for manual copy
        console.log("=== CONTRACT ADDRESSES ===");
        console.log("DEPLOYER_ADDRESS=", deployer);
        console.log("CRYPTOLOTTO_1DAY=", address(lottery1Day));
        console.log("CRYPTOLOTTO_7DAYS=", address(lottery7Days));
        console.log("CRYPTOLOTTO_AD=", address(lotteryAd));
        console.log("TREASURY_MANAGER=", address(treasuryManager));
        console.log("CONTRACT_REGISTRY=", address(registry));
        console.log("STATS_AGGREGATOR=", address(stats));
        console.log("FUNDS_DISTRIBUTOR=", address(fundsDistributor));
        console.log("CRYPTOLOTTO_REFERRAL=", address(referral));
        console.log("AD_TOKEN=", address(adToken));
        console.log("OWNABLE=", address(ownable));
        console.log("=== END ADDRESSES ===");
    }
}
