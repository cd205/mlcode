# The web app runs the engine on the server only

2026-10-27, web app W0 ([web_app_plan.md](../web_app_plan.md) C1).

The web app lets anyone build a Sequence and evaluate or optimise it, but the `oms` code stays private. The browser sends a Sequence as JSON and gets results back as JSON. All Python runs in a FastAPI process on the server, and the page holds no engine code.

**Considered and rejected:**
- *Pyodide (the engine running in the browser).* It would be free to host as a static site and needs no job queue, but it ships the full `oms` source to every visitor.
- *Re-implementing the engine in JavaScript.* That makes two engines to keep in step with the reference cases, and the JavaScript one is still readable in the browser.

**Consequences:**
- Hosting needs a running server, not static files. Long requests (`search_sequences`, Monte Carlo from 4 Features) will need a job queue and request limits (plan W5).
- The repo `cd205/mlcode` must stay private. If the web code is ever made public, `oms` moves to a private package first.
- API errors never return tracebacks, so the code can't leak through error messages.
