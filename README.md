# ライブラリー紹介：ActionCable

## ActionCableとは
Rails5の新しいWebsockets機能。使うと色々リアルタイムできるようになります。このチュートリアルで簡単なチャットアプリを作る手順を紹介します。

## Gemfile
```Ruby
source 'https://rubygems.org'

gem 'rails', '4.2.3'
gem 'actioncable', github: 'rails/actioncable'

gem 'sqlite3'
gem 'coffee-rails', '~> 4.1.0'
gem 'jquery-rails'
gem 'turbolinks'
gem 'puma'
gem 'uglifier', '>= 1.3.0'

group :development, :test do
  gem 'byebug'
  gem 'spring'
  gem 'web-console', '~> 2.0'
end
```

## メッセージController

`Messages#create`メソッドがWebsocketにメッセージを送るけど、とりあえず`head :ok`だけ返します（まだActionCableを設定していないので）

```Ruby
class MessagesController < ApplicationController
  def create
    head :ok
  end
end
```


## メッセージのindexページ

`app/views/messages/index.html.slim`

```Slim
h1 ActionCableチャット
p

#messages
  br
  br
= form_for :message, url: messages_path, remote: true, id: 'messages-form' do |f|
  = f.label :body, 'メッセージを入力してください：'
  br
  = f.text_field :body, class: "form-control message-body"
  br
  = f.submit '送信', class: "form-control"
```

`remote: true`を指定したらformがajaxでリクエストを送ります。新しいメッセージが
`#messages`のところに追加されます。

## ActionCableの設定
まだAlphaなのでgeneratorがないですが、必要なクラスは以下の２つ：
`ApplicationCable::Connection`

```Ruby
# app/channels/application_cable/connection.rb
module ApplicationCable
  class Connection < ActionCable::Connection::Base
  end
end
```

`ApplicationCable::Channel`

```Ruby
# app/channels/application_cable/channel.rb
module ApplicationCable
  class Channel < ActionCable::Channel::Base
  end
end
```

WebSocketのメッセージがJSONで保存されるのでRedisも必要です：

```Ruby
# config/redis/cable.yml
local: &local
  :url: redis://localhost:6379
  :host: localhost
  :port: 6379
  :timeout: 1
  :inline: true
development: *local
test: *local
```

ActionCableはRailsと別のサーバーで動くのでrackup fileも必要です：

```Ruby
# cable/config.ru
require ::File.expand_path('../../config/environment',  __FILE__)
Rails.application.eager_load!

require 'action_cable/process/logging'

run ActionCable.server
```

このサーバーはPumaで`bin/cable`で28080ポートで実行します。

```Ruby
# /bin/bash
bundle exec puma -p 28080 cable/config.ru
```

## メッセージChannel
```Ruby
# app/channels/messages_channel.rb
class MessagesChannel < ApplicationCable::Channel
  def subscribed
    stream_from 'messages'
  end
end
```
あるユーザが`MessagesChannel`にサブスクライブするタイミングで`#subscribed`メソッドが実行されます。

## メッセージstreamにメッセージを流す

```Ruby
class MessagesController < ApplicationController
  def create
    ActionCable.server.broadcast 'messages',
      message: params[:message][:body],
      username: cookies.signed[:username]

    head :ok
  end
end
```

## Client Sideからメッセージにサブスクライブ

`app/assets/javascripts/channels/index.coffee`:

```Ruby
#= require cable
#= require_self
#= require_tree .

@App = {}
App.cable = Cable.createConsumer 'ws://127.0.0.1:28080'
```

`app/assets/javascripts/channels/messages.coffee`：

```Coffeescript
App.messages = App.cable.subscriptions.create 'MessagesChannel',
  received: (data) ->
    $('#messages').append @renderMessage(data)

  renderMessage: (data) ->
    "<p><b>[#{data.username}]:</b> #{data.message}</p>"
```
clientがwebsocketからデータを受けるときに`App.messages.received`が実行されます。

最後に、`app/assets/javascripts/channels`で`channels`を`require`する必要があります。

```Ruby
//= require channels
```

## サーバーを起動
* `sh bin/cable`
* `bundle exec rails server`

## 参考
* [テストアプリ](
* [Getting started with Rails 5's ActionCable and websockets](http://nithinbekal.com/posts/rails-action-cable/)
* [github.com/rails/actioncable](https://github.com/rails/actioncable)
* [GoRails: ActionCable and Websockets Introduction](https://gorails.com/episodes/rails-5-actioncable-websockets)
