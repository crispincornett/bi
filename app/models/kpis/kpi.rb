class Kpi < ActiveRecord::Base
  attr_accessible :name, :query, :active, :tag_list, :data_source

  acts_as_taggable

  has_many :kpi_results, :dependent => :destroy

  scope :active, :conditions => {:active => true}

  def self.results_for_tag_and_date(tag, date)
    kpi_ids = Kpi.tagged_with(tag).map(&:id)
    KpiResult.scoped(:conditions => {:date => date, :kpi_id => kpi_ids})
  end

  def most_recent_result
    KpiResult.where("kpi_id = ?", self.id).order("date DESC").limit(1).first
  end

  def result_for_date(date)
    KpiResult.where("kpi_id = ? AND date = ?", self.id, date).first
  end

  def results_between_dates(start_date, end_date)
    KpiResult.where("kpi_id = ? AND date BETWEEN ? AND ?", self.id, start_date, end_date).order("date desc")
  end

  def values_between_dates(start_date, end_date, value)
    query = results_between_dates(start_date, end_date).select("date, max(#{value})").where("#{value} > 0").group(:date).to_sql
    connection.select_rows query
  end

  def calculate!(date)
    KpiCalculator.new(self, date).calculate!
  end

  def backfill(start = Date.new(2010,1,1), only_empty = true)
    date = start
    while date < Time.now.to_date do
      calculate!(date) unless only_empty && result_for_date(date).present?
      date +=1
    end
  end

  def query_connection
    kpi_connection
  end

  private

  def kpi_connection
    if Rails.env != 'test'
      @connection ||= ConnectionChooser.new(data_source).connection
    end
  end

end
