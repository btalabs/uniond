//License: GPL
//Author: @hugooconnor
//Thanks to @XertroV for @voteFlux issue based direct democracy
//TODO
// add getPayment methods
// add getMember methods
// add getElection methods
// add methods to un-elect
// add method to get current funds on hand

contract Uniond {
	
	address public founder;
	uint public joiningFee;
	uint public subscriptionPeriod;
	uint public issueSerial;
	uint public electionSerial;
	uint public paymentSerial;
	
	mapping(address => bool) public treasurer;
	mapping(address => bool) public memberAdmin;
	mapping(address => bool) public isMember;

	address[] public members;
	address[] public memberAdminList;
	address[] public treasurerList;

	mapping(address => Subscription) public subscriptions;
	mapping(uint => Issue) public issues;
	mapping(uint => Payment) public payments;
	mapping(uint => Election) public elections;
	
	mapping(uint => address[]) public electionVotes;
	mapping(address => uint) public votes;

	struct Payment{
		address spender;
		address recipient;
		string reason;
		uint amount;
		uint date;
	}

	struct Subscription {
		bool paid;
		uint date;
	}

	struct Election {
		address owner;
	    address nominee;
	    //1 == treasurer, 2 == memberAdmin
	    uint role;
	    uint deadline;
	}

	struct Issue {
	    address owner;
	    string description;
	    uint approve;
	    uint disapprove;
	    uint deadline;
	    //uint budget;
	}

 	function Uniond(){
	    founder = msg.sender;
	    memberAdmin[msg.sender] = true;
	    treasurer[msg.sender] = true;
	    isMember[msg.sender] = true;
	    members.push(msg.sender);
	    memberAdminList.push(msg.sender);
	    treasurerList.push(msg.sender);
	    votes[msg.sender] = 1;
	    issueSerial = 0;
	    electionSerial = 0;
	    paymentSerial = 0;
	}

	modifier onlyMemberAdmin {
	    if (!memberAdmin[msg.sender]) {
	      throw;
	    }
	    _
	}

	modifier onlyTreasurer {
	    if (!memberAdmin[msg.sender]) {
	      throw;
	    }
	    _
	}

	modifier onlyMember {
	    if (!isMember[msg.sender]) {
	      throw;
	    }
	    _
	}

  	function addElection(address nominee, uint position) returns (uint success){
  	    uint duration = 60*60*24*7*4;
  		uint deadline = now + duration;
  		elections[electionSerial] = Election(msg.sender, nominee, position, deadline);
  		electionSerial++;
  		return 1;
  	}

  	function voteElection(uint election) returns (uint success){
  		if(now < elections[election].deadline && isMember[msg.sender]){
  		   //need to stop people from voting twice - probably a better way to do this...
  		   bool hasVoted = false;
  		   for(var i=0; i < electionVotes[election].length; i++){
  		   		if(electionVotes[election][i] == msg.sender){
  		   			hasVoted = true;
  		   			break;
  		   		}
  		   }
  		   if(!hasVoted){
  		   		electionVotes[election].push(msg.sender); 
  		   		return 1;
  		   }
  		}
  		return 0;
  	}

  	function callElection(uint election) returns (uint result){
  		if(now > elections[election].deadline && electionVotes[election].length > (members.length / 2)){
  			return 1;
  		} else {
  			return 0;
  		}
  	}

  	function addCandidate(uint election) returns (uint success){
  		if(callElection(election) == 1){
  			address nominee = elections[election].nominee;
  			if(elections[election].role == 1){
  				//add to treasurer role
			    treasurer[nominee] = true;
			    treasurerList.push(nominee);
  			} else if (elections[election].role == 2){
  			   	//add to memberAdmin role
  			   	memberAdmin[nominee] = true;
		   	   	memberAdminList.push(nominee);
  			} else {
  				return 0;
  			}
  			return 1;
  		} else {
  			//fail case
  			return 0;
  		}
  	}

  	function applyMember() returns (uint success){
  		if(msg.value >= joiningFee){
  			subscriptions[msg.sender] = Subscription(true, now);
  			return 1;
  		}
  		return 0;
  	}

  	function addMember(address member) onlyMemberAdmin returns (uint success){
  		if(subscriptions[member].paid && (now - subscriptions[member].date > subscriptionPeriod)){
  			members.push(member);
  			isMember[member] = true;
  			return 1;
  		}
  		return 0;
  	}

  	function reviewMembers() onlyMemberAdmin returns (uint success){
  		for(var i=0; i < members.length; i++){
  			address m = members[i];
  			if (now - subscriptions[m].date > subscriptionPeriod){
  				isMember[m] = true;
  			} else {
  				isMember[m] = false;
  			}
  		}
  		return 1;
  	}

  	function spend(address recipient, uint amount, string reason) onlyTreasurer returns (uint success){
		if (this.balance >= amount){
			//this is the place to 'clip the ticket'
			recipient.send(amount);
			payments[paymentSerial] =  Payment(msg.sender, recipient, reason, amount, now);
			paymentSerial++;
			return 1;
		}
		return 0;
  	}

  	function setJoiningFee(uint fee) onlyTreasurer returns (uint success){
  		joiningFee = fee;
  		return 1;
  	}

  	//create new issue
	function addIssue(string description, uint deadline) onlyMember returns (uint success){
	    issues[issueSerial] = Issue(msg.sender, description, 0, 0, deadline);
	    issueSerial++;
	    //credit each member with a vote
	    for(var i=0; i < members.length; i++){
	      if(isMember[members[i]]){
	      	votes[members[i]]++;
	      }
	    }
	    return 1;
	}

    //vote on an issue
    //q - should members who haven't paid subscription be able to vote with accumulated votes?
  	function vote(uint issue, bool approve, uint amount) onlyMember returns (uint success){
	    if(now < issues[issue].deadline && votes[msg.sender] >= amount){
	      votes[msg.sender] -= amount;
	      if(approve){
			issues[issue].approve += amount;
	      } else {
			issues[issue].disapprove += amount;
	      }
	      return 1;
	    }
	    return 0;
	}

  	//transfer votes
  	//should this exist? ppl can buy votes?
	function transfer(address reciever, uint amount) returns (uint success){
	    if(votes[msg.sender] >= amount){
	      votes[msg.sender] -= amount;
	      votes[reciever] += amount;
	      return 1;
	    }
	    return 0;
	}

	//get membership count
	function getMemberCount() returns (uint count){
	    count = members.length;
	}

}