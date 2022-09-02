//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

//Import the Hardhat console to log messages in the terminal for debugging.
import "hardhat/console.sol";

interface MintWorldToken {
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function decimals() external view returns (uint8);
}


contract MintWorldFaucet is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable {
    //Public mint state
    bool public mintActive = false;
    //Amount of game tokens recived for burning NFTs
    uint256 public BURNING_REWARD = 1;
    //Token ID
    uint256 tokenID;


    //Last transfer mapping
    mapping(address => uint) lastTransfers;
    //Mapping to check if tokenId can be burn (json) to get token coin game (MWG)
    mapping(string => bool) checkBurnable;
 

    MintWorldToken tokenContract;

    constructor(address _addressContract) ERC721("MintMonster", "MST") {
        console.log("Hello Mintworld!");
        tokenContract = MintWorldToken(_addressContract);
    }

    //----SET VARIABLES----//

    //Sets public mint state
    function setMintState(bool val) external onlyOwner {
        mintActive = val;
    }

    //Sets amount of coin tokens to transfer when 10 NFTs are burn
    function setBurningReward(uint256 amount) external onlyOwner {
        BURNING_REWARD = amount;
    }

    //----END----//

    //----GENERATE JSON----//

    //Generate random number (0-999)
    function numRandom() private view returns(uint256){
        return uint256( keccak256( abi.encode(block.timestamp, msg.sender,tokenID))) % 1000;
    }

    //Assign json
    function checkNum(uint256 _num) private pure returns(string memory) {
        if(_num <= 247) {
            return "https://ipfs.moralis.io:2053/ipfs/QmabYRQNWPDYv8arf6DYXtsewWy8Exo3DJJnTNuVscNdKy/Stoney_637962478831665065.json";
        }
            
        else if(_num <= 496){
            return "https://ipfs.moralis.io:2053/ipfs/QmQ2YB83TfrEYpMCWES75RJRbLBjZJVPFA2mUthWZy49Qr/Firefy_637962481697783261.json";
        }

        else if(_num <= 745){
            return "https://ipfs.moralis.io:2053/ipfs/QmRe2Q4XDHTr7pbCuH6o696T5XMm2PsPwHgSLAK4bu8A6N/Watery_637962482900416213.json";
        }

        else if(_num <= 995){
            return "https://ipfs.moralis.io:2053/ipfs/QmewNL1WUJij9xqi8jo1YAeefVy7wzRjQWtiEvFftXXdvQ/Windry_637962484104104770.json";
        }
        
        else if(_num == 996){
            return "https://ipfs.moralis.io:2053/ipfs/QmUZCQW2nQu1LPMytzGrc6ugPRoGu4YBbgfe7mSzBkKzjh/Stoneman_637962479844393253.json";
        }

        else if(_num == 997){
            return "https://ipfs.moralis.io:2053/ipfs/QmfBagmaHHc93CEuKAqcQHemVrvxNwhCuZRkBZLDZ9h6D5/Lavagron_637962480480789209.json";
        }

        else if(_num == 998){
            return "https://ipfs.moralis.io:2053/ipfs/QmRFKDT9WsXP5UDsdJfB8XDxrFQbpy92TpneDvqb9DVVzB/Octopus_637962482220138079.json";
        }
        
        else{
            return "https://ipfs.moralis.io:2053/ipfs/QmYQ5bfqPP4m3EnLGxD32BbbZhvMJfW62LdySqmssy5zYN/Wingron_637962483552551184.json";
        }
    }

    //----END----//

    //----MINT NFT----//

    function mintNFT() public returns(uint256)  {
        //set last transfer to check if eligible for claiming
        uint lastTransfer = lastTransfers[msg.sender];

        require(
            lastTransfer + 24 hours <= block.timestamp,
            "You can only claim every 24 hours"
        );

        require(
            mintActive,
            "Minting paused"
        );

        //Generate random number
        uint256 _numRandom = numRandom();

        //Mapping for last trasnfer
        lastTransfers[msg.sender] = block.timestamp;

        //Mint the NFT to the sender using msg.sender.
        _safeMint(msg.sender, tokenID);

        //Set the NFTs data.
        _setTokenURI(tokenID, checkNum(_numRandom));

        //Increment token ID
        tokenID++;

        //Returns token ID
        return tokenID-1;

    }

    function getLastTransfer() public view returns(uint){
        return lastTransfers[msg.sender];
    }

    //----END----//

    //----BURN TOKENS----//

    //Add json that can be burn to get MWG. True can be burn.
    function addjson(string memory _json, bool burnable)public onlyOwner {
        checkBurnable[_json] = burnable;
    }

    //Check if the json can be burn to get MWG
    function CheckBurnable(string memory _json) public view returns(bool) {
        return checkBurnable[_json];
    }

    //Burn 10 NFT to get MWG
    function burnNFTs(uint256[] calldata tokens) external {
        require(tokens.length == 10,"You need to burn 10 NFTs to get a coin token");

        for(uint256 i=0; i < tokens.length; i++){
            require(_isApprovedOrOwner(_msgSender(), tokens[i]), "Caller is not token owner nor approved");

            require(checkBurnable[tokenURI(tokens[i])], "Check the items, you cannot burn a shining NFT");

            _burn(tokens[i]);
        }

        transferToken();
    }

    //----END----//

    //---COIN TOKEN CONTRACT---//

    function transferToken() private {
        tokenContract.transferFrom(address(tokenContract), msg.sender, mul(BURNING_REWARD, uint256(10)**tokenContract.decimals()));
    }

    //----END----//

    //----AUX FUNCTIONS----//

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }

    //----END----//

    //----OVERRIDE FUNCTIONS----//

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function tokenURI(uint256 tokenId) public view override (ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    //----END----//

}

