class MessagesController < ApplicationController
  def create
   ActionCable.server.broadcast 'messages',
      message: params[:message][:body],
      username: current_user["email"] || "Guest"
    head :ok
  end
end
