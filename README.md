# Little Shop | Final Project | Backend Repo

## Author

Rig Freyr

GitHub Link: https://github.com/ontruster74

## Description

This repository is the completed API for use with the Mod2 Final Project. The FE repo for this project lives [here](https://github.com/ontruster74/little-shop-fe-final-project).

## Setup

```ruby
bundle install
rails db:{drop,create,migrate,seed}
rails db:schema:dump
```

This repo uses a pgdump file to seed the database. Your `db:seed` command will produce lots of output, and that's normal. If all your tests fail after running `db:seed`, you probably forgot to run `rails db:schema:dump`. 

Run your server with `rails s` and you should be able to access endpoints via localhost:3000.
