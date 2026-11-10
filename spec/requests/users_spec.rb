require "rails_helper"

RSpec.describe "Users", type: :request do
  describe "GET /users/new" do
    it "正常に表示されること" do
      get new_user_path
      expect(response).to have_http_status(:success)
    end

    it "「New User」というタイトルが表示されること" do
      get new_user_path
      expect(response.body).to include("<title>New User</title>")
    end

    it "「New User」という見出しが表示されること" do
      get new_user_path
      expect(response.body).to include("<h1>New User</h1>")
    end
  end
end
