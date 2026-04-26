import Vapor

func registerOpenAPIRoutes(_ app: Application) throws {
    app.get("openapi.json") { _ -> Response in
        let spec = """
        {
          "openapi": "3.0.0",
          "info": { "title": "Plantio API", "version": "1.0.0", "description": "Social network for plant lovers. All requests go through the API Gateway at /v1." },
          "servers": [{ "url": "/v1" }],
          "components": {
            "securitySchemes": {
              "bearerAuth": { "type": "http", "scheme": "bearer", "bearerFormat": "JWT" }
            }
          },
          "paths": {
            "/auth/register": { "post": { "tags": ["Auth"], "summary": "Register", "responses": { "200": { "description": "Tokens + user" } } } },
            "/auth/login": { "post": { "tags": ["Auth"], "summary": "Login", "responses": { "200": { "description": "Tokens + user" } } } },
            "/auth/refresh": { "post": { "tags": ["Auth"], "summary": "Refresh token", "responses": { "200": { "description": "New tokens" } } } },
            "/auth/logout": { "post": { "tags": ["Auth"], "summary": "Logout", "responses": { "200": { "description": "OK" } } } },
            "/users/me": {
              "get": { "tags": ["Users"], "summary": "My profile", "security": [{ "bearerAuth": [] }], "responses": { "200": { "description": "User" } } },
              "put": { "tags": ["Users"], "summary": "Update profile", "security": [{ "bearerAuth": [] }], "responses": { "200": { "description": "Updated user" } } }
            },
            "/users/{userID}": { "get": { "tags": ["Users"], "summary": "Public profile", "parameters": [{ "name": "userID", "in": "path", "required": true, "schema": { "type": "string", "format": "uuid" } }], "responses": { "200": { "description": "Profile" } } } },
            "/users/{userID}/followers": { "get": { "tags": ["Users"], "summary": "Followers list", "parameters": [{ "name": "userID", "in": "path", "required": true, "schema": { "type": "string", "format": "uuid" } }], "responses": { "200": { "description": "Followers" } } } },
            "/users/{userID}/following": { "get": { "tags": ["Users"], "summary": "Following list", "parameters": [{ "name": "userID", "in": "path", "required": true, "schema": { "type": "string", "format": "uuid" } }], "responses": { "200": { "description": "Following" } } } },
            "/users/{userID}/follow": {
              "post": { "tags": ["Users"], "summary": "Follow", "security": [{ "bearerAuth": [] }], "parameters": [{ "name": "userID", "in": "path", "required": true, "schema": { "type": "string", "format": "uuid" } }], "responses": { "201": { "description": "Followed" } } },
              "delete": { "tags": ["Users"], "summary": "Unfollow", "security": [{ "bearerAuth": [] }], "parameters": [{ "name": "userID", "in": "path", "required": true, "schema": { "type": "string", "format": "uuid" } }], "responses": { "204": { "description": "Unfollowed" } } }
            },
            "/plants": {
              "get": { "tags": ["Plants"], "summary": "My plants", "security": [{ "bearerAuth": [] }], "responses": { "200": { "description": "Plants" } } },
              "post": { "tags": ["Plants"], "summary": "Create plant", "security": [{ "bearerAuth": [] }], "responses": { "200": { "description": "Plant" } } }
            },
            "/plants/{plantID}": {
              "get": { "tags": ["Plants"], "summary": "Get plant", "security": [{ "bearerAuth": [] }], "parameters": [{ "name": "plantID", "in": "path", "required": true, "schema": { "type": "string", "format": "uuid" } }], "responses": { "200": { "description": "Plant" } } },
              "put": { "tags": ["Plants"], "summary": "Update plant", "security": [{ "bearerAuth": [] }], "parameters": [{ "name": "plantID", "in": "path", "required": true, "schema": { "type": "string", "format": "uuid" } }], "responses": { "200": { "description": "Plant" } } },
              "delete": { "tags": ["Plants"], "summary": "Delete plant", "security": [{ "bearerAuth": [] }], "parameters": [{ "name": "plantID", "in": "path", "required": true, "schema": { "type": "string", "format": "uuid" } }], "responses": { "204": { "description": "Deleted" } } }
            },
            "/plants/{plantID}/care-events": {
              "get": { "tags": ["Care Events"], "summary": "List care events", "security": [{ "bearerAuth": [] }], "parameters": [{ "name": "plantID", "in": "path", "required": true, "schema": { "type": "string", "format": "uuid" } }], "responses": { "200": { "description": "Care events" } } },
              "post": { "tags": ["Care Events"], "summary": "Create care event", "security": [{ "bearerAuth": [] }], "parameters": [{ "name": "plantID", "in": "path", "required": true, "schema": { "type": "string", "format": "uuid" } }], "responses": { "200": { "description": "Care event" } } }
            },
            "/plants/{plantID}/photos": {
              "get": { "tags": ["Photos"], "summary": "List photos", "security": [{ "bearerAuth": [] }], "parameters": [{ "name": "plantID", "in": "path", "required": true, "schema": { "type": "string", "format": "uuid" } }], "responses": { "200": { "description": "Photos" } } },
              "post": { "tags": ["Photos"], "summary": "Upload photo", "security": [{ "bearerAuth": [] }], "parameters": [{ "name": "plantID", "in": "path", "required": true, "schema": { "type": "string", "format": "uuid" } }], "responses": { "200": { "description": "Photo" } } }
            },
            "/posts": { "get": { "tags": ["Feed"], "summary": "Personal feed", "security": [{ "bearerAuth": [] }], "responses": { "200": { "description": "Feed posts" } } } },
            "/posts/global": { "get": { "tags": ["Feed"], "summary": "Global feed (all users)", "responses": { "200": { "description": "Feed posts" } } } },
            "/posts/{postID}/comments": {
              "get": { "tags": ["Comments"], "summary": "List comments", "parameters": [{ "name": "postID", "in": "path", "required": true, "schema": { "type": "string", "format": "uuid" } }], "responses": { "200": { "description": "Comments" } } },
              "post": { "tags": ["Comments"], "summary": "Add comment", "security": [{ "bearerAuth": [] }], "parameters": [{ "name": "postID", "in": "path", "required": true, "schema": { "type": "string", "format": "uuid" } }], "responses": { "200": { "description": "Comment" } } }
            },
            "/notifications": { "get": { "tags": ["Notifications"], "summary": "My notifications", "security": [{ "bearerAuth": [] }], "responses": { "200": { "description": "Notifications" } } } },
            "/notifications/{notificationID}/read": { "post": { "tags": ["Notifications"], "summary": "Mark as read", "security": [{ "bearerAuth": [] }], "parameters": [{ "name": "notificationID", "in": "path", "required": true, "schema": { "type": "string", "format": "uuid" } }], "responses": { "200": { "description": "Updated notification" } } } }
          }
        }
        """
        return Response(status: .ok, headers: ["Content-Type": "application/json"], body: .init(string: spec))
    }

    app.get("docs") { _ -> Response in
        Response(status: .ok, headers: ["Content-Type": "text/html"], body: .init(string: swaggerUIHTML(title: "Plantio API", specURL: "/openapi.json")))
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
