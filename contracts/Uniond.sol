//License: GPL
//Author: @hugooconnor @arkhh
//Thanks to @XertroV for @voteFlux issue based direct democracy
// TODO  renew membership function
//  payStipend - may need new data struct
//  reviewOffice - put time limit on office 

contract Constitutional {
  Constitution constitution;

  struct SpendRules {
    uint minSignatures; //
  }

  struct ElectionRules {
    uint duration;
    uint winThreshold;
    uint mandateDuration;
  }

  struct AmendmentRules {
    uint winThreshold;
  }

  struct MemberRules {
    uint joiningFee;
    uint subscriptionPeriod;
  }

  struct TokenRules {
    uint canSetSalary; //0= no, >1 = yes
    uint salaryCap;
    uint salaryPeriod;
  }

  struct Constitution {
    ElectionRules electionRules;
    MemberRules memberRules;
    SpendRules spendRules;
    TokenRules tokenRules;
    AmendmentRules amendmentRules;
  }

}

contract Uniond is Constitutional {

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
      constitution = Constitution(
              ElectionRules(1, 1, 1),
              MemberRules(0, 1),
              SpendRules(1),
              TokenRules(1, 1000, 100000),
              AmendmentRules(60)
              );
  }

  modifier onlyMemberAdmin {
      if (!member[msg.sender].isMemberAdmin && now - member[msg.sender].electedMemberAdminDate < constitution.electionRules.mandateDuration) {
        throw;
      }
      _
  }

  modifier onlyTreasurer {
      if (!member[msg.sender].isTreasurer && now - member[msg.sender].electedTreasurerDate < constitution.electionRules.mandateDuration) {
        throw;
      }
      _
  }

  modifier onlyMember {
      if (!member[msg.sender].isMember && now - member[msg.sender].renewalDate < constitution.memberRules.subscriptionPeriod) {
        throw;
      }
      _
  }

  function addElection(address nominee, uint position) returns (bool success){
      uint duration = constitution.electionRules.duration;
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
        ((getActiveMemberCount() / elections[election].votes.length)*100) > constitution.electionRules.winThreshold){
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
      if(msg.value >= constitution.memberRules.joiningFee && !member[msg.sender].exists){
        member[msg.sender] = Member(now, 0, true, false, false, false, 0, 0, 0);
        return true;
      } else if (msg.value >= constitution.memberRules.joiningFee && member[msg.sender].exists){
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
      constitution.memberRules.joiningFee = fee;
      return true;
    }

    function setSubscriptionPeriod(uint period) onlyTreasurer returns (bool success){
      constitution.memberRules.subscriptionPeriod = period;
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
    if(this.balance >= spends[spend].amount && spends[spend].signatures.length >= constitution.spendRules.minSignatures){
      spends[spend].recipient.send(spends[spend].amount);
      spends[spend].spent = true;
      Payment(msg.sender, spends[spend].recipient, reason, spends[spend].amount, now);
      return true;
    } else {
      return false;
    }
  }

  function newAmendment(string reason, uint clause, uint value) onlyMember returns (bool success){
    uint duration = constitution.electionRules.duration;
    uint deadline = now + duration;
    address[] memory votes;
    amendments.push(Amendment(reason, clause, value, deadline, false, votes));
    return true;
  }

  //todo set as supermajority-- 2/3;
  function callAmendment(uint amendment) returns (uint result){
      if(now > amendments[amendment].deadline && 
        ((getActiveMemberCount() / amendments[amendment].votes.length)*100) > constitution.amendmentRules.winThreshold){
        return 1;
      } else {
        return 0;
      }
    }

    // Clauses -->
    // GeneralRules == 1_
    // ElectionRules == 2_
    // MemberRules == 3_
    // StipendRules == 4_
    // SpendRules == 5_
    // TokenRules == 6_
    function executeAmendmentMandate(uint amendment) returns (uint success){
      if(!amendments[amendment].executed && callAmendment(amendment) == 1){
        if (amendments[amendment].clause == 21){
           constitution.electionRules.duration = amendments[amendment].value;
           amendments[amendment].executed = true;
        } else if (amendments[amendment].clause == 22){
           constitution.electionRules.winThreshold = amendments[amendment].value;
           amendments[amendment].executed = true;
        } else if (amendments[amendment].clause == 23){
           constitution.electionRules.mandateDuration = amendments[amendment].value;
           amendments[amendment].executed = true;
        } else if (amendments[amendment].clause == 31){
           constitution.memberRules.joiningFee = amendments[amendment].value;
           amendments[amendment].executed = true;
        } else if (amendments[amendment].clause == 32){
           constitution.memberRules.subscriptionPeriod = amendments[amendment].value;
           amendments[amendment].executed = true;
        } else if (amendments[amendment].clause == 52){
            constitution.spendRules.minSignatures = amendments[amendment].value;
            amendments[amendment].executed = true;
        } else if (amendments[amendment].clause == 62){
            constitution.tokenRules.canSetSalary = amendments[amendment].value;
            amendments[amendment].executed = true;
        } else if (amendments[amendment].clause == 63){
            constitution.tokenRules.salaryCap = amendments[amendment].value;
            amendments[amendment].executed = true;
        } else if (amendments[amendment].clause == 64){
            constitution.tokenRules.salaryPeriod = amendments[amendment].value;
            amendments[amendment].executed = true;
        } else {
          return 0;
        }
        return 1;
      } else {
        //fail case
        return 0;
      }
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
    if(constitution.tokenRules.canSetSalary > 0 && amount <= constitution.tokenRules.salaryCap && member[msg.sender].exists){
      member[msg.sender].salary = amount;
      return true;
    }
    return false;
  }

  function paySalary() returns (bool success){
    if(now - tokenPayments[tokenPayments.length - 1].paymentDate >= constitution.tokenRules.salaryPeriod) {
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