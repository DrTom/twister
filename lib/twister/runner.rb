module Twister

  class Runner
    def initialize params
      # some defaults:
      @pgpidname = 'pid'
      @rails_env = 'development'

      params.each do |key,value|
        instance_variable_set "@#{key}", value
      end
    end

    def backup 
      Net::SSH.start @host, @torquebox_user do |ssh|
        ssh.ex_prefix= "cd #{@app_dir};export RAILS_ENV=#{@rails_env}; #{pg_env}"
        ssh.ex_with_print! "pg_dump -E utf-8 -F p -Z 5 -O --no-acl -f 'tmp/backup_#{Time.now.iso8601}.pgsql.gz' #{@database_database}"
      end
      self
    end



    def create_and_fetch_db_dump
      name=  "dump_#{@rails_env}_#{Time.now.iso8601}.pgbin"
      remote_file_path = "/tmp/#{name}"
      local_file_path = "tmp/#{name}"
      Net::SSH.start @host, @torquebox_user do |ssh|
        ssh.ex_prefix= "cd #{@app_dir};export RAILS_ENV=#{@rails_env}; #{pg_env}"
        ssh.ex_with_print! "pg_dump -E utf-8 -F c -Z 5 -O --no-acl -f '#{remote_file_path}' #{@database_database}"
      end
      Net::SCP.download! @host, @torquebox_user, remote_file_path, local_file_path
      self
    end

    def undeploy
      Net::SSH.start @host, @torquebox_user do |ssh|
        ssh.ex_prefix= "cd #{@app_dir};export RAILS_ENV=#{@rails_env}; #{@load_torquebox_env_cmd};" 
        ssh.ex_with_print! "rm -f $JBOSS_HOME/standalone/deployments/#{descriptor_name}.deployed"
      end
      self
    end

    def git_update
      Net::SSH.start @host, @torquebox_user, forward_agent: true do |ssh|
        ssh.ex_prefix= "cd #{@app_dir};export RAILS_ENV=#{@rails_env}; #{@load_torquebox_env_cmd};"
        ssh.ex_with_print! "git fetch origin +#{@branch}:tmp"
        ssh.ex_with_print! "git reset --hard tmp --"
      end
      self
    end

    def bundle
      Net::SSH.start @host, @torquebox_user do |ssh|
        ssh.ex_prefix= "cd #{@app_dir};export RAILS_ENV=#{@rails_env}; #{@load_torquebox_env_cmd};"
        ssh.ex_with_print! 'bundle install --deployment'
      end
      self
    end

    def terminate_db_connections
      Net::SSH.start @host, @torquebox_user do |ssh|
        ssh.ex_prefix= "cd #{@app_dir};export RAILS_ENV=#{@rails_env}; #{pg_env}"
        sql= <<-SQL
        SELECT pg_terminate_backend(pg_stat_activity.#{@pgpidname}) 
          FROM pg_stat_activity WHERE pg_stat_activity.datname = '#{@database_database}';
        SQL
        ssh.ex_with_print! "psql -c \"#{sql}\""
      end
      self
    end

    def restore_db_from_db
      Net::SSH.start @host, @torquebox_user do |ssh|
        ssh.ex_prefix= "cd #{@app_dir};"
        ssh.ex_with_print! "dropdb --if-exists -U postgres #{@database_database}"
        ssh.ex_with_print! "createdb -U postgres #{@database_database}"
        # we could get rid of the file entirely
        ssh.ex_with_print! "pg_dump -U postgres -E utf-8 -F p -Z 5 -O --no-acl -f tmp/productive_data.pgsql.gz #{@database_database_source}"
        ssh.ex_with_print! "cat tmp/productive_data.pgsql.gz | gunzip | psql -U postgres -q #{@database_database}"
      end
      self
    end

    def migrate
      Net::SSH.start @host, @torquebox_user do |ssh|
        ssh.ex_prefix= "cd #{@app_dir}; export RAILS_ENV=#{@rails_env}; load_rbenv; " 
        ssh.ex_with_print! "bundle install --deployment"
        ssh.ex_with_print! "bundle exec rake db:migrate"
      end
      self
    end

    def reset_db
      Net::SSH.start @host, @torquebox_user do |ssh|
        ssh.ex_prefix= "cd #{@app_dir}; export RAILS_ENV=#{@rails_env}; load_rbenv; " 
        ssh.ex_with_print! "bundle install --deployment"
        ssh.ex_with_print! "bundle exec rake db:reset"
      end
    end

    def precompile_assets
      Net::SSH.start @host, @torquebox_user do |ssh|
        ssh.ex_prefix= "cd #{@app_dir}; export RAILS_ENV=#{@rails_env}; load_rbenv; " 
        ssh.ex_with_print! "bundle install --deployment"
        ssh.ex_with_print! "rm -rf public/assets/*"
        ssh.ex_with_print! "rm -rf tmp/cache/*"
        ssh.ex_with_print! "RAILS_RELATIVE_URL_ROOT='#{@sub_path}' bundle exec rake assets:precompile"
      end
      self
    end

    def deploy
      Net::SSH.start @host, @torquebox_user do |ssh|
        ssh.ex_prefix= "cd #{@app_dir};export RAILS_ENV=#{@rails_env}; #{@load_torquebox_env_cmd};" 
        ssh.ex_with_print! "cp #{@descriptor} $JBOSS_HOME/standalone/deployments/#{descriptor_name}"
        ssh.ex_with_print! "touch $JBOSS_HOME/standalone/deployments/#{descriptor_name}.dodeploy"
      end
      self
    end

    def pg_env 
      { "@database_host" => "PGHOST",
        "@database_port" => "PGPORT",
        "@database_password" => "PGPASSWORD",
        "@database_username" => "PGUSER",
        "@database_database" => "PGDATABASE" } \
        .select{ |instance_variable_name,target_env| instance_variable_defined?(instance_variable_name) } \
        .map{ |instance_variable_name,target_env| "export #{target_env}='#{instance_variable_get(instance_variable_name)}';" } \
        .join(" ")
    end

    def descriptor_name
      "#{@app_name}_#{@rails_env}-knob.yml"
    end

  end
end
