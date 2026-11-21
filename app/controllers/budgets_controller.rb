class BudgetsController < ApplicationController
  before_action :require_login
  before_action :require_no_budget, only: %i[new create]
  before_action :set_budget, only: %i[edit update destroy]

  def new
    @budget = Budget.new
  end

  def create
    @budget = Budget.new(budget_params)
    @budget.user = current_user

    if @budget.save
      redirect_to after_path, notice: t(".success")
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @budget.update(budget_params)
      redirect_to after_path, notice: t(".success")
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @budget.destroy
    redirect_to after_path, notice: t(".success"), status: :see_other
  end

  private
    # すでに予算がある人は、設定画面ではなく、編集画面へ
    def require_no_budget
      redirect_to edit_budget_path, alert: t("budgets.already_set") if current_user.budget
    end

    # 予算がない人は、編集・削除できないので、設定画面へ
    def set_budget
      @budget = current_user.budget
      redirect_to new_budget_path, alert: t("budgets.not_set") if @budget.nil?
    end

    def budget_params
      params.require(:budget).permit(:amount)
    end

    # 保存・削除のあと、「戻る」「キャンセル」の行き先（PR②で、マイページに変える）
    def after_path
      mypage_path
    end
end
