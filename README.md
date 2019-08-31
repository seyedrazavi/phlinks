# phlinks

[phlinks.herokuapp.com](https://phlinks.herokuapp.com/)

## Install

### Clone the repository

```shell
git clone git@github.com:seyedrazavi/phlinks.git
cd project
```

### Check your Ruby version

```shell
ruby -v
```

The ouput should start with something like `ruby 2.6.3`

If not, install the right ruby version using [rbenv](https://github.com/rbenv/rbenv) (it could take a while):

```shell
rbenv install 2.6.3
```

### Install dependencies

Using [Bundler](https://github.com/bundler/bundler) and [Yarn](https://github.com/yarnpkg/yarn):

```shell
bundle && yarn
```

### Set environment variables

Using [Figaro](https://github.com/laserlemon/figaro):

See [config/application.yml.sample](https://github.com/seyedrazavi/phlinks/master/config/application.yml.sample) and contact the developer: [me@srazavi.com](mailto:me@srazavi.com) (sensitive data).

### Initialize the database

```shell
rails db:create db:migrate
rails fetch
```

### Add heroku remotes

Using [Heroku CLI](https://devcenter.heroku.com/articles/heroku-cli):

```shell
heroku git:remote -a phlinks
heroku git:remote --remote heroku-staging -a phlinks-staging
```

## Serve

```shell
rails s
```

## Deploy

### With Heroku pipeline (recommended)

Push to Heroku staging remote:

```shell
git push heroku-staging
```

Go to the Heroku Dashboard and [promote the app to production](https://devcenter.heroku.com/articles/pipelines) or use Heroku CLI:

```shell
heroku pipelines:promote -a phlinks-staging
```

### Directly to production (not recommended)

Push to Heroku production remote:

```shell
git push heroku
```
