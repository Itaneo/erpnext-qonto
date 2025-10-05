/**
 * Qonto Connector - Global JavaScript functions
 * 
 * This file contains utility functions that can be used across the app
 */

// Utility function to format currency
function format_qonto_currency(amount, currency) {
    currency = currency || 'EUR';
    
    return new Intl.NumberFormat('en-US', {
        style: 'currency',
        currency: currency,
        minimumFractionDigits: 2
    }).format(amount);
}

// Utility function to format date
function format_qonto_date(date_string) {
    if (!date_string) return 'Never';
    
    const date = new Date(date_string);
    return date.toLocaleString('en-US', {
        year: 'numeric',
        month: 'short',
        day: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
    });
}

// Show connection status indicator
function show_qonto_connection_status(is_connected) {
    const indicator_class = is_connected ? 'connected' : 'disconnected';
    const status_text = is_connected ? __('Connected') : __('Disconnected');
    
    return `<span class="qonto-connection-indicator ${indicator_class}"></span>${status_text}`;
}

// Show alert with auto-hide
function show_qonto_alert(message, indicator, timeout) {
    indicator = indicator || 'blue';
    timeout = timeout || 5;
    
    frappe.show_alert({
        message: message,
        indicator: indicator
    }, timeout);
}

// Get log level badge class
function get_log_level_class(level) {
    const level_map = {
        'INFO': 'text-info',
        'WARN': 'text-warning',
        'ERROR': 'text-danger'
    };
    return level_map[level] || 'text-muted';
}

// Format transaction amount with color
function format_transaction_amount(amount, currency) {
    const formatted = format_qonto_currency(Math.abs(amount), currency);
    const color_class = amount < 0 ? 'text-danger' : 'text-success';
    const sign = amount < 0 ? '-' : '+';
    
    return `<span class="${color_class}">${sign} ${formatted}</span>`;
}

// Build account summary card HTML
function build_account_card(account) {
    let html = '<div class="qonto-account-card">';
    html += `<h6>${account.name || __('Unnamed Account')}</h6>`;
    html += `<p><strong>${__('IBAN')}:</strong> ${account.iban || 'N/A'}</p>`;
    html += `<p><strong>${__('Currency')}:</strong> ${account.currency || 'EUR'}</p>`;
    html += `<p><strong>${__('Balance')}:</strong> ${format_qonto_currency(account.balance, account.currency)}</p>`;
    
    if (account.status) {
        const badge_class = account.status === 'active' ? 'badge-qonto-active' : 'badge-qonto-inactive';
        html += `<span class="badge ${badge_class}">${account.status}</span>`;
    }
    
    html += '</div>';
    return html;
}

// Build sync log table HTML
function build_sync_log_table(logs) {
    let html = '<div class="qonto-table-responsive">';
    html += '<table class="table table-bordered table-hover">';
    html += '<thead><tr>';
    html += `<th>${__('Time')}</th>`;
    html += `<th>${__('Level')}</th>`;
    html += `<th>${__('Message')}</th>`;
    html += `<th>${__('Items')}</th>`;
    html += `<th>${__('Duration')}</th>`;
    html += '</tr></thead><tbody>';
    
    if (logs && logs.length > 0) {
        logs.forEach(function(log) {
            const level_class = get_log_level_class(log.level);
            
            html += '<tr>';
            html += `<td>${format_qonto_date(log.run_at)}</td>`;
            html += `<td class="${level_class}">${log.level || ''}</td>`;
            html += `<td>${log.message || ''}</td>`;
            html += `<td>${log.items_processed || 0}</td>`;
            html += `<td>${log.duration_ms ? log.duration_ms + 'ms' : 'N/A'}</td>`;
            html += '</tr>';
        });
    } else {
        html += `<tr><td colspan="5" class="text-center text-muted">${__('No logs found')}</td></tr>`;
    }
    
    html += '</tbody></table></div>';
    return html;
}

// Show error dialog
function show_qonto_error(title, message) {
    frappe.msgprint({
        title: title || __('Error'),
        message: message || __('An error occurred'),
        indicator: 'red'
    });
}

// Show success dialog
function show_qonto_success(title, message) {
    frappe.msgprint({
        title: title || __('Success'),
        message: message || __('Operation completed successfully'),
        indicator: 'green'
    });
}

// Confirm action dialog
function confirm_qonto_action(message, callback) {
    frappe.confirm(
        message,
        function() {
            if (callback) callback();
        }
    );
}

