# Rock Paper Scissors – Ethereum Smart Contract

A decentralized **Rock Paper Scissors** game implemented as an **Ethereum smart contract** using **Solidity**.  
The game follows a **commit–reveal scheme** to ensure fairness and prevent cheating, with rewards distributed automatically on-chain.

---

## 📌 Overview

This project implements a trustless Rock Paper Scissors game between two players.  
A manager deploys the contract and deposits a reward, while players commit hashed moves and later reveal them.

The contract ensures:
- Fair gameplay using cryptographic commitments
- Time-based commit and reveal phases
- Automatic winner determination
- Secure reward distribution
- Timeout handling for inactive players

---

## 🛠️ Technologies Used

- Solidity `^0.8.4`
- Ethereum Virtual Machine (EVM)
- Commit–Reveal cryptographic pattern

---

## 🎮 Game Rules

Moves are represented as:
- `0` → Rock
- `1` → Paper
- `2` → Scissors

---

## 🔄 Game Phases

### 1. Commit Phase
Players submit a hash of their move and a secret:
```
keccak256(abi.encodePacked(move, secret))
```

### 2. Reveal Phase
Players reveal their move and secret.  
The contract verifies correctness by recomputing the hash.

### 3. Finished Phase
The winner is determined and the reward is distributed.

---

## 🔐 Commit–Reveal Mechanism

This mechanism prevents players from changing their move after seeing the opponent’s choice.

1. Commit a hashed move
2. Reveal the original move and secret
3. Contract validates the hash

---

## 💰 Reward Distribution

- **Winner** receives the full reward
- **Tie** → reward split equally
- **One player fails to reveal** → revealed player wins
- **Both fail to reveal** → reward refunded to the manager

---

## ⏱️ Timeout Handling

If the reveal deadline passes, anyone can call:
```
claimTimeout()
```

Funds are distributed based on which players revealed their moves.

---

## 📄 Smart Contract Details

- **File:** `RockPaperScissors.sol`
- **Solidity Version:** `^0.8.4`
- **License:** GPL-3.0

---

## 🚀 Deployment

The contract is deployed by the manager with:
- Two participant addresses
- Commit phase duration
- Reveal phase duration
- Reward amount (sent as `msg.value`)
