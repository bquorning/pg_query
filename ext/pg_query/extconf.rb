# rubocop:disable Style/GlobalVars

require 'digest'
require 'mkmf'
require 'open-uri'

LIB_PG_QUERY_TAG = '10-1.0.1'.freeze
LIB_PG_QUERY_DIGEST = 'd028b3b309138a008aebc2d6bd14b119'.freeze

workdir = Dir.pwd
libdir = File.join(workdir, 'libpg_query-' + LIB_PG_QUERY_TAG)
gemdir = File.join(__dir__, '../..')
libfile = libdir + '/libpg_query.a'
target_file_path = "#{workdir}/libpg_query.tar.gz"

unless File.exist?(target_file_path)
  File.open(target_file_path, 'wb') do |target_file|
    open('https://codeload.github.com/lfittl/libpg_query/tar.gz/' + LIB_PG_QUERY_TAG, 'rb') do |read_file|
      target_file.write(read_file.read)
    end
  end
end

unless Digest::MD5.file(target_file_path).hexdigest == LIB_PG_QUERY_DIGEST
  raise("MD5 digest of downloaded file #{target_file_path} is wrong.")
end

unless Dir.exist?(libdir)
  system("tar -xzf #{workdir}/libpg_query.tar.gz") || raise('ERROR')
end

unless Dir.exist?(libfile)
  # Build libpg_query (and parts of PostgreSQL)
  system("cd #{libdir}; #{ENV['MAKE'] || (RUBY_PLATFORM =~ /bsd/ ? 'gmake' : 'make')} build")
end

# Copy test files (this intentionally overwrites existing files!)
system("cp #{libdir}/testdata/* #{gemdir}/spec/files/")

$objs = ['pg_query_ruby.o']

$LOCAL_LIBS << '-lpg_query'
$LIBPATH << libdir
$CFLAGS << " -I #{libdir} -O3 -Wall -fno-strict-aliasing -fwrapv -g"

SYMFILE = File.join(__dir__, 'pg_query_ruby.sym')
if RUBY_PLATFORM =~ /darwin/
  $DLDFLAGS << " -Wl,-exported_symbols_list #{SYMFILE}" unless defined?(::Rubinius)
else
  $DLDFLAGS << " -Wl,--retain-symbols-file=#{SYMFILE}"
end

create_makefile 'pg_query/pg_query'
