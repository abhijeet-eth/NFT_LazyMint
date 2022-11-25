// Reference Repo Link :   https://github.com/ipfs-shipyard/nft-school-examples/tree/main/lazy-minting

const ethers = require('ethers')
require("dotenv").config();

const SIGNING_DOMAIN_NAME = "NFT"
const SIGNING_DOMAIN_VERSION = "1"
const chainId = 5 //Goerli  
const contract = "<Contract ADdress>" // Put the contract address here from remix

const signer = new ethers.Wallet(process.env.PRIVATE_KEY) // private key

const domain = {
    name: SIGNING_DOMAIN_NAME,
    version: SIGNING_DOMAIN_VERSION,
    verifyingContract: contract,
    chainId
}


const createVoucher = async (tokenId, minPrice, uri, royaltyPercentage) => {
    const voucher = { tokenId, minPrice, uri, royaltyPercentage }
    const types = {
        NFTVoucher: [
            { name: "tokenId", type: "uint256" },
            { name: "minPrice", type: "uint256" },
            { name: "uri", type: "string" },
            { name: "royaltyPercentage", type: "uint256" }
        ]
    }
    const signature = await signer._signTypedData(domain, types, voucher)
    return {
        ...voucher,
        signature,
    }
}

const main = async () => {
    const voucher = await createVoucher(2, 200, "uriAbcd", 14) // the address is the address which receives the NFT
    console.log(`[${voucher.tokenId}, ${voucher.minPrice}, "${voucher.uri}",${voucher.royaltyPercentage} ,"${voucher.signature}"]`)
}

main();

// module.exports = {
//     LazyMinter
// }