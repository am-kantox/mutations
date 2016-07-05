begin
  require 'dry-validation'
  require 'mutations/dry/schema'
rescue LoadError => e
  $stderr.puts [
    '[DRY] Unable to load dry validation extension.',
    'Make sure it is installed. Rolling back to standard impl.',
    "Error: [#{e.message}]."
  ].join($/)
end
