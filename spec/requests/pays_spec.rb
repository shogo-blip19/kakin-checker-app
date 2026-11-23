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

      context "予算の進捗" do
        let!(:budget) { create(:budget, user: user, amount: 50_000) }

        def create_pay(amount, paid_at: Date.new(2025, 10, 15), owner: user)
          create(:pay, user: owner, preset_title: owner.preset_titles.order(:id).first, amount: amount, paid_at: paid_at)
        end

        it "合計に応じた、割合と、バーの幅が表示されること" do
          create_pay(30_000)

          get pays_path(month: "2025-10")

          expect(response.body).to include("進捗 : 30,000/50,000課金力（60%）")
          expect(response.body).to include('style="width: 60%"')
          expect(response.body).to include('role="progressbar"')
        end

        it "予算以内のとき、バーは緑（超過の色ではない）であること" do
          create_pay(30_000)

          get pays_path(month: "2025-10")

          expect(response.body).to include("bg-primary")
          expect(response.body).not_to include("bg-amber-400")
        end

        it "予算とちょうど同じ合計は、100%で、超過の色にならないこと" do
          create_pay(50_000)

          get pays_path(month: "2025-10")

          expect(response.body).to include("（100%）")
          expect(response.body).not_to include("bg-amber-400")
        end

        it "予算を超えたら、120%と表示され、バーは100%で止まり、超過の色になること" do
          create_pay(60_000)

          get pays_path(month: "2025-10")

          expect(response.body).to include("進捗 : 60,000/50,000課金力（120%）")
          expect(response.body).to include('style="width: 100%"')
          expect(response.body).to include("bg-amber-400")
        end

        it "記録がない月は、0%で、バーの幅は0であること" do
          get pays_path(month: "2025-10")

          expect(response.body).to include("進捗 : 0/50,000課金力（0%）")
          expect(response.body).to include('style="width: 0%"')
        end

        it "進捗には、その月の記録だけが含まれること" do
          create_pay(30_000)
          create_pay(99_999, paid_at: Date.new(2025, 9, 30))
          create_pay(88_888, paid_at: Date.new(2025, 11, 1))

          get pays_path(month: "2025-10")

          expect(response.body).to include("進捗 : 30,000/50,000課金力（60%）")
        end

        it "他のユーザーの記録は、進捗に含まれないこと" do
          create_pay(30_000)
          create_pay(70_000, owner: other_user)

          get pays_path(month: "2025-10")

          expect(response.body).to include("進捗 : 30,000/50,000課金力（60%）")
        end

        it "過去の月も、今の予算と比べて表示されること" do
          create_pay(10_000, paid_at: Date.new(2024, 1, 10))

          get pays_path(month: "2024-01")

          expect(response.body).to include("進捗 : 10,000/50,000課金力（20%）")
        end

        it "予算を変更すると、表示される進捗も変わること" do
          create_pay(30_000)
          budget.update!(amount: 100_000)

          get pays_path(month: "2025-10")

          expect(response.body).to include("進捗 : 30,000/100,000課金力（30%）")
        end
      end

      it "予算が未設定のとき、進捗バーは表示されないこと" do
        get pays_path(month: "2025-10")

        expect(response.body).not_to include('role="progressbar"')
        expect(response.body).to include(I18n.t("pays.index.budget_unset"))
      end



      it "予算が未設定のとき、予算を設定するリンクが表示されること" do
        get pays_path(month: "2025-10")

        expect(response.body).to include(I18n.t("pays.index.budget_unset"))
        expect(response.body).to include(%(href="#{new_budget_path}"))
      end

      it "予算が設定済みのとき、進捗と、編集・削除のリンクが表示されること" do
        create(:budget, user: user, amount: 50_000)

        get pays_path(month: "2025-10")

        expect(response.body).to include("進捗 : 0/50,000課金力（0%）")
        expect(response.body).to include(%(href="#{edit_budget_path}"))
        expect(response.body).not_to include(%(href="#{new_budget_path}"))
      end

      it "各記録に、確認ダイアログつきの削除ボタンが表示されること" do
        pay = create(:pay, user: user, preset_title: first_title, paid_at: Date.new(2025, 10, 15))

        get pays_path(month: "2025-10")

        expect(response.body).to include(%(action="#{pay_path(pay)}"))
        expect(response.body).to include("data-turbo-confirm")
        expect(response.body).to include(I18n.t("pays.index.confirm_delete"))
      end

      it "各記録に、編集画面へのリンクが表示されること" do
        pay = create(:pay, user: user, preset_title: first_title, paid_at: Date.new(2025, 10, 15))

        get pays_path(month: "2025-10")

        expect(response.body).to include(%(href="#{edit_pay_path(pay)}"))
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

  describe "課金データの編集・更新" do
    let!(:pay) do
      create(:pay, user: user, preset_title: user.preset_titles.order(:id).first,
                   amount: 10_000, paid_at: Date.new(2025, 10, 15))
    end
    let!(:other_pay) do
      create(:pay, user: other_user, preset_title: other_user.preset_titles.order(:id).first,
                   amount: 5_000, paid_at: Date.new(2025, 10, 20))
    end
    let(:second_title) { user.preset_titles.order(:id).second }

    context "未ログインの場合" do
      it "編集画面は、ログイン画面にリダイレクトされること" do
        get edit_pay_path(pay)

        expect(response).to redirect_to(login_path)
      end

      it "更新は行われず、ログイン画面にリダイレクトされること" do
        expect { patch pay_path(pay), params: { pay: { amount: "1" } } }.not_to change { pay.reload.amount }
        expect(response).to redirect_to(login_path)
      end
    end

    context "ログイン済みの場合" do
      before { log_in_as(user) }

      describe "GET /pays/:id/edit" do
        it "正常に表示され、現在の金額と日付がフォームに入っていること" do
          get edit_pay_path(pay)

          expect(response).to have_http_status(:ok)
          expect(response.body).to include("課金データ編集")
          expect(response.body).to include('value="10000"')
          expect(response.body).to include('value="2025-10-15"')
        end

        it "現在のゲームタイトルが選択されていること" do
          pay.update!(preset_title: second_title)

          get edit_pay_path(pay)

          expect(response.body).to match(/<option[^>]*(?:selected[^>]*value="#{second_title.id}"|value="#{second_title.id}"[^>]*selected)/)
        end

        it "詳細一覧に戻るリンクが、その記録の月の一覧になっていること" do
          get edit_pay_path(pay)

          expect(response.body).to include(%(href="#{pays_path(month: "2025-10")}"))
        end

        it "他のユーザーの記録は、開けないこと（404）" do
          get edit_pay_path(other_pay)

          expect(response).to have_http_status(:not_found)
        end
      end

      describe "PATCH /pays/:id" do
        it "金額、ゲームタイトル、日付を、すべて更新できること" do
          patch pay_path(pay), params: {
            pay: { preset_title_id: second_title.id, amount: "3000", paid_at: "2025-09-20" }
          }

          pay.reload
          expect(pay.preset_title).to eq(second_title)
          expect(pay.amount).to eq(3_000)
          expect(pay.paid_at).to eq(Date.new(2025, 9, 20))
        end

        it "更新後の日付の月の一覧にリダイレクトされ、完了メッセージが表示されること" do
          patch pay_path(pay), params: { pay: { paid_at: "2025-09-20" } }

          expect(response).to redirect_to(pays_path(month: "2025-09"))
          follow_redirect!
          expect(response.body).to include("課金データを更新しました。")
        end

        it "金額だけを変更しても、ほかの項目は変わらないこと" do
          patch pay_path(pay), params: { pay: { amount: "2000" } }

          pay.reload
          expect(pay.amount).to eq(2_000)
          expect(pay.paid_at).to eq(Date.new(2025, 10, 15))
          expect(pay.preset_title).to eq(user.preset_titles.order(:id).first)
        end

        { "空" => "", "0" => "0", "100万1円" => "1000001", "小数" => "1000.5", "文字列" => "abc" }.each do |label, value|
          it "金額が#{label}の場合、更新されず422になること" do
            expect { patch pay_path(pay), params: { pay: { amount: value } } }.not_to change { pay.reload.amount }
            expect(response).to have_http_status(:unprocessable_content)
          end
        end

        it "未来の日付の場合、更新されず、エラーメッセージが表示されること" do
          expect {
            patch pay_path(pay), params: { pay: { paid_at: (Date.current + 1.day).to_s } }
          }.not_to change { pay.reload.paid_at }

          expect(response).to have_http_status(:unprocessable_content)
          expect(response.body).to include("課金日は今日以前の日付を入力してください")
        end

        it "他のユーザーのタイトルIDを送っても、更新されず、エラーメッセージが表示されること" do
          other_title = other_user.preset_titles.first

          expect {
            patch pay_path(pay), params: { pay: { preset_title_id: other_title.id } }
          }.not_to change { pay.reload.preset_title_id }

          expect(response).to have_http_status(:unprocessable_content)
          expect(response.body).to include("ゲームタイトルは選択できません")
        end

        it "user_idを送っても、記録の持ち主は変わらないこと" do
          patch pay_path(pay), params: { pay: { user_id: other_user.id, amount: "2000" } }

          pay.reload
          expect(pay.user).to eq(user)
          expect(pay.amount).to eq(2_000)
        end

        it "他のユーザーの記録は、更新できないこと（404）" do
          expect {
            patch pay_path(other_pay), params: { pay: { amount: "1" } }
          }.not_to change { other_pay.reload.amount }

          expect(response).to have_http_status(:not_found)
        end

        it "更新に失敗したとき、編集画面が再表示され、戻るリンクは元の月のままであること" do
          patch pay_path(pay), params: { pay: { amount: "12345", paid_at: "2099-01-01" } }

          expect(response.body).to include("課金データ編集")
          expect(response.body).to include('value="12345"')
          expect(response.body).to include(%(href="#{pays_path(month: "2025-10")}"))
        end
      end
    end
  end

  describe "課金データの削除" do
    let!(:pay) do
      create(:pay, user: user, preset_title: user.preset_titles.order(:id).first,
                   amount: 10_000, paid_at: Date.new(2025, 10, 15))
    end
    let!(:other_pay) do
      create(:pay, user: other_user, preset_title: other_user.preset_titles.order(:id).first,
                   amount: 5_000, paid_at: Date.new(2025, 10, 20))
    end

    context "未ログインの場合" do
      it "削除は行われず、ログイン画面にリダイレクトされること" do
        expect { delete pay_path(pay) }.not_to change(Pay, :count)
        expect(response).to redirect_to(login_path)
      end
    end

    context "ログイン済みの場合" do
      before { log_in_as(user) }

      it "記録が1件削除されること" do
        expect { delete pay_path(pay) }.to change(Pay, :count).by(-1)
        expect(Pay.exists?(pay.id)).to be(false)
      end

      it "削除した記録の月の一覧に、303でリダイレクトされ、完了メッセージが表示されること" do
        delete pay_path(pay)

        expect(response).to have_http_status(:see_other)
        expect(response).to redirect_to(pays_path(month: "2025-10"))
        follow_redirect!
        expect(response.body).to include("課金データを削除しました。")
      end

      it "ほかの記録（自分の別の記録、他のユーザーの記録）は削除されないこと" do
        own_other = create(:pay, user: user, preset_title: user.preset_titles.order(:id).first,
                                 amount: 3_000, paid_at: Date.new(2025, 10, 1))

        delete pay_path(pay)

        expect(Pay.exists?(own_other.id)).to be(true)
        expect(Pay.exists?(other_pay.id)).to be(true)
      end

      it "削除後の一覧から、その記録が消え、合計も減ること" do
        create(:pay, user: user, preset_title: user.preset_titles.order(:id).first,
                     amount: 3_000, paid_at: Date.new(2025, 10, 1))

        delete pay_path(pay)
        follow_redirect!

        expect(response.body.scan(/💪 ([\d,]+)課金力/).flatten).to eq([ "3,000" ])
        expect(response.body).to include(">3,000課金力<")
      end

      it "月の最後の記録を削除すると、その月の合計は0課金力になること" do
        delete pay_path(pay)
        follow_redirect!

        expect(response.body).to include(">0課金力<")
        expect(response.body).to include(I18n.t("pays.index.empty"))
      end

      it "他のユーザーの記録は、削除できないこと（404）" do
        expect { delete pay_path(other_pay) }.not_to change(Pay, :count)

        expect(response).to have_http_status(:not_found)
      end

      it "存在しないIDは、404になり、何も削除されないこと" do
        expect { delete pay_path(0) }.not_to change(Pay, :count)

        expect(response).to have_http_status(:not_found)
      end
    end
  end


  describe "予算超過の案内（課金登録画面）" do
    let(:title) { user.preset_titles.order(:id).first }
    let(:notice_text) { I18n.t("pays.new.over_budget_notice") }

    before { log_in_as(user) }

    def pay_this_month(amount, owner: user, title: self.title)
      create(:pay, user: owner, preset_title: title, amount: amount, paid_at: Date.current)
    end

    context "今月の合計が、予算を超えているとき" do
      before do
        create(:budget, user: user, amount: 50_000)
        pay_this_month(60_000)
      end

      it "課金登録画面に、案内が表示されること" do
        get new_pay_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(notice_text)
      end

      it "案内には、金額や課金力が表示されないこと" do
        get new_pay_path

        expect(response.body).not_to include("60,000")
        expect(response.body).not_to include("課金力")
      end

      it "案内が出ていても、課金を登録できること（登録は制限されない）" do
        valid_params

        expect { post pays_path, params: valid_params }.to change(Pay, :count).by(1)
      end

      it "登録に失敗して再表示されたときも、案内が表示されること" do
        post pays_path, params: valid_params.deep_merge(pay: { amount: "0" })

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include(notice_text)
      end

      it "登録の直後のホーム画面には、案内も、課金力も表示されないこと" do
        post pays_path, params: valid_params
        follow_redirect!

        expect(response.body).not_to include(notice_text)
        expect(response.body).not_to include("課金力")
      end

      it "課金登録以外の画面（履歴の一覧、編集画面）には、案内が表示されないこと" do
        pay = pay_this_month(1_000)

        get pays_path
        expect(response.body).not_to include(notice_text)

        get edit_pay_path(pay)
        expect(response.body).not_to include(notice_text)
      end
    end

    context "案内が表示されない場合" do
      it "合計が、予算以内なら、表示されないこと" do
        create(:budget, user: user, amount: 50_000)
        pay_this_month(49_999)

        get new_pay_path

        expect(response.body).not_to include(notice_text)
      end

      it "合計が、予算とちょうど同じなら、表示されないこと" do
        create(:budget, user: user, amount: 50_000)
        pay_this_month(50_000)

        get new_pay_path

        expect(response.body).not_to include(notice_text)
      end

      it "予算が未設定なら、合計が大きくても、表示されないこと" do
        pay_this_month(500_000)

        get new_pay_path

        expect(response.body).not_to include(notice_text)
      end

      it "先月の記録だけが予算を超えていても、表示されないこと" do
        create(:budget, user: user, amount: 50_000)
        create(:pay, user: user, preset_title: title, amount: 99_999,
                     paid_at: Date.current.beginning_of_month - 1.day)

        get new_pay_path

        expect(response.body).not_to include(notice_text)
      end

      it "ほかのユーザーの記録は、判定に含まれず、表示されないこと" do
        create(:budget, user: user, amount: 50_000)
        pay_this_month(70_000, owner: other_user, title: other_user.preset_titles.first)

        get new_pay_path

        expect(response.body).not_to include(notice_text)
      end
    end

    it "予算を超えたあと、予算を上げると、案内が表示されなくなること" do
      budget = create(:budget, user: user, amount: 50_000)
      pay_this_month(60_000)

      get new_pay_path
      expect(response.body).to include(notice_text)

      budget.update!(amount: 100_000)

      get new_pay_path
      expect(response.body).not_to include(notice_text)
    end
  end

  describe "N+1問題の防止" do
    let(:titles) { user.preset_titles.order(:id).to_a }

    before { log_in_as(user) }

    # ゲームタイトルを使い回して、日付を変えながら、記録を作る
    def add_pays(count, day_offset: 0)
      count.times do |i|
        create(:pay, user: user, preset_title: titles[i % titles.size], amount: 1_000,
                     paid_at: Date.new(2025, 10, 1 + day_offset + i))
      end
    end

    it "月の一覧は、記録の件数が増えても、クエリの数が増えないこと" do
      add_pays(1)
      get pays_path(month: "2025-10") # 初回のみの処理を済ませるための、ウォームアップ

      queries_for_one = count_queries { get pays_path(month: "2025-10") }

      add_pays(5, day_offset: 1)
      queries_for_six = count_queries { get pays_path(month: "2025-10") }

      expect(queries_for_six).to eq(queries_for_one)
    end

    it "月の一覧に、複数のゲームタイトルの記録が並んでも、エラーにならず表示されること（Bulletの検出対象）" do
      add_pays(6)

      get pays_path(month: "2025-10")

      expect(response).to have_http_status(:ok)
      expect(response.body.scan("🎮").size).to eq(6)
    end
  end
end
