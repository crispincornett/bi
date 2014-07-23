## BI

BI is a rails app built at Paperless Post to solve our business reporting needs.

As our team grew, more and more people needed data. So, it became the developers part time jobs to run queries. Whenever someone needed data, a dev would have to manually run a query, and send a csv with the query results.

This process was a big pain to both devs and business people, and as a result, people were not getting the data they needed.

The idea behind BI is that one developer writes a query once, and anyone in the company can run that query again, whenever they want, for whatever parameters they want, and get realtime results.

It gives super simple realtime reporting, in a format that business people love, and is easy to service by programmers.

BI is divided into four sections:

#### *Questions*

Questions are the core of BI, and where you will spend most of your time. Questions are stored SQL queries, with variable parameters that can be input by the user when they are run.

Questions use `erb` notation within the SQL, so you can write a template of a query, with variable parameters, such as `start_date` or `end_date` for users to input when they run the query.

Results are shown to the user on screen, and they can also be downloaded in csv form.

#### *KPIs*

KPIs are queries that are run each night, and the results of those nightly queries are stored in the BI database.

KPIs are the things you want to track every single day, and have an easy way to track going back in time. KPI queries return results in a very specific format with the following fields:

`today, today % change, 7 days, 7 day % change, 30 days, 30 day % change, quarter to date, year to date`

KPIs are for top line metrics that you want to see every day, and will fit into this format.

Examples of things that fit well as KPI's would be: total sales, number of customers, new accounts, and number of cancelled customers.

Here's an example of how you need to structure a kpi query. You need to be pretty specific about the naming, but you get a lof of easy analysis in return.

      SELECT '<%=kpi_date%>' as date,
      COUNT(CASE WHEN a.registered_at BETWEEN '<%=today_start%>' AND '<%=end_date%>' THEN a.id ELSE NULL END) as Today,
      COUNT(CASE WHEN a.registered_at BETWEEN '<%=seven_day_start%>' AND '<%=end_date%>' THEN a.id ELSE NULL END) as T7Days,
      COUNT(CASE WHEN a.registered_at BETWEEN '<%=thirty_day_start%>' AND '<%=end_date%>' THEN a.id ELSE NULL END) as T30Days,
      COUNT(CASE WHEN a.registered_at BETWEEN '<%=quarter_start%>' AND '<%=end_date%>' THEN a.id ELSE NULL END) as QTD,
      COUNT(CASE WHEN a.registered_at BETWEEN '<%=year_start%>' AND '<%=end_date%>' THEN a.id ELSE NULL END) as YTD
      FROM accounts a
      WHERE a.registered_at BETWEEN '<%=start_date%>' AND '<%=end_date%>'

There is a rake task that will run all your kpis, and calculate percent changes. Just call:

`bundle exec rake daily_kpis_from_replica`

#### *Reports*

Reports are for when a single SQL query isn't enough, and you need some extra code to either combine multiple queries, pull data from an external API, or do another custom thing with the data.

Reports are just ruby classes that return whatever data you are looking for and display it in a rails view. Anything you can do in ruby, you can do in a report.

Reports also take a much longer amount of time to create, so we try to answer most data requests in Questions instead of reports.

Some reports that have been very useful to us are:

**KPI Goal Report** - Tracks our progress towards quarterly KPI goals

**Comparison Report** - Compares two time periods for sales, number of customers, repeat customers and other important metrics

**Activity Report** - Given a csv of users, show all activity of those users over a specific time period

#### *Visualizations*

Visualizations are our dashboards, and playground. Similar to Reports, they are just plain ruby classes connected to a rails view, which we use to build pretty dashboards, primarily using d3.js.

Some examples of our visualizations are:

**Live Purchase Map** - Displays a map of the US with a live feed of customer purchases

**Countdown** - This shows a countdown to important upcoming holidays. At Paperless Post, it's very convineint to see this information at a glance.

## Installation

BI is a Ruby on Rails app. If you already have the necessary components in place, installing BI into your infrastructure should be quick.

Here's how you install BI to your infrastructure:

##### Fork it

You're going to want to have your own copy of the app so you can create your own reports and visualizations.

