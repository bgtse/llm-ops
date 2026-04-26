$env:ENV_OVERRIDE = ""
$args_list = @()

# Parse arguments
for ($i = 0; $i -lt $args.Count; $i++) {
    if ($args[$i] -eq "--env") {
        if ($i + 1 -lt $args.Count -and $args[$i+1] -notlike "--*") {
            $env:ENV_OVERRIDE = $args[$i+1]
            $i++
        } else {
            Write-Error "Error: --env requires a non-empty argument"
            exit 1
        }
    } else {
        $args_list += $args[$i]
    }
}

$script_dir = Split-Path -Parent $MyInvocation.MyCommand.Definition
if ($null -eq $script_dir) { $script_dir = Get-Location }

if ($env:ENV_OVERRIDE) {
    $env_file = Join-Path $script_dir ".env.$($env:ENV_OVERRIDE)"
} else {
    $env_file = Join-Path $script_dir ".env"
}

if (-not (Test-Path $env_file)) {
    Write-Error "Environment file not found: $env_file"
    exit 1
}

# Load environment variables from the file into a local hashtable
$loaded_env = @{}
Get-Content $env_file | ForEach-Object {
    if ($_ -match '^([^=]+)=(.*)$') {
        $name = $matches[1].Trim()
        $value = $matches[2].Trim()
        # Remove quotes if present
        if ($value.StartsWith('"') -and $value.EndsWith('"')) {
            $value = $value.Substring(1, $value.Length - 2)
        }
        $loaded_env[$name] = $value
    }
}

# Helper to set environment variables for the current session
function Set-EnvVar {
    param([string]$name, [string]$value)
    if ($null -ne $value) {
        Set-Item -Path "Env:\$name" -Value $value
    }
}

# Apply loaded environment variables to the current process environment
foreach ($key in $loaded_env.Keys) {
    Set-EnvVar -name $key -value $loaded_env[$key]
}

$proxy_process = $null

try {
    if ($loaded_env.ContainsKey("MC_PROXY_PORT") -and $env:ENV_OVERRIDE) {
        if (-not $env:ANTHROPIC_BASE_URL) { Write-Error "ANTHROPIC_BASE_URL is required"; exit 1 }
        if (-not $env:MC_PROXY_PORT) { Write-Error "MC_PROXY_PORT is required"; exit 1 }
        if (-not $env:MC_CF_ID) { Write-Error "MC_CF_ID is required"; exit 1 }
        if (-not $env:MC_CF_SECRET) { Write-Error "MC_CF_SECRET is required"; exit 1 }

        $uri = [System.Uri]$env:ANTHROPIC_BASE_URL
        $host_name = $uri.Host
        $port = $env:MC_PROXY_PORT
        $cf_id = $env:MC_CF_ID
        $cf_secret = $env:MC_CF_SECRET

        # Start Node.js proxy in the background
        $node_script = @"
const http = require('http');
const https = require('https');

const HOST = '$host_name';
const PORT = $port;
const CF_ID = '$cf_id';
const CF_SECRET = '$cf_secret';

const server = http.createServer((req, res) => {
  const options = {
    hostname: HOST,
    port: 443,
    path: req.url,
    method: req.method,
    servername: HOST,
    headers: {
      ...req.headers,
      host: HOST,
      'CF-Access-Client-Id': CF_ID,
      'CF-Access-Client-Secret': CF_SECRET,
    },
  };

  const proxy = https.request(options, (r) => {
    const headers = { ...r.headers };
    delete headers['transfer-encoding'];
    res.writeHead(r.statusCode, headers);
    r.pipe(res);
  });

  proxy.on('error', () => {
    if (!res.headersSent) res.writeHead(502);
    res.end('Bad gateway');
  });

  req.pipe(proxy);
});

server.listen(PORT);
"@

        $proxy_process = Start-Process node -ArgumentList "-e `"$node_script`"" -PassThru -NoNewWindow

        Start-Sleep -Seconds 1
        $env:ANTHROPIC_BASE_URL = "http://127.0.0.1:$port"
    } else {
        if (-not $env:ANTHROPIC_BASE_URL) { Write-Error "ANTHROPIC_BASE_URL is required"; exit 1 }
    }

    # Fetch model name using Invoke-RestMethod
    $models_json = Invoke-RestMethod -Uri "$($env:ANTHROPIC_BASE_URL)/v1/models"
    $env:ANTHROPIC_MODEL = $models_json.models[0].name

    # Run claude
    if ($args_list.Count -gt 0) {
        & claude @args_list
    } else {
        & claude
    }
}
finally {
    if ($proxy_process) {
        Stop-Process -Id $proxy_process.Id -Force -ErrorAction SilentlyContinue
    }
}
