// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../contracts/games/Cryptolotto1Day.sol";
import "../contracts/games/Cryptolotto7Days.sol";
import "../contracts/analytics/StatsAggregator.sol";
import "../contracts/distribution/FundsDistributor.sol";
import "../contracts/distribution/CryptolottoReferral.sol";
import "../contracts/managers/TreasuryManager.sol";
import "../contracts/core/SimpleOwnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DeployScript is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Deploy base contracts first
        SimpleOwnable ownable = new SimpleOwnable();
        StatsAggregator stats = new StatsAggregator();
        FundsDistributor fundsDistributor = new FundsDistributor();
        CryptolottoReferral referral = new CryptolottoReferral(
            address(ownable)
        );

        // Deploy TreasuryManager
        TreasuryManager treasuryManager = new TreasuryManager();

        // Deploy implementation contracts
        Cryptolotto1Day implementation1Day = new Cryptolotto1Day();
        Cryptolotto7Days implementation7Days = new Cryptolotto7Days();

        // Create Treasury
        treasuryManager.createTreasury("unique_test_lottery_1day", 1000 ether);
        treasuryManager.createTreasury("unique_test_lottery_7days", 1000 ether);

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

        // Deploy proxy contracts
        ERC1967Proxy proxy1Day = new ERC1967Proxy(
            address(implementation1Day),
            initData1Day
        );

        ERC1967Proxy proxy7Days = new ERC1967Proxy(
            address(implementation7Days),
            initData7Days
        );

        vm.stopBroadcast();

        // Log deployed addresses
        console.log("Ownable deployed at:", address(ownable));
        console.log("StatsAggregator deployed at:", address(stats));
        console.log("FundsDistributor deployed at:", address(fundsDistributor));
        console.log("CryptolottoReferral deployed at:", address(referral));
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
    }
}
