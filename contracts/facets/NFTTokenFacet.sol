// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "../libraries/LibAppStorage.sol";

contract NFTTokenFacet {
     
     LibAppStorage.AppStorage s;

     using Strings for uint256;

    constructor() ERC721("MyToken", "MTK") {}

    function balanceOf(address owner) public view virtual returns (uint256) {
        
        return s._balances[owner];
    }

    function ownerOf(uint256 tokenId) public view virtual returns (address) {
        return _requireOwned(tokenId);
    }

    function name() public view virtual returns (string memory) {
        return "MyToken";
    }

    function symbol() public view virtual returns (string memory) {
        return "MTK";
    }

   function tokenURI(uint256 tokenId) public view virtual returns (string memory) {
        _requireOwned(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string.concat(baseURI, tokenId.toString()) : "";
    }

    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    function approve(address to, uint256 tokenId) public virtual {
        _approve(to, tokenId, _msgSender());
    }

    function getApproved(uint256 tokenId) public view virtual returns (address) {
        _requireOwned(tokenId);

        return _getApproved(tokenId);
    }

   function setApprovalForAll(address operator, bool approved) public virtual {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

   function isApprovedForAll(address owner, address operator) public view virtual returns (bool) {
        return s._operatorApprovals[owner][operator];
    }

    function transferFrom(address from, address to, uint256 tokenId) public virtual {
        if (to == address(0)) {
            revert ERC721InvalidReceiver(address(0));
        }
        // Setting an "auth" arguments enables the `_isAuthorized` check which verifies that the token exists
        // (from != 0). Therefore, it is not needed to verify that the return value is not 0 here.
        address previousOwner = _update(to, tokenId, _msgSender());
        if (previousOwner != from) {
            revert ERC721IncorrectOwner(from, tokenId, previousOwner);
        }
    }

   function safeTransferFrom(address from, address to, uint256 tokenId) public {
        safeTransferFrom(from, to, tokenId, "");
    }

    // function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual {
    //     transferFrom(from, to, tokenId);
    //     ERC721Utils.checkOnERC721Received(_msgSender(), from, to, tokenId, data);
    // }

    
    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        return s._owners[tokenId];
    }

    
    function _getApproved(uint256 tokenId) internal view virtual returns (address) {
        return s._tokenApprovals[tokenId];
    }

   
    function _isAuthorized(address owner, address spender, uint256 tokenId) internal view virtual returns (bool) {
        return
            spender != address(0) &&
            (owner == spender || isApprovedForAll(owner, spender) || _getApproved(tokenId) == spender);
    }

    
    function _increaseBalance(address account, uint128 value) internal virtual {
        unchecked {
            s._balances[account] += value;
        }
    }

    function _update(address to, uint256 tokenId, address auth) internal virtual returns (address) {
        address from = _ownerOf(tokenId);

        // Perform (optional) operator check
        if (auth != address(0)) {
            _checkAuthorized(from, auth, tokenId);
        }

        // Execute the update
        if (from != address(0)) {
            // Clear approval. No need to re-authorize or emit the Approval event
            _approve(address(0), tokenId, address(0), false);

            unchecked {
                s._balances[from] -= 1;
            }
        }

        if (to != address(0)) {
            unchecked {
                _balances[to] += 1;
            }
        }

        s._owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        return from;
    }

       function _safeMint(address to, uint256 tokenId) internal {
        _safeMint(to, tokenId, "");
    }


     function _safeTransfer(address from, address to, uint256 tokenId) internal {
        _safeTransfer(from, to, tokenId, "");
    }


    function _approve(address to, uint256 tokenId, address auth) internal {
        _approve(to, tokenId, auth, true);
    }


        function _generateNFT(uint256 _tokenId) internal pure returns (string memory) {
        bytes memory svg = abi.encodePacked(
            '<svg id="sw-js-blob-svg" viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">',
            '<defs><linearGradient id="sw-gradient"><stop id="stop1" stop-color="rgb(248, 117, 55)" offset="0%"></stop><stop id="stop2" stop-color="rgb(251, 168, 31)" offset="100%"></stop></linearGradient></defs>',
            '<path fill="url(#sw-gradient)" d="M 17.5 -19.2 C 25 -14.5 35.1 -11.2 37.9 -5.2 C 40.7 0.7 36.1 9.5 30.4 15.7 C 24.6 22 17.7 25.8 10.8 27.3 C 3.9 28.8 -3 28 -10 26.1 C -16.9 24.1 -24 21 -29.9 15.1 C -35.8 9.3 -40.5 0.7 -38.3 -5.9 C -36.2 -12.5 -27.1 -16.9 -19.5 -21.7 C -12 -26.4 -6 -31.5 -0.5 -30.8 C 5 -30.2 9.9 -24 17.5 -19.2 Z" transform="matrix(1,0,0,1,50,50)" style="transition: all 0.3s ease 0s" stroke="url(#sw-gradient)"></path>',
            '<text font-size="12" x="25" y="50" fill="rgb(255, 255, 255)">',
            _tokenId.toString(),
            "</text></svg>"
        );

        return string(abi.encodePacked("data:image/svg+xml;base64,", Base64.encode(svg)));
    }

    function getTokenURI(uint256 _tokenId) public pure returns (string memory) {
        string memory id = _tokenId.toString();
        bytes memory dataURI = abi.encodePacked(
            "{",
            '"name": "DevFarunaNFT #',
            id,
            '",',
            '"description": "DevFaruna giving out free NFTs ',
            id,
            '",',
            '"image": "',
            _generateNFT(_tokenId),
            '"',
            "}"
        );

        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(dataURI)));
    }

    function _safeMint(address _to) internal {
        s._tokenIds++;
        _mint(_to, _tokenIds);
        _setTokenURI(s._tokenIds, getTokenURI(s._tokenIds));
    }
    
    // function _checkAuthorized(address owner, address spender, uint256 tokenId) internal view virtual {
    //     if (!_isAuthorized(owner, spender, tokenId)) {
    //         if (owner == address(0)) {
    //             revert ERC721NonexistentToken(tokenId);
    //         } else {
    //             revert ERC721InsufficientApproval(spender, tokenId);
    //         }
    //     }
    // }

    // function _mint(address to, uint256 tokenId) internal {
    //     if (to == address(0)) {
    //         revert ERC721InvalidReceiver(address(0));
    //     }
    //     address previousOwner = _update(to, tokenId, address(0));
    //     if (previousOwner != address(0)) {
    //         revert ERC721InvalidSender(address(0));
    //     }
    // }

 

    
    // function _safeMint(address to, uint256 tokenId, bytes memory data) internal virtual {
    //     _mint(to, tokenId);
    //     ERC721Utils.checkOnERC721Received(_msgSender(), address(0), to, tokenId, data);
    // }

    
    // function _burn(uint256 tokenId) internal {
    //     address previousOwner = _update(address(0), tokenId, address(0));
    //     if (previousOwner == address(0)) {
    //         revert ERC721NonexistentToken(tokenId);
    //     }
    // }

    
    // function _transfer(address from, address to, uint256 tokenId) internal {
    //     if (to == address(0)) {
    //         revert ERC721InvalidReceiver(address(0));
    //     }
    //     address previousOwner = _update(to, tokenId, address(0));
    //     if (previousOwner == address(0)) {
    //         revert ERC721NonexistentToken(tokenId);
    //     } else if (previousOwner != from) {
    //         revert ERC721IncorrectOwner(from, tokenId, previousOwner);
    //     }
    // }

    
   

   
    // function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal virtual {
    //     _transfer(from, to, tokenId);
    //     ERC721Utils.checkOnERC721Received(_msgSender(), from, to, tokenId, data);
    // }

    
    

   
    // function _approve(address to, uint256 tokenId, address auth, bool emitEvent) internal virtual {
    //     // Avoid reading the owner unless necessary
    //     if (emitEvent || auth != address(0)) {
    //         address owner = _requireOwned(tokenId);

    //         // We do not use _isAuthorized because single-token approvals should not be able to call approve
    //         if (auth != address(0) && owner != auth && !isApprovedForAll(owner, auth)) {
    //             revert ERC721InvalidApprover(auth);
    //         }

    //         if (emitEvent) {
    //             emit Approval(owner, to, tokenId);
    //         }
    //     }

    //     s._tokenApprovals[tokenId] = to;
    // }


    // function _setApprovalForAll(address owner, address operator, bool approved) internal virtual {
    //     if (operator == address(0)) {
    //         revert ERC721InvalidOperator(operator);
    //     }
    //     s._operatorApprovals[owner][operator] = approved;
    //     emit ApprovalForAll(owner, operator, approved);
    // }

   
    // function _requireOwned(uint256 tokenId) internal view returns (address) {
    //     address owner = _ownerOf(tokenId);
    //     if (owner == address(0)) {
    //         revert ERC721NonexistentToken(tokenId);
    //     }
    //     return owner;
    // }
    


}
