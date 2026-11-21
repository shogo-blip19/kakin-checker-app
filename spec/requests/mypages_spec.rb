require "rails_helper"

RSpec.describe "Mypages", type: :request do
  let(:user) { create(:user, email: "my_user@example.com") }
  let(:other_user) { create(:user) }

  describe "GET /mypage" do
    context "未ログインの場合" do
      it "ログイン画面にリダイレクトされること" do
        get mypage_path

        expect(response).to redirect_to(login_path)
      end
    end

    context "ログイン済みの場合" do
      before { log_in_as(user) }

      it "正常に表示され、ナビゲーションバーは表示されないこと" do
        get mypage_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("マイページ")
        expect(response.body).not_to include(I18n.t("shared.nav.record"))
      end

      it "TOPへ移動するリンクと、各ブロックが表示されること" do
        get mypage_path

        expect(response.body).to include(%(href="#{home_path}"))
        expect(response.body).to include("ユーザー情報", "月間目標予算", "登録ゲームタイトル管理")
      end

      it "ログアウトのボタンが表示されること" do
        get mypage_path

        expect(response.body).to include(%(action="#{logout_path}"))
      end

      it "予算が未設定のとき、未設定と、予算を設定するリンクが表示されること" do
        get mypage_path

        expect(response.body).to include("現在の設定 : 未設定")
        expect(response.body).to include(%(href="#{new_budget_path}"))
        expect(response.body).not_to include(%(href="#{edit_budget_path}"))
      end

      it "予算が設定済みのとき、現在の金額と、編集・削除のリンクが表示されること" do
        create(:budget, user: user, amount: 30_000)

        get mypage_path

        expect(response.body).to include("30,000課金力/月")
        expect(response.body).to include(%(href="#{edit_budget_path}"))
        expect(response.body).not_to include(%(href="#{new_budget_path}"))
      end

      it "他のユーザーの予算は、表示されないこと" do
        create(:budget, user: other_user, amount: 77_000)

        get mypage_path

        expect(response.body).not_to include("77,000課金力")
        expect(response.body).to include("現在の設定 : 未設定")
      end

      it "ログアウトすると、マイページを開けなくなること" do
        delete logout_path
        get mypage_path

        expect(response).to redirect_to(login_path)
      end
    end
  end
end
