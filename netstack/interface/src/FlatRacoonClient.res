// SPDX-License-Identifier: PMPL-1.0-or-later
// FlatRacoon SDK - Client for orchestrator API

type moduleStatus = Running | Stopped | Pending | Error

type moduleInfo = {
  name: string,
  status: moduleStatus,
  completion: int,
  layer: string,
  version: string,
}

type healthSummary = {
  allHealthy: bool,
  healthyCount: int,
  unhealthyCount: int,
  unknownCount: int,
}

type deploymentResponse = {
  status: string,
  message: option<string>,
  moduleName: option<string>,
}

type logsResponse = {
  moduleName: string,
  logs: string,
}

type client = {baseUrl: string}

// Create a new client
let make = (~baseUrl="http://localhost:4000") => {baseUrl: baseUrl}

// Helper to parse module status
let parseStatus = (str: string): moduleStatus =>
  switch str {
  | "healthy" => Running
  | "deploying" => Pending
  | "not_deployed" => Stopped
  | "degraded" => Pending
  | "failed" => Error
  | _ => Error
  }

// Fetch API bindings
module Fetch = {
  type response
  type requestInit

  @val external fetch: string => promise<response> = "fetch"
  @val external fetchWithInit: (string, requestInit) => promise<response> = "fetch"

  @get external ok: response => bool = "ok"
  @get external status: response => int = "status"
  @get external statusText: response => string = "statusText"
  @send external json: response => promise<Js.Json.t> = "json"

  @obj
  external makeInit: (
    ~method: string=?,
    ~headers: Js.Dict.t<string>=?,
    ~body: string=?,
    unit,
  ) => requestInit = ""
}

// JSON decoder helpers using built-in Js.Json
module Decode = {
  let getString = (dict: Js.Dict.t<Js.Json.t>, key: string): option<string> => {
    switch Js.Dict.get(dict, key) {
    | None => None
    | Some(json) => Js.Json.decodeString(json)
    }
  }

  let getInt = (dict: Js.Dict.t<Js.Json.t>, key: string): option<int> => {
    switch Js.Dict.get(dict, key) {
    | None => None
    | Some(json) =>
      switch Js.Json.decodeNumber(json) {
      | None => None
      | Some(num) => Some(int_of_float(num))
      }
    }
  }

  let getBool = (dict: Js.Dict.t<Js.Json.t>, key: string): option<bool> => {
    switch Js.Dict.get(dict, key) {
    | None => None
    | Some(json) => Js.Json.decodeBoolean(json)
    }
  }

  let getObject = (dict: Js.Dict.t<Js.Json.t>, key: string): option<Js.Dict.t<Js.Json.t>> => {
    switch Js.Dict.get(dict, key) {
    | None => None
    | Some(json) => Js.Json.decodeObject(json)
    }
  }

  let getArray = (dict: Js.Dict.t<Js.Json.t>, key: string): option<array<Js.Json.t>> => {
    switch Js.Dict.get(dict, key) {
    | None => None
    | Some(json) => Js.Json.decodeArray(json)
    }
  }

  // Decode module info from module_state
  let moduleInfo = (json: Js.Json.t): result<moduleInfo, string> => {
    switch Js.Json.decodeObject(json) {
    | None => Error("Expected object for module")
    | Some(dict) =>
      switch (getObject(dict, "manifest"), getString(dict, "status")) {
      | (Some(manifest), Some(statusStr)) =>
        switch (
          getString(manifest, "name"),
          getString(manifest, "version"),
          getString(manifest, "layer"),
        ) {
        | (Some(name), Some(version), Some(layer)) =>
          Ok({
            name: name,
            status: parseStatus(statusStr),
            completion: 100,
            layer: layer,
            version: version,
          })
        | _ => Error("Missing required manifest fields")
        }
      | _ => Error("Missing required fields in module")
      }
    }
  }

  // Decode array of modules
  let moduleArray = (json: Js.Json.t): result<array<moduleInfo>, string> => {
    switch Js.Json.decodeObject(json) {
    | None => Error("Expected object with modules field")
    | Some(dict) =>
      switch getArray(dict, "modules") {
      | None => Error("Missing modules array")
      | Some(modulesJson) =>
        let decoded = Array.map(moduleInfo, modulesJson)

        // Find first error or collect all successes using fold
        let initialResult: result<array<moduleInfo>, string> = Ok([])
        Array.fold_left(
          (acc: result<array<moduleInfo>, string>, result) =>
            switch (acc, result) {
            | (Error(_), _) => acc // Already have error, keep it
            | (Ok(arr), Ok(m)) => Ok(Array.append(arr, [m]))
            | (Ok(_), Error(msg)) => Error(msg)
            },
          initialResult,
          decoded,
        )
      }
    }
  }

  // Decode health summary
  let healthSummary = (json: Js.Json.t): result<healthSummary, string> => {
    switch Js.Json.decodeObject(json) {
    | None => Error("Expected object with health field")
    | Some(dict) =>
      switch getObject(dict, "health") {
      | None => Error("Missing health object")
      | Some(health) =>
        switch (
          getBool(health, "allHealthy"),
          getInt(health, "healthyCount"),
          getInt(health, "unhealthyCount"),
          getInt(health, "unknownCount"),
        ) {
        | (Some(allHealthy), Some(healthyCount), Some(unhealthyCount), Some(unknownCount)) =>
          Ok({
            allHealthy: allHealthy,
            healthyCount: healthyCount,
            unhealthyCount: unhealthyCount,
            unknownCount: unknownCount,
          })
        | _ => Error("Missing required health fields")
        }
      }
    }
  }

