contract('Uniond', function(accounts)
{
  it("Init Uniond", function(done)
  {
    var meta = Uniond.deployed();
    
    meta.issueSerial.call().then(function(issueSerial)
    {
      console.log("issueSerial = " + issueSerial.toNumber() );
      assert.equal(issueSerial.toNumber(), 0, "issue serial was not set to 0");
    }).then(done).catch(done);
  });
  
  it("set joining free", function(done)
  {
    var meta = Uniond.deployed();
    
    meta.setJoiningFee.call(100000).then(function(success)
    {
      console.log("setJoiningFee success = " + success);
      assert.equal(success, true, "could not set joining free");
    }).then(done).catch(done);
  });
});