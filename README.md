<!-- PROJECT SHIELDS -->

[![Contributors][contributors-shield]][contributors-url]
[![Forks][forks-shield]][forks-url]
[![Stargazers][stars-shield]][stars-url]
[![Issues][issues-shield]][issues-url]
[![MIT License][license-shield]][license-url]

<!-- PROJECT LOGO -->
<br />
<div align="center">
  <!-- <a href="https://github.com/mgnfy-view/simple-token-wallet-challenge">
    <img src="assets/icon.svg" alt="Logo" width="80" height="80">
  </a> -->

  <h3 align="center">Simple Token Wallet Challenge</h3>

  <p align="center">
    A simple token wallet featuring gasless transfers built for the Monad developers monthly coding challenge
    <br />
    <a href="https://github.com/mgnfy-view/simple-token-wallet-challenge/issues/new?labels=bug&template=bug-report---.md">Report Bug</a>
    ·
    <a href="https://github.com/mgnfy-view/simple-token-wallet-challenge/issues/new?labels=enhancement&template=feature-request---.md">Request Feature</a>
  </p>
</div>

<!-- TABLE OF CONTENTS -->
<details>
  <summary>Table of Contents</summary>
  <ol>
    <li>
      <a href="#about-the-project">About The Project</a>
      <ul>
        <li><a href="#built-with">Built With</a></li>
      </ul>
    </li>
    <li>
      <a href="#getting-started">Getting Started</a>
      <ul>
        <li><a href="#prerequisites">Prerequisites</a></li>
        <li><a href="#installation">Installation</a></li>
      </ul>
    </li>
    <li><a href="#roadmap">Roadmap</a></li>
    <li><a href="#contributing">Contributing</a></li>
    <li><a href="#license">License</a></li>
    <li><a href="#contact">Contact</a></li>
  </ol>
</details>

<!-- ABOUT THE PROJECT -->

## About The Project

This is a simple token wallet contract that allows you to manage your tokens - depost, withdraw, transfer tokens, use token allowance provided to the wallet, and provide allowance to other addresses. Additionally, it uses EIP712 structured signatures to enable gas sponsorship for token transfers.

**Some design choices that were made include:**

- Tracking token balances in mapping is gas inefficient. Also, if tokens are directly sent to the wallet without using the `deposit()` function, there will be a disparity between the actual balance held by the contract and the stored balance in the mapping. Thus, balaces are retrieved by querying the ERC20 token contract.
- The native gas token is stored in the wrapped form (for example, ETH -> WETH). When native token is sent to the contract, it is automatically wrapped in the `receive()` function. This choice allows us to use the ERC20 functions for the native token, reducing additional code required for native token handling, and effectively decreasing the contract size (and thus deployment costs).
- Aside from simple deposits and withdrawals, the wallet also supports transferring tokens out to other addresses, and using token allowance provided to the wallet. This makes the wallet more feature-rich.
- EIP712 signatures enable gasless transfers. The wallet owner can sign transactions for withdrawals, token transfers, and using allowance, and these can be relayed by anyone to the wallet. This enables gas sponsorship and easier onboarding.
- Ownership of the wallet is transferrable.

**Gas optimizations:**

- Using custom errors instead of `require()` statements saves gas.
- Using external functions over public functions saves gas.
- Token balances are dynamically determined, saving gas (sstore, sload not required).
- Using immutable and private variables. Getters have been written for private variables separately, saving a bit of gas.

**Some security measures that were taken:**

- Critical functions like `withdraw()`, `transferTokens()`, `transferTokensFrom()` are guarded by the `onlyOwner` modifier.
- Nonce and deadline values are used for gasless transfers. Nonce prevents replay attacks, and deadline ensures that signatures are valid only for a predefined time interval.
- Using Openzeppelin's well audited and battle tested contracts for verifying signatures, and handling wallet ownership.

A sample deployment script has also been provided at `./script/DeploySimpleTokenWallet.s.sol`.

### Built With

- Solidity
- Foundry

<!-- GETTING STARTED -->

## Getting Started

### Prerequisites

Make sure you have git, rust, and foundry installed and configured on your system.

### Installation

Clone the repo,

```shell
git clone https://github.com/mgnfy-view/simple-token-wallet-challenge.git
```

cd into the repo, and install the necessary dependencies

```shell
cd simple-token-wallet-challenge
forge build
```

Run tests by executing

```shell
forge test
```

That's it, you are good to go now!

<!-- ROADMAP -->

## Roadmap

-   [x] Smart contract development
-   [x] Unit tests
-   [x] Write a good README.md

See the [open issues](https://github.com/mgnfy-view/simple-token-wallet-challenge/issues) for a full list of proposed features (and known issues).

<!-- CONTRIBUTING -->

## Contributing

Contributions are what make the open source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

If you have a suggestion that would make this better, please fork the repo and create a pull request. You can also simply open an issue with the tag "enhancement".
Don't forget to give the project a star! Thanks again!

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

<!-- LICENSE -->

## License

Distributed under the MIT License. See `LICENSE.txt` for more information.

<!-- CONTACT -->

## Reach Out

Here's a gateway to all my socials, don't forget to hit me up!

[![Linktree](https://img.shields.io/badge/linktree-1de9b6?style=for-the-badge&logo=linktree&logoColor=white)][linktree-url]

<!-- MARKDOWN LINKS & IMAGES -->
<!-- https://www.markdownguide.org/basic-syntax/#reference-style-links -->

[contributors-shield]: https://img.shields.io/github/contributors/mgnfy-view/simple-token-wallet-challenge.svg?style=for-the-badge
[contributors-url]: https://github.com/mgnfy-view/simple-token-wallet-challenge/graphs/contributors
[forks-shield]: https://img.shields.io/github/forks/mgnfy-view/simple-token-wallet-challenge.svg?style=for-the-badge
[forks-url]: https://github.com/mgnfy-view/simple-token-wallet-challenge/network/members
[stars-shield]: https://img.shields.io/github/stars/mgnfy-view/simple-token-wallet-challenge.svg?style=for-the-badge
[stars-url]: https://github.com/mgnfy-view/simple-token-wallet-challenge/stargazers
[issues-shield]: https://img.shields.io/github/issues/mgnfy-view/simple-token-wallet-challenge.svg?style=for-the-badge
[issues-url]: https://github.com/mgnfy-view/simple-token-wallet-challenge/issues
[license-shield]: https://img.shields.io/github/license/mgnfy-view/simple-token-wallet-challenge.svg?style=for-the-badge
[license-url]: https://github.com/mgnfy-view/simple-token-wallet-challenge/blob/master/LICENSE.txt
[linktree-url]: https://linktr.ee/mgnfy.view
