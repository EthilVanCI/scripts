def puts(*args)
   return puts('') if args.empty?
   Kernel.puts(*args.map { |arg| '#  ' + arg.to_s })
end

def puts_line
   Kernel.puts '# ' + '=' * 100
end

def puts_datas(datas)
   ljust = datas.map { |key, value| key.length }.max + 3
   datas.each do |key, value|
      puts key.to_s.ljust(ljust) + ' : ' + value.to_s
   end
end

@exit_code = 0
def abort_if(condition, message)
   @exit_code += 1
   return unless condition
   puts message
   exit @exit_code
end

def abort_unless(condition, message)
   abort_if(!condition, message)
end

def env(name, default = :exit)
   value = ENV[name]
   return value unless value.nil?
   abort_if(default == :exit, "Missing Environment variable '#{name}'")
   return default
end

def shell(cmd, verbose = false)
   puts "Command: #{cmd}" if verbose
   output = `#{cmd}`
   return unless verbose
   output = *output.split("\n").compact
   unless output.empty?
      puts 'Output'
      puts output
   end
end

def shell_v(cmd)
   shell(cmd, true)
end
