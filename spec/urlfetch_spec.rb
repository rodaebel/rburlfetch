require 'urlfetch'


describe Urlfetch do

  describe "#pack" do
    it "packs binary data" do
      Urlfetch.pack(3, "foo").should == "\003foo"
      Urlfetch.pack(3, "foo", 4, "test").should == "\003foo\004test"
    end
  end

  describe "#command" do
    it "encodes a command sequence" do
      Urlfetch.command("foo").should == "foo"
      Urlfetch.command("foo", "bar").should == "\003foobar"
      Urlfetch.command("foo", "test", "bar").should == "\003foo\004testbar"
    end
  end

end
