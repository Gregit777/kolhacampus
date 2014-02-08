require Rails.root.join('lib/yaml_column')
$db_conn = {:host => 'localhost', :username => 'root', :password => '', :database => '106fm_%s' % Rails.env, :encoding => 'utf8'}
$base_dir = Rails.env.to_s == 'development' ? '/Users/zohararad/workspace/106fm' : '/var/www/106fm/production/current'
$mysql_client = Mysql2::Client.new($db_conn)

def cleanup_body(str)
  patterns = [
    /style\=\"[^\"]+\"/i,
    /class\=\"[^\"]+\"/i,
    /dir\=\"[^\"]+\"/i,
    /[\n\r\t]/,
    /<br\s?\/>/i,
    /<p><\/p>/i,
    /<p>\&nbsp\;<\/p>/i,
    /<\/?b>/
  ]
  patterns.each do |regex|
    str.gsub!(regex,'')
  end
  str
end

## Migrate Users
def migrate_users
  puts "migrating users"
  ActiveRecord::Base.connection.execute('truncate table users')
  $mysql_client.query("select * from users order by id asc").each(:symbolize_keys => true) do |_user|
    user = User.new
    user.id = _user[:id]
    user.first_name = _user[:firstname]
    user.last_name = _user[:surname]
    user.first_name_en = _user[:firstname_en]
    user.last_name_en = _user[:surname_en]
    user.email = _user[:email]
    user.about = _user[:description]
    user.active = _user[:active]
    user.status = _user[:confirmed].to_i == 1 ? Status::Confirmed : Status::Pending
    path = File.join($base_dir,'public',_user[:image])
    if File.exist?(path)
      user.image = File.open(path)
    end

    roles = []
    roles << 'admin' if _user[:admin].to_i == 1
    case _user[:type]
      when 1 then roles << 'broadcaster'
      when 2 then roles << 'assistant_broadcaster'
      when 3 then roles << 'producer'
      when 4 then roles << 'assistant_producer'
      when 5 then roles << 'author'
      else roles << 'user'
    end
    user.roles = roles
    user.password = _user[:email]
    if user.save
      puts "user #{user.id} save"
    else
      if user.errors.include? :email
        user.email = '%s@106fm.co.il' % (Random.rand(1..10000) + Random.rand(1..10000)).to_s
        if user.save
          puts "user #{user.id} save"
        else
          user.errors.each {|error| puts error.inspect }
        end
      end
    end
  end
end

## Migrate Programs
def migrate_programs
  puts "migrating programs"
  ActiveRecord::Base.connection.execute('truncate table programs')
  ActiveRecord::Base.connection.execute('truncate table programs_users')
  ActiveRecord::Base.connection.execute('insert into programs_users (select program_id, user_id from 106fm_%s.programs_users)' % Rails.env)
  ActiveRecord::Base.connection.execute('insert into programs (select id, name, name_en, description, null as image, active, live, (confirmed + 1) as status, icast_program_id, 0 as is_set, 0 as tracklist_count, NOW() as created_at, NOW() as updated_at from 106fm_%s.programs)' % Rails.env)

  $mysql_client.query("select id, image from programs order by id asc").each(:symbolize_keys => true) do |_prog|
    path = File.join($base_dir,'public',_prog[:image])
    prog = Program.find(_prog[:id])
    if File.exist?(path)
      f = File.open(path)
      prog.image = f
    end
    prog.tracklist_count = Tracklist.where(program_id: prog.id).where.not(ondemand_url: nil).count
    prog.save!
  end
end

## Migrate Schedules
def migrate_schedules
  puts "migrating schedules"
  ActiveRecord::Base.connection.execute('truncate table schedules')
  ActiveRecord::Base.connection.execute('insert into schedules (select id, title, description, configuration, start_date, end_date, is_default from 106fm_%s.schedules)' % Rails.env)
end

def migrate_tracks
  puts "migrating tracks"
  begin
    ActiveRecord::Base.connection.execute('truncate table tracklists')
    ActiveRecord::Base.connection.execute("ALTER TABLE `tracklists` ADD `old_tracks` LONGTEXT NULL")
    ActiveRecord::Base.connection.execute('insert into tracklists (select id, program_id, description, NULL as description_en, publish_date as publish_at, NULL as tracks, NULL as feed, ondemand_url, confirmed + 1 as status, token, publish_date as created_at, publish_date as updated_at, tracklist_data as old_tracks from 106fm_%s.tracks where YEAR(publish_date) >= 2005 and ondemand_url is not null order by id desc)' % Rails.env)
    Tracklist.instance_eval do
      serialize :old_tracks, YAMLColumn.new
    end
    Tracklist.all.find_each do | tl |
      begin
        unless tl.old_tracks.nil?
          puts "updating tracklist #{tl.id}"
          tl.tracks = tl.old_tracks
          tl.save
        end
      rescue Exception => e
        puts e.message
        puts "Cannot save track with id #{tl.id}"
      end
    end
  ensure
    ActiveRecord::Base.connection.execute("ALTER TABLE `tracklists` DROP `old_tracks`")
    ActiveRecord::Base.connection.execute("delete from `tracklists` where tracks = '{}' or tracks is null or ondemand_url is null or ondemand_url = ''")
  end
