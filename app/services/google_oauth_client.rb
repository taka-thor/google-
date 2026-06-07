require "net/http"
require "uri"
require "json"

# Googleのauthorization code flowにおけるHTTP通信を集約するクラス。
# コントローラ・モデルにHTTP通信の詳細を持ち込まないための層。
class GoogleOauthClient
  AUTHORIZATION_ENDPOINT = "https://accounts.google.com/o/oauth2/v2/auth"
  TOKEN_ENDPOINT = "https://oauth2.googleapis.com/token"
  USERINFO_ENDPOINT = "https://www.googleapis.com/oauth2/v3/userinfo"
  SCOPE = "openid email profile"

  def initialize
    @client_id = ENV.fetch("GOOGLE_CLIENT_ID")
    @client_secret = ENV.fetch("GOOGLE_CLIENT_SECRET")
    @redirect_uri = ENV.fetch("GOOGLE_REDIRECT_URI")
  end

  # Googleの同意画面へ遷移させるためのURLを組み立てる
  def authorization_url(state:)
    params = {
      client_id: @client_id,
      redirect_uri: @redirect_uri,
      response_type: "code",
      scope: SCOPE,
      state: state
    }
    "#{AUTHORIZATION_ENDPOINT}?#{URI.encode_www_form(params)}"
  end

  # 認可コードをもとにアクセストークンを取得する
  def exchange_code_for_token(code:)
    response = Net::HTTP.post_form(URI(TOKEN_ENDPOINT), {
      "client_id" => @client_id,
      "client_secret" => @client_secret,
      "code" => code,
      "grant_type" => "authorization_code",
      "redirect_uri" => @redirect_uri
    })
    JSON.parse(response.body)
  end

  # アクセストークンを使ってユーザー情報(email/name等)を取得する
  def fetch_user_info(access_token:)
    uri = URI(USERINFO_ENDPOINT)
    request = Net::HTTP::Get.new(uri)
    request["Authorization"] = "Bearer #{access_token}"

    response = Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
      http.request(request)
    end
    JSON.parse(response.body)
  end
end
