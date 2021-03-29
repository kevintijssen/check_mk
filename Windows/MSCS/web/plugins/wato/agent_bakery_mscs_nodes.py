#!/usr/bin/python
# -*- encoding: utf-8; py-indent-offset: 4 -*-

group = "agents/" + _("Agent Plugins")

register_rule(group,
    "agent_config:mscs_nodes",
    DropdownChoice(
        title = _("Microsoft Cluster Nodes (Windows)"),
        choices = [
            ( True, _("Deploy plugin") ),
            ( None, _("Do not deploy plugin") ),
        ]
    )
)

