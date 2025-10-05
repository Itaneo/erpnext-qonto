from frappe import _


def get_data():
    return [
        {
            "module_name": "Qonto Connector",
            "color": "#FF6B35",
            "icon": "octicon octicon-credit-card",
            "type": "module",
            "label": _("Qonto Connector"),
            "description": _("Sync Qonto bank transactions into ERPNext"),
        }
    ]

