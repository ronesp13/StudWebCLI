def feide?
  @config['login_method'] == 'FEIDE'
end

def pin?
  @config['login_method'] == 'PIN'
end

def prompt_password?
  @config['password'].nil?
end

def prompt_password
  @config['password'] = ask('Enter your FEIDE password: ') { |q| q.echo = false}
end

def prompt_pin?
  @config['pin'].nil?
end

def prompt_pin
  @config['pin'] = ask('Enter your PIN: ') { |q| q.echo = false }
end

def feide_login(browser)
  prompt_password if prompt_password?
  puts 'Attempting to log in using FEIDE'
  browser.element(css: '#j_idt129\:j_idt141 > a:nth-child(6)').click
  choose_affiliation browser
  browser.text_field(id: 'username').set @config['username']
  browser.text_field(id: 'password').set @config['password']
  browser.element(css: '.submit').click
end

def pin_login(browser)
  prompt_pin if prompt_pin?
  puts 'Attempting to log in using PIN'
  browser.element(css: 'div.login-flap.login-name-pin').click
  browser.text_field(id: 'j_idt129:j_idt131:fodselsnummer').set @config['ssn']
  browser.text_field(id: 'j_idt129:j_idt131:pincode').set @config['pin']
  browser.element(css: '#j_idt129\:j_idt131\:login').click
  choose_affiliation browser
  browser.element(css: '#infoPanel\:popup_title > header:nth-child(1)').wait_while_present
  if browser.element(css: 'ul.feedback-full.error').present?
    puts 'Your login attempt failed! Check your credentials in config.yml and try again. Program terminating.'
    exit
  end
end

def choose_affiliation(browser)
  if browser.element(css: '#org').present?
    browser.select_list(id: 'org').select @config['institution_name']
    browser.element(css: '#submit').click
    puts "Chose #{@config['institution_name']} as affiliation."
  end
end

def digit_to_letter(digit)
  return 0 if digit.zero?
  digit = digit.round
  case digit
    when 65
      return 'A'
    when 66
      return 'B'
    when 67
      return 'C'
    when 68
      return 'D'
    when 69
      return 'E'
    when 70
      return 'F'
    else
      return 'Unknown'
  end
end

url = "https://fsweb.no/studentweb/login.jsf?inst=#{@config['institution_code']}"
results_url = 'https://fsweb.no/studentweb/resultater.jsf'

headless = Headless.new(dimensions: '1920x1200x24')
headless.start
browser = Watir::Browser.start url

if feide?
  feide_login browser
elsif pin?
  pin_login browser
else
  puts 'Please specify login-method in config.yml. Program terminating.'
  exit
end

if browser.element(css: 'div#pageTitle').present?
  puts 'Successfully logged into studentweb.'
else
  puts 'Your login attempt failed. Please verify that your credentials are correct in config.yml. Program terminating'
  exit
end

browser.goto results_url

grades = Array.new

browser.elements(css: 'tr.resultatTop, tr.none').each do |element|
  subject = element.elements(css: 'td.col2Emne div.infoLinje')
  grade = element.element(css: 'td.col6Resultat div.infoLinje').text.strip
  printf '%-8s', subject[0].text.strip
  printf '%-30s', subject[1].text.strip
  puts grade
  grades << grade.ord
end

total = 0
grades.each { |i| total += i }

50.times.each { print '-'}
puts "\nGjennomsnittskarakteren din er #{digit_to_letter(total.to_f / grades.size)}."
50.times.each { print '-'}
puts

browser.close
headless.destroy