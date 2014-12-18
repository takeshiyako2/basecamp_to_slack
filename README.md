basecamp_to_slack
========================================

Get todo from Basecamp and then say it to Slack.

# How to setup


Install gem library.
```
$ bundle
```

Set basecamp and Slack Webhook URL.
```
# set basecamp  
@check_interval_min = 5
@basecamp_ID = "12345678"
@auth_hash = { :username => "me@example.com", :password => "xxxxxxxxxxxxx" }
@user_agent = "LoganUserAgent (me@example.com)"

# set Slack Webhook URL
@slack_webhook_url = 'https://hooks.slack.com/services/aaaaa/bbbbbb/xxxxxxxxxxx'
```

Set cron.
```
$ crontab -e
*/5 * * * * ruby basecamp_to_slack.rb >> basecamp_to_slack.log
```



# License

Streem is distributed under MIT license.

Takeshi Yako
