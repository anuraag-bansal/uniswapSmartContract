const {Web3} = require('web3');
const _ = require('lodash');
const web3 = new Web3('https://sepolia.infura.io/v3/c9dbee06f9f4413cb35b85ef7178789f');

const contractABI = require("./abis/uniswap.contract.abi.json")
const contractAddress = '0xFf7DF91e15112516eCAB0EB65cB3BB5C89f327ce';

const blockNumber = 7583716;

async function getContractData() {
    try {

        const contract = new web3.eth.Contract(contractABI, contractAddress);
        contract.defaultBlock = blockNumber;

        const data = await contract.methods.getUniswapV2Position("0x90427805C25c749f6ea6d7d9017841412F4A6434", "0x9984b4b4e408e8d618a879e5315bd30952c89103").call(// {
            // from:"0x34BdF5CbE399f109C92ECbB2795ebd105cB5ae23"
            // },
            // blockNumber
        );
        console.log('Data at block', blockNumber, ':', data);
    } catch (error) {
        console.error('Error fetching data:', error);
    }
}

async function getPositionForUniswapV3(tokenId) {
    try {
        let amt0, amt1, positions;
        const contract = new web3.eth.Contract(contractABI, contractAddress);

        try {
            positions = await contract.methods.getUniswapV3Position(tokenId).call();
        } catch {
            positions = []
        }
        console.log('Positions:', positions);
        if (_.isEmpty(positions)) {
            return {
                tokenId: tokenId, amt0: 0, amt1: 0
            }
        }

        const tick = Number(positions.currentTick)
        const liquidity = Number(positions.liquidity)
        const lowerTick = Number(positions.tickLower)
        const upperTick = Number(positions.tickUpper)

        if (liquidity > 0) {
            const lowerPrice = 1.0001 ** lowerTick
            const upperPrice = 1.0001 ** upperTick
            const currentPrice = 1.0001 ** tick

            if (currentPrice < lowerPrice) {
                amt0 = liquidity * ((Math.sqrt(upperPrice) - Math.sqrt(lowerPrice)) / (Math.sqrt(lowerPrice) * Math.sqrt(upperPrice)))
                amt1 = 0
            } else if (upperPrice > currentPrice && currentPrice > lowerPrice) {
                amt0 = liquidity * ((Math.sqrt(upperPrice) - Math.sqrt(currentPrice)) / (Math.sqrt(currentPrice) * Math.sqrt(upperPrice)))
                amt1 = liquidity * (Math.sqrt(currentPrice) - Math.sqrt(lowerPrice))
            } else {
                amt0 = 0
                amt1 = liquidity * (Math.sqrt(upperPrice) - Math.sqrt(lowerPrice))
            }
        }

        if (amt0 === undefined) {
            amt0 = 0
        }
        if (amt1 === undefined) {
            amt1 = 0
        }
        console.log('Position:', tokenId, amt0, amt1, positions.owner);

        return {
            tokenId: tokenId, amt0: amt0, amt1: amt1, owner: positions.owner
        }


    } catch (error) {
        console.error('Error fetching data:', error);
    }
}

;(async () => {
    //await getContractData();
    //await getPositionForUniswapV3(1);
})()
