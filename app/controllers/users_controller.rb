class UsersController < ApplicationController
  before_filter :signed_in_user, only: [:show, :edit, :update, :destroy]
  before_filter :correct_user,   only: [:edit, :update]
  
  def new
    @user = User.new
  end

  def show
    @user = User.find(params[:id])
    @micropost = current_user.microposts.build
  end
  
  def create
    @user = User.new(params[:user])

    if @user.save
      sign_in @user
      flash[:success] = "Welcome to the Facebook Project!"
      redirect_to root_path
    else
      render 'new'
    end
  end

  def edit

  end

  private

    def signed_in_user
      store_location
      redirect_to root_path, notice: "Please sign in." unless signed_in?
    end

    def correct_user
      @user = User.find(params[:id])
      redirect_to(root_path) unless current_user?(@user)
    end
end
