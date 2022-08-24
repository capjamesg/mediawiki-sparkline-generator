require "nokogiri"
require "httparty"
require "date"
require "sinatra"

def get_sparkline (url)
    begin
        request = HTTParty.get(url)
    rescue
        error 400
    end

    dates = []

    month = Date.today.month
    year = Date.today.year

    date_90_days_ago = Date.new(year, month, 1) - 90

    last_month = (date_90_days_ago..Date.today).to_a

    # convert last month to strings
    last_month = last_month.map { |date| date.to_s }

    last_month_as_dict = last_month.map { |date| [date.to_s, 0] }.to_h

    for contribution in JSON.parse(request.body)["query"]["usercontribs"]
        # date comes after time
        date = contribution["timestamp"].split("T")[0]

        formatted_date = Date.parse date

        dates << formatted_date.to_s
    end

    for date in dates
        if last_month.include? date
            last_month_as_dict[date] += 1
        end
    end

    return "https://jamesg.blog/assets/sparkline.svg?" + last_month_as_dict.values.join(","), last_month_as_dict.values.sum
end

get "/" do
    username = params[:username]
    api_url = params[:api_url]
    only_image = params[:only_image]

    if !username
        return "A ?username= value is required. This value is case sensitive."
    end

    if !api_url
        return "An ?api_url= value is required."
    end

    url = "#{api_url}?action=query&format=json&list=usercontribs&ucuser=#{username}&uclimit=500"

    sparkline, contributions_in_three_months = get_sparkline(url)

    if contributions_in_three_months == 500
        contributions_in_three_months = "500 (contributions are limited to 500 so the actual number of contributions made by this user may be higher)"
    end

    if only_image
        redirect sparkline
    end

    doc = "
    <p>sparkline for #{username.downcase} (last three months)</p>
    <p>total contributions: #{contributions_in_three_months}</p>
    <embed src='#{sparkline}' alt='Sparkline'></embed>
    "

    return doc
end

error 400 do
    "Please provide a valid username and URL."
end

error 404 do
    "This page does not exist."
end

error 500.599 do
    "There was a server error."
end