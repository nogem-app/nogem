// // SPDX-License-Identifier: UNLICENSED
// pragma solidity ^0.8.0;

// import {Script, console2} from "forge-std/Script.sol";
// import "../src/L2PassONFT721";
// import "../src/L2PortalRefuel";

// contract LinkONFTContractsScript is Script {
//     mapping(uint16 => address) private contracts;
//     mapping(uint16 => uint256) private minDstGas;
//     mapping(uint256 => uint16) private lzIds;
//     uint256 private chainsCount = 1;

//     struct ChainToConnect {
//         uint16 lzId;
//         address contractAddress;
//         uint256 minDstGas;
//     }

//     ChainToConnect[] private chainsToConnect;


//     // REFUEL
//     // ChainToConnect private ETHEREUM = ChainToConnect(101, 0x178608fFe2Cca5d36f3Fc6e69426c4D3A5A74A41, 300000); // ethereum
//     // ChainToConnect private ARBITRUM = ChainToConnect(110, 0x412aea168aDd34361aFEf6a2e3FC01928Fba1248, 200000); // arbitrum
//     // ChainToConnect private OPTIMISM = ChainToConnect(111, 0x2076BDd52Af431ba0E5411b3dd9B5eeDa31BB9Eb, 200000); // optimism
//     // ChainToConnect private POLYGON = ChainToConnect(109, 0x2ef766b59e4603250265EcC468cF38a6a00b84b3, 250000); // polygon
//     // ChainToConnect private BSC = ChainToConnect(102, 0x5B209E7c81DEaad0ffb8b76b696dBb4633A318CD, 250000); // bsc
//     ChainToConnect private AVALANCHE = ChainToConnect(106, 0x0D9E8Eed827bcc7808b86D278c4cdD5946F25e73, 250000); // avalanche
//     // ChainToConnect private BASE = ChainToConnect(184, 0x9415AD63EdF2e0de7D8B9D8FeE4b939dd1e52F2C, 250000);
//     // ChainToConnect private ZORA = ChainToConnect(195, 0x1fe2c567169d39CCc5299727FfAC96362b2Ab90E, 250000); // zora
//     // ChainToConnect private SCROLL = ChainToConnect(214, 0xEB22C3e221080eAD305CAE5f37F0753970d973Cd, 250000); // scroll
//     // ChainToConnect private ZKSYNC = ChainToConnect(165, 0x7dA50bD0fb3C2E868069d9271A2aeb7eD943c2D6, 2000000); // zkSync
//     // ChainToConnect private LINEA = ChainToConnect(183, 0x5188368a92B49F30f4Cf9bEF64635bCf8459c7A7, 250000); // linea
//     // ChainToConnect private NOVA = ChainToConnect(175, 0x5188368a92B49F30f4Cf9bEF64635bCf8459c7A7, 250000); // nova
//     // ChainToConnect private METIS = ChainToConnect(151, 0x5188368a92B49F30f4Cf9bEF64635bCf8459c7A7, 250000); // metis
//     // ChainToConnect private MOONBEAM = ChainToConnect(126, 0x4c5AeDA35d8F0F7b67d6EB547eAB1df75aA23Eaf, 400000); // moonbeam
//     // ChainToConnect private POLYGONZKEVM = ChainToConnect(158, 0x4c5AeDA35d8F0F7b67d6EB547eAB1df75aA23Eaf, 250000); // polygonZkEvm
//     // ChainToConnect private CORE = ChainToConnect(153, 0x5188368a92B49F30f4Cf9bEF64635bCf8459c7A7, 250000); // core
//     // ChainToConnect private CELO = ChainToConnect(125, 0x4c5AeDA35d8F0F7b67d6EB547eAB1df75aA23Eaf, 250000); // celo
//     // ChainToConnect private HARMONY = ChainToConnect(116, 0x5188368a92B49F30f4Cf9bEF64635bCf8459c7A7, 250000); // harmony
//     // ChainToConnect private CANTO = ChainToConnect(159, 0x5188368a92B49F30f4Cf9bEF64635bCf8459c7A7, 250000); // canto
//     // ChainToConnect private FANTOM = ChainToConnect(112, 0x5188368a92B49F30f4Cf9bEF64635bCf8459c7A7, 250000); // fantom
//     // ChainToConnect private GNOSIS = ChainToConnect(145, 0x5188368a92B49F30f4Cf9bEF64635bCf8459c7A7, 250000); // gnosis

