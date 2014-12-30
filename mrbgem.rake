MRuby::Gem::Specification.new('mruby-pure-regexp') do |spec|
  spec.license = 'MIT'
  spec.authors = 'h2so5'
  spec.summary = 'pure mruby Regexp class'
  spec.add_dependency('mruby-array-ext', :core => 'mruby-array-ext')
  spec.add_dependency('mruby-fiber', :core => 'mruby-fiber')
end
