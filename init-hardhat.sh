#!/bin/sh

if [ $# != 1 ]; then
  echo "Please use like \n> sh init-hardhat.sh <app-name>"
  exit 1
fi

mkdir $1
cd $1

lower_app_name=`echo $1 | tr '[:upper:]' '[:lower:]'`
cat <<EOF > package.json
{
  "name": "$lower_app_name",
  "version": "0.1.0"
}
EOF

npm i -D \
  hardhat typescript ts-node \
  ethers @nomiclabs/hardhat-ethers \
  ethereum-waffle @nomiclabs/hardhat-waffle \
  chai @types/chai @types/mocha \
  typechain @typechain/hardhat @typechain/ethers-v5 \
  dotenv solidity-coverage \
  eslint eslint-config-prettier \
  @typescript-eslint/{parser,eslint-plugin}

cat <<EOF > hardhat.config.ts
import 'solidity-coverage';
import '@nomiclabs/hardhat-waffle';
import '@typechain/hardhat';

import * as dotenv from 'dotenv';
import { HardhatUserConfig, task } from 'hardhat/config';

dotenv.config();
const { RINKEBY_URL, PRIVATE_KEY } = process.env;

// Custom hardhat command
task('accounts', 'Prints the list of accounts', async (_taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();
  for (const account of accounts) {
    console.log(account.address);
  }
});

const config: HardhatUserConfig = {
  solidity: '0.8.9',
  networks: {
    rinkeby: {
      url: RINKEBY_URL,
      accounts: [\`0x\${PRIVATE_KEY}\`],
    },
    shibuya: {
      url: 'https://rpc.shibuya.astar.network:8545',
      chainId: 81,
      accounts: [\`0x\${PRIVATE_KEY}\`],
    },
  },
};

export default config;
EOF

cat <<EOF > .gitignore
/artifacts
/cache
/coverage
/node_modules
/typechain-types

/.env
/coverage.json
/package-lock.json
EOF

cat <<EOF > tsconfig.json
{
  "compilerOptions": {
    "target": "es2018",
    "module": "commonjs",
    "strict": true,
    "esModuleInterop": true,
    "declaration": true,
  },
  "include": [
    "./scripts",
    "./test",
    "./typechain-types"
  ],
  "files": [
    "./hardhat.config.ts"
  ]
}
EOF

cat <<EOF > .eslintrc.json
{
  "env": {
    "browser": false,
    "es2022": true,
    "mocha": true
  },
  "extends": [
    "eslint:recommended",
    "plugin:@typescript-eslint/recommended"
  ],
  "parser": "@typescript-eslint/parser",
  "parserOptions": {
    "ecmaVersion": "latest"
  },
  "plugins": [
    "@typescript-eslint"
  ],
  "rules": {
    "@typescript-eslint/no-unused-vars": [
      "warn",
      {
        "varsIgnorePattern": "^_",
        "argsIgnorePattern": "^_"
      }
    ]
  }
}
EOF

cat <<EOF > .solhint.json
{
  "extends": "solhint:recommended",
  "rules": {
    "compiler-version": [
      "error",
      "^0.8.9"
    ],
    "func-visibility": [
      "warn",
      {
        "ignoreConstructors": true
      }
    ]
  }
}
EOF

cat <<EOF > .env
RINKEBY_URL="https://eth-rinkeby.alchemyapi.io/v2/<api key>"
PRIVATE_KEY="<MetaMask private key>"
PUBLIC_KEY="<MetaMask public key>"
EOF

mkdir contracts
cat <<EOF > contracts/Greeter.sol
//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "hardhat/console.sol";

contract Greeter {
    string private greeting;

    constructor(string memory _greeting) {
        console.log("Deploying a Greeter with greeting:", _greeting);
        greeting = _greeting;
    }

    function greet() public view returns (string memory) {
        return greeting;
    }

    function setGreeting(string memory _greeting) public {
        console.log("Changing greeting from '%s' to '%s'", greeting, _greeting);
        greeting = _greeting;
    }
}
EOF

mkdir scripts
cat <<EOF > scripts/deploy.ts
import { ethers } from 'hardhat';

async function main() {
  const Greeter = await ethers.getContractFactory('Greeter');
  const greeter = await Greeter.deploy('Hello, Hardhat!');
  await greeter.deployed();
  console.log('Greeter deployed to:', greeter.address);
}

main().catch(error => {
  console.error(error);
  process.exitCode = 1;
});
EOF

mkdir test
cat <<EOF > test/index.ts
import { expect } from 'chai';
import { ethers } from 'hardhat';

describe('Greeter', function () {
  it("Should return the new greeting once it's changed", async function () {
    this.timeout(60_000); // set 60 second timeout

    // deploy test
    const Greeter = await ethers.getContractFactory('Greeter');
    const greeter = await Greeter.deploy('Hello, world!');
    await greeter.deployed();
    expect(await greeter.greet()).to.equal('Hello, world!');

    // setter test
    const setGreetingTx = await greeter.setGreeting('Hola, mundo!');
    await setGreetingTx.wait();
    expect(await greeter.greet()).to.equal('Hola, mundo!');
  });
});
EOF
