class List
  # ==================================================
  #                      SET UP
  # ==================================================
  # add attribute readers for instance accesss
  attr_reader :id, :list, :completed

  # connect to postgres
  DB = PG.connect({:host => "localhost", :port => 5432, :dbname => 'list_development'})

  #need to update list_development to correct name once started in psql

  # initialize options hash
  def initialize(opts = {}, id = nil)
    @id = id.to_i
    @list_item = opts["list_item"]
    @completed = opts["completed"]
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
      INSERT INTO tasks (list_item, completed)
      VALUES ( $1, $2 )
      RETURNING id, list_item, completed;
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
      SET list_item = $2, completed = $3
      WHERE id = $1
      RETURNING id, list_item, completed;
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
      if result["completed"] === 'f'
        result["completed"] = false
      else
        result["completed"] = true
      end
      # create and return the lists
      task = List.new(result, result["id"])
    end
  end

  # get one task by id
  def self.find(id)
    # find the result
    result = DB.exec_prepared("find_list", [id]).first
    p result
    p '---'
    # turn completed value into boolean
    if result["completed"] === 'f'
      result["completed"] = false
    else
      result["completed"] = true
    end
    p result
    # create and return the task
    task = List.new(result, result["id"])
  end

  # create one
  def self.create(opts)
    # if opts["completed"] does not exist, default it to false
    if opts["completed"] === nil
      opts["completed"] = false
    end
    # create the task
    results = DB.exec_prepared("create_list", [opts["list_item"], opts["completed"]])
    # turn completed value into boolean
    if results.first["completed"] === 'f'
      completed = false
    else
      completed = true
    end
    # return the task
    task = List.new(
      {
        "list_item" => results.first["list_item"],
        "completed" => completed
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
    results = DB.exec_prepared("update_list", [id, opts["list_item"], opts["completed"]])
    # if results.first exists, it was successfully updated so return the updated list
    if results.first
      if results.first["completed"] === 'f'
        completed = false
      else
        completed = true
      end
      # return the task
      task = List.new(
        {
          "list_item" => results.first["list_item"],
          "completed" => completed
        },
        results.first["id"]
      )
    else # otherwise, alert that update failed
      return { message: "sorry, cannot find list at id: #{id}", status: 400 }
    end
  end

end
