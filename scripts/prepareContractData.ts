import * as fs from 'fs';
const hre = require("hardhat");

async function main(){

    const contractPath = "contracts/package/tokens/"
    const contractName = "ERC721STD"

    const sourceJSON = await hre.run("verify:etherscan-get-minimal-input", {
        sourceName: `${contractPath}${contractName}.sol`,
    })

    let contractMeta = {
        // title to show on STS
        title: "ERC721",
        // contract NAME
        name: contractName,
        verificationName: `${contractPath}${contractName}.sol:${contractName}`,
        git: "https://github.com/AlphaWallet/stl-contracts/blob/main/contracts/package/tokens/ERC721STD.sol",
        description: "This ERC721 implementation is Mintable, Burnable, Enumerable, use AccessControl, has Metadata control, can change ContractURI, supports ERC5169",
        compiler: "v0.8.20+commit.a1b79de6",
        codeformat: "solidity-standard-json-input",
        // uncomment next line to disable this contract
        // disabled: false,
        // "0" or "1"
        optimizationused: "1",
        runs: "200",
        content: sourceJSON
    }

    const contractJSONData = await fs.promises.readFile(`artifacts/${contractPath}/${contractName}.sol/${contractName}.json`, 'utf8');
    const contractJSON = JSON.parse(contractJSONData)

    contractMeta = Object.assign(contractMeta, contractJSON)

    await fs.promises.writeFile(`./${contractName}.json`, JSON.stringify([contractMeta]));
}
main()

