require 'workling/remote/runners/base'

class TestQRunner < Workling::Remote::Runners::ClientRunner
  
  def initialize(with_client)
    @@client = with_client
    super()
  end
  
  def self.client
    @@client
  end  
  
end