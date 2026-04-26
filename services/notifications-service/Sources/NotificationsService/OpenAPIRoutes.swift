import Vapor

func registerOpenAPIRoutes(_ app: Application) throws {
    app.get("openapi.json") { _ -> Response in
        let spec = """
        {
          "openapi": "3.0.0",
          "info": { "title": "Notifications Service", "version": "1.0.0", "description": "In-app notifications and real-time WebSocket delivery" },
          "components": {
            "securitySchemes": {
              "bearerAuth": { "type": "http", "scheme": "bearer", "bearerFormat": "JWT" }
            },
            "schemas": {
              "Notification": {
                "type": "object",
                "properties": {
                  "id": { "type": "string", "format": "uuid" },
                  "title": { "type": "string" },
                  "body": { "type": "string" },
                  "isRead": { "type": "boolean" },
                  "careEventID": { "type": "string", "format": "uuid" },
                  "plantID": { "type": "string", "format": "uuid" },
                  "createdAt": { "type": "string", "format": "date-time" }
                }
              }
            }
          },
          "paths": {
            "/notifications": {
              "get": {
                "tags": ["Notifications"], "summary": "List notifications for current user",
                "security": [{ "bearerAuth": [] }],
                "responses": { "200": { "description": "Array of notifications", "content": { "application/json": { "schema": { "type": "array", "items": { "$ref": "#/components/schemas/Notification" } } } } } }
              }
            },
            "/notifications/{notificationID}/read": {
              "post": {
                "tags": ["Notifications"], "summary": "Mark notification as read",
                "security": [{ "bearerAuth": [] }],
                "parameters": [{ "name": "notificationID", "in": "path", "required": true, "schema": { "type": "string", "format": "uuid" } }],
                "responses": {
                  "200": { "description": "Updated notification", "content": { "application/json": { "schema": { "$ref": "#/components/schemas/Notification" } } } },
                  "404": { "description": "Not found" }
                }
              }
            },
            "/ws": {
              "get": {
                "tags": ["WebSocket"],
                "summary": "Connect to real-time notifications via WebSocket",
                "description": "Connect with `ws://host/ws?token=<access_token>`. Receives JSON-encoded Notification objects when new notifications arrive.",
                "parameters": [{ "name": "token", "in": "query", "required": true, "schema": { "type": "string" }, "description": "JWT access token" }],
                "responses": { "101": { "description": "Switching Protocols" }, "403": { "description": "Invalid token" } }
              }
            }
          }
        }
        """
        return Response(status: .ok, headers: ["Content-Type": "application/json"], body: .init(string: spec))
    }

    app.get("docs") { _ -> Response in
        Response(status: .ok, headers: ["Content-Type": "text/html"], body: .init(string: swaggerUIHTML(title: "Notifications Service", specURL: "/openapi.json")))
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
