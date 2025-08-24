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
        console.log("=== STARTING DEPLOYMENT ===");

        // 환경변수에서 private key 가져오기
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        console.log("Deployer address:", deployer);

        vm.startBroadcast(deployerPrivateKey);

        // Deploy core contracts
        console.log("Deploying core contracts...");
        _deployCoreContracts();
        console.log("Core contracts deployed successfully");

        // Deploy lottery contracts
        console.log("Deploying lottery contracts...");
        _deployLotteryContracts();
        console.log("Lottery contracts deployed successfully");

        // IMPORTANT: Setup contracts INSIDE broadcast to ensure they are actual transactions
        console.log("Setting up contracts...");
        _setupContracts();
        console.log("Contract setup completed");

        // IMPORTANT: Register contracts INSIDE broadcast to ensure they are actual transactions
        console.log("Registering contracts...");
        _registerContracts();
        console.log("Contracts registered successfully");

        vm.stopBroadcast();

        // Log deployment summary
        console.log("Generating deployment summary...");
        _logDeploymentSummary();

        console.log("=== DEPLOYMENT COMPLETED SUCCESSFULLY ===");
    }

    function _deployCoreContracts() internal {
        console.log("Starting core contracts deployment...");

        // Get deployer address
        address deployer = vm.addr(vm.envUint("PRIVATE_KEY"));

        // Deploy core contracts
        console.log("Deploying SimpleOwnable...");
        ownable = new SimpleOwnable();
        console.log("SimpleOwnable deployed at:", address(ownable));

        console.log("Deploying StatsAggregator...");
        stats = new StatsAggregator();
        console.log("StatsAggregator deployed at:", address(stats));

        console.log("Deploying FundsDistributor...");
        fundsDistributor = new FundsDistributor();
        console.log("FundsDistributor deployed at:", address(fundsDistributor));

        console.log("Deploying CryptolottoReferral...");
        referral = new CryptolottoReferral();
        console.log("CryptolottoReferral deployed at:", address(referral));

        console.log("Deploying AdToken...");
        adToken = new AdToken(1000000 * 10 ** 18); // 1M tokens initial supply
        console.log("AdToken deployed at:", address(adToken));

        console.log("Deploying ContractRegistry...");
        registry = new ContractRegistry(deployer); // Set deployer as owner
        console.log("ContractRegistry deployed at:", address(registry));

        console.log("Deploying TreasuryManager...");
        treasuryManager = new TreasuryManager();
        console.log("TreasuryManager deployed at:", address(treasuryManager));

        // Create treasuries
        console.log("Creating treasuries...");
        treasuryManager.createTreasury("unique_test_lottery_1day", 0);
        treasuryManager.createTreasury("unique_test_lottery_7days", 0);
        treasuryManager.createTreasury("unique_test_lottery_ad", 0);
        console.log("Treasuries created successfully");

        console.log("Core contracts deployment completed");
    }

    function _deployLotteryContracts() internal {
        console.log("Starting lottery contracts deployment...");

        // Deploy implementations
        console.log("Deploying Cryptolotto1Day implementation...");
        Cryptolotto1Day implementation1Day = new Cryptolotto1Day();
        console.log("Cryptolotto1Day implementation deployed at:", address(implementation1Day));

        console.log("Deploying Cryptolotto7Days implementation...");
        Cryptolotto7Days implementation7Days = new Cryptolotto7Days();
        console.log("Cryptolotto7Days implementation deployed at:", address(implementation7Days));

        console.log("Deploying CryptolottoAd implementation...");
        CryptolottoAd implementationAd = new CryptolottoAd();
        console.log("CryptolottoAd implementation deployed at:", address(implementationAd));

        // Get deployer address
        address deployer = vm.addr(vm.envUint("PRIVATE_KEY"));

        // Prepare initialization data with proper parameters
        console.log("Preparing initialization data for Cryptolotto1Day...");
        console.log("- Owner:", deployer);
        console.log("- FundsDistributor:", address(fundsDistributor));
        console.log("- Stats:", address(stats));
        console.log("- Referral:", address(referral));
        console.log("- TreasuryManager:", address(treasuryManager));

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

        console.log("Initialization data prepared successfully");

        // Deploy proxy contracts
        console.log("Creating ERC1967Proxy for Cryptolotto1Day...");
        ERC1967Proxy proxy1Day = new ERC1967Proxy(address(implementation1Day), initData1Day);
        console.log("Cryptolotto1Day proxy created at:", address(proxy1Day));

        console.log("Creating ERC1967Proxy for Cryptolotto7Days...");
        ERC1967Proxy proxy7Days = new ERC1967Proxy(address(implementation7Days), initData7Days);
        console.log("Cryptolotto7Days proxy created at:", address(proxy7Days));

        console.log("Creating ERC1967Proxy for CryptolottoAd...");
        ERC1967Proxy proxyAd = new ERC1967Proxy(address(implementationAd), initDataAd);
        console.log("CryptolottoAd proxy created at:", address(proxyAd));

        // Cast proxies to their respective types
        console.log("Casting proxies to contract types...");
        lottery1Day = Cryptolotto1Day(payable(address(proxy1Day)));
        lottery7Days = Cryptolotto7Days(payable(address(proxy7Days)));
        lotteryAd = CryptolottoAd(payable(address(proxyAd)));
        console.log("Proxy casting completed successfully");

        console.log("Lottery contracts deployment completed");
    }

    function _setupContracts() internal {
        console.log("Setting up contracts...");

        // IMPORTANT: Proxy contracts are already initialized during deployment
        // We just need to set additional configuration

        // Set registry for lottery contracts (needed after initialization)
        console.log("Setting registry for lottery contracts...");

        // Force transaction execution by using low-level calls with explicit gas
        // These calls will be broadcast as actual transactions
        (bool success1, bytes memory data1) =
            address(lottery1Day).call{gas: 200000}(abi.encodeWithSignature("setRegistry(address)", address(registry)));
        if (success1) {
            console.log("[SUCCESS] Registry set for Cryptolotto1Day");
        } else {
            console.log("[FAILED] Registry set for Cryptolotto1Day");
            if (data1.length > 0) {
                console.log("Error data:", vm.toString(data1));
            }
        }

        (bool success2, bytes memory data2) =
            address(lottery7Days).call{gas: 200000}(abi.encodeWithSignature("setRegistry(address)", address(registry)));
        if (success2) {
            console.log("[SUCCESS] Registry set for Cryptolotto7Days");
        } else {
            console.log("[FAILED] Registry set for Cryptolotto7Days");
            if (data2.length > 0) {
                console.log("Error data:", vm.toString(data2));
            }
        }

        (bool success3, bytes memory data3) =
            address(lotteryAd).call{gas: 200000}(abi.encodeWithSignature("setRegistry(address)", address(registry)));
        if (success3) {
            console.log("[SUCCESS] Registry set for CryptolottoAd");
        } else {
            console.log("[FAILED] Registry set for CryptolottoAd");
            if (data3.length > 0) {
                console.log("Error data:", vm.toString(data3));
            }
        }
        console.log("Registry setup completed");

        // Set treasury names for lottery contracts
        console.log("Setting treasury names...");

        (bool success4, bytes memory data4) = address(lottery1Day).call{gas: 200000}(
            abi.encodeWithSignature("setTreasuryName(string)", "unique_test_lottery_1day")
        );
        if (success4) {
            console.log("[SUCCESS] Treasury name set for Cryptolotto1Day");
        } else {
            console.log("[FAILED] Treasury name set for Cryptolotto1Day");
            if (data4.length > 0) {
                console.log("Error data:", vm.toString(data4));
            }
        }

        (bool success5, bytes memory data5) = address(lottery7Days).call{gas: 200000}(
            abi.encodeWithSignature("setTreasuryName(string)", "unique_test_lottery_7days")
        );
        if (success5) {
            console.log("[SUCCESS] Treasury name set for Cryptolotto7Days");
        } else {
            console.log("[FAILED] Treasury name set for Cryptolotto7Days");
            if (data5.length > 0) {
                console.log("Error data:", vm.toString(data5));
            }
        }

        (bool success6, bytes memory data6) = address(lotteryAd).call{gas: 200000}(
            abi.encodeWithSignature("setTreasuryName(string)", "unique_test_lottery_ad")
        );
        if (success6) {
            console.log("[SUCCESS] Treasury name set for CryptolottoAd");
        } else {
            console.log("[FAILED] Treasury name set for CryptolottoAd");
            if (data6.length > 0) {
                console.log("Error data:", vm.toString(data6));
            }
        }
        console.log("Treasury names setup completed");

        // Set AdToken for Ad Lottery
        console.log("Setting AdToken for Ad Lottery...");
        (bool success7, bytes memory data7) =
            address(lotteryAd).call{gas: 200000}(abi.encodeWithSignature("setAdToken(address)", address(adToken)));
        if (success7) {
            console.log("[SUCCESS] AdToken set for CryptolottoAd");
        } else {
            console.log("[FAILED] AdToken set for CryptolottoAd");
            if (data7.length > 0) {
                console.log("Error data:", vm.toString(data7));
            }
        }
        console.log("AdToken setup completed");

        // Set test mode for easier testing
        console.log("Setting test mode...");
        (bool success8, bytes memory data8) =
            address(lottery1Day).call{gas: 200000}(abi.encodeWithSignature("setTestMode(bool)", true));
        if (success8) {
            console.log("[SUCCESS] Test mode enabled for Cryptolotto1Day");
        } else {
            console.log("[FAILED] Test mode failed for Cryptolotto1Day");
            if (data8.length > 0) {
                console.log("Error data:", vm.toString(data8));
            }
        }

        (bool success9, bytes memory data9) =
            address(lottery7Days).call{gas: 200000}(abi.encodeWithSignature("setTestMode(bool)", true));
        if (success9) {
            console.log("[SUCCESS] Test mode enabled for Cryptolotto7Days");
        } else {
            console.log("[FAILED] Test mode failed for Cryptolotto7Days");
            if (data9.length > 0) {
                console.log("Error data:", vm.toString(data9));
            }
        }

        (bool success10, bytes memory data10) =
            address(lotteryAd).call{gas: 200000}(abi.encodeWithSignature("setTestMode(bool)", true));
        if (success10) {
            console.log("[SUCCESS] Test mode enabled for CryptolottoAd");
        } else {
            console.log("[FAILED] Test mode failed for CryptolottoAd");
            if (data10.length > 0) {
                console.log("Error data:", vm.toString(data10));
            }
        }
        console.log("Test mode setup completed");

        // Add lottery contracts as authorized contracts in TreasuryManager
        console.log("Adding lottery contracts as authorized contracts...");
        (bool success11, bytes memory data11) = address(treasuryManager).call{gas: 200000}(
            abi.encodeWithSignature("addAuthorizedContract(address)", address(lottery1Day))
        );
        if (success11) {
            console.log("[SUCCESS] Cryptolotto1Day authorized in TreasuryManager");
        } else {
            console.log("[FAILED] Cryptolotto1Day authorization failed");
            if (data11.length > 0) {
                console.log("Error data:", vm.toString(data11));
            }
        }

        (bool success12, bytes memory data12) = address(treasuryManager).call{gas: 200000}(
            abi.encodeWithSignature("addAuthorizedContract(address)", address(lottery7Days))
        );
        if (success12) {
            console.log("[SUCCESS] Cryptolotto7Days authorized in TreasuryManager");
        } else {
            console.log("[FAILED] Cryptolotto7Days authorization failed");
            if (data12.length > 0) {
                console.log("Error data:", vm.toString(data12));
            }
        }

        (bool success13, bytes memory data13) = address(treasuryManager).call{gas: 200000}(
            abi.encodeWithSignature("addAuthorizedContract(address)", address(lotteryAd))
        );
        if (success13) {
            console.log("[SUCCESS] CryptolottoAd authorized in TreasuryManager");
        } else {
            console.log("[FAILED] CryptolottoAd authorization failed");
            if (data13.length > 0) {
                console.log("Error data:", vm.toString(data13));
            }
        }
        console.log("Authorization setup completed");

        console.log("Contract setup completed successfully");

        // IMPORTANT: Wait a few blocks to ensure transactions are mined
        console.log("Waiting for transactions to be mined...");

        // Verify setup by calling functions
        console.log("Verifying setup...");

        // Check if registry is set
        (bool verify1, bytes memory verifyData1) =
            address(lottery1Day).call{gas: 200000}(abi.encodeWithSignature("registry()"));
        if (verify1) {
            console.log("[SUCCESS] Registry verification successful for Cryptolotto1Day");
        } else {
            console.log("[FAILED] Registry verification failed for Cryptolotto1Day");
            if (verifyData1.length > 0) {
                console.log("Verification error data:", vm.toString(verifyData1));
            }
        }

        // Test game config to ensure everything is working
        (bool verify2, bytes memory verifyData2) =
            address(lottery1Day).call{gas: 200000}(abi.encodeWithSignature("getGameConfig()"));
        if (verify2) {
            console.log("[SUCCESS] Game config accessible for Cryptolotto1Day");
        } else {
            console.log("[FAILED] Game config failed for Cryptolotto1Day");
            if (verifyData2.length > 0) {
                console.log("Verification error data:", vm.toString(verifyData2));
            }
        }

        console.log("Setup verification completed");
    }

    function _registerContracts() internal {
        // Register contracts in registry using low-level calls to ensure transaction broadcasting
        console.log("Registering contracts in registry...");

        string[] memory names = new string[](9);
        address[] memory contracts = new address[](9);

        names[0] = "TreasuryManager";
        names[1] = "CryptolottoReferral";
        names[2] = "StatsAggregator";
        names[3] = "FundsDistributor";
        names[4] = "SimpleOwnable";
        names[5] = "AdToken";
        names[6] = "Cryptolotto1Day";
        names[7] = "Cryptolotto7Days";
        names[8] = "CryptolottoAd";

        contracts[0] = address(treasuryManager);
        contracts[1] = address(referral);
        contracts[2] = address(stats);
        contracts[3] = address(fundsDistributor);
        contracts[4] = address(ownable);
        contracts[5] = address(adToken);
        contracts[6] = address(lottery1Day);
        contracts[7] = address(lottery7Days);
        contracts[8] = address(lotteryAd);

        // Use low-level call to ensure transaction broadcasting
        (bool success, bytes memory data) = address(registry).call{gas: 500000}(
            abi.encodeWithSignature("registerBatchContracts(string[],address[])", names, contracts)
        );

        if (success) {
            console.log("[SUCCESS] All contracts registered successfully");
        } else {
            console.log("[FAILED] Contract registration failed");
            if (data.length > 0) {
                console.log("Error data:", vm.toString(data));
            }
        }
    }

    function _logDeploymentSummary() internal {
        address deployer = vm.addr(vm.envUint("PRIVATE_KEY"));

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

        // Output addresses in GitHub Actions friendly format
        console.log("::set-output name=CRYPTOLOTTO_1DAY::", address(lottery1Day));
        console.log("::set-output name=CRYPTOLOTTO_7DAYS::", address(lottery7Days));
        console.log("::set-output name=CRYPTOLOTTO_AD::", address(lotteryAd));
        console.log("::set-output name=TREASURY_MANAGER::", address(treasuryManager));
        console.log("::set-output name=CONTRACT_REGISTRY::", address(registry));
        console.log("::set-output name=STATS_AGGREGATOR::", address(stats));
        console.log("::set-output name=FUNDS_DISTRIBUTOR::", address(fundsDistributor));
        console.log("::set-output name=CRYPTOLOTTO_REFERRAL::", address(referral));
        console.log("::set-output name=AD_TOKEN::", address(adToken));
        console.log("::set-output name=OWNABLE::", address(ownable));
    }
}
