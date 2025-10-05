// Copyright (c) 2025, Itanéo and contributors
// For license information, please see license.txt

frappe.ui.form.on('Qonto Settings', {
    refresh: function(frm) {
        // Add Test Connection button
        frm.add_custom_button(__('Test Connection'), function() {
            test_qonto_connection(frm);
        }, __('Actions'));

        // Add Fetch Accounts button
        if (frm.doc.connected) {
            frm.add_custom_button(__('Fetch Accounts'), function() {
                fetch_qonto_accounts(frm);
            }, __('Actions'));

            // Add Sync Now button
            frm.add_custom_button(__('Sync Now'), function() {
                trigger_sync(frm);
            }, __('Actions'));

            // Add View Sync Status button
            frm.add_custom_button(__('View Sync Status'), function() {
                view_sync_status(frm);
            }, __('Actions'));
        }

        // Set button handler for inline button
        frm.fields_dict.test_connection.$input.on('click', function() {
            test_qonto_connection(frm);
        });
    },

    environment: function(frm) {
        // Clear connection status when environment changes
        frm.set_value('connected', 0);
        frm.set_value('organization_id', '');
        frm.set_value('organization_name', '');
    }
});

function test_qonto_connection(frm) {
    frappe.call({
        method: 'qonto_connector.api.v1.test_connection',
        freeze: true,
        freeze_message: __('Testing connection...'),
        callback: function(r) {
            if (r.message && r.message.success) {
                frappe.show_alert({
                    message: r.message.message,
                    indicator: 'green'
                }, 5);
                frm.reload_doc();
            } else {
                frappe.msgprint({
                    title: __('Connection Failed'),
                    message: r.message ? r.message.message : __('Unknown error'),
                    indicator: 'red'
                });
            }
        }
    });
}

function fetch_qonto_accounts(frm) {
    frappe.call({
        method: 'qonto_connector.api.v1.fetch_accounts',
        freeze: true,
        freeze_message: __('Fetching accounts...'),
        callback: function(r) {
            if (r.message && r.message.success) {
                const accounts = r.message.accounts;
                
                // Show dialog with accounts
                const d = new frappe.ui.Dialog({
                    title: __('Available Qonto Accounts'),
                    fields: [
                        {
                            fieldtype: 'HTML',
                            fieldname: 'accounts_html'
                        }
                    ],
                    primary_action_label: __('Close'),
                    primary_action: function() {
                        d.hide();
                    }
                });

                // Build HTML table
                let html = '<table class="table table-bordered"><thead><tr>';
                html += '<th>' + __('Name') + '</th>';
                html += '<th>' + __('IBAN') + '</th>';
                html += '<th>' + __('Currency') + '</th>';
                html += '<th>' + __('Balance') + '</th>';
                html += '<th>' + __('Status') + '</th>';
                html += '</tr></thead><tbody>';

                accounts.forEach(function(acc) {
                    html += '<tr>';
                    html += '<td>' + (acc.name || '') + '</td>';
                    html += '<td>' + (acc.iban || '') + '</td>';
                    html += '<td>' + (acc.currency || '') + '</td>';
                    html += '<td>' + (acc.balance || 0) + '</td>';
                    html += '<td>' + (acc.status || '') + '</td>';
                    html += '</tr>';
                });

                html += '</tbody></table>';
                d.fields_dict.accounts_html.$wrapper.html(html);
                d.show();
            } else {
                frappe.msgprint({
                    title: __('Error'),
                    message: r.message ? r.message.message : __('Failed to fetch accounts'),
                    indicator: 'red'
                });
            }
        }
    });
}

function trigger_sync(frm) {
    frappe.call({
        method: 'qonto_connector.api.v1.sync_now',
        freeze: true,
        freeze_message: __('Triggering sync...'),
        callback: function(r) {
            if (r.message && r.message.success) {
                frappe.show_alert({
                    message: r.message.message,
                    indicator: 'green'
                }, 5);
            } else {
                frappe.msgprint({
                    title: __('Error'),
                    message: r.message ? r.message.message : __('Failed to trigger sync'),
                    indicator: 'red'
                });
            }
        }
    });
}

function view_sync_status(frm) {
    frappe.call({
        method: 'qonto_connector.api.v1.get_sync_status',
        freeze: true,
        freeze_message: __('Loading sync status...'),
        callback: function(r) {
            if (r.message) {
                const status = r.message;
                
                const d = new frappe.ui.Dialog({
                    title: __('Sync Status'),
                    fields: [
                        {
                            fieldtype: 'HTML',
                            fieldname: 'status_html'
                        }
                    ],
                    primary_action_label: __('Close'),
                    primary_action: function() {
                        d.hide();
                    }
                });

                let html = '<div class="qonto-sync-status">';
                html += '<p><strong>' + __('Connected') + ':</strong> ' + (status.connected ? __('Yes') : __('No')) + '</p>';
                html += '<p><strong>' + __('Sync Running') + ':</strong> ' + (status.is_running ? __('Yes') : __('No')) + '</p>';
                html += '<p><strong>' + __('Last Sync') + ':</strong> ' + (status.last_sync || __('Never')) + '</p>';
                
                if (status.last_error) {
                    html += '<p><strong>' + __('Last Error') + ':</strong> <span class="text-danger">' + status.last_error + '</span></p>';
                }

                html += '<h5 class="mt-3">' + __('Recent Logs') + '</h5>';
                html += '<table class="table table-bordered"><thead><tr>';
                html += '<th>' + __('Time') + '</th>';
                html += '<th>' + __('Level') + '</th>';
                html += '<th>' + __('Message') + '</th>';
                html += '<th>' + __('Items') + '</th>';
                html += '</tr></thead><tbody>';

                (status.recent_logs || []).forEach(function(log) {
                    let level_class = 'text-muted';
                    if (log.level === 'ERROR') level_class = 'text-danger';
                    else if (log.level === 'WARN') level_class = 'text-warning';
                    
                    html += '<tr>';
                    html += '<td>' + (log.run_at || '') + '</td>';
                    html += '<td class="' + level_class + '">' + (log.level || '') + '</td>';
                    html += '<td>' + (log.message || '') + '</td>';
                    html += '<td>' + (log.items_processed || 0) + '</td>';
                    html += '</tr>';
                });

                html += '</tbody></table></div>';
                d.fields_dict.status_html.$wrapper.html(html);
                d.show();
            }
        }
    });
}

