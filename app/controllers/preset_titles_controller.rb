class PresetTitlesController < ApplicationController
  before_action :require_login
  before_action :set_user

  def edit
  end

  def update
    if @user.update(user_params)
      redirect_to mypage_path, notice: t(".success")
    else
      render :edit, status: :unprocessable_content
    end
  end

  private
    # current_user とは別のオブジェクトにする（入力途中の値が、ヘッダーなどの表示に影響しないように）
    def set_user
      @user = User.find(current_user.id)
    end

    # 受け取るのは、既存のタイトルの id と game_title だけ。idのないもの（新しいタイトルの追加）は、無視する
    def user_params
      permitted = params.require(:user).permit(preset_titles_attributes: %i[id game_title])
      titles = permitted[:preset_titles_attributes].to_h.select { |_, title| title[:id].present? }
      { preset_titles_attributes: titles }
    end
end
