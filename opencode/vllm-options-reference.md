# vLLM OpenAI-Compatible API - Client-Side Options Reference

## Overview
This document lists all parameters you can control when connecting to vLLM via the OpenAI-compatible API through opencode.json and the @ai-sdk/openai-compatible package.

## Quick Reference: Your Current Setup
- **Server:** https://lame.ai.mattilsynet.io/v1 (shared, read-only)
- **Provider:** @ai-sdk/openai-compatible
- **Config Location:** ~/.config/opencode/opencode.json
- **Model:** Qwen3.5 122B FP8

**What You Can Control:**
Since you're using a shared vLLM server, you can only pass **client-side request parameters** through the OpenAI-compatible API. You cannot control server-level settings (like model loading, quantization, etc.).

---

## 1. Standard OpenAI Chat Completion Parameters

### Core Parameters
| Parameter | Type | Range | Default | Description |
|-----------|------|-------|---------|-------------|
| `model` | string | - | - | Model ID to use |
| `messages` | array | - | - | List of chat messages |
| `temperature` | number | 0.0-2.0 | 1.0 | Sampling temperature (lower = more deterministic) |
| `top_p` | number | 0.0-1.0 | 1.0 | Nucleus sampling parameter |
| `n` | integer | 1+ | 1 | Number of completions to generate |
| `stream` | boolean | - | false | Stream responses token-by-token |
| `stream_options` | object | - | - | Streaming options (`include_usage`, `continuous_usage_stats`) |

### Output Control
| Parameter | Type | Range | Default | Description |
|-----------|------|-------|---------|-------------|
| `max_completion_tokens` | integer | 1+ | - | Maximum completion tokens (replaces `max_tokens`) |
| `max_tokens` | integer | 1+ | - | Maximum tokens (deprecated, use `max_completion_tokens`) |
| `stop` | string/array | - | - | Stop sequences (string or array of strings) |
| `presence_penalty` | number | -2.0 to 2.0 | 0.0 | Penalize new tokens based on presence in text |
| `frequency_penalty` | number | -2.0 to 2.0 | 0.0 | Penalize new tokens based on frequency in text |
| `logit_bias` | object | - | - | Modify token likelihoods (e.g., `{"151644": -100}` to block token) |
| `seed` | integer | - | - | Random seed for reproducibility |
| `user` | string | - | - | End-user identifier for tracking |

### Logprobs
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `logprobs` | boolean | false | Return log probabilities for generated tokens |
| `top_logprobs` | integer | - | Number of top alternative logprobs to return |
| `prompt_logprobs` | integer | - | Return logprobs for prompt tokens (vLLM-specific) |

### Response Format
```json
{
  "response_format": {
    "type": "text" | "json_object" | "json_schema",
    "json_schema": {
      "name": "schema_name",
      "schema": { /* JSON schema definition */ }
    }
  }
}
```

### Tools (Function Calling)
| Parameter | Type | Description |
|-----------|------|-------------|
| `tools` | array | List of available tools/functions |
| `tool_choice` | string/object | "none", "auto", "required", or specific tool |
| `parallel_tool_calls` | boolean | Allow parallel tool calls (default: true) |

---

## 2. vLLM-Specific Sampling Parameters

These parameters extend beyond standard OpenAI API and control sampling behavior:

