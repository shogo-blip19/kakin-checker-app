require "rails_helper"

RSpec.describe "Users", type: :request do
  let(:valid_params) do
    {
      user: {
        email: "new_user@example.com",
        password: "password123",
        password_confirmation: "password123",
        preset_titles_attributes: {
          "0" => { game_title: "タイトル①" },
          "1" => { game_title: "タイトル②" },
          "2" => { game_title: "タイトル③" }
        },
        budget_attributes: { amount: "10000" }
      }
    }
  end



  describe "GET /users/new" do
    it "正常に表示されること" do
      get new_user_path
      expect(response).to have_http_status(:success)
    end



    it "「新規登録」というタイトルが表示されること" do
      get new_user_path
      expect(response.body).to include("<title>新規登録</title>")
    end

    it "「新規登録」という見出しが表示されること" do
      get new_user_path
      expect(response.body).to include("新規登録")
    end
  end



  describe "POST /users" do
    context "有効なパラメータの場合(予算あり)" do
      it "ユーザーが1件、プリセットタイトルが3件、予算が1件作成されること" do
        expect {
          post users_path, params: valid_params
        }.to change(User, :count).by(1).and change(PresetTitle, :count).by(3).and change(Budget, :count).by(1)
      end

      it "ログイン後のホームにリダイレクトされること" do
  post users_path, params: valid_params
  expect(response).to redirect_to(home_path)
end

    # 変更：メッセージの確認（テスト名だけ、実態に合わせる）
    it "登録後のホーム画面に、完了メッセージが表示されること" do
      post users_path, params: valid_params
      follow_redirect!

      expect(response.body).to include("ユーザー登録が完了しました。")
    end

    # 追加：自動ログイン
    it "登録後、そのままログイン状態になること" do
      post users_path, params: valid_params
      get home_path

      expect(response).to have_http_status(:ok)
    end
    end

    context "有効なパラメータの場合(予算なし)" do
      it "ユーザーが1件、プリセットタイトルが3件作成され、予算が作成されないこと" do
        expect {
          post users_path, params: valid_params.deep_merge(user: { budget_attributes: { amount: "" } })
        }.to change(User, :count).by(1).and change(PresetTitle, :count).by(3).and change(Budget, :count).by(0)
      end
    end

    context "無効なパラメータの場合" do
      it "登録に失敗したとき、ログイン状態にならないこと" do
        post users_path, params: valid_params.deep_merge(user: { email: "" })
        get home_path

        expect(response).to redirect_to(login_path)
      end

      it "メールアドレスが空の場合、ユーザー、プリセットタイトル、予算が作成されないこと" do
        expect {
          post users_path, params: valid_params.deep_merge(user: { email: "" })
        }.not_to change { [ User.count, PresetTitle.count, Budget.count ] }
        expect(response.body).to include("メールアドレスを入力してください")
      end

      it "メールアドレスが重複している場合、ユーザー、プリセットタイトル、予算が作成されないこと" do
        create(:user, email: "test@example.com")
        expect {
          post users_path, params: valid_params.deep_merge(user: { email: "test@example.com" })
        }.not_to change { [ User.count, PresetTitle.count, Budget.count ] }
        expect(response.body).to include("メールアドレスはすでに存在します")
      end

      it "プリセットタイトルが3件未満の場合、ユーザー、プリセットタイトル、予算が作成されないこと" do
        params = valid_params.deep_dup
        params[:user][:preset_titles_attributes].delete("2")

        expect {
          post users_path, params: params
        }.not_to change { [ User.count, PresetTitle.count, Budget.count ] }
        expect(response.body).to include("プリセットタイトルは3件にしてください")
      end

      it "プリセットタイトルが空の場合、ユーザー、プリセットタイトル、予算が作成されないこと" do
        expect {
          post users_path, params: valid_params.deep_merge(user: { preset_titles_attributes: {
          "0" => { game_title: "" }, "1" => { game_title: "" }, "2" => { game_title: "" }
        } })
        }.not_to change { [ User.count, PresetTitle.count, Budget.count ] }
        expect(response.body).to include("ゲームタイトルを入力してください")
      end

      it "パスワードが空の場合、ユーザー、プリセットタイトル、予算が作成されないこと" do
        expect {
          post users_path, params: valid_params.deep_merge(user: { password: "", password_confirmation: "" })
        }.not_to change { [ User.count, PresetTitle.count, Budget.count ] }
        expect(response.body).to include("パスワードを入力してください")
      end

      it "パスワード確認が空の場合、ユーザー、プリセットタイトル、予算が作成されないこと" do
        expect {
          post users_path, params: valid_params.deep_merge(user: { password_confirmation: nil })
        }.not_to change { [ User.count, PresetTitle.count, Budget.count ] }
        expect(response.body).to include("パスワード（確認）を入力してください")
      end

      it "パスワードが8文字未満の場合、ユーザー、プリセットタイトル、予算が作成されないこと" do
        expect {
          post users_path, params: valid_params.deep_merge(user: { password: "short", password_confirmation: "short" })
        }.not_to change { [ User.count, PresetTitle.count, Budget.count ] }
        expect(response.body).to include("パスワードは8文字以上で入力してください")
      end

      it "パスワードとパスワード確認が一致しない場合、ユーザー、プリセットタイトル、予算が作成されないこと" do
        expect {
          post users_path, params: valid_params.deep_merge(user: { password: "password", password_confirmation: "different" })
        }.not_to change { [ User.count, PresetTitle.count, Budget.count ] }
        expect(response.body).to include("パスワード（確認）とパスワードの入力が一致しません")
      end

      it "別の項目でエラーになっても、予算の入力欄が表示されること" do
        post users_path, params: valid_params.deep_merge(user: { email: "", budget_attributes: { amount: "" } })

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("user[budget_attributes][amount]")
      end


      it "失敗時のステータスが422であること" do
        post users_path, params: valid_params.deep_merge(user: { email: nil })
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
