require 'rails'

module Rightchoice
  class Railtie < Rails::Railtie
    
    initializer "rightchoice" do
      ActiveSupport.on_load(:action_view) do
        require 'rightchoice/view_helper'
        ::ActionController::Base.send :include, Rightchoice::ViewHelper
      end
    end
  end
end
