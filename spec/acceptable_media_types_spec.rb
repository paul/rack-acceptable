require File.expand_path("../spec_helper", __FILE__)

describe "Acceptable media types hander" do

  describe "#include?" do
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
  end

  describe "#preference_of?" do
    it 'should pick the first one by order' do
      mt = Rack::Request::AcceptableMediaTypes.new("text/html,application/xml")
      mt.preference_of('application/xml,text/html').should == 'text/html'
    end

    it 'should pick by quality' do
      mt = Rack::Request::AcceptableMediaTypes.new("text/html;q=0.9,application/xml;q=1.0")
      mt.preference_of('application/xml,text/html').should == 'application/xml'
    end
  end

  describe "#prioritize" do
    it 'should order them by client order' do
      mt = Rack::Request::AcceptableMediaTypes.new("text/html,application/xml")
      mt.prioritize('application/xml,text/html').should == ["text/html", "application/xml"]
    end

    it 'should order them by quality' do
      mt = Rack::Request::AcceptableMediaTypes.new("text/html;q=0.9,application/xml;q=1.0")
      mt.prioritize('application/xml,text/html').should == ['application/xml', 'text/html']
    end
  end

  describe "#first_acceptable" do
    it 'should pick the first media type that is acceptable' do
      mt = Rack::Request::AcceptableMediaTypes.new("text/html,application/xml")
      mt.first_acceptable('image/png,application/xml').should == 'application/xml'
    end

    it 'should pick the first given media type, even if its not the most preferred by quality' do
      mt = Rack::Request::AcceptableMediaTypes.new("text/html;q=0.5,application/xml")
      mt.first_acceptable('text/html,application/xml').should == 'text/html'
    end

    it 'should serve html to safari\'s broken-ass Accept header' do
      safari_accept = "application/xml,application/xhtml+xml,text/html;q=0.9,text/plain;q=0.8,image/png,*/*;q=0.5"
      mt = Rack::Request::AcceptableMediaTypes.new(safari_accept)
      mt.first_acceptable('text/html,application/xml').should == 'text/html'
    end
  end

  describe 'initialization' do
    it 'should take a http accept header string' do
      mt = Rack::Request::AcceptableMediaTypes.new("application/xml,text/html")
      mt.should have(2).items
    end

    it 'should take an array of media type strings' do
      mt = Rack::Request::AcceptableMediaTypes.new("application/xml", "text/html")
      mt.should have(2).items
    end

    it 'should take an array of MediaType objects' do
      xml = Rack::Request::AcceptableMediaTypes::MediaType.new("application/xml")
      html = Rack::Request::AcceptableMediaTypes::MediaType.new("text/html")
      mt = Rack::Request::AcceptableMediaTypes.new(xml, html)
      mt.should have(2).items
    end
    
    it 'should not arbitrarily reorder media types with no quality param' do
      mt = Rack::Request::AcceptableMediaTypes.new("application/xml,text/html")
      mt.first.should == "application/xml"
      mt.last.should  == "text/html"
    end
  end

end
