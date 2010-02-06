require File.expand_path("../spec_helper", __FILE__)

describe "Acceptable media types hander" do

  it 'should know if it includes a media type' do
    mt = Rack::Request::AcceptableMediaTypes.new("text/html")
    mt.include?("text/html").should be_true
    mt.include?("application/xml").should be_false
  end

  it 'should know if */* includes any media type' do
    mt = Rack::Request::AcceptableMediaTypes.new("*/*")
    mt.include?("text/html").should be_true
    mt.include?("application/xml").should be_true
  end

  it 'should know if text/* includes any media subtype' do
    mt = Rack::Request::AcceptableMediaTypes.new("text/*")
    mt.include?("text/html").should be_true
    mt.include?("application/xml").should be_false
  end

  describe "preferred media type" do
    it 'should pick the first one by order' do
      mt = Rack::Request::AcceptableMediaTypes.new("text/html,application/xml")
      mt.preference_of('application/xml,text/html').should == 'text/html'
    end

    it 'should pick by quality' do
      mt = Rack::Request::AcceptableMediaTypes.new("text/html;q=0.9,application/xml;q=1.0")
      mt.preference_of('application/xml,text/html').should == 'application/xml'
    end

    it 'should work around busted-ass browsers' do
      safari_accept = "application/xml,application/xhtml+xml,text/html;q=0.9,text/plain;q=0.8,image/png,*/*;q=0.5"
      mt = Rack::Request::AcceptableMediaTypes.new(safari_accept)
      mt.preference_of('text/html,application/xml', true).should == 'text/html'
    end
  end
end
