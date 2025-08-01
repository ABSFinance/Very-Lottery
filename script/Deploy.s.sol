// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "forge-std/Script.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../contracts/modules/lottery/Cryptolotto1Day.sol";
import "../contracts/modules/lottery/Cryptolotto7Days.sol";
import "../contracts/modules/lottery/CryptolottoAd.sol";
import "../contracts/modules/lottery/AdToken.sol";
import "../contracts/modules/analytics/StatsAggregator.sol";
import "../contracts/modules/treasury/FundsDistributor.sol";
import "../contracts/modules/treasury/CryptolottoReferral.sol";
import "../contracts/modules/treasury/TreasuryManager.sol";
import "../contracts/modules/lottery/SimpleOwnable.sol";
import "../contracts/shared/utils/ContractRegistry.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DeployScript is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);

        console.log("Deployer address:", deployer);

        // Deploy base contracts first
        SimpleOwnable ownable = new SimpleOwnable();
        StatsAggregator stats = new StatsAggregator();
        FundsDistributor fundsDistributor = new FundsDistributor();
        CryptolottoReferral referral = new CryptolottoReferral();
        AdToken adToken = new AdToken();
        ContractRegistry registry = new ContractRegistry();

        // Deploy TreasuryManager
        TreasuryManager treasuryManager = new TreasuryManager();

        // Deploy implementation contracts
        Cryptolotto1Day implementation1Day = new Cryptolotto1Day();
        Cryptolotto7Days implementation7Days = new Cryptolotto7Days();
        CryptolottoAd implementationAd = new CryptolottoAd();

        // Create Treasuries
        treasuryManager.createTreasury("unique_test_lottery_1day", 1000 ether);
        treasuryManager.createTreasury("unique_test_lottery_7days", 1000 ether);
        treasuryManager.createTreasury("unique_test_lottery_ad", 1000 ether);

        // Prepare initialization data
        bytes memory initData1Day = abi.encodeWithSelector(
            Cryptolotto1Day.initialize.selector,
            address(ownable),
            address(fundsDistributor),
            address(stats),
            address(referral),
            address(treasuryManager)
        );

        bytes memory initData7Days = abi.encodeWithSelector(
            Cryptolotto7Days.initialize.selector,
            address(ownable),
            address(fundsDistributor),
            address(stats),
            address(referral),
            address(treasuryManager)
        );

        bytes memory initDataAd = abi.encodeWithSelector(
            CryptolottoAd.initialize.selector,
            address(ownable),
            address(fundsDistributor),
            address(stats),
            address(referral),
            address(treasuryManager)
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
        Cryptolotto1Day lottery1Day = Cryptolotto1Day(
            payable(address(proxy1Day))
        );
        Cryptolotto7Days lottery7Days = Cryptolotto7Days(
            payable(address(proxy7Days))
        );
        CryptolottoAd lotteryAd = CryptolottoAd(payable(address(proxyAd)));

        // Set registry for lottery contracts
        lottery1Day.setRegistry(address(registry));
        lottery7Days.setRegistry(address(registry));
        lotteryAd.setRegistry(address(registry));

        // Set AdToken for Ad Lottery
        lotteryAd.setAdToken(address(adToken));

        // Set test mode for easier testing
        lottery1Day.setTestMode(true);
        lottery7Days.setTestMode(true);
        lotteryAd.setTestMode(true);

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
        contracts[7] = address(lottery7Days);

        registry.registerBatchContracts(names, contracts);

        vm.stopBroadcast();

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
        console.log(
            "Cryptolotto1Day Implementation deployed at:",
            address(implementation1Day)
        );
        console.log("Cryptolotto1Day Proxy deployed at:", address(proxy1Day));
        console.log(
            "Cryptolotto7Days Implementation deployed at:",
            address(implementation7Days)
        );
        console.log("Cryptolotto7Days Proxy deployed at:", address(proxy7Days));
        console.log(
            "CryptolottoAd Implementation deployed at:",
            address(implementationAd)
        );
        console.log("CryptolottoAd Proxy deployed at:", address(proxyAd));
        console.log("=== DEPLOYMENT COMPLETE ===");
    }
}
