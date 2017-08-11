# GammaRay

Sends events to DynamoDB from ActiveRecord (more sources coming soon).

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'gamma_ray', :git => 'git@github.com:transfixio/gamma_ray.git'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install gamma_ray

### Setup

Set your DynamoDB table name in an initializer.

`config/initializers/gamma_ray.rb`

```ruby
GammaRay::ActiveRecord.stream_name = 'XXX'
GammaRay::ActiveRecord.bucket_name = 'XXX'
```

## Usage

Track an event by calling:

```ruby
GammaRay::ActiveRecord.client.track('event_name', properties={})
```

Automatically track create/update/destroy actions on your models by
adding `has_autolog` to your models.

You can choose to filter out specific attributes using the :ignore
option, or keep only specific attributes using the :only attribute.

**Note: attributes that are rails filtered params are filtered automatically.**

Example: Filter our Devise tokens.

```ruby
class User << ActiveRecord::Base
  has_autolog :ignore => [:encrypted_password, :reset_password_token, :confirmation_token, :unlock_token]
end
```


Example: Track only the name and email address.
```ruby
class User < ActiveRecord::Base
  has_autolog :only => [:name, :email]
end
```
### Deploys
Make sure jq is installed:

    $ brew install jq


To deploy to development alias:

    $ ./deploy.sh <function>


To promote:

    $ ./promote <function> <source> <destination>


## Run Locally
By default GammaRay is turned off in development and test environments. To turn it on in the console just run:
```ruby
GammaRay::ActiveRecord.turn_off = false
```
