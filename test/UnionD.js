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

  it("should be able to get Member count", function(done) {
    let uniond = Uniond.deployed();
    uniond.getMemberCount.call({from: accounts[0]}).then((result) => {
      assert.equal(result, 1, 'member count not set to 1');
    }).then(done).catch(done);
  });

  it("should be able to review active members", function(done) {
    let uniond = Uniond.deployed();
    uniond.getMemberCount.call().then((result) => {
      return uniond.reviewActiveMembers(0, result.toNumber(), {from: accounts[0]});
    }).then((result) => {
      return uniond.activeMembers.call();
    }).then((result) => {
      assert.equal(result.toNumber(), 1, 'active member count not set to 1')
    }).then(done).catch(done);
  });

  it("should be able to add new member", function(done) {
    var uniond = Uniond.deployed();
    uniond.applyMember({from: accounts[1], value: 1000}).then((result) => {
      return uniond.addMember(accounts[1], {from: accounts[0]});
    }).then((result) => {
      return uniond.member(accounts[1]);
    }).then((result) => {
      assert.equal(result[3], true, 'accounts[1] not a member')
    }).then(done).catch(done);
  });

  it("should be able to create an issue", function(done) {
    let uniond = Uniond.deployed();
    uniond.addIssue("test").then((result) => {
      return uniond.vote(0, true, 1, {from: accounts[0]});
    }).then((result) => {
      return uniond.issues(0);
    }).then((result) => {
      assert.equal(result[3].toNumber(), 1, "vote approve not 1");
    }).then(done).catch(done);
  })

  it("should be able to transfer votes to a proxy", function(done) {
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

  it("should be able to get Uniond balance", function(done) {
    let uniond = Uniond.deployed();
    uniond.unionBalance().then((result) => {
      assert.equal(result.toNumber(), 1000, "uniond balance not correct");
    }).then(done).catch(done);
  })

});