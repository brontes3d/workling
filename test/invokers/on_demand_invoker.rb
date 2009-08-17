class OnDemandInvoker < Workling::Remote::Invokers::ThreadedPoller
  
  def initialize(client)
    client_class = client.class
    @client = client
    super(Workling::Routing::ClassAndMethodRouting.new, client_class)
  end
  
  def connect
    yield
  end
  
  def listen
    Workling::Discovery.discovered.each do |clazz|
      dispatch!(@client, clazz)
    end
  end
  
  def stop
    #ok
  end
  
end