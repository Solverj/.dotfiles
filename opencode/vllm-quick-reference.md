# vLLM Quick Reference - Client-Side Options

**Your Setup:**
- Server: `https://lame.ai.mattilsynet.io/v1` (shared)
- Provider: `@ai-sdk/openai-compatible`
- Model: Qwen3.5 122B FP8
- Config: `~/.config/opencode/opencode.json`

---

## Top 10 Most Used Parameters

| Parameter | Type | Typical Values | Description |
|-----------|------|----------------|-------------|
| `temperature` | number | 0.0-2.0 | Creativity (0=deterministic, 1=balanced, 2=chaotic) |
| `top_p` | number | 0.8-1.0 | Nucleus sampling (0.9 = top 90% probability) |
| `max_completion_tokens` | integer | 256-8192 | Max output tokens |
| `top_k` | number | 40-50 | Top-k sampling (-1 to disable) |
| `stop` | string/array | `["\n\n"]` | Stop sequences |
| `seed` | integer | Any | Reproducibility |
| `repetition_penalty` | number | 1.0-1.2 | Prevent repetition |
| `chat_template_kwargs.enable_thinking` | boolean | true/false | Qwen thinking mode |
| `guided_json` | object | JSON schema | Structured output |
| `priority` | integer | -10 to 10 | Request priority |

---

## Qwen Thinking Control

### Disable Thinking (Fast Responses)
```json
{
  "chat_template_kwargs": {
    "enable_thinking": false
  }
}
```

### Enable Thinking (Deep Reasoning)
```json
{
  "chat_template_kwargs": {
    "enable_thinking": true,
    "enable_thinking_budget": 2048
  }
}
```

---

## Common Configurations

### Fast & Direct
```json
{
  "temperature": 0.7,
  "top_p": 0.9,
  "max_completion_tokens": 1024,
  "chat_template_kwargs": { "enable_thinking": false }
}
```

### Creative
```json
{
  "temperature": 1.2,
  "top_p": 0.95,
  "top_k": 50,
  "repetition_penalty": 1.1
}
```

### Deterministic/Reproducible
```json
{
  "seed": 42,
  "temperature": 0.1,
  "top_p": 0.95,
  "top_k": 40
}
```

### Structured JSON
```json
{
  "guided_json": {
    "type": "object",
    "properties": {
      "field1": {"type": "string"},
      "field2": {"type": "number"}
    },
    "required": ["field1"]
  },
  "temperature": 0.1
}
```

### Code Generation
```json
{
  "temperature": 0.2,
  "top_p": 0.95,
  "top_k": 40,
  "stop": ["\nclass", "\ndef "]
}
```

---

## How to Use in Code

### opencode.json (Model Defaults)
```json
{
  "provider": {
    "dramallama": {
      "npm": "@ai-sdk/openai-compatible",
      "options": {
        "baseURL": "https://lame.ai.mattilsynet.io/v1",
        "chat_template_kwargs": { "enable_thinking": false }
      },
      "models": {
        "drama/code-thinking": {
          "options": {
            "chat_template_kwargs": { "enable_thinking": true }
          }
        }
      }
    }
  }
}
```

### Per-Request Override (TypeScript)
```typescript
const result = await generateText({
  model: vllm('drama/code-thinking'),
  prompt: 'Your prompt',
  providerOptions: {
    dramallama: {
      temperature: 0.7,
      top_k: 40,
      chat_template_kwargs: { enable_thinking: false }
    }
  }
});
```

---

## Parameter Constraints

**Only ONE of these at a time:**
- `guided_json`
- `guided_regex`
- `guided_choice`
- `guided_grammar`

**Cannot combine with tool_choice** (except "none"/"auto"/"required")

**`continue_final_message` and `add_generation_prompt`** cannot both be true

---

## Troubleshooting Quick Fixes

| Problem | Quick Fix |
|---------|-----------|
| Thinking still on | `"chat_template_kwargs": { "enable_thinking": false }` |
| Output too repetitive | `"repetition_penalty": 1.2, "frequency_penalty": 0.5` |
| Output too short | `"max_completion_tokens": 4096` |
| Non-deterministic | `"seed": 42, "temperature": 0.1` |
| JSON not structured | Use `guided_json` instead of `response_format` |
| Model loops | `"top_k": 40, "min_p": 0.05` |

---

## Parameter Ranges

| Parameter | Min | Max | Typical |
|-----------|-----|-----|---------|
| `temperature` | 0.0 | 2.0 | 0.7 |
| `top_p` | 0.0 | 1.0 | 0.9 |
| `top_k` | -1 | 100+ | 40 |
| `min_p` | 0.0 | 1.0 | 0.05 |
| `repetition_penalty` | 0.0 | 2.0 | 1.0-1.2 |
| `presence_penalty` | -2.0 | 2.0 | 0.0 |
| `frequency_penalty` | -2.0 | 2.0 | 0.0 |
| `max_completion_tokens` | 1 | 100000+ | 1024-4096 |

---

## Quick Test Commands

```bash
# Test basic connectivity
curl https://lame.ai.mattilsynet.io/v1/models

# Test with thinking disabled
curl -X POST https://lame.ai.mattilsynet.io/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "Qwen/Qwen3.5-122B-Instruct-FP8",
    "messages": [{"role": "user", "content": "Hello"}],
    "chat_template_kwargs": {"enable_thinking": false}
  }'
```

---

*Quick reference for vLLM + Qwen3.5 122B FP8*
*See `vllm-options-reference.md` for complete documentation*
