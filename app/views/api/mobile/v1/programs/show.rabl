object @program
attributes :id, :description, :is_set, :live, :active, :tracklist_count
node :name do |program|
  program.name_i18n
end
node do |program|
  program.image.as_json
end
node :has_tracklists do |program|
  program.tracklist_count > 0
end
child :users, :object_root => false do
  extends 'api/mobile/v1/users/show'
end