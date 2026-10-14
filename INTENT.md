# K3 Uber AI runtime manager

1. Be able to execute AI runtime on both the X100 and A100
2. Be Open AI compatible and Claude compatible
3. Provide a KV cache

## Able to execute all modern open source AI models

- Gemma4
- GWEN3.8
- etc.

## The runtime manager allow to manage model

The manager should allow to download model from public source. An external adapter should be
provided to allow private vendor to implement their own repository.

The manager should allow to fine tune the execution of a model: not all models may be optimzed for
the A100 and rely on the X100 raw performance. This may include management of the context size and
KV cache.

## Session management must remain on the X100

The X100 allow more reactive behaviour while the A100 promise better vector capacity.

