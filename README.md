# copyright-nft
> NFT that represents the Copyright of a song.

With this ERC-721 token you can demostrate the ownership of a song, and you will be able to create new ERC-20 tokens to consume this song and collect profits for its use.

## 🔍 Overview
Main properties of this ERC-721 token:
- Every NFT has a unique token ID and owner, and it stores the metadata information of the song.
- You can transfer the ownership of the NFT token to another user.
- The owner of the smart contract can adminstrate the ERC-721 token (assign new minter user, transfer smart contract ownership, etc).
- The minter account can mint new tokens.
- The copyright users (owners of the NFTs) can mint a new token to themselves calling the `redeem()` function. This function uses the ERC-712 signature of the minter to verify that the user can mint a new token. This is also called *lazy minting*. With this, the minter won't pay the fees for the token minting, it will be paid by the users.
- When a new NFT is minted, it will store the metadata of the song (name, album, artist, song URL), and a new ERC-20 token will be created. This ERC-20 token can be used later to consume the song (THIS PART OF THE PROCESS IS NOT PART OF THE CURRENT PROJECT).
- The final users can buy an ERC-20 token to consume the song calling the `buy()` function. With this fuction, we need to send 1 MATIC to buy the ERC-20 token. This MATIC token will be added to the copyright users (owners of the NFTs) balance.
- The copyright users (owners of the NFTs) will be able to collect their copyright gains calling the `collectCopyrightGains()`. This function transfers the gains for the copyright of the song to the owner of the NFT.

## 📝 Lazy minting
The process of minting NFTs is expensive. With this, if all the minting is done by the minter user, he will need to pay a lot of fees. These costs are too high for many use-cases, particularly if a system administrator is considering minting hundreds or thousands of NFTs.

This NFT uses lazy minting to let copyright users (owners of the NFTs) mint their own assets calling the `redeem()` function. With this, the costs of minting new tokens will be paid by the users that want to own an NFT.

Using cryptographic primitives, the minter user can sign “minting authorizations” that later allow a user to do the minting themselves. These signatures are free to produce, as they do not require an on-chain transaction. They guarantee that the minter keeps total control over the NFTs, and ensure no token can be minted without prior approval.

## 📚 Installation

To install this repository, run:
```
yarn install
```

### Configuration of .env file

Create the file `.env`:
```bash
cp .env.example .env
vi .env # add an account's mnemonic and an Infura API key
```

Add the following information:
```
MNEMONIC=
INFURA_API_KEY=
COINMARKETCAP_API_KEY=
MATIC_RPC=
MUMBAI_RPC=
```

To see the mnemonic or seed phrase in Metamask, [follow this instruction](https://metamask.zendesk.com/hc/en-us/articles/360015290032-How-to-Reveal-Your-Seed-Phrase).

The account associated with the mnemonic needs to have enough funds in the network where you want to interact with the smart contracts.

To add test funds:
- Matic Mumbai test network: [Polygon Faucet](https://faucet.polygon.technology/)


## 🖥️ Main commands

Compile the smart contracts:
```
yarn compile
```

Run the tests in the local hardhat network:
```
yarn test
```

Run the coverage test:
```
yarn coverage
```

Deploy the smart contracts to the local hardhat network:
```
yarn deploy:localnet
```

Deploy the smart contracts to the MATIC/Polygon main network:
```
yarn deploy:matic
```

Deploy the smart contracts to the Mumbai test network:
```
yarn deploy:mumbai
```