end

def migrate_categories
  puts "migrating categories"
  ActiveRecord::Base.connection.execute('truncate table categories')
  ['ביקורת אלבום', 'כתבה', 'אירוע', 'עדכוני רדיו'].each do |cat|
    Category.create name: cat
  end
end

def migrate_articles
  puts "migrating articles"
  ActiveRecord::Base.connection.execute('truncate table articles')
  ActiveRecord::Base.connection.execute('truncate table articles_users')
  ActiveRecord::Base.connection.execute('truncate table articles_categories')
  articles_sql = '
    select articles.id, articles.title, articles.subtitle, articles.post, articles.publish_date,
    articles.status, articles.updated_at, GROUP_CONCAT(articles_users.user_id) as user_ids, GROUP_CONCAT(tags.name) as tags, GROUP_CONCAT(subjects.subject) as subjects
    from articles
    inner join articles_users on articles.id = articles_users.article_id
    inner join taggings on taggings.taggable_id = articles.id and taggings.taggable_type = "Article"
    inner join tags on taggings.tag_id = tags.id
    left join posts_subjects on posts_subjects.post_uid = CONCAT("article-",articles.id)
    left join subjects on subjects.id = posts_subjects.subject_id
    GROUP BY articles.id
    order by articles.id desc
    limit 100
  '

  albums_sql = '
    select albums.id, albums.title, albums.subtitle, albums.post, albums.publish_date, albums.preview_image,
    albums.status, albums.updated_at, GROUP_CONCAT(albums_users.user_id) as user_ids, GROUP_CONCAT(tags.name) as tags, GROUP_CONCAT(subjects.subject) as subjects
    from albums
    inner join albums_users on albums.id = albums_users.album_id
    inner join taggings on taggings.taggable_id = albums.id and taggings.taggable_type = "Album"
    inner join tags on taggings.tag_id = tags.id
    left join posts_subjects on posts_subjects.post_uid = CONCAT("album-",albums.id)
    left join subjects on subjects.id = posts_subjects.subject_id
    GROUP BY albums.id
    order by albums.id desc
    limit 100
  '

  updates_sql = '
    select updates.id, updates.title, updates.subtitle, updates.post, updates.publish_date, updates.preview_image,
    updates.status, updates.updated_at, updates.user_id, GROUP_CONCAT(tags.name) as tags, GROUP_CONCAT(subjects.subject) as subjects
    from updates
    inner join taggings on taggings.taggable_id = updates.id and taggings.taggable_type = "Update"
    inner join tags on taggings.tag_id = tags.id
    left join posts_subjects on posts_subjects.post_uid = CONCAT("update-",updates.id)
    left join subjects on subjects.id = posts_subjects.subject_id
    GROUP BY updates.id
    order by updates.id desc
    limit 100
  '

  articles_cat = Category.find_by_name 'כתבה'
  albums_cat = Category.find_by_name 'ביקורת אלבום'
  updates_cat = Category.find_by_name 'עדכוני רדיו'

  puts "migrating articles into articles"
  $mysql_client.query(articles_sql).each(:symbolize_keys => true) do |raw_article|
    h = {
      title: raw_article[:title],
      subtitle: raw_article[:subtitle],
      body: cleanup_body(raw_article[:post]),
      publish_at: raw_article[:publish_date],
      status: raw_article[:status],
      created_at: raw_article[:updated_at],
      updated_at: raw_article[:updated_at],
      tags: raw_article[:tags].split(',').uniq,
      old_id: 'articles:%s' % raw_article[:id]
    }
    article = Article.new h
    r = Regexp.new('/images/uploads/\d{4,}-\d{2}/[\w\d]+\.\w+')
    image = raw_article[:post].match(r)
    if image
      path = File.join($base_dir,'public',image[0])
      if File.exist?(path)
        article.image = File.open(path)
      end
    end
    raw_article[:user_ids].split(',').each do |user_id|
      if User.exists?(user_id)
        article.users.push User.find(user_id)
      end
    end
    unless raw_article[:subjects].nil?
      raw_article[:subjects].split(',').uniq.each do |subject|
        category = Category.find_or_create_by name: subject
        article.categories.push category
      end
    end
    article.categories.push articles_cat
    article.save
  end

  puts "migrating albums into articles"
  $mysql_client.query(albums_sql).each(:symbolize_keys => true) do |raw_album|
    h = {
      title: raw_album[:title],
      subtitle: raw_album[:subtitle],
      body: cleanup_body(raw_album[:post]),
      publish_at: raw_album[:publish_date],
      status: raw_album[:status],
      created_at: raw_album[:updated_at],
      updated_at: raw_album[:updated_at],
      tags: raw_album[:tags].split(',').uniq,
      old_id: 'albums:%s' % raw_album[:id]
    }
    album = Article.new h
    unless raw_album[:preview_image].blank?
      path = File.join($base_dir,'public',raw_album[:preview_image])
      if File.exist?(path)
        album.image = File.open(path)
      end
    end
    raw_album[:user_ids].split(',').each do |user_id|
      if User.exists?(user_id)
        album.users.push User.find(user_id)
      end
    end
    unless raw_album[:subjects].nil?
      raw_album[:subjects].split(',').uniq.each do |subject|
        category = Category.find_or_create_by name: subject
        album.categories.push category
      end
    end
    album.categories.push albums_cat
    album.save
  end

  puts "migrating updates into articles"
  $mysql_client.query(updates_sql).each(:symbolize_keys => true) do |raw_update|
    h = {
      title: raw_update[:title],
      subtitle: raw_update[:subtitle],
      body: cleanup_body(raw_update[:post]),
      publish_at: raw_update[:publish_date],
      status: raw_update[:status],
      created_at: raw_update[:updated_at],
      updated_at: raw_update[:updated_at],
      tags: raw_update[:tags].split(',').uniq,
      old_id: 'updates:%s' % raw_update[:id]
    }
    update = Article.new h
    unless raw_update[:preview_image].blank?
      path = File.join($base_dir,'public',raw_update[:preview_image])
      if File.exist?(path)
        update.image = File.open(path)
      end
    end

    if User.exists?(raw_update[:user_id])
      update.users.push User.find(raw_update[:user_id])
    end
    unless raw_update[:subjects].nil?
      raw_update[:subjects].split(',').uniq.each do |subject|
        category = Category.find_or_create_by name: subject
        update.categories.push category
      end
    end
    update.categories.push updates_cat
    update.save
  end
