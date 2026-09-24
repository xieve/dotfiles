{ config, lib, ... }:
let
  inherit (config.virtualisation.oci-containers.containers.trawl) serviceName;
  cfg = config.services.trawl;
  uid = toString config.users.users.trawl.uid;
  gid = toString config.users.groups.trawl.gid;
in
{
  options.services.trawl =
    with lib.types;
    let
      inherit (lib) mkOption;
    in
    {
      port = mkOption {
        type = str;
        default = "6766";
      };
      proxyPort = mkOption {
        type = str;
        default = "6767";
      };
    };
  config = {
    users.users.trawl = {
      isSystemUser = true;
      group = "trawl";
      uid = 959;
    };
    users.groups.trawl.gid = 959;
    virtualisation.oci-containers.containers.trawl = {
      image = "ghcr.io/germondai/trawl";
      ports = [
        "${cfg.port}:8191"
        "${cfg.proxyPort}:8192"
      ];
      volumes = [
        "/var/lib/trawl:/data/proxy-ca"
        "${config.services.redis.servers.trawl.unixSocket}:/run/redis.sock"
      ];
      extraOptions = [
        "--userns=auto:uidmapping=${uid}:${uid}:1,gidmapping=${gid}:${gid}:1"
        "--shm-size=1gb"
        "--memory=3g"
        ''--health-cmd=["curl", "-sf", "http://localhost:8191/health"]''
        "--health-start-period=90s"
        "--health-timeout=10s"
        "--label=io.containers.autoupdate=registry"
      ];
      environment = {
        SESSION_CACHE_DRIVER = "redis";
        REDIS_URL = "redis+unix:///run/redis.sock";
        REDIS_SESSION_TTL_SECONDS = "3600";
        MEMORY_SESSION_CACHE_MAX_ENTRIES = "1000";
        REDIS_CONNECT_TIMEOUT_MS = "5000";
        REDIS_RETRY_DELAY_MS = "5000";
        BROWSER_POOL_SIZE = "1";
        LOG_LEVEL = "info";
        SCRAPE_MIN_TIER = "1";
        BROWSER_MAX_CONTENT_PROCESSES = "2";
        BROWSER_HEADFUL_POOL_SIZE = "0";
        BROWSER_ACQUIRE_TIMEOUT_MS = "15000";
        BROWSER_RECYCLE_AFTER_CONTEXTS = "8";
        BROWSER_STALL_TIMEOUT_MS = "180000";
        BROWSER_CLOSE_TIMEOUT_MS = "10000";
        BROWSER_LAUNCH_TIMEOUT_MS = "90000";
        SCREENSHOT_SETTLE_MS = "3000";
        SCREENSHOT_TIMEOUT_MS = "10000";
        SCREENSHOT_JPEG_QUALITY = "60";
        SCREENSHOT_MAX_BYTES = "4000000";
        BLOCKED_EVIDENCE_MAX_HTML_CHARS = "512000";
        DIAGNOSTICS_MAX_CONSOLE_ENTRIES = "500";
        DIAGNOSTICS_MAX_NETWORK_ENTRIES = "1000";
        DIAGNOSTICS_MAX_STRING_CHARS = "2000";
        DIAGNOSTICS_MAX_TOTAL_CHARS = "1000000";
        DIAGNOSTICS_SIZE_TIMEOUT_MS = "2000";
        REDIRECT_MAX_ENTRIES = "50";
        REDIRECT_MAX_URL_CHARS = "2000";
        REDIRECT_MAX_TOTAL_CHARS = "1000000";
        CAPTURE_MAX_PATTERNS = "10";
        CAPTURE_MAX_RESPONSES = "5";
        CAPTURE_MAX_BODY_BYTES = "5242880";
        CAPTURE_MAX_TOTAL_BYTES = "10485760";
        CAPTURE_MAX_READ_BYTES = "10485760";
        CAPTURE_MAX_METADATA_CHARS = "2000";
        CAPTURE_BODY_TIMEOUT_MS = "5000";
        CAPTURE_SETTLE_MS = "15000";
        CAPTURE_MAX_SETTLE_MS = "60000";
        CAPTURE_IDLE_FLOOR_MS = "5000";
        MHTML_MAX_PARTS = "200";
        MHTML_MAX_PART_BYTES = "2097152";
        MHTML_MAX_TOTAL_CHARS = "8388608";
        MHTML_MAX_INFLIGHT_READS = "32";
        MHTML_MAX_OMISSION_RECORDS = "100";
        STT_URL = "";
        STT_API_KEY = "";
        FFMPEG_PATH = "";
        MCP_ENABLED = "true";
        MCP_ALLOWED_ORIGINS = "";
        SCRAPE_PROXY_SELECTION = "failover";
        PROXY_URL = "";
        PROXY_LIST_FILE = "";
        RESIDENTIAL_PROXY_URL = "";
        RESIDENTIAL_PROXY_LIST_FILE = "";
        MITM_ENABLED = "true";
        MITM_HOST = "0.0.0.0";
        MITM_PORT = "8192";
        MITM_CA_DIR = "/data/proxy-ca";
        MITM_MAX_TIER = "4";
        MITM_ALWAYS_SCRAPE = "false";
        MITM_DEBUG = "false";
      };
    };

    services.redis.servers.trawl = {
      enable = true;
      user = "trawl";
      port = 0;
    };

    systemd.services.${serviceName} =
      let
        wants = [ "redis-trawl.service" ];
      in
      {
        inherit wants;
        after = wants;
      };

    systemd.tmpfiles.settings.trawl."/var/lib/trawl".d = {
      user = "trawl";
      group = "trawl";
    };

    networking.firewall.allowedTCPPorts = [
      (lib.toInt cfg.port)
      (lib.toInt cfg.proxyPort)
    ];
  };
}
