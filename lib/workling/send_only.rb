module Workling
  class SendOnly < Base
    
    def self.inherited(subclass)
      #Don't call super, override Base.inherited so this worker won't be discovered
    end

    def prepare_for_method(method, options)
      self.send(method, options)
    end
    
    def dispatch_to_worker_method(method, options = {})
      raise ArgumentError, "No worker method invocation allowed. #{self} is a send only worker!"
    end
    
  end
end
Workling::Discovery.discovered.delete(Workling::SendOnly)
