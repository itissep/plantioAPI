import Vapor

func registerOpenAPIRoutes(_ app: Application) throws {
    app.get("openapi.json") { _ -> Response in
        let spec = """
        {
          "openapi": "3.0.0",
          "info": { "title": "Plants Service", "version": "1.0.0", "description": "Plant management, care events and photos" },
          "components": {
            "securitySchemes": {
              "bearerAuth": { "type": "http", "scheme": "bearer", "bearerFormat": "JWT" }
            },
            "schemas": {
              "Plant": {
                "type": "object",
                "properties": {
                  "id": { "type": "string", "format": "uuid" },
                  "userID": { "type": "string", "format": "uuid" },
                  "name": { "type": "string" },
                  "description": { "type": "string", "nullable": true },
                  "species": { "type": "string", "nullable": true },
                  "wateringPeriod": { "type": "integer", "nullable": true, "description": "Days between watering" },
                  "createdAt": { "type": "string", "format": "date-time" },
                  "updatedAt": { "type": "string", "format": "date-time" }
                }
              },
              "CareEvent": {
                "type": "object",
                "properties": {
                  "id": { "type": "string", "format": "uuid" },
                  "plantID": { "type": "string", "format": "uuid" },
                  "kind": { "type": "string", "enum": ["watering", "fertilizing", "repotting", "note"] },
                  "notes": { "type": "string", "nullable": true },
                  "occurredAt": { "type": "string", "format": "date-time" },
                  "createdAt": { "type": "string", "format": "date-time" }
                }
              },
              "Photo": {
                "type": "object",
                "properties": {
                  "id": { "type": "string", "format": "uuid" },
                  "plantID": { "type": "string", "format": "uuid" },
                  "mimeType": { "type": "string" },
                  "byteSize": { "type": "integer" },
                  "createdAt": { "type": "string", "format": "date-time" }
                }
              }
            }
          },
          "paths": {
            "/plants": {
              "get": {
                "tags": ["Plants"], "summary": "List my plants",
                "security": [{ "bearerAuth": [] }],
                "responses": { "200": { "description": "Array of plants", "content": { "application/json": { "schema": { "type": "array", "items": { "$ref": "#/components/schemas/Plant" } } } } } }
              },
              "post": {
                "tags": ["Plants"], "summary": "Create a plant",
                "security": [{ "bearerAuth": [] }],
                "requestBody": {
                  "required": true,
                  "content": { "application/json": { "schema": { "type": "object", "required": ["name"], "properties": { "name": { "type": "string" }, "description": { "type": "string" }, "species": { "type": "string" }, "wateringPeriod": { "type": "integer" } } } } }
                },
                "responses": { "200": { "description": "Created plant", "content": { "application/json": { "schema": { "$ref": "#/components/schemas/Plant" } } } } }
              }
            },
            "/plants/{plantID}": {
              "get": {
                "tags": ["Plants"], "summary": "Get plant by ID",
                "security": [{ "bearerAuth": [] }],
                "parameters": [{ "name": "plantID", "in": "path", "required": true, "schema": { "type": "string", "format": "uuid" } }],
                "responses": { "200": { "description": "Plant", "content": { "application/json": { "schema": { "$ref": "#/components/schemas/Plant" } } } }, "404": { "description": "Not found" } }
              },
              "put": {
                "tags": ["Plants"], "summary": "Update plant",
                "security": [{ "bearerAuth": [] }],
                "parameters": [{ "name": "plantID", "in": "path", "required": true, "schema": { "type": "string", "format": "uuid" } }],
                "requestBody": { "content": { "application/json": { "schema": { "type": "object", "properties": { "name": { "type": "string" }, "description": { "type": "string" }, "species": { "type": "string" }, "wateringPeriod": { "type": "integer" } } } } } },
                "responses": { "200": { "description": "Updated plant", "content": { "application/json": { "schema": { "$ref": "#/components/schemas/Plant" } } } } }
              },
              "delete": {
                "tags": ["Plants"], "summary": "Delete plant",
                "security": [{ "bearerAuth": [] }],
                "parameters": [{ "name": "plantID", "in": "path", "required": true, "schema": { "type": "string", "format": "uuid" } }],
                "responses": { "204": { "description": "Deleted" } }
              }
            },
            "/plants/{plantID}/care-events": {
              "get": {
                "tags": ["Care Events"], "summary": "List care events for a plant",
                "security": [{ "bearerAuth": [] }],
                "parameters": [{ "name": "plantID", "in": "path", "required": true, "schema": { "type": "string", "format": "uuid" } }],
                "responses": { "200": { "description": "Array of care events", "content": { "application/json": { "schema": { "type": "array", "items": { "$ref": "#/components/schemas/CareEvent" } } } } } }
              },
              "post": {
                "tags": ["Care Events"], "summary": "Create care event",
                "security": [{ "bearerAuth": [] }],
                "parameters": [{ "name": "plantID", "in": "path", "required": true, "schema": { "type": "string", "format": "uuid" } }],
                "requestBody": {
                  "required": true,
                  "content": { "application/json": { "schema": { "type": "object", "required": ["kind"], "properties": { "kind": { "type": "string", "enum": ["watering", "fertilizing", "repotting", "note"] }, "notes": { "type": "string" }, "occurredAt": { "type": "string", "format": "date-time" } } } } }
                },
                "responses": { "200": { "description": "Created care event", "content": { "application/json": { "schema": { "$ref": "#/components/schemas/CareEvent" } } } } }
              }
            },
            "/plants/{plantID}/photos": {
              "get": {
                "tags": ["Photos"], "summary": "List photos for a plant",
                "security": [{ "bearerAuth": [] }],
                "parameters": [{ "name": "plantID", "in": "path", "required": true, "schema": { "type": "string", "format": "uuid" } }],
                "responses": { "200": { "description": "Array of photos", "content": { "application/json": { "schema": { "type": "array", "items": { "$ref": "#/components/schemas/Photo" } } } } } }
              },
              "post": {
                "tags": ["Photos"], "summary": "Upload a photo",
                "security": [{ "bearerAuth": [] }],
                "parameters": [{ "name": "plantID", "in": "path", "required": true, "schema": { "type": "string", "format": "uuid" } }],
                "requestBody": { "required": true, "content": { "multipart/form-data": { "schema": { "type": "object", "properties": { "file": { "type": "string", "format": "binary" } } } } } },
                "responses": { "200": { "description": "Uploaded photo metadata", "content": { "application/json": { "schema": { "$ref": "#/components/schemas/Photo" } } } } }
              }
            },
            "/plants/{plantID}/photos/{photoID}": {
              "delete": {
                "tags": ["Photos"], "summary": "Delete a photo",
                "security": [{ "bearerAuth": [] }],
                "parameters": [
                  { "name": "plantID", "in": "path", "required": true, "schema": { "type": "string", "format": "uuid" } },
                  { "name": "photoID", "in": "path", "required": true, "schema": { "type": "string", "format": "uuid" } }
                ],
                "responses": { "204": { "description": "Deleted" } }
              }
            },
            "/media/{photoID}": {
              "get": {
                "tags": ["Photos"], "summary": "Serve photo file",
                "parameters": [{ "name": "photoID", "in": "path", "required": true, "schema": { "type": "string", "format": "uuid" } }],
                "responses": { "200": { "description": "Image file", "content": { "image/*": {} } } }
              }
            }
          }
        }
        """
        return Response(status: .ok, headers: ["Content-Type": "application/json"], body: .init(string: spec))
    }

    app.get("docs") { _ -> Response in
        Response(status: .ok, headers: ["Content-Type": "text/html"], body: .init(string: swaggerUIHTML(title: "Plants Service", specURL: "/openapi.json")))
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
