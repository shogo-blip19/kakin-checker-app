require "rails_helper"

RSpec.describe "Pays", type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:preset_title) { user.preset_titles.order(:id).first }
  let(:valid_params) do
    {
      pay: {
        preset_title_id: preset_title.id,
        amount: "10000",
        paid_at: Date.current.to_s
      }
    }
  end

  describe "未ログインの場合" do
    it "GET /pays/new は、ログイン画面にリダイレクトされること" do
      get new_pay_path

      expect(response).to redirect_to(login_path)
    end

    it "POST /pays は、課金記録が作成されず、ログイン画面にリダイレクトされること" do
      valid_params

      expect { post pays_path, params: valid_params }.not_to change(Pay, :count)
      expect(response).to redirect_to(login_path)
    end
  end

  context "ログイン済みの場合" do
    before do
      log_in_as(user)
      user.preset_titles.order(:id).each_with_index { |title, i| title.update!(game_title: "ゲーム#{i + 1}") }
    end

    describe "GET /pays/new" do
      it "正常に表示され、自分のプリセットタイトル3件が選択肢に出ること" do
        get new_pay_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("ゲーム1", "ゲーム2", "ゲーム3")
      end

      it "他のユーザーのプリセットタイトルは、選択肢に出ないこと" do
        other_user.preset_titles.first.update!(game_title: "他人のゲーム")

        get new_pay_path

        expect(response.body).not_to include("他人のゲーム")
      end

      it "日付の初期値が今日であること" do
        get new_pay_path

        expect(response.body).to include(%(value="#{Date.current.iso8601}"))
      end

      it "金額プリセットが表示されること" do
        get new_pay_path

        expect(response.body).to include("¥10,000", "¥30,000", "¥50,000")
      end

      it "課金記録がないとき、1つ目のタイトルが選択されていること" do
        get new_pay_path

        first_id = user.preset_titles.order(:id).first.id
        expect(response.body).to match(/<option[^>]*(?:selected[^>]*value="#{first_id}"|value="#{first_id}"[^>]*selected)/)
      end

      it "前回の課金で選んだタイトルが、選択されていること" do
        second = user.preset_titles.order(:id).second
        create(:pay, user: user, preset_title: second)

        get new_pay_path

        expect(response.body).to match(/<option[^>]*(?:selected[^>]*value="#{second.id}"|value="#{second.id}"[^>]*selected)/)
      end
    end

    describe "POST /pays" do
      context "有効なパラメータの場合" do
        it "登録直後のホーム画面に、課金力（合計）が表示されないこと" do
          post pays_path, params: valid_params
          follow_redirect!

          expect(response.body).not_to include("課金力")
        end


        it "課金記録が1件作成されること" do
          valid_params

          expect { post pays_path, params: valid_params }.to change(Pay, :count).by(1)
        end

        it "ログイン中のユーザーの記録として、入力した内容で保存されること" do
          post pays_path, params: valid_params

          pay = Pay.last
          expect(pay.user).to eq(user)
          expect(pay.preset_title).to eq(preset_title)
          expect(pay.amount).to eq(10_000)
          expect(pay.paid_at).to eq(Date.current)
        end

        it "過去の日付でも保存できること" do
          post pays_path, params: valid_params.deep_merge(pay: { paid_at: (Date.current - 1.month).to_s })

          expect(Pay.last.paid_at).to eq(Date.current - 1.month)
        end

        it "ホームにリダイレクトされ、完了メッセージが表示されること" do
          post pays_path, params: valid_params

          expect(response).to redirect_to(home_path)
          follow_redirect!
          expect(response.body).to include("課金を記録しました。")
        end
      end

      context "金額が不正な場合" do
        {
          "空" => "",
          "0" => "0",
          "マイナス" => "-1",
          "100万1円" => "1000001",
          "小数" => "1000.5",
          "文字列" => "abc"
        }.each do |label, value|
          it "金額が#{label}の場合、保存されず422になること" do
            params = valid_params.deep_merge(pay: { amount: value })

            expect { post pays_path, params: params }.not_to change(Pay, :count)
            expect(response).to have_http_status(:unprocessable_entity)
          end
        end

        it "上限ちょうど（100万円）は保存できること" do
          expect {
            post pays_path, params: valid_params.deep_merge(pay: { amount: "1000000" })
          }.to change(Pay, :count).by(1)
        end
      end

      context "日付が不正な場合" do
        it "未来の日付は、保存されず、エラーメッセージが表示されること" do
          params = valid_params.deep_merge(pay: { paid_at: (Date.current + 1.day).to_s })

          expect { post pays_path, params: params }.not_to change(Pay, :count)
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.body).to include("課金日は今日以前の日付を入力してください")
        end

        it "日付が空の場合、保存されず422になること" do
          params = valid_params.deep_merge(pay: { paid_at: "" })

          expect { post pays_path, params: params }.not_to change(Pay, :count)
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end

      context "ゲームタイトルが不正な場合" do
        it "タイトルが未選択の場合、保存されず422になること" do
          params = valid_params.deep_merge(pay: { preset_title_id: "" })

          expect { post pays_path, params: params }.not_to change(Pay, :count)
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it "存在しないタイトルIDの場合、保存されないこと" do
          params = valid_params.deep_merge(pay: { preset_title_id: "0" })

          expect { post pays_path, params: params }.not_to change(Pay, :count)
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it "他のユーザーのタイトルIDを送っても、保存されず、エラーメッセージが表示されること" do
          other_title = other_user.preset_titles.first
          params = valid_params.deep_merge(pay: { preset_title_id: other_title.id })

          expect { post pays_path, params: params }.not_to change(Pay, :count)
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.body).to include("ゲームタイトルは選択できません")
        end
      end

      context "リクエストを改ざんした場合" do
        it "user_idを送っても、ログイン中のユーザーの記録として保存されること" do
          params = valid_params.deep_merge(pay: { user_id: other_user.id })

          post pays_path, params: params

          expect(Pay.last.user).to eq(user)
          expect(other_user.pays.count).to eq(0)
        end
      end

      context "失敗して再表示されたとき" do
        it "フォームとエラー一覧が表示され、入力した金額が残っていること" do
          params = valid_params.deep_merge(pay: { paid_at: (Date.current + 1.day).to_s, amount: "12345" })

          post pays_path, params: params

          expect(response.body).to include('name="pay[amount]"')
          expect(response.body).to include('value="12345"')
          expect(response.body).to include("件のエラーが発生しました。")
        end
      end
    end
  end





  describe "GET /pays（月別の履歴一覧）" do
    context "未ログインの場合" do
      it "ログイン画面にリダイレクトされること" do
        get pays_path

        expect(response).to redirect_to(login_path)
      end
    end

    context "ログイン済みの場合" do
      let(:first_title) { user.preset_titles.order(:id).first }
      let(:second_title) { user.preset_titles.order(:id).second }

      before do
        log_in_as(user)
        first_title.update!(game_title: "原神")
        second_title.update!(game_title: "スタレ")
      end

      it "指定した月の記録だけが表示され、件数も表示されること" do
        create(:pay, user: user, preset_title: first_title, amount: 10_000, paid_at: Date.new(2025, 10, 15))
        create(:pay, user: user, preset_title: second_title, amount: 3_000, paid_at: Date.new(2025, 10, 1))
        create(:pay, user: user, preset_title: first_title, amount: 99_999, paid_at: Date.new(2025, 9, 30))
        create(:pay, user: user, preset_title: first_title, amount: 88_888, paid_at: Date.new(2025, 11, 1))

        get pays_path(month: "2025-10")

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("2025年10月の記録")
        list_amounts = response.body.scan(/💪 ([\d,]+)課金力/).flatten
        expect(list_amounts).to contain_exactly("10,000", "3,000")
        expect(response.body).to include("（2件）")
        expect(response.body).not_to include("99,999課金力")
        expect(response.body).not_to include("88,888課金力")
      end

      it "ゲームタイトル名と、日付（月/日（曜日））が表示されること" do
        create(:pay, user: user, preset_title: first_title, amount: 10_000, paid_at: Date.new(2025, 10, 15))
        create(:pay, user: user, preset_title: second_title, amount: 3_000, paid_at: Date.new(2025, 10, 1))

        get pays_path(month: "2025-10")

        expect(response.body).to include("原神", "スタレ")
        expect(response.body).to include("10/15（水）", "10/1（水）")
      end

      it "日付の新しい順に表示されること" do
        create(:pay, user: user, preset_title: first_title, amount: 3_000, paid_at: Date.new(2025, 10, 1))
        create(:pay, user: user, preset_title: first_title, amount: 10_000, paid_at: Date.new(2025, 10, 15))

        get pays_path(month: "2025-10")

        list_amounts = response.body.scan(/💪 ([\d,]+)課金力/).flatten
        expect(list_amounts).to eq([ "10,000", "3,000" ])
      end

      it "他のユーザーの記録は表示されないこと" do
        other_title = other_user.preset_titles.first
        create(:pay, user: other_user, preset_title: other_title, amount: 77_777, paid_at: Date.new(2025, 10, 15))

        get pays_path(month: "2025-10")

        expect(response.body).not_to include("77,777課金力")
      end

      it "記録がない月は、その旨のメッセージが表示されること" do
        get pays_path(month: "2025-10")

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("この月の記録は、まだありません。")
      end

      it "monthを指定しない場合は、今月の記録が表示されること" do
        create(:pay, user: user, preset_title: first_title, amount: 12_345, paid_at: Date.current)

        get pays_path

        expect(response.body).to include("#{Date.current.year}年#{Date.current.month}月の記録")
        expect(response.body).to include("12,345課金力")
      end

      [ "abc", "2025-13", "" ].each do |invalid_month|
        it "monthが不正な値（#{invalid_month.inspect}）の場合は、エラーにならず今月が表示されること" do
          get pays_path(month: invalid_month)

          expect(response).to have_http_status(:ok)
          expect(response.body).to include("#{Date.current.year}年#{Date.current.month}月の記録")
        end
      end

      it "ナビゲーションの「課金履歴」が、選択状態になること" do
        get pays_path

        expect(response.body).to match(/aria-current="page"[^>]*>\s*課金履歴|課金履歴[^<]*<\/a>/)
      end

      it "履歴選択に戻るリンクが、その月の年の選択画面になっていること" do
        get pays_path(month: "2025-10")

        expect(response.body).to include(%(href="#{archives_path(year: 2025)}"))
      end

      it "指定した月の合計が、課金力で表示されること" do
        create(:pay, user: user, preset_title: first_title, amount: 10_000, paid_at: Date.new(2025, 10, 15))
        create(:pay, user: user, preset_title: second_title, amount: 3_000, paid_at: Date.new(2025, 10, 1))
        create(:pay, user: user, preset_title: first_title, amount: 99_999, paid_at: Date.new(2025, 9, 30))
        create(:pay, user: other_user, preset_title: other_user.preset_titles.first, amount: 77_777, paid_at: Date.new(2025, 10, 20))

        get pays_path(month: "2025-10")

        expect(response.body).to include(I18n.t("pays.index.total_title"))
        expect(response.body).to include(">13,000課金力<")
      end

      it "記録がない月の合計は、0課金力と表示されること" do
        get pays_path(month: "2025-10")

        expect(response.body).to include(">0課金力<")
      end
    end
  end
end
