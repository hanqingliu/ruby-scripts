# This tool is used to register edx courses
# assumption: you have an account

require 'rubygems'
require 'selenium-webdriver'
Selenium::WebDriver::Firefox::Binary.path='D:\Program Files\Mozilla Firefox\firefox.exe'

dr=Selenium::WebDriver.for :firefox
dr.manage.timeouts.implicit_wait = 20
dr.manage.timeouts.script_timeout = 20
dr.manage.timeouts.page_load = 100
url="http://edx.org"

# fill in your account here
account_email = ''
account_password = ''

# before calling this function, dr should be course list page
def register_one_course(dr, page_num, idx_in_page)
    if page_num == 0
        page_url="https://www.edx.org/course-list"
    else
        page_url="https://www.edx.org/course-list?page=#{page_num}"
    end
   
    dr.get page_url

    course = dr.find_elements(:xpath, '//a[contains(@href, "www.edx.org/course/")]')[idx_in_page]
    p course.attribute("text")
    course.click
    sleep 3

    dr.switch_to.frame dr.find_elements(:xpath, '//iframe[contains(@class, "iframe-register")]')[0]
    registerlink=dr.find_elements(:xpath, '//a[contains(text(), "Register for")]')
    if registerlink[0].nil? != true
        registerlink[0].click
        p "click register"
        sleep 3

	# may still need to select track, by default use audit mode
        audit=dr.find_elements(:xpath, '//input[@name="audit_mode"]')[0]
        if audit.nil? != true
            audit.click
            sleep 3
        end
    else
        p "cannot find register link, go back to course list"
        dr.switch_to.default_content
        allcourseslink=dr.find_elements(:link, "COURSES")[0]
        allcourseslink.click
        return false
    end
    return true
end

# start work from log in
p url
dr.get url

loginlink=dr.find_elements(:link, "log in")
loginlink[0].click

sleep 5
p "we are now in log in page"

email=dr.find_elements(:id, "email")
email[0].send_keys(account_email)

passbox=dr.find_elements(:id, "password")
passbox[0].send_keys(account_password)

submitbutton=dr.find_elements(:id, "submit")
submitbutton[0].click

sleep 5
p "we have log in"

allcourseslink=dr.find_elements(:link, "FIND COURSES")
allcourseslink[0].click
sleep 5
p "In all courses page"

course_cnt = 0
registered_course_cnt=0
page_cnt = 0

courses=dr.find_elements(:xpath, '//a[contains(@href, "www.edx.org/course/")]')
idx_in_current_page=0
courses.each {|c|
    p "course cnt : #{course_cnt}"
    p "registered course cnt : #{registered_course_cnt}"

    if register_one_course(dr, page_cnt, idx_in_current_page)
        registered_course_cnt += 1
    end

    idx_in_current_page += 1
    course_cnt += 1
}

dr.get "https://www.edx.org/course-list"
nextpagelink=dr.find_elements(:xpath, '//a[contains(text(), "next")]')
while nextpagelink[0].nil? != true do
    nextpagelink[0].click
    page_cnt += 1
    sleep 3
    courses=dr.find_elements(:xpath, '//a[contains(@href, "www.edx.org/course/")]')
    idx_in_current_page=0
    courses.each {|c|
        p "course cnt : #{course_cnt}"
        p "registered course cnt : #{registered_course_cnt}"
	    
        if register_one_course(dr, page_cnt, idx_in_current_page)
            registered_course_cnt += 1
        end
        idx_in_current_page += 1
        course_cnt += 1
    }

    # go back to course list of current page
    dr.get "https://www.edx.org/course-list?page=#{page_cnt}"
    nextpagelink=dr.find_elements(:xpath, '//a[contains(text(), "next")]')
end
