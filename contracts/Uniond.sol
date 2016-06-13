//License: GPL
//Author: @hugooconnor @arkhh
//Thanks to @XertroV for @voteFlux issue based direct democracy
// TODO  renew membership function
//  payStipend - may need new data struct
//  reviewOffice - put time limit on office 

contract Uniond {

  uint[10] public constitution;

  address[] public members;
  mapping(address => Member) public member;

  struct Member {
    uint joinDate;
    uint renewalDate;
    bool exists;
    bool isMember;
    bool isMemberAdmin;
    bool isTreasurer;
    uint electedMemberAdminDate;
    uint electedTreasurerDate;
    uint salary;
  }
  
  uint tokenSupply;
  mapping(address => uint) public tokens;

  mapping(address => uint) public votes;
  
  Issue[] public issues;
  Spend[] public spends;
  Election[] public elections;
  Amendment[] public amendments;
  TokenPayments[] public tokenPayments;

  struct TokenPayments {
    uint amountPaid;
    uint paymentDate;
  }

  struct Amendment {
    string reason;
    uint clause;
    uint value;
    uint deadline;
    bool executed;
    address[] votes;
  }

  struct Spend{
    address recipient;
    uint amount;
    address[] signatures;
    bool spent;
  }

  struct Election {
    address owner;
    address nominee;
    uint role;
    uint deadline;
    bool executed;
    address[] votes;  //TODO set after deadline is passed
  }

  struct Issue {
    address owner;
    string description;
    uint date;
    uint approve;
    uint disapprove;
    uint deadline;
  }

  event Payment(address spender, address recipient, string reason, uint amount, uint date);

  //constructor
  function Uniond(){
      member[msg.sender] = Member(now, now, true, true, true, true, now, now, 1000);
      members.push(msg.sender);
      tokenPayments.push(TokenPayments(0, 0));
      constitution[0] = 1; //minSignatures
      constitution[1] = 2419200; //electionDuration
      constitution[2] = 50; //electionWinThreshold
      constitution[3] = 31536000; //mandateDuration
      constitution[4] = 66; //amendmentWinThreshold
      constitution[5] = 0; //joiningFee
      constitution[6] = 31536000; //subscriptionPeriod
      constitution[7] = 1; //canSetSalary
      constitution[8] = 1000; //salaryCap
      constitution[9] = 86400; //salaryPeriod
  }

  modifier onlyMemberAdmin {
      if (!member[msg.sender].isMemberAdmin && now - member[msg.sender].electedMemberAdminDate < constitution[1]) {
        throw;
      }
      _
  }

  modifier onlyTreasurer {
      if (!member[msg.sender].isTreasurer && now - member[msg.sender].electedTreasurerDate < constitution[1]) {
        throw;
      }
      _
  }

  modifier onlyMember {
      if (!member[msg.sender].isMember && now - member[msg.sender].renewalDate < constitution[6]) {
        throw;
      }
      _
  }

  function addElection(address nominee, uint position) returns (bool success){
      uint duration = constitution[1];
      uint deadline = now + duration;
      address[] memory votes;
      elections.push(Election(msg.sender, nominee, position, deadline, false, votes));
      return true;
  }

  function voteElection(uint election) returns (bool success){
      if(now < elections[election].deadline && member[msg.sender].exists && member[msg.sender].isMember){
         bool hasVoted = false;
         for(uint i=0; i < elections[election].votes.length; i++){
            if(elections[election].votes[i] == msg.sender){
              hasVoted = true;
              break;
            }
         }
         if(!hasVoted){
            elections[election].votes.push(msg.sender);
            return true;
         }
      }
      return false;
  }

  function callElection(uint election) returns (bool result){ // rename to triggerElection ?
      if(now > elections[election].deadline && 
        ((getActiveMemberCount() / elections[election].votes.length)*100) > constitution[2]){
        return true;
      } else {
        return false;
      }
  }

    //positions; 1 == treasurer, 2 == memberAdmin, 3 == chair, 4 == representative 
  // 5 == revoke treasurer, 6 == revoke memberAdmin, 7 == revoke Chair, 8 == revoke representative
    function executeElectionMandate(uint election) returns (bool success){
      if(!elections[election].executed && callElection(election)){
        address nominee = elections[election].nominee;
        if(elections[election].role == 1){
          //add treasurer
          member[nominee].isTreasurer = true;
          elections[election].executed = true;
          member[nominee].electedTreasurerDate = now;
        } else if (elections[election].role == 2){
            //add memberAdmin 
            member[nominee].isMemberAdmin = true;
            elections[election].executed = true;
            member[nominee].electedMemberAdminDate = now;
        } else if (elections[election].role == 5) {
          //revoke treasurer
          member[nominee].isTreasurer = false;
          elections[election].executed = true;
        } else if (elections[election].role == 6) {
          //revoke memberAdmin
          member[nominee].isMemberAdmin = false;
          elections[election].executed = true;
        } else {
          return false;
        }
        return true;
      } else {
        //fail case
        return false;
      }
    }

  function applyMember() returns (bool success){
      if(msg.value >= constitution[5] && !member[msg.sender].exists){
        member[msg.sender] = Member(now, 0, true, false, false, false, 0, 0, 0);
        return true;
      } else if (msg.value >= constitution[5] && member[msg.sender].exists){
        member[msg.sender].isMember = true;
        member[msg.sender].renewalDate = now;
      }
      return false;
  }

  function addMember(address newMember) onlyMemberAdmin returns (bool success){
      if(member[newMember].exists){
        members.push(newMember);
        member[newMember].isMember = true;
        member[newMember].renewalDate = now;
        return true;
      }
      return false;
  }

    function setJoiningFee(uint fee) onlyTreasurer returns (bool success){
      constitution[5] = fee;
      return true;
    }

    function setSubscriptionPeriod(uint period) onlyTreasurer returns (bool success){
      constitution[6] = period;
      return true;
    }

    function unionBalance() constant returns (uint balance) {
      return this.balance;
    }

  //create new issue
  function addIssue(string description, uint deadline) returns (bool success){
      issues.push(Issue(msg.sender, description, now, 0, 0, deadline));
      //credit each member with a vote
      for(uint i=0; i < members.length; i++){
        if(member[members[i]].isMember){
          votes[members[i]]++;
        }
      }
      return true;
  }

    //vote on an issue
    //q - should members who haven't paid subscription be able to vote with accumulated votes?
  function vote(uint issue, bool approve, uint amount) onlyMember returns (bool success){
      if(now < issues[issue].deadline && votes[msg.sender] >= amount){
        votes[msg.sender] -= amount;
        if(approve){
      issues[issue].approve += amount;
        } else {
      issues[issue].disapprove += amount;
        }
        return true;
      }
      return false;
  }

    //transfer votes
    //decentralised whip function
  function transferVotes(address reciever, uint amount) returns (bool success){
      if(votes[msg.sender] >= amount){
        votes[msg.sender] -= amount;
        votes[reciever] += amount;
        return true;
      }
      return false;
  }

  function getActiveMemberCount() constant returns (uint count){
    count = 0;
    for(uint i=0; i < members.length; i++){
      if(member[members[i]].isMember){
        count ++;
      }
    }
    return count;
  }

  function newSpend(uint amount, address recipient) onlyTreasurer returns (bool success){
    address[] memory signatures;
    spends.push(Spend(recipient, amount, signatures, false));
    return true;
  }

  function signSpend(uint spend) onlyTreasurer returns (bool success){
    //check hasn't already signed;
    bool hasSigned = false;
    for(uint i=0; i < spends[spend].signatures.length; i++){
      if(msg.sender == spends[spend].signatures[i]){
        hasSigned = true;
        break;
      }
    }
    if(!hasSigned){
      spends[spend].signatures.push(msg.sender);
      return true;
    } else {
      return false;
    }
  }

  function executeSpend(uint spend, string reason) onlyTreasurer returns (bool success){
    if(this.balance >= spends[spend].amount && spends[spend].signatures.length >= constitution[0]){
      spends[spend].recipient.send(spends[spend].amount);
      spends[spend].spent = true;
      Payment(msg.sender, spends[spend].recipient, reason, spends[spend].amount, now);
      return true;
    } else {
      return false;
    }
  }

  function newAmendment(string reason, uint clause, uint value) onlyMember returns (bool success){
    uint duration = constitution[1];
    uint deadline = now + duration;
    address[] memory votes;
    amendments.push(Amendment(reason, clause, value, deadline, false, votes));
    return true;
  }

  //todo set as supermajority-- 2/3;
  function callAmendment(uint amendment) returns (bool result){
      if(now > amendments[amendment].deadline && 
        ((getActiveMemberCount() / amendments[amendment].votes.length)*100) > constitution[4]){
        return true;
      } else {
        return false;
      }
    }

    function executeAmendmentMandate(uint amendment) returns (bool success){
      if(!amendments[amendment].executed && callAmendment(amendment)){
        constitution[amendments[amendment].clause] = amendments[amendment].value;
        amendments[amendment].executed = true;
        return true;
        }
      return false;
    }

    function totalSupply() constant returns (uint256 supply){
      return tokenSupply;
    }

    function balanceOf(address _owner) constant returns (uint256 balance){
      return tokens[_owner];
    }

    function transfer(address _to, uint256 _value) returns (bool success){
      if(tokens[msg.sender] >= _value){
        tokens[msg.sender] -= _value;
        tokens[_to] += _value;
        return true;  
      } else {
        return false;
      }
    }

  function setSalary(uint amount) returns (bool success){
    if(constitution[7] > 0 && amount <= constitution[8] && member[msg.sender].exists){
      member[msg.sender].salary = amount;
      return true;
    }
    return false;
  }

  function paySalary() returns (bool success){
    if(now - tokenPayments[tokenPayments.length - 1].paymentDate >= constitution[9]) {
      uint amountPaid = 0;
      for(uint i = 0; i < members.length; i++){
        if(member[members[i]].isMember && member[members[i]].salary > 0){
          tokens[members[i]] += member[members[i]].salary;
          amountPaid += member[members[i]].salary;
        }
      }
      tokenSupply += amountPaid;
      tokenPayments.push(TokenPayments(amountPaid, now));
      return true;
    }
    return false;
  }

}