require "rails_helper"

RSpec.describe "Budgets", type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }

  describe "未ログインの場合" do
    it "設定画面は、ログイン画面にリダイレクトされること" do
      get new_budget_path

      expect(response).to redirect_to(login_path)
    end

    it "編集画面は、ログイン画面にリダイレクトされること" do
      get edit_budget_path

      expect(response).to redirect_to(login_path)
    end

    it "作成は、行われず、ログイン画面にリダイレクトされること" do
      expect { post budget_path, params: { budget: { amount: "1000" } } }.not_to change(Budget, :count)
      expect(response).to redirect_to(login_path)
    end

    it "更新は、行われず、ログイン画面にリダイレクトされること" do
      budget = create(:budget, user: user, amount: 1_000)

      expect { patch budget_path, params: { budget: { amount: "2000" } } }.not_to change { budget.reload.amount }
      expect(response).to redirect_to(login_path)
    end

    it "削除は、行われず、ログイン画面にリダイレクトされること" do
      create(:budget, user: user)

      expect { delete budget_path }.not_to change(Budget, :count)
      expect(response).to redirect_to(login_path)
    end
  end

  context "ログイン済みの場合" do
    before { log_in_as(user) }

    describe "GET /budget/new" do
      it "予算が未設定なら、正常に表示され、ナビゲーションは表示されないこと" do
        get new_budget_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("月の予算設定")
        expect(response.body).not_to include(I18n.t("shared.nav.record"))
      end

      it "すでに設定済みなら、編集画面にリダイレクトされること" do
        create(:budget, user: user)

        get new_budget_path

        expect(response).to redirect_to(edit_budget_path)
      end
    end

    describe "POST /budget" do
      it "予算が作成され、マイページにリダイレクトされ、完了メッセージが表示されること" do
        expect { post budget_path, params: { budget: { amount: "50000" } } }.to change(Budget, :count).by(1)

        expect(user.reload.budget.amount).to eq(50_000)
        expect(response).to redirect_to(mypage_path)
        follow_redirect!
        expect(response.body).to include("予算を設定しました。")
      end

      { "空" => "", "0" => "0", "マイナス" => "-1", "100万1円" => "1000001", "小数" => "1000.5", "文字列" => "abc" }.each do |label, value|
        it "金額が#{label}の場合、作成されず422になること" do
          expect { post budget_path, params: { budget: { amount: value } } }.not_to change(Budget, :count)
          expect(response).to have_http_status(:unprocessable_content)
        end
      end

      it "上限ちょうど（100万円）は作成できること" do
        expect { post budget_path, params: { budget: { amount: "1000000" } } }.to change(Budget, :count).by(1)
      end

      it "user_idを送っても、ログイン中のユーザーの予算として作成されること" do
        post budget_path, params: { budget: { amount: "1000", user_id: other_user.id } }

        expect(user.reload.budget).to be_present
        expect(other_user.reload.budget).to be_nil
      end

      it "すでに予算がある場合は、作成されず、今ある予算も変わらず、編集画面にリダイレクトされること" do
        existing = create(:budget, user: user, amount: 1_000)

        expect { post budget_path, params: { budget: { amount: "2000" } } }.not_to change(Budget, :count)

        expect(existing.reload.amount).to eq(1_000)
        expect(response).to redirect_to(edit_budget_path)
      end
    end

    describe "GET /budget/edit" do
      it "現在の予算が入った状態で表示され、削除ボタン（確認ダイアログつき）があること" do
        create(:budget, user: user, amount: 50_000)

        get edit_budget_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("月の予算編集・削除")
        expect(response.body).to include('value="50000"')
        expect(response.body).to include("data-turbo-confirm")
        expect(response.body).not_to include(I18n.t("shared.nav.record"))
      end

      it "他のユーザーの予算は、表示されないこと" do
        create(:budget, user: user, amount: 50_000)
        create(:budget, user: other_user, amount: 77_000)

        get edit_budget_path

        expect(response.body).not_to include('value="77000"')
      end

      it "予算が未設定なら、設定画面にリダイレクトされること" do
        get edit_budget_path

        expect(response).to redirect_to(new_budget_path)
      end
    end

    describe "PATCH /budget" do
      let!(:budget) { create(:budget, user: user, amount: 50_000) }

      it "更新され、マイページにリダイレクトされ、完了メッセージが表示されること" do
        patch budget_path, params: { budget: { amount: "30000" } }

        expect(budget.reload.amount).to eq(30_000)
        expect(response).to redirect_to(mypage_path)
        follow_redirect!
        expect(response.body).to include("予算を更新しました。")
      end

      { "空" => "", "0" => "0", "100万1円" => "1000001", "小数" => "1000.5", "文字列" => "abc" }.each do |label, value|
        it "金額が#{label}の場合、更新されず422になること" do
          expect { patch budget_path, params: { budget: { amount: value } } }.not_to change { budget.reload.amount }
          expect(response).to have_http_status(:unprocessable_content)
        end
      end

      it "user_idを送っても、予算の持ち主は変わらないこと" do
        patch budget_path, params: { budget: { amount: "30000", user_id: other_user.id } }

        expect(budget.reload.user).to eq(user)
        expect(budget.amount).to eq(30_000)
      end

      it "他のユーザーの予算は、変更されないこと" do
        other_budget = create(:budget, user: other_user, amount: 77_000)

        patch budget_path, params: { budget: { amount: "30000" } }

        expect(other_budget.reload.amount).to eq(77_000)
      end
    end

    describe "PATCH /budget（予算が未設定の場合）" do
      it "設定画面にリダイレクトされること" do
        patch budget_path, params: { budget: { amount: "30000" } }

        expect(response).to redirect_to(new_budget_path)
      end
    end

    describe "DELETE /budget" do
      it "予算が削除され、303でマイページにリダイレクトされ、完了メッセージが表示されること" do
        create(:budget, user: user)

        expect { delete budget_path }.to change(Budget, :count).by(-1)

        expect(user.reload.budget).to be_nil
        expect(response).to have_http_status(:see_other)
        expect(response).to redirect_to(mypage_path)
        follow_redirect!
        expect(response.body).to include("予算を削除しました。")
      end

      it "他のユーザーの予算は、削除されないこと" do
        create(:budget, user: user)
        other_budget = create(:budget, user: other_user)

        delete budget_path

        expect(Budget.exists?(other_budget.id)).to be(true)
      end

      it "予算が未設定の場合は、エラーにならず、設定画面にリダイレクトされること" do
        expect { delete budget_path }.not_to change(Budget, :count)

        expect(response).to redirect_to(new_budget_path)
      end
    end
  end
end
