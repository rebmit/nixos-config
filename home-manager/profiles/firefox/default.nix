# Portions of this file are sourced from
# https://github.com/NickCao/flakes/blob/3b03efb676ea602575c916b2b8bc9d9cd13b0d85/nixos/mainframe/home.nix (MIT License)
# https://github.com/llakala/nixos/blob/b3c5fbde5a5f78c91ee658250f9b42418b73a7b7/apps/gui/firefox.nix (MIT License)
# https://gist.github.com/swwind/fe691c06ea53f89e02eb194df6144afa
{
  lib,
  pkgs,
  ...
}:
{
  programs.firefox.enable = true;

  programs.firefox.policies = {
    AutofillAddressEnabled = false;
    AutofillCreditCardEnabled = false;
    DisableAccounts = true;
    DisableFirefoxAccounts = true;
    DisableFirefoxStudies = true;
    DisablePocket = true;
    DisableTelemetry = true;
    EnableTrackingProtection = {
      Value = true;
      Locked = true;
      Cryptomining = true;
      Fingerprinting = true;
      EmailTracking = true;
    };
    FirefoxHome = {
      Search = true;
      TopSites = false;
      SponsoredTopSites = false;
      Highlights = false;
      Pocket = false;
      SponsoredPocket = false;
      Snippets = false;
      Locked = true;
    };
    FirefoxSuggest = {
      WebSuggestions = false;
      SponsoredSuggestions = false;
      ImproveSuggest = false;
      Locked = true;
    };
    PasswordManagerEnabled = false;
    PostQuantumKeyAgreementEnabled = true;
    SearchSuggestEnabled = false;
  };

  programs.firefox.policies.ExtensionSettings = {
    "{446900e4-71c2-419f-a6a7-df9c091e268b}" = {
      installation_mode = "force_installed";
      install_url = "https://addons.mozilla.org/firefox/downloads/latest/bitwarden-password-manager/latest.xpi";
    };
    "uBlock0@raymondhill.net" = {
      installation_mode = "force_installed";
      install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
    };
    "addon@darkreader.org" = {
      installation_mode = "force_installed";
      install_url = "https://addons.mozilla.org/firefox/downloads/latest/darkreader/latest.xpi";
    };
    "@testpilot-containers" = {
      installation_mode = "force_installed";
      install_url = "https://addons.mozilla.org/firefox/downloads/latest/multi-account-containers/latest.xpi";
    };
  };

  programs.firefox.policies.Preferences = {
    "browser.urlbar.autoFill.adaptiveHistory.enabled" = true;
    "browser.tabs.closeWindowWithLastTab" = false;
    "browser.tabs.inTitlebar" = 0;
    "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
    "media.ffmpeg.vaapi.enabled" = true;
  };

  programs.firefox.policies.Preferences."browser.uiCustomization.state" = builtins.toJSON {
    placements = {
      widget-overflow-fixed-list = [ ];
      nav-bar = [
        "back-button"
        "forward-button"
        "stop-reload-button"
        "sidebar-button"
        "urlbar-container"
        "downloads-button"
        "unified-extensions-button"
        "fxa-toolbar-menu-button"
      ];
      toolbar-menubar = [ "menubar-items" ];
      TabsToolbar = [ ];
      vertical-tabs = [ "tabbrowser-tabs" ];
      PersonalToolbar = [ "personal-bookmarks" ];
    };
    currentVersion = 20;
    newElementCount = 0;
  };

  programs.firefox.profiles.default = {
    isDefault = true;
    search = {
      force = true;
      default = "google";
    };
    containersForce = true;
    containers = {
      "Domestic" = {
        id = 1;
        color = "green";
        icon = "fingerprint";
      };
    };
    settings = {
      "sidebar.revamp" = true;
      "sidebar.verticalTabs" = true;
    };
    userChrome = ''
      #tabbrowser-tabbox {
        padding-right: var(--space-small);
        padding-bottom: var(--space-small);
        outline: none !important;
        box-shadow: none !important;
        background-color: var(--toolbar-bgcolor);
        :root[inDOMFullscreen] & {    
          padding-right: 0;
          padding-bottom: 0;
        }
      }

      #tabbrowser-tabpanels {
        border-radius: var(--border-radius-medium);
        box-shadow: var(--content-area-shadow);
        overflow: hidden;
        :root[inDOMFullscreen] & {
          border-radius: 0;
        }
      }

      .browser-toolbox-background {
        background-color: var(--toolbar-bgcolor) !important;
      }
    '';
  };

  programs.firefox.profiles.default.search.engines = {
    "bing".metaData.hidden = true;
    "ebay".metaData.hidden = true;
    "amazondotcom-us".metaData.hidden = true;
    "wikipedia".metaData.hidden = true;
    "Nixpkgs" = {
      urls = lib.singleton {
        template = "https://search.nixos.org/packages";
        params = lib.attrsToList {
          "channel" = "unstable";
          "query" = "{searchTerms}";
        };
      };
      icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
      definedAliases = [ "@np" ];
    };
    "NixOS Options" = {
      urls = lib.singleton {
        template = "https://search.nixos.org/options";
        params = lib.attrsToList {
          "channel" = "unstable";
          "query" = "{searchTerms}";
        };
      };
      icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
      definedAliases = [ "@no" ];
    };
    "Home Manager Options" = {
      urls = lib.singleton {
        template = "https://home-manager-options.extranix.com";
        params = lib.attrsToList {
          "release" = "master";
          "query" = "{searchTerms}";
        };
      };
      icon = "https://home-manager-options.extranix.com/images/favicon.png";
      definedAliases = [ "@ho" ];
    };
  };

  preservation.preserveAt."/persist".directories = [ ".mozilla" ];

  programs.niri.browser = lib.mkDefault [ "firefox" ];
}
