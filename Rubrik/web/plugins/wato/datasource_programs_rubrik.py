#!/usr/bin/python
# -*- encoding: utf-8; py-indent-offset: 4 -*-

group = "datasource_programs"

register_rule(group,
    "special_agents:rubrik",
    Dictionary(
        elements = [
            ( "cluster",
              Alternative(
                  title = _("Cluster Address"),
                  help  = _("If you specify a hostname here, then a dynamic DNS lookup "
                            "will be done instead of using the IP address of the host "
                            "as configured in your host properties."),
                  elements = [
                    FixedValue(True, title = _("Use host address"), totext = ""),
                    TextAscii(title = _("Enter IP or FQDN"))
                  ],
                  default_value = True
              )
            ),
            ( "username",
              TextAscii(
                  title = _("Username"),
                  allow_empty = False,
              )
            ),
            ( "password",
              Password(
                  title = _("Password"),
                  allow_empty = False,
              )
            ),
            ( "growth",
               Checkbox(
                   title = _("Growth"),
                   label = _("Show average growth per day"),
                   default_value = False,
              )
            ),
            ( "runway",
               Checkbox(
                   title = _("Runway"),
                   label = _("Show Estimated Runway in days"),
                   default_value = False,
              )
            ),
            ( "sys_storage",
               Checkbox(
                   title = _("System Storage"),
                   label = _("Show stats from System Storage"),
                   default_value = False,
              )
            ),
        ],
        optional_keys = False
    ),
    title = _("Check Rubrik via REST-API"),
    help = _("This rule selects the Rubrik Agent instead of the normal Check_MK Agent "
             "which collects the data through the Nutanix web interface"),
    match = 'first'
)

