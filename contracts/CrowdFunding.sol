
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract CrowdFunding {
    mapping(address => uint) public contributors;
    address public immutable manager;
    uint public minimumContribution;
    uint public deadline;
    uint public target;
    uint public raisedAmount;
    uint public noOfContributors;

    struct Request {
        string description;
        address payable recipient;
        uint value;
        bool completed;
        uint noOfVoters;
        mapping(address => bool) voters;
    }

    mapping(uint => Request) public requests;
    uint public numRequests;

    event ContributionReceived(address indexed contributor, uint amount);
    event RefundIssued(address indexed contributor, uint amount);
    event RequestCreated(uint indexed requestId, string description, address indexed recipient, uint value);
    event Voted(address indexed voter, uint indexed requestId);
    event PaymentMade(uint indexed requestId, address indexed recipient, uint value);

    constructor() {
        target = 1000;
        deadline = block.timestamp + 2 minutes;
        minimumContribution = 100 wei;
        manager = msg.sender;
    }

    modifier onlyManager() {
        require(msg.sender == manager, "Only manager can call this function");
        _;
    }

    receive() external payable {
        sendEth();
    }

    function sendEth() public payable {
        require(block.timestamp < deadline, "Deadline has passed");
        require(msg.value >= minimumContribution, "Minimum Contribution is not met");

        if (contributors[msg.sender] == 0) {
            noOfContributors++;
        }
        contributors[msg.sender] += msg.value;
        raisedAmount += msg.value;

        emit ContributionReceived(msg.sender, msg.value);
    }

    function getContractBalance() public view returns (uint) {
        return address(this).balance;
    }

    function refund() public {
        require(block.timestamp > deadline && raisedAmount < target, "Refund not allowed");
        uint contributedAmount = contributors[msg.sender];
        require(contributedAmount > 0, "No contributions found for you");

        contributors[msg.sender] = 0;

        (bool sent, ) = payable(msg.sender).call{value: contributedAmount}("");
        require(sent, "Transfer failed");

        emit RefundIssued(msg.sender, contributedAmount);
    }

    function createRequests(string memory _description, address payable _recipient, uint _value) public onlyManager {
        require(_value <= address(this).balance, "Request value exceeds contract balance");

        Request storage newRequest = requests[numRequests];
        newRequest.description = _description;
        newRequest.recipient = _recipient;
        newRequest.value = _value;
        newRequest.completed = false;
        newRequest.noOfVoters = 0;

        emit RequestCreated(numRequests, _description, _recipient, _value);
        numRequests++;
    }

    function voteRequest(uint _requestNo) public {
        require(contributors[msg.sender] > 0, "Only contributors can vote");

        Request storage thisRequest = requests[_requestNo];
        require(!thisRequest.voters[msg.sender], "Already voted");

        thisRequest.voters[msg.sender] = true;
        thisRequest.noOfVoters++;

        emit Voted(msg.sender, _requestNo);
    }

    function makePayment(uint _requestNo) public onlyManager {
        require(raisedAmount >= target, "Funding target not reached");

        Request storage thisRequest = requests[_requestNo];
        require(!thisRequest.completed, "Request already completed");
        require(thisRequest.noOfVoters > noOfContributors / 2, "Majority approval not met");
        require(address(this).balance >= thisRequest.value, "Insufficient contract balance");

        thisRequest.completed = true;
        (bool sent, ) = thisRequest.recipient.call{value: thisRequest.value}("");
        require(sent, "Payment transfer failed");

        emit PaymentMade(_requestNo, thisRequest.recipient, thisRequest.value);
    }

    function updateCampaign(uint _newTarget, uint _extraMinutes) public onlyManager {
        require(block.timestamp < deadline, "Cannot update after deadline");
        require(_newTarget > raisedAmount, "New target must exceed raised amount");
        require(_extraMinutes > 0, "Must add positive time");

        target = _newTarget;
        deadline += _extraMinutes * 1 minutes;
    }
}




// https://sepolia.etherscan.io/address/0x381BC9D86C7C76F29cb0f25Ddc79Ee5B1BA61ad7#code
 