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
    uniond.getMemberCount.call().then(function(result){
      //console.log("getmembercount", result);
      return uniond.reviewActiveMembers(0, result.toNumber(), {from: accounts[0]});
    }).then(function(result) {
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
      // console.log("new member", result);
      assert.equal(result[3], true, 'accounts[1] not a member')
    }).then(done).catch(done);
  });

  it("should be able to recieve funds", function(done) {
    var uniond = Uniond.deployed();
    var amount = 1000000;
    var Web3 = require('web3');
    var web3 = new Web3();
    web3.setProvider(new web3.providers.HttpProvider('http://localhost:8545'));    
    web3.eth.sendTransaction({from: accounts[0], to: uniond.address, value: amount});
    var balance = web3.eth.getBalance(uniond.address);
    assert.equal(balance.toNumber(), amount+1000, "funds not recieved");
    done();
  });

  it("should be able to create, sign and execute spends", function(done){
    var uniond = Uniond.deployed();
    uniond.newSpend(1000, accounts[1], {from: accounts[0]}).then(function(result){
      if(result){
        return uniond.signSpend(0, {from: accounts[0]});
      }
    }).then(function(result){
      if(result){
        return uniond.executeSpend(0, 'testing');
      }
    }).then(function(result){
      if(result){
        return uniond.unionBalance();
      }
    }).then(function(balance){
      assert.equal(balance, 1000000, "funds not deducted");
    }).then(done).catch(done)
  });

  it("should not execute spends twice", function(done){
    var uniond = Uniond.deployed();
    uniond.executeSpend(0, 'testing', {from: accounts[0]}).then(function(result){
     return uniond.unionBalance();
    }).then(function(balance){
      assert.equal(balance, 1000000, "funds deducted twice!!");
    }).then(done).catch(done)
  });

  it("should not let non-treasurers sign spends", function(done){
    var uniond = Uniond.deployed();
    uniond.newSpend(1000, accounts[1], {from: accounts[0]}).then(function(result){
      return uniond.signSpend(1, {from: accounts[1]});
    }).then(function(result){
      return uniond.executeSpend(1, 'testing');
    }).then(function(result){
      // console.log(result);
      return uniond.spends.call(1);
    }).then(function(result){
      // console.log(result);
      assert.equal(result[2], false, "spend signed by non treasurer!");
    }).then(done).catch(done)
  });

  it("should not let non-treasurers execute spends", function(done){
    var uniond = Uniond.deployed();
    uniond.newSpend(1000, accounts[1], {from: accounts[0]}).then(function(result){
      return uniond.signSpend(1, {from: accounts[0]});
    }).then(function(result){
      return uniond.executeSpend(1, 'testing', {from: accounts[1]});
    }).then(function(result){
      // console.log(result);
      return uniond.spends.call(1);
    }).then(function(result){
      // console.log(result);
      assert.equal(result[2], false, "spend executed by non treasurer!");
    }).then(done).catch(done)
  });

  it("should not execute spends that aren't signed", function(done){
    var uniond = Uniond.deployed();
    uniond.newSpend(1000, accounts[1], {from: accounts[0]}).then(function(result){
      return uniond.executeSpend(2, 'testing', {from: accounts[1]});
    }).then(function(result){
      // console.log(result);
      return uniond.spends.call(2);
    }).then(function(result){
      // console.log(result);
      assert.equal(result[2], false, "spend executed by non treasurer!");
    }).then(done).catch(done)
  });

  it("should create 101 members", function(done){
    var uniond = Uniond.deployed();

    for(var i=2; i < 101; i++){
      uniond.applyMember({from: accounts[i], value: 1000});
      uniond.addMember(accounts[i], {from: accounts[0]});
    }

    uniond.member.call(accounts[100]).then(function(result){
      assert.equal(result[3], true, "100th member not added")
    }).then(done).catch(done)

  });

  it("should be able to create an election", function(done){
    var uniond = Uniond.deployed();

    uniond.addElection(accounts[100], 1).then(function(result){
      return uniond.elections.call(0);
    }).then(function(result){
      assert.equal(result[1], accounts[100], "member not up for election");
    }).then(done).catch(done);

  });

  it("should be able to call an election loss", function(done){
    var uniond = Uniond.deployed();

    for(var i = 0; i < 40; i++){
      uniond.voteElection(0);
    }

    uniond.getMemberCount.call().then(function(result){
      console.log("membercount", result);
      var end = result.toNumber();
      console.log('end', end);
      return uniond.reviewActiveMembers(0, end, {from: accounts[0]});
    }).then(function(result){
      console.log("activemembers", result);
      return uniond.callElection.call(0);
    }).then(function(result){
      assert.equal(result, false, "threshold not met -- yet election passed")
    }).then(done).catch(done);

  });

  it("should be able to call an election win", function(done){
    var uniond = Uniond.deployed();

    uniond.addElection(accounts[98], 1);

    for(var i = 0; i < 60; i++){
      uniond.voteElection(1, {from: accounts[i]});
    }

    uniond.callElection.call(1).then(function(result){
      //console.log(result);
      assert.equal(result, true, "threshold met -- yet election not passed");
    }).then(done).catch(done);

  });

  it("should be able to review activeMembers", function(done){
    var uniond = Uniond.deployed();

    uniond.activeMembers.call().then(function(result){
      console.log('init activemembers', result);
      return uniond.getMemberCount.call();
    }).then(function(result){
      var end = result.toNumber()
      console.log(end);
      return uniond.reviewActiveMembers(0, end, {from: accounts[0]})
    }).then(function(result){
      //console.log(result);
      return uniond.activeMembers.call();
    }).then(function(members){
      console.log("activemembers", members);
    }).then(done).catch(done);
  })

  // it("should be able to review activeMembers in batches", function(done){
  //   var uniond = Uniond.deployed();

  //   uniond.getMemberCount.call().then(function(result){
  //     return uniond.reviewActiveMembers(0, result.toNumber(), {from: accounts[0]})
  //   }).then(function(result){
  //     //console.log(result);
  //     return uniond.activeMembers.call();
  //   }).then(function(members){
  //     //console.log("activemembers", members);
  //   }).then(done).catch(done);
  // })


  // it("should be able to do maths", function(done){
  //   var uniond = Uniond.deployed()
  //   uniond.test.call().then((result)=>{
  //     console.log(result.toNumber());
  //   }).then(done).catch(done);
  // })


});