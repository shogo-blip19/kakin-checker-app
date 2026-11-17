class PaysController < ApplicationController
  before_action :require_login

  def index
    @month = month_from(params[:month])
    @pays = current_user.pays.in_month(@month).recent_first.includes(:preset_title)
  end

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

    def month_from(value)
      Date.strptime(value.to_s, "%Y-%m")
    rescue Date::Error
      Date.current.beginning_of_month
    end
end
