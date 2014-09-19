class Question < ActiveRecord::Base
  attr_accessible :name, :description, :question_sql, :tag_list, :data_source
  attr_reader :error

  acts_as_taggable

  # If the sql query has names defined with 'as' then this will find all the columns in the query
  def fields
    question_sql
      .downcase
      .gsub(/(?<block>\((?:(?>[^()]+)|\g<block>)*\))/,'')  # remove nested blocks
      .split(/\s?select\s/).last.split('from').first       # take last root select statement
      .split(',')                                          # split select statement apart
      .map{ |e| (e.strip.ends_with? '%>') ?                # if ERB block...
        e.split[-2] :                                      # use block content. else...
        e.gsub('.', ' ').split[-1] }                       # take final token
  end

  # All ERB inputs of the format <%= input %>
  def inputs
    question_sql.split('<%=').drop(1).map{ |e| e.split[0] }.uniq
  end

  def perform(options = {})
    sql = build_sql(options)
    begin
      question_connection.execute(sql)
    rescue Exception => e
      @error = e
    end
  end

  def build_sql(options = {})
    Erubis::Eruby.new(self.question_sql).result(options)
  end

  def api_info
    {
      :name => name,
      :description => description,
      :inputs => inputs,
      :outputs => fields
    }
  end

  def filename(options)
    tokens = ['Q' + self.id.to_s]
    if options
      tokens += options.to_a.flatten
    end

    tokens << Date.today.to_s

    tokens.join('.') + '.csv'
  end

  private
  def question_connection
    @question_connection || ConnectionChooser.new(data_source).connection
  end
end
