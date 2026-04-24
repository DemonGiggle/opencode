import { afterAll, afterEach, describe, expect, test } from "bun:test"
import fs from "fs/promises"
import path from "path"
import { pathToFileURL } from "url"
import { Effect } from "effect"
import { tmpdir } from "../fixture/fixture"

const localOnly = process.env.OPENCODE_LOCAL_ONLY
process.env.OPENCODE_LOCAL_ONLY = "1"

const { Plugin } = await import("../../src/plugin/index")
const { Instance } = await import("../../src/project/instance")

afterEach(async () => {
  await Instance.disposeAll()
})

afterAll(() => {
  if (localOnly === undefined) {
    delete process.env.OPENCODE_LOCAL_ONLY
    return
  }
  process.env.OPENCODE_LOCAL_ONLY = localOnly
})

async function project() {
  return tmpdir({
    init: async (dir) => {
      const file = path.join(dir, "plugin.ts")
      const marker = path.join(dir, "called.txt")
      await Bun.write(
        file,
        [
          "export default async () => ({",
          '  "experimental.chat.system.transform": async (_input, output) => {',
          `    await Bun.write(${JSON.stringify(marker)}, "called")`,
          '    output.system.unshift("plugin")',
          "  },",
          "})",
          "",
        ].join("\n"),
      )
      await Bun.write(
        path.join(dir, "opencode.json"),
        JSON.stringify({
          $schema: "https://opencode.ai/config.json",
          plugin: [pathToFileURL(file).href],
        }),
      )
      return { marker }
    },
  })
}

describe("plugin.local-only", () => {
  test("skips server plugins in local-only mode", async () => {
    await using tmp = await project()

    const count = await Instance.provide({
      directory: tmp.path,
      fn: async () =>
        Effect.gen(function* () {
          const plugin = yield* Plugin.Service
          yield* plugin.init()
          return (yield* plugin.list()).length
        }).pipe(Effect.provide(Plugin.defaultLayer), Effect.runPromise),
    })

    expect(count).toBe(0)
    await expect(fs.readFile(tmp.extra.marker, "utf8")).rejects.toThrow()
  })
})
