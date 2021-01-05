require "kemal"

require "./db/*"
require "./helpers"

get "/api/v1/clusters" do |env|
  # Show only Cluster for which the user is part of
  MoanaDB.list_clusters(env.get("user_id").as(String)).to_json
end

get "/api/v1/clusters/:cluster_id" do |env|
  if !cluster_viewer?(env)
    halt(env, status_code: 403, response: forbidden_response)
  end

  cluster = MoanaDB.get_cluster(env.params.url["cluster_id"])

  if cluster.nil?
    env.response.status_code = 400
    {"error": "Invalid Cluster ID"}.to_json
  else
    cluster.to_json
  end
end

post "/api/v1/clusters" do |env|
  name = env.params.json["name"].as(String)

  env.response.status_code = 201
  MoanaDB.create_cluster(env.get("user_id").as(String), name).to_json
end

put "/api/v1/clusters/:cluster_id" do |env|
  if !cluster_maintainer?(env)
    halt(env, status_code: 403, response: forbidden_response)
  end

  name = env.params.json["name"].as(String)
  MoanaDB.update_cluster(env.params.url["cluster_id"], name).to_json
end

delete "/api/v1/clusters/:cluster_id" do |env|
  if !cluster_admin?(env)
    halt(env, status_code: 403, response: forbidden_response)
  end

  MoanaDB.delete_cluster(env.params.url["cluster_id"])

  env.response.status_code = 204
  nil
end
