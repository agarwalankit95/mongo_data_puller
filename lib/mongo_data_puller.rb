class MongoDataPuller

  THRESHOLD_TIME_LIMIT = 10.days

  def initialize options
    options = options.deep_symbolize_keys!
    @target = options[:target] # collection in which data is to be stored in mongo
    @source = options[:source] # mysql table from which we need to pull data
    @query = options[:query]   # query for which data is to be pulled
    @default_from_date = options[:default_from_date] # default from date, in case date not present
    @from_date_fields = options[:from_date_fields] # hash which consist of is represent tables as key and value as fields
  end

  def pull
    objects = @query

    # Last updated for multiple fields
    last_updated = []
    @from_date_fields.each do |k,v|
      max_date = @target.collection.aggregate([{:$group => {:_id => '', maxDate: {:$max => "$#{k}_#{v}"}}}])
      last_updated << max_date.first["maxDate"] unless max_date.blank?
    end

    # Finding out last updated date
    last_updated = last_updated.compact
    if last_updated.blank?
      last_updated = @default_from_date
    else
      threshold_date = Time.now - THRESHOLD_TIME_LIMIT
      last_updated = last_updated.min
      last_updated = threshold_date if threshold_date > last_updated
    end

    # Making queries for last updated date
    last_updated = last_updated.strftime("%Y-%m-%d %H:%M:%S")
    last_updated_query = @from_date_fields.collect{|k,v| "`#{k}`.`#{v}` >= '#{last_updated}'"}.join(" OR ")
    update_select_query = @from_date_fields.collect{|k,v| "`#{k}`.`#{v}` #{k}_#{v}"}.join(",")

    all_objects = objects.where(last_updated_query).select(update_select_query)

    total_count = all_objects.count
    # Incase total_count is a hash (is possible incase of group by)
    total_count = total_count.count if total_count.is_a?(Hash)
    count = 0
    limit = 10000
    while count <= total_count
      inner_count = count
      @source.connection.reconnect!

      objects = all_objects.offset(count).limit(limit)
      objects.each do |object|
        create_object_replica object
        inner_count = inner_count + 1
        print "\r#{inner_count} of #{total_count} #{@source.table_name} completed (#{(inner_count * 100)/total_count}%)"
      end

      count = count + limit
    end
    puts "\n"
  end


  def flush
    @target.collection.drop()
  end

  def create_object_replica object
    primary_key = @source.primary_key
    attributes = self::class.filter_attributes(object.attributes.merge!({'_id' => object.send(primary_key)}))

    # Merge old attributes
    old_attributes = @target.find(attributes['_id'])
    attributes.reverse_merge!(old_attributes.attributes) unless old_attributes.blank?

    @target.collection.update({'_id' => attributes['_id']}, attributes ,{:upsert => true})
  end


  def self.filter_attributes attributes
    new_attributes = {}
    attributes.each do |k,v|
      if v.is_a?(BigDecimal)
        new_attributes[k] = v.to_f
      elsif v.is_a?(Time)
        new_attributes[k] = v.utc
      else
        new_attributes[k] = v
      end
    end
    return new_attributes
  end

end