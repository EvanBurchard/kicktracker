#!/usr/bin/env ruby

require 'rubygems'
require 'mechanize'
require 'pp'

username = "eerichmond"
project = "lets-sail-around-the-world-the-first-ever-communi"
# URL to your Kickstarter project
url = "http://www.kickstarter.com/projects/#{username}/#{project}?ref=search"
directory = File.dirname(__FILE__)+"/projects/#{username}/#{project}/"
filename = directory + "results-#{DateTime.now.to_s}.yml"
storage = ( File.exists?(filename) ? YAML.load(File.open(filename, 'r')) : [] )

agent = Mechanize.new
agent.user_agent = "Kicktracker <http://github.com/evanburchard/kicktracker>"
page = agent.get(url)

money = (page/'#moneyraised')
counts = (money/'h5').map do |stat|
  stat.content.split("\n").select {|n| !n.nil? && !n.empty? }.compact
end
goal_date = (page/'#banner').map do |words|
  words.content.select {|n| !n.nil? && !n.empty? }.compact
end
goal = counts[1][1].match(/of (.*) goal/)[1].gsub('$','').gsub(',','').to_i
raised = counts[1][0].gsub(',','').gsub('$','').to_i

what_you_get = page/'#what-you-get'

reward_index = 0
rewards = {} 
  (what_you_get/'div'/'.reward').each do |reward|
  rewards[("level_" + reward_index.to_s).to_sym] = {
    :backing_amount => (reward/'h3')[0].content.delete(",").match(/\d+/)[0].to_i,
    :description => (reward/'.desc'/'p')[0].content,
    :backers => (reward/'.num-backers')[0].content.split("\n").select{|n| !n.nil? && !n.empty? }.compact[0].to_i}
  reward_index = reward_index + 1
end
totals = {
  :goal_date => goal_date[0].to_s.strip,
  :time => DateTime.now.to_s,
  :backers => counts[0][0].to_i, 
  :raised => raised, 
  :goal => goal,
  :cash_over_goal => -(goal - raised),
  :cash_under_goal => goal - raised,
  :days_left => counts[2][0].to_i,
  :rewards => rewards
}

# puts url
 pp totals
storage << totals

FileUtils.mkdir_p directory
File.open(filename, 'w+') {|f| f.write(storage.to_yaml) }
exit 0

