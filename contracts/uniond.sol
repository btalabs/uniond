//License: GPL
//Author: @hugooconnor @arkhh
//Thanks to @XertroV for @voteFlux issue based direct democracy

contract Uniond {
	
	Constitution constitution;

	uint public issueSerial;
	uint public electionSerial;
	uint public paymentSerial;
	
	mapping(address => Member) public member;
	address[] public members;

	mapping(uint => Issue) public issues;
	mapping(uint => Payment) public payments;
	mapping(uint => Election) public elections;
	
	mapping(uint => address[]) public electionVotes;
	mapping(address => uint) public votes;
	mapping(address => uint) public tokens;

	struct Payment{
		address spender;
		address recipient;
		string reason;
		uint amount;
		uint date;
	}

	struct Election {
		address owner;
	    address nominee;
	    bool appoint;
	    uint role;
	 	uint deadline;
	    bool executed;
	    uint totalVoters;  //TODO set after deadline is passed
	}

	struct Issue {
	    address owner;
	    string description;
	    bool visible;
	    uint date;
	    uint approve;
	    uint disapprove;
	    uint deadline;
	    uint budget;
	}

	struct Member {
	    uint joinDate;
	    uint renewalDate;
	    bool isMember;
	    bool isMemberAdmin;
	    bool isTreasurer;
	    bool isRepresentative;
	    bool isChair;
	}

/*
	struct SpendRules {
        uint threshold; // number of signature required for spending more than 10 eth
        uint signatureThreshold; //
    }
*/

    struct GeneralRules {
        uint nbrTreasurer;
        uint nbrSecretary;
        uint nbrRepresentative;
        uint nbrAdmin;
    }

	struct ElectionRules {
        uint duration;
        uint winThreshold;
        uint mandateDuration;
    }

  	struct MemberRules {
    	uint joiningFee;
    	uint subscriptionPeriod;
   	}

    struct IssuesRules {
        uint minApprovalRate;
        uint minConsultationLevel;
    }

    struct AdminStipend {
        uint stipendTreasurer;
        uint stipendSecretary;
        uint stipendRepresentative;
        uint stipendAdmin;
    }

	struct Constitution {
		GeneralRules generalRules;
		ElectionRules electionRules;
		MemberRules memberRules;
		AdminStipend adminStipend;
		IssuesRules issuesRules;
        //SpendRules[] spendRules;
      }

	//constructor
 	function Uniond(){
	    member[msg.sender] = Member(now, 0, true, true, true, true, true);
	    members.push(msg.sender);
	    votes[msg.sender] = 0;
	    issueSerial = 0;
	    electionSerial = 0;
	    paymentSerial = 0;
	    constitution = Constitution(
	    				GeneralRules(1, 1, 1, 1),
	    				ElectionRules(1, 1, 1),
	    				MemberRules(1, 1),
	    				AdminStipend(1, 1, 1, 1),
	    				IssuesRules(10,34)
	    				);
	}

	modifier onlyMemberAdmin {
	    if (!member[msg.sender].isMemberAdmin) {
	      throw;
	    }
	    _
	}

	modifier onlyTreasurer {
	    if (!member[msg.sender].isTreasurer) {
	      throw;
	    }
	    _
	}

	modifier onlyMember {
	    if (!member[msg.sender].isMember) {
	      throw;
	    }
	    _
	}

	modifier onlyChair {
	    if (!member[msg.sender].isChair) {
	      throw;
	    }
	    _
	}

/*
	modifier twoThirdMajority {
	// sample test
	    if (!election.result>=(0.666*totalVoters)+1){
          throw;
	    }
	    _
    }
*/

	
  	function addElection(address nominee, uint position, bool appoint) returns (uint success){
  	    uint duration = constitution.electionRules.duration;
  		uint deadline = now + duration;
  		elections[electionSerial] = Election(msg.sender, nominee, appoint, position, deadline, false, 0);
  		electionSerial++;
  		return 1;
  	}

  	function voteElection(uint election) returns (uint success){
  		if(now < elections[election].deadline && member[msg.sender].isMember){
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
  		   		elections[election].totalVoters++;
  		   		return 1;
  		   }
  		}
  		return 0;
  	}

  	function callElection(uint election) returns (uint result){ // rename to triggerElection ?
  		if(now > elections[election].deadline && electionVotes[election].length > (members.length / 2)){
  			return 1;
  		} else {
  			return 0;
  		}
  	}

  	//positions; 1 == treasurer, 2 == memberAdmin, 3 == chair, 
	// 4 == revoke treasurer, 5 == revoke memberAdmin, 6 == revoke Chair
  	function executeMandate(uint election) returns (uint success){
  		if(!elections[election].executed && callElection(election) == 1){
  			address nominee = elections[election].nominee;
  			if(elections[election].role == 1){
  				//add treasurer
			    member[nominee].isTreasurer = true;
			    elections[election].executed = true;
  			} else if (elections[election].role == 2){
  			   	//add memberAdmin 
  			   	member[nominee].isMemberAdmin = true;
		   	   	elections[election].executed = true;
  			} else if (elections[election].role == 3) {
  				//add chair
  				member[nominee].isChair = true;
  				elections[election].executed = true;
  			} else if (elections[election].role == 4) {
  				//revoke treasurer
  				member[nominee].isTreasurer = false;
  				elections[election].executed = true;
  			} else if (elections[election].role == 5) {
  				//revoke memberAdmin
  				member[nominee].isMemberAdmin = false;
  				elections[election].executed = true;
  			} else if (elections[election].role == 6) {
  				//revoke chair
  				member[nominee].isChair = false;
  				elections[election].executed = true;
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
  		if(msg.value >= constitution.memberRules.joiningFee){
  			member[msg.sender] = Member(now, 0, false, false, false, false, false);
  			return 1;
  		}
  		return 0;
  	}

  	function addMember(address newMember) onlyMemberAdmin returns (uint success){
  		if(member[newMember].joinDate < now){
  			members.push(newMember);
  			member[newMember].isMember = true;
  			member[newMember].renewalDate = now;
  			return 1;
  		}
  		return 0;
  	}

  	function reviewMembers() onlyMemberAdmin returns (uint success){
  		for(var i=0; i < members.length; i++){
  			address m = members[i];
  			if (now - member[m].renewalDate > constitution.memberRules.subscriptionPeriod){
  				member[m].isMember = true;
  			} else {
  				member[m].isMember = false;
  				delete members[i];
  			}
  		}
  		return 1;
  	}
  	
  	//todo -- add multisig on spending
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
  		constitution.memberRules.joiningFee = fee;
  		return 1;
  	}

  	function setSubscriptionPeriod(uint period) onlyTreasurer returns (uint success){
  		constitution.memberRules.subscriptionPeriod = period;
  		return 1;
  	}

  	function unionBalance() returns (uint balance) {
  		return this.balance;
  	}

  	//create new issue
	function addIssue(string description, uint deadline, uint budget) onlyMember returns (uint success){
	    issues[issueSerial] = Issue(msg.sender, description, false, now, 0, 0, deadline, budget);
	    issueSerial++;
	    //credit each member with a vote
	    for(var i=0; i < members.length; i++){
	      if(member[members[i]].isMember){
	      	votes[members[i]]++;
	      }
	    }
	    return 1;
	}

    function selectAgenda(){
        for(var i=0; i < issues.length; i++){
        var percentVoters = ((issues[i].approve+issues[i].disapprove)/totalVoters)*100;
        var percentApproval = (issues[i].approve/issues[i].disapprove)*100;

          // 28 days after submission if the consultation level is reached AND the approval rate is not met then disable the issue.
          if(((issues[i].date)+(60*60*24*28)<now) && (percentVoters>constitution.minConsultationLevel) && (percentApproval<constitution.minApprovalRate)){
            issues[i].visible=false;
          }

        }
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
  	//decentralised whip function
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