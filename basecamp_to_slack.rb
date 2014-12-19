#!/usr/bin/ruby
require 'logan'
require 'rest_client'

# set basecamp 
@check_interval_min = 5
@basecamp_ID = "12345678"
@auth_hash = { :username => "me@example.com", :password => "xxxxxxxxxxxxx" }
@user_agent = "LoganUserAgent (me@example.com)"

# set Slack Webhook URL
@slack_webhook_url = 'https://hooks.slack.com/services/aaaaa/bbbbbb/xxxxxxxxxxx'

# parse json
def get_collection(url)
  response = RestClient::Request.new(
    :method => :get,
    :url => url.to_s,
    :user => @auth_hash[:username],
    :password => @auth_hash[:password],
    :headers => { :accept => :json,
    :content_type => :json }
  ).execute
  results = JSON.parse(response.to_str)
end

# print to Slack
def put_slack(text)
  puts text
  ref = `curl -X POST --data-urlencode 'payload={
    "channel": "#notification", 
    "icon_emoji": ":ocean:",
    "mrkdwn": true, 
    "text": "#{text}", 
    "type": "message", 
    "username": "basecamp"
}' #{@slack_webhook_url}`
  puts ref
end

# client for basecamp
logan = Logan::Client.new(@basecamp_ID, @auth_hash, @user_agent)
basecamp_projects = logan.projects

# datetime for check interval
datetime_interval = (Time.now - 60 * @check_interval_min).strftime("%Y%m%d%H%M%S")

# projects loop
basecamp_projects.each do |project|

  # todolist loop
  project.todolists.each do |todolist|
    todolist_json = get_collection(todolist.url)

    # remaining todo loop
    todolist_json["todos"]["remaining"].each do |todo|
      todo_created_datetime = DateTime.parse(todo["created_at"])
      todo_updated_datetime = DateTime.parse(todo["updated_at"])

      # is new todo?
      if todo_created_datetime.strftime("%Y%m%d%H%M%S") > datetime_interval
        # new todo was created!!!
        # has assignee?
        assignee = ''
        if todo["assignee"] == nil
          assignee = 'nil'
        else
          assignee = todo["assignee"]["name"]
        end
        put_slack("[#{project.name} #{todolist.name}] #{todo["creator"]["name"]} created #{todo["content"]} assignee #{assignee} #{todo["app_url"]}")
      end

      # todo was updated?
      if todo_updated_datetime.strftime("%Y%m%d%H%M%S") > datetime_interval
        # updated todo!!
        todo_json = get_collection(todo["url"])
        todo_json["comments"].each do |comment|
          comment_updated_datetime = DateTime.parse(comment["updated_at"])
          # is new comment?
          if comment_updated_datetime.strftime("%Y%m%d%H%M%S") > datetime_interval
            # updated comment!!
            content = comment["content"]
            if content != nil
              content = content.gsub(/"/, "").gsub(/<\/?[^>]*>/, "")
              max_size = 300
              if content.size >= max_size
                content = content.each_char.each_slice(300).map(&:join)[0]
                content = content + ' ...'
              end
            end
            put_slack("[#{project.name} #{todolist.name}] #{comment["creator"]["name"]} updated #{todo["content"]} -> #{content} #{todo["app_url"]}")
          end
        end
      end
    end

    # completed todo loop
    todolist_json["todos"]["completed"].each do |completed_todo|
      completed_todoupdated_datetime = DateTime.parse(completed_todo["updated_at"])
      # todo was updated?
      if completed_todoupdated_datetime.strftime("%Y%m%d%H%M%S") > datetime_interval
        # closes todo!!
        put_slack("[#{project.name} #{todolist.name}] #{completed_todo["completer"]["name"]} closed #{completed_todo["content"]} #{completed_todo["app_url"]}")
      end
    end

  end
end
