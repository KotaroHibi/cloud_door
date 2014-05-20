guard :rspec do
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^spec/cloud_door_spec/.+_spec\.rb$})
  watch(%r{^lib/(.+)\.rb$})     { |m| "spec/#{m[1]}_spec.rb" }
  watch(%r{^lib/cloud_door/(.+)\.rb$})     { |m| "spec/cloud_door/#{m[1]}_spec.rb" }
  watch('spec/spec_helper.rb')  { 'spec' }
end
