#!/bin/bash
# monitor_swarm.sh - Docker Swarm Service Monitor with Email Notifications

# Configuration
STACK_NAME="${STACK_NAME:-laravel}"
LOG_FILE="/logs/swarm_monitor.log"
EMAIL_TO="${EMAIL_TO:-admin@instasure.com}"
EMAIL_FROM="${EMAIL_FROM:-monitor@instasure.com}"
SMTP_SERVER="${SMTP_SERVER:-smtp.gmail.com}"
SMTP_PORT="${SMTP_PORT:-587}"
SMTP_USER="${SMTP_USER:-your-email@gmail.com}"
SMTP_PASS="${SMTP_PASS:-your-app-password}"

# Service configurations
declare -A SERVICES=(
    ["${STACK_NAME}_app"]="Laravel Application"
    ["${STACK_NAME}_nginx"]="Nginx Web Server"
    ["${STACK_NAME}_mysql"]="MySQL Database"
    ["${STACK_NAME}_redis"]="Redis Cache"
    ["${STACK_NAME}_phpmyadmin"]="PHPMyAdmin"
    ["${STACK_NAME}_node"]="Node.js Assets"
)

declare -A CRITICAL_SERVICES=(
    ["${STACK_NAME}_app"]=1
    ["${STACK_NAME}_nginx"]=1
    ["${STACK_NAME}_mysql"]=1
    ["${STACK_NAME}_redis"]=1
)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Ensure directories exist
mkdir -p /logs
touch "$LOG_FILE"

# Configure SSMTP for email sending
configure_email() {
    if [ -n "$SMTP_USER" ] && [ -n "$SMTP_PASS" ]; then
        cat > /etc/ssmtp/ssmtp.conf << EOF
root=postmaster
mailhub=${SMTP_SERVER}:${SMTP_PORT}
hostname=docker-monitor
AuthUser=${SMTP_USER}
AuthPass=${SMTP_PASS}
UseSTARTTLS=YES
FromLineOverride=YES
EOF

        cat > /etc/ssmtp/revaliases << EOF
root:${EMAIL_FROM}:${SMTP_SERVER}:${SMTP_PORT}
EOF
        chmod 600 /etc/ssmtp/ssmtp.conf
    fi
}

# Logging function with timestamp
log_message() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${timestamp} [${level}] ${message}" | tee -a "$LOG_FILE"
}

