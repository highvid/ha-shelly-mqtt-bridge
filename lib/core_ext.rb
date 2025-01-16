Dir[File.join(__dir__, 'core_ext/**/*.rb')].sort.each do |file|
  require file
end
