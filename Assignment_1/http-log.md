## Request 1: Get Post 1

**Command**
```powershell
curl.exe -i https://jsonplaceholder.typicode.com/posts/1
```

**Request URL:** `https://jsonplaceholder.typicode.com/posts/1`

**HTTP Method:** GET

**Status:** `200 OK`

**Important Response Headers**
- `Date: Sat, 10 Oct 2026 08:33:21 GMT`
- `Content-Type: application/json; charset=utf-8`
- `Content-Length: 292`
- `Cache-Control: max-age=43200`
- `ETag: W/"124-yiKdLzqO5gfBrJFrcdJ8Yq0LGnU"`
- `Server: cloudflare`
- `CF-Cache-Status: HIT`

**Response Body**
```json
{
  "userId": 1,
  "id": 1,
  "title": "sunt aut facere repellat provident occaecati excepturi optio reprehenderit",
  "body": "quia et suscipit\nsuscipit recusandae consequuntur expedita et cum\nreprehenderit molestiae ut ut quas totam\nnostrum rerum est autem sunt rem eveniet architecto"
}
```

**Observation:** The server returned `200 OK`, indicating that the requested post was retrieved successfully. The response contains the post's user ID, post ID, title, and body.


## Request 2: Request a Missing Post

**Command**
```bash
curl.exe -i https://jsonplaceholder.typicode.com/posts/999999
```

**Request**
- Method: GET
- URL: `https://jsonplaceholder.typicode.com/posts/999999`

**Response**
- Status: `404 Not Found`
- Date: `Sat, 10 Oct 2026 08:33:21 GMT`
- Content-Type: `application/json; charset=utf-8`
- Content-Length: `2`
- Cache-Control: `max-age=43200`
- ETag: `W/"2-vyGp6PvFo4RvsFtPoIWeCReyIC8"`
- Server: `cloudflare`
- CF-Cache-Status: `HIT`

**Response body**
```json
{}
```

**Observation:** This is a deliberate negative test. The requested post does not exist, and the API returns HTTP 404.

---

## Request 3: Retrieve Post 2

**Command**
```bash
curl.exe -i https://jsonplaceholder.typicode.com/posts/2
```

**Request**
- Method: GET
- URL: `https://jsonplaceholder.typicode.com/posts/2`

**Response**
- Status: `200 OK`
- Date: `Sat, 10 Oct 2026 08:33:22 GMT`
- Content-Type: `application/json; charset=utf-8`
- Content-Length: `278`
- Cache-Control: `max-age=43200`
- ETag: `W/"116-jnDuMpjju89+9j7e0BqkdFsVRjs"`
- Server: `cloudflare`
- CF-Cache-Status: `HIT`

**Response body**
```json
{
  "userId": 1,
  "id": 2,
  "title": "qui est esse",
  "body": "est rerum tempore vitae\nsequi sint nihil reprehenderit dolor beatae ea dolores neque\nfugiat blanditiis voluptate porro vel nihil molestiae ut reiciendis\nqui aperiam non debitis possimus qui neque nisi nulla"
}
```

**Observation:** The API successfully returns Post 2 in JSON format.
## Request 4: Retrieve User 1

**Command**
```bash
curl.exe -i https://jsonplaceholder.typicode.com/users/1
```

**Request**
- Method: GET
- URL: `https://jsonplaceholder.typicode.com/users/1`

**Response**
- Status: `200 OK`
- Date: `Sat, 10 Oct 2026 08:33:22 GMT`
- Content-Type: `application/json; charset=utf-8`
- Content-Length: `509`
- Cache-Control: `max-age=43200`
- ETag: `W/"1fd-+2Y3G3w049iSZtw5t1mzSnunngE"`
- Server: `cloudflare`
- CF-Cache-Status: `HIT`

**Response body**
```json
{
  "id": 1,
  "name": "Leanne Graham",
  "username": "Bret",
  "email": "Sincere@april.biz",
  "address": {
    "street": "Kulas Light",
    "suite": "Apt. 556",
    "city": "Gwenborough",
    "zipcode": "92998-3874",
    "geo": {
      "lat": "-37.3159",
      "lng": "81.1496"
    }
  },
  "phone": "1-770-736-8031 x56442",
  "website": "hildegard.org",
  "company": {
    "name": "Romaguera-Crona",
    "catchPhrase": "Multi-layered client-server neural-net",
    "bs": "harness real-time e-markets"
  }
}
```

**Observation:** The API successfully returns a user resource containing profile, address, contact, and company information in JSON format.
## Request 5: Get Comment 1

**Command**
```powershell
curl.exe -i https://jsonplaceholder.typicode.com/comments/1
```

**Request URL:** `https://jsonplaceholder.typicode.com/comments/1`

**HTTP Method:** GET

**Status:** `200 OK`

**Date:** Sat, 10 Oct 2026 08:33:22 GMT

**Important Response Headers**
- `Content-Type: application/json; charset=utf-8`
- `Content-Length: 268`
- `Cache-Control: max-age=43200`
- `ETag: W/"10c-KJ4I9RM/+33TKdV8CFsIvqsDSP0"`
- `Server: cloudflare`
- `CF-Cache-Status: HIT`

**Response Body**
```json
{
  "postId": 1,
  "id": 1,
  "name": "id labore ex et quam laborum",
  "email": "Eliseo@gardner.biz",
  "body": "laudantium enim quasi est quidem magnam voluptate ipsam eos\ntempora quo necessitatibus\ndolor quam autem quasi\nreiciendis et nam sapiente accusantium"
}
```

**Observation:** The server returned `200 OK`, indicating that the comment resource was retrieved successfully. The response contains the comment's ID, associated post ID, author name, email, and comment body. `CF-Cache-Status: HIT` indicates that Cloudflare served the response from its cache.