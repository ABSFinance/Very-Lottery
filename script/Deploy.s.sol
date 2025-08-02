// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

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
    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployer);

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

    function _deployCoreContracts()
        internal
        returns (
            SimpleOwnable ownable,
            StatsAggregator stats,
            FundsDistributor fundsDistributor,
            CryptolottoReferral referral,
            AdToken adToken,
            ContractRegistry registry,
            TreasuryManager treasuryManager
        )
    {
        // Deploy core contracts
        ownable = new SimpleOwnable();
        stats = new StatsAggregator();
        fundsDistributor = new FundsDistributor();
        referral = new CryptolottoReferral();
        adToken = new AdToken();
        registry = new ContractRegistry();
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

    function _deployLotteryContracts()
        internal
        returns (
            Cryptolotto1Day lottery1Day,
            Cryptolotto7Days lottery7Days,
            CryptolottoAd lotteryAd
        )
    {
        // Deploy implementations
        Cryptolotto1Day implementation1Day = new Cryptolotto1Day();
        Cryptolotto7Days implementation7Days = new Cryptolotto7Days();
        CryptolottoAd implementationAd = new CryptolottoAd();

        // Prepare initialization data
        bytes memory initData1Day = abi.encodeWithSelector(
            Cryptolotto1Day.initialize.selector
        );
        bytes memory initData7Days = abi.encodeWithSelector(
            Cryptolotto7Days.initialize.selector
        );
        bytes memory initDataAd = abi.encodeWithSelector(
            CryptolottoAd.initialize.selector
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
        // Get deployed contracts
        (
            SimpleOwnable _ownable,
            StatsAggregator _stats,
            FundsDistributor _fundsDistributor,
            CryptolottoReferral _referral,
            AdToken _adToken,
            ContractRegistry _registry,
            TreasuryManager _treasuryManager
        ) = _deployCoreContracts();

        (
            Cryptolotto1Day _lottery1Day,
            Cryptolotto7Days _lottery7Days,
            CryptolottoAd _lotteryAd
        ) = _deployLotteryContracts();

        // Set registry for lottery contracts
        _lottery1Day.setRegistry(address(_registry));
        _lottery7Days.setRegistry(address(_registry));
        _lotteryAd.setRegistry(address(_registry));

        // Set AdToken for Ad Lottery
        _lotteryAd.setAdToken(address(_adToken));

        // Set test mode for easier testing
        _lottery1Day.setTestMode(true);
        _lottery7Days.setTestMode(true);
        _lotteryAd.setTestMode(true);
    }

    function _registerContracts() internal {
        // Get deployed contracts
        (
            SimpleOwnable _ownable,
            StatsAggregator _stats,
            FundsDistributor _fundsDistributor,
            CryptolottoReferral _referral,
            AdToken _adToken,
            ContractRegistry _registry,
            TreasuryManager _treasuryManager
        ) = _deployCoreContracts();

        (
            Cryptolotto1Day _lottery1Day,
            Cryptolotto7Days _lottery7Days,
            CryptolottoAd _lotteryAd
        ) = _deployLotteryContracts();

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

        contracts[0] = address(_treasuryManager);
        contracts[1] = address(_referral);
        contracts[2] = address(_stats);
        contracts[3] = address(_fundsDistributor);
        contracts[4] = address(_ownable);
        contracts[5] = address(_adToken);
        contracts[6] = address(_lottery1Day);
        contracts[7] = address(_lottery7Days);

        _registry.registerBatchContracts(names, contracts);
    }

    function _logDeploymentSummary() internal {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        // Get deployed contracts
        (
            SimpleOwnable _ownable,
            StatsAggregator _stats,
            FundsDistributor _fundsDistributor,
            CryptolottoReferral _referral,
            AdToken _adToken,
            ContractRegistry _registry,
            TreasuryManager _treasuryManager
        ) = _deployCoreContracts();

        (
            Cryptolotto1Day _lottery1Day,
            Cryptolotto7Days _lottery7Days,
            CryptolottoAd _lotteryAd
        ) = _deployLotteryContracts();

        // Log deployed addresses
        console.log("=== DEPLOYMENT SUMMARY ===");
        console.log("Deployer:", deployer);
        console.log("Ownable deployed at:", address(_ownable));
        console.log("StatsAggregator deployed at:", address(_stats));
        console.log(
            "FundsDistributor deployed at:",
            address(_fundsDistributor)
        );
        console.log("CryptolottoReferral deployed at:", address(_referral));
        console.log("AdToken deployed at:", address(_adToken));
        console.log("ContractRegistry deployed at:", address(_registry));
        console.log("TreasuryManager deployed at:", address(_treasuryManager));
        console.log("Cryptolotto1Day deployed at:", address(_lottery1Day));
        console.log("Cryptolotto7Days deployed at:", address(_lottery7Days));
        console.log("CryptolottoAd deployed at:", address(_lotteryAd));
        console.log("=== DEPLOYMENT COMPLETE ===");
    }
}
