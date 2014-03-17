
def run_local(cmd)
  system cmd
  if($?.exitstatus != 0) then
    puts 'exit code: ' + $?.exitstatus.to_s
    exit
  end
end
