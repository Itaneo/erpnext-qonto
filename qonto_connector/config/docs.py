"""
Configuration for documentation
"""


def get_context(context):
    context.brand_html = "Qonto Connector"
    context.top_bar_items = [
        {"label": "Documentation", "url": "/docs"},
        {"label": "GitHub", "url": "https://github.com/itaneo/qonto-connector", "right": True},
    ]