### Advanced Sampling
| Parameter | Type | Range | Default | Description |
|-----------|------|-------|---------|-------------|
| `top_k` | integer | -1+ | -1 | Top-k sampling (-1 to disable, typical: 40-50) |
| `min_p` | number | 0.0-1.0 | 0.0 | Minimum probability threshold (typical: 0.05-0.2) |
| `best_of` | integer | 1+ | 1 | Generate best_of sequences and return the best |
| `use_beam_search` | boolean | - | false | Use beam search instead of sampling |
| `length_penalty` | number | - | 1.0 | Length penalty for beam search (1.0 = no penalty) |
| `repetition_penalty` | number | 0.0-2.0 | 1.0 | Penalty for repetition (1.0 = no penalty, >1.0 penalizes) |
| `ignore_eos` | boolean | - | false | Ignore EOS token and continue generation |
| `min_tokens` | integer | 0+ | 0 | Minimum tokens to generate before stopping |
| `stop_token_ids` | array | - | - | Additional stop token IDs (e.g., `[151644]` for Qwen thinking end) |
| `include_stop_str_in_output` | boolean | - | false | Include stop strings in output |
| `skip_special_tokens` | boolean | - | true | Skip special tokens in output |
| `spaces_between_special_tokens` | boolean | - | true | Add spaces between special tokens |
| `truncate_prompt_tokens` | integer | 1+ | - | Truncate prompt to this many tokens |
| `allowed_token_ids` | array | - | - | Only allow specific token IDs (constrained decoding) |

---

## 3. Chat Template Parameters (Qwen-Specific)

### chat_template_kwargs
These are passed to the Jinja template renderer and control model-specific behavior. For Qwen models, this is where you control thinking/reasoning:

```json
{
  "chat_template_kwargs": {
    "enable_thinking": true/false,        // Qwen: Enable/disable thinking mode
    "enable_thinking_budget": 1000,       // Qwen: Token budget for thinking (max thinking tokens)
    "include_thinking_in_output": false   // Qwen: Include thinking content in final output
  }
}
```

**Key Qwen Thinking Parameters:**
- `enable_thinking` (boolean): When `true`, the model will generate thinking/reasoning content before the final answer
- `enable_thinking_budget` (integer): Maximum number of tokens the model can use for thinking
- `include_thinking_in_output` (boolean): Whether to include the thinking content in the returned output

### Chat Template Control Parameters
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `chat_template` | string | - | Custom Jinja template for chat formatting |
| `add_generation_prompt` | boolean | true | Add generation prompt to template |
| `continue_final_message` | boolean | false | Keep final message open-ended (cannot be true with `add_generation_prompt`) |
| `add_special_tokens` | boolean | false | Add special tokens on top of template |
| `echo` | boolean | false | Echo the last message if same role |
| `mm_processor_kwargs` | object | - | Additional kwargs for HuggingFace processor (multi-modal) |

---

## 4. Guided Decoding (Structured Output)

vLLM supports structured output through guided decoding. **Important constraints:**
- Only **ONE** of these can be used at a time
- Cannot be used with `tool_choice` (except "none", "auto", "required")

| Parameter | Type | Description |
|-----------|------|-------------|
| `guided_json` | object/string | Output must follow this JSON schema |
| `guided_regex` | string | Output must follow this regex pattern |
| `guided_choice` | array | Output must be one of these string choices |
| `guided_grammar` | string | Output must follow this CFG grammar |
| `guided_decoding_backend` | string | Backend to use: "outlines" or "lm-format-enforcer" |
| `guided_whitespace_pattern` | string | Whitespace pattern for JSON decoding |
| `structural_tag` | string | Structural tag schema for output |

### Example: JSON Schema Output
```json
{
  "guided_json": {
    "type": "object",
    "properties": {
      "name": {"type": "string"},
      "age": {"type": "number"},
      "email": {"type": "string", "format": "email"}
    },
    "required": ["name", "age"]
  }
}
```

### Example: Choice Selection
```json
{
  "guided_choice": ["Yes", "No", "Maybe"]
}
```

---

## 5. Advanced Request Control

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `priority` | integer | 0 | Request priority (lower = earlier in queue, e.g., -10 for high priority) |
| `request_id` | string | auto | Custom request ID for tracking |
| `return_token_ids` | boolean | false | Include token IDs alongside generated text |
| `return_tokens_as_token_ids` | boolean | false | Return tokens in `token_id:{id}` format |
| `cache_salt` | string | - | Salt for prefix cache security |
| `kv_transfer_params` | object | - | Parameters for disaggregated serving |
| `logits_processors` | array | - | Custom logits processors (qualified names or constructor objects) |
| `repetition_detection` | object | - | Parameters for detecting repetitive patterns |
| `documents` | array | - | Documents for RAG (each with "title" and "text" keys) |

