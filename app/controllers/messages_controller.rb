class MessagesController < ApplicationController
  skip_before_filter :verify_authenticity_token
  def create
   ActionCable.server.broadcast 'messages',
      message: params[:message][:body],
      username: current_user["email"] || "Guest"
    head :ok
  end
end
