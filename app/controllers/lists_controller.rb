class ListsController < ApplicationController
  # index route
  def index
    render json: List.all
  end

  #show route
  def show
    render json: List.find(params["id"])
  end

  # create route
  def create
    render json: List.create(params["list"])
  end

  # delete route
  def delete
    render json: List.delete(params["id"])
  end

  # update route
  def update
    render json: List.update(params["id"], params["list"])
  end
end
