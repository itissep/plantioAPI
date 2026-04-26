import Vapor

func registerOpenAPIRoutes(_ app: Application) throws {
    app.get("openapi.json") { _ -> Response in
        let spec = """
        {
          "openapi": "3.0.0",
          "info": {
            "title": "Identity Service",
            "version": "1.0.0",
            "description": "Authentication and user management"
          },
          "components": {
            "securitySchemes": {
              "bearerAuth": { "type": "http", "scheme": "bearer", "bearerFormat": "JWT" }
            },
            "schemas": {
              "AuthTokensResponse": {
                "type": "object",
                "properties": {
                  "accessToken": { "type": "string" },
                  "refreshToken": { "type": "string" },
                  "user": { "$ref": "#/components/schemas/UserPublic" }
                }
              },
              "UserPublic": {
                "type": "object",
                "properties": {
                  "id": { "type": "string", "format": "uuid" },
                  "email": { "type": "string" },
                  "name": { "type": "string" },
                  "avatar": { "type": "string", "nullable": true }
                }
              },
              "UserPublicProfile": {
                "type": "object",
                "properties": {
                  "id": { "type": "string", "format": "uuid" },
                  "name": { "type": "string" },
                  "avatar": { "type": "string", "nullable": true }
                }
              }
            }
          },
          "paths": {
            "/auth/register": {
              "post": {
                "tags": ["Auth"],
                "summary": "Register a new user",
                "requestBody": {
                  "required": true,
                  "content": {
                    "application/json": {
                      "schema": {
                        "type": "object",
                        "required": ["email", "password", "name"],
                        "properties": {
                          "email": { "type": "string", "format": "email" },
                          "password": { "type": "string", "minLength": 8 },
                          "name": { "type": "string" },
                          "avatar": { "type": "string", "nullable": true }
                        }
                      }
                    }
                  }
                },
                "responses": {
                  "200": { "description": "Tokens and user", "content": { "application/json": { "schema": { "$ref": "#/components/schemas/AuthTokensResponse" } } } },
                  "400": { "description": "Invalid input" },
                  "409": { "description": "Email already registered" }
                }
              }
            },
            "/auth/login": {
              "post": {
                "tags": ["Auth"],
                "summary": "Login",
                "requestBody": {
                  "required": true,
                  "content": {
                    "application/json": {
                      "schema": {
                        "type": "object",
                        "required": ["email", "password"],
                        "properties": {
                          "email": { "type": "string" },
                          "password": { "type": "string" }
                        }
                      }
                    }
                  }
                },
                "responses": {
                  "200": { "description": "Tokens and user", "content": { "application/json": { "schema": { "$ref": "#/components/schemas/AuthTokensResponse" } } } },
                  "401": { "description": "Invalid credentials" }
                }
              }
            },
            "/auth/refresh": {
              "post": {
                "tags": ["Auth"],
                "summary": "Refresh access token",
                "requestBody": {
                  "required": true,
                  "content": { "application/json": { "schema": { "type": "object", "properties": { "refreshToken": { "type": "string" } } } } }
                },
                "responses": {
                  "200": { "description": "New tokens", "content": { "application/json": { "schema": { "$ref": "#/components/schemas/AuthTokensResponse" } } } },
                  "401": { "description": "Invalid or expired refresh token" }
                }
              }
            },
            "/auth/logout": {
              "post": {
                "tags": ["Auth"],
                "summary": "Logout",
                "requestBody": {
                  "required": true,
                  "content": { "application/json": { "schema": { "type": "object", "properties": { "refreshToken": { "type": "string" } } } } }
                },
                "responses": { "200": { "description": "Logged out" } }
              }
            },
            "/users/me": {
              "get": {
                "tags": ["Users"],
                "summary": "Get current user profile",
                "security": [{ "bearerAuth": [] }],
                "responses": {
                  "200": { "description": "Current user", "content": { "application/json": { "schema": { "$ref": "#/components/schemas/UserPublic" } } } },
                  "401": { "description": "Unauthorized" }
                }
              },
              "put": {
                "tags": ["Users"],
                "summary": "Update current user profile",
                "security": [{ "bearerAuth": [] }],
                "requestBody": {
                  "content": { "application/json": { "schema": { "type": "object", "properties": { "name": { "type": "string" }, "avatar": { "type": "string" } } } } }
                },
                "responses": { "200": { "description": "Updated user", "content": { "application/json": { "schema": { "$ref": "#/components/schemas/UserPublic" } } } } }
              }
            },
            "/users/{userID}": {
              "get": {
                "tags": ["Users"],
                "summary": "Get public profile",
                "parameters": [{ "name": "userID", "in": "path", "required": true, "schema": { "type": "string", "format": "uuid" } }],
                "responses": { "200": { "description": "Public profile", "content": { "application/json": { "schema": { "$ref": "#/components/schemas/UserPublicProfile" } } } } }
              }
            },
            "/users/{userID}/followers": {
              "get": {
                "tags": ["Users"],
                "summary": "Get followers list",
                "parameters": [{ "name": "userID", "in": "path", "required": true, "schema": { "type": "string", "format": "uuid" } }],
                "responses": { "200": { "description": "List of followers", "content": { "application/json": { "schema": { "type": "array", "items": { "$ref": "#/components/schemas/UserPublicProfile" } } } } } }
              }
            },
            "/users/{userID}/following": {
              "get": {
                "tags": ["Users"],
                "summary": "Get following list",
                "parameters": [{ "name": "userID", "in": "path", "required": true, "schema": { "type": "string", "format": "uuid" } }],
                "responses": { "200": { "description": "List of following", "content": { "application/json": { "schema": { "type": "array", "items": { "$ref": "#/components/schemas/UserPublicProfile" } } } } } }
              }
            },
            "/users/{userID}/follow": {
              "post": {
                "tags": ["Users"],
                "summary": "Follow a user",
                "security": [{ "bearerAuth": [] }],
                "parameters": [{ "name": "userID", "in": "path", "required": true, "schema": { "type": "string", "format": "uuid" } }],
                "responses": { "201": { "description": "Followed" }, "400": { "description": "Cannot follow yourself" } }
              },
              "delete": {
                "tags": ["Users"],
                "summary": "Unfollow a user",
                "security": [{ "bearerAuth": [] }],
                "parameters": [{ "name": "userID", "in": "path", "required": true, "schema": { "type": "string", "format": "uuid" } }],
                "responses": { "204": { "description": "Unfollowed" } }
              }
            }
          }
        }
        """
        return Response(status: .ok, headers: ["Content-Type": "application/json"], body: .init(string: spec))
    }

    app.get("docs") { _ -> Response in
        Response(status: .ok, headers: ["Content-Type": "text/html"], body: .init(string: swaggerUIHTML(title: "Identity Service", specURL: "/openapi.json")))
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
            SwaggerUIBundle({
                url: "\(specURL)",
                dom_id: '#swagger-ui',
                presets: [SwaggerUIBundle.presets.apis, SwaggerUIBundle.SwaggerUIStandalonePreset],
                layout: "BaseLayout",
                deepLinking: true
            })
        </script>
    </body>
    </html>
    """
}
