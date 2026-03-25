FROM swift:6.0-jammy as build

WORKDIR /app

COPY Package.swift ./
COPY Sources ./Sources

RUN swift build --configuration release --static-swift-stdlib

FROM ubuntu:22.04

RUN groupadd -g 1000 vapor && useradd -m -u 1000 -g vapor vapor

WORKDIR /run

COPY --from=build /app/.build/release/APIGateway /run/APIGateway

USER vapor

ENV PORT=3000
EXPOSE 3000

CMD ["/run/APIGateway"]

