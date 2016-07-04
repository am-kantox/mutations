require 'minitest/unit'
require 'minitest/autorun'
require 'pry'
require 'pp'

$LOAD_PATH.unshift File.expand_path(File.dirname(__FILE__))
$LOAD_PATH.unshift File.expand_path(File.dirname(__FILE__) + '/../lib')

require 'mutations'
