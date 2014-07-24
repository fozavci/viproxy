$:.unshift(File.dirname(__FILE__) + '/../lib')


require "rubygems"
require "eventmachine"
require "socket"

%w[ backend proxy connection ].each do |file|
  require "viproxy/#{file}"
end
