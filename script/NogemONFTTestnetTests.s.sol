// // SPDX-License-Identifier: UNLICENSED
// pragma solidity ^0.8.0;

// import {Script, console2} from "forge-std/Script.sol";
// import "../src/NogemONFT721.sol";

// contract MintAndBridgeScript is Script {

//     uint16 private ARBITRUM = 10143;
//     uint16 private ZKSYNC = 10165;
//     uint16 private MUMBAI = 10109;

//     function run() public {
//         address from = 0xdF2f595541307c31F879A17E7C0BBeaca6375634;
//         bytes memory to = abi.encodePacked(from);
//         address addr = 0xEB22C3e221080eAD305CAE5f37F0753970d973Cd;
//         uint16 dstChainId = 110;

//         NogemONFT721 nogem = NogemONFT721(addr);

//         vm.startBroadcast();

//         nogem.mint{value: nogem.mintFee()}();
//         uint256 tokenId = nogem.tokenCounter() - 1;

//         uint16 adapterV = 1;
//         uint256 value = nogem.minDstGasLookup(dstChainId, 1);
//         bytes memory adapterParams = abi.encodePacked(adapterV, value);
//         (uint256 nativeFee, uint256 zroFee) = nogem.estimateSendFee(
//             dstChainId,
//             to,
//             tokenId,
//             false,
//             adapterParams
//         );

//         nogem.sendFrom{value: nativeFee}(
//             from,
//             dstChainId,
//             to,
//             tokenId,
//             payable(from),
//             address(0),
//             adapterParams
//         );

//         vm.stopBroadcast();
//     }
// }

// contract SetBaseURIScript is Script {

//     function run() public {
//         address addr = 0x1acCF58b9A5367Bf2c73A683Cb617800ceba6f09;
//         NogemONFT721 nogem = NogemONFT721(addr);

//         vm.startBroadcast();

//         nogem.setTokenBaseURI("https://zerius.mypinata.cloud/ipfs/QmNQLvTeZVyAjStrAmJxr1RU359ZgFtXECD6z37HsoGBwk/", ".png");

//         nogem.mint{value: nogem.mintFee()}();
//         uint256 tokenId = nogem.tokenCounter() - 1;

//         string memory tokenURI = nogem.tokenURI(tokenId);

//         vm.stopBroadcast();

//         console2.log(tokenURI);
//     }
// }

// contract ClaimFeeEarningsScript is Script {
//     function run() public {
//         address addr = 0x1acCF58b9A5367Bf2c73A683Cb617800ceba6f09;
//         NogemONFT721 nogem = NogemONFT721(addr);

//         vm.startBroadcast();

//         nogem.setMintFee(360000000000000);
//         nogem.mint{value: nogem.mintFee()}();

//         nogem.claimFeeEarnings();

//         vm.stopBroadcast();
//     }
// }

// contract ClaimReferralEarningsScript is Script {
//     function run() public {
//         address referrer = 0xB9d364158Dc1B5E856402De54F18A3d8b7dAa80F;
//         address addr = 0x1acCF58b9A5367Bf2c73A683Cb617800ceba6f09;
//         NogemONFT721 nogem = NogemONFT721(addr);

//         vm.startBroadcast();

//         nogem.setReferralEarningBips(5000);
//         nogem.mint{value: nogem.mintFee()}(referrer);

//         nogem.claimReferrerEarnings();

//         vm.stopBroadcast();
//     }
// }
