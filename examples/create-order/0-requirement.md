# Requirement (as received from the user)

> We need an endpoint so an authenticated user can create an order with one or
> more items. Stock has to be checked before the order is accepted, and the
> total must be computed on the server — never trusted from the client.
> Currency is always BRL and we store prices in cents.

That's it — this single paragraph is the input to the pipeline. Everything under
`1-planner/`, `2-architect/`, `3-builder/` and `4-tester/` was derived from it,
stage by stage, with a confirmation gate between each stage.
