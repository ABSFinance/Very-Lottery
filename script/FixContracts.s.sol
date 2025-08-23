// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../contracts/modules/lottery/Cryptolotto1Day.sol";
import "../contracts/modules/lottery/Cryptolotto7Days.sol";
import "../contracts/modules/lottery/CryptolottoAd.sol";

contract FixContracts is Script {
    function run() public {
        console.log("=== FIXING DEPLOYED CONTRACTS ===");

        // Get deployer address
        address deployer = vm.addr(vm.envUint("PRIVATE_KEY"));
        console.log("Deployer:", deployer);

        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        // Fix Cryptolotto1Day
        console.log("\nFixing Cryptolotto1Day...");
        Cryptolotto1Day lottery1Day = Cryptolotto1Day(payable(0x26D97e6580A423b2cf006500285455b85DCcCC4c));

        try lottery1Day.initialize(
            deployer, // owner
            address(0x7742c6200196560Ae97C7E3840dbADAce8F70506), // FundsDistributor
            address(0x8b5f18a38cc923Db86c2481e948D6543dc0d22e1), // StatsAggregator
            address(0xc562E45DDf33bC61020776c6947Fa99704e3B296), // CryptolottoReferral
            address(0x72385DaFD88e6Aaa1119ebEAef55F021fFD771d4), // TreasuryManager
            "unique_test_lottery_1day" // treasuryName
        ) {
            console.log("Cryptolotto1Day initialized successfully");
        } catch Error(string memory reason) {
            console.log("Cryptolotto1Day initialization failed:", reason);
        } catch {
            console.log("Cryptolotto1Day initialization failed with unknown error");
        }

        // Fix Cryptolotto7Days
        console.log("\nFixing Cryptolotto7Days...");
        Cryptolotto7Days lottery7Days = Cryptolotto7Days(payable(0x315Dbcc9E66a79C2E3f50B26AEE3Ca1b2e513f65));

        try lottery7Days.initialize(
            deployer, // owner
            address(0x7742c6200196560Ae97C7E3840dbADAce8F70506), // FundsDistributor
            address(0x8b5f18a38cc923Db86c2481e948D6543dc0d22e1), // StatsAggregator
            address(0xc562E45DDf33bC61020776c6947Fa99704e3B296), // CryptolottoReferral
            address(0x72385DaFD88e6Aaa1119ebEAef55F021fFD771d4), // TreasuryManager
            "unique_test_lottery_7days" // treasuryName
        ) {
            console.log("Cryptolotto7Days initialized successfully");
        } catch Error(string memory reason) {
            console.log("Cryptolotto7Days initialization failed:", reason);
        } catch {
            console.log("Cryptolotto7Days initialization failed with unknown error");
        }

        // Fix CryptolottoAd
        console.log("\nFixing CryptolottoAd...");
        CryptolottoAd lotteryAd = CryptolottoAd(payable(0xF30AA92045FF4B077F2dfE61c7DE979a7dEDfF91));

        try lotteryAd.initialize(
            deployer, // owner
            address(0x7742c6200196560Ae97C7E3840dbADAce8F70506), // FundsDistributor
            address(0x8b5f18a38cc923Db86c2481e948D6543dc0d22e1), // StatsAggregator
            address(0xc562E45DDf33bC61020776c6947Fa99704e3B296), // CryptolottoReferral
            address(0x72385DaFD88e6Aaa1119ebEAef55F021fFD771d4), // TreasuryManager
            "unique_test_lottery_ad" // treasuryName
        ) {
            console.log("CryptolottoAd initialized successfully");
        } catch Error(string memory reason) {
            console.log("CryptolottoAd initialization failed:", reason);
        } catch {
            console.log("CryptolottoAd initialization failed with unknown error");
        }

        vm.stopBroadcast();

        console.log("\n=== CONTRACT FIXING COMPLETE ===");
        console.log("Now test the contracts to see if they work!");
    }
}
