//License: GPL
//Author: @hugooconnor
//Thanks to @XertroV for @voteFlux issue based direct democracy

contract Uniond {
	
	address founder;

	uint joiningFee;

	uint subscriptionPeriod;
	
	uint issueSerial;
	uint electionSerial;
	
	mapping(address => bool) treasurer;
	
	mapping(address => bool) memberAdmin;

	mapping(address => bool) isMember;

	mapping(address => Subscription) subscriptions;

	mapping(uint => Issue) issues;

	mapping(uint => Election) elections;
	
	mapping(uint => address[]) electionVotes;

	mapping(address => uint) votes;

	address[] members;

	address[] memberAdminList;

	address[] treasurerList;

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
	}

	//memberAdmin modifier
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
  		   electionVotes[election].push(msg.sender); 
  		   return 1;
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

  	function getElectionNominee(uint election) returns (address nominee){
  		return elections[election].nominee;
  	}

  	function getElectionRole(uint election) returns (uint role){
  		return elections[election].role;
  	}

  	function addCandidate(uint election) returns (uint success){
  		if(callElection(election) == 1){
  			address nominee = getElectionNominee(election);
  			if(getElectionRole(election) == 1){
  				//add to treasurer role
			    treasurer[nominee] = true;
			    treasurerList.push(nominee);
  			} else if (getElectionNominee(election) == 2){
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
  		if(subscriptions[member].paid){
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
	function transfer(address reciever, uint amount) returns (uint success){
	    if(votes[msg.sender] >= amount){
	      votes[msg.sender] -= amount;
	      votes[reciever] += amount;
	      return 1;
	    }
	    return 0;
	}

  	//get balance of votes
	function getBalance() returns (uint balance){
	    balance = votes[msg.sender];
	}

  	//get current issue
	function getIssue(uint serial) returns
	    (string description, uint approve, uint disapprove, uint deadline){
	    description = issues[serial].description;
	    approve = issues[serial].approve;
	    disapprove = issues[serial].disapprove;
	    deadline = issues[serial].deadline;
	}

	//get membership count
	function getMemberCount() returns (uint count){
	    count = members.length;
	}

	//get member at position i
	function getMember(uint index) returns (address member){
	    member = members[index];
	}

  	function getIssueCount() returns (uint count){
    	count = issueSerial;
  	}

  	function getFounder() returns (address owner){
    	owner = founder;
  	}

  	function getJoiningFee() returns (uint fee){
  		fee = joiningFee;
  	}
}