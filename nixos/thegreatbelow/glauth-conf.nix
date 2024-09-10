{
  ldap = {
    enabled = true;
    listen = "localhost:389";
  };
  ldaps.enabled = false;

  backend = {
    datastore = "config";
    baseDN = "dc=thegreatbelow";
  };

  users = [
    {
      name = "xieve";
      uidnumber = 1000;
      primarygroup = 100; # users
      passbcrypt = "REDACTED";
    }
  ];

  groups = [
    {
      name = "users";
      gidnumber = 100;
    }
  ];
}
