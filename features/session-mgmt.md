# Feature: Session & Project Isolation

## Codename: `session-mgmt`

### Business Logic
Sessions organize continuous conversational state and provide resource boundaries across projects.

### Key Concepts
1. **Conversational Session**:
   - Represents an ordered sequence of user and assistant interactions.
   - Maintains conversational continuity across discrete API requests.
2. **Project Isolation**:
   - Namespaces sessions by project or tenant.
   - Guarantees memory budgets and model access permissions per project.
3. **Long-Lived Memory & Cache**:
   - Persistent tokenization and prefix KV cache tied to session and project scopes.
   - Drastically cuts redundant tokenization and prefill computation across repeated queries.
