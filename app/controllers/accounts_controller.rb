class AccountsController < ApplicationController
  before_action :require_login
  before_action :set_user

  def edit
  end

  def update
    if @user.valid_password?(params[:current_password].to_s)
      if @user.update(user_params)
        redirect_to mypage_path, notice: t(".success")
      else
        render :edit, status: :unprocessable_content
      end
    else
      @user.assign_attributes(user_params.slice(:email))
      @user.errors.add(:base, t("accounts.current_password_invalid"))
      render :edit, status: :unprocessable_content
    end
  end

  private
    # current_user とは別のオブジェクトにする（入力途中の値が、ヘッダーなどの表示に影響しないように）
    def set_user
      @user = User.find(current_user.id)
    end

    def user_params
      permitted = params.require(:user).permit(:email, :password, :password_confirmation)
      permitted[:password].blank? ? permitted.except(:password, :password_confirmation) : permitted
    end
end
