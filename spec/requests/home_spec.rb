require "rails_helper"

RSpec.describe "Home", type: :request do
  describe "GET /home" do
    context "未ログインの場合" do
      it "ログイン画面にリダイレクトされること" do
        get home_path

        expect(response).to redirect_to(login_path)
      end

      it "ログインを促すメッセージが表示されること" do
        get home_path
        follow_redirect!

        expect(response.body).to include("ログインしてください。")
      end
    end

    context "ログイン済みの場合" do
        let(:user) { create(:user, email: "home_user@example.com") }

        before { log_in_as(user) }

        it "正常に表示され、課金記録と履歴のボタンが表示されること" do
            get home_path

            expect(response).to have_http_status(:ok)
            expect(response.body).to include("課金を記録")
            expect(response.body).to include("履歴を見る")
        end

        it "ヘッダーに、ログイン中のメールアドレス（アバターのtitle）が出力されること" do
            get home_path

            expect(response.body).to include('title="home_user@example.com"')
        end
    end
  end
end
