class List
 # ==================================================
 #                      SET UP
 # ==================================================
 # add attribute readers for instance accesss
  attr_reader :id, :title, :image, :description, :done, :likes
  # CREATE TABLE lists (id SERIAL, title VARCHAR(50), description VARCHAR(255), done INT, likes INT);

    if(ENV['DATABASE_URL'])
        uri = URI.parse(ENV['DATABASE_URL'])
        DB = PG.connect(uri.hostname, uri.port, nil, nil, uri.path[1..-1], uri.user, uri.password)
    else
        DB = PG.connect({:host => "localhost", :port => 5432, :dbname => 'bucket-lister-api'})
    end
# change db name back to bucket-lister-api
    #initialize options Hash
    def initialize(opts = {}, id = nil)
      @id = id.to_i
      @title = opts["title"]
      @image = opts["image"]
      @description = opts["description"]
      @done = opts["done"].to_i
      @likes = opts["likes"].to_i
    end


  # ==================================================
  #                 PREPARED STATEMENTS
  # ==================================================
  # find list
  DB.prepare("find_list",
    <<-SQL
      SELECT lists.*
      FROM lists
      WHERE lists.id = $1;
    SQL
  )

  # create task
  DB.prepare("create_list",
    <<-SQL
      INSERT INTO lists (title, description, image, likes)
      VALUES ( $1, $2, $3, $4 )
      RETURNING id, title, description, image, likes, done;
    SQL
  )

  # delete task
  DB.prepare("delete_list",
    <<-SQL
      DELETE FROM lists
      WHERE id=$1
      RETURNING id;
    SQL
  )

  # update task
  DB.prepare("update_list",
    <<-SQL
      UPDATE lists
      SET title = $2, description = $3, image = $4, likes = $5
      WHERE id = $1
      RETURNING id, title, description, image, likes;
    SQL
  )

  # ==================================================
  #                      ROUTES
  # ==================================================
  # get all lists
  def self.all
    results = DB.exec("SELECT * FROM lists;")
    return results.map do |result|
      # turn completed value into boolean

      # create and return the lists
      list = List.new(result, result["id"])
    end
  end

  # get one task by id
  def self.find(id)
    # find the result
    result = DB.exec_prepared("find_list", [id]).first
    p result
    p '---'
    # turn completed value into boolean

    p result
    # create and return the task
    list = List.new(result, result["id"])
  end

  # create one
  def self.create(opts)
    # if opts["completed"] does not exist, default it to false
  # p opts
  # p '==================================='
    # create the task
    results = DB.exec_prepared("create_list", [opts["title"], opts["description"], opts["image"], opts["likes"]])
    # turn completed value into boolean

    # return the task
    list = List.new(
      {
        "title" => results.first["title"],
        "description" => results.first["description"],
        "image" => results.first["image"]
      },
      results.first["id"]
    )
  end

  # delete one
  def self.delete(id)
    # delete one
    results = DB.exec_prepared("delete_list", [id])
    # if results.first exists, it successfully deleted
    results.first
    return { deleted: true }

  end

  # update one
  def self.update(id, opts)
    # update the list
    results = DB.exec_prepared("update_list", [id, opts["title"], opts["description"], opts["image"], opts["likes"]])
    # if results.first exists, it was successfully updated so return the updated list

      # return the task
      list = List.new(
        {
          "title" => results.first["title"],
          "description" => results.first["description"],
          "image" => results.first["image"],
          "likes" => results.first["likes"]
        },
        results.first["id"]
      )

      return list
    end
  end
