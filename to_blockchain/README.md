# timesheet-backend/to_blockchain

Basic "skeleton" implementation of storage smart contract + simple interface to store data on smart contract

To test the following code you need Node.js and NPM

run

```bash
npm install -g ethereumjs-testrpc
```

then start it

```bash
testrpc
```
In different terminal window in to_blockchain directory run

```bash
npm init
```

```bash
npm install ethereum/web3.js --save
```

copy code from data_storage_contract.sol to http://remix.ethereum.org/ compile code and deploy it to "Web3 Provider" of your test network

change 

```
var data_storage = data_storage_contract.at("YOU SMART CONTRACT'S ADRESS");
```
run index.html

now you can store data in smart contract in the format : address, string, string

run getProjects on Remix to see smart contracts of projects in the "database" 