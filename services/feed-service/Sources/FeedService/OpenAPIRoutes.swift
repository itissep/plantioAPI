import Vapor

func registerOpenAPIRoutes(_ app: Application) throws {
    app.get("openapi.json") { _ -> Response in
        let spec = """
        {
          "openapi": "3.0.0",
          "info": { "title": "Feed Service", "version": "1.0.0", "description": "Feed posts and comments" },
          "components": {
            "securitySchemes": {
              "bearerAuth": { "type": "http", "scheme": "bearer", "bearerFormat": "JWT" }
            },
            "schemas": {
              "FeedPost": {
                "type": "object",
                "properties": {
                  "id": { "type": "string", "format": "uuid" },
                  "authorUserID": { "type": "string", "format": "uuid" },
                  "plantID": { "type": "string", "format": "uuid" },
                  "careEventID": { "type": "string", "format": "uuid" },
                  "kind": { "type": "string", "enum": ["watering", "fertilizing", "repotting", "note"] },
                  "occurredAt": { "type": "string", "format": "date-time" },
                  "createdAt": { "type": "string", "format": "date-time" }
                }
              },
              "Comment": {
                "type": "object",
                "properties": {
                  "id": { "type": "string", "format": "uuid" },
                  "postID": { "type": "string", "format": "uuid" },
                  "authorUserID": { "type": "string", "format": "uuid" },
                  "text": { "type": "string" },
                  "createdAt": { "type": "string", "format": "date-time" }
                }
              }
            }
          },
          "paths": {
            "/posts": {
              "get": {
                "tags": ["Feed"], "summary": "Get personal feed (subscriptions + own activity)",
                "security": [{ "bearerAuth": [] }],
                "parameters": [
                  { "name": "page", "in": "query", "schema": { "type": "integer", "default": 1 } },
                  { "name": "perPage", "in": "query", "schema": { "type": "integer", "default": 20 } }
                ],
                "responses": { "200": { "description": "Array of feed posts", "content": { "application/json": { "schema": { "type": "array", "items": { "$ref": "#/components/schemas/FeedPost" } } } } } }
              }
            },
            "/posts/global": {
              "get": {
                "tags": ["Feed"], "summary": "Get global feed (all users)",
                "parameters": [
                  { "name": "page", "in": "query", "schema": { "type": "integer", "default": 1 } },
                  { "name": "perPage", "in": "query", "schema": { "type": "integer", "default": 20 } }
                ],
                "responses": { "200": { "description": "Array of feed posts", "content": { "application/json": { "schema": { "type": "array", "items": { "$ref": "#/components/schemas/FeedPost" } } } } } }
              }
            },
            "/posts/{postID}/comments": {
              "get": {
                "tags": ["Comments"], "summary": "List comments for a post",
                "parameters": [{ "name": "postID", "in": "path", "required": true, "schema": { "type": "string", "format": "uuid" } }],
                "responses": { "200": { "description": "Array of comments", "content": { "application/json": { "schema": { "type": "array", "items": { "$ref": "#/components/schemas/Comment" } } } } } }
              },
              "post": {
                "tags": ["Comments"], "summary": "Add a comment",
                "security": [{ "bearerAuth": [] }],
                "parameters": [{ "name": "postID", "in": "path", "required": true, "schema": { "type": "string", "format": "uuid" } }],
                "requestBody": {
                  "required": true,
                  "content": { "application/json": { "schema": { "type": "object", "required": ["text"], "properties": { "text": { "type": "string" } } } } }
                },
                "responses": { "200": { "description": "Created comment", "content": { "application/json": { "schema": { "$ref": "#/components/schemas/Comment" } } } } }
              }
            },
            "/posts/{postID}/comments/{commentID}": {
              "delete": {
                "tags": ["Comments"], "summary": "Delete own comment",
                "security": [{ "bearerAuth": [] }],
                "parameters": [
                  { "name": "postID", "in": "path", "required": true, "schema": { "type": "string", "format": "uuid" } },
                  { "name": "commentID", "in": "path", "required": true, "schema": { "type": "string", "format": "uuid" } }
                ],
                "responses": { "204": { "description": "Deleted" }, "403": { "description": "Cannot delete another user's comment" } }
              }
            }
          }
        }
        """
        return Response(status: .ok, headers: ["Content-Type": "application/json"], body: .init(string: spec))
    }

    app.get("docs") { _ -> Response in
        Response(status: .ok, headers: ["Content-Type": "text/html"], body: .init(string: swaggerUIHTML(title: "Feed Service", specURL: "/openapi.json")))
    }
}

private func swaggerUIHTML(title: String, specURL: String) -> String {
    """
    <!DOCTYPE html>
    <html>
    <head>
        <title>\(title) – API Docs</title>
        <meta charset="utf-8"/>
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <link rel="stylesheet" type="text/css" href="https://unpkg.com/swagger-ui-dist/swagger-ui.css">
    </head>
    <body>
        <div id="swagger-ui"></div>
        <script src="https://unpkg.com/swagger-ui-dist/swagger-ui-bundle.js"></script>
        <script>
            SwaggerUIBundle({ url: "\(specURL)", dom_id: '#swagger-ui', presets: [SwaggerUIBundle.presets.apis, SwaggerUIBundle.SwaggerUIStandalonePreset], layout: "BaseLayout", deepLinking: true })
        </script>
    </body>
    </html>
    """
}
