class PaysController < ApplicationController
  before_action :require_login
  before_action :set_pay, only: %i[edit update destroy]

  def index
    @month = month_from(params[:month])
    month_pays = current_user.pays.in_month(@month)
    @pays = month_pays.recent_first.includes(:preset_title)
    @total = month_pays.sum(:amount)
    @budget = current_user.budget
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

  def edit
  end

  def update
    if @pay.update(pay_params)
      redirect_to month_list_path(@pay), notice: t(".success")
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @pay.destroy
    redirect_to month_list_path(@pay), notice: t(".success"), status: :see_other
  end

  private
    def set_pay
      @pay = current_user.pays.find(params[:id])
    end

    def pay_params
      params.require(:pay).permit(:preset_title_id, :amount, :paid_at)
    end

    def month_from(value)
      Date.strptime(value.to_s, "%Y-%m")
    rescue Date::Error
      Date.current.beginning_of_month
    end

    # その記録の日付の月の、履歴一覧のパス
    def month_list_path(pay)
      pays_path(month: pay.paid_at.strftime("%Y-%m"))
    end
end
