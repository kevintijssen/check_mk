#!/usr/bin/python
# -*- encoding: utf-8; py-indent-offset: 4 -*-

group = "agents/" + _("Agent Plugins")

register_rule(group,
    "agent_config:windows_os_info",
    DropdownChoice(
        title = _("Windows OS Info (Windows)"),
        choices = [
            ( True, _("Deploy plugin for Windows OS Info") ),
            ( None, _("Do not deploy plugin for Windows OS Info") ),
        ]
    )
)

