{ ... }:
{
  services = {
    lldap = {
      enable = true;
      settings = {
        ldap_host = "::1";
        http_host = "::1";
        http_url = "https://auth.xieve.net";
        ldap_base_dn = "dc=auth,dc=xieve,dc=net";
        smtp_options.enable_password_reset = false;
      };
    };
  };
  systemd.services.lldap.serviceConfig.SetCredentialEncrypted = [
    "LLDAP_JWT_SECRET_FILE:Whxqht+dQJax1aZeCGLxmiAAAAABAAAADAAAABAAAADjFROOrH34XxZYnKsAAAAAv3jIy8F+7x9iKBM2wCqGCSwlJIGzAFC4f2ve84OaMgw4ljuJBZOn03rC5n1fWIrL+fixvENwBhprZ6+fKmDi0xZ9AKDAbA46SLr1S4T94qivfHp9Jd9eOJV4zL0bgTYw"
    "LLDAP_KEY_SEED_FILE:Whxqht+dQJax1aZeCGLxmiAAAAABAAAADAAAABAAAAD/tWFCRpQY2qQY2yAAAAAAlmKIeQAjspB7Ge5asJcrqClIVsD4RDh2UrcoVhjGNojsXfzOhkTLxPQo3n6wVwdA87kZ3ODHjK5D9A7oHOQHKnpNfrRqrjdo2xmpapZQGFF9BAEOVB6BuSe8Eo/CDuJUhm4eWkFn8UASYEK0dLxxiJxGNw7L6byJGfbsAdR2sBJvXPqPtzFvHTeIAnPgZFWKsAQvqC+8L6P2QnlKBO3Y9lshREJfYuiRMqXOhba4EbA9N6u082xo+Q=="
  ];
}
