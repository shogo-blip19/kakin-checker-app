require "rails_helper"

RSpec.describe "Top", type: :request do
  describe "GET /" do
    it "正常に表示される" do
      get "/"
      expect(response).to have_http_status(:success)
    end

    it "「アプリを始める」ボタンが表示される" do
      get "/"
      expect(response.body).to include("アプリを始める")
    end
  end
end
