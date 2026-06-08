class SessionsController < ApplicationController
  def new
  end

  # Googleの同意画面へリダイレクトする
  def google
    state = SecureRandom.hex(16)
    session[:google_oauth_state] = state
    redirect_to GoogleOauthClient.new.authorization_url(state: state), allow_other_host: true
  end

  # Googleからのコールバックを受け取り、stateを検証した上で
  # アクセストークン取得・ユーザー情報取得・DB保存・ログインまでを行う
  def google_callback
    if params[:state].blank? || params[:state] != session.delete(:google_oauth_state)
      return redirect_to login_path, alert: "認証に失敗しました"
    end

    client = GoogleOauthClient.new
    token_response = client.exchange_code_for_token(code: params[:code])
    user_info = client.fetch_user_info(access_token: token_response["access_token"])
    user = User.from_google(user_info)

    session[:user_id] = user.id
    redirect_to root_path, notice: "ログインしました"
  end

  def destroy
    session.delete(:user_id)
    redirect_to login_path, notice: "ログアウトしました"
  end
end
