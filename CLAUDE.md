# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Windmill starter repository that provides a Docker Compose setup for running Windmill - an open-source workflow automation platform. The repository contains configuration for a complete Windmill deployment with database, workers, and web interface.

## Common Commands

### Starting the Application
```bash
docker compose up
```
Starts all Windmill services including PostgreSQL database, server, workers, and Caddy reverse proxy.

### Starting in Background
```bash
docker compose up -d
```
Starts services in detached mode.

### Stopping Services
```bash
docker compose down
```
Stops all running services.

### Viewing Logs
```bash
docker compose logs -f [service_name]
```
View logs for all services or a specific service (e.g., windmill_server, windmill_worker).

### Updating Images
```bash
docker compose pull
```
Pull latest images for all services.

## Architecture

### Core Services
- **db**: PostgreSQL 16 database with health checks
- **windmill_server**: Main Windmill server (port 8000) handling API and web interface
- **windmill_worker**: General-purpose workers (3 replicas) for job execution with Docker socket access
- **windmill_worker_native**: Specialized workers for lightweight "native" jobs
- **windmill_indexer**: Full-text search service (disabled by default, EE feature)
- **lsp**: Language Server Protocol service for code intelligence
- **multiplayer**: Real-time collaboration service (disabled, EE feature)
- **caddy**: Reverse proxy handling HTTP routing and load balancing

### Configuration
- Environment variables defined in `.env` file
- Database connection string: `postgres://postgres:changeme@db/windmill`
- Default image: `ghcr.io/windmill-labs/windmill:main`
- Enterprise Edition available as `ghcr.io/windmill-labs/windmill-ee:main`

### Networking
- Caddy serves on port 80 (configurable)
- SMTP proxy on port 25
- All internal services communicate via Docker network
- LSP WebSocket traffic routed to `/ws/*`
- Optional HTTPS support via custom certificates

### Storage
- Database data persisted in `db_data` volume
- Worker dependency cache in `worker_dependency_cache` volume
- Shared worker logs in `worker_logs` volume
- Search index data in `windmill_index` volume (if enabled)

## Development Notes

- Workers have Docker socket mounted for container execution
- Memory limits: 2GB per worker
- CPU limits: 1 CPU per worker
- Log rotation configured via environment variables
- Health checks implemented for database dependency management