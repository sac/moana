require "./helpers"
require "../conf"
require "../datastore/*"

get "/api/v1/nodes" do |env|
  state = env.params.query["state"]

  nodes = Datastore.list_nodes_by_user(env.user_id)

  next nodes.to_json unless state

  resp = dispatch_action(
    ACTION_PING,
    "",
    nodes
  )

  nodes.each do |node|
    node.state = resp.node_responses[node.id].ok ? "Up" : "Down"
  end

  nodes.to_json
end

get "/api/v1/pools/:pool_name/nodes" do |env|
  pool_name = env.params.url["pool_name"]
  state = env.params.query["state"]

  next forbidden(env) unless Datastore.viewer?(env.user_id, pool_name)

  nodes = Datastore.list_nodes(pool_name)

  next nodes.to_json unless state

  resp = dispatch_action(
    ACTION_PING,
    pool_name,
    nodes
  )

  nodes.each do |node|
    node.state = resp.node_responses[node.id].ok ? "Up" : "Down"
  end

  nodes.to_json
end

get "/api/v1/pools/:pool_name/nodes/:node_name/services" do |env|
  pool_name = env.params.url["pool_name"]
  node_name = env.params.url["node_name"]

  next forbidden(env) if env.get?("node_id").nil?

  node = Datastore.get_node(pool_name, node_name)

  if node.nil?
    halt(env, status_code: 400, response: ({"error": "Node does not exist."}.to_json))
  end

  Datastore.list_services(node.pool.id, node.id).to_json
end
