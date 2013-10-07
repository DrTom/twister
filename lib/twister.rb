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


      opts = Slop.parse help: true, banner: "Usage: twister [options] action|command environment [options]" do 

        on :c, :config, "Specify the path to alternative configuration file", argument: true  

        on :a, "show-actions", "Show the defined basic actions" do
          puts Twister::Runner.instance_methods(false).sort
          exit 0
        end

        on :m, "show-commands", 
          "Show the (in the configuration) defined commands (sequence of actions) for the environment", 
          argument: true 

        on :v, :version, 'Print the version' do
          puts "Version #{Twister::VERSION}"
          exit 0
        end

      end

      if environment = opts.to_hash[:"show-commands"]
        config = YAML.load_file(opts[:config] || 'config/twister.yml')
        puts config[environment]["commands"].keys
        exit 0
      end

      action = ARGV.shift
      environment = ARGV.shift

      if action and environment
        config = YAML.load_file(opts[:config] || 'config/twister.yml')
        twister_runner = Twister::Runner.new config[environment]["variables"]
        if commands = config[environment]["commands"][action]
          commands.each do |step|
            twister_runner.send step
          end
        else
          twister_runner.send action
        end
      else
        puts %<I don't understand what I am supposed to do, try "twister --help"!>
      end

    end
  end
end
