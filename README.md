mongo_data_puller
=================

###Introduction
Had a problem in replicating/sinking your data from mysql or postgres to Mongo? 
Mongo data puller does exactly same. It keeps your data from sql based databases to the mongo database.
Our aim is to just make sinking much easier, get rid of unrequired crons writing them again and again, and making our codebase dirtier.


###Install
For installing just put in your gemfile
```
gem 'mongo_data_puller', :git => 'https://github.com/paritosh90/mongo_data_puller.git', :branch => 'master'
```

###How to start

####Create the activerecord from which  to pull
Here we take case of sinking users from mysql to mongo
```
class User < ActiveRecord::Base

end
```
Similarly we have a class for Mongo
```
class MUser
include MongoMapper::Document
end
```

Then for sinking we just need to give (we are sinking only active registred users)
```
puller = MongoDataPuller.new(:target => MUser, :source => User, :default_from_date => (Time.now - 4.months),
                                    :from_date_fields => {:users => 'UpdationDate'},
                                    :query => User.where(:active => 1))
```                                    
where 
*target*: Tells which collection to target
*source*: Primary source table
*default_from_date*: From which date should be taken in consideration, like in above last 4 months data will be pulled and sinked if dataset is empty in mongo.
*query*: Query in activerecord format

For pulling data
```
 puller.pull
```

For flushing db (flushing will delete whole collection and restart sinking)
```
  puller.flush
```