//     //fantom=0xa6ce244C423Af2bCef522fc5Fbc1df28528Da2e0
//     //mantle=0x6D594b9FCb39E7E8942b431C0826BEeaE25bA39a
//     // ChainToConnect private fantom = ChainToConnect(112, 0xa6ce244C423Af2bCef522fc5Fbc1df28528Da2e0, 250000); // fanto
//     // ChainToConnect private mantle = ChainToConnect(181, 0x6D594b9FCb39E7E8942b431C0826BEeaE25bA39a, 250000); // fanto
//     // ChainToConnect private loot = ChainToConnect(197, 0x6D594b9FCb39E7E8942b431C0826BEeaE25bA39a, 250000);
//     // ChainToConnect private gnosis = ChainToConnect(145, 0x92E5b93af8fB4eE8b1db0ac8dF85a6Bfa15651eE, 250000); // gnosis
//     ChainToConnect private selectedChain = AVALANCHE;


//     function setUp() public {
// // REFUEL CONTRACT ADDRESSES
// //        chainsToConnect.push(ETHEREUM); // ethereum
// //        chainsToConnect.push(ARBITRUM); // arbitrum
// //        chainsToConnect.push(SDASD); // optimism
// //        chainsToConnect.push(POLYGON); // polygon
// //        chainsToConnect.push(BSC); // bsc
// //        chainsToConnect.push(AVALANCHE); // avalanche
// //        chainsToConnect.push(BASE); // base
// //        chainsToConnect.push(ZORA); // zora
// //        chainsToConnect.push(SCROLL); // scroll
// //        chainsToConnect.push(ZKSYNC); // zkSync
// //        chainsToConnect.push(LINEA); // linea
// //        chainsToConnect.push(NOVA); // nova
// //        chainsToConnect.push(METIS); // metis
// //        chainsToConnect.push(MOONBEAM); // moonbeam
// //        chainsToConnect.push(POLYGONZKEVM); // polygonZkEvm
// //        chainsToConnect.push(CORE); // core
// //        chainsToConnect.push(CELO); // celo
// //        chainsToConnect.push(HARMONY); // harmony
// //        chainsToConnect.push(CANTO); // canto
//           //chainsToConnect.push(mantle); // fantom
// //        chainsToConnect.push(GNOSIS); // gnosis
//     }

//   function run() public {
//     vm.startBroadcast();

//     for (uint256 i = 0; i < chainsToConnect.length; i++) {
//         ChainToConnect memory primaryChain = chainsToConnect[i];
//         NogemRefuel primaryNogem = NogemRefuel(primaryChain.contractAddress);

//         for (uint256 j = 0; j < chainsToConnect.length; j++) {
//             if (i != j) { // Убедитесь, что не пытаетесь подключить контракт сам к себе
//                 ChainToConnect memory secondaryChain = chainsToConnect[j];

//                 // Установка minDstGas, если она ещё не установлена
//                 if (primaryNogem.minDstGasLookup(secondaryChain.lzId, 0) == 0) {
//                     primaryNogem.setMinDstGas(secondaryChain.lzId, 0, secondaryChain.minDstGas);
//                 }

//                 // Установка trustedRemote, если оно ещё не установлено
//                 if (primaryNogem.trustedRemoteLookup(secondaryChain.lzId).length == 0) {
//                     bytes memory trusted = abi.encodePacked(secondaryChain.contractAddress, primaryChain.contractAddress);
//                     primaryNogem.setTrustedRemote(secondaryChain.lzId, trusted);
//                 }
//             }
//         }
//     }
//     vm.stopBroadcast();
// }
// }
