require 'twitter'
require 'date'
require 'bitly'

# ダメ
OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

# setting
SEARCH_TERM = 60000

TW_CONSUMER_KEY        = ""
TW_CONSUMER_SECRET     = ""

TW_POST_ACCESS_TOKEN        = ""
TW_POST_ACCESS_TOKEN_SECRET = ""


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

BITLY_ACCESS_TOKEN = ""

def bitly_shorten(url)
  Bitly.use_api_version_3
  Bitly.configure do |config|
    config.api_version = 3
    config.access_token = BITLY_ACCESS_TOKEN
  end
  Bitly.client.shorten(url).short_url
end


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
		:count => 10,
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

	outputText += "/ " + Time.now.strftime("%H:%M") # %Y-%m-%d %H:%M:%S
	puts outputText
	puts outputText[0,128]
	twitterOutput(outputText[0,128])
end


