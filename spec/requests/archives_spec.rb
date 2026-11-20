require "rails_helper"

RSpec.describe "Archives", type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }

  def month_label(year, month)
    I18n.t("archives.index.month", year: year, month: month)
  end

  describe "GET /archives" do
    context "未ログインの場合" do
      it "ログイン画面にリダイレクトされること" do
        get archives_path

        expect(response).to redirect_to(login_path)
      end
    end

    context "ログイン済みの場合" do
      before { log_in_as(user) }

      it "記録がある月だけが、新しい順に、1回ずつ表示されること" do
        create(:pay, user: user, paid_at: Date.new(2025, 10, 15))
        create(:pay, user: user, paid_at: Date.new(2025, 10, 1))
        create(:pay, user: user, paid_at: Date.new(2025, 8, 20))

        get archives_path(year: 2025)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(month_label(2025, 10), month_label(2025, 8))
        expect(response.body).not_to include(month_label(2025, 9))
        expect(response.body.scan(month_label(2025, 10)).size).to eq(1)
        expect(response.body.index(month_label(2025, 10))).to be < response.body.index(month_label(2025, 8))
      end

      it "各月のカードが、その月の一覧へのリンクになっていること" do
        create(:pay, user: user, paid_at: Date.new(2025, 10, 15))

        get archives_path(year: 2025)

        expect(response.body).to include(%(href="#{pays_path(month: "2025-10")}"))
      end

      it "金額、課金力、合計は表示されないこと（クッションUI）" do
        create(:pay, user: user, amount: 55_555, paid_at: Date.new(2025, 10, 15))

        get archives_path(year: 2025)

        expect(response.body).not_to include("55,555")
        expect(response.body).not_to include("課金力")
      end

      it "他のユーザーの記録の月は表示されないこと" do
        create(:pay, user: other_user, paid_at: Date.new(2025, 7, 10))

        get archives_path(year: 2025)

        expect(response.body).not_to include(month_label(2025, 7))
      end

      it "記録がない年は、その旨のメッセージが表示されること" do
        get archives_path(year: 2025)

        expect(response.body).to include(I18n.t("archives.index.empty"))
      end

      it "yearを指定しない場合は、今年が表示されること" do
        create(:pay, user: user, paid_at: Date.current)

        get archives_path

        expect(response.body).to include(month_label(Date.current.year, Date.current.month))
      end

      [ "abc", "", "0", "99999" ].each do |invalid_year|
        it "yearが不正な値（#{invalid_year.inspect}）の場合は、エラーにならず今年が表示されること" do
          get archives_path(year: invalid_year)

          expect(response).to have_http_status(:ok)
          expect(response.body).to include(I18n.t("archives.index.year", year: Date.current.year))
        end
      end

      context "年の切り替え" do
        before do
          create(:pay, user: user, paid_at: Date.new(2023, 5, 1))
          create(:pay, user: user, paid_at: Date.new(2025, 5, 1))
        end

        it "記録がある直前の年と、直後の年へのリンクが表示されること" do
          create(:pay, user: user, paid_at: Date.new(2024, 5, 1))

          get archives_path(year: 2024)

          expect(response.body).to include(%(href="#{archives_path(year: 2023)}"))
          expect(response.body).to include(%(href="#{archives_path(year: 2025)}"))
        end

        it "記録のない年は飛ばして、記録がある年へのリンクになること" do
          get archives_path(year: 2025)

          expect(response.body).to include(%(href="#{archives_path(year: 2023)}"))
          expect(response.body).not_to include(%(href="#{archives_path(year: 2024)}"))
        end

        it "最も古い年では、前の年へのリンクが表示されないこと" do
          get archives_path(year: 2023)

          expect(response.body).not_to include(%(href="#{archives_path(year: 2022)}"))
          expect(response.body).to include(%(href="#{archives_path(year: 2025)}"))
        end

        it "最も新しい年では、次の年へのリンクが表示されないこと" do
          get archives_path(year: 2025)

          expect(response.body).not_to include(%(href="#{archives_path(year: 2026)}"))
        end
      end
    end
  end
end
