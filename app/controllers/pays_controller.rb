class PaysController < ApplicationController
  before_action :require_login

  def new
    last_pay = current_user.pays.order(created_at: :desc, id: :desc).first
    @pay = current_user.pays.build(
      paid_at: Date.current,
      preset_title: last_pay&.preset_title || current_user.preset_titles.order(:id).first
    )
  end

  def create
    @pay = current_user.pays.build(pay_params)

    if @pay.save
      redirect_to home_path, notice: t(".success")
    else
      render :new, status: :unprocessable_entity
    end
  end

  private
    def pay_params
      params.require(:pay).permit(:preset_title_id, :amount, :paid_at)
    end
end
