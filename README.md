# Vend-O-Matic

A beverage vending machine service over HTTP/JSON. **Zero dependencies**: only Node.js built-ins (`http`, `JSON`).

## Setup (macOS)

1. Install Node.js 16+ if needed:
   ```
   brew install node
   node --version
   ```
2. Start the server (default port 8080):
   ```
   cd vend-o-matic
   node server.js
   ```
   Use a different port with `PORT=9000 node server.js`.
3. In another terminal, run the smoke test against a freshly started server:
   ```
   ./test.sh            # or ./test.sh http://localhost:9000
   ```

State is in memory; restart the server to reset inventory to `[5,5,5]` and coins to 0.

## API

| Verb | URI | Result |
|------|-----|--------|
| PUT | `/` body `{"coin":1}` | 204, `X-Coins`: coins accepted so far |
| DELETE | `/` | 204, `X-Coins`: coins returned (balance resets to 0) |
| GET | `/inventory` | 200, array of remaining quantities, e.g. `[5,5,5]` |
| GET | `/inventory/:id` | 200, integer quantity (id 0-2) |
| PUT | `/inventory/:id` | 200, `X-Coins`: change returned, `X-Inventory-Remaining`: stock left, body `{"quantity":1}` |
| PUT | `/inventory/:id` | 404 if out of stock, `X-Coins`: coins still in machine (not consumed) |
| PUT | `/inventory/:id` | 403 if fewer than 2 coins, `X-Coins`: 0 or 1 |

## Assumptions

- Items are ids `0`, `1`, `2`; price is 2 quarters; 5 of each in stock.
- A successful purchase vends exactly one item and returns all remaining coins (`coins - 2`); balance resets to 0.
- Out-of-stock is checked before coin sufficiency, and coins are kept for the customer to buy something else or cancel with DELETE.
- Unknown item ids return 404; a PUT `/` with anything other than `{"coin":1}` or with bad JSON returns 400.

## Manual example

```
curl -i -X PUT -H 'Content-Type: application/json' -d '{"coin":1}' localhost:8080/
curl -i -X PUT -H 'Content-Type: application/json' -d '{"coin":1}' localhost:8080/
curl -i -X PUT localhost:8080/inventory/0
curl -s localhost:8080/inventory
```
