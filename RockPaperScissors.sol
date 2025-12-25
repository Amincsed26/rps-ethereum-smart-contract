// SPDX-License-Identifier: GPL-3.0
/**
I acknowledge that I am aware of the academic integrity guidelines of this course, 
and that I worked on this assignment independently without any unauthorized help
امين محمد امين السيد
*/

/**
==========================================================
==========================================================
======================= More Assumption ==================
==========================================================
==========================================================
1. The hash of the move was generated in Remix IDE's terminal using:
web3.utils.soliditySha3(
  { type: 'uint8', value: 0 },
  { type: 'string', value: "secret" }
)
and then submitted in the commit phase.

2. Timeout function design:
- If claimTimeout is restricted to participants only, the reward can be locked
  forever if both participants didn't call it.
- If claimTimeout is restricted to the manager, it will introduce a bottleneck.
- Therefore, claimTimeout is left open for anyone to call.
*/
pragma solidity ^0.8.4;
contract RockPaperScissors {
    // addresses of manager and the two participants.
    address public manager;
    address public participant1;
    address public participant2;

    // reward deposited by manager.
    uint public reward;

    // possible phases.
    enum Phase { Commit, Reveal, Finished }
    Phase public phase;

    // maps for commitment, moves, and reveal status.
    mapping(address => bytes32) public commitments;
    mapping(address => uint8) public moves;
    mapping(address => bool) public revealed;

    // deadlines for commit and reveal phases.
    uint public commitDeadline;
    uint public revealDeadline;

    // utility events.
    event CommitMade(address participant);
    event RevealMade(address participant, uint8 move);
    event RewardDistributed(address winner, uint amount);
    event PhaseAdvanced(Phase newPhase);

    /* modifier to restrict access to participants. */
    modifier onlyParticipants() {
        require(msg.sender == participant1 || msg.sender == participant2, "Not a participant");
        _;
    }

    /* constructor creation. */
    constructor(
        address pparticipant1,
        address pparticipant2,
        uint ccommitTime,
        uint rrevealTime
    ) payable {
        require(msg.value > 0, "No reward deposited");

        // setting vars.
        manager = msg.sender;
        participant1 = pparticipant1;
        participant2 = pparticipant2;
        reward = msg.value;

        // initialization of phase and deadlines.
        phase = Phase.Commit;
        commitDeadline = block.timestamp + ccommitTime;
        revealDeadline = commitDeadline + rrevealTime;
    }

    /* commit function */
    function commit(bytes32 hashedMove) external onlyParticipants {
        require(phase == Phase.Commit, "Not in commit phase");
        require(block.timestamp <= commitDeadline, "Commit phase ended");
        require(commitments[msg.sender] == 0, "Already committed");
        require(hashedMove != 0, "Invalid commitment");

        // storing the hash for later comparison.
        commitments[msg.sender] = hashedMove;
        emit CommitMade(msg.sender);
    }

    /* reveal function. */
    function reveal(uint8 move, string calldata secret) external onlyParticipants {
        // proceed to next phase.
        if (phase == Phase.Commit && block.timestamp > commitDeadline) {
            phase = Phase.Reveal;
            emit PhaseAdvanced(phase);
        }
        require(phase == Phase.Reveal, "Not in reveal phase");
        require(block.timestamp <= revealDeadline, "Reveal phase ended");
        require(commitments[msg.sender] != 0, "No commitment found");
        require(!revealed[msg.sender], "Already revealed");
        require(move <= 2, "Invalid move");

        // checking that the revealed correctly hash to the commited.
        bytes32 hashed = keccak256(abi.encodePacked(move, secret));
        require(hashed == commitments[msg.sender], "Invalid reveal");

        moves[msg.sender] = move;
        revealed[msg.sender] = true;
        emit RevealMade(msg.sender, move);

        // if both reveal then go to distribute the reward.
        if (revealed[participant1] && revealed[participant2]) {
            distributeReward();
        }
    }

    /* distribute reward to winner and handle tie function. */
    function distributeReward() internal {
        phase = Phase.Finished;
        address winner;
        uint8 m1 = moves[participant1];
        uint8 m2 = moves[participant2];

        if (m1 == m2) winner = address(0); // tie.
        else if (m1 == 0 && m2 == 2) winner = participant1; // r >> s.
        else if (m1 == 1 && m2 == 0) winner = participant1; // p >> r.
        else if (m1 == 2 && m2 == 1) winner = participant1; // s >> p.
        else winner = participant2; // any other configuration makes 2 wins.
        // tie.
        if (winner == address(0)) {
            (bool sent1, ) = participant1.call{value: reward / 2}("");
            require(sent1, "Failed to send reward to participant 1");
            (bool sent2, ) = participant2.call{value: reward / 2}("");
            require(sent2, "Failed to send reward to participant 2");
            emit RewardDistributed(address(0), reward);
        }
        // the winner wins.
        else {
            (bool sent, ) = winner.call{value: reward}("");
            require(sent, "Failed to send reward to winner");
            emit RewardDistributed(winner, reward);
        }
    }

    /* claim reward after timeout occurs function. */
    function claimTimeout() external {
        require(block.timestamp > revealDeadline, "Reveal deadline not reached");
        require(phase != Phase.Finished, "Game finished");
        phase = Phase.Finished;
        // 1 revealed but 2 didn't.
        if (revealed[participant1] && !revealed[participant2]) {
            (bool sent1, ) = participant1.call{value: reward}("");
            require(sent1, "Failed to send reward to participant1");
            emit RewardDistributed(participant1, reward);
        } 
        // 2 revealed but 1 didn't.
        else if (revealed[participant2] && !revealed[participant1]) {
            (bool sent2, ) = participant2.call{value: reward}("");
            require(sent2, "Failed to send reward to participant2");
            emit RewardDistributed(participant2, reward);
        } 
        // neither of them revealed.
        else {
            (bool sent, ) = manager.call{value: reward}("");
            require(sent, "Failed to refund manager");
            emit RewardDistributed(manager, reward);
        }
    }
}