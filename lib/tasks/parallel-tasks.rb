class ParallelTasks
  include Rake::DSL if defined? Rake::DSL

  def install_tasks
    require 'bundler/setup'
    require 'parallel'
    require 'rspec/core/rake_task'
    require 'rubocop/rake_task'
    require 'cucumber/rake/task'
    require 'yard'

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
      "--format pretty --format junit --out=reports/#{name} --strict --format html " \
      "--out=reports/#{name}.html --format json --out=reports/#{name}.json"
    end

    def env
      ENV['ENVIRONMENT'] ? "ENVIRONMENT=#{ENV['ENVIRONMENT']}" : 'ENVIRONMENT=live'
    end

    def tags
      ENV['TAGS'] || ''
    end

    def get_thread_count
      ENV['THREAD_COUNT'] ? ENV['THREAD_COUNT'].to_i : 2
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
      sh "bundle exec parallel_cucumber -n #{get_thread_count} -o '#{tags} #{env}' features"
    end

    desc 'Rerun failed cukes on production with browserstack chrome'
    Cucumber::Rake::Task.new(:rerun_browserstack) do |t|
      t.cucumber_opts = %W(-p browserstack #{env} @reports/rerun.txt #{reports('junit_rerun')})
    end

    desc 'Run selenium and rerun failed tests'
    task :tests_with_retry do
      selenium_successful = run_rake_task('parallel_cuke')
      rerun_successful = true
      rerun_successful = run_rake_task('rerun_browserstack') unless selenium_successful
      puts "result is #{selenium_successful} and  #{rerun_successful}"
      fail 'Cucumber Failure' unless selenium_successful || rerun_successful
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
            sh "junit_merge #{junit_dir}#{thread}/#{report} #{junit_dir}/#{report}"
          else
            puts  "copy #{junit_dir}#{thread}/#{report} to #{junit_dir}"
            FileUtils.cp  "#{junit_dir}#{thread}/#{report}", junit_dir
          end
        end
      end
      junit_rerun = Dir.glob "#{report_dir}/junit_rerun/*xml"
      sh "junit_merge #{report_dir}/junit_rerun #{junit_dir}" unless junit_rerun.empty?
    end
  end
end

ParallelTasks.new.install_tasks