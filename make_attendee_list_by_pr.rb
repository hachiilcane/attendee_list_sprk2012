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

  http = Net::HTTP.new(uri.host, uri.port)
  p uri.host
  p uri.request_uri
  http.use_ssl = true if uri.scheme == "https"

  extension = uri.request_uri[/\.\w+$/]
  img = File.expand_path('../avatar/' + save_basename + extension, __FILE__)
  p img
  open(img, 'wb') do |file|
    file.puts http.get(uri.request_uri).body
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
      
      output_lines << get_personal_info_by_pull_request(https, pr_no, email)
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

# pull request json
# "head": {
#   "user": {
#       "gravatar_id": "76a777ff80f30bd3b390e275cce625bc",
#       "login": "amatsuda",
#       "url": "https://api.github.com/users/amatsuda",
#       "avatar_url": "https://secure.gravatar.com/avatar/76a777ff80f30bd3b390e275cce625bc?d=https://a248.e.akamai.net/assets.github.com%2Fimages%2Fgravatars%2Fgravatar-user-420.png",
#       "id": 11493
#   },

# user json
# {
#   "type": "User",
#   "gravatar_id": "0fac0b94dd1a21302fab15d141fae4bc",
#   "public_repos": 4,
#   "login": "hachiilcane",
#   "created_at": "2011-08-01T14:31:44Z",
#   "public_gists": 2,
#   "followers": 4,
#   "url": "https://api.github.com/users/hachiilcane",
#   "avatar_url": "https://secure.gravatar.com/avatar/0fac0b94dd1a21302fab15d141fae4bc?d=https://a248.e.akamai.net/assets.github.com%2Fimages%2Fgravatars%2Fgravatar-user-420.png",
#   "following": 4,
#   "html_url": "https://github.com/hachiilcane",
#   "id": 951892
# }

