// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import "../src/NogemRefuel.sol";

contract NogemRefuelScript is Script {

    function run() public {
        address lzEndpoint = 0xb6319cC6c8c27A8F5dAF0dD3DF91EA35C4720dd7;
        vm.broadcast();

        L2PortalRefuel portal = new L2PortalRefuel(lzEndpoint);
    }
}
//forge create --rpc-url https://42170.rpc.thirdweb.com --private-key 9c8d112c471f44993f04cdfc61a5cf522a934f11938fc98ce3c80c384e6e79bb src/NogemRefuel.sol:NogemRefuel --constructor-args 0x4EE2F9B7cf3A68966c370F3eb2C16613d3235245
//forge script --broadcast --private-key d02ec8debb210b1c142eaedeba8b503996ece80366b97d387346b7d47ef80e4b --rpc-url https://5000.rpc.thirdweb.com ./script/ZeriusRefuel.s.sol:NogemRefuelScript --legacy
