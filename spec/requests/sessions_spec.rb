require "rails_helper"

RSpec.describe "Sessions", type: :request do
  let!(:user) { create(:user, email: "login_user@example.com") }

  describe "GET /login" do
    it "正常に表示されること" do
      get login_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("ログイン")
    end
  end

  describe "POST /login" do
    context "正しい認証情報の場合" do
      it "ログイン後のホームにリダイレクトされること" do
        log_in_as(user)

        expect(response).to redirect_to(home_path)
      end

      it "ログイン成功のメッセージが表示されること" do
        log_in_as(user)
        follow_redirect!

        expect(response.body).to include("ログインしました。")
      end

      it "ログイン後、ログイン必須のページを開けること" do
        log_in_as(user)
        get home_path

        expect(response).to have_http_status(:ok)
      end
    end

    context "パスワードが違う場合" do
      before { post login_path, params: { email: user.email, password: "wrong_password" } }

      it "422で、ログイン画面が再表示されること" do
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("メールアドレスまたはパスワードが正しくありません。")
      end

      it "ログイン状態にならないこと" do
        get home_path

        expect(response).to redirect_to(login_path)
      end

      it "入力したメールアドレスは残り、パスワードは残らないこと" do
        expect(response.body).to include('value="login_user@example.com"')
        expect(response.body).not_to include("wrong_password")
      end
    end

    context "登録されていないメールアドレスの場合" do
      it "パスワードが違う場合と同じメッセージが表示されること" do
        post login_path, params: { email: "nobody@example.com", password: "password123" }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("メールアドレスまたはパスワードが正しくありません。")
      end
    end
  end

  describe "DELETE /logout" do
    before { log_in_as(user) }

    it "TOP画面にリダイレクトされること（303）" do
      delete logout_path

      expect(response).to have_http_status(:see_other)
      expect(response).to redirect_to(root_path)
    end

    it "ログアウトのメッセージが表示されること" do
      delete logout_path
      follow_redirect!

      expect(response.body).to include("ログアウトしました。")
    end

    it "ログアウト後は、ログイン必須のページを開けないこと" do
      delete logout_path
      get home_path

      expect(response).to redirect_to(login_path)
    end
  end

  describe "ヘッダーの表示切り替え" do
    it "未ログインのとき、新規登録とログインのリンクが表示され、ログアウトは表示されないこと" do
      get root_path

      expect(response.body).to include(%(href="#{new_user_path}"))
      expect(response.body).to include(%(href="#{login_path}"))
      expect(response.body).not_to include(%(action="#{logout_path}"))
    end

    it "ログイン中は、ログアウトが表示され、新規登録とログインのリンクは表示されないこと" do
      log_in_as(user)
      get home_path

      expect(response.body).to include(%(action="#{logout_path}"))
      expect(response.body).not_to include(%(href="#{new_user_path}"))
      expect(response.body).not_to include(%(href="#{login_path}"))
    end

    it "ログイン中は、ナビゲーション（課金登録・課金履歴）が表示されること" do
        log_in_as(user)
        get home_path

        expect(response.body).to include("課金登録")
        expect(response.body).to include("課金履歴")
    end

    it "未ログインのときは、ナビゲーションが表示されないこと" do
    get root_path

    expect(response.body).not_to include("課金履歴")
    end
  end
end
