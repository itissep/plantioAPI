FROM swift:6.0-jammy as build

WORKDIR /app

COPY Package.swift Package.resolved* ./
RUN swift package resolve

# Нужны и Tests: иначе SPM может пометить тестовый таргет как «пересекающийся» с Sources
COPY Sources ./Sources
COPY Tests ./Tests

RUN swift build --configuration release --static-swift-stdlib --product IdentityService

FROM ubuntu:22.04

RUN groupadd -g 1000 vapor && useradd -m -u 1000 -g vapor vapor

WORKDIR /run

COPY --from=build /app/.build/release/IdentityService /run/IdentityService

USER vapor

ENV PORT=3001
EXPOSE 3001

CMD ["/run/IdentityService"]

