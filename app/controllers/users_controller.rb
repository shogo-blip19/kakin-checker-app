class UsersController < ApplicationController
    def new
        @user =User.new(
            preset_titles_attributes: [
                { game_title: "タイトル①" },
                { game_title: "タイトル②" },
                { game_title: "タイトル③" }
            ]

        )
        @user.build_budget
    end

    def create
        @user = User.new(user_params)
        if @user.save
            redirect_to root_path, notice: t(".success")
        else
            @user.build_budget if @user.budget.nil?
            render :new, status: :unprocessable_entity
        end
    end


    private
    def user_params
        params.require(:user).permit(:email, :password, :password_confirmation, preset_titles_attributes: [ :game_title ], budget_attributes: [ :amount ])
    end
end
