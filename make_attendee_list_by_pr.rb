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

    info << pr_info["head"]["user"]["avatar_url"]
    login_name = pr_info["head"]["user"]["login"]
    info << login_name

    response = w.get("/users/#{login_name}")
    user_info = JSON.parse(response.body)

    info << user_info["name"]
    email = user_info["email"]
    info << applied_email
  end
  
  info
end

def main
  if ARGV.size < 2
    puts "Usage: ruby make_attendee_list_by_pr.rb INPUT_FILE OUTPUT_FILE"
    return
  end

  input_filename = ARGV[0]
  output_filename = ARGV[1]

  https = Net::HTTP.new('api.github.com',443)
  https.use_ssl = true

  output_lines = []
  File.open(input_filename) do |f|
    i = 0
    f.each_line do |line|
      pr_no, email = line.split(/\s/)
      
      output_lines << get_personal_info_by_pull_request(https, pr_no, email) if i < 2
      i += 1
    end
  end

  package = Axlsx::Package.new
  worksheet = package.workbook.add_worksheet(name: File.basename(output_filename, ".*"))
  output_lines.each do |line|
    worksheet.add_row(line)
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

