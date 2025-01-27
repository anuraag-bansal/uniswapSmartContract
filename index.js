const {Web3} = require('web3');

const web3 = new Web3('https://sepolia.infura.io/v3/c9dbee06f9f4413cb35b85ef7178789f');

const contractABI = require("./uniswap.contract.abi.json")
const contractAddress = '0x2c13ef1683f8c8488ccd9f697c4f511b28a47f2a';


const blockNumber = 7583716;

async function getContractData() {
    try {

        const contract = new web3.eth.Contract(contractABI, contractAddress);
         contract.defaultBlock = blockNumber;

        const data = await contract.methods.getUniswapV2Position("0x90427805C25c749f6ea6d7d9017841412F4A6434", "0x9984b4b4e408e8d618a879e5315bd30952c89103").call(
            // {
            // from:"0x34BdF5CbE399f109C92ECbB2795ebd105cB5ae23"
            // },
            // blockNumber
        );
        console.log('Data at block', blockNumber, ':', data);
    } catch (error) {
        console.error('Error fetching data:', error);
    }
}

;(async () => {
    await getContractData();
})()
