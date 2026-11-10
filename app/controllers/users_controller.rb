class UsersController < ApplicationController
    
    def new
        @user =User.new
        3.times { @user.preset_titles.build }
        
    end

    def create
        @user = User.new(user_params)
        if @user.save
            redirect_to root_path, notice: "User created successfully."
        else
            render :new, status: :unprocessable_entity
        end
    end


    private
    def user_params
        params.require(:user).permit(:email, :password, :password_confirmation, preset_titles_attributes: [:game_title])
    end
end 