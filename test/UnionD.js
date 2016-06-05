contract('Uniond', function(accounts)
{
  it("Init Uniond", function(done)
  {
    var uniond = Uniond.deployed();
    
    uniond.members.call().then(function(member)
    {
      console.log("init member = " + member);
      //assert.equal(issueSerial.toNumber(), 0, "issue serial was not set to 0");
    }).then(done).catch(done);
  });


});