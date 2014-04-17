class Story
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  embeds_many :labels
  embeds_many :activities

  def commencement
    activities.where(highlight: 'started').first
  end

  def acceptance
    activities.where(highlight: 'accepted').first
  end

  def duration
    start_date = commencement.try(:occurred_at) || Time.now.strftime('%c')
    accepted_date = acceptance.try(:occurred_at) || Time.now.strftime('%c')
    Time.parse(accepted_date) - Time.parse(start_date)
  end

  def duration_words
    Duration.new.distance_of_time_in_words duration
  end

  class Duration
    include ActionView::Helpers::DateHelper
  end

  class Top10List
    def example
      features = Story.where(story_type: "feature")
      top10 = features.sort_by { |f| f.duration }.reverse[0, 10]
      pp top10.map { |x| [x.name, x.duration_words]}
    end
  end
end
