#!/usr/bin/python
# -*- encoding: utf-8; py-indent-offset: 4 -*-

group = "agents/" + _("Agent Plugins")

register_rule(group,
    "agent_config:win_fw",
    DropdownChoice(
        title = _("Windows Firewall State (Windows)"),
        choices = [
            ( True, _("Deploy plugin for Windows") ),
            ( None, _("Do not deploy plugin") ),
        ]
    )
)