---

## 6. How to Use in opencode.json

### Provider-Level Defaults
Set defaults that apply to all models under this provider:

```json
{
  "provider": {
    "dramallama": {
      "npm": "@ai-sdk/openai-compatible",
      "options": {
        "baseURL": "https://lame.ai.mattilsynet.io/v1",
        "chat_template_kwargs": {
          "enable_thinking": false
        }
      },
      "models": {
        "drama/code-thinking": {
          "options": {
            "chat_template_kwargs": {
              "enable_thinking": true
            }
          }
        },
        "drama/code-thinking-no-thinking": {
          "options": {
            "chat_template_kwargs": {
              "enable_thinking": false
            }
          }
        }
      }
    }
  }
}
```

### Per-Request Override (via AI SDK in your code)
When calling the AI SDK in your TypeScript/JavaScript code:

```typescript
import { createOpenAICompatible } from '@ai-sdk/openai-compatible';
import { generateText } from 'ai';

const vllm = createOpenAICompatible({
  name: 'dramallama',
  baseURL: 'https://lame.ai.mattilsynet.io/v1',
});

// Standard usage - uses model defaults from opencode.json
const result1 = await generateText({
  model: vllm('drama/code-thinking'),
  prompt: 'Your prompt',
});

// Per-request override
const result2 = await generateText({
  model: vllm('drama/code-thinking'),
  prompt: 'Generate JSON',
  providerOptions: {
    dramallama: {  // Your provider name
      temperature: 0.7,
      top_p: 0.9,
      max_completion_tokens: 2048,
      chat_template_kwargs: {
        enable_thinking: false  // Override model default
      },
      guided_json: {
        type: 'object',
        properties: {
          name: { type: 'string' },
          age: { type: 'number' }
        },
        required: ['name', 'age']
      },
      top_k: 40,
      min_p: 0.05,
      repetition_penalty: 1.1,
      priority: -10  // High priority
    }
  }
});
```

---

## 7. Qwen3.5 122B FP8 - Specific Use Cases

### Use Case 1: Fast Response Mode (No Thinking)
For quick, direct responses without reasoning:

```json
{
  "chat_template_kwargs": {
    "enable_thinking": false
  },
  "temperature": 0.7,
  "top_p": 0.9,
  "max_completion_tokens": 1024
}
```

### Use Case 2: Deep Thinking Mode
For complex reasoning tasks where you want the model to think through the problem:

```json
{
  "chat_template_kwargs": {
    "enable_thinking": true,
    "enable_thinking_budget": 2048,
    "include_thinking_in_output": false
  },
  "temperature": 0.5,
  "top_p": 0.95,
  "max_completion_tokens": 4096
}
```

### Use Case 3: Structured JSON Output
For API responses, data extraction, or structured data generation:

```json
{
  "guided_json": {
    "type": "object",
    "properties": {
      "summary": {"type": "string"},
      "sentiment": {"type": "string", "enum": ["positive", "negative", "neutral"]},
      "entities": {
        "type": "array",
        "items": {"type": "string"}
      }
    },
    "required": ["summary", "sentiment"]
  },
  "temperature": 0.1,
  "top_p": 0.95
}
```

### Use Case 4: Reproducible Generation
For consistent, repeatable results:

```json
{
  "seed": 42,
  "temperature": 0.7,
  "top_k": 40,
  "min_p": 0.05,
  "repetition_penalty": 1.05
}
```

### Use Case 5: Creative Writing
For more diverse, creative outputs:

