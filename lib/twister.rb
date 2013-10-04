# require 'pry'
require 'net/ssh'
require 'net/scp'
require 'net_ssh_ext'
require 'rubygems'
require 'slop'
require 'time'
require 'twister/runner'
require 'twister/version'
require 'yaml'

module Twister

  class << self

    def main

      opts = Slop.parse help: true, banner: "Usage: twister [options] command environment [options]" do

        on :c, :config, "path to alternative configuration file", argument: true  

        on :v, :version, 'Print the version' do
          puts "Version #{Twister::VERSION}"
          exit 0
        end

      end

      action = ARGV.shift
      environment = ARGV.shift

      if action and environment
        config = YAML.load_file(opts[:config] || 'config/twister.yml')
        twister_runner = Twister::Runner.new config[environment]["variables"]
        steps = config[environment]["steps"][action]
        steps.each do |step|
          twister_runner.send step
        end
      else
        puts %<I don't understand what I am supposed to do, try "twister --help"!>
      end

    end
  end
end
