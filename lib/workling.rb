#
#  I can haz am in your Workling are belong to us! 
#
require 'mattr_accessor' unless Module.respond_to?(:mattr_accessor)
require 'cattr_accessor' unless Class.respond_to?(:cattr_accessor)

gem 'activesupport'
require 'active_support/inflector'
require 'active_support/core_ext/hash/keys'

class Hash #:nodoc:
  include ActiveSupport::CoreExtensions::Hash::Keys
end

require 'yaml'

module Workling
  class WorklingError < StandardError; end
  class WorklingNotFoundError < WorklingError; end
  class WorklingConnectionError < WorklingError; end
  class QueueserverNotFoundError < WorklingError
    def initialize
      super "config/workling.yml configured to connect to queue server on #{ Workling.config[:listens_on] } for this environment. could not connect to queue server on this host:port. for starling users: pass starling the port with -p flag when starting it. If you don't want to use Starling, then explicitly set Workling::Remote.dispatcher (see README for an example)"
    end
  end

  class ConfigurationError < WorklingError
    def initialize
      super File.exist?(Workling.path('config', 'starling.yml')) ? 
        "config/starling.yml has been depracated. rename your config file to config/workling.yml then try again!" :
        "config/workling.yml could not be loaded. check out README.markdown to see what this file should contain. "
    end
  end
  
  def self.path(*args)
    if defined?(RAILS_ROOT)
      File.join(RAILS_ROOT, *args)
    else
      File.join(Dir.pwd, *args)
    end
  end

  def self.env
    @env ||= if defined?(RAILS_ENV)
               RAILS_ENV.to_s
             elsif defined?(RACK_ENV)
               RACK_ENV.to_s
             end
  end

  mattr_accessor :load_path
  @@load_path = [ File.expand_path(path('app', 'workers', '*.rb')) ]

  VERSION = "0.4.9"

  #
  # determine the runner to use if nothing is specifically set. workling will try to detect
  # starling, spawn, or bj, in that order. if none of these are found, notremoterunner will
  # be used. 
  #
  # this can be overridden by setting Workling::Remote.dispatcher, eg:
  #   Workling::Remote.dispatcher = Workling::Remote::Runners::StarlingRunner.new
  #
  def self.default_runner
    if env == "test"
      Workling::Remote::Runners::NotRemoteRunner.new
    elsif starling_installed?
      Workling::Remote::Runners::StarlingRunner.new
    elsif spawn_installed?
      Workling::Remote::Runners::SpawnRunner.new
    elsif bj_installed?
      Workling::Remote::Runners::BackgroundjobRunner.new
    else
      Workling::Remote::Runners::NotRemoteRunner.new
    end
  end
  
  #
  # gets the worker instance, given a class. the optional method argument will cause an 
  # exception to be raised if the worker instance does not respoind to said method. 
  #
  def self.find(clazz, method = nil)
    begin
      inst = clazz.to_s.camelize.constantize.new 
    rescue NameError
      raise_not_found(clazz, method)
    end
    raise_not_found(clazz, method) if method && !inst.respond_to?(method)
    inst
  end
  
  # returns Workling::Return::Store.instance. 
  def self.return
    Workling::Return::Store.instance
  end

  # is spawn installed?
  def self.spawn_installed?
    begin
      require 'spawn'
    rescue LoadError
    end

    Object.const_defined? "Spawn"
  end

  # is starling installed?  
  def self.starling_installed?
    begin
      require 'starling' 
    rescue LoadError
    end
      
    Object.const_defined? "Starling"
  end

  # is bj installed?
  def self.bj_installed?
    Object.const_defined? "Bj"
  end
  
  # Attempts to load the memcache-client gem
  def self.try_load_a_memcache_client
    begin
      gem 'memcache-client'
      require 'memcache'
    rescue Gem::LoadError
      Workling::Base.logger.info "WORKLING: couldn't find memcache-client. Install: \"gem install memcache-client\". "
    end
  end
  
  # attempts to load amqp and writes out descriptive error message if not present
  def self.try_load_an_amqp_client
    begin
      require 'mq'
    rescue Exception => e
      raise WorklingError.new(
        "WORKLING: couldn't find the ruby amqp client - you need it for the amqp runner. " \
        "Install from github: gem sources -a http://gems.github.com/ && sudo gem install tmm1-amqp "
      )
    end
  end

  # attempts to load xmpp4r library and writes out descriptive error message if not present
  def self.try_load_xmpp4r
    begin
      gem "xmpp4r"
      require 'xmpp4r'
      require "xmpp4r/pubsub"
      require "xmpp4r/pubsub/helper/servicehelper.rb"
      require "xmpp4r/pubsub/helper/nodebrowser.rb"
      require "xmpp4r/pubsub/helper/nodehelper.rb"
    rescue Exception => e
      raise WorklingError.new("Couldnt load the XMPP library. check that you have the xmpp4r gem installed")
    end
  end


  #
  #  returns a config hash. reads ./config/workling.yml
  #
  def self.config
    return @@config if defined?(@@config) && @@config

    config_path = File.join(RAILS_ROOT, 'config', 'workling.yml')
    return nil unless File.exists?(config_path)
    
    @@config ||= YAML.load_file(config_path)[RAILS_ENV || 'development'].symbolize_keys
    @@config[:memcache_options].symbolize_keys! if @@config[:memcache_options]
    @@config
  end
  
  #
  #  Raises exceptions thrown inside of the worker. normally, these are logged to 
  #  logger.error. it's easy to miss these log calls while developing, though. 
  #
  mattr_accessor :raise_exceptions
  @@raise_exceptions = (RAILS_ENV == "test" || RAILS_ENV == "development")
  
  def self.raise_exceptions?
    @@raise_exceptions
  end
  
  private
    def self.raise_not_found(clazz, method)
      raise Workling::WorklingNotFoundError.new("could not find #{ clazz }:#{ method } workling. ") 
    end
end

require "workling/discovery"
require "workling/base"
require "workling/send_only"
require "workling/remote"
require "workling/return/store/base"
require "workling/return/store/memory_return_store"
require "workling/return/store/starling_return_store"
