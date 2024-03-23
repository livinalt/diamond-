// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../contracts/interfaces/IDiamondCut.sol";
import "../contracts/facets/DiamondCutFacet.sol";
import "../contracts/facets/DiamondLoupeFacet.sol";
import "../contracts/facets/OwnershipFacet.sol";
import "forge-std/Test.sol";
import "../contracts/Diamond.sol";

import "../contracts/facets/NFTTokenFacet.sol";
import "../contracts/facets/MarketPlaceFacet.sol";

contract DiamondDeployer is Test, IDiamondCut {
    //contract types of facets to be deployed
    Diamond diamond;
    DiamondCutFacet dCutFacet;
    DiamondLoupeFacet dLoupe;
    OwnershipFacet ownerF;
    NFTTokenFacet erc721F;
    MarketPlaceFacet nftMarketF;

    address A = address(0xa);
    address B = address(0xb);

    function setUp() public {
        //deploy facets
        dCutFacet = new DiamondCutFacet();
        diamond = new Diamond(address(this), address(dCutFacet));
        dLoupe = new DiamondLoupeFacet();
        ownerF = new OwnershipFacet();
        erc721F = new NFTTokenFacet();
        nftMarketF = new MarketPlaceFacet();

        //upgrade diamond with facets

        //build cut struct
        FacetCut[] memory cut = new FacetCut[](4);

        cut[0] = (
            FacetCut({
                facetAddress: address(dLoupe),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("DiamondLoupeFacet")
            })
        );

        cut[1] = (
            FacetCut({
                facetAddress: address(ownerF),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("OwnershipFacet")
            })
        );

        cut[2] = (
            FacetCut({
                facetAddress: address(erc721F),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("NFTTokenFacet")
            })
        );

        cut[3] = (
            FacetCut({
                facetAddress: address(MarketPlaceFacet),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("MarketPlaceFacet")
            })
        );

        //upgrade diamond
        IDiamondCut(address(diamond)).diamondCut(cut, address(0x0), "");

        A = mkaddr("staker a");
        B = mkaddr("staker b");

        //call a function
        DiamondLoupeFacet(address(diamond)).facetAddresses();
    }

    function generateSelectors(
        string memory _facetName
    ) internal returns (bytes4[] memory selectors) {
        string[] memory cmd = new string[](3);
        cmd[0] = "node";
        cmd[1] = "scripts/genSelectors.js";
        cmd[2] = _facetName;
        bytes memory res = vm.ffi(cmd);
        selectors = abi.decode(res, (bytes4[]));
    }

    function testNameAndSymbol() public {
        NFTTokenFacet e = NFTTokenFacet(address(diamond));
        assertEq(e.name(), "MyToken");
        assertEq(e.symbol(), "MTK");
    }

    function testMintFunction() public {
        NFTTokenFacet e = NFTTokenFacet(address(diamond));
        switchSigner(A);

        // vm.expectEmit();
        e.mint{value: 1e16}();
        assertEq(e.balanceOf(A), 1);
        assertEq(e.ownerOf(0), A);
    }

    function testMintRevertWithLessEther() public {
        NFTTokenFacet e = NFTTokenFacet(address(diamond));
        switchSigner(A);

        vm.expectRevert("Not enough mint fee");
        e.mint{value: 0.001 ether}();
    }

    function testTransferFunction() public {
        NFTTokenFacet e = NFTTokenFacet(address(diamond));
        switchSigner(A);
        e.mint{value: 1e16}();

        e.transfer(B, 0);
        assertEq(e.ownerOf(0), B);
    }

    function testApproveFunction() public {
        NFTTokenFacet e = NFTTokenFacet(address(diamond));
        switchSigner(A);
        e.mint{value: 0.01 ether}();

        e.approve(address(diamond), 0);
        assertEq(e.getApproved(0), address(diamond));
    }

    function testListNft() public {
        NFTTokenFacet e = NFTTokenFacet(address(diamond));
        MarketPlaceFacet n = MarketPlaceFacet(address(diamond));
        switchSigner(A);
        e.mint{value: 0.01 ether}();

        n.listNft(0, 2 ether);

        assertEq(n.getNftPrice(0), 2 ether);
    }

    function testBuyNft() public {
        NFTTokenFacet e = NFTTokenFacet(address(diamond));
        MarketPlaceFacet n = MarketPlaceFacet(address(diamond));
        switchSigner(A);
        e.mint{value: 0.01 ether}();

        n.listNft(0, 2 ether);

        switchSigner(B);

        n.buyNft{value: 2 ether}(0);
        assertEq(e.ownerOf(0), B);
    }

    function testBuyNftRevertForUnlistedNft() public {
        NFTTokenFacet e = NFTTokenFacet(address(diamond));
        MarketPlaceFacet n = MarketPlaceFacet(address(diamond));
        switchSigner(A);
        e.mint{value: 0.01 ether}();

        switchSigner(B);
        vm.expectRevert("not listed");
        n.buyNft(0);
    }

    function testBuyNftRefundWithExcessValue() public {
        NFTTokenFacet e = NFTTokenFacet(address(diamond));
        MarketPlaceFacet n = MarketPlaceFacet(address(diamond));
        switchSigner(A);
        e.mint{value: 0.01 ether}();

        n.listNft(0, 5 ether);

        switchSigner(B);

        n.buyNft{value: 9 ether}(0);

        assertEq(address(B).balance, 5 ether);
    }

    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external override {}

    function mkaddr(string memory name) public returns (address) {
        address addr = address(
            uint160(uint256(keccak256(abi.encodePacked(name))))
        );
        vm.label(addr, name);
        return addr;
    }

    function switchSigner(address _newSigner) public {
        address foundrySigner = 0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38;
        if (msg.sender == foundrySigner) {
            vm.startPrank(_newSigner);
            vm.deal(_newSigner, 10 ether);
        } else {
            vm.stopPrank();
            vm.startPrank(_newSigner);
        }
    }
}
