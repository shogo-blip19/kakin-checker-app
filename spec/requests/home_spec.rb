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

      it "正常に表示され、ログイン中のメールアドレスが表示されること" do
        log_in_as(user)
        get home_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("home_user@example.com")
      end
    end
  end
end