```json
{
  "temperature": 1.2,
  "top_p": 0.95,
  "top_k": 50,
  "repetition_penalty": 1.1,
  "frequency_penalty": 0.5,
  "presence_penalty": 0.5
}
```

### Use Case 6: Code Generation
For precise, deterministic code:

```json
{
  "temperature": 0.2,
  "top_p": 0.95,
  "top_k": 40,
  "repetition_penalty": 1.05,
  "stop": ["\nclass", "\ndef ", "\nif ", "\nprint("],
  "guided_regex": "^```(?:python|javascript|typescript|bash)\\n[\\s\\S]*?```$"
}
```

---

## 8. Parameter Conflicts & Constraints

### Critical Constraints
1. **Guided decoding:** Only ONE of `guided_json`, `guided_regex`, `guided_choice`, `guided_grammar` at a time
2. **Guided decoding + Tools:** Cannot use together (except when tool_choice is "none"/"auto"/"required")
3. **Chat template:** `continue_final_message` and `add_generation_prompt` cannot both be true
4. **Beam search:** When `use_beam_search: true`, sampling parameters like `temperature` are ignored

### Server-Side Limitations
Since you're using a shared server, some parameters may be ignored or restricted:
- `priority` - May require server-side priority scheduling to be enabled
- `logits_processors` - May be disabled for security reasons
- `kv_transfer_params` - Only works with disaggregated serving setups
- Very high/low values for `temperature`, `top_p`, etc. may be clamped by server

---

## 9. Troubleshooting Common Issues

### Issue: "enable_thinking" Not Working
**Symptoms:** Model still generates thinking content even when `enable_thinking: false`

**Possible Causes:**
1. Server has thinking enabled by default and ignores client settings
2. Wrong parameter location (should be in `chat_template_kwargs`)
3. Model variant doesn't support thinking control

**Solution:**
```json
{
  "chat_template_kwargs": {
    "enable_thinking": false
  }
}
```
Make sure it's nested under `chat_template_kwargs`, not at the root level.

### Issue: "Parameter Not Recognized"
**Symptoms:** Server returns error about unknown parameter

**Possible Causes:**
1. Parameter is server-side only (not supported via API)
2. Typo in parameter name
3. Server version doesn't support this parameter

**Solution:**
- Check vLLM version on server
- Verify parameter name against documentation
- Try removing the parameter and see if request succeeds

### Issue: Structured Output Not Working
**Symptoms:** `guided_json` or `guided_regex` doesn't constrain output

**Possible Causes:**
1. Using with `tool_choice` (not allowed)
2. Multiple guided decoding parameters at once
3. Server doesn't have guided decoding backend installed

**Solution:**
- Remove `tool_choice` or set to "none"/"auto"/"required"
- Ensure only ONE guided decoding parameter
- Check server logs for guided decoding errors

### Issue: Thinking Tokens in Output
**Symptoms:** You see `<thinking>...</thinking>` or similar in output when you don't want it

**Solution:**
```json
{
  "chat_template_kwargs": {
    "enable_thinking": false,
    "include_thinking_in_output": false
  },
  "stop_token_ids": [151644]  // Qwen thinking end token ID
}
```

### Issue: Repetitive Output
**Symptoms:** Model gets stuck in loops or repeats itself

**Solution:**
```json
{
  "repetition_penalty": 1.2,
  "frequency_penalty": 0.5,
  "presence_penalty": 0.3,
  "top_k": 40,
  "min_p": 0.05
}
```

### Issue: Output Too Short
**Symptoms:** Model stops generating before completing thoughts

**Solution:**
```json
{
  "max_completion_tokens": 4096,
  "min_tokens": 100,
  "ignore_eos": false  // Default: respect EOS token
}
```

### Issue: Non-Deterministic Results
**Symptoms:** Same prompt gives different results each time

**Solution:**
```json
{
  "seed": 42,
  "temperature": 0.0,  // Or very low like 0.1
  "top_p": 1.0,
  "top_k": -1
}
```

