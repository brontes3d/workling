require File.dirname(__FILE__) + '/test_helper.rb'

context "the remote runner" do
  specify "should be able to invoke a task on a worker" do
    Util.any_instance.stubs(:echo).with("hello")
    Workling::Remote.run(:util, :echo, "hello")
  end
  
  specify "should invoke the dispatcher set up in Workling::Remote.dispatcher" do
    clazz, method, options = :util, :echo, { :message => "somebody_came@along.com" }
    old_dispatcher = Workling::Remote.dispatcher
    dispatcher = mock
    dispatcher.expects(:run).with(clazz, method, options)
    Workling::Remote.dispatcher = dispatcher
    Workling::Remote.run(clazz, method, options)
    Workling::Remote.dispatcher = old_dispatcher # set back to whence we came
  end
  
  specify "should, when being tested, use the default remote runner by when no runner was explicitly set. " do
    Workling::Remote.dispatcher.class.should.equal Workling.default_runner.class
  end
  
  specify "should raise a Workling::WorklingNotFoundError if it is invoked with a worker key that cannot be constantized" do
    should.raise Workling::WorklingNotFoundError do
      Workling::Remote.run(:quatsch_mit_sosse, :fiddle_di_liddle)
    end
  end
  
  specify "should raise a Workling::WorklingNotFoundError if it is invoked with a valid worker key but the method is not defined on that worker" do
    dispatcher = Workling::Remote.dispatcher
    Workling::Remote.dispatcher = Workling::Remote::Runners::ThreadRunner.new # simulates a remote runner (workling in another context)
    
    should.raise Workling::WorklingNotFoundError do
      Workling::Remote.run(:util, :sau_sack)
    end
    
    Workling::Remote.dispatcher = dispatcher
  end
  
  specify "should invoke work when called in this way: YourWorkling.asynch_your_method(options)" do
    Util.any_instance.expects(:echo).once
    Util.asynch_echo
  end
  
  specify "should invoke work with the arguments intact when called in this way: YourWorkling.asynch_your_method(options)" do
    stuffing = { :description => "toasted breadcrumbs with dill" }
    Util.any_instance.expects(:stuffing).with(stuffing).once
    Util.asynch_stuffing(stuffing)
  end

  specify "should use default arguments if they exist" do
    default_options = { :flavor => 'purple' }
    custom_options  = { :color  => 'purple' }
    Util.any_instance.expects(:default_options).returns(default_options)
    Util.any_instance.expects(:stuffing).with(all_of(has_entry(:flavor => 'purple'), has_entry(:color => 'purple'))).once
    Util.asynch_stuffing(custom_options)
  end
  
  specify "should pass options through prepare_options before serialize" do
    class PreparedUtil < Util
      def prepare_options(options)
        options[:flavor] = "delicious"
      end
    end
    custom_options  = { :color  => 'nutritious' }
    PreparedUtil.any_instance.expects(:stuffing).with(all_of(has_entry(:flavor => 'delicious'), has_entry(:color => 'nutritious'))).once
    PreparedUtil.asynch_stuffing(custom_options)
  end
  
end
