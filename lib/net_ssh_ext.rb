class Net::SSH::Connection::Session
  class CommandFailed < StandardError
  end

  class CommandExecutionFailed < StandardError
  end


  def exec_sc!(command,with_print = false)
    stdout_data,stderr_data = "",""
    exit_code,exit_signal = nil,nil
    self.open_channel do |channel|
      channel.exec("bash -l") do |ch,success|

        ch.send_data "#{command}\n"
        ch.send_data "exit\n"
        raise CommandExecutionFailed, "Command \"#{command}\" was unable to execute" unless success

        channel.on_data do |_,data|
          print data if with_print
          stdout_data += data
        end

        channel.on_extended_data do |_,_,data|
          stderr_data += data
        end

        channel.on_request("exit-status") do |_,data|
          exit_code = data.read_long
        end

        channel.on_request("exit-signal") do |_, data|
          exit_signal = data.read_long
        end
      end
    end
    self.loop


    unless exit_code == 0
      puts stderr_data
      raise CommandFailed, "Command \"#{command}\" returned exit code #{exit_code}" 
    end

    {
      stdout:stdout_data,
      stderr:stderr_data,
      exit_code:exit_code,
      exit_signal:exit_signal
    }
  end

  def ex_prefix= prefix
    @ex_prefix= prefix
  end

  def ex_with_print! command
    puts "$ " + command
    @last_ex_state = 
      exec_sc!(@ex_prefix.to_s + " " + command,true) \
      .merge(command: command)
    @last_ex_state[:stdout].strip
  end

  def ex! command
    @last_ex_state = exec_sc!(@ex_prefix.to_s + " " + command) \
      .merge(command: command)
    @last_ex_state[:stdout].strip
  end

  def last_ex_state
    @last_ex_state
  end

  def print_last_ex_state
    puts "#{@last_ex_state[:command]} : #{last_ex_state[:stdout]}"
  end


end

