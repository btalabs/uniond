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

  it("should set tokenSupply to 0 initially", function(done) {
    var uniond = Uniond.deployed();
    uniond.totalSupply.call({from: accounts[0]}).then(function(result) {
      assert.equal(result, 0, 'tokenSupply not set to 0');
    }).then(done).catch(done);
  });

});