require 'selenium-webdriver'

#Monkey Patch's - Use with care!
#Path to allow true custom capabilities
#e.g. job name for sauce labs
module Selenium
  module WebDriver
    module Remote
      class Capabilities

        def custom_capabilities(opts)
          @custom_capabilities = opts
        end

        #hopefuly this alias approach will mean we capture changes in the webdriver method
        alias_method :old_as_json, :as_json
        def as_json(opts = nil)

          hash = old_as_json
          if @custom_capabilities 
            @custom_capabilities.each do |key, value|
              hash[key] = value
            end
          end
          hash
        end

      end
    end
  end
end

##
#Patch to allow following of symlinks when serializing ff profiles
#This means we can put certs and key db files into a secure location
#on the ci box and then check in symlinks to these files.
#
#I think this should be fixed in Webdriver itself
#http://code.google.com/p/selenium/issues/detail?id=2416
module Selenium
  module WebDriver
    module Zipper
      def self.zip(path)
        # can't use Tempfile here since it doesn't support File::BINARY mode on 1.8
        # can't use Dir.mktmpdir(&blk) because of http://jira.codehaus.org/browse/JRUBY-4082
        tmp_dir = Dir.mktmpdir
        begin
          zip_path = File.join(tmp_dir, "webdriver-zip")

          Zip::ZipFile.open(zip_path, Zip::ZipFile::CREATE) { |zip|
            ::Find.find(path) do |file|
              next if File.directory?(file)
              entry = file.sub("#{path}/", '')
              #PATCH begin
              entry = Zip::ZipEntry.new(zip_path, entry)
              entry.follow_symlinks = true
              #PATCH end - nothing removed from original

              zip.add entry, file
            end
          }

          File.open(zip_path, "rb") { |io| Base64.strict_encode64 io.read }
        ensure
          FileUtils.rm_rf tmp_dir
        end
      end
    end # Zipper
  end # WebDriver
end # Selenium
