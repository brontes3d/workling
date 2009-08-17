require File.dirname(__FILE__) + '/test_helper.rb'

context "with TestQRunner (wrapping MemoryQueueClient) and OnDemandInvoker" do
  setup do
    @old_dispatcher = Workling::Remote.dispatcher
    @old_invoker = Workling::Remote.invoker        
    @client = Workling::Clients::MemoryQueueClient.new
    
    Workling::Remote.dispatcher = TestQRunner.new(@client)
    @invoker = OnDemandInvoker.new(@client)
    Workling::Remote.invoker = @invoker

  end
  teardown do
    Workling::Remote.dispatcher = @old_dispatcher
    Workling::Remote.invoker = @old_invoker
  end
  
  #should invoke echo on SendOnlyUtil as soon as inserted into Q
  specify "on SendOnlyUtil.async_echo: should immediately invoke echo" do
    SendOnlyUtil.any_instance.expects(:echo).once
    SendOnlyUtil.async_echo(:test => "hi")
  end

  #should NOT invoke echo on Util as soon as inserted into Q
  specify "on SendOnlyUtil.async_echo: should immediately invoke echo" do
    Util.any_instance.expects(:echo).never
    Util.async_echo(:test => "hi")
  end
  
  specify "on SendOnlyUtil.async_echo: should put into Q but not run" do
    @client.expects(:request).with do |(val1, val2)| 
      val1 == "send_only_utils__echo" &&
      val2.is_a?(Hash) &&
      val2[:test] == "hi"
    end
    SendOnlyUtil.async_echo(:test => "hi")
  end
  
  #should invoke echo on Util when Q is run, but not on SendOnlyUtil  
  #should NOT invoke echo on SendOnlyUtil when Q is run
  specify "should call invoke the async method on Util but not SendOnlyUtil when listen is called" do
    @client.request("send_only_utils__echo", {:test => "hi"})
    @client.request("utils__echo", {:test => "hi"})
    Util.any_instance.expects(:echo).once
    SendOnlyUtil.any_instance.expects(:echo).never    
    @invoker.listen
  end
  
end
