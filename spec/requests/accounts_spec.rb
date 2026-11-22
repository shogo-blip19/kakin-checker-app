require "rails_helper"

RSpec.describe "Accounts", type: :request do
  let(:user) { create(:user, email: "me@example.com") }
  let(:other_user) { create(:user, email: "other@example.com") }
  let(:current_password) { "password123" }

  def update_account(user_params, current: current_password)
    patch account_path, params: { user: user_params, current_password: current }
  end

  describe "未ログインの場合" do
    it "編集画面は、ログイン画面にリダイレクトされること" do
      get edit_account_path

      expect(response).to redirect_to(login_path)
    end

    it "更新は行われず、ログイン画面にリダイレクトされること" do
      user

      expect { update_account({ email: "new@example.com" }) }.not_to change { user.reload.email }
      expect(response).to redirect_to(login_path)
    end
  end

  context "ログイン済みの場合" do
    before { log_in_as(user) }

    describe "GET /account/edit" do
      it "正常に表示され、現在のメールアドレスが入った状態で、現在のパスワード欄があること" do
        get edit_account_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("ユーザー情報編集")
        expect(response.body).to include('value="me@example.com"')
        expect(response.body).to include('name="current_password"')
      end

      it "ナビゲーションバーは表示されず、マイページに戻るリンクがあること" do
        get edit_account_path

        expect(response.body).not_to include(I18n.t("shared.nav.record"))
        expect(response.body).to include(%(href="#{mypage_path}"))
      end
    end

    describe "PATCH /account（成功する場合）" do
    it "メールアドレスだけを変更でき、パスワードは変わらないこと" do
        before_crypted = user.crypted_password

        update_account({ email: "new@example.com", password: "", password_confirmation: "" })

        expect(user.reload.email).to eq("new@example.com")
        expect(user.crypted_password).to eq(before_crypted)
      end

      it "パスワードを変更でき、新しいパスワードでログインできること" do
        update_account({ email: "me@example.com", password: "newpassword456", password_confirmation: "newpassword456" })

        delete logout_path
        post login_path, params: { email: "me@example.com", password: "newpassword456" }
        expect(response).to redirect_to(home_path)
      end

      it "パスワードを変更すると、古いパスワードでは、ログインできなくなること" do
        update_account({ email: "me@example.com", password: "newpassword456", password_confirmation: "newpassword456" })

        delete logout_path
        post login_path, params: { email: "me@example.com", password: "password123" }
        expect(response).to have_http_status(:unprocessable_content)
      end

      it "変更したメールアドレスで、ログインできること" do
        update_account({ email: "new@example.com" })

        delete logout_path
        post login_path, params: { email: "new@example.com", password: "password123" }
        expect(response).to redirect_to(home_path)
      end

      it "マイページにリダイレクトされ、完了メッセージが表示されること" do
        update_account({ email: "new@example.com" })

        expect(response).to redirect_to(mypage_path)
        follow_redirect!
        expect(response.body).to include("ユーザー情報を更新しました。")
      end

      it "更新後も、ログイン状態が続くこと" do
        update_account({ email: "new@example.com", password: "newpassword456", password_confirmation: "newpassword456" })

        get mypage_path
        expect(response).to have_http_status(:ok)
      end

      it "新しいパスワードが空欄なら、確認用に入力があっても、パスワードは変更されないこと" do
        expect {
          update_account({ email: "me@example.com", password: "", password_confirmation: "something" })
        }.not_to change { user.reload.crypted_password }

        expect(response).to redirect_to(mypage_path)
      end
    end

    describe "PATCH /account（現在のパスワードが正しくない場合）" do
      it "違うパスワードでは、何も更新されず、エラーメッセージが表示されること" do
        expect {
          update_account({ email: "new@example.com", password: "newpassword456", password_confirmation: "newpassword456" },
                         current: "wrong_password")
        }.not_to change { user.reload.attributes.slice("email", "crypted_password") }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("現在のパスワードが正しくありません。")
      end

      it "現在のパスワードが空の場合も、何も更新されないこと" do
        expect { update_account({ email: "new@example.com" }, current: "") }.not_to change { user.reload.email }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("現在のパスワードが正しくありません。")
      end

      it "入力したメールアドレスは画面に残り、入力したパスワードは残らないこと" do
        update_account({ email: "new@example.com", password: "newpassword456", password_confirmation: "newpassword456" },
                       current: "wrong_password")

        expect(response.body).to include('value="new@example.com"')
        expect(response.body).not_to include("newpassword456")
        expect(response.body).not_to include("wrong_password")
      end
    end

    describe "PATCH /account（入力内容が不正な場合）" do
      it "メールアドレスの形式が不正なら、更新されず、エラーが表示されること" do
        expect { update_account({ email: "invalid_email" }) }.not_to change { user.reload.email }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("件のエラーが発生しました。")
      end

      it "メールアドレスが空でも、画面が表示され、更新されないこと（ヘッダーでエラーにならない）" do
        expect { update_account({ email: "" }) }.not_to change { user.reload.email }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("ユーザー情報編集")
      end

      it "他のユーザーと重複するメールアドレスには、変更できないこと" do
        other_user

        expect { update_account({ email: "other@example.com" }) }.not_to change { user.reload.email }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("メールアドレスはすでに存在します")
      end

      it "新しいパスワードが8文字未満なら、更新されないこと" do
        expect {
          update_account({ email: "me@example.com", password: "short", password_confirmation: "short" })
        }.not_to change { user.reload.crypted_password }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("パスワードは8文字以上で入力してください")
      end

      it "新しいパスワードと確認用が一致しなければ、更新されないこと" do
        expect {
          update_account({ email: "me@example.com", password: "newpassword456", password_confirmation: "different" })
        }.not_to change { user.reload.crypted_password }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("パスワード（確認）とパスワードの入力が一致しません")
      end

      it "新しいパスワードを入力して、確認用が空なら、更新されないこと" do
        expect {
          update_account({ email: "me@example.com", password: "newpassword456", password_confirmation: "" })
        }.not_to change { user.reload.crypted_password }

        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    describe "PATCH /account（リクエストを改ざんした場合）" do
      it "idを送っても、自分の情報だけが更新され、ほかのユーザーは変わらないこと" do
        other_user

        update_account({ email: "new@example.com", id: other_user.id })

        expect(user.reload.email).to eq("new@example.com")
        expect(other_user.reload.email).to eq("other@example.com")
      end

      it "crypted_passwordを送っても、無視されること" do
        expect {
          update_account({ email: "me@example.com", crypted_password: "hacked", salt: "hacked" })
        }.not_to change { user.reload.attributes.slice("crypted_password", "salt") }
      end
    end
  end
end
