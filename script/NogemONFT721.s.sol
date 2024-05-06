// // SPDX-License-Identifier: UNLICENSED
// pragma solidity ^0.8.13;

// import {Script, console2} from "forge-std/Script.sol";
// import "../src/L2PassONFT721.sol";

// /**
// * @author Nogem
// * @title NogemONFT721Script
// * @notice Deploy script for {NogemONFT721}
// */
// contract NogemONFT721Script is Script {

//     function run() public {

//        uint256 minGasToTransfer = 100000;
//        address lzEndpoint = 0x3c2269811836af69497E5F486A85D7316753cf62;
//        uint256 startMintId = 2000001;
//        uint256 endMintId = 2500000;
//        uint256 mintFee = 0 ether;
//        uint256 bridgeFee = 0 ether;
//        address feeCollector = 0x004fbB1E3Ae907fA7fECcbCF8e3607C9911Eb523; 
//        uint256 referralEarningBips = 0;
        
//         vm.broadcast();
//         L2PassONFT721 nogem = new NogemONFT721(
//             minGasToTransfer,
//             lzEndpoint,
//             startMintId,
//             endMintId,
//             mintFee,
//             bridgeFee,
//             feeCollector,
//             referralEarningBips
//         );
//     }
// }

// //forge script --broadcast --private-key 9c8d112c471f44993f04cdfc61a5cf522a934f11938fc98ce3c80c384e6e79bb --rpc-url https://43114.rpc.thirdweb.com ./script/ZeriusONFT721.s.sol --legacy


// // Conflux | 4500001 - 5000000

// // Harmony | 7000001 - 7500000

// // Klaytn | 8500001 - 9000000

// // Linea | 9000001 - 9500000


// // Mantle | 10500001 - 11000000


// // Moonbeam | 11500001 - 12000000

// // Moonriver | 12000001 - 12500000


// // Polygon zkEVM | 15000001 - 15500000
// // Scroll | 16000001 - 16500000

// // forge create --rpc-url https://250.rpc.thirdweb.com --constructor-args "100000" "0xb6319cC6c8c27A8F5dAF0dD3DF91EA35C4720dd7" 5500001 6000000 0 0 0x004fbB1E3Ae907fA7fECcbCF8e3607C9911Eb523 0 --private-key 9c8d112c471f44993f04cdfc61a5cf522a934f11938fc98ce3c80c384e6e79bb --etherscan-api-key MBNGUS4CRQC2HK3XJJWVNBZ5986S1EXV6X --verify src/NogemONFT721.sol:NogemONFT721

// //forge verify-contract --chain-id 250 --watch --constructor-args $(cast abi-encode "constructor(uint256 _minGasToTransfer,address _lzEndpoint,uint256 _startMintId,uint256 _endMintId,uint256 _mintFee,uint256 _bridgeFee,address _feeCollector,uint256 _referralEarningBips)" "100000" "0xb6319cC6c8c27A8F5dAF0dD3DF91EA35C4720dd7" 5500001 6000000 0 0 0x004fbB1E3Ae907fA7fECcbCF8e3607C9911Eb523 0) --etherscan-api-key MBNGUS4CRQC2HK3XJJWVNBZ5986S1EXV6X 0x9DEb6e95e092EA81F2083E1997DC4fEc8F352bD4 src/NogemONFT721.sol:NogemONFT721