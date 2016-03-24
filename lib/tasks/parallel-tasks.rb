class ParallelTasks
  include Rake::DSL if defined? Rake::DSL

  def install_tasks
    require 'bundler/setup'
    require 'parallel'
    require 'rspec/core/rake_task'
    require 'rubocop/rake_task'
    require 'cucumber/rake/task'
    require 'yard'
    require_relative 'merge_cucumber_json_reports'

    def run_rake_task(name)
      puts "name is #{name}"
      begin
        Rake::Task[name].invoke
      rescue Exception => e
        puts "Exception running rake task: #{e}"
        return false
      end
      true
    end

    def reports(name)
      "--format pretty --format junit --out=reports/junit_#{name} --strict --format html " \
      "--out=reports/#{name}.html --format json --out=reports/#{name}.json"
    end

    def bundle_exec
      ENV['BUNDLE_EXEC'] || 'bundle exec '
    end

    def env
      ENV['ENVIRONMENT'] ? "ENVIRONMENT=#{ENV['ENVIRONMENT']}" : 'ENVIRONMENT=live'
    end

    def tags
      ENV['TAGS'] || ''
    end

    def features_dir
      ENV['FEATURES_DIR'] || 'features'
    end

    def get_thread_count
      ENV['THREAD_COUNT'] ? ENV['THREAD_COUNT'].to_i : 2
    end

    def write_confluence_report(passfail)
      require "erb"
      template = File.read(File.dirname(__FILE__) + '/confluence.erb')
      @result = passfail == 'pass' ? 'green' : 'red'
      File.open('reports/confluence.html', 'w+').puts ERB.new(template).result(binding)
    end

    desc 'Run all examples'
    RSpec::Core::RakeTask.new(:spec) do |t|
      t.rspec_opts = %w(--color -fprogress -fhtml -oreports/rspec.html)
    end

    desc 'Create some docs'
    YARD::Rake::YardocTask.new do |t|
      t.files   = ['lib/**/*.rb']
      t.options = %w(--markup=markdown)
    end

    desc 'Feature documentation'
    YARD::Rake::YardocTask.new(:yarddoc) do |t|
      t.files = ['features/*.feature', 'features/**/*.rb']
    end

    desc 'Make sure we are good rubyists'
    RuboCop::RakeTask.new(:rubocop) do |t|
      t.formatters = ['progress']
      t.options = ['-fhtml', '-oreports/rubocop.html']
      # don't abort rake on failure
      t.fail_on_error = false
    end

    desc 'Run cukes on production in parallel with browserstack chrome'
    task :parallel_cuke do |t|
      sh "#{bundle_exec}parallel_cucumber -n #{get_thread_count} -o '#{tags} #{env}' #{features_dir}"
    end

    desc 'Rerun failed cukes on production with browserstack chrome'
    task :rerun do
      sh "#{bundle_exec}cucumber -p rerun #{env} @reports/rerun.txt #{reports('rerun')}"
    end

    desc 'Run selenium and rerun failed tests'
    task :tests_with_retry do
      selenium_successful = run_rake_task('parallel_cuke')
      rerun_successful = true
      rerun_successful = run_rake_task('rerun') unless selenium_successful
      result = (selenium_successful || rerun_successful) == true ? 'pass' : 'fail'
      puts "Overall result is #{result}"
      write_confluence_report(result)
      fail 'Cucumber Failure' if result == 'fail'
    end

    desc 'Remove all files from the ./reports and ./doc directory'
    task :clean do
      require 'fileutils'
      FileUtils.rm_rf Dir.glob('reports/*')
      FileUtils.rm_rf Dir.glob('doc/*')
    end

    desc 'Use Junit Merge to merge results from multiple threads'
    task :junit_merge do
      require 'fileutils'

      report_dir = 'reports'
      junit_dir = "#{report_dir}/junit_results"

      (2..get_thread_count).each do |thread|
        original_reports = Dir.entries junit_dir
        thread_reports = Dir.entries "#{junit_dir}#{thread}"
        thread_reports.reject { |f| File.directory?(f) }.each do |report|
          if  original_reports.include?(report)
            sh "#{bundle_exec}junit_merge #{junit_dir}#{thread}/#{report} #{junit_dir}/#{report}"
          else
            puts  "copy #{junit_dir}#{thread}/#{report} to #{junit_dir}"
            FileUtils.cp  "#{junit_dir}#{thread}/#{report}", junit_dir
          end
        end
      end
      junit_rerun = Dir.glob "#{report_dir}/junit_rerun/*xml"
      sh "#{bundle_exec}junit_merge #{report_dir}/junit_rerun #{junit_dir}" unless junit_rerun.empty?
    end

    desc 'Merge Cucumber JSON reports'
    task :json_merge do
      c = CucumberJSONMerger.new
      c.run
      c.rerun
      File.open('combined.json', 'w+').write c.master.to_json
    end
  end
end

ParallelTasks.new.install_tasks
