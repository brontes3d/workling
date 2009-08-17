require 'workling/base'

class SendOnlyUtil < Workling::SendOnly
  
  def echo(options)
    return options
  end
  
  def transform(options)
    return options.merge(:something => "else")
  end

end
