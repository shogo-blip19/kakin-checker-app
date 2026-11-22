require "rails_helper"

RSpec.describe "PresetTitles", type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:titles) { user.preset_titles.order(:id).to_a }
  let(:original_names) { %w[原神 スタレ FGO] }

  # 例：title_params(["A", "B", "C"]) → フォームから送られる形のパラメーター
  def title_params(names, ids: titles.map(&:id))
    entries = names.each_with_index.to_h { |name, i| [ i.to_s, { id: ids[i], game_title: name } ] }
    { user: { preset_titles_attributes: entries } }
  end

  def current_names
    titles.map { |title| title.reload.game_title }
  end

  describe "未ログインの場合" do
    it "編集画面は、ログイン画面にリダイレクトされること" do
      get edit_preset_titles_path

      expect(response).to redirect_to(login_path)
    end

    it "更新は行われず、ログイン画面にリダイレクトされること" do
      first_title = user.preset_titles.order(:id).first

      expect { patch preset_titles_path, params: title_params(%w[A B C], ids: user.preset_titles.pluck(:id)) }
        .not_to change { first_title.reload.game_title }
      expect(response).to redirect_to(login_path)
    end
  end

  context "ログイン済みの場合" do
    before do
      log_in_as(user)
      titles.each_with_index { |title, i| title.update!(game_title: original_names[i]) }
    end

    describe "GET /preset_titles/edit" do
      it "正常に表示され、現在の3つのタイトルが、番号つきで入っていること" do
        get edit_preset_titles_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("ゲームタイトルの編集")
        expect(response.body).to include('value="原神"', 'value="スタレ"', 'value="FGO"')
        expect(response.body).to include("ゲームタイトル①", "ゲームタイトル②", "ゲームタイトル③")
        expect(response.body).to include("user[preset_titles_attributes][0][id]")
      end

      it "他のユーザーのタイトルは、表示されないこと" do
        other_user.preset_titles.first.update!(game_title: "他人のゲーム")

        get edit_preset_titles_path

        expect(response.body).not_to include("他人のゲーム")
      end

      it "ナビゲーションバーは表示されず、マイページに戻るリンクがあること" do
        get edit_preset_titles_path

        expect(response.body).not_to include(I18n.t("shared.nav.record"))
        expect(response.body).to include(%(href="#{mypage_path}"))
      end
    end

    describe "PATCH /preset_titles（成功する場合）" do
      it "3つのタイトルを、まとめて更新できること" do
        patch preset_titles_path, params: title_params(%w[崩壊 ブルアカ ウマ娘])

        expect(current_names).to eq(%w[崩壊 ブルアカ ウマ娘])
      end

      it "マイページにリダイレクトされ、完了メッセージが表示されること" do
        patch preset_titles_path, params: title_params(%w[崩壊 ブルアカ ウマ娘])

        expect(response).to redirect_to(mypage_path)
        follow_redirect!
        expect(response.body).to include("ゲームタイトルを更新しました。")
      end

      it "1つだけ送っても、そのタイトルだけが更新され、ほかは変わらないこと" do
        params = { user: { preset_titles_attributes: { "0" => { id: titles[1].id, game_title: "新しい名前" } } } }

        patch preset_titles_path, params: params

        expect(current_names).to eq([ "原神", "新しい名前", "FGO" ])
      end

      it "20文字ちょうどのタイトルは、更新できること" do
        patch preset_titles_path, params: title_params([ ("あ" * 20), "スタレ", "FGO" ])

        expect(current_names.first).to eq("あ" * 20)
      end

      it "同じ名前のタイトルも、更新できること（MVPでは重複を許可）" do
        patch preset_titles_path, params: title_params(%w[同じ 同じ 同じ])

        expect(current_names).to eq(%w[同じ 同じ 同じ])
      end

      it "更新しても、タイトルは3件のままであること" do
        expect { patch preset_titles_path, params: title_params(%w[崩壊 ブルアカ ウマ娘]) }
          .not_to change { user.preset_titles.count }
      end
    end

    describe "名前を変更したときの、課金記録への影響" do
      let!(:pay) do
        create(:pay, user: user, preset_title: titles.first, amount: 10_000, paid_at: Date.new(2025, 10, 15))
      end

      it "過去の課金記録は、同じタイトル（枠）にひも付いたまま、新しい名前になること" do
        patch preset_titles_path, params: title_params(%w[崩壊 スタレ FGO])

        expect(pay.reload.preset_title).to eq(titles.first)
        expect(pay.preset_title.game_title).to eq("崩壊")
      end

      it "履歴の一覧と、課金登録の選択肢に、新しい名前が表示されること" do
        patch preset_titles_path, params: title_params(%w[崩壊 スタレ FGO])

        get pays_path(month: "2025-10")
        expect(response.body).to include("崩壊")

        get new_pay_path
        expect(response.body).to include("崩壊")
      end
    end

    describe "PATCH /preset_titles（入力内容が不正な場合）" do
      it "タイトルが空なら、更新されず、エラーが表示されること" do
        expect { patch preset_titles_path, params: title_params([ "", "スタレ", "FGO" ]) }
          .not_to change { current_names }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("ゲームタイトルを入力してください")
      end

      it "空白だけのタイトルは、更新されないこと" do
        expect { patch preset_titles_path, params: title_params([ "　 ", "スタレ", "FGO" ]) }
          .not_to change { current_names }

        expect(response).to have_http_status(:unprocessable_content)
      end

      it "21文字のタイトルは、更新されないこと" do
        expect { patch preset_titles_path, params: title_params([ ("あ" * 21), "スタレ", "FGO" ]) }
          .not_to change { current_names }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("20文字以内")
      end

      it "3つのうち1つでも不正なら、ほかの2つも更新されないこと" do
        expect { patch preset_titles_path, params: title_params([ "崩壊", "", "ウマ娘" ]) }
          .not_to change { current_names }
      end

      it "失敗して再表示されたとき、入力した値が画面に残っていること" do
        patch preset_titles_path, params: title_params([ "崩壊", "", "ウマ娘" ])

        expect(response.body).to include('value="崩壊"', 'value="ウマ娘"')
      end
    end

    describe "PATCH /preset_titles（リクエストを改ざんした場合）" do
      it "他のユーザーのタイトルのidを送っても、更新されず、404になること" do
        other_title = other_user.preset_titles.first
        params = title_params([ "乗っ取り", "スタレ", "FGO" ], ids: [ other_title.id, titles[1].id, titles[2].id ])

        expect { patch preset_titles_path, params: params }.not_to change { other_title.reload.game_title }

        expect(response).to have_http_status(:not_found)
        expect(current_names).to eq(original_names)
      end

      it "idのないタイトル（新規の追加）は、無視され、タイトルが増えないこと" do
        params = title_params(%w[崩壊 ブルアカ ウマ娘])
        params[:user][:preset_titles_attributes]["3"] = { game_title: "4つ目" }

        expect { patch preset_titles_path, params: params }.not_to change(PresetTitle, :count)

        expect(current_names).to eq(%w[崩壊 ブルアカ ウマ娘])
      end

      it "_destroyを送っても、タイトルは削除されないこと" do
        params = title_params(original_names)
        params[:user][:preset_titles_attributes]["0"][:_destroy] = "1"

        expect { patch preset_titles_path, params: params }.not_to change(PresetTitle, :count)
      end

      it "user_idを送っても、タイトルの持ち主は変わらないこと" do
        params = title_params(%w[崩壊 ブルアカ ウマ娘])
        params[:user][:preset_titles_attributes]["0"][:user_id] = other_user.id

        patch preset_titles_path, params: params

        expect(titles.first.reload.user_id).to eq(user.id)
      end

      it "ユーザー本体の項目（メールアドレスなど）を送っても、変更されないこと" do
        params = title_params(%w[崩壊 ブルアカ ウマ娘])
        params[:user][:email] = "hacked@example.com"

        expect { patch preset_titles_path, params: params }.not_to change { user.reload.email }
      end
    end
  end
end