---

## 10. How to Discover Server Capabilities

### Method 1: Check Server Info Endpoint
```bash
curl https://lame.ai.mattilsynet.io/v1/models
```
This shows available models and may include capability information.

### Method 2: Test Parameters Incrementally
Start with basic parameters and add advanced ones one at a time:
```bash
# Test 1: Basic request
curl -X POST https://lame.ai.mattilsynet.io/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model": "Qwen/Qwen3.5-122B-Instruct-FP8", "messages": [{"role": "user", "content": "test"}]}'

# Test 2: Add top_k
curl -X POST https://lame.ai.mattilsynet.io/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model": "Qwen/Qwen3.5-122B-Instruct-FP8", "messages": [{"role": "user", "content": "test"}], "top_k": 40}'

# Test 3: Add chat_template_kwargs
curl -X POST https://lame.ai.mattilsynet.io/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model": "Qwen/Qwen3.5-122B-Instruct-FP8", "messages": [{"role": "user", "content": "test"}], "chat_template_kwargs": {"enable_thinking": false}}'
```

### Method 3: Check vLLM Version
```bash
curl https://lame.ai.mattilsynet.io/v1/models | jq
```
Look for version info in response headers or body.

### Method 4: Review Server Logs (If You Have Access)
If you have any access to server logs, check for:
- Unsupported parameter warnings
- Parameter clamping messages
- Feature availability notices

---

## 11. Documentation Sources

**Primary Documentation:**
- **vLLM OpenAI-Compatible Server:** https://docs.vllm.ai/en/stable/serving/openai_compatible_server.html
- **vLLM Server Arguments:** https://docs.vllm.ai/en/stable/configuration/serve_args.html
- **vLLM Engine Arguments:** https://docs.vllm.ai/en/stable/configuration/engine_args.html
- **Interleaved Thinking (Qwen):** https://docs.vllm.ai/en/stable/features/interleaved_thinking.html
- **Reasoning Outputs:** https://docs.vllm.ai/en/stable/features/reasoning_outputs.html
- **FP8 Quantization:** https://docs.vllm.ai/en/stable/features/quantization/fp8.html
- **Structured Outputs:** https://docs.vllm.ai/en/stable/features/structured_outputs.html
- **Tool Calling:** https://docs.vllm.ai/en/stable/features/tool_calling.html

**AI SDK Documentation:**
- **@ai-sdk/openai-compatible:** https://sdk.vercel.ai/providers/ai-sdk-providers/openai-compatible

---

## 12. Quick Parameter Cheat Sheet

### Most Commonly Used Parameters
```json
{
  "temperature": 0.7,           // Creativity vs determinism
  "top_p": 0.9,                 // Nucleus sampling
  "max_completion_tokens": 2048, // Max output length
  "stop": ["\n\n"],             // Stop sequences
  "chat_template_kwargs": {
    "enable_thinking": false     // Qwen thinking control
  }
}
```

### Advanced Sampling
```json
{
  "top_k": 40,                  // Top-k sampling
  "min_p": 0.05,                // Minimum probability
  "repetition_penalty": 1.1,    // Repetition control
  "frequency_penalty": 0.3,     // Frequency penalty
  "presence_penalty": 0.3       // Presence penalty
}
```

### Structured Output
```json
{
  "guided_json": { /* schema */ },  // JSON schema
  "guided_choice": ["a", "b"],      // Choice selection
  "guided_regex": "pattern"         // Regex pattern
}
```

### Reproducibility
```json
{
  "seed": 42,                     // Random seed
  "temperature": 0.0,             // Deterministic
  "top_k": -1,                    // No top-k filtering
  "top_p": 1.0                    // No nucleus sampling
}
```

---

*Last updated: March 2026*
*For Qwen3.5 122B FP8 on vLLM via @ai-sdk/openai-compatible*
