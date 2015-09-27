require 'twitter'
require 'date'
require 'bitly'
require "google/api_client"
require "google_drive"

# ダメ
OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

# setting
SEARCH_TERM = 600

# tattyammアカウントのappとtoken
TW_CONSUMER_KEY        = ""
TW_CONSUMER_SECRET     = ""
# TW_ACCESS_TOKEN        = ""
# TW_ACCESS_TOKEN_SECRET = ""

#　plat_sanのtoken
TW_POST_ACCESS_TOKEN        = ""
TW_POST_ACCESS_TOKEN_SECRET = ""

# bitly
BITLY_ACCESS_TOKEN = ""

# google
GOOGLE_CLIENT_ID = ""
GOOGLE_CLIENT_SECRET = ""
GOOGLE_REFRESH_TOKEN = ""
GOOGLE_SPREADSHEET_KEY = ""
GOOGLE_SPREADSHEET_WORKSHEET_NO = 0


def twitterOutput(message)
	twOutputClient = Twitter::REST::Client.new do |config|
	  config.consumer_key        = TW_CONSUMER_KEY
	  config.consumer_secret     = TW_CONSUMER_SECRET
	  config.access_token        = TW_POST_ACCESS_TOKEN
	  config.access_token_secret = TW_POST_ACCESS_TOKEN_SECRET
	end
	twOutputClient.update(message)
end

def tweetPuts(tweet)
	puts Time.parse(tweet[:created_at])
	puts tweet[:id]
	puts "@" + tweet[:user][:screen_name]
	puts tweet[:text]
	puts
end


def bitly_shorten(url)
  Bitly.use_api_version_3
  Bitly.configure do |config|
    config.api_version = 3
    config.access_token = BITLY_ACCESS_TOKEN
  end
  Bitly.client.shorten(url).short_url
end

def connectSpreadsheet()
	# Authorizes with OAuth and gets an access token.
	client_id = GOOGLE_CLIENT_ID
	client_secret = GOOGLE_CLIENT_SECRET
	refresh_token = GOOGLE_REFRESH_TOKEN

	client = OAuth2::Client.new(
		client_id,
		client_secret,
		site: "https://accounts.google.com",
		token_url: "/o/oauth2/token",
		authorize_url: "/o/oauth2/auth"
	)
	auth_token = OAuth2::AccessToken.from_hash(client,{:refresh_token => refresh_token, :expires_at => 3600})
	auth_token = auth_token.refresh!
	session = GoogleDrive.login_with_oauth(auth_token.token)
	ws = session.spreadsheet_by_key(GOOGLE_SPREADSHEET_KEY).worksheets[GOOGLE_SPREADSHEET_WORKSHEET_NO]
	return ws
end


# TODO 重複チェックして除外
def saveToSpreadsheet(ws, hashList)
	hashList.each do |hash|
		ws.list.push(hash)
	end
	ws.save
end


#-----------------------------------------------------------------

words = [
	"アプリ 課金 できない -rt",
	"アプリ 課金 エラー -rt",
]


# search
twClient = Twitter::REST::Client.new do |config|
  config.consumer_key        = TW_CONSUMER_KEY
  config.consumer_secret     = TW_CONSUMER_SECRET
#  tokenを渡さないでApplication-only authenticationにする
#  config.access_token        = TW_ACCESS_TOKEN
#  config.access_token_secret = TW_ACCESS_TOKEN_SECRET
end
tweetAlertList = []
words.each do |word|
	results = twClient.search(
		word,
		:lang => "ja",
		:result_type => "recent",
		:count => 5,	#default 15. max 
		:until => ((Date.today) + 1).to_s,
	)

	results.attrs[:statuses].each do |tweet|
		if (Time.parse(tweet[:created_at]) > Time.now - SEARCH_TERM) then
			tweetAlertList << tweet
		end
	end
end



# output
if (tweetAlertList.length < 2) then
	puts "no output."
else
	puts tweetAlertList.length.to_s + "counts"

	outputText = "カウント = " + tweetAlertList.length.to_s + " / "
	tweetAlertList.each do |tweet|
		tweetPuts(tweet)
		tweetUrl = "https://twitter.com/" + tweet[:user][:screen_name] + "/status/" + tweet[:id].to_s
		puts bitly_shorten(tweetUrl)
		outputText += bitly_shorten(tweetUrl) + " "
	end

	# twitter output
	outputText += "/ " + Time.now.strftime("%H:%M") # %Y-%m-%d %H:%M:%S
	puts outputText
	puts outputText[0,128]
	#twitterOutput(outputText[0,128])

	# spreadsheet output
	ws = connectSpreadsheet()
	hashList = []
	tweetAlertList.each do |tweet|
		hash = {
			"created_at" => Time.parse(tweet[:created_at]),
			"text" => tweet[:text],
			"screen_name" => tweet[:user][:screen_name],
			"id" => tweet[:id],
			"tweet_url" => "https://twitter.com/" + tweet[:user][:screen_name] + "/status/" + tweet[:id].to_s,
			"ctime" => Time.now.strftime("%Y-%m-%d %H:%M:%S")
		}
		hashList << hash
	end
	if (tweetAlertList.empty?) then
		puts "no output for googlespreadsheets"
	else
		saveToSpreadsheet(ws, hashList)
	end
end

