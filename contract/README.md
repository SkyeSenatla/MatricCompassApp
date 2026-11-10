# The API contract, copied

`openapi/v1.json` is a copy of the Matric Compass API's committed contract.

- Source: the `Matric-Compass` repo, `openapi/v1.json`
- Copied at API commit: `27adcf0` (End of day 2 and 3 week 9)

Week 10 Day 1: copied so the app's repo holds the contract it was built
against. Week 11 Day 1 generates the Dart client from this copy, and adds a
CI step that fails when it no longer matches the API repo's file.

To update it: copy the file again from the API repo, update the commit above,
regenerate the client, and fix whatever no longer compiles, in one pull
request.