# Send email notification
send_email() {
    local subject="$1"
    local body="$2"
    local priority="${3:-normal}"
    
    log_message "INFO" "Sending email notification: $subject"
    
    # Prepare email content
    local email_content=$(cat << EOF
To: ${EMAIL_TO}
From: ${EMAIL_FROM}
Subject: [INSTASURE-MONITOR] $subject
X-Priority: $([ "$priority" = "critical" ] && echo "1" || echo "3")
Content-Type: text/html; charset=UTF-8

<!DOCTYPE html>
<html>
<head>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { background-color: #$([ "$priority" = "critical" ] && echo "dc3545" || echo "28a745"); color: white; padding: 10px; border-radius: 5px; }
        .content { margin: 20px 0; }
        .timestamp { color: #666; font-size: 12px; }
        .service-info { background-color: #f8f9fa; padding: 10px; border-left: 4px solid #007bff; margin: 10px 0; }
        .critical { border-left-color: #dc3545 !important; }
        .warning { border-left-color: #ffc107 !important; }
        .success { border-left-color: #28a745 !important; }
    </style>
</head>
<body>
    <div class="header">
        <h2>🚨 Docker Swarm Monitor Alert</h2>
        <div class="timestamp">Timestamp: $(date '+%Y-%m-%d %H:%M:%S %Z')</div>
    </div>
    <div class="content">
        $body
    </div>
    <hr>
    <p><small>This is an automated message from Docker Swarm Monitor on $(hostname)</small></p>
</body>
</html>
EOF
)

    # Send email using ssmtp
    if command -v ssmtp >/dev/null 2>&1; then
        echo "$email_content" | ssmtp "$EMAIL_TO" 2>/dev/null
        if [ $? -eq 0 ]; then
            log_message "INFO" "Email sent successfully"
        else
            log_message "ERROR" "Failed to send email"
        fi
    else
        log_message "WARNING" "ssmtp not available, email not sent"
    fi
}

# Get service status
get_service_status() {
    local service_name="$1"
    local status=$(docker service ps "$service_name" --format "table {{.Name}}\t{{.CurrentState}}\t{{.DesiredState}}\t{{.Error}}" --no-trunc 2>/dev/null)
    echo "$status"
}

# Get service replicas info
get_service_replicas() {
    local service_name="$1"
    local replicas=$(docker service ls --filter "name=$service_name" --format "{{.Replicas}}" 2>/dev/null)
    echo "$replicas"
}

# Check if service is healthy
is_service_healthy() {
    local service_name="$1"
    local replicas=$(get_service_replicas "$service_name")
    
    if [ -z "$replicas" ]; then
        return 1  # Service doesn't exist
    fi
    
    # Extract running and desired replicas (format: "2/2" or "1/3")
    local running=$(echo "$replicas" | cut -d'/' -f1)
    local desired=$(echo "$replicas" | cut -d'/' -f2)
    
    [ "$running" -eq "$desired" ] && [ "$running" -gt 0 ]
}

# Get detailed service health info
get_service_health_info() {
    local service_name="$1"
    local replicas=$(get_service_replicas "$service_name")
    local tasks=$(docker service ps "$service_name" --format "{{.CurrentState}} - {{.Error}}" --no-trunc 2>/dev/null)
    
    cat << EOF
Service: $service_name
Replicas: $replicas
Recent Tasks:
$tasks

Service Configuration:
$(docker service inspect "$service_name" --format '{{json .Spec.TaskTemplate.RestartPolicy}}' 2>/dev/null | jq -r '.')
EOF
}

# Restart service with detailed logging
restart_service() {
    local service_name="$1"
    local service_description="${SERVICES[$service_name]:-$service_name}"
    
    log_message "WARNING" "Attempting to restart service: $service_name ($service_description)"
    
    # Get service info before restart
    local before_info=$(get_service_health_info "$service_name")
    
    # Force update to restart service
    if docker service update --force "$service_name" >/dev/null 2>&1; then
        log_message "INFO" "Successfully triggered restart for $service_name"
        
        # Wait for service to stabilize
        local attempts=0
        local max_attempts=30
        while [ $attempts -lt $max_attempts ]; do
            sleep 10
            if is_service_healthy "$service_name"; then
                log_message "SUCCESS" "Service $service_name is now healthy"
                
                # Send success notification
                send_email "✅ Service Recovered: $service_description" \
                    "<div class='service-info success'>
                        <h3>Service Successfully Recovered</h3>
                        <p><strong>Service:</strong> $service_description ($service_name)</p>
                        <p><strong>Status:</strong> Healthy and Running</p>
                        <p><strong>Recovery Time:</strong> $((attempts * 10)) seconds</p>
                        <p><strong>Current Replicas:</strong> $(get_service_replicas "$service_name")</p>
                    </div>" "normal"
                
                return 0
            fi
            ((attempts++))
        done
        
        log_message "ERROR" "Service $service_name failed to recover after restart"
        return 1
    else
        log_message "ERROR" "Failed to restart service $service_name"
        return 1
    fi
}

# Scale service up if needed
scale_service() {
    local service_name="$1"
    local desired_replicas="$2"
    
    log_message "INFO" "Scaling service $service_name to $desired_replicas replicas"
    
    if docker service scale "$service_name=$desired_replicas" >/dev/null 2>&1; then
        log_message "SUCCESS" "Successfully scaled $service_name to $desired_replicas replicas"
        return 0
    else
        log_message "ERROR" "Failed to scale service $service_name"
        return 1
    fi
}

# Check node resources
check_node_resources() {
    local node_info=$(docker node ls --format "table {{.Hostname}}\t{{.Status}}\t{{.Availability}}" 2>/dev/null)
    log_message "INFO" "Cluster nodes status:"
    echo "$node_info" | while read line; do
        log_message "INFO" "  $line"
    done
}

# Emergency stack redeploy
emergency_redeploy() {
    log_message "CRITICAL" "🚨 EMERGENCY: Initiating stack redeploy"
    
    send_email "🚨 EMERGENCY: Stack Redeploy Initiated" \
        "<div class='service-info critical'>
            <h3>Emergency Stack Redeploy</h3>
            <p><strong>Reason:</strong> Multiple critical services are down</p>
            <p><strong>Action:</strong> Redeploying entire stack</p>
            <p><strong>Estimated Recovery Time:</strong> 5-10 minutes</p>
            <p><strong>Services Affected:</strong> All services in $STACK_NAME stack</p>
        </div>" "critical"
    
    # Remove and redeploy stack
    if docker stack rm "$STACK_NAME" >/dev/null 2>&1; then
        log_message "INFO" "Stack removed, waiting for cleanup..."
        sleep 60
        
        # Redeploy stack (assumes docker-stack.yml is available)
        if [ -f "/docker-stack.yml" ] || [ -f "./docker-stack.yml" ]; then
            local stack_file=$([ -f "/docker-stack.yml" ] && echo "/docker-stack.yml" || echo "./docker-stack.yml")
            if docker stack deploy -c "$stack_file" "$STACK_NAME" >/dev/null 2>&1; then
                log_message "SUCCESS" "Stack redeployed successfully"
                
                send_email "✅ Emergency Recovery Complete" \
                    "<div class='service-info success'>
                        <h3>Emergency Recovery Complete</h3>
                        <p><strong>Status:</strong> Stack has been successfully redeployed</p>
                        <p><strong>Next Steps:</strong> Services are starting up, monitoring will continue</p>
                    </div>" "normal"
                
                return 0
            else
                log_message "ERROR" "Failed to redeploy stack"
                return 1
            fi
        else
            log_message "ERROR" "docker-stack.yml not found, cannot redeploy"
            return 1
        fi
    else
        log_message "ERROR" "Failed to remove stack"
        return 1
    fi
}

# Main monitoring function
monitor_services() {
    log_message "INFO" "Starting service health check for stack: $STACK_NAME"
    
    local unhealthy_services=()
    local critical_down=0
    local total_issues=0
    
    # Check each service
    for service_name in "${!SERVICES[@]}"; do
        local service_description="${SERVICES[$service_name]}"
        
        if is_service_healthy "$service_name"; then
            log_message "SUCCESS" "✅ $service_description ($service_name) is healthy"
        else
            log_message "ERROR" "❌ $service_description ($service_name) is unhealthy"
            unhealthy_services+=("$service_name")
            ((total_issues++))
            
            # Check if this is a critical service
            if [[ "${CRITICAL_SERVICES[$service_name]}" == "1" ]]; then
                ((critical_down++))
            fi
            
            # Get detailed health info
            local health_info=$(get_service_health_info "$service_name")
            log_message "INFO" "Health details for $service_name:"
            echo "$health_info" | while read line; do
                log_message "INFO" "  $line"
            done
            
            # Send individual service failure notification
            send_email "🔥 Service Down: $service_description" \
                "<div class='service-info critical'>
                    <h3>Service Failure Detected</h3>
                    <p><strong>Service:</strong> $service_description ($service_name)</p>
                    <p><strong>Status:</strong> Unhealthy/Down</p>
                    <p><strong>Replicas:</strong> $(get_service_replicas "$service_name")</p>
                    <p><strong>Action:</strong> Attempting automatic restart...</p>
                    <pre>$health_info</pre>
                </div>" "critical"
            
            # Attempt to restart the service
            if restart_service "$service_name"; then
                log_message "SUCCESS" "Service $service_name recovered successfully"
                ((total_issues--))
            else
                log_message "ERROR" "Failed to recover service $service_name"
            fi
        fi
    done
    
    # Check for emergency conditions
    if [ $critical_down -ge 2 ]; then
        log_message "CRITICAL" "Multiple critical services are down, initiating emergency recovery"
        emergency_redeploy
    elif [ $total_issues -gt 0 ]; then
        log_message "WARNING" "Some services are still unhealthy after recovery attempts"
        
        # Send summary notification
        local unhealthy_list=$(printf '%s\n' "${unhealthy_services[@]}")
        send_email "⚠️  Service Issues Summary" \
            "<div class='service-info warning'>
                <h3>Service Health Summary</h3>
                <p><strong>Unhealthy Services:</strong> $total_issues</p>
                <p><strong>Critical Services Down:</strong> $critical_down</p>
                <p><strong>Services with Issues:</strong></p>
                <ul>$(for service in "${unhealthy_services[@]}"; do echo "<li>${SERVICES[$service]} ($service)</li>"; done)</ul>
            </div>" "critical"
    else
        log_message "SUCCESS" "All services are healthy"
    fi
    
    # Log cluster resource status
    check_node_resources
    
    return $total_issues
}

# Cleanup old log files
cleanup_logs() {
    if [ -f "$LOG_FILE" ]; then
        # Keep only last 5000 lines
        tail -5000 "$LOG_FILE" > "${LOG_FILE}.tmp" && mv "${LOG_FILE}.tmp" "$LOG_FILE"
    fi
}

# Main execution
main() {
    log_message "INFO" "Docker Swarm Monitor started - Version 2.0"
    
    # Configure email if not already done
    configure_email
    
    # Cleanup old logs
    cleanup_logs
    
    # Run monitoring
    if monitor_services; then
        log_message "INFO" "Monitoring cycle completed successfully"
    else
        log_message "WARNING" "Monitoring cycle completed with issues"
    fi
    
    log_message "INFO" "Next check in 60 seconds..."
}

# Signal handlers
cleanup() {
    log_message "INFO" "Monitor shutting down gracefully"
    exit 0
}

trap cleanup SIGTERM SIGINT

# Run the main function
main "$@"
