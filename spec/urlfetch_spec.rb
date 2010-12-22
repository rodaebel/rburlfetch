require 'urlfetch'


describe Urlfetch do
  describe "#pack" do
    it "packs binary data" do
      Urlfetch.pack(3, "foo").should == "\003foo"
      Urlfetch.pack(3, "foo", 4, "test").should == "\003foo\004test"
    end
  end
end
