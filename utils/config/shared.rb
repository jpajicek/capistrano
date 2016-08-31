
def run_local(cmd)
  system cmd
  if($?.exitstatus != 0) then
    puts 'exit code: ' + $?.exitstatus.to_s
    exit
  end
end

def remote_file_exists?(full_path)
  'true' ==  capture("if [ -e #{full_path} ]; then echo 'true'; fi").strip
end

