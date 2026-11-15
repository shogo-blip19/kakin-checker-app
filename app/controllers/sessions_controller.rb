class SessionsController < ApplicationController
  def new
  end

  def create
    user = login(params[:email], params[:password])

    if user
      redirect_to home_path, notice: t(".success")
    else
      flash.now[:alert] = t(".failure")
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    logout
    redirect_to root_path, notice: t(".success"), status: :see_other
  end
end
