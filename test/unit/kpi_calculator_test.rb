require 'test_helper'

class KpiCalculatorTest < ActiveSupport::TestCase
  context "build sql" do
    setup do
      @kpi_hash = {
        :name     => "test query",
        :query    => "SELECT '<%= kpi_date %>' as date,
                      CAST('Total' as varchar(255)) as event_type,
                      COUNT(CASE WHEN a.created_at BETWEEN '<%=today_start%>' AND '<%=end_date%>' THEN a.id ELSE NULL END) as Today,
                      COUNT(CASE WHEN a.created_at BETWEEN '<%=seven_day_start%>' AND '<%=end_date%>' THEN a.id ELSE NULL END) as T7Days,
                      COUNT(CASE WHEN a.created_at BETWEEN '<%=thirty_day_start%>' AND '<%=end_date%>' THEN a.id ELSE NULL END) as T30Days,
                      COUNT(CASE WHEN a.created_at BETWEEN '<%=quarter_start%>' AND '<%=end_date%>' THEN a.id ELSE NULL END) as QTD,
                      COUNT(CASE WHEN a.created_at BETWEEN '<%=year_start%>' AND '<%=end_date%>' THEN a.id ELSE NULL END) as YTD
                      FROM accounts a
                      WHERE a.created_at BETWEEN '<%=start_date%>' AND '<%=end_date%>'"
      }
    end

    should "build the correct sql" do
      date        = Date.new(2013,3,15)
      kpi         = Kpi.new(@kpi_hash)
      correct_kpi = "SELECT '2013-03-15' as date,
                    CAST('Total' as varchar(255)) as event_type,
                    COUNT(CASE WHEN a.created_at BETWEEN '2013-03-1504:00:00-0400' AND '2013-03-1604:00:00-0400' THEN a.id ELSE NULL END) as Today,
                    COUNT(CASE WHEN a.created_at BETWEEN '2013-03-0904:00:00-0500' AND '2013-03-1604:00:00-0400' THEN a.id ELSE NULL END) as T7Days,
                    COUNT(CASE WHEN a.created_at BETWEEN '2013-02-1404:00:00-0500' AND '2013-03-1604:00:00-0400' THEN a.id ELSE NULL END) as T30Days,
                    COUNT(CASE WHEN a.created_at BETWEEN '2013-01-0104:00:00-0500' AND '2013-03-1604:00:00-0400' THEN a.id ELSE NULL END) as QTD,
                    COUNT(CASE WHEN a.created_at BETWEEN '2013-01-0104:00:00-0500' AND '2013-03-1604:00:00-0400' THEN a.id ELSE NULL END) as YTD
                    FROM accounts a
                    WHERE a.created_at BETWEEN '2013-01-0104:00:00-0500' AND '2013-03-1604:00:00-0400'"
      Time.use_zone('Eastern Time (US & Canada)') do
        calculator = KpiCalculator.new(kpi, date)
        assert_equal correct_kpi.gsub(/\s+/,""), calculator.build_sql.gsub(/\s+/,"")
      end
    end
  end

  context "#percent change" do
    setup do
      @calculator = KpiCalculator.new(Kpi.new, Date.today)
    end

    should "give correct percent change with no nil values" do
      assert_equal 100.00, @calculator.send(:percent_change, 100, 50)
      assert_equal -40.00, @calculator.send(:percent_change, 60, 100)
    end

    should "return nil if any nil values" do
      assert_equal nil, @calculator.send(:percent_change, 100, nil)
      assert_equal nil, @calculator.send(:percent_change, nil, 100)
    end

    should "return nil if any zero values" do
      assert_equal nil, @calculator.send(:percent_change, 100, 0)
      assert_equal nil, @calculator.send(:percent_change, 0, 100)
    end
  end
end
