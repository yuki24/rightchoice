require 'rails'

module Rightchoice
  class Railtie < Rails::Railtie
    
    initializer "rightchoice" do
      require 'rightchoice/view_helper'
      ::ActionController::Base.send :include, Rightchoice::ViewHelper
      ::ActionController::Base.send :helper, Rightchoice::ViewHelper::InstanceMethods
    end
  end
end
