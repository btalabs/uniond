contract('UnionD', function(accounts) {

  it("should make creator a member", function(done) {
    let uniond = Uniond.deployed();
    uniond.member.call(accounts[0], {from: accounts[0]}).then((result) => {
      assert.equal(result[3], true, 'creator not made a member');
    }).then(done).catch(done);
  });

  it("should set tokenSupply to 1000000 initially", function(done) {
    let uniond = Uniond.deployed();
    uniond.totalSupply.call({from: accounts[0]}).then((result) => {
      assert.equal(result.toNumber(), 1000000, 'tokenSupply not set to 0');
    }).then(done).catch(done);
  });

  it("should get Member count", function(done) {
    let uniond = Uniond.deployed();
    uniond.getMemberCount.call({from: accounts[0]}).then((result) => {
      assert.equal(result, 1, 'member count not set to 1');
    }).then(done).catch(done);
  });

  it("should review active members", function(done) {
    let uniond = Uniond.deployed();
    uniond.getMemberCount.call().then((result) => {
      return uniond.reviewActiveMembers(0, result.toNumber(), {from: accounts[0]});
    }).then((result) => {
      return uniond.activeMembers.call();
    }).then((result) => {
      assert.equal(result.toNumber(), 1, 'active member count not set to 1')
    }).then(done).catch(done);
  });

  it("should add new member", function(done) {
    var uniond = Uniond.deployed();
    uniond.applyMember({from: accounts[1], value: 1000}).then((result) => {
      return uniond.addMember(accounts[1], {from: accounts[0]});
    }).then((result) => {
      return uniond.member(accounts[1]);
    }).then((result) => {
      assert.equal(result[3], true, 'accounts[1] not a member')
    }).then(done).catch(done);
  });

  it("should create an issue", function(done) {
    let uniond = Uniond.deployed();
    uniond.addIssue("test").then((result) => {
      return uniond.vote(0, true, 1, {from: accounts[0]});
    }).then((result) => {
      return uniond.issues(0);
    }).then((result) => {
      assert.equal(result[3].toNumber(), 1, "vote approve not 1");
    }).then(done).catch(done);
  })

  it("should transfer votes to a proxy", function(done) {
    let uniond = Uniond.deployed();
    uniond.transferVotes(accounts[0], 1, {from: accounts[1]}).then((result) => {
      return uniond.member(accounts[0]);
    }).then((result) => {
      assert.equal(result[result.length -1].toNumber(), 1, "vote not transferred");
      return uniond.vote(0, true, 1, {from: accounts[0]});
    }).then((result) => {
      return uniond.issues(0);
    }).then((result) => {
      assert.equal(result[3].toNumber(), 2, "vote approve not 2");
    }).then(done).catch(done);
  })

  it("should not allow member to vote more than they have votes", function(done){
    let uniond = Uniond.deployed();
    uniond.totalVotes({from: accounts[0]}).then((result) => {
      assert.equal(result.toNumber(), 0, "incorrect amount of votes");
      return uniond.addIssue("test2");
    }).then((result) => {
      return uniond.totalVotes({from: accounts[0]});
    }).then((result) => {
      assert.equal(result.toNumber(), 1, "incorrect amount of votes");
      return uniond.vote(1, true, 1, {from: accounts[0]});
    }).then((result) => {
      return uniond.totalVotes({from: accounts[0]});
    }).then((result) => {
      assert.equal(result.toNumber(), 0, "incorrect amount of votes");
      return uniond.vote(1, true, 1, {from: accounts[0]});
    }).then((result) => {
      return uniond.issues(1);
    }).then((result) => {
      assert.equal(result[3].toNumber(), 1, "vote not cast");
    }).then(done).catch(done);
  })

  it("should get Uniond balance", function(done) {
    let uniond = Uniond.deployed();
    uniond.unionBalance().then((result) => {
      assert.equal(result.toNumber(), 1000, "uniond balance not correct");
    }).then(done).catch(done);
  })

  it("should run a general election", function(done) {
    let uniond = Uniond.deployed();
    //elect accounts[3] to treasurer
    uniond.addElection(accounts[3], 1, {from: accounts[0]}).then((result) => {
      return uniond.voteElection(0, {from: accounts[0]});
    }).then((result) => {
      return uniond.voteElection(0, {from: accounts[1]});
    }).then((result) => {
      return uniond.reviewActiveMembers(0, 1, {from: accounts[0]});
    }).then((result) => {
      return uniond.callElection.call(0);
    }).then((result) => {
      return uniond.applyMember({from: accounts[3], value: 1000});
    }).then((result) => {
      return uniond.executeElectionMandate(0);
    }).then((result) => {
      return uniond.member(accounts[3]);
    }).then((result) => {
      assert.equal(result[6], true, "accounts[3] is not a treasurer");
    }).then(done).catch(done);
  })

  it("should pass an ammendment", function(done) {
    let uniond = Uniond.deployed();
    uniond.newAmendment("test", 2, 55, {from: accounts[0]}).then((result) => {
      return uniond.voteAmendment(0, {from: accounts[0]});
    }).then((result) => {
      return uniond.voteAmendment(0, {from: accounts[1]});
    }).then((result) => {
      return uniond.executeAmendmentMandate(0);
    }).then((result) => {
      return uniond.constitution(2);
    }).then((result) => {
      assert.equal(result.toNumber(), 55, "amendment not passed");
    }).then(done).catch(done);
  })

  it("should pass an election with many votes", function(done) {
    let applyMember = (uniond, count) => {
      promises = [];
      for(let i = 0; i < count; i++){
        promises.push(uniond.applyMember({from: accounts[i], value: 1000}));
      }
      return promises;
    }

    let addMember = (uniond, count) => {
      promises = [];
      for(let i = 0; i < count; i++){
        promises.push(uniond.addMember(accounts[i], {from: accounts[0]}));
      }
      return promises;
    }

    let voteMany = (uniond, count, electionIndex) => {
      promises = [];
      for(let i = 0; i < count; i++){
        promises.push(uniond.voteElection(electionIndex, {from: accounts[i]}));
      }
      return promises;
    }

    let uniond = Uniond.deployed();

    Promise.all(applyMember(uniond, 100)).then((results) => {
      return Promise.all(addMember(uniond, 100));
    }).then((result) => {
      return uniond.addElection(accounts[4], 2, {from: accounts[0]});
    }).then((result) => {
      return uniond.reviewActiveMembers(0, 100, {from: accounts[0]});
    }).then((result) => {
      return uniond.getMemberCount.call();
    }).then((result) => {
      return uniond.activeMembers.call();
    }).then((result) => {
      return Promise.all(voteMany(uniond, 56, 1));
    }).then((result) => {
      return uniond.elections.call(1);
    }).then((result) => {
      return uniond.executeElectionMandate(1);
    }).then((result) => {
      return uniond.member(accounts[4]);
    }).then((result) => {
      assert.equal(result[5], true, "accounts[4] not made a member admin")
    }).then(done).catch(done);
  })

});