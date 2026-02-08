// SPDX-License-Identifier: PMPL-1.0-or-later
// Basic example of FlatRacoon SDK usage

@@warning("-27") // Suppress unused variable warnings for example

open FlatRacoonClient

let main = async () => {
  Console.log("FlatRacoon SDK Example")
  Console.log("=====================\n")

  // Create client
  let client = make(~baseUrl="http://localhost:4000")
  Console.log("Connected to orchestrator at http://localhost:4000\n")

  // Get all modules
  Console.log("Fetching modules...")
  switch await getModules(client) {
  | Ok(modules) => {
      Console.log(`✓ Found ${modules->Array.length->Int.toString} modules`)
      modules->Array.forEach(m => {
        Console.log(`  - ${m.name} (${m.version}) [${m.layer}]`)
      })
    }
  | Error(e) => Console.error(`✗ Error fetching modules: ${e}`)
  }

  Console.log("")

  // Get health status
  Console.log("Checking health...")
  switch await getHealth(client) {
  | Ok(health) => {
      Console.log(
        `✓ Health: ${health.healthyCount->Int.toString} healthy, ${health.unhealthyCount->Int.toString} unhealthy`,
      )
      if health.allHealthy {
        Console.log("  🟢 All systems operational")
      } else {
        Console.log("  🟡 Some systems require attention")
      }
    }
  | Error(e) => Console.error(`✗ Error checking health: ${e}`)
  }

  Console.log("")

  // Get deployment order
  Console.log("Fetching deployment order...")
  switch await getDeploymentOrder(client) {
  | Ok(order) => {
      Console.log(`✓ Deployment order (${order->Array.length->Int.toString} modules):`)
      order->Array.forEachWithIndex((name, i) => {
        Console.log(`  ${(i + 1)->Int.toString}. ${name}`)
      })
    }
  | Error(e) => Console.error(`✗ Error fetching order: ${e}`)
  }

  Console.log("\nExample complete!")
}

// Run main
await main()
