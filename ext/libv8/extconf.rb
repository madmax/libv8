require 'mkmf'
require File.expand_path '../../../lib/libv8/version.rb', __FILE__
create_makefile('libv8')
require File.expand_path '../arch.rb', __FILE__
require File.expand_path '../make.rb', __FILE__
require File.expand_path '../compiler.rb', __FILE__

include Libv8::Arch
include Libv8::Make
include Libv8::Compiler

profile = enable_config('debug') ? 'debug' : 'release'

V8_Version = Libv8::VERSION.gsub(/\.\d$/,'')
V8_Source = File.expand_path '../../../vendor/v8', __FILE__
Libv8_Source = File.expand_path '../../..', __FILE__


Dir.chdir(Libv8_Source) do
  system "git submodule update --init"
end

Dir.chdir(V8_Source) do
  system 'git fetch'
  system "git checkout #{V8_Version} -f"
  system "#{make} dependencies"
end

Dir.chdir(Libv8_Source) do
  system "patch -N -p0 -d vendor/v8 < patches/add-freebsd9-and-freebsd10-to-gyp-GetFlavor.patch"
  system "patch -N -p1 -d vendor/v8 < patches/fPIC-on-x64.patch"
  system "patch -N -p1 -d vendor/v8 < patches/gcc42-on-freebsd.patch" if RUBY_PLATFORM.include?("freebsd") && !system("pkg_info | grep gcc-4")
end

Dir.chdir(V8_Source) do
  puts `env CXX=#{compiler} LINK=#{compiler} #{make} #{libv8_arch}.#{profile} GYPFLAGS="-Dhost_arch=#{libv8_arch}"`
end

exit $?.exitstatus
