require "nokogiri"
require "httparty"
require "date"
require "sinatra"

set :port, 3031
set :environment, :production

def get_sparkline (url, days, is_bar)
    begin
        request = HTTParty.get(url)
    rescue
        error 400
    end

    dates = []

    month = Date.today.month
    year = Date.today.year

    date_90_days_ago = Date.new(year, month, 1) - days.to_i

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

    if is_bar
        svg_contents = ""
        bars_created = 0
        
        for i in last_month_as_dict.values.each
            # make sure at least a tiny bar is shown for each item
            puts i
            if i == 0
                bar_height = 1.to_s
            else
                bar_height = i.to_s
            end

            svg_contents += '<rect width="1" height="' + bar_height + '" x="' + (bars_created + 2).to_s + '" y="0" />'
            bars_created += 1
        end

        return '<svg width="100%" height="100%" viewBox="0 0 200 100" preserveAspectRatio="none" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:ev="http://www.w3.org/2001/xml-events">' + svg_contents + '</svg'
    else
        return "/sparkline.svg?" + last_month_as_dict.values.join(","), last_month_as_dict.values.sum
    end
end

get "/" do
    username = params[:username]
    api_url = params[:api_url]
    only_image = params[:only_image]
    days = params[:days]
    is_bar = params[:is_bar]

    if !days
        days = 90
    end

    if days.to_i > 120 || days.to_i < 1
        return "?days= must be between 1 and 120."
    end

    if !username
        return "A ?username= value is required. This value is case sensitive."
    end

    if !api_url
        return "An ?api_url= value is required."
    end

    # default is to generate a line graph
    if !is_bar
        is_bar = false
    end

    url = "#{api_url}?action=query&format=json&list=usercontribs&ucuser=#{username}&uclimit=500"

    sparkline, contributions_in_three_months = get_sparkline(url, days, is_bar)

    if contributions_in_three_months == 500
        contributions_in_three_months = "500 (contributions are limited to 500 so the actual number of contributions made by this user may be higher)"
    end

    if only_image
        redirect sparkline
    end

    # <embed src='alt='Sparkline'></embed>

    doc = "
    <p>sparkline for #{username.downcase} (last three months)</p>
    <p>total contributions: #{contributions_in_three_months}</p>
    #{sparkline}
    <p>Source code available on <a href='https://github.com/capjamesg/mediawiki-sparkline-generator'>GitHub</a>.</p>
    "

    return doc
end

get "/sparkline.svg" do
    send_file File.read(File.join(settings.public_folder, "sparkline.svg"))
end

get "/sparkline_bar.svg" do
    send_file File.read(File.join(settings.public_folder, "sparkline_bar.svg"))
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