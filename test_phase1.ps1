# FreshGuard AI - Phase 1 Verification Test Suite
$baseUrl = "http://localhost:8080/api"
$results = @()

function Record-Test($name, $passed, $details) {
    $status = if ($passed) { "PASS" } else { "FAIL" }
    Write-Host "[$status] $name : $details" -ForegroundColor $(if ($passed) { "Green" } else { "Red" })
    $script:results += [PSCustomObject]@{
        TestName = $name
        Status   = $status
        Details  = $details
    }
}

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " STARTING FRESHGUARD AI PHASE 1 TEST SUITE" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

# 1. Admin login succeeds
$adminToken = $null
try {
    $resp = Invoke-RestMethod -Uri "$baseUrl/auth/login" -Method Post -ContentType "application/json" -Body '{"email":"admin@freshguard.local","password":"Admin@123"}'
    if ($resp.token -and $resp.role -eq "ADMIN") {
        $adminToken = $resp.token
        Record-Test "1. Admin Login" $true "Role is ADMIN, Token length=$($resp.token.Length)"
    } else {
        Record-Test "1. Admin Login" $false "Unexpected response: $($resp | ConvertTo-Json)"
    }
} catch {
    Record-Test "1. Admin Login" $false $_.Exception.Message
}

# 2. Manager login succeeds
$managerToken = $null
try {
    $resp = Invoke-RestMethod -Uri "$baseUrl/auth/login" -Method Post -ContentType "application/json" -Body '{"email":"manager@freshguard.local","password":"Manager@123"}'
    if ($resp.token -and $resp.role -eq "STORE_MANAGER") {
        $managerToken = $resp.token
        Record-Test "2. Manager Login" $true "Role is STORE_MANAGER, Store=$($resp.storeName)"
    } else {
        Record-Test "2. Manager Login" $false "Unexpected response: $($resp | ConvertTo-Json)"
    }
} catch {
    Record-Test "2. Manager Login" $false $_.Exception.Message
}

# 3. Employee login succeeds
$employeeToken = $null
try {
    $resp = Invoke-RestMethod -Uri "$baseUrl/auth/login" -Method Post -ContentType "application/json" -Body '{"email":"employee@freshguard.local","password":"Employee@123"}'
    if ($resp.token -and $resp.role -eq "EMPLOYEE") {
        $employeeToken = $resp.token
        Record-Test "3. Employee Login" $true "Role is EMPLOYEE, Store=$($resp.storeName)"
    } else {
        Record-Test "3. Employee Login" $false "Unexpected response: $($resp | ConvertTo-Json)"
    }
} catch {
    Record-Test "3. Employee Login" $false $_.Exception.Message
}

# 4. Wrong password is rejected
try {
    $resp = Invoke-RestMethod -Uri "$baseUrl/auth/login" -Method Post -ContentType "application/json" -Body '{"email":"admin@freshguard.local","password":"WrongPassword123!"}'
    Record-Test "4. Wrong Password Rejected" $false "Expected 401 but received HTTP 200"
} catch {
    $statusCode = $_.Exception.Response.StatusCode.value__
    if ($statusCode -eq 401) {
        Record-Test "4. Wrong Password Rejected" $true "HTTP 401 Unauthorized received correctly"
    } else {
        Record-Test "4. Wrong Password Rejected" $false "Received unexpected status code: $statusCode"
    }
}

# 5. JWT token is generated
if ($adminToken -and $adminToken.Split('.').Count -eq 3) {
    Record-Test "5. JWT Token Generation" $true "Valid 3-part header.payload.signature structure confirmed"
} else {
    Record-Test "5. JWT Token Generation" $false "Token is invalid or missing"
}

# 6. JWT is accepted on protected endpoints
try {
    $headers = @{ Authorization = "Bearer $managerToken" }
    $prods = Invoke-RestMethod -Uri "$baseUrl/products" -Method Get -Headers $headers
    if ($prods -ne $null) {
        Record-Test "6. JWT Accepted on Protected Endpoints" $true "Retrieved $($prods.Count) products using Bearer token"
    } else {
        Record-Test "6. JWT Accepted on Protected Endpoints" $false "Empty response"
    }
} catch {
    Record-Test "6. JWT Accepted on Protected Endpoints" $false $_.Exception.Message
}

# 7. Admin-only endpoint rejects non-admin users
try {
    $headers = @{ Authorization = "Bearer $employeeToken" }
    $resp = Invoke-RestMethod -Uri "$baseUrl/admin/analytics" -Method Get -Headers $headers
    Record-Test "7. Admin Endpoint Rejects Non-Admin" $false "Employee should have been forbidden"
} catch {
    $statusCode = $_.Exception.Response.StatusCode.value__
    if ($statusCode -eq 403) {
        Record-Test "7. Admin Endpoint Rejects Non-Admin" $true "HTTP 403 Forbidden returned for Employee accessing Admin endpoint"
    } else {
        Record-Test "7. Admin Endpoint Rejects Non-Admin" $false "Received status: $statusCode instead of 403"
    }
}

# 8. Registration works
$uniqueId = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
$regEmail = "staff_$uniqueId@freshguard.local"
$regPassword = "Password@123"
try {
    $regBody = @{
        name = "Staff Member"
        email = $regEmail
        phone = "9123456780"
        role = "EMPLOYEE"
        storeName = "Downtown Supermarket"
        password = $regPassword
        confirmPassword = $regPassword
    } | ConvertTo-Json

    $regResp = Invoke-RestMethod -Uri "$baseUrl/auth/register" -Method Post -ContentType "application/json" -Body $regBody
    if ($regResp.token -and $regResp.email -eq $regEmail) {
        Record-Test "8. Registration Works" $true "Successfully registered $regEmail with token and role $($regResp.role)"
    } else {
        Record-Test "8. Registration Works" $false "Invalid response: $($regResp | ConvertTo-Json)"
    }
} catch {
    Record-Test "8. Registration Works" $false $_.Exception.Message
}

