require 'rbbt/util/misc'

require 'sinatra/base'

module Sinatra
  module RbbtAuth

    module Helpers
      def authorized?
        ! user.nil?
      end

      def authorize!
        return true if authorized?
        target_url = @uri
        Log.warn{ "Unauthorized access to #{target_url}" }
        session[:target_url] = target_url
        redirect to('/login')
      end

      def logout!
        session[:user] = nil
      end

      def user
        session[:user]
      end
    end

    def self.registered(app)
      app.helpers RbbtAuth::Helpers

      if Rbbt.etc.web_users.exists?
        app.set :users, Rbbt.etc.web_users.yaml
      else
        app.set :users, {}
      end

      app.get '/login' do
        "<form class='login ui form' method='POST' action='/login'>" +
          "<div class='ui field'>" +
          "<label for='login_name' class='ui label'>Name: </label>" +
          "<input id='login_name' class='ui input' type='text' name='user'>" +
          "</div>" +
          "<div class='ui field'>" +
          "<label for='login_pass' class='ui label'>Pass: </label>" +
          "<input id='login_pass' class='ui input' type='password' name='pass'>" +
          "</div>" +
          "<input type='submit'>" +
        "</form>"
      end

      app.post '/login' do
        user = params[:user]
        pass = params[:pass]

        if settings.users.include?(user) and settings.users[user] == pass
          Log.warn{ "Successful login #{[user, pass] * ": "}" }
          session[:user] = user
          if session[:target_url]
            url = session.delete :target_url
            redirect to(url)
          else
            redirect to('/')
          end
        else
          Log.warn{ "Failed login attempt #{[user, pass] * ": "}" }
          session[:user] = nil
          redirect to('/login')
        end
      end
      
      app.get '/logout' do
        session[:user] = nil
        redirect to('/')
      end
    end
  end

end
