FROM swift:6.0-jammy as build

WORKDIR /app

COPY Package.swift Package.resolved* ./
RUN swift package resolve

COPY Sources ./Sources
COPY Tests ./Tests

RUN swift build --configuration release --static-swift-stdlib --product NotificationsService

FROM ubuntu:22.04

RUN groupadd -g 1000 vapor && useradd -m -u 1000 -g vapor vapor

WORKDIR /run

COPY --from=build /app/.build/release/NotificationsService /run/NotificationsService

USER vapor

ENV PORT=3004
EXPOSE 3004

CMD ["/run/NotificationsService"]

