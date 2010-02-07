require 'rubygems'
require 'rbench'
require File.expand_path('../../lib/rack/acceptable', __FILE__)

TIMES = 10_000

SIMPLE = "text/html"
SAFARI = "application/xml,application/xhtml+xml,text/html;q=0.9,text/plain;q=0.8,image/png,*/*;q=0.5"

ONE = "text/html"
THREE = "text/html,application/xml,application/xhtml+xml"

RBench.run(TIMES) do

  column :one,   :title => "One choice"
  column :three, :title => "Three choices"

  report "Simple #{SIMPLE}" do
    one { Rack::Request::AcceptableMediaTypes.new(SIMPLE).first_acceptable(ONE) }
    three { Rack::Request::AcceptableMediaTypes.new(SIMPLE).first_acceptable(THREE) }
  end

  report "Safari" do
    one { Rack::Request::AcceptableMediaTypes.new(SAFARI).first_acceptable(ONE) }
    three { Rack::Request::AcceptableMediaTypes.new(SAFARI).first_acceptable(THREE) }
  end

end
