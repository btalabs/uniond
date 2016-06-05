contract('Uniond', function(accounts)
{

  it("Add Member to Uniond", function(done)
  {
    var uniond = Uniond.deployed();

    var account_one = accounts[0];

    //console.log(uniond);
    
    uniond.addMemberTest.call(account_one).then(function(result)
    {
      console.log("add member = ", result);
      assert.equal(result, true, "member wasn't added");
    }).then(done).catch(done);
  });

  it("Check Member exists", function(done)
  {
    var uniond = Uniond.deployed();
    
    uniond.member.call(accounts[0]).then(function(member)
    {
      console.log("check member = ", member);
      assert.equal(member[2], true, "member doens't exist");
    }).then(done).catch(done);
  });

  it("Check supply of tokens", function(done)
  {
    var uniond = Uniond.deployed();
    
    uniond.tokenSupply.call().then(function(supply)
    {
      console.log("tokenSupply  = ", supply.toNumber());
      assert.equal(supply.toNumber(), 0, "supply not equal 0");
    }).then(done).catch(done);
  });


});