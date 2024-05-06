// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@layerzerolabs/contracts/mocks/LZEndpointMock.sol";
import "@openzeppelin//contracts/token/ERC721/IERC721Receiver.sol";
import {Test, console2} from "forge-std/Test.sol";

import {L2PortalONFT721} from "../src/NogemONFT721.sol";

/**
* @author L2Portal
* @title Test for L2PortalONFT721 contract
* @notice Use this contract for foundry tests only
*/
contract L2PortalONFT721Test is Test, IERC721Receiver {

    L2PortalONFT721 public nogemONFT721;
    LZEndpointMock public lzEndpointMock;

    L2PortalONFT721 public dstL2PortalONFT721;
    LZEndpointMock public dstLzEndpointMock;

    /********************
    * EVENTS
    */

    event MintFeeChanged(uint256 indexed oldMintFee, uint256 indexed newMintFee);
    event BridgeFeeChanged(uint256 indexed oldBridgeFee, uint256 indexed newBridgeFee);
    event ReferralEarningBipsChanged(uint256 indexed oldReferralEarningBips, uint256 indexed newReferralEarningBips);
    event EarningBipsForReferrerChanged(address indexed referrer, uint256 newEraningBips);
    event EarningBipsForReferrersChanged(address[] indexed referrer, uint256 newEraningBips);
    event FeeCollectorChanged(address indexed oldFeeCollector, address indexed newFeeCollector);
    event TokenURIChanged(string indexed oldTokenURI, string indexed newTokenURI, string fileExtension);
    event TokenURILocked(bool indexed newState);
    event ONFTMinted(
        address indexed minter,
        uint256 indexed itemId,
        uint256 feeEarnings,
        address indexed referrer,
        uint256 referrerEarnings
    );
    event BridgeFeeEarned(
        address indexed from,
        uint16 indexed dstChainId,
        uint256 amount
    );
    event FeeEarningsClaimed(address indexed collector, uint256 claimedAmount);
    event ReferrerEarningsClaimed(address indexed referrer, uint256 claimedAmount);

    /********************
    * ERRORS
    */

    uint8 public constant ERROR_INVALID_URI_LOCK_STATE = 1;
    uint8 public constant ERROR_MINT_EXCEEDS_LIMIT = 2;
    uint8 public constant ERROR_MINT_INVALID_FEE = 3;
    uint8 public constant ERROR_INVALID_TOKEN_ID = 4;
    uint8 public constant ERROR_INVALID_COLLECTOR_ADDRESS = 5;
    uint8 public constant ERROR_NOTHING_TO_CLAIM = 6;
    uint8 public constant ERROR_NOT_FEE_COLLECTOR = 7;
    uint8 public constant ERROR_REFERRAL_BIPS_TOO_HIGH = 8;
    uint8 public constant ERROR_INVALID_REFERER = 9;

    error L2PortalONFT721_CoreError(uint256 errorCode);

    /********************
   * SETUP
   */
    uint16 public constant DST_CHAIN_ID = 1;
    uint16 public constant SRC_CHAIN_ID = 0;
    uint256 public constant DST_BATCH_LIMIT = 5;
    uint256 public constant END_MINT_ID = 5;
    uint256 public constant START_MINT_ID = 0;
    uint256 public constant MINT_FEE = 0.0001 ether;
    uint256 public constant BRIDGE_FEE = 0.0001 ether;
    uint256 public constant MAX_REFERRAL_EARNING_BIPS = 5000; // 50%
    uint256 public constant MAX_REFERRER_EARNING_BIPS = 10000; // 100%

    address public constant PAYABLE_ADDRESS = 0xAb5801a7D398351b8bE11C439e05C5B3259aeC9B;
    uint256 public constant DENOMINATOR = 10000; // 100%
    uint256 public constant MIN_GAS_TO_TRANSFER = 200_000;
    uint16 public constant LZ_VERSION = 1;
    string public constant IPFS_URI = "https://ipfs.io/ipfs/";


    /**
    * @notice Setup testing contract before running tests
    * @dev You can customize settings (eg. CHAIN_ID)
    * by changing setup fields above
    */
    function setUp() public {
        _error = ERC721ReceiveError.None;
        lzEndpointMock = new LZEndpointMock(SRC_CHAIN_ID);
        nogemONFT721 = new L2PortalONFT721(
            MIN_GAS_TO_TRANSFER,
            address(lzEndpointMock),
            START_MINT_ID,
            END_MINT_ID,
            MINT_FEE,
            BRIDGE_FEE,
            PAYABLE_ADDRESS,
            0
        );

        dstLzEndpointMock = new LZEndpointMock(DST_CHAIN_ID);
        dstL2PortalONFT721 = new L2PortalONFT721(
            MIN_GAS_TO_TRANSFER,
            address(dstLzEndpointMock),
            START_MINT_ID,
            END_MINT_ID,
            MINT_FEE,
            BRIDGE_FEE,
            PAYABLE_ADDRESS,
            0
        );

        lzEndpointMock.setDestLzEndpoint(address(dstL2PortalONFT721), address(dstLzEndpointMock));
        dstLzEndpointMock.setDestLzEndpoint(address(nogemONFT721), address(lzEndpointMock));

        nogemONFT721.setTrustedRemote(DST_CHAIN_ID, abi.encodePacked(address(dstL2PortalONFT721), address(nogemONFT721)));
        dstL2PortalONFT721.setTrustedRemote(SRC_CHAIN_ID, abi.encodePacked(address(nogemONFT721), address(dstL2PortalONFT721)));

        nogemONFT721.setMinDstGas(DST_CHAIN_ID, nogemONFT721.FUNCTION_TYPE_SEND(), MIN_GAS_TO_TRANSFER);
        nogemONFT721.setDstChainIdToBatchLimit(DST_CHAIN_ID, DST_BATCH_LIMIT);
    }

    /********************
    * TESTS
    */

    //////////////////
    ////// MINT //////
    //////////////////

    /// @custom:test Successfully mint ONFT
    /// @dev See {L2PortalONFT721-mint}
    function test_mint_success() public {
        _error = ERC721ReceiveError.None;
        address minter = address(this);

        uint256 before_tokenCounter = nogemONFT721.tokenCounter();
        uint256 before_ownerBalance = nogemONFT721.balanceOf(minter);
        uint256 before_earnings = nogemONFT721.feeEarnedAmount();

        uint256 nextTokenId = before_tokenCounter;

        vm.expectEmit();
        emit ONFTMinted(
            minter,
            nextTokenId,
            MINT_FEE,
            address(0),
            0
        );
        nogemONFT721.mint{value: MINT_FEE}();

        uint256 after_tokenCounter = nogemONFT721.tokenCounter();
        uint256 after_ownerBalance = nogemONFT721.balanceOf(minter);
        uint256 after_earnings = nogemONFT721.feeEarnedAmount();
        uint256 earned = after_earnings - before_earnings;

        assertEq(nogemONFT721.ownerOf(nextTokenId), minter, "Incorrect token owner");
        assertEq(before_tokenCounter + 1, after_tokenCounter, "Token counter is not updated");
        assertEq(before_ownerBalance + 1, after_ownerBalance, "Owner balance is not updated");
        assertEq(earned, MINT_FEE, "Mint fee is not collected");
    }

    /// @custom:test Fail mint because of a recipient error
    /// @dev See {L2PortalONFT721-mint}
    function test_mint_fail_receiveFailedWithoutMessage() public {
        _error = ERC721ReceiveError.RevertWithoutMessage;
        vm.expectRevert();
        nogemONFT721.mint{value: MINT_FEE}();
    }

    /// @custom:test Fail mint because of insufficient fee
    /// @dev See {L2PortalONFT721-mint}
    function test_mint_fail_invalidMintFee() public {
        _error = ERC721ReceiveError.None;
        vm.expectRevert(abi.encodeWithSelector(L2PortalONFT721_CoreError.selector, ERROR_MINT_INVALID_FEE));
        nogemONFT721.mint{value: 0}();
    }

    /// @custom:test Fail mint because of reaching minting limit
    /// @dev See {L2PortalONFT721-mint}
    function test_mint_fail_exceedsMintLimit() public mintAmountBeforeTest(END_MINT_ID - START_MINT_ID) {
        _error = ERC721ReceiveError.None;
        vm.expectRevert(abi.encodeWithSelector(L2PortalONFT721_CoreError.selector, ERROR_MINT_EXCEEDS_LIMIT));
        nogemONFT721.mint{value: MINT_FEE}();
    }

    /// @custom:test Successfully mint ONFT with referrer address and referral earning bips
    /// @dev See {L2PortalONFT721-mint}
    function test_mint_withReferral_success() public {
        _error = ERC721ReceiveError.None;
        address minter = address(this);
        address referrer = PAYABLE_ADDRESS;

        nogemONFT721.setReferralEarningBips(MAX_REFERRAL_EARNING_BIPS);
        uint256 referrerEarnings = MINT_FEE * MAX_REFERRAL_EARNING_BIPS / DENOMINATOR;

        uint256 before_tokenCounter = nogemONFT721.tokenCounter();
        uint256 before_ownerBalance = nogemONFT721.balanceOf(minter);
        uint256 before_earnings = nogemONFT721.feeEarnedAmount();
        uint256 before_referrerTransactionsCount = nogemONFT721.referredTransactionsCount(referrer);
        uint256 before_referrerEarnings = nogemONFT721.referrersEarnedAmount(referrer);

        uint256 nextTokenId = before_tokenCounter;

        vm.expectEmit();
        emit ONFTMinted(
            minter,
            nextTokenId,
            MINT_FEE - referrerEarnings,
            referrer,
            referrerEarnings
        );
        nogemONFT721.mint{value: MINT_FEE}(referrer);

        uint256 after_tokenCounter = nogemONFT721.tokenCounter();
        uint256 after_ownerBalance = nogemONFT721.balanceOf(minter);
        uint256 after_earnings = nogemONFT721.feeEarnedAmount();
        uint256 earned = after_earnings - before_earnings;
        uint256 after_referrerTransactionsCount = nogemONFT721.referredTransactionsCount(referrer);
        uint256 after_referrerEarnings = nogemONFT721.referrersEarnedAmount(referrer);

        assertEq(nogemONFT721.ownerOf(nextTokenId), minter, "Incorrect token owner");
        assertEq(before_tokenCounter + 1, after_tokenCounter, "Token counter is not updated");
        assertEq(before_ownerBalance + 1, after_ownerBalance, "Owner balance is not updated");
        assertEq(earned, MINT_FEE - referrerEarnings, "Mint fee is not collected");
        assertEq(after_referrerTransactionsCount - before_referrerTransactionsCount, 1, "Referrer transactions is not updated");
        assertEq(after_referrerEarnings - before_referrerEarnings, referrerEarnings, "Referrer earnings is not updated");
    }

    /// @custom:test Successfully mint ONFT with referrer address and referrer earning bips
    /// @dev See {L2PortalONFT721-mint}
    function test_mint_withReferrerEarningBips_success() public {
        _error = ERC721ReceiveError.None;
        address minter = address(this);
        address referrer = PAYABLE_ADDRESS;

        nogemONFT721.setEarningBipsForReferrer(referrer, MAX_REFERRAL_EARNING_BIPS);
        uint256 referrerEarnings = MINT_FEE * MAX_REFERRAL_EARNING_BIPS / DENOMINATOR;

        uint256 before_tokenCounter = nogemONFT721.tokenCounter();
        uint256 before_ownerBalance = nogemONFT721.balanceOf(minter);
        uint256 before_earnings = nogemONFT721.feeEarnedAmount();
        uint256 before_referrerTransactionsCount = nogemONFT721.referredTransactionsCount(referrer);
        uint256 before_referrerEarnings = nogemONFT721.referrersEarnedAmount(referrer);

        uint256 nextTokenId = before_tokenCounter;

        vm.expectEmit();
        emit ONFTMinted(
            minter,
            nextTokenId,
            MINT_FEE - referrerEarnings,
            referrer,
            referrerEarnings
        );
        nogemONFT721.mint{value: MINT_FEE}(referrer);

        uint256 after_tokenCounter = nogemONFT721.tokenCounter();
        uint256 after_ownerBalance = nogemONFT721.balanceOf(minter);
        uint256 after_earnings = nogemONFT721.feeEarnedAmount();
        uint256 earned = after_earnings - before_earnings;
        uint256 after_referrerTransactionsCount = nogemONFT721.referredTransactionsCount(referrer);
        uint256 after_referrerEarnings = nogemONFT721.referrersEarnedAmount(referrer);

        assertEq(nogemONFT721.ownerOf(nextTokenId), minter, "Incorrect token owner");
        assertEq(before_tokenCounter + 1, after_tokenCounter, "Token counter is not updated");
        assertEq(before_ownerBalance + 1, after_ownerBalance, "Owner balance is not updated");
        assertEq(earned, MINT_FEE - referrerEarnings, "Mint fee is not collected");
        assertEq(after_referrerTransactionsCount - before_referrerTransactionsCount, 1, "Referrer transactions is not updated");
        assertEq(after_referrerEarnings - before_referrerEarnings, referrerEarnings, "Referrer earnings is not updated");
    }

    /// @custom:test Fail mint ONFT with referrer address because of incorrect referrer
    /// @dev See {L2PortalONFT721-mint}
    function test_mint_withReferrer_fail_senderReferrer() public {
        _error = ERC721ReceiveError.None;
        address referrer = address(this);

        vm.expectRevert(abi.encodeWithSelector(L2PortalONFT721_CoreError.selector, ERROR_INVALID_REFERER));
        nogemONFT721.mint{value: MINT_FEE}(referrer);
    }

    ////////////////////
    ////// BRIDGE //////
    ////////////////////

    /// @custom:test Bridge ONFT
    /// @dev See {L2PortalONFT721-sendFrom}
    function test_sendFrom_success() public mintBeforeTest {
        address sender = address(this);
        uint256 before_tokenCounter = nogemONFT721.tokenCounter();
        uint256 before_ownerBalance = nogemONFT721.balanceOf(sender);
        uint256 before_earnings = nogemONFT721.feeEarnedAmount();
        uint256 tokenId = before_tokenCounter - 1;

        (uint256 nativeFee, ) = nogemONFT721.estimateSendFee(
            DST_CHAIN_ID,
            abi.encodePacked(address(this)),
            tokenId,
            false,
            abi.encodePacked(LZ_VERSION, MIN_GAS_TO_TRANSFER)
        );

        vm.expectEmit();
        emit BridgeFeeEarned(sender, DST_CHAIN_ID, BRIDGE_FEE);
        nogemONFT721.sendFrom{value: nativeFee + MIN_GAS_TO_TRANSFER}(
            address(this),
            DST_CHAIN_ID,
            abi.encodePacked(address(this)),
            tokenId,
            payable(address(this)),
            address(0x0),
            abi.encodePacked(LZ_VERSION, MIN_GAS_TO_TRANSFER)
        );

        uint256 after_tokenCounter = nogemONFT721.tokenCounter();
        uint256 after_ownerBalance = nogemONFT721.balanceOf(sender);
        uint256 after_earnings = nogemONFT721.feeEarnedAmount();
        uint256 earned = after_earnings - before_earnings;

        assertEq(nogemONFT721.ownerOf(tokenId), address(nogemONFT721), "Token is not transferred");
        assertEq(before_tokenCounter, after_tokenCounter, "Counter updated");
        assertEq(before_ownerBalance - 1, after_ownerBalance, "Balance is not updated");
        assertEq(earned, BRIDGE_FEE, "Earnings are not updated");
    }

    /// @custom:test Bridge batch of ONFTs
    /// @dev See {L2PortalONFT721-sendBatchFrom}
    function test_sendBatchFrom_success() public mintAmountBeforeTest(DST_BATCH_LIMIT) {
        address sender = address(this);
        uint256 before_tokenCounter = nogemONFT721.tokenCounter();
        uint256 before_ownerBalance = nogemONFT721.balanceOf(sender);
        uint256 before_earnings = nogemONFT721.feeEarnedAmount();
        uint256 tokensCount = DST_BATCH_LIMIT;
        uint256[] memory tokenIds = new uint256[](tokensCount);
        for (uint256 i; i < tokensCount; i++) {
            tokenIds[i] = i;
        }

        (uint256 nativeFee, ) = nogemONFT721.estimateSendBatchFee(
            DST_CHAIN_ID,
            abi.encodePacked(PAYABLE_ADDRESS),
            tokenIds,
            false,
            abi.encodePacked(LZ_VERSION, MIN_GAS_TO_TRANSFER)
        );

        vm.expectEmit();
        emit BridgeFeeEarned(sender, DST_CHAIN_ID, BRIDGE_FEE);
        nogemONFT721.sendBatchFrom{value: nativeFee + MIN_GAS_TO_TRANSFER}(
            address(this),
            DST_CHAIN_ID,
            abi.encodePacked(PAYABLE_ADDRESS),
            tokenIds,
            payable(address(this)),
            address(0x0),
            abi.encodePacked(LZ_VERSION, MIN_GAS_TO_TRANSFER)
        );

        uint256 after_tokenCounter = nogemONFT721.tokenCounter();
        uint256 after_ownerBalance = nogemONFT721.balanceOf(sender);
        uint256 after_earnings = nogemONFT721.feeEarnedAmount();
        uint256 earned = after_earnings - before_earnings;

        for (uint256 i; i < tokensCount; i++) {
            assertEq(nogemONFT721.ownerOf(tokenIds[i]), address(nogemONFT721), "Token is not transferred");
        }
        assertEq(before_tokenCounter, after_tokenCounter, "Counter updated");
        assertEq(before_ownerBalance - tokensCount, after_ownerBalance, "Balance is not updated");
        assertEq(earned, BRIDGE_FEE, "Earnings are not updated");
    }

    /// @custom:test Fail bridge batch of ONFTs because of empty list of sent tokens
    /// @dev See {L2PortalONFT721-sendBatchFrom}
    function test_sendBatchFrom_fail_emptyTokenIds() public {
        uint256[] memory tokenIds;

        vm.expectRevert("tokenIds[] is empty");
        nogemONFT721.sendBatchFrom{value: BRIDGE_FEE + 0.1 ether}(
            address(this),
            DST_CHAIN_ID,
            abi.encodePacked(PAYABLE_ADDRESS),
            tokenIds,
            payable(address(this)),
            address(0x0),
            abi.encodePacked(LZ_VERSION, MIN_GAS_TO_TRANSFER * 4)
        );
    }

    /// @custom:test Fail bridge batch of ONFTs because of exceeding batch limit
    /// @dev See {L2PortalONFT721-sendBatchFrom}
    function test_sendBatchFrom_fail_exceedsBatchLimit() public {
        uint256[] memory tokenIds = new uint256[](DST_BATCH_LIMIT + 1);

        vm.expectRevert("batch size exceeds dst batch limit");
        nogemONFT721.sendBatchFrom{value: BRIDGE_FEE + 0.1 ether}(
            address(this),
            DST_CHAIN_ID,
            abi.encodePacked(PAYABLE_ADDRESS),
            tokenIds,
            payable(address(this)),
            address(0x0),
            abi.encodePacked(LZ_VERSION, MIN_GAS_TO_TRANSFER * 4)
        );
    }

    ///////////////////
    ////// CLAIM //////
    ///////////////////

    /// @custom:test Claim fee earnings
    /// @dev See {L2PortalONFT721-claimFeeEarnings}
    function test_claimFeeEarnings_success() public mintBeforeTest {
        uint256 before_feeCollectorBalance = PAYABLE_ADDRESS.balance;
        uint256 before_feeEarnedAmount = nogemONFT721.feeEarnedAmount();
        uint256 before_feeClaimedAmount = nogemONFT721.feeClaimedAmount();

        vm.startPrank(PAYABLE_ADDRESS);
        vm.expectEmit();
        emit FeeEarningsClaimed(PAYABLE_ADDRESS, before_feeEarnedAmount);
        nogemONFT721.claimFeeEarnings();
        vm.stopPrank();

        uint256 after_feeCollectorBalance = PAYABLE_ADDRESS.balance;
        uint256 after_feeEarnedAmount = nogemONFT721.feeEarnedAmount();
        uint256 after_feeClaimedAmount = nogemONFT721.feeClaimedAmount();

        assertEq(after_feeCollectorBalance - before_feeCollectorBalance, MINT_FEE, "Fee collector balace is incorrect");
        assertEq(after_feeEarnedAmount, 0, "Fee earned amount is not 0 after claim");
        assertEq(after_feeClaimedAmount - before_feeClaimedAmount, MINT_FEE, "Fee claimed amount is incorrect");
    }

    /// @custom:test Fail claiming fee earnings because of calling claim from incorrect address
    /// @dev See {L2PortalONFT721-claimFeeEarnings}
    function test_claimFeeEarnings_fail_calledByIncorrectAddress() public mintBeforeTest {
        vm.expectRevert(abi.encodeWithSelector(L2PortalONFT721_CoreError.selector, ERROR_NOT_FEE_COLLECTOR));
        nogemONFT721.claimFeeEarnings();
    }

    /// @custom:test Fail claiming fee earnings because of incorrect earned amount
    /// @dev See {L2PortalONFT721-claimFeeEarnings}
    function test_claimFeeEarnings_fail_nothingToClaim() public {
        vm.startPrank(PAYABLE_ADDRESS);
        vm.expectRevert(abi.encodeWithSelector(L2PortalONFT721_CoreError.selector, ERROR_NOTHING_TO_CLAIM));
        nogemONFT721.claimFeeEarnings();
        vm.stopPrank();
    }

    /// @custom:test Fail claiming fee earnings because of failing funds transfer
    /// @dev See {L2PortalONFT721-claimFeeEarnings}
    function test_claimFeeEarnings_fail_failedSendEth() public mintBeforeTest {
        nogemONFT721.setFeeCollector(address(lzEndpointMock));

        vm.startPrank(address(lzEndpointMock));
        vm.expectRevert("Failed to send Ether");
        nogemONFT721.claimFeeEarnings();
        vm.stopPrank();
    }

    /// @custom:test Claiming referral earnings
    /// @dev See {L2PortalONFT721-claimReferrerEarnings}
    function test_claimReferralEarnings_success() public
        mintRefBeforeTest(PAYABLE_ADDRESS, 0, MAX_REFERRAL_EARNING_BIPS)
    {
        address referrer = PAYABLE_ADDRESS;
        uint256 referrerEarnings = nogemONFT721.referrersEarnedAmount(referrer);

        vm.startPrank(referrer);
        vm.expectEmit();
        emit ReferrerEarningsClaimed(referrer, referrerEarnings);
        nogemONFT721.claimReferrerEarnings();
        vm.stopPrank();

        uint256 after_referrerEarnings = nogemONFT721.referrersEarnedAmount(referrer);
        uint256 after_referrerClaimed = nogemONFT721.referrersClaimedAmount(referrer);

        assertEq(after_referrerEarnings, 0, "Referrer earnings is not 0 after claim");
        assertEq(after_referrerClaimed, referrerEarnings, "Referrer claimed amount is not updated");
    }

    /// @custom:test Fail claiming referral earnings because of failed send funds
    /// @dev See {L2PortalONFT721-claimReferrerEarnings}
    function test_claimReferralEarnings_fail_failedSendEth() public
    mintRefBeforeTest(address(lzEndpointMock), 0, MAX_REFERRAL_EARNING_BIPS)
    {
        address referrer = address(lzEndpointMock);

        vm.startPrank(referrer);
        vm.expectRevert("Failed to send Ether");
        nogemONFT721.claimReferrerEarnings();
        vm.stopPrank();
    }

    /// @custom:test Fail claiming referral earnings because of insufficient earnings
    /// @dev See {L2PortalONFT721-claimReferrerEarnings}
    function test_claimReferralEarnings_fail_nothingToClaim() public {
        address referrer = PAYABLE_ADDRESS;

        vm.startPrank(referrer);
        vm.expectRevert(abi.encodeWithSelector(L2PortalONFT721_CoreError.selector, ERROR_NOTHING_TO_CLAIM));
        nogemONFT721.claimReferrerEarnings();
        vm.stopPrank();
    }

    ///////////////////////////////
    ////// SETTERS / GETTERS //////
    ///////////////////////////////

    /// @custom:test Setting new mint fee
    /// @dev See {L2PortalONFT721-setMintFee}
    function test_setMintFee() public {
        uint256 before_mintFee = nogemONFT721.mintFee();
        uint256 newMintFee = MINT_FEE * 2;

        vm.expectEmit();
        emit MintFeeChanged(before_mintFee, newMintFee);
        nogemONFT721.setMintFee(newMintFee);

        uint256 after_mintFee = nogemONFT721.mintFee();

        assertEq(after_mintFee, newMintFee, "Mint fee is not changed");
    }

    /// @custom:test Setting new bridge fee
    /// @dev See {L2PortalONFT721-setBridgeFee}
    function test_setBridgeFee() public {
        uint256 before_bridgeFee = nogemONFT721.bridgeFee();
        uint256 newBridgeFee = BRIDGE_FEE * 2;

        vm.expectEmit();
        emit BridgeFeeChanged(before_bridgeFee, newBridgeFee);
        nogemONFT721.setBridgeFee(newBridgeFee);

        uint256 after_bridgeFee = nogemONFT721.bridgeFee();

        assertEq(after_bridgeFee, newBridgeFee, "Bridge fee is not changed");
    }

    /// @custom:test Setting new referral earning bips
    /// @dev See {L2PortalONFT721-setReferralEarningBips}
    function test_setReferralEarningBips_success() public {
        uint256 before_referralEarningBips = nogemONFT721.referralEarningBips();
        uint256 newReferralEarningBips = MAX_REFERRAL_EARNING_BIPS;

        vm.expectEmit();
        emit ReferralEarningBipsChanged(before_referralEarningBips, newReferralEarningBips);
        nogemONFT721.setReferralEarningBips(newReferralEarningBips);

        uint256 after_referralEarningBips = nogemONFT721.referralEarningBips();

        assertEq(after_referralEarningBips, newReferralEarningBips);
    }

    /// @custom:test Fail to set new referral earning bips because of high bips value
    /// @dev See {L2PortalONFT721-setReferralEarningBips}
    function test_setReferralEarningBips_fail_bipsTooHigh() public {
        uint256 newReferralEarningBips = MAX_REFERRAL_EARNING_BIPS * 2;

        vm.expectRevert(abi.encodeWithSelector(L2PortalONFT721_CoreError.selector, ERROR_REFERRAL_BIPS_TOO_HIGH));
        nogemONFT721.setReferralEarningBips(newReferralEarningBips);
    }

    /// @custom:test Setting new earning bips for referrer
    /// @dev See {L2PortalONFT721-setEarningBipsForReferrer}
    function test_setEarningBipsForReferrer_success() public {
        address referrer = PAYABLE_ADDRESS;
        uint256 newReferrerEarningBips = MAX_REFERRER_EARNING_BIPS;

        vm.expectEmit();
        emit EarningBipsForReferrerChanged(referrer, newReferrerEarningBips);
        nogemONFT721.setEarningBipsForReferrer(referrer, newReferrerEarningBips);

        uint256 after_earningBipsForReferrer = nogemONFT721.referrersEarningBips(PAYABLE_ADDRESS);

        assertEq(after_earningBipsForReferrer, newReferrerEarningBips, "Referrer earning bips is not updated");
    }

    /// @custom:test Fail to set new earning bips for referrer because of high bips value
    /// @dev See {L2PortalONFT721-setEarningBipsForReferrer}
    function test_setEarningBipsForReferrer_fail_bipsTooHigh() public {
        address referrer = PAYABLE_ADDRESS;
        uint256 newReferrerEarningBips = MAX_REFERRER_EARNING_BIPS * 2;

        vm.expectRevert(abi.encodeWithSelector(L2PortalONFT721_CoreError.selector, ERROR_REFERRAL_BIPS_TOO_HIGH));
        nogemONFT721.setEarningBipsForReferrer(referrer, newReferrerEarningBips);
    }

    /// @custom:test Setting new earning bips for referrers
    /// @dev See {L2PortalONFT721-setEarningBipsForReferrersBatch}
    function test_setEarningBipsForReferrersBatch_success() public {
        uint256 referrersCount = 1;
        address[] memory referrers = new address[](referrersCount);
        for (uint256 i; i < referrersCount; i++) {
            referrers[i] = PAYABLE_ADDRESS;
        }
        uint256 newReferrerEarningBips = MAX_REFERRER_EARNING_BIPS;

        vm.expectEmit();
        emit EarningBipsForReferrersChanged(referrers, newReferrerEarningBips);
        nogemONFT721.setEarningBipsForReferrersBatch(referrers, newReferrerEarningBips);

        for (uint256 i; i < referrers.length; i++) {
            uint256 after_earningBipsForReferrer = nogemONFT721.referrersEarningBips(referrers[i]);
            assertEq(after_earningBipsForReferrer, newReferrerEarningBips, "Referrer earning bips is not updated");
        }
    }

    /// @custom:test Setting new fee collector
    /// @dev See {L2PortalONFT721-setFeeCollector}
    function test_setFeeCollector_success() public {
        address before_feeCollector = nogemONFT721.feeCollector();
        address newFeeCollector = PAYABLE_ADDRESS;

        vm.expectEmit();
        emit FeeCollectorChanged(before_feeCollector, newFeeCollector);
        nogemONFT721.setFeeCollector(newFeeCollector);

        address after_feeCollector = nogemONFT721.feeCollector();

        assertEq(after_feeCollector, newFeeCollector, "Fee collector is not changed");
    }

    /// @custom:test Fail to set new fee collector because of invalid address
    /// @dev See {L2PortalONFT721-setFeeCollector}
    function test_setFeeCollector_fail_invalidCollectorAddress() public {
        address newFeeCollector = address(0x0);

        vm.expectRevert(abi.encodeWithSelector(L2PortalONFT721_CoreError.selector, ERROR_INVALID_COLLECTOR_ADDRESS));
        nogemONFT721.setFeeCollector(newFeeCollector);
    }

    /// @custom:test Locking base URI
    /// @dev See {L2PortalONFT721-setTokenBaseURILocked}
    function test_setTokenBaseURILocked_success() public {
        bool before_tokenURILocked = nogemONFT721.tokenBaseURILocked();
        assertFalse(before_tokenURILocked);
        bool locked = true;

        vm.expectEmit();
        emit TokenURILocked(locked);
        nogemONFT721.setTokenBaseURILocked(locked);

        bool after_tokenURILocked = nogemONFT721.tokenBaseURILocked();

        assertTrue(after_tokenURILocked);
    }

    /// @custom:test Fail locking base URI because of URI is already locked
    /// @dev See {L2PortalONFT721-setTokenBaseURILocked}
    function test_setTokenBaseURILocked_fail_tokenURILocked() public {
        bool locked = true;
        nogemONFT721.setTokenBaseURILocked(locked);

        vm.expectRevert(abi.encodeWithSelector(L2PortalONFT721_CoreError.selector, ERROR_INVALID_URI_LOCK_STATE));
        nogemONFT721.setTokenBaseURILocked(locked);
    }

    /// @custom:test Set new base URI
    /// @dev See {L2PortalONFT721-setTokenBaseURI}
    function test_setTokenBaseURI_success() public {
        string memory before_baseTokenURI = "";
        string memory newBaseTokenURI = IPFS_URI;
        string memory fileExtension = ".png";

        vm.expectEmit();
        emit TokenURIChanged(before_baseTokenURI, newBaseTokenURI, fileExtension);
        nogemONFT721.setTokenBaseURI(newBaseTokenURI, fileExtension);
    }

    /// @custom:test Fail set new base URI because of token URI is locked
    /// @dev See {L2PortalONFT721-setTokenBaseURI}
    function test_setTokenBaseURI_fail_tokenURILocked() public {
        nogemONFT721.setTokenBaseURILocked(true);

        string memory newBaseTokenURI = IPFS_URI;
        string memory fileExtension = ".png";

        vm.expectRevert(abi.encodeWithSelector(L2PortalONFT721_CoreError.selector, ERROR_INVALID_URI_LOCK_STATE));
        nogemONFT721.setTokenBaseURI(newBaseTokenURI, fileExtension);
    }

    /// @custom:test Get token URI
    /// @dev See {L2PortalONFT721-tokenURI}
    function test_tokenURI_success() public mintBeforeTest {
        nogemONFT721.setTokenBaseURI(IPFS_URI, ".png");
        uint256 tokenId = nogemONFT721.tokenCounter() - 1;

        string memory tokenURI = nogemONFT721.tokenURI(tokenId);

        assertEq(tokenURI, "https://ipfs.io/ipfs/0.png", "Invalid token URI");
    }

    /// @custom:test Fail get token URI because of token id is not exist
    /// @dev See {L2PortalONFT721-tokenURI}
    function test_tokenURI_fail_invalidTokenId() public {
        uint256 tokenId = 10;

        vm.expectRevert(abi.encodeWithSelector(L2PortalONFT721_CoreError.selector, ERROR_INVALID_TOKEN_ID));
        nogemONFT721.tokenURI(tokenId);
    }

    /********************
    * TEST HELPERS
    */

    /**
    * @notice Shortcut for minting 1 token before running test
    * @dev Set _error to ERC721ReceiveError.None to make sure tokens will be minted successfully
    */
    modifier mintBeforeTest {
        _error = ERC721ReceiveError.None;
        nogemONFT721.mint{value: MINT_FEE}();
        _;
    }

    /**
    * @notice Shortcut for minting `amount` tokens before running test
    * @dev Set _error to ERC721ReceiveError.None to make sure tokens will be minted successfully
    *
    * @param amount   The amount of tokens that should has been minted
    */
    modifier mintAmountBeforeTest(uint256 amount) {
        _error = ERC721ReceiveError.None;
        for (uint256 i; i < amount; i++) {
            nogemONFT721.mint{value: MINT_FEE}();
        }
        _;
    }

    /**
    * @notice Shortcut for minting `amount` tokens with referrer `referrer` before running test
    * @dev Set _error to ERC721ReceiveError.None to make sure tokens will be minted successfully
    *
    * @param referrer      The referrer address
    * @param referralBips  Refferal shares from mint
    * @param referrerBips  Refferer shares from mint
    */
    modifier mintRefBeforeTest(
        address referrer,
        uint256 referralBips,
        uint256 referrerBips
    ) {
        _error = ERC721ReceiveError.None;
        nogemONFT721.setReferralEarningBips(referralBips);
        nogemONFT721.setEarningBipsForReferrer(referrer, referrerBips);
        nogemONFT721.mint{value: MINT_FEE}(referrer);
        _;
    }

    /********************
    * IERC721Receiver Mock implementation
    */

    /**
    * @dev Mocks for onERC721Received behaviour
    * @dev None                     Successful receive
    * @dev RevertWithMessage        Revert receive with error message
    * @dev RevertWithoutMessage     Revert receive
    * @dev Panic                    Cause panic error (eg. division by zero)
    */
    enum ERC721ReceiveError {
        None,
        RevertWithMessage,
        RevertWithoutMessage,
        Panic
    }

    ERC721ReceiveError private _error;

    bytes4 public constant ERC721_RECEIVE_RETVAL = IERC721Receiver.onERC721Received.selector;

    /**
    * @dev See {IERC721Receiver-onERC721Received}
    *
    * @notice Mock IERC721Receiver logic
    * @dev Customize _error to imitate different behaviour
    */
    function onERC721Received(
        address, // operator
        address, // from
        uint256, // tokenId
        bytes memory // data
    ) public view override returns (bytes4) {
        if (_error == ERC721ReceiveError.RevertWithMessage) {
            revert("ERC721ReceiverMock: reverting");
        } else if (_error == ERC721ReceiveError.RevertWithoutMessage) {
            revert();
        } else if (_error == ERC721ReceiveError.Panic) {
            uint256 a = uint256(0) / uint256(0);
            a;
        }
        return ERC721_RECEIVE_RETVAL;
    }

    /// Impl for receiving funds

    fallback() external {}

    receive() external payable {}
}
