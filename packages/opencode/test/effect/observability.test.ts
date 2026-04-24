import { afterEach, describe, expect, test } from "bun:test"
import { resource } from "../../src/effect/observability"

const otelResourceAttributes = process.env.OTEL_RESOURCE_ATTRIBUTES
const otelExporterEndpoint = process.env.OTEL_EXPORTER_OTLP_ENDPOINT
const opencodeLocalOnly = process.env.OPENCODE_LOCAL_ONLY
const opencodeClient = process.env.OPENCODE_CLIENT

afterEach(() => {
  if (otelResourceAttributes === undefined) delete process.env.OTEL_RESOURCE_ATTRIBUTES
  else process.env.OTEL_RESOURCE_ATTRIBUTES = otelResourceAttributes

  if (otelExporterEndpoint === undefined) delete process.env.OTEL_EXPORTER_OTLP_ENDPOINT
  else process.env.OTEL_EXPORTER_OTLP_ENDPOINT = otelExporterEndpoint

  if (opencodeLocalOnly === undefined) delete process.env.OPENCODE_LOCAL_ONLY
  else process.env.OPENCODE_LOCAL_ONLY = opencodeLocalOnly

  if (opencodeClient === undefined) delete process.env.OPENCODE_CLIENT
  else process.env.OPENCODE_CLIENT = opencodeClient
})

describe("resource", () => {
  test("parses and decodes OTEL resource attributes", () => {
    process.env.OTEL_RESOURCE_ATTRIBUTES =
      "service.namespace=anomalyco,team=platform%2Cobservability,label=hello%3Dworld,key%2Fname=value%20here"

    expect(resource().attributes).toMatchObject({
      "service.namespace": "anomalyco",
      team: "platform,observability",
      label: "hello=world",
      "key/name": "value here",
    })
  })

  test("drops OTEL resource attributes when any entry is invalid", () => {
    process.env.OTEL_RESOURCE_ATTRIBUTES = "service.namespace=anomalyco,broken"

    expect(resource().attributes["service.namespace"]).toBeUndefined()
    expect(resource().attributes["opencode.client"]).toBeDefined()
  })

  test("keeps built-in attributes when env values conflict", () => {
    process.env.OPENCODE_CLIENT = "cli"
    process.env.OTEL_RESOURCE_ATTRIBUTES =
      "opencode.client=web,service.instance.id=override,service.namespace=anomalyco"

    expect(resource().attributes).toMatchObject({
      "opencode.client": "cli",
      "service.namespace": "anomalyco",
    })
    expect(resource().attributes["service.instance.id"]).not.toBe("override")
  })

  test("disables OTLP export in local-only mode", async () => {
    process.env.OPENCODE_LOCAL_ONLY = "1"
    process.env.OTEL_EXPORTER_OTLP_ENDPOINT = "https://otel.example"

    const { Observability } = await import(`../../src/effect/observability.ts?local-only=${Date.now()}`)
    expect(Observability.enabled).toBe(false)
  })
})
