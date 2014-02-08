class RawTracklist < ActiveRecord::Base
  serialize :results, Array
end
