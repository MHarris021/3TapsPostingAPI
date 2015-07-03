rails_root = File.expand_path(File.join(Dir.pwd, '..', '..', 'current')) #"#{deploy_to}/current"
deploy_to = File.expand_path(File.join(Dir.pwd, '..', '..'))
pid_file   = "#{deploy_to}/shared/pids/unicorn_posting.pid"
socket_file= "#{deploy_to}/shared/unicorn_posting.sock"
log_file   = "#{rails_root}/log/unicorn_posting.log"
err_log    = "#{rails_root}/log/unicorn_posting_error.log"
old_pid    = pid_file + '.oldbin'

timeout 60
worker_processes 15
listen socket_file, :backlog => 512
pid pid_file
stderr_path err_log
stdout_path log_file

preload_app true 

GC.copy_on_write_friendly = true if GC.respond_to?(:copy_on_write_friendly=) 

before_exec do |server|
  ENV["BUNDLE_GEMFILE"] = "#{rails_root}/Gemfile"
end

before_fork do |server, worker|
  defined?(ActiveRecord::Base) and
  ActiveRecord::Base.connection.disconnect!

  if File.exists?(old_pid) && server.pid != old_pid
    begin
      Process.kill("QUIT", File.read(old_pid).to_i)
    rescue Errno::ENOENT, Errno::ESRCH
    end
  end
end

after_fork do |server, worker|
  defined?(ActiveRecord::Base) and
  ActiveRecord::Base.establish_connection
end

