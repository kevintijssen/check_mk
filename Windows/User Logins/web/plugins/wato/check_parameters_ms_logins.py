register_check_parameters(
    subgroup_applications,
    "ms_logins",
    _("MS User Logins"),
    Tuple(
        title = _("Parameters for the Microsoft User Logins"),
        elements = [
            Checkbox(title = _("Display All Users (Active and Disconnected) verbosely"), default_value = True),
            ],
    ),
    None,
    "first"
)