# 9. Duplicate email is rejected
try {
    $dupBody = @{
        name = "Staff Duplicate"
        email = $regEmail
        phone = "9123456781"
        role = "EMPLOYEE"
        storeName = "Downtown Supermarket"
        password = $regPassword
        confirmPassword = $regPassword
    } | ConvertTo-Json

    $dupResp = Invoke-RestMethod -Uri "$baseUrl/auth/register" -Method Post -ContentType "application/json" -Body $dupBody
    Record-Test "9. Duplicate Email Rejected" $false "Duplicate email was allowed!"
} catch {
    $statusCode = $_.Exception.Response.StatusCode.value__
    if ($statusCode -eq 400) {
        Record-Test "9. Duplicate Email Rejected" $true "HTTP 400 Bad Request returned for duplicate email"
    } else {
        Record-Test "9. Duplicate Email Rejected" $false "Status code: $statusCode"
    }
}

# 10. Invalid email is rejected
try {
    $invalidEmailBody = @{
        name = "Invalid Email User"
        email = "notanemailaddress"
        phone = "9123456782"
        role = "EMPLOYEE"
        storeName = "Downtown Supermarket"
        password = "Password@123"
        confirmPassword = "Password@123"
    } | ConvertTo-Json

    $resp = Invoke-RestMethod -Uri "$baseUrl/auth/register" -Method Post -ContentType "application/json" -Body $invalidEmailBody
    Record-Test "10. Invalid Email Rejected" $false "Invalid email was allowed!"
} catch {
    $statusCode = $_.Exception.Response.StatusCode.value__
    if ($statusCode -eq 400) {
        Record-Test "10. Invalid Email Rejected" $true "HTTP 400 Bad Request returned for invalid email format"
    } else {
        Record-Test "10. Invalid Email Rejected" $false "Status code: $statusCode"
    }
}

# 11. Invalid password is rejected
try {
    $shortPassBody = @{
        name = "Short Pass User"
        email = "shortpass_$uniqueId@freshguard.local"
        phone = "9123456783"
        role = "EMPLOYEE"
        storeName = "Downtown Supermarket"
        password = "123"
        confirmPassword = "123"
    } | ConvertTo-Json

    $resp = Invoke-RestMethod -Uri "$baseUrl/auth/register" -Method Post -ContentType "application/json" -Body $shortPassBody
    Record-Test "11. Invalid Password Rejected" $false "Short password was allowed!"
} catch {
    $statusCode = $_.Exception.Response.StatusCode.value__
    if ($statusCode -eq 400) {
        Record-Test "11. Invalid Password Rejected" $true "HTTP 400 Bad Request returned for password < 6 chars"
    } else {
        Record-Test "11. Invalid Password Rejected" $false "Status code: $statusCode"
    }
}

# 12. MongoDB data is actually persisted
try {
    $newLoginResp = Invoke-RestMethod -Uri "$baseUrl/auth/login" -Method Post -ContentType "application/json" -Body (@{ email = $regEmail; password = $regPassword } | ConvertTo-Json)
    if ($newLoginResp.token -and $newLoginResp.email -eq $regEmail) {
        Record-Test "12. MongoDB Persistence" $true "Newly registered user successfully logged in with persisted DB record"
    } else {
        Record-Test "12. MongoDB Persistence" $false "Could not login with newly registered user"
    }
} catch {
    Record-Test "12. MongoDB Persistence" $false $_.Exception.Message
}

# 13. Admin analytics returns real database values
try {
    $headers = @{ Authorization = "Bearer $adminToken" }
    $analytics = Invoke-RestMethod -Uri "$baseUrl/admin/analytics" -Method Get -Headers $headers
    if ($analytics.totalRegisteredUsers -gt 0 -and $analytics.totalProducts -gt 0) {
        Record-Test "13. Admin Analytics Real DB Values" $true "Users=$($analytics.totalRegisteredUsers), Products=$($analytics.totalProducts), Expired=$($analytics.expiredProducts), NearExpiry=$($analytics.nearExpiryProducts), LowStock=$($analytics.lowStockProducts)"
    } else {
        Record-Test "13. Admin Analytics Real DB Values" $false "Values returned 0 or null"
    }
} catch {
    Record-Test "13. Admin Analytics Real DB Values" $false $_.Exception.Message
}

# 14. System health returns real server/database/API status
try {
    $headers = @{ Authorization = "Bearer $adminToken" }
    $health = Invoke-RestMethod -Uri "$baseUrl/admin/system-health" -Method Get -Headers $headers
    if ($health.serverStatus -eq "UP" -and $health.mongoStatus -like "*CONNECTED*") {
        Record-Test "14. System Health Real Status" $true "Server=$($health.serverStatus), Mongo=$($health.mongoStatus), JVM Mem Used=$($health.jvmMemoryUsedMb)MB, Uptime=$($health.uptimeSeconds)s"
    } else {
        Record-Test "14. System Health Real Status" $false "Unexpected health response: $($health | ConvertTo-Json)"
    }
} catch {
    Record-Test "14. System Health Real Status" $false $_.Exception.Message
}

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " TEST SUMMARY" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
$script:results | Format-Table -AutoSize
