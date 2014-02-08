object @user
attributes :id
node :first_name do |user|
  user.first_name_i18n
end
node :last_name do |user|
  user.last_name_i18n
end
node :about do |user|
  strip_tags(user.about).gsub(/\&nbsp\;/,' ')
end
node do |user|
  user.image.as_json
end
node :fullname do |user|
  user.fullname
end