require 'rest_client'
require 'json'

class TrackerClient
  attr_reader :project_id

  def initialize(project_id, token=nil)
    @project_id = project_id
    @token = token
  end

  def accepted_stories(accepted_since=nil)
    modified_since_query = "%20modified_since:#{accepted_since.strftime('%m/%d/%Y')}" if accepted_since

    accepted_story_payload = RestClient.get "#{project_url}/search?query=state:accepted%20includedone:true#{modified_since_query}", api_options
    accepted_stories = JSON.parse(accepted_story_payload)['stories']['stories']
    accepted_stories.map { |story| story['id'].to_s }
  end

  def raw_stories_between(start_date, end_date)
    RestClient.get "#{project_url}/search?query=state:accepted%20includedone:true%20accepted_since:#{start_date}%20accepted_before:#{end_date}", api_options
  end

  def raw_activities_for(story_id)
    RestClient.get "#{project_url}/stories/#{story_id}/activity", api_options
  end

  def parsed_stories
    @parsed_stories ||= JSON.parse(raw_stories_between('1/1/2014', '4/1/2014'))['stories']['stories']
  end

  def pull_stories
    parsed_stories.each_with_index do |story_hash, x|
      s = Story.create(story_hash)
      s.activities = JSON.parse(raw_activities_for(story_hash['id']))
      puts x if x % 10 == 0
    end
  end

  def project_url
    "https://www.pivotaltracker.com/services/v5/projects/#{project_id}"
  end

  def api_options
    @token ? { 'X-TrackerToken' => @token } : {}
  end
end
