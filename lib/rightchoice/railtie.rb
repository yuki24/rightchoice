require 'railtie'

module Rightchoice
  class Railtie < Rails::Railtie
    
    initializer "rightchoice" do
      ActiveSupport.on_load(:action_view) do
        require 'rightchoice/view_helper'
        ::ActionView::Base.send :include, Rightchoice::ViewHelper
      end
    end
  end
end
