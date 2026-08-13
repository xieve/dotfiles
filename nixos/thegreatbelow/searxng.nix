{
  config,
  lib,
  pkgs,
  searxng-src,
  ...
}:

let
  cfg = config.services.searx;

  settingsFile = pkgs.writeText "settings.yml" (
    builtins.toJSON (removeAttrs cfg.settings [ "redis" ])
  );
  secrets = {
    SEARXNG_SECRET = ''
      Whxqht+dQJax1aZeCGLxmiAAAAABAAAADAAAABAAAAABnLul6+Hl+5IZ8W8AAAAARFCOa \
      nk/jjnt7bvvHO/zHqKyNfhAyMDDV1WXk8zXEGy8oBx8h/64XfUotfOl/ObMnfWLZNCbIS \
      N1NV190pDK3XcC6qs2FF7rINK14Ujk8+9+tC0BXQaCzFB2ACLRL9FvSNYB+esyzNpkCzF \
      Fr9opeQcJsk2ouc2C
    '';
    EXA_API_KEY = ''
      Whxqht+dQJax1aZeCGLxmiAAAAABAAAADAAAABAAAAB2j3+cJWHnVwHXhd4AAAAAioNpu \
      Y4km5OKrJRbi70uKAmRd7wuYc2FJHLkCANzkQ0r+pU38KghnWJb8m4NY4RK4kmOOrNB8S \
      1Jcw1jNbvE0RnsFtGIbfNtu87+oL/AYGoFquRn
    '';
  };
in
{
  systemd.services.searx-init = {
    script = lib.mkForce ''
      cd /run/searx

      # write NixOS settings as JSON
      (
        umask 077
        ${lib.concatMapAttrsStringSep "\n" (
          name: _: ''export ${name}="$(cat "$CREDENTIALS_DIRECTORY"/${name})"''
        ) secrets}
        ${pkgs.envsubst}/bin/envsubst < ${settingsFile} > settings.yml
      )
    '';
    serviceConfig = {
      SetCredentialEncrypted = lib.mapAttrsToList (name: value: "${name}:${value}") secrets;
    };
  };

  services.searx = {
    redisCreateLocally = true;
    configureUwsgi = true;
    uwsgiConfig = {
      disable-logging = true;
      http = "[::1]:41318";
    };
    # We need to call toPythonModule again since we're changing deps
    package = pkgs.python3Packages.toPythonModule (
      pkgs.searxng.overridePythonAttrs (
        final: prev: {
          src = searxng-src;
          dependencies = prev.dependencies ++ [ pkgs.python3Packages.curl-cffi ];
        }
      )
    );
    settings = {
      use_default_settings = true;
      categories_as_tabs = {
        general = [ ];
        images = [ ];
        videos = [ ];
        news = [ ];
        map = [ ];
        it = [ ];
        science = [ ];
        #files = [];
      };
      server = {
        secret_key = "$SEARXNG_SECRET";
        limiter = true;
        method = "GET";
        public_instance = true;
      };
      search = {
        autocomplete = "duckduckgo";
        safe_search = 0;
        default_lang = "all";
        languages = [
          "all"
          "en"
          "de"
        ];
      };
      ui = {
        static_use_hash = true;
        query_in_title = true;
      };
      outgoing = {
        max_redirects = 30;
        enable_http2 = true;
      };
      engines = [
        {
          name = "yacy";
          disabled = false;
          base_url = [
            "https://yacy.xieve.net"
          ];
          weight = 0.7;
        }
        {
          name = "wiby";
          disabled = false;
          weight = 0.6;
        }
        {
          name = "exaapi";
          api_key = "$EXA_API_KEY";
          inactive = false;
          disabled = true;
          weight = 1.5;
        }
        {
          name = "wolframalpha";
          disabled = false;
        }
        {
          name = "yahoo";
          disabled = false;
        }
        {
          name = "ddg definitions";
          disabled = false;
        }
        {
          name = "apple maps";
          disabled = false;
        }
        {
          name = "google";
          shortcut = "g";
        }
        {
          name = "wikipedia";
          shortcut = "w";
        }
        {
          name = "bing";
          disabled = true;
        }
        {
          name = "deviantart";
          disabled = true;
        }
        {
          name = "ebay";
          engine = "ebay";
          shortcut = "ede";
          base_url = "https://ebay.de";
          timeout = 8;
          categories = "shopping";
        }
        {
          name = "apk mirror";
          disabled = false;
          weight = 0.5;
        }
        {
          name = "fdroid";
          disabled = false;
          weight = 0.5;
        }
        {
          name = "github";
          categories = [
            "it"
            "repos"
            "files"
          ];
        }
        {
          name = "filepursuit";
          shortcut = "fp";
          categories = "files";
          engine = "xpath";
          search_url = "https://filepursuit.com/pursuit?q={query}&type=all&startrow={pageno}";
          paging = true;
          page_size = 50;
          first_page_num = 0;
          url_xpath = "//div[contains(@class, \"file-post-item\")]/div/a[div[contains(@class, \"file-post-item-header\")]]/@href";
          title_xpath = "//div[contains(@class, \"file-post-item-header\")]/h5/text()";
          content_xpath = "//div[contains(@class, \"file-post-item-body\")]/div/a/text()";
        }
        {
          name = "peertube";
          disabled = false;
          categories = [
            "videos"
            "files"
          ];
        }
        {
          name = "mediathekviewweb";
          disabled = false;
          categories = [
            "videos"
            "files"
          ];
        }
        {
          name = "library genesis";
          disabled = false;
          weight = 0.5;
        }
        {
          name = "1337x";
          categories = "torrents";
          disabled = false;
        }
        {
          name = "btdigg";
          categories = "torrents";
        }
        {
          name = "kickass";
          categories = "torrents";
          disabled = false;
        }
        {
          name = "nyaa";
          categories = "torrents";
        }
        {
          name = "piratebay";
          categories = "torrents";
        }
        {
          name = "solidtorrents";
          categories = "torrents";
        }
        {
          name = "tokyotoshokan";
          categories = "torrents";
        }
        {
          name = "wallhaven";
          disabled = true;
        }
        {
          name = "library of congress";
          disabled = true;
        }
        {
          name = "artic";
          disabled = true;
        }
        {
          name = "flickr";
          disabled = true;
        }
        {
          name = "unsplash";
          disabled = true;
        }
        {
          name = "wikicommons.images";
          disabled = true;
        }
        {
          name = "openverse";
          disabled = true;
        }
        {
          name = "lucide";
          disabled = true;
        }
        {
          name = "devicons";
          disabled = true;
        }
      ];
    };
  };
}
