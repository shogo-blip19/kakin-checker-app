class MypagesController < ApplicationController
  before_action :require_login

  def show
    @budget = current_user.budget
  end
end
