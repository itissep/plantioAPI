import Vapor

func proxyToUpstream(_ req: Request, baseURL: String) async throws -> Response {
    let trimmed = baseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    let path = req.url.path
    guard path.hasPrefix("/v1") else {
        throw Abort(.notFound)
    }
    let suffix = String(path.dropFirst(3))
    var target = "\(trimmed)\(suffix)"
    if let q = req.url.query {
        target += "?\(q)"
    }
    let uri = URI(string: target)

    var headers = HTTPHeaders()
    for name in [HTTPHeaders.Name.authorization, .contentType, .accept, .acceptLanguage] {
        if let v = req.headers[name].first {
            headers.replaceOrAdd(name: name, value: v)
        }
    }

    let maxBytes = 10 * 1024 * 1024
    let bodyBuffer = try await req.body.collect(upTo: maxBytes)
    let clientReq = ClientRequest(method: req.method, url: uri, headers: headers, body: bodyBuffer)
    let clientRes = try await req.client.send(clientReq)

    let response = Response(status: clientRes.status, headers: clientRes.headers)
    if let buffer = clientRes.body {
        response.body = .init(buffer: buffer)
    }
    return response
}

func proxyToIdentity(_ req: Request) async throws -> Response {
    let base = Environment.get("IDENTITY_SERVICE_URL") ?? "http://127.0.0.1:3001"
    return try await proxyToUpstream(req, baseURL: base)
}

func proxyToPlants(_ req: Request) async throws -> Response {
    let base = Environment.get("PLANTS_SERVICE_URL") ?? "http://127.0.0.1:3002"
    return try await proxyToUpstream(req, baseURL: base)
}
