import searxngPlugin from "./searxng.mjs";
import yttPlugin from "./ytt.mjs";

export default async function indexPlugin(input) {
  const [searxng, ytt] = await Promise.all([
    searxngPlugin(input),
    yttPlugin(input),
  ]);

  return {
    tool: {
      ...(searxng?.tool ?? {}),
      ...(ytt?.tool ?? {}),
    },
  };
}
