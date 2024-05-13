{ config, lib, pkgs, ... }:

let
  wwwRoot = ./wwwroot;
  phpPkgNames = [ "php80" "php81" "php82" ];

  phpPools =
    let
      f = phpPkgName: {
        name = phpPkgName;
        value = {
          user = "php";
          phpPackage = pkgs.${phpPkgName};
          settings = {
            "listen.owner" = config.services.nginx.user;
            "pm" = "dynamic";
            "pm.max_children" = 32;
            "pm.max_requests" = 500;
            "pm.start_servers" = 2;
            "pm.min_spare_servers" = 1;
            "pm.max_spare_servers" = 5;
          };
        };
      };
    in
      builtins.listToAttrs (map f phpPkgNames);

  nginxLocations =
    let
      f = phpPkgName: {
        name = "/${phpPkgName}";
        value = {
          root = wwwRoot;
          extraConfig = ''
            rewrite ^/${phpPkgName}(.*)$ /$1 break;

            include ${pkgs.nginx}/conf/fastcgi_params;
            include ${pkgs.nginx}/conf/fastcgi.conf;
            fastcgi_pass  unix:${config.services.phpfpm.pools.${phpPkgName}.socket};
            fastcgi_index index.php;
            fastcgi_split_path_info ^(.+?\.php)(|/.*)$;
            fastcgi_param SCRIPT_FILENAME ${wwwRoot}$fastcgi_script_name;
          '';
        };
      };
    in
      builtins.listToAttrs (map f phpPkgNames);
in
{
  nixpkgs.config.permittedInsecurePackages = [
    "openssl-1.1.1w"
  ];

  services = {
    phpfpm.pools = phpPools;
    nginx = {
      enable = true;
      virtualHosts.localhost.locations = nginxLocations;
    };
  };
  users.users.php = {
    isSystemUser = true;
    group  = "php";
  };
  users.groups.php = {};
}