end

def migrate_events
  puts "migrating events"
  ActiveRecord::Base.connection.execute('truncate table events')
  ActiveRecord::Base.connection.execute('truncate table events_users')
  ActiveRecord::Base.connection.execute('truncate table categories_events')

  events_sql = '
    select events.id, events.title, events.subtitle, events.post, events.start_date, events.end_date, events.preview_image,
    events.user_id, events.address, events.status, events.updated_at, GROUP_CONCAT(tags.name) as tags, GROUP_CONCAT(subjects.subject) as subjects
    from events
    inner join taggings on taggings.taggable_id = events.id and taggings.taggable_type = "Event"
    inner join tags on taggings.tag_id = tags.id
    left join posts_subjects on posts_subjects.post_uid = CONCAT("event-",events.id)
    left join subjects on subjects.id = posts_subjects.subject_id
    GROUP BY events.id
    order by events.id desc
    limit 100
  '
  events_cat = Category.find_by_name 'אירוע'

  $mysql_client.query(events_sql).each(:symbolize_keys => true) do |raw_event|
    h = {
      title: raw_event[:title],
      subtitle: raw_event[:subtitle],
      body: cleanup_body(raw_event[:post]),
      starts_at: raw_event[:start_date],
      ends_at: raw_event[:end_date],
      status: raw_event[:status],
      created_at: raw_event[:updated_at],
      updated_at: raw_event[:updated_at],
      tags: raw_event[:tags].split(',').uniq,
      old_id: 'events:%s' % raw_event[:id]
    }
    if raw_event[:end_date].blank?
      h[:ends_at] = raw_event[:start_date]
    end
    event = Event.new h
    unless raw_event[:preview_image].blank?
      path = File.join($base_dir,'public',raw_event[:preview_image])
      if File.exist?(path)
        event.image = File.open(path)
      end
    end

    if User.exists?(raw_event[:user_id])
      event.users.push User.find(raw_event[:user_id])
    end
    unless raw_event[:subjects].nil?
      raw_event[:subjects].split(',').uniq.each do |subject|
        category = Category.find_or_create_by name: subject
        event.categories.push category
      end
    end
    event.categories.push events_cat
    event.save
  end
end

#def migrate_tags
#  puts "migrating tags"
#  ActiveRecord::Base.connection.execute('truncate table tags')
#  ActiveRecord::Base.connection.execute('truncate table taggings')
#  ActiveRecord::Base.connection.execute('insert into tags (select id, name from 106fm_%s.tags)' % Rails.env)
#  ActiveRecord::Base.connection.execute('insert into taggings (select id, tag_id, taggable_id, taggable_type, tagger_id, tagger_type, context, created_at from 106fm_%s.taggings)' % Rails.env)
#  ActiveRecord::Base.connection.execute('update taggings set taggable_type="Tracklist" where taggable_type="Track"')
#end

def migrate_configuration
  puts "migrating configuration"
  ActiveRecord::Base.connection.execute('truncate table configuration')
  Configuration.create name: 'home', data: {headlines: [], today: [], tracklists: []}
  Configuration.create name: 'home_components', data: {headlines: 5, today: 3, tracklists: 3}
  Configuration.create name: 'navigation', data: {categories: []}
  Configuration.create name: 'about', data: {hebrew: nil, english: nil}
end

#migrate_users
#migrate_schedules
#migrate_tracks
migrate_programs
#migrate_configuration
#migrate_categories
#migrate_articles
#migrate_events