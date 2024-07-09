{ config, lib, ... }:

{
  # SearXNG
  services.searx = {
    redisCreateLocally = true;
    runInUwsgi = true;
    environmentFile = ./searxng.env;
    settings = {
      use_default_settings = true;
      categories_as_tabs = {
        general = [];
        images = [];
        videos = [];
        news = [];
        map = [];
        it = [];
        science = [];
        #files = [];
      };
      server = {
        limiter = true;
        image_proxy = true;
        method = "GET";
      };
      search = {
        autocomplete = "duckduckgo";
        safe_search = 1;
        languages = ["all" "en" "de"];
      };
      ui = {
        static_use_hash = true;
        query_in_title = true;
      };
      engines = [
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
          disabled = false;
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
          categories = ["it" "repos" "files"];
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
          categories = ["videos" "files"];
        }
        {
          name = "mediathekviewweb";
          disabled = false;
          categories = ["videos" "files"];
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
      ];
      outgoing.max_redirects = 30;
    };
  };
  
  # Workaround for https://github.com/NixOS/nixpkgs/issues/292652
  services.uwsgi.instance.vassals = lib.mkIf config.services.searx.enable {
    searx.env = lib.strings.splitString "\n" (lib.readFile config.services.searx.environmentFile);
  };
}