##### Configure Settings

`bundle exec rake secret` to generate a new secret token for `config/initializers/secret_token.rb`

setup your email smtp settings in `config/application.rb:79`


##### Set Up Data Sources

Copy `config/data_sources.yml.example` to `config/data_sources.yml`

In the data_sources file, you can add two types of connections: database connections or api connections.

For database connections, add a `type:db` attribute to each record, and then just give the normal ActiveRecord connection information.

You don't want to run BI on any production database, because when users run long queries, they will mess with production. We recommend you set up a read-only database for analytics, and run your BI queries on that database.

For API connections, add `type:api` along with any api keys or tokens you need for that API.

Currently, only Graphite is supported as an API, with Mixpanel coming very soon. If you're looking for support for other API's, open an issue.

##### Create The Database

Create a `config/database.yml` file based off of the `config/database.yml.example` file. This gives BI connection information for the BI database, not the database(s) you will be querying.

`bundle exec rake db:create`

`bundle exec rake db:migrate`

##### Run Tests

`bundle exec rake db:test:prepare` to create the test database

`bundle exec rake` to run the tests. Everything should be all green



### Style and Conventions

#### Questions

Please ensure that any new questions are tagged. If possible, use existing tags.

Questions take the form of SQL queries. Any token that you would like the user to be able to input in a text field can be indicated with `erb` markers `<%= sample %>`.

`WHERE a.created_at = '<%= created_date %>`

becomes

`WHERE a.created_at = '1/1/2013'`

*Special Formats*

Two types of markers are treated specially, dates and groups. 

Any marker containing the string `'date'`, e.g. `<%= start_date %>` will display a datepicker to assist the user in inserting a date.

The special marker `<%= group_by_range %>` will display a dropdown allowing the user to select between different data groupings.

A sample query using this marker may look like the following:

    SELECT date_trunc('<%= group_by_range %>', created_at) AS <%= group_by_range %>
    , Count(*) as count
    FROM accounts
    WHERE registered_at between '<%= start_date %>' AND '<%= end_date %>'
    GROUP BY date_trunc('<%= group_by_range %>', created_at)
    ORDER BY date_trunc('<%= group_by_range %>', created_at) DESC

The user will see a dropdown with options for `day`, `week`, `month`, `quarter` and `year`, and can group that data however they want

#### KPIs

These take the form of SQL queries that return data in a very specific format. These fields must be named either: 

`'Today', 'T7days', 'T30days', 'QTD', and 'YTD'`

preferably including all five. The data for each is saved to the BI database, for quick access later. 

    BETWEEN '<%=today_start%>' AND '<%=end_date%>'
    BETWEEN '<%=seven_day_start%>' AND '<%=end_date%>'
    BETWEEN '<%=thirty_day_start%>' AND '<%=end_date%>'
    BETWEEN '<%=quarter_start%>' AND '<%=end_date%>'
    BETWEEN '<%=year_start%>' AND '<%=end_date%>'
    
After the initial KPI Results are saved, another function goes through and calculates percent changes. All you need to do to get a KPI set up and calculated forever is write the query once.

#### Reports, Visualizations

No rules here. Just don't break anything. These both work just like a normal rails view.

For those unfamiliar with creating a page in rails, you should check out one of the many online rails tutorials, but here is an extremely condensed overview of what you need to do:

Add a method to `app/controllers/report_controller.rb` for the report you want, and in the controller, pass any information you want to be available in the view as a variable starting with `@`: so `@variable_name`

Generally, add a class to `app/models/reports/` to create a class that will do all the calculations you want for the report.

Add a file to `app/views/reports/` where the file name matches your method name

Add javascript files as necessary to `app/assets/javascripts`

### Contributors

A number of people contributed either code or ideas to BI

1. [Solomon Kahn](http://www.twitter.com/solomonkahn)
2. [Alfred Lee](http://www.twitter.com/alphrabet)
3. [Aaron Quint](http:/www.twitter.com/aq)
4. [Michael Hansen](http://www.twitter.com/modality)
5. [Dan Schneiderman](http://www.twitter.com/hiteak)

### Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
