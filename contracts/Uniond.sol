//License: GPL
//Author: @hugooconnor @arkhh
//Thanks to @XertroV for @voteFlux issue based direct democracy
// TODO  renew membership function
//  payStipend - may need new data struct
//  reviewOffice - put time limit on office 

contract Uniond {
  
  Constitution constitution;
  
  uint public tokenSupply;
  mapping(address => uint) public votes;
  mapping(address => uint) public tokens;

  address[] public members;
  mapping(address => Member) public member;

  Issue[] public issues;
  Spend[] public spends;
  Payment[] public payments;
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
    uint role;
    uint deadline;
    bool executed;
    address[] votes;  //TODO set after deadline is passed
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
    bool exists;
    bool isMember;
    bool isMemberAdmin;
    bool isTreasurer;
    bool isRepresentative;
    bool isChair;
    uint electedMemberAdminDate;
    uint electedTreasurerDate;
    uint electedRepresentativeDate;
    uint electedChairDate;
    uint salary;
    address[] endorsements;
  }

  struct SpendRules {
    uint threshold; // number of signature required for spending more than 10 eth -- how will this work?
    uint minSignatures; //
  }

  struct GeneralRules {
    uint nbrTreasurer;
    uint nbrChair;
    uint nbrRepresentative;
    uint nbrMemberAdmin;
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

  struct IssueRules {
    uint minApprovalRate;
    uint minConsultationLevel;
  }

  struct StipendRules {
    uint stipendTreasurer;
    uint stipendChair;
    uint stipendRepresentative;
    uint stipendMemberAdmin;
  }

  struct TokenRules {
    uint memberCredit;
    uint canSetSalary; //0= no, >1 = yes
    uint salaryCap;
    uint salaryPeriod;
  }

  struct Constitution {
    GeneralRules generalRules;
    ElectionRules electionRules;
    MemberRules memberRules;
    StipendRules stipendRules;
    IssueRules issueRules;
    SpendRules spendRules;
    TokenRules tokenRules;
    AmendmentRules amendmentRules;
  }

  //constructor
  function Uniond(){
      address[] memory endorsements;
      member[msg.sender] = Member(now, now, true, true, true, true, true, true, now, now, now, now, 1000, endorsements);
      members.push(msg.sender);
      votes[msg.sender] = 0;
      tokenPayments.push(TokenPayments(0, 0));
      constitution = Constitution(
              GeneralRules(1, 1, 1, 1),
              ElectionRules(1, 1, 1),
              MemberRules(0, 1),
              StipendRules(1, 1, 1, 1),
              IssueRules(10,34),
              SpendRules(1, 1),
              TokenRules(1000, 1, 1000, 100000),
              AmendmentRules(60)
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

  modifier onlySpecialMember {
      if (!member[msg.sender].isChair || !member[msg.sender].isTreasurer || !member[msg.sender].isMemberAdmin) {
        throw;
      }
      _
  }

  modifier canSetSalary {
    if(constitution.tokenRules.canSetSalary == 0){
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

//function payDividend(uint amount) returns (uint success){}

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
         for(var i=0; i < elections[election].votes.length; i++){
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

  function callElection(uint election) returns (uint result){ // rename to triggerElection ?
      if(now > elections[election].deadline && 
        ((getActiveMemberCount() / elections[election].votes.length)*100) > constitution.electionRules.winThreshold){
        return 1;
      } else {
        return 0;
      }
  }

    //positions; 1 == treasurer, 2 == memberAdmin, 3 == chair, 4 == representative 
  // 5 == revoke treasurer, 6 == revoke memberAdmin, 7 == revoke Chair, 8 == revoke representative
    function executeElectionMandate(uint election) returns (bool success){
      if(!elections[election].executed && callElection(election) == 1){
        address nominee = elections[election].nominee;
        if(elections[election].role == 1 && getTreasurerCount() < constitution.generalRules.nbrTreasurer){
          //add treasurer
          member[nominee].isTreasurer = true;
          elections[election].executed = true;
          member[nominee].electedTreasurerDate = now;
        } else if (elections[election].role == 2 && getMemberAdminCount() < constitution.generalRules.nbrMemberAdmin){
            //add memberAdmin 
            member[nominee].isMemberAdmin = true;
            elections[election].executed = true;
            member[nominee].electedMemberAdminDate = now;
        } else if (elections[election].role == 3 && getChairCount() < constitution.generalRules.nbrChair) {
          //add chair
          member[nominee].isChair = true;
          elections[election].executed = true;
          member[nominee].electedChairDate = now;
        } else if (elections[election].role == 5) {
          //revoke treasurer
          member[nominee].isTreasurer = false;
          elections[election].executed = true;
        } else if (elections[election].role == 6) {
          //revoke memberAdmin
          member[nominee].isMemberAdmin = false;
          elections[election].executed = true;
        } else if (elections[election].role == 7) {
          //revoke chair
          member[nominee].isChair = false;
          elections[election].executed = true;
        } else if (elections[election].role == 4 && getRepresentativeCount() < constitution.generalRules.nbrRepresentative) {
          //add representative
          member[nominee].isRepresentative = true;
          elections[election].executed = true;
          member[nominee].electedRepresentativeDate = now;
        } else if (elections[election].role == 8) {
          //revoke representative
          member[nominee].isRepresentative = false;
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
        address[] memory endorsements;
        member[msg.sender] = Member(now, 0, true, false, false, false, false, false, 0, 0, 0, 0, 0, endorsements);
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

    function reviewMembers() returns (bool success){
      for(var i=0; i < members.length; i++){
        address m = members[i];
        if (now - member[m].renewalDate > constitution.memberRules.subscriptionPeriod){
          member[m].isMember = true;
        } else {
          member[m].isMember = false;
        }
      }
      return true;
    }

    function reviewChairs() returns (bool success){
      for(var i=0; i < members.length; i++){
        address m = members[i];
        if (now - member[m].electedChairDate < constitution.electionRules.mandateDuration){
          member[m].isChair = false;
        }
      }
      return true;
    }

    function reviewMemberAdmins() returns (bool success){
      for(var i=0; i < members.length; i++){
        address m = members[i];
        if (now - member[m].electedMemberAdminDate < constitution.electionRules.mandateDuration){
          member[m].isMemberAdmin = false;
        }
      }
      return true;
    }

    function reviewRepresentatives() returns (bool success){
      for(var i=0; i < members.length; i++){
        address m = members[i];
        if (now - member[m].electedRepresentativeDate < constitution.electionRules.mandateDuration){
          member[m].isRepresentative = false;
        }
      }
      return true;
    }

    function reviewTreasurers() returns (bool success){
      for(var i=0; i < members.length; i++){
        address m = members[i];
        if (now - member[m].electedTreasurerDate < constitution.electionRules.mandateDuration){
          member[m].isTreasurer = false;
        }
      }
      return true;
    }
    
    /*
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
    */

    function setJoiningFee(uint fee) onlyTreasurer returns (bool success){
      constitution.memberRules.joiningFee = fee;
      return true;
    }

    function setSubscriptionPeriod(uint period) onlyTreasurer returns (bool success){
      constitution.memberRules.subscriptionPeriod = period;
      return true;
    }

    function unionBalance() returns (uint balance) {
      return this.balance;
    }

    //create new issue
  function addIssue(string description, uint deadline, uint budget) returns (bool success){
      issues.push(Issue(msg.sender, description, false, now, 0, 0, deadline, budget));
      //credit each member with a vote
      for(var i=0; i < members.length; i++){
        if(member[members[i]].isMember){
          votes[members[i]]++;
        }
      }
      return true;
  }

    function selectAgenda(){
    var totalVoters=getMemberCount();
        for(var i=0; i < issues.length; i++){
        var percentVoters = ((issues[i].approve+issues[i].disapprove)/totalVoters)*100;
        var percentApproval = (issues[i].approve/issues[i].disapprove)*100;

          // 28 days after submission if the consultation level is reached AND the approval rate is not met then disable the issue.
          if(((issues[i].date)+(60*60*24*28)<now) && (percentVoters>constitution.issueRules.minConsultationLevel) && (percentApproval<constitution.issueRules.minApprovalRate)){
            issues[i].visible=false;
          }

        }
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

  //get membership count
  function getMemberCount() returns (uint count){
      count = members.length;
  }

  function getActiveMemberCount() returns (uint count){
    count = 0;
    for(var i=0; i < members.length; i++){
      if(member[members[i]].isMember){
        count ++;
      }
    }
    return count;
  }

  function getTreasurerCount() returns (uint count){
    count = 0;
    for(var i=0; i < members.length; i++){
      if(member[members[i]].isTreasurer){
        count ++;
      }
    }
    return count;
  }

  function getChairCount() returns (uint count){
    count = 0;
    for(var i=0; i < members.length; i++){
      if(member[members[i]].isChair){
        count ++;
      }
    }
    return count;
  }

  function getMemberAdminCount() returns (uint count){
    count = 0;
    for(var i=0; i < members.length; i++){
      if(member[members[i]].isMemberAdmin){
        count ++;
      }
    }
    return count;
  }

  function getRepresentativeCount() returns (uint count){
    count = 0;
    for(var i=0; i < members.length; i++){
      if(member[members[i]].isRepresentative){
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
    for(var i=0; i < spends[spend].signatures.length; i++){
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

  function executeSpend(uint spend) onlyTreasurer returns (bool success){
    if(this.balance >= spends[spend].amount && spends[spend].signatures.length >= constitution.spendRules.minSignatures){
      spends[spend].recipient.send(spends[spend].amount);
      spends[spend].spent = true;
      //address reciever = spends[spend].recipient;
      //payments[paymentSerial] =  Payment(msg.sender, reciever, reason, amount, now);
      //paymentSerial++;
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

/*
    function payStipend(member m)  returns(uint result){
        var amountDue=0;
        if(now>(payroll[m.address].lastPaymentDate+60*60*24)){
            if(m.isMemberAdmin==true){
                amountDue+= constitution.stipendRules.stipendMemberAdmin;
            }
            if(m.isTreasurer==true){
                amountDue+= constitution.stipendRules.stipendTreasurer;
            }
            if(m.isRepresentative==true){
                amountDue+= constitution.stipendRules.stipendRepresentative;
            }
            if(m.isChair==true){
                amountDue+= constitution.stipendRules.stipendChair;
            }
            if(payroll.contains[m.address]{
                payroll[m.address].dueAmount=amountDue;
                payroll[m.address].lastPaymentDate=now;
            }
            else{
                thisPayroll = Payroll(m.address,amountDue,now);
                payroll.push(thisPayroll);
            }
            return 1;
        }
        return 0;
    }
*/

    // Clauses -->
    // GeneralRules == 1_
    // ElectionRules == 2_
    // MemberRules == 3_
    // StipendRules == 4_
    // SpendRules == 5_
    // TokenRules == 6_
    function executeAmendmentMandate(uint amendment) returns (uint success){
      if(!amendments[amendment].executed && callAmendment(amendment) == 1){
        if(amendments[amendment].clause == 11){
          constitution.generalRules.nbrTreasurer = amendments[amendment].value;
          amendments[amendment].executed = true;
        } else if (amendments[amendment].clause == 12){
          constitution.generalRules.nbrChair = amendments[amendment].value;
          amendments[amendment].executed = true;
        } else if (amendments[amendment].clause == 13){
          constitution.generalRules.nbrRepresentative = amendments[amendment].value;
          amendments[amendment].executed = true;
        } else if (amendments[amendment].clause == 14){
          constitution.generalRules.nbrMemberAdmin = amendments[amendment].value;
          amendments[amendment].executed = true;
        } else if (amendments[amendment].clause == 21){
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
        } else if (amendments[amendment].clause == 41){
           constitution.stipendRules.stipendTreasurer = amendments[amendment].value;
            amendments[amendment].executed = true;
        } else if (amendments[amendment].clause == 42){
            constitution.stipendRules.stipendChair = amendments[amendment].value;
            amendments[amendment].executed = true;
        } else if (amendments[amendment].clause == 43){
          constitution.stipendRules.stipendRepresentative = amendments[amendment].value;
            amendments[amendment].executed = true;
        } else if (amendments[amendment].clause == 44){
            constitution.stipendRules.stipendMemberAdmin = amendments[amendment].value;
            amendments[amendment].executed = true;
        } else if (amendments[amendment].clause == 51){
            constitution.spendRules.threshold = amendments[amendment].value;
            amendments[amendment].executed = true;
        } else if (amendments[amendment].clause == 52){
            constitution.spendRules.minSignatures = amendments[amendment].value;
            amendments[amendment].executed = true;
        } else if (amendments[amendment].clause == 61){
            constitution.tokenRules.memberCredit = amendments[amendment].value;
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
      } else if (member[msg.sender].isMember && tokens[msg.sender] >= _value - constitution.tokenRules.memberCredit) {
        tokens[msg.sender] -= _value;
        tokens[_to] += _value;
      } else {
        return false;
      }
    }

  function endorseMember(address m) onlyMember returns (bool success){
    //check hasn't already endorsed member
    bool hasEndorsed = false;
    for(var i = 0; i < member[m].endorsements.length; i++){
      if(member[m].endorsements[i] == msg.sender){
        hasEndorsed = true;
        break;
      }
    }
    if(!hasEndorsed){
      member[m].endorsements.push(msg.sender);
      return true;
    }
    return false;
  }

  function revokeEndorsement(address m) onlyMember returns (bool success){
    bool hasEndorsed = false;
    uint index = 0;
    for(var i = 0; i < member[m].endorsements.length; i++){
      if(member[m].endorsements[i] == msg.sender){
        hasEndorsed = true;
        index = i;
        break;
      }
    }
    if(hasEndorsed){
      delete member[m].endorsements[index];
      return true;
    }
    return false;
  }

  function setSalary(uint amount) canSetSalary returns (bool success){
    if(amount <= constitution.tokenRules.salaryCap && member[msg.sender].exists){
      member[msg.sender].salary = amount;
      return true;
    }
    return false;
  }

  function paySalary() returns (bool success){
    if(now - tokenPayments[tokenPayments.length - 1].paymentDate >= constitution.tokenRules.salaryPeriod) {
      uint amountPaid = 0;
      for(var i = 0; i < members.length; i++){
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