require 'sinatra'

class PuppyRun < Sinatra::Base
  %w[hitbox bandcamp github howamidoing].each { |job|
    require "puppy_run/jobs/#{job}.rb"
  }

  JOBS = Jobs.constants.map(&Jobs.method(:const_get))

  JOBS.each { |job|
    job.new.spawn_update_loop!
  }

  TITLES = {
    stream: 'Live Streams',
    code: 'Code',
    music: 'Music',
  }

  def generate_kwargs(view, page=nil, title=nil)
    bc = Jobs::Bandcamp

    {
      layout: :default,
      locals: {
        title: title || TITLES[view],
        page: page || view.to_s,
        is_streaming: Jobs::Hitbox.streaming?,
        album_date: bc.album_date,
        album_id: bc.album_id,
        album_slug: bc.album_slug,
        album_name: bc.album_name,
        tag_push_event: Jobs::GitHub.tag_push_event,
        statuses: Jobs::Howamidoing.statuses,
      }
    }
  end

  set :public_folder, File.dirname(__FILE__) + '/static'

  get '/' do
    view = JOBS.reject { |x| x.updated_at.nil? }.sort_by(&:updated_at).last.view
    title = "Latest: #{TITLES[view]}"

    erb view,
      **generate_kwargs(view, 'home', title)
  end

  get '/stream' do
    erb :stream,
      **generate_kwargs(:stream)
  end

  get '/code' do
    erb :code,
      **generate_kwargs(:code)
  end

  get '/music' do
    erb :music,
      **generate_kwargs(:music)
  end
end

