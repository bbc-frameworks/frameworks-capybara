require 'json'

# class to merge cucumber json report
class CucumberJSONMerger
  attr_reader :master

  def initialize
    @reports = Dir.glob('reports/report*.json').map { |f| JSON.parse(File.read(f)) }
    @master = @reports.shift
  end

  def run
    @reports.each do |report|
      report.each do |feature|
        fname = feature.fetch 'uri'
        update(fname, feature, report)
      end
    end
  end

  def update(fname, feature, report)
    if feature_exists? fname
      scenarios(report, fname).each do |scenario|
        sname = scenario.fetch 'name'
        scenario_exists?(sname, fname) ? replace_scenario(sname, scenario, fname) : append_scenario(scenario, fname)
      end
    else
      append_feature feature
    end
  end

  def rerun
    json_rerun = Dir.glob "#{report_dir}/rerun.json"
    if json_rerun.empty?
      puts 'no rerun file found'
    else
      @reports = [JSON.parse(File.read('reports/rerun.json'))]
      run
    end
  end

  private

  def feature_names(report)
    report.map { |f| f['uri'] }
  end

  def scenario_names(report, fname)
    scenarios(report, fname).map { |s| s['name'] }
  end

  def scenarios(report, fname)
    report.find { |f| f['uri'] == fname }['elements'].select { |e| e['keyword'] == 'Scenario' }.flatten
  end

  def feature_exists?(name)
    feature_names(@master).include? name
  end

  def scenario_exists?(scenario, fname)
    scenario_names(@master, fname).include? scenario
  end

  def replace_scenario(sname, scenario, feature)
    puts "Replacing #{sname} in #{feature} in master"
    @master.find { |f| f['uri'] == feature }['elements'].delete_if do |e|
      e['keyword'] == 'Scenario' && e['name'] == sname
    end
    append_scenario(scenario, feature)
  end

  def append_scenario(scenario, feature)
    puts "Need to append SCENARIO: #{scenario['name']} to FEATURE: #{feature} in master"
    @master.find { |f| f['uri'] == feature }['elements'] << scenario
  end

  def append_feature(feature)
    puts "Need to append FEATURE: '#{feature['name']}' in master"
    @master.push feature
  end
end
