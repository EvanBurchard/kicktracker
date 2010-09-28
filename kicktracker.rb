#!/usr/bin/env ruby

require 'rubygems'
require 'mechanize'
require 'pp'

def number_of_projects(search_url)
  crawl_agent = Mechanize.new
  crawl_agent.user_agent = "Kicktracker <http://github.com/evanburchard/kicktracker>"
  page = crawl_agent.get(search_url)
  (page/'.blurb'/'span')[0].content.match(/\d+/)[0].to_i
end

def get_project_urls(search_url)
  crawl_agent = Mechanize.new
  crawl_agent.user_agent = "Kicktracker <http://github.com/evanburchard/kicktracker>"
  begin
    page = crawl_agent.get(search_url)
    urls = []
    projects = (page/'.project'/'a').map do |p|
      if p.attributes['href'].to_s.match(/projects/)
        urls << p.attributes['href'].to_s
      end
    end
    urls
  rescue
    []
  end
end

primary_search_url = "http://www.kickstarter.com/projects/search?term=e&commit=Go"
per_page = 12
project_totals = number_of_projects(primary_search_url)
times_to_search = project_totals/per_page


project_urls = get_project_urls(primary_search_url)

times_to_search.times do |i|  
  project_urls = project_urls | get_project_urls("http://www.kickstarter.com/projects/search?commit=Go&page=#{i+2}&term=e")
end
project_urls =  project_urls.uniq


def project_info(url)
  username = url.split("/")[2]
  project = url.split("/")[3][0..-12]

  directory = File.dirname(__FILE__)+"/projects/#{username}/#{project}/"
  filename = directory + "results-#{DateTime.now.to_s}.yml"
  storage = ( File.exists?(filename) ? YAML.load(File.open(filename, 'r')) : [] )

  agent = Mechanize.new
  agent.user_agent = "Kicktracker <http://github.com/evanburchard/kicktracker>"
  page = agent.get("http://kickstarter.com" + url)

  money = (page/'#moneyraised')
  counts = (money/'h5').map do |stat|
    stat.content.split("\\\\n").select {|n| !n.nil? && !n.empty? }.compact
  end
  goal_date = (page/'#banner').map do |words|
    words.content.select {|n| !n.nil? && !n.empty? }.compact
  end
  begin
    goal = counts[1][1].match(/of (.*) goal/)[1].gsub('$','').gsub(',','').to_i
  rescue
    goal = counts[1][0].match(/of (.*) goal/)[1].gsub('$','').gsub(',','').to_i
  end
  raised = counts[1][0].gsub(',','').gsub('$','').to_i

  what_you_get = page/'#what-you-get'

  reward_index = 0
  rewards = {} 
    (what_you_get/'div'/'.reward').each do |reward|
    rewards[("level_" + reward_index.to_s).to_sym] = {
      :backing_amount => (reward/'.dollasignage'/'h3')[0].content.delete(",").match(/\d+/)[0].to_i,
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

   pp totals
  storage << totals

  FileUtils.mkdir_p directory
  f = File.open(filename, 'w+') {|f| f.write(storage.to_yaml) }
end
project_urls.each do |project_url|
  project_info(project_url)
end
