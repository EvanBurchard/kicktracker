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


totals = {
  :goal_date => goal_date[0].to_s.strip,
  :time => DateTime.now.to_s,
  :backers => counts[0][0].to_i, 
  :raised => raised, 
  :goal => goal,
  :cash_over_goal => -(goal - raised),
  :cash_under_goal => goal - raised,
  :days_left => counts[2][0].to_i
}

puts url
pp totals
storage << totals

FileUtils.mkdir_p directory
File.open(filename, 'w+') {|f| f.write(storage.to_yaml) }
exit 0

