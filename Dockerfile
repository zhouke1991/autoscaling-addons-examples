# Build stage
FROM vcf-kubernetes-service-dev-docker-local.usw5.packages.broadcom.com/golang:1.24 AS builder

WORKDIR /app

# Copy go mod files
COPY go.mod go.sum ./

# Download dependencies
RUN go mod download

# Copy source code
COPY . .

# Build the application
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -a -installsuffix cgo -o main .

# Final stage
FROM vcf-kubernetes-service-dev-docker-local.usw5.packages.broadcom.com/alpine:3.23.2

RUN apk --no-cache add ca-certificates

WORKDIR /root/

# Copy the binary from builder
COPY --from=builder /app/main .

# Expose port
EXPOSE 8080

# Run the application
CMD ["./main"]

