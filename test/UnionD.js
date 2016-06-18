contract('UnionD', function(accounts) {

  it("should make creator a member", function(done) {
    var uniond = Uniond.deployed();
    uniond.member.call(accounts[0], {from: accounts[0]}).then(function(result) {
      assert.equal(result[3], true, 'creator not made a member');
    }).then(done).catch(done);
  });

  it("should set tokenSupply to 0 initially", function(done) {
    var uniond = Uniond.deployed();
    uniond.totalSupply.call({from: accounts[0]}).then(function(result) {
      assert.equal(result, 0, 'tokenSupply not set to 0');
    }).then(done).catch(done);
  });

  it("should be able to get Member count", function(done) {
    var uniond = Uniond.deployed();
    uniond.getMemberCount.call({from: accounts[0]}).then(function(result) {
      assert.equal(result, 1, 'member count not set to 1');
    }).then(done).catch(done);
  });

  it("should be able to review active members", function(done) {
    var uniond = Uniond.deployed();
    uniond.reviewActiveMembers(0, 1, {from: accounts[0]}).then(function(result) {
      return uniond.activeMembers.call();
    }).then(function(result) {
      assert.equal(result.toNumber(), 1, 'active member count not set to 1')
    }).then(done).catch(done);
  });

  it("should be able to add new member", function(done) {
    var uniond = Uniond.deployed();
    uniond.applyMember({from: accounts[1], value: 1000}).then(function(result) {
      return uniond.addMember(accounts[1], {from: accounts[0]});
    }).then(function(result) {
      return uniond.member.call(accounts[1]);
    }).then(function(result) {
      assert.equal(result[3], true, 'accounts[1] not a member')
    }).then(done).catch(done);
  });

});