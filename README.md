# Twister

Twister helps you to deploy ruby on rails applications to a torquebox instance.
It works much like a seriously pared down variant of capistrano!

## Usage

Here is an example `twister deploy staging -c config/twister.yml`. With the
relevant part of `config/twister.yml` as follows: 

    default: 
      variables: &default_variables
        app_name: 'domina_ci'
        load_torquebox_env_cmd: 'load_torquebox_env'
        root_user: 'root'
        torquebox_user: 'torquebox'
        host: BigMac3
     
    staging:
      variables:
        <<: *default_variables
        app_dir: /home/torquebox/domina_ci_staging
        branch: master
        database_database: domina_ci_staging
        database_username: postgres
        descriptor: config/torquebox-domina_ci_staging.yml
        rails_env: staging
        sub_path: "/domina_ci_staging"
      steps: 
        deploy: [undeploy, git_update, bundle, terminate_db_connections, migrate, precompile_assets, deploy]