  // Decode deployment order
  let deploymentOrder = (json: Js.Json.t): result<array<string>, string> => {
    switch Js.Json.decodeObject(json) {
    | None => Error("Expected object with order field")
    | Some(dict) =>
      switch getArray(dict, "order") {
      | None => Error("Missing order array")
      | Some(orderJson) =>
        let decoded = Array.fold_left(
          (acc, item) =>
            switch Js.Json.decodeString(item) {
            | Some(str) => Array.append(acc, [str])
            | None => acc
            },
          [],
          orderJson,
        )
        Ok(decoded)
      }
    }
  }

  // Decode logs response
  let logsResponse = (json: Js.Json.t): result<logsResponse, string> => {
    switch Js.Json.decodeObject(json) {
    | None => Error("Expected object for logs response")
    | Some(dict) =>
      switch (getString(dict, "module"), getString(dict, "logs")) {
      | (Some(moduleName), Some(logs)) => Ok({moduleName: moduleName, logs: logs})
      | _ => Error("Missing required logs fields")
      }
    }
  }
}

// Fetch wrapper with error handling
let fetchJson = async (url: string): result<Js.Json.t, string> => {
  try {
    let response = await Fetch.fetch(url)
    if Fetch.ok(response) {
      let json = await Fetch.json(response)
      Ok(json)
    } else {
      Error(`HTTP ${Fetch.status(response)->(string_of_int)}: ${Fetch.statusText(response)}`)
    }
  } catch {
  | Js.Exn.Error(e) =>
    switch Js.Exn.message(e) {
    | Some(msg) => Error(msg)
    | None => Error("Unknown fetch error")
    }
  }
}

// POST request helper
let postJson = async (url: string, ~body: option<Js.Json.t>=?): result<Js.Json.t, string> => {
  try {
    let headers = Js.Dict.empty()
    Js.Dict.set(headers, "Content-Type", "application/json")

    let init = switch body {
    | None => Fetch.makeInit(~method="POST", ~headers, ())
    | Some(json) => Fetch.makeInit(~method="POST", ~headers, ~body=Js.Json.stringify(json), ())
    }

    let response = await Fetch.fetchWithInit(url, init)
    if Fetch.ok(response) {
      let json = await Fetch.json(response)
      Ok(json)
    } else {
      Error(`HTTP ${Fetch.status(response)->(string_of_int)}: ${Fetch.statusText(response)}`)
    }
  } catch {
  | Js.Exn.Error(e) =>
    switch Js.Exn.message(e) {
    | Some(msg) => Error(msg)
    | None => Error("Unknown POST error")
    }
  }
}

// Get all modules
let getModules = async (client: client): result<array<moduleInfo>, string> => {
  let url = `${client.baseUrl}/api/modules`
  switch await fetchJson(url) {
  | Ok(json) => Decode.moduleArray(json)
  | Error(e) => Error(e)
  }
}

// Get specific module
let getModule = async (client: client, ~name: string): result<moduleInfo, string> => {
  let url = `${client.baseUrl}/api/modules/${name}`
  switch await fetchJson(url) {
  | Ok(json) =>
    switch Js.Json.decodeObject(json) {
    | None => Error("Expected object with module field")
    | Some(dict) =>
      switch Decode.getObject(dict, "module") {
      | None => Error("Missing module field")
      | Some(moduleObj) => Decode.moduleInfo(Js.Json.object_(moduleObj))
      }
    }
  | Error(e) => Error(e)
  }
}

// Get health summary
let getHealth = async (client: client): result<healthSummary, string> => {
  let url = `${client.baseUrl}/api/health`
  switch await fetchJson(url) {
  | Ok(json) => Decode.healthSummary(json)
  | Error(e) => Error(e)
  }
}

// Get deployment order
let getDeploymentOrder = async (client: client): result<array<string>, string> => {
  let url = `${client.baseUrl}/api/deployment_order`
  switch await fetchJson(url) {
  | Ok(json) => Decode.deploymentOrder(json)
  | Error(e) => Error(e)
  }
}

// Deploy all modules
let deployAll = async (client: client): result<deploymentResponse, string> => {
  let url = `${client.baseUrl}/api/deploy`
  switch await postJson(url) {
  | Ok(_json) => {
      Ok({
        status: "deployment_initiated",
        message: Some("All modules deployment started"),
        moduleName: None,
      })
    }
  | Error(e) => Error(e)
  }
}

// Deploy specific module
let deployModule = async (client: client, ~name: string): result<deploymentResponse, string> => {
  let url = `${client.baseUrl}/api/deploy/${name}`
  switch await postJson(url) {
  | Ok(_json) => {
      Ok({status: "deployment_initiated", message: None, moduleName: Some(name)})
    }
  | Error(e) => Error(e)
  }
}

// Restart module
let restartModule = async (client: client, ~name: string): result<deploymentResponse, string> => {
  let url = `${client.baseUrl}/api/restart/${name}`
  switch await postJson(url) {
  | Ok(_json) => {
      Ok({status: "restart_initiated", message: None, moduleName: Some(name)})
    }
  | Error(e) => Error(e)
  }
}

// Stop module
let stopModule = async (client: client, ~name: string): result<deploymentResponse, string> => {
  let url = `${client.baseUrl}/api/stop/${name}`
  switch await postJson(url) {
  | Ok(_json) => {
      Ok({status: "stop_initiated", message: None, moduleName: Some(name)})
    }
  | Error(e) => Error(e)
  }
}

// Get logs for module
let getLogs = async (client: client, ~name: string, ~lines: int=50): result<logsResponse, string> => {
  let url = `${client.baseUrl}/api/logs/${name}?lines=${lines->(string_of_int)}`
  switch await fetchJson(url) {
  | Ok(json) => Decode.logsResponse(json)
  | Error(e) => Error(e)
  }
}
