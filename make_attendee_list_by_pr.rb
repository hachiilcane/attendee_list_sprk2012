require 'net/https'
require 'json'
require 'axlsx'

def get_personal_info_by_pull_request(https, pr_no, applied_email)
  # pr_no, icon, login_name, name, email
  info = []
  info << pr_no

  https.start do |w|
    response = w.get("/repos/sprk2012/sprk2012-cfp/pulls/#{pr_no}")
    pr_info = JSON.parse(response.body)

    avatar_url = pr_info["user"]["avatar_url"]
    img_filename = nil
    img_filename = save_image_file(avatar_url, pr_no) if avatar_url != nil
    info << img_filename
    login_name = pr_info["user"]["login"]
    info << login_name

    response = w.get("/users/#{login_name}")
    user_info = JSON.parse(response.body)

    info << user_info["name"]
    # email = user_info["email"]
    info << applied_email
  end
  
  info
end

def save_image_file(url, save_basename)
  uri = URI.parse(url)

  # get image
  http = Net::HTTP.new(uri.host, uri.port)
  p uri.host
  p uri.request_uri
  http.use_ssl = true if uri.scheme == "https"
  response = http.get(uri.request_uri)

  # save image
  extension = ""
  if /filename=\".+(\..+)\"/ =~ response['Content-Disposition']
    extension = $1
  end
  img = File.expand_path('../avatar/' + save_basename + extension, __FILE__)
  p img

  response_body = response.body
  if response_body.length > 1
    open(img, 'wb') do |file|
      file.puts response_body
    end
  else
    img = nil
  end

  img
end

def main
  if ARGV.size < 2
    puts "Usage: ruby make_attendee_list_by_pr.rb INPUT_FILE OUTPUT_FILE"
    return
  end

  input_filename = ARGV[0]
  output_filename = ARGV[1]

  image_dir = './avatar'
  FileUtils.mkdir_p(image_dir) unless FileTest.exist?(image_dir)

  https = Net::HTTP.new('api.github.com',443)
  https.use_ssl = true

  output_lines = []
  File.open(input_filename) do |f|
    i = 0
    f.each_line do |line|
      pr_no, email = line.split(/\s/)
      if pr_no.to_i > 0
        output_lines << get_personal_info_by_pull_request(https, pr_no, email)
      end
      i += 1
    end
  end

  # output as xlsx
  package = Axlsx::Package.new
  worksheet = package.workbook.add_worksheet(name: File.basename(output_filename, ".*"))

  output_lines.each_with_index do |line, index|
    img_filename = line[1]
    line[1] = nil

    worksheet.add_row(line, :height => 35)
    if img_filename != nil
      frame = worksheet.add_image(:image_src => img_filename, :noSelect => true, :noMove => true, :noResize => true) do |image|
        image.width=30
        image.height=30
        image.start_at 1, index
      end

      # if there isn't the line below, the anchor of the image is not in the right cell. Is this a bug? 
      frame.anchor.from.rowOff = 10000
    end

  end

  package.use_shared_strings = true # for Numbers
  package.serialize(output_filename)
end

main()
