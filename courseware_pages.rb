# This tool is used to download edx courseware pages
# assumption: you have an account which has alreay registered for the course
# The tool is based on professor Wei Xu's ruby tool :)
require 'fileutils'
require 'rubygems'
require 'selenium-webdriver'
Selenium::WebDriver::Firefox::Binary.path='D:\Program Files\Mozilla Firefox\firefox.exe'

# use local goagent proxy
PROXY = "localhost:8087"
profile = Selenium::WebDriver::Firefox::Profile.new
profile.proxy = Selenium::WebDriver::Proxy.new(
  :http     => PROXY,
  :ftp      => PROXY,
  :ssl      => PROXY
)

#dr=Selenium::WebDriver.for :firefox, :profile => profile
dr=Selenium::WebDriver.for :firefox

dr.manage.timeouts.implicit_wait = 50
dr.manage.timeouts.script_timeout = 50
dr.manage.timeouts.page_load = 300

$course_page_dir="C:/Users/pcliu/Downloads/ruby/data"

# before calling this function, dr should be course list page
def download_one_course(dr, c_url)
    tmp_url=String.new(c_url)
    tmp_url["https://courses.edx.org/courses/"]=""
	tmp_url["/info"]=""
	cname = tmp_url.gsub(/\//, "-")

    data_dir="#{$course_page_dir}/#{cname}"
	p "data dir #{data_dir}"
    FileUtils.mkdir_p data_dir
    
	if File.file?("#{data_dir}/done")
	    p "skip course #{cname}"
	    return
	end

    # go to course page
	p "navigate to #{c_url}"
    dr.navigate.to c_url

	# go to course page
	#p cname
	#query_str = "//a[text()=\"#{cname}\"]"
	#p query_str
	#courselink=dr.find_elements(:xpath, query_str)
    #courselink[0].click

    #sleep 5

    courseware=dr.find_elements(:xpath, '//a[contains(text(),"Courseware")]')
    courseware[0].click

    sleep 5

    cnt = 0
    urls = []
    texts = []
    links=dr.find_elements(:xpath,'//a')
    links.each { |l|
    url = l.attribute("href")
    if url =~ /.*courseware.*/
        urls << url
        texts << l.attribute("text")
        p cnt
        p l.attribute("href")
        p l.attribute("text")
        cnt += 1
    end
    }

    cnt = 0
    urls.each { |l|
        p "============"
		link_text=texts[cnt]
        p "going to : #{link_text}"
        p cnt
        p l
        dr.navigate.to l
        content = dr.page_source.to_str

        #p content

        File.open("#{data_dir}/#{cnt}.html", 'w') { |file|
            file.puts(content)
        }
        cnt += 1
        sleep 1
    }

    # create finish flag for this course
    done_file = File.new("#{data_dir}/done", "w")
	done_file.close
end

login_url="https://courses.edx.org/login"
dr.get login_url

email=dr.find_elements(:id, "email")
email[0].send_keys('liupengcheng@xuetangx.com')

passbox=dr.find_elements(:id, "password")
passbox[0].send_keys('xuetangX')

submitbutton=dr.find_elements(:id, "submit")
submitbutton[0].click

sleep 5
p "we have log in"

course_links=dr.find_elements(:xpath, '//a[@class="enter-course"]')
course_cnt=course_links.length
open_course_urls=[]
p "open course #{course_cnt}"
course_links.each {|c|
    c_url=c.attribute("href")
	open_course_urls << c_url
}

archived_course_links=dr.find_elements(:xpath, '//a[@class="enter-course archived"]')
archived_course_cnt=archived_course_links.length
archived_course_urls=[]
p "archived course #{archived_course_cnt}"
archived_course_links.each {|c|
    c_url=c.attribute("href")
	archived_course_urls << c_url
}

open_course_urls.each{|u|
    download_one_course(dr, u)
}

archived_course_links.each{|u|
    download_one_course(dr, u)
}
#download_one_course(dr, course_name)