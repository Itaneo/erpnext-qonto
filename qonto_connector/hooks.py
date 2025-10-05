app_name = "qonto_connector"
app_title = "Qonto Connector"
app_publisher = "Itanéo"
app_description = "Sync Qonto bank transactions into ERPNext"
app_email = "support@itaneo.com"
app_license = "MIT"
app_version = "1.0.0"

# Includes in <head>
# ------------------

# Include JS / CSS files in the desk
# NOTE: DO NOT include files globally as they affect all pages including login
# app_include_css = "/assets/qonto_connector/css/qonto.css"
# app_include_js = "/assets/qonto_connector/js/qonto_settings.js"

# Include JS / CSS in a specific web page
# page_js = {"page" : "public/js/file.js"}
# page_css = {"page" : "public/css/file.css"}

# Home Pages
# ----------

# Application home page (will override Website Settings)
# home_page = "login"

# Website user home page (by Role)
# role_home_page = {
# 	"Role": "home_page"
# }

# Generators
# ----------

# Automatically create page for each record of this doctype
# website_generators = ["Web Page"]

# Installation
# ------------

# before_install = "qonto_connector.install.before_install"
# after_install = "qonto_connector.install.after_install"

# Uninstallation
# --------------

# before_uninstall = "qonto_connector.uninstall.before_uninstall"
# after_uninstall = "qonto_connector.uninstall.after_uninstall"

# Desk Notifications
# ------------------
# See frappe.core.notifications.get_notification_config

# notification_config = "qonto_connector.notifications.get_notification_config"

# Permissions
# -----------
# Permissions evaluated in scripted ways

# permission_query_conditions = {
# 	"Event": "frappe.desk.doctype.event.event.get_permission_query_conditions",
# }
#
# has_permission = {
# 	"Event": "frappe.desk.doctype.event.event.has_permission",
# }

# DocType Class
# ---------------
# Override standard doctype classes

# override_doctype_class = {
# 	"ToDo": "custom_app.overrides.CustomToDo"
# }

# Document Events
# ---------------
# Hook on document methods and events

doc_events = {
    "Bank Transaction": {
        "before_insert": "qonto_connector.qonto.utils.prevent_duplicate_qonto_transaction"
    }
}

# Scheduled Tasks
# ---------------

scheduler_events = {
    # Run every 15 minutes
    "cron": {
        "*/15 * * * *": [
            "qonto_connector.qonto.sync.schedule_all_syncs"
        ]
    }
}

# Testing
# -------

# before_tests = "qonto_connector.install.before_tests"

# Overriding Methods
# ------------------------------
#
# override_whitelisted_methods = {
# 	"frappe.desk.doctype.event.event.get_events": "qonto_connector.event.get_events"
# }
#
# each overriding function accepts a `data` argument;
# generated from the base implementation of the doctype dashboard,
# along with any modifications made in other Frappe apps
# override_doctype_dashboards = {
# 	"Task": "qonto_connector.task.get_dashboard_data"
# }

# Exempt Linked Doctypes
# -----------------------

# exempted_from_linked_with_doctypes = ["Cost Center"]

# Migrate Hooks
# -------------

after_migrate = [
    "qonto_connector.qonto.utils.ensure_custom_fields",
    "qonto_connector.qonto.utils.ensure_qonto_manager_role"
]

# User Data Protection
# --------------------

# user_data_fields = [
# 	{
# 		"doctype": "{doctype_1}",
# 		"filter_by": "{filter_by}",
# 		"redact_fields": ["{field_1}", "{field_2}"],
# 		"partial": 1,
# 	},
# 	{
# 		"doctype": "{doctype_2}",
# 		"filter_by": "{filter_by}",
# 		"partial": 1,
# 	},
# 	{
# 		"doctype": "{doctype_3}",
# 		"strict": False,
# 	},
# 	{
# 		"doctype": "{doctype_4}"
# 	}
# ]

# Authentication and authorization
# --------------------------------

# auth_hooks = [
# 	"qonto_connector.auth.validate"
# ]

