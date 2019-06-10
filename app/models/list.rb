class List
 # ==================================================
 #                      SET UP
 # ==================================================
 # add attribute readers for instance accesss
  attr_reader :id, :list, :completed


    if(ENV['https://buckidea-api.herokuapp.com/'])
        uri = URI.parse(ENV['https://buckidea-api.herokuapp.com/'])
        DB = PG.connect(uri.hostname, uri.port, nil, nil, uri.path[1..-1], uri.user, uri.password)
    else
        DB = PG.connect({:host => "localhost", :port => 5432, :dbname => 'plan_it_app_api_development'})
    end

    #initialize options Hash
    def initialize(opts = {}, id = nil)
      @id = id.to_i
      @title = opts["title"]
      @iscomplete = opts["iscomplete"]
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
      INSERT INTO lists (title, iscomplete)
      VALUES ( $1, $2 )
      RETURNING id, title, iscomplete;
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
      SET title = $2, iscomplete = $3
      WHERE id = $1
      RETURNING id, title, iscomplete;
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
      if result["iscomplete"] === 'f'
        result["iscomplete"] = false
      else
        result["iscomplete"] = true
      end
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
    if result["iscomplete"] === 'f'
      result["iscomplete"] = false
    else
      result["iscomplete"] = true
    end
    p result
    # create and return the task
    list = List.new(result, result["id"])
  end

  # create one
  def self.create(opts)
    # if opts["completed"] does not exist, default it to false
    if opts["iscomplete"] === nil
      opts["iscomplete"] = false
    end
    # create the task
    results = DB.exec_prepared("create_list", [opts["title"], opts["iscomplete"]])
    # turn completed value into boolean
    if results.first["iscomplete"] === 'f'
      iscomplete = false
    else
      iscomplete = true
    end
    # return the task
    list = List.new(
      {
        "title" => results.first["title"],
        "iscomplete" => iscomplete
      },
      results.first["id"]
    )
  end

  # delete one
  def self.delete(id)
    # delete one
    results = DB.exec_prepared("delete_list", [id])
    # if results.first exists, it successfully deleted
    if results.first
      return { deleted: true }
    else # otherwise it didn't, so leave a message that the delete was not successful
      return { message: "sorry cannot find person at id: #{id}", status: 400}
    end
  end

  # update one
  def self.update(id, opts)
    # update the list
    results = DB.exec_prepared("update_list", [id, opts["title"], opts["iscomplete"]])
    # if results.first exists, it was successfully updated so return the updated list
    if results.first
      if results.first["iscomplete"] === 'f'
        iscomplete = false
      else
        iscomplete = true
      end
      # return the task
      list = List.new(
        {
          "title" => results.first["title"],
          "iscomplete" => iscomplete
        },
        results.first["id"]
      )
    else # otherwise, alert that update failed
      return { message: "sorry, cannot find list at id: #{id}", status: 400 }
    end
  end

end
